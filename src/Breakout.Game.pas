unit Breakout.Game;

interface

uses Breakout.Types;

type
  TGame = class
  private
    FConfig: TGameConfig;
    FSeed: Cardinal;
    FRandom: TSeededRandom;
    procedure StartNewGame;
    procedure LoadLevel;
    procedure ResetPositions;
    procedure Advance;
    procedure HandleBounds;
    function HasLostBall: Boolean;
    procedure LoseLife;
    procedure HandlePaddleCollision;
    procedure HandleBrickCollisions;
    function CountActiveBricks: Integer;
  protected
    { Scenario probes in the test tools arrange inputs here, without VCL. }
    FState: TGameState;
    FBall: TBall;
    FPaddle: TPaddle;
    FBricks: TArray<TBrick>;
    FLives, FScore, FLevel, FLastHitBrickId: Integer;
  public
    constructor Create(const Config: TGameConfig; Seed: Cardinal);
    procedure Execute(Command: TGameCommand);
    procedure MovePaddle(CenterX: Double);
    procedure Step;
    function Snapshot: TGameSnapshot;
  end;

implementation

uses System.SysUtils, System.Math, Breakout.Levels;

constructor TGame.Create(const Config: TGameConfig; Seed: Cardinal);
begin
  inherited Create;
  if (Config.Width < Config.PaddleWidth) or (Config.PaddleWidth < Config.BallSize) or
     (Config.BallSize <= 0) or (Config.PaddleHeight <= 0) or
     (Config.PaddleY < Config.BallSize + Config.BallGap) or
     (Config.PaddleY + Config.PaddleHeight > Config.Height) or
     (Config.InitialLives <= 0) or (Config.LevelCount <= 0) or
     (Config.InitialStep <= 0) or (Config.EdgeStep <= 0) or
     (Config.BallGap < 0) or (Config.PaddleTolerance < 0) or
     (Config.PaddleEdge < 0) or (2 * Config.PaddleEdge > Config.PaddleWidth) then
    raise EArgumentException.Create('Invalid game configuration');
  FConfig := Config;
  FSeed := Seed;
  StartNewGame;
end;

procedure TGame.StartNewGame;
begin
  FLives := FConfig.InitialLives;
  FScore := 0;
  FLevel := 1;
  FRandom.Reset(FSeed xor $A5A5A5A5);
  LoadLevel;
end;

procedure TGame.LoadLevel;
begin
  FBricks := GenerateLegacyLevel(FSeed, FLevel);
  FLastHitBrickId := -1;
  ResetPositions;
  FState := gsReady;
end;

procedure TGame.ResetPositions;
begin
  FPaddle.Width := FConfig.PaddleWidth;
  FPaddle.Height := FConfig.PaddleHeight;
  FPaddle.Y := FConfig.PaddleY;
  FPaddle.X := Trunc((FConfig.Width - FPaddle.Width) / 2);
  FBall.Size := FConfig.BallSize;
  FBall.X := FPaddle.X + Trunc((FPaddle.Width - FBall.Size) / 2);
  FBall.Y := FPaddle.Y - FBall.Size - FConfig.BallGap;
  FBall.StepX := FConfig.InitialStep;
  if FRandom.Next(2) = 0 then
    FBall.StepX := -FBall.StepX;
  FBall.StepY := -FConfig.InitialStep;
end;

procedure TGame.Execute(Command: TGameCommand);
begin
  case Command of
    gcRestart: StartNewGame;
    gcLaunch:
      case FState of
        gsReady: FState := gsPlaying;
        gsLevelComplete:
          begin
            Inc(FLevel);
            LoadLevel;
          end;
      end;
    gcTogglePause:
      case FState of
        gsPlaying: FState := gsPaused;
        gsPaused: FState := gsPlaying;
      end;
    gcDeactivate:
      if FState = gsPlaying then FState := gsPaused;
    gcDebugStep:
      if FState = gsPaused then Advance;
  end;
end;

procedure TGame.MovePaddle(CenterX: Double);
begin
  if not (FState in [gsReady, gsPlaying]) then Exit;
  FPaddle.X := EnsureRange(CenterX - FPaddle.Width / 2, 0.0,
    FConfig.Width - FPaddle.Width);
  if FState = gsReady then
    FBall.X := FPaddle.X + Trunc((FPaddle.Width - FBall.Size) / 2);
end;

procedure TGame.Step;
begin
  if FState = gsPlaying then Advance;
end;

procedure TGame.Advance;
begin
  HandleBounds;
  if HasLostBall then
  begin
    LoseLife;
    Exit;
  end;
  HandlePaddleCollision;
  HandleBrickCollisions;
  if CountActiveBricks = 0 then
  begin
    if FLevel = FConfig.LevelCount then FState := gsVictory
    else FState := gsLevelComplete;
    Exit;
  end;
  FBall.X := FBall.X + FBall.StepX;
  FBall.Y := FBall.Y + FBall.StepY;
