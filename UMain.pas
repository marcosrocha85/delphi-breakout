unit UMain;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  ImgList, Math, AppEvnts, System.ImageList;

type
  THorizontalDirection = (hdLeft, hdRight);
  TVerticalDirection = (vdDown, vdUp);

  TFrmMain = class(TForm)
    Timer1: TTimer;
    Ball: TImage;
    VLives: TImage;
    Image: TImageList;
    ApplicationEvents1: TApplicationEvents;
    Player: TPanel;
    ImgPlayerL: TImage;
    ImgPlayerR: TImage;
    ImgPlayerM: TImage;
    procedure PlayerClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormClick(Sender: TObject);
    procedure ApplicationEvents1Deactivate(Sender: TObject);
  private
    FPlaying, FPaused, FUpdating: Boolean;
    FHorizontalDirection: THorizontalDirection;
    FVerticalDirection: TVerticalDirection;
    FStepX, FStepY: Integer;
    FLives, FScore: Integer;
    FLastBarName: string;
    FLastBarLeft, FLastBarTop: Integer;
    procedure StartNewGame;
    procedure LaunchBall;
    procedure SetPaused(Value: Boolean);
    procedure ResetPositions;
    procedure StepGame;
    procedure HandleBounds;
    function HasLostBall: Boolean;
    procedure LoseLife;
    procedure HandlePaddleCollision;
    procedure HandleBrickCollisions;
    procedure RemoveDestroyedBars;
    procedure ClearBars;
    procedure CreateBars(const Level: Smallint);
    procedure MoveBall;
    procedure AddScore(Points: Integer);
    procedure UpdateLives;
    procedure UpdateMessages;
    procedure UpdateDebug;
    procedure ToggleDebug;
  public
    destructor Destroy; override;
    class function FormatScore(Value: Integer): string; static;
  end;

var
  FrmMain: TFrmMain;

implementation

uses UDebug, UDM;

{$R *.dfm}

const
  InitialLives = 3;
  InitialBallStep = 5;
  EdgeBallStep = 15;
  PaddleEdgeWidth = 17;
  PaddleTolerance = 5;
  BallPaddleGap = 8;
  LifeIconWidth = 15;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  Randomize;
  Language := TLanguage.Create(Self);
  Language.Load;
  Cursor := crNone;
  ImgPlayerL.Cursor := crNone;
  ImgPlayerM.Cursor := crNone;
  ImgPlayerR.Cursor := crNone;
  StartNewGame;
end;

destructor TFrmMain.Destroy;
begin
  if Assigned(Timer1) then
    Timer1.Enabled := False;
  FreeAndNil(FrmDebug);
  if Assigned(Language) and (Language.Owner = Self) then
    FreeAndNil(Language);
  inherited;
end;

procedure TFrmMain.StartNewGame;
begin
  ResetPositions;
  FLives := InitialLives;
  FScore := 0;
  FLastBarName := '';
  FLastBarLeft := 0;
  FLastBarTop := 0;
  ClearBars;
  CreateBars(1);
  Language.Score.Caption := Language.LangScore + ' ' + FormatScore(FScore);
  UpdateLives;
  UpdateMessages;
  UpdateDebug;
end;

procedure TFrmMain.ResetPositions;
begin
  Timer1.Enabled := False;
  FPlaying := False;
  FPaused := False;
  FHorizontalDirection := THorizontalDirection(Random(2));
  FVerticalDirection := vdUp;
  FStepX := InitialBallStep;
  FStepY := InitialBallStep;
  Player.Left := (ClientWidth - Player.Width) div 2;
  Ball.Left := Player.Left + (Player.Width - Ball.Width) div 2;
  Ball.Top := Player.Top - Ball.Height - BallPaddleGap;
end;

procedure TFrmMain.LaunchBall;
begin
  if (FLives <= 0) or FPlaying or FPaused then
    Exit;
  FPlaying := True;
  Timer1.Enabled := True;
  UpdateMessages;
  UpdateDebug;
end;

procedure TFrmMain.SetPaused(Value: Boolean);
begin
  if (not FPlaying) or (FLives <= 0) then
    Exit;
  FPaused := Value;
  Timer1.Enabled := not FPaused;
  UpdateMessages;
  UpdateDebug;
end;

procedure TFrmMain.PlayerClick(Sender: TObject);
begin
  LaunchBall;
end;

procedure TFrmMain.FormClick(Sender: TObject);
begin
  LaunchBall;
end;

