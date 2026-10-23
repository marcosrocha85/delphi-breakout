unit UMain;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  StdCtrls, ImgList, Math, AppEvnts, System.ImageList,
  Breakout.Types, Breakout.Game;

type
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
    FGame: TGame;
    FBrickViews: TArray<TImage>;
    FMessageLabel, FScoreLabel, FLivesLabel: TLabel;
    procedure SendCommand(Command: TGameCommand);
    procedure CreateHud;
    procedure SyncBricks(const Snapshot: TGameSnapshot);
    procedure UpdateHud(const Snapshot: TGameSnapshot);
    procedure ToggleDebug;
  public
    destructor Destroy; override;
    class function FormatScore(Value: Integer): string; static;
    procedure RefreshView;
    property Game: TGame read FGame;
    property MessageLabel: TLabel read FMessageLabel;
    property ScoreLabel: TLabel read FScoreLabel;
    property LivesLabel: TLabel read FLivesLabel;
  end;

var
  FrmMain: TFrmMain;

implementation

uses UDebug, Breakout.Texts;

{$R *.dfm}

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FGame := TGame.Create(TGameConfig.Default, GetTickCount);
  CreateHud;
  Cursor := crNone;
  ImgPlayerL.Cursor := crNone;
  ImgPlayerM.Cursor := crNone;
  ImgPlayerR.Cursor := crNone;
  RefreshView;
end;

destructor TFrmMain.Destroy;
begin
  if Assigned(Timer1) then Timer1.Enabled := False;
  FreeAndNil(FrmDebug);
  FreeAndNil(FGame);
  inherited;
end;

procedure TFrmMain.CreateHud;
  function LabelAt(X, Y, W: Integer): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := Self;
    Result.AutoSize := False;
    Result.SetBounds(X, Y, W, 13);
    Result.Font.Color := clWhite;
    Result.Font.Style := [fsBold];
  end;
begin
  FMessageLabel := LabelAt(0, 220, ClientWidth);
  FMessageLabel.Alignment := taCenter;
  FScoreLabel := LabelAt(576, 437, 105);
  FLivesLabel := LabelAt(5, 437, 35);
  FLivesLabel.Caption := SLives;
end;

procedure TFrmMain.SendCommand(Command: TGameCommand);
begin
  FGame.Execute(Command);
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
    VK_F1:
      if Assigned(FrmDebug) and FrmDebug.Visible then SendCommand(gcDebugStep);
    VK_F2: SendCommand(gcRestart);
    VK_F3: SendCommand(gcTogglePause);
    VK_F10: ToggleDebug;
    VK_SPACE: SendCommand(gcLaunch);
  else
    Exit;
  end;
  Key := 0;
end;

procedure TFrmMain.ApplicationEvents1Deactivate(Sender: TObject);
begin
  if Assigned(FGame) then SendCommand(gcDeactivate);
end;

procedure TFrmMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  FGame.MovePaddle(ScreenToClient(Mouse.CursorPos).X);
  RefreshView;
end;

procedure TFrmMain.Timer1Timer(Sender: TObject);
begin
  FGame.Step;
  RefreshView;
end;

procedure TFrmMain.SyncBricks(const Snapshot: TGameSnapshot);
var
  I: Integer;
  Brick: TBrick;
begin
  if Length(FBrickViews) <> Length(Snapshot.Bricks) then
  begin
    for I := 0 to High(FBrickViews) do FBrickViews[I].Free;
    SetLength(FBrickViews, Length(Snapshot.Bricks));
    for I := 0 to High(FBrickViews) do
    begin
      FBrickViews[I] := TImage.Create(Self);
      FBrickViews[I].Parent := Self;
      FBrickViews[I].Name := 'Bar' + IntToStr(Snapshot.Bricks[I].Id);
      FBrickViews[I].OnClick := FormClick;
      FBrickViews[I].OnMouseMove := FormMouseMove;
      FBrickViews[I].Tag := -1;
    end;
  end;
  for I := 0 to High(FBrickViews) do
  begin
    Brick := Snapshot.Bricks[I];
    FBrickViews[I].SetBounds(Round(Brick.X), Round(Brick.Y),
      Round(Brick.Width), Round(Brick.Height));
    if FBrickViews[I].Tag <> Brick.SpriteIndex then
    begin
      Image.GetBitmap(Brick.SpriteIndex, FBrickViews[I].Picture.Bitmap);
      FBrickViews[I].Tag := Brick.SpriteIndex;
    end;
    FBrickViews[I].Visible := Brick.Active;
  end;
end;

procedure TFrmMain.RefreshView;
var
  View: TGameSnapshot;
begin
  View := FGame.Snapshot;
  Player.SetBounds(Round(View.Paddle.X), Round(View.Paddle.Y),
    Round(View.Paddle.Width), Round(View.Paddle.Height));
  Ball.SetBounds(Round(View.Ball.X), Round(View.Ball.Y),
    Round(View.Ball.Size), Round(View.Ball.Size));
  SyncBricks(View);
  UpdateHud(View);
  Timer1.Enabled := View.State = gsPlaying;
  if Assigned(FrmDebug) then FrmDebug.UpdateFrom(View);
end;

class function TFrmMain.FormatScore(Value: Integer): string;
begin
  Result := FormatFloat('000000000', Value);
end;

procedure TFrmMain.UpdateHud(const Snapshot: TGameSnapshot);
begin
  FScoreLabel.Caption := SScore + ' ' + FormatScore(Snapshot.Score);
  VLives.Width := Snapshot.Lives * 15;
  case Snapshot.State of
    gsPaused: FMessageLabel.Caption := SPaused;
    gsGameOver: FMessageLabel.Caption := SGameOver;
    gsLevelComplete: FMessageLabel.Caption := SLevelComplete;
    gsVictory: FMessageLabel.Caption := SVictory;
  else
    FMessageLabel.Caption := '';
  end;
  FMessageLabel.Visible := FMessageLabel.Caption <> '';
end;

procedure TFrmMain.ToggleDebug;
begin
  if Assigned(FrmDebug) and FrmDebug.Visible then
    FreeAndNil(FrmDebug)
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