end;

procedure TGame.HandleBounds;
begin
  if FBall.X <= 0 then
  begin
    FBall.X := 0;
    FBall.StepX := Abs(FBall.StepX);
  end
  else if FBall.X >= FConfig.Width - FBall.Size then
  begin
    FBall.X := FConfig.Width - FBall.Size;
    FBall.StepX := -Abs(FBall.StepX);
  end;
  if FBall.Y <= 0 then
  begin
    FBall.Y := 0;
    FBall.StepY := Abs(FBall.StepY);
  end;
end;

function TGame.HasLostBall: Boolean;
begin
  { Preserve the E1 loss geometry until E3 defines the lower boundary. }
  Result := (FBall.Y > FPaddle.Y) and
    ((FBall.X < FPaddle.X - FConfig.PaddleTolerance) or
     (FBall.X > FPaddle.X + FPaddle.Width + FConfig.PaddleTolerance));
end;

procedure TGame.LoseLife;
begin
  Dec(FLives);
  ResetPositions;
  if FLives = 0 then FState := gsGameOver else FState := gsReady;
end;

procedure TGame.HandlePaddleCollision;
begin
  if (FBall.StepY <= 0) or
     (FBall.X <= FPaddle.X - FConfig.PaddleTolerance) or
     (FBall.X >= FPaddle.X + FPaddle.Width + FConfig.PaddleTolerance) or
     (FBall.Y < FPaddle.Y - FBall.Size - FConfig.PaddleTolerance) then Exit;
  FBall.StepY := -Abs(FBall.StepY);
  { Three legacy regions: E3 will replace this with proportional reflection. }
  if FBall.X < FPaddle.X + FConfig.PaddleEdge then
  begin
    FBall.StepX := -FConfig.EdgeStep;
    FBall.StepY := -FConfig.EdgeStep;
  end
  else if FBall.X > FPaddle.X + FPaddle.Width - FConfig.PaddleEdge then
  begin
    FBall.StepX := FConfig.EdgeStep;
    FBall.StepY := -FConfig.EdgeStep;
  end
  else
  begin
    if FBall.StepX < 0 then FBall.StepX := -FConfig.InitialStep
    else FBall.StepX := FConfig.InitialStep;
    FBall.StepY := -FConfig.InitialStep;
  end;
end;

procedure TGame.HandleBrickCollisions;
var
  I: Integer;
begin
  for I := 0 to High(FBricks) do
  begin
    if not FBricks[I].Active then Continue;
    if (FBall.Y > FBricks[I].Y + FBricks[I].Height) or
       (FBall.Y + FBall.Size < FBricks[I].Y) or
       (FBall.X > FBricks[I].X + FBricks[I].Width) or
       (FBall.X + FBall.Size < FBricks[I].X) then Continue;
    { Legacy face tests, including the known lateral/vertical defects. E3 owns
      their replacement; extracting the model must not hide that work. }
    if (FBall.Y <= FBricks[I].Y + FBricks[I].Height) and
       (FBall.X <= FBricks[I].X + FBricks[I].Width - 5) and
       (FBall.X + FBall.Size >= FBricks[I].X + 5) then
      FBall.StepY := Abs(FBall.StepY)
    else if (FBall.Y + FBall.Size >= FBricks[I].Y) and
       (FBall.X <= FBricks[I].X + FBricks[I].Width - 5) and
       (FBall.X + FBall.Size >= FBricks[I].X + 5) then
      FBall.StepY := -Abs(FBall.StepY);
    if (FBall.Y + FBall.Size <= FBricks[I].Y + FBricks[I].Height) and
       (FBall.Y >= FBricks[I].Y) and (FBall.X <= FBricks[I].X + FBricks[I].Width) then
      FBall.StepX := -Abs(FBall.StepX)
    else if (FBall.Y + FBall.Size <= FBricks[I].Y + FBricks[I].Height) and
       (FBall.Y >= FBricks[I].Y) and (FBall.X + FBall.Size >= FBricks[I].X) then
      FBall.StepX := Abs(FBall.StepX);
    FBricks[I].Active := False;
    Inc(FScore, FBricks[I].Points);
    FLastHitBrickId := FBricks[I].Id;
  end;
end;

function TGame.CountActiveBricks: Integer;
var
  Brick: TBrick;
begin
  Result := 0;
  for Brick in FBricks do
    if Brick.Active then Inc(Result);
end;

function TGame.Snapshot: TGameSnapshot;
begin
  Result.State := FState;
  Result.Lives := FLives;
  Result.Score := FScore;
  Result.Level := FLevel;
  Result.Seed := FSeed;
  Result.ActiveBricks := CountActiveBricks;
  Result.LastHitBrickId := FLastHitBrickId;
  Result.Ball := FBall;
  Result.Paddle := FPaddle;
  { The caller cannot mutate the live board through a shared dynamic array. }
  Result.Bricks := Copy(FBricks);
end;

end.