procedure TFrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_F1:
      if Assigned(FrmDebug) and FrmDebug.Visible and FPaused then
        StepGame;
    VK_F2: StartNewGame;
    VK_F3: SetPaused(not FPaused);
    VK_F10: ToggleDebug;
    VK_SPACE: LaunchBall;
  else
    Exit;
  end;
  { Consume handled keys, including F10's default menu activation. }
  Key := 0;
end;

procedure TFrmMain.ApplicationEvents1Deactivate(Sender: TObject);
begin
  SetPaused(True);
end;

procedure TFrmMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  MousePoint: TPoint;
begin
  if FPaused or (FLives <= 0) then
    Exit;
  MousePoint := ScreenToClient(Mouse.CursorPos);
  Player.Left := EnsureRange(MousePoint.X - Player.Width div 2,
    0, Max(0, ClientWidth - Player.Width));
  if not FPlaying then
    Ball.Left := Player.Left + (Player.Width - Ball.Width) div 2;
end;

procedure TFrmMain.Timer1Timer(Sender: TObject);
begin
  if FPaused then
    Exit;
  StepGame;
end;

procedure TFrmMain.StepGame;
begin
  if FUpdating or (not FPlaying) or (FLives <= 0) then
    Exit;
  FUpdating := True;
  try
    HandleBounds;
    if HasLostBall then
    begin
      LoseLife;
      Exit;
    end;
    HandlePaddleCollision;
    HandleBrickCollisions;
    RemoveDestroyedBars;
    MoveBall;
  finally
    FUpdating := False;
    UpdateDebug;
  end;
end;

procedure TFrmMain.HandleBounds;
begin
  if Ball.Left <= 0 then
  begin
    Ball.Left := 0;
    FHorizontalDirection := hdRight;
  end
  else if Ball.Left >= ClientWidth - Ball.Width then
  begin
    Ball.Left := ClientWidth - Ball.Width;
    FHorizontalDirection := hdLeft;
  end;
  if Ball.Top <= 0 then
  begin
    Ball.Top := 0;
    FVerticalDirection := vdDown;
  end;
end;

function TFrmMain.HasLostBall: Boolean;
begin
  Result := (Ball.Top > Player.Top) and
    ((Ball.Left < Player.Left - PaddleTolerance) or
     (Ball.Left > Player.Left + Player.Width + PaddleTolerance));
end;

procedure TFrmMain.LoseLife;
begin
  Dec(FLives);
  ResetPositions;
  UpdateLives;
  UpdateMessages;
end;

procedure TFrmMain.HandlePaddleCollision;
begin
  if (FVerticalDirection <> vdDown) or
     (Ball.Left <= Player.Left - PaddleTolerance) or
     (Ball.Left >= Player.Left + Player.Width + PaddleTolerance) or
     (Ball.Top < Player.Top - Ball.Height - PaddleTolerance) then
    Exit;
  FVerticalDirection := vdUp;
  { Keep the three legacy regions until E3 replaces them with a continuous angle. }
  if Ball.Left < Player.Left + PaddleEdgeWidth then
  begin
    FHorizontalDirection := hdLeft;
    FStepX := EdgeBallStep;
    FStepY := EdgeBallStep;
  end
  else if Ball.Left > Player.Left + Player.Width - PaddleEdgeWidth then
  begin
    FHorizontalDirection := hdRight;
    FStepX := EdgeBallStep;
    FStepY := EdgeBallStep;
  end
  else
  begin
    FStepX := InitialBallStep;
    FStepY := InitialBallStep;
  end;
end;

procedure TFrmMain.HandleBrickCollisions;
var
  I: Integer;
  Bar: TImage;
begin
  for I := 0 to ComponentCount - 1 do
  begin
    if not (Components[I] is TImage) then
      Continue;
    Bar := TImage(Components[I]);
    if (Bar.Tag <= 0) or (not Bar.Visible) then
      Continue;
    if (Ball.Top > Bar.Top + Bar.Height) or
       (Ball.Top + Ball.Height < Bar.Top) or
       (Ball.Left > Bar.Left + Bar.Width) or
       (Ball.Left + Ball.Width < Bar.Left) then
      Continue;
    FLastBarName := Bar.Name;
    FLastBarLeft := Bar.Left;
    FLastBarTop := Bar.Top;
    { Preserve the legacy face tests here; E3 will replace collision resolution. }
    if (Ball.Top <= Bar.Top + Bar.Height) and
       (Ball.Left <= Bar.Left + Bar.Width - 5) and
       (Ball.Left + Ball.Width >= Bar.Left + 5) then
      FVerticalDirection := vdDown
    else if (Ball.Top + Ball.Height >= Bar.Top) and
       (Ball.Left <= Bar.Left + Bar.Width - 5) and
       (Ball.Left + Ball.Width >= Bar.Left + 5) then
      FVerticalDirection := vdUp;
    if (Ball.Top + Ball.Height <= Bar.Top + Bar.Height) and
       (Ball.Top >= Bar.Top) and (Ball.Left <= Bar.Left + Bar.Width) then
      FHorizontalDirection := hdLeft
    else if (Ball.Top + Ball.Height <= Bar.Top + Bar.Height) and
       (Ball.Top >= Bar.Top) and (Ball.Left + Ball.Width >= Bar.Left) then
      FHorizontalDirection := hdRight;
    Bar.Visible := False;
    AddScore(Bar.Tag);
  end;
end;

procedure TFrmMain.RemoveDestroyedBars;
var
  I: Integer;
begin
  for I := ComponentCount - 1 downto 0 do
    if (Components[I] is TImage) and (TImage(Components[I]).Tag > 0) and
       (not TImage(Components[I]).Visible) then
      Components[I].Free;
end;

procedure TFrmMain.ClearBars;
var
  I: Integer;
begin
  for I := ComponentCount - 1 downto 0 do
    if (Components[I] is TImage) and (TImage(Components[I]).Tag > 0) then
      Components[I].Free;
end;

procedure TFrmMain.CreateBars(const Level: Smallint);
const
  LevelOneColors: array[0..34] of Integer =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,2,3,3,3,4,4,5);
