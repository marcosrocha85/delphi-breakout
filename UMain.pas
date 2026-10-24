unit UMain;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.AppEvnts,
  Breakout.Types, Breakout.Game, Breakout.Loop, Breakout.Presentation,
  Breakout.Renderer.Vcl;

type
  TFrmMain = class(TForm)
    Timer1: TTimer;
    ApplicationEvents1: TApplicationEvents;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ApplicationEvents1Deactivate(Sender: TObject);
    procedure ApplicationEvents1Activate(Sender: TObject);
  private
    FGame: TGame;
    FLoop: TGameLoop;
    FPresentation: TGamePresentation;
    FRenderer: TGameRenderer;
    FLastTimestamp: Int64;
    FAppActive: Boolean;
    FDebugElapsed, FSimulationMs: Double;
    FDebugUpdates: Integer;
    FCursorClipped: Boolean;
    FCursorClipBounds: TRect;
    procedure UpdateCursorConfinement;
    procedure ReleaseCursorConfinement;
    procedure SendCommand(Command: TGameCommand);
    procedure ToggleDebug;
    procedure UpdateDiagnostic(Force: Boolean);
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    function CursorWindowActive: Boolean; virtual;
    function ApplyCursorClip(Bounds: PRect): Boolean; virtual;
    procedure WndProc(var Message: TMessage); override;
    procedure DestroyWnd; override;
  public
    destructor Destroy; override;
    class function FormatScore(Value: Integer): string; static;
    procedure RefreshView(ForceDiagnostic: Boolean = True);
    procedure AdvanceFrame(ElapsedSeconds: Double);
    procedure PlayerClick(Sender: TObject);
    property GameLoop: TGameLoop read FLoop;
    property Game: TGame read FGame;
    property Presentation: TGamePresentation read FPresentation;
    property Renderer: TGameRenderer read FRenderer;
    property SimulationMs: Double read FSimulationMs;
    property DebugUpdates: Integer read FDebugUpdates;
  end;

var
  FrmMain: TFrmMain;

implementation

uses System.Math, System.Diagnostics, UDebug;

{$R *.dfm}

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FGame := TGame.Create(TGameConfig.Default, GetTickCount);
  FLoop := TGameLoop.Create(FGame);
  FPresentation := TGamePresentation.Create(TVisualConfig.Default);
  FPresentation.Reset(FGame.Snapshot);
  FRenderer := TGameRenderer.Create;
  FAppActive := True;
  FLastTimestamp := TStopwatch.GetTimeStamp;
  Cursor := crDefault;
  { Keep the initial client readable; VCL scales these window constraints on DPI
    changes. The viewport handles larger client sizes without changing physics. }
  Constraints.MinWidth := Width;
  Constraints.MinHeight := Height;
  { One persistent frame buffer; erase suppression avoids an exposed clear and
    removes the need for a second VCL form buffer. }
  ControlStyle := ControlStyle + [csOpaque];
  RefreshView;
end;

destructor TFrmMain.Destroy;
begin
  ReleaseCursorConfinement;
  if Assigned(Timer1) then Timer1.Enabled := False;
  FreeAndNil(FrmDebug);
  FreeAndNil(FRenderer);
  FreeAndNil(FPresentation);
  FreeAndNil(FLoop);
  FreeAndNil(FGame);
  inherited;
end;

function TFrmMain.CursorWindowActive: Boolean;
begin
  Result := HandleAllocated and Visible and
    IsWindowVisible(Handle) and (GetForegroundWindow = Handle) and not IsIconic(Handle);
end;

function TFrmMain.ApplyCursorClip(Bounds: PRect): Boolean;
begin
  Result := Winapi.Windows.ClipCursor(Bounds);
end;

procedure TFrmMain.ReleaseCursorConfinement;
begin
  Cursor := crDefault;
  if FCursorClipped and ApplyCursorClip(nil) then FCursorClipped := False;
end;

procedure TFrmMain.UpdateCursorConfinement;
var
  Viewport: TViewport;
  Origin: TPoint;
  Bounds: TRect;
begin
  if not Assigned(FGame) then Exit;
  if not FAppActive or (FGame.State <> gsPlaying) or
    (WindowState = wsMinimized) or not CursorWindowActive then
  begin
    ReleaseCursorConfinement;
    Exit;
  end;
  Viewport := TViewport.Fit(ClientWidth, ClientHeight);
  Origin := ClientToScreen(Point(0, 0));
  { ClipCursor uses screen pixels; round inward to exclude letterbox pixels. }
  Bounds := Rect(Origin.X + Ceil(Viewport.OffsetX), Origin.Y + Ceil(Viewport.OffsetY),
    Origin.X + Floor(Viewport.OffsetX + Viewport.Width),
    Origin.Y + Floor(Viewport.OffsetY + Viewport.Height));
  if (Bounds.Right <= Bounds.Left) or (Bounds.Bottom <= Bounds.Top) then
  begin
    ReleaseCursorConfinement;
    Exit;
  end;
  if not FCursorClipped or not EqualRect(Bounds, FCursorClipBounds) then
    if ApplyCursorClip(@Bounds) then
    begin
      FCursorClipped := True;
      FCursorClipBounds := Bounds;
    end;
  if FCursorClipped then Cursor := crNone else Cursor := crDefault;
end;