var
  X, Y: Integer;
  Bar: TImage;
begin
  if Level <> 1 then
    Exit;
  Y := 16;
  while Y < 208 do
  begin
    X := 10;
    while X < 633 do
    begin
      Bar := TImage.Create(Self);
      Bar.SetBounds(X, Y, 50, 20);
      Bar.Name := 'Bar' + IntToStr(X) + 'x' + IntToStr(Y);
      Bar.Tag := RandomFrom(LevelOneColors);
      Image.GetBitmap(Bar.Tag, Bar.Picture.Bitmap);
      Bar.Tag := (Bar.Tag + 1) * 10;
      Bar.Parent := Self;
      Bar.OnClick := FormClick;
      Bar.OnMouseMove := FormMouseMove;
      Inc(X, 56);
    end;
    Inc(Y, 24);
  end;
end;

procedure TFrmMain.MoveBall;
begin
  if FHorizontalDirection = hdLeft then
    Ball.Left := Ball.Left - FStepX
  else
    Ball.Left := Ball.Left + FStepX;
  if FVerticalDirection = vdDown then
    Ball.Top := Ball.Top + FStepY
  else
    Ball.Top := Ball.Top - FStepY;
end;

class function TFrmMain.FormatScore(Value: Integer): string;
begin
  Result := FormatFloat('000000000', Value);
end;

procedure TFrmMain.AddScore(Points: Integer);
begin
  Inc(FScore, Points);
  Language.Score.Caption := Language.LangScore + ' ' + FormatScore(FScore);
end;

procedure TFrmMain.UpdateLives;
begin
  VLives.Width := FLives * LifeIconWidth;
end;

procedure TFrmMain.UpdateMessages;
begin
  if FLives <= 0 then
    Language.Messages.Caption := Language.LangGameOver
  else if FPaused then
    Language.Messages.Caption := Language.LangPaused
  else
    Language.Messages.Caption := '';
  Language.Messages.Visible := (FLives <= 0) or FPaused;
end;

procedure TFrmMain.UpdateDebug;
begin
  if not Assigned(FrmDebug) then
    Exit;
  FrmDebug.VLE.Strings.BeginUpdate;
  try
    FrmDebug.VLE.Values[DebugLives] := IntToStr(FLives);
    FrmDebug.VLE.Values[DebugScore] := IntToStr(FScore);
    FrmDebug.VLE.Values[DebugPlayerLeft] := IntToStr(Player.Left);
    FrmDebug.VLE.Values[DebugPlayerTop] := IntToStr(Player.Top);
    FrmDebug.VLE.Values[DebugBallLeft] := IntToStr(Ball.Left);
    FrmDebug.VLE.Values[DebugBallTop] := IntToStr(Ball.Top);
    FrmDebug.VLE.Values[DebugBarName] := FLastBarName;
    FrmDebug.VLE.Values[DebugBarLeft] := IntToStr(FLastBarLeft);
    FrmDebug.VLE.Values[DebugBarTop] := IntToStr(FLastBarTop);
  finally
    FrmDebug.VLE.Strings.EndUpdate;
  end;
end;

procedure TFrmMain.ToggleDebug;
begin
  if Assigned(FrmDebug) and FrmDebug.Visible then
    FreeAndNil(FrmDebug)
  else
  begin
    if not Assigned(FrmDebug) then
      FrmDebug := TFrmDebug.Create(Self);
    FrmDebug.Left := Max(0, Left - FrmDebug.Width - 8);
    FrmDebug.Top := Top;
    FrmDebug.Show;
    UpdateDebug;
    if CanFocus then
      SetFocus;
  end;
end;

end.