procedure TFrmMain.WndProc(var Message: TMessage);
begin
  if ((Message.Msg = WM_ACTIVATE) and (TWMActivate(Message).Active = WA_INACTIVE)) or
    ((Message.Msg = WM_SIZE) and (Message.WParam = SIZE_MINIMIZED)) or
    ((Message.Msg = WM_SHOWWINDOW) and (Message.WParam = 0)) then
    ReleaseCursorConfinement;
  inherited;
  case Message.Msg of
    WM_ACTIVATE: if TWMActivate(Message).Active <> WA_INACTIVE then UpdateCursorConfinement;
    WM_SIZE: if Message.WParam <> SIZE_MINIMIZED then UpdateCursorConfinement;
    WM_SHOWWINDOW: if Message.WParam <> 0 then UpdateCursorConfinement;
    WM_WINDOWPOSCHANGED, WM_DPICHANGED: UpdateCursorConfinement;
  end;
end;

procedure TFrmMain.DestroyWnd;
begin
  ReleaseCursorConfinement;
  inherited;
end;

procedure TFrmMain.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TFrmMain.SendCommand(Command: TGameCommand);
var
  Before: TGameState;
begin
  Before := FGame.State;
  { Match AdvanceFrame ordering: age existing feedback first, then simulate.
    Newly hit bricks are synchronized below and start at full opacity. }
  if (Command = gcDebugStep) and (Before = gsPaused) then
    FPresentation.Advance(FixedDeltaSeconds, False);
  FLoop.Execute(Command);
  if (Before <> FGame.State) or (Command in [gcRestart, gcDebugStep]) then
    FLastTimestamp := TStopwatch.GetTimeStamp;
  if Command = gcRestart then FPresentation.Reset(FGame.Snapshot);
  RefreshView;
end;

procedure TFrmMain.PlayerClick(Sender: TObject);
begin
  SendCommand(gcLaunch);
end;

procedure TFrmMain.FormClick(Sender: TObject);
begin
  SendCommand(gcLaunch);
end;

procedure TFrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_F1: if Assigned(FrmDebug) and FrmDebug.Visible then SendCommand(gcDebugStep);
    VK_F2: SendCommand(gcRestart);
    VK_F3: SendCommand(gcTogglePause);
    VK_F10: ToggleDebug;
    VK_SPACE: SendCommand(gcLaunch);
  else Exit;
  end;
  Key := 0;
end;

procedure TFrmMain.ApplicationEvents1Deactivate(Sender: TObject);
begin
  FAppActive := False;
  if Assigned(FGame) then SendCommand(gcDeactivate);
end;

procedure TFrmMain.ApplicationEvents1Activate(Sender: TObject);
begin
  FAppActive := True;
  FLastTimestamp := TStopwatch.GetTimeStamp;
  if Assigned(FPresentation) then RefreshView;
end;

procedure TFrmMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  Viewport: TViewport;
begin
  Viewport := TViewport.Fit(ClientWidth, ClientHeight);
  FGame.MovePaddle(Viewport.ToLogicalX(X), Assigned(FrmDebug) and FrmDebug.Visible);
  RefreshView(False);
end;

procedure TFrmMain.Timer1Timer(Sender: TObject);
var
  NowTimestamp: Int64;
begin
  NowTimestamp := TStopwatch.GetTimeStamp;
  AdvanceFrame((NowTimestamp - FLastTimestamp) / TStopwatch.Frequency);
  FLastTimestamp := NowTimestamp;
end;

procedure TFrmMain.AdvanceFrame(ElapsedSeconds: Double);
var
  Started: Int64;
begin
  FPresentation.Advance(Min(ElapsedSeconds, MaxElapsedSeconds),
    not FAppActive or (FGame.State = gsPaused));
  Started := TStopwatch.GetTimeStamp;
  FLoop.Advance(ElapsedSeconds);
  FSimulationMs := (TStopwatch.GetTimeStamp - Started) * 1000 / TStopwatch.Frequency;
  FDebugElapsed := FDebugElapsed + ElapsedSeconds;
  RefreshView(False);
end;

procedure TFrmMain.RefreshView(ForceDiagnostic: Boolean);
begin
  FPresentation.Sync(FGame.Snapshot);
  Timer1.Enabled := FAppActive and ((FGame.State = gsPlaying) or
    ((FGame.State <> gsPaused) and FPresentation.HasPending));
  UpdateCursorConfinement;
  UpdateDiagnostic(ForceDiagnostic);
  Invalidate;
end;

procedure TFrmMain.FormPaint(Sender: TObject);
begin
  if Assigned(FRenderer) then FRenderer.Paint(Canvas, FPresentation, ClientWidth, ClientHeight);
end;

procedure TFrmMain.FormResize(Sender: TObject);
begin
  UpdateCursorConfinement;
  Invalidate;
end;

procedure TFrmMain.UpdateDiagnostic(Force: Boolean);
begin
  if not Assigned(FrmDebug) or not FrmDebug.Visible then Exit;
  if not Force and (FDebugElapsed < DebugRefreshSeconds) then Exit;
  FDebugElapsed := 0;
  FrmDebug.UpdateFrom(FGame.Snapshot, FLoop.Diagnostics, FPresentation.DisplayedScore,
    FPresentation.HasPending, FSimulationMs, FRenderer.Metrics);
  Inc(FDebugUpdates);
end;

class function TFrmMain.FormatScore(Value: Integer): string;
begin
  Result := FormatGameScore(Value);
end;

procedure TFrmMain.ToggleDebug;
begin
  if Assigned(FrmDebug) and FrmDebug.Visible then FreeAndNil(FrmDebug)
  else
  begin
    if not Assigned(FrmDebug) then FrmDebug := TFrmDebug.Create(Self);
    FrmDebug.Left := Max(0, Left - FrmDebug.Width - 8);
    FrmDebug.Top := Top;
    FrmDebug.Show;
    RefreshView;
    if CanFocus then SetFocus;
  end;
end;

end.
