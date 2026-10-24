{** Game rules and earliest-contact resolution, without VCL or OS clocks. }
unit Breakout.Game;

interface

uses Breakout.Types;

type
  {** Owns the mutable match state. The caller owns this object.
      Use @link(Snapshot) to read state without exposing the live brick array. }
  TGame = class
  private
    FConfig: TGameConfig;
    FSeed: Cardinal;
    FRandom: TSeededRandom;
    FCollisionLimitCount: Integer;
    FCollisionDiscardedSeconds: Double;
    procedure StartNewGame;
    procedure LoadLevel;
    procedure ResetPositions;
    function LevelBallSpeed: Double;
    procedure Advance;
    procedure LoseLife;
    function CountActiveBricks: Integer;
  protected
    { Scenario probes in the test tools arrange inputs here, without VCL. }
    FState: TGameState;
    FBall: TBall;
    FPaddle: TPaddle;
    FBricks: TArray<TBrick>;
    FLives, FScore, FLevel, FLastHitBrickId: Integer;
  public
    {** Starts a ready match with deterministic generation.
        @param(Config Valid dimensions/speed/lives; 1..CampaignLevelCount levels,
          nonnegative finite LevelSpeedIncrease, MaxBallSpeed at least BallSpeed.)
        @param(Seed Reused on restart to reproduce the board and launch sequence.)
        Raises @code(EArgumentException) on invalid configuration. }
    constructor Create(const Config: TGameConfig; Seed: Cardinal);
    {** Applies one lifecycle command. Launch starts Ready, or loads the next
        board in Ready after LevelComplete while preserving lives/score. Victory
        requires Restart, which resets the whole seeded match. DebugStep advances
        once only when paused; it can change state after a loss or final brick. }
    procedure Execute(Command: TGameCommand);
    {** Moves the paddle in Ready/Playing and carries the ready ball.
        Paused diagnostics may opt in to reposition only the paddle between
        debug steps; the ball and simulation remain frozen.
        @param(CenterX Requested center in logical units, clamped to the field.)
        @param(AllowPaused Explicit permission from the diagnostics input adapter.) }
    procedure MovePaddle(CenterX: Double; AllowPaused: Boolean = False);
    {** Advances one FixedDeltaSeconds quantum only while Playing.
        Earliest impacts consume time, reflect velocity and continue the
        remaining interval, up to MaxImpactsPerStep. }
    procedure Step;
    {** Returns values and a copy of the brick array. Painting this snapshot
        must not call Step or modify the live engine. }
    function Snapshot: TGameSnapshot;
    property State: TGameState read FState;
  end;

implementation

uses System.SysUtils, System.Math, Breakout.Levels, Breakout.Physics;

function FiniteValues(const Values: array of Double): Boolean;
var
  Value: Double;
begin
  for Value in Values do
    if IsNan(Value) or IsInfinite(Value) then Exit(False);
  Result := True;
end;

constructor TGame.Create(const Config: TGameConfig; Seed: Cardinal);
begin
  inherited Create;
  if not FiniteValues([Config.Width, Config.Height, Config.PaddleWidth,
     Config.PaddleHeight, Config.PaddleY, Config.BallSize, Config.BallGap,
     Config.BallSpeed, Config.MinPaddleAngle, Config.MaxPaddleAngle,
     Config.LevelSpeedIncrease, Config.MaxBallSpeed]) or
     (Config.Width < Config.PaddleWidth) or (Config.PaddleWidth < Config.BallSize) or
     (Config.BallSize <= 0) or (Config.PaddleHeight <= 0) or
     (Config.PaddleWidth < Config.PaddleHeight) or
     (Config.PaddleY < Config.BallSize + Config.BallGap) or
     (Config.PaddleY + Config.PaddleHeight > Config.Height) or
     (Config.InitialLives <= 0) or (Config.LevelCount <= 0) or
     (Config.LevelCount > CampaignLevelCount) or
     (Config.LevelSpeedIncrease < 0) or (Config.MaxBallSpeed < Config.BallSpeed) or
     (Config.BallSpeed <= 0) or
     (Config.BallGap < 0) or (Config.MinPaddleAngle <= 0) or
     (Config.MaxPaddleAngle < Config.MinPaddleAngle) or (Config.MaxPaddleAngle > 60) then
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
  FCollisionLimitCount := 0;
  FCollisionDiscardedSeconds := 0;
  FRandom.Reset(FSeed xor $A5A5A5A5);
  LoadLevel;
end;

procedure TGame.LoadLevel;
begin
  FBricks := GenerateLevel(FSeed, FLevel);
  FLastHitBrickId := -1;
  ResetPositions;
  FState := gsReady;
end;

function TGame.LevelBallSpeed: Double;
var
  I: Integer;
begin
  Result := FConfig.BallSpeed;
  for I := 2 to FLevel do
  begin
    { Compare before multiplying, including unusually large finite increases. }
    if FConfig.LevelSpeedIncrease >= FConfig.MaxBallSpeed / Result - 1 then
      Exit(FConfig.MaxBallSpeed);
    Result := Result * (1 + FConfig.LevelSpeedIncrease);
  end;
end;

procedure TGame.ResetPositions;
var
  Speed: Double;
begin
  FPaddle.Width := FConfig.PaddleWidth;
  FPaddle.Height := FConfig.PaddleHeight;
  FPaddle.Y := FConfig.PaddleY;
  FPaddle.X := (FConfig.Width - FPaddle.Width) / 2;
  FBall.Size := FConfig.BallSize;
  FBall.X := FPaddle.X + (FPaddle.Width - FBall.Size) / 2;
  FBall.Y := FPaddle.Y - FBall.Size - FConfig.BallGap;
  Speed := LevelBallSpeed;
  FBall.VelocityX := Speed / Sqrt(2);
  if FRandom.Next(2) = 0 then
    FBall.VelocityX := -FBall.VelocityX;
  FBall.VelocityY := -Speed / Sqrt(2);
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

procedure TGame.MovePaddle(CenterX: Double; AllowPaused: Boolean);
begin
  if not ((FState in [gsReady, gsPlaying]) or
    (AllowPaused and (FState = gsPaused))) then Exit;
  FPaddle.X := EnsureRange(CenterX - FPaddle.Width / 2, 0.0,
    FConfig.Width - FPaddle.Width);
  if FState = gsReady then
    FBall.X := FPaddle.X + (FPaddle.Width - FBall.Size) / 2;
end;

procedure TGame.Step;
begin
  if FState = gsPlaying then Advance;
end;

procedure TGame.Advance;
type
  TContactKind = (ckWall, ckPaddle, ckBrick, ckLoss);
  TContact = record
    Kind: TContactKind;
    BrickIndex: Integer;
    Hit: TCircleHit;
  end;
var
  Contacts: TArray<TContact>;
  Count, I, J, Iteration: Integer;
  Remaining, Earliest, Radius, CX, CY, Speed, Offset: Double;
  Hit: TCircleHit;

  procedure AddContact(Kind: TContactKind; Index: Integer; const Value: TCircleHit);
  begin
    if (Value.Time < -TimeEpsilon) or (Value.Time > Remaining + TimeEpsilon) then Exit;
    Contacts[Count].Kind := Kind;
    Contacts[Count].BrickIndex := Index;
    Contacts[Count].Hit := Value;
    Inc(Count);
    Earliest := Min(Earliest, Max(0.0, Value.Time));
  end;

  procedure Plane(Distance, Velocity, NX, NY: Double; Kind: TContactKind);
  var
    Value: TCircleHit;
  begin
    { Distance is positive on the playable side; velocity points inward. }
    if (Distance >= 0) and (Velocity >= -TimeEpsilon) then Exit;
    Value := Default(TCircleHit);
    Value.NormalX := NX;
    Value.NormalY := NY;
    Value.Penetration := Max(0.0, -Distance);
    if Distance > 0 then Value.Time := -Distance / Velocity;
    AddContact(Kind, -1, Value);
  end;

begin
  if FBall.Y >= FConfig.Height then
  begin
    LoseLife;
    Exit;
  end;
  Radius := FBall.Size / 2;
  Remaining := FixedDeltaSeconds;
  SetLength(Contacts, Length(FBricks) + 5);
  for Iteration := 1 to MaxImpactsPerStep do
  begin
    Count := 0;
    Earliest := Remaining + 1;
    CX := FBall.X + Radius;
    CY := FBall.Y + Radius;
    { Stable tie order: left/right/top wall, paddle, brick collection, loss.
      All contacts at the earliest time score together. Approaching normals
      reflect in this order; duplicate seam normals cannot flip twice. }
    Plane(FBall.X, FBall.VelocityX, 1, 0, ckWall);
    Plane(FConfig.Width - FBall.Size - FBall.X, -FBall.VelocityX, -1, 0, ckWall);
    Plane(FBall.Y, FBall.VelocityY, 0, 1, ckWall);
    if (FBall.VelocityY > 0) and (CY <= FPaddle.Y + FPaddle.Height / 2 + TimeEpsilon) and
      SweepCirclePaddle(CX, CY, Radius, FBall.VelocityX, FBall.VelocityY,
        Remaining, TPhysicsRect.Create(FPaddle.X, FPaddle.Y,
          FPaddle.Width, FPaddle.Height), Hit) and (Hit.NormalY < 0) then
      AddContact(ckPaddle, -1, Hit);
    for I := 0 to High(FBricks) do
      if FBricks[I].Active and
        SweepCircleRect(CX, CY, Radius, FBall.VelocityX, FBall.VelocityY,
          Remaining, TPhysicsRect.Create(FBricks[I].X, FBricks[I].Y,
            FBricks[I].Width, FBricks[I].Height), Hit) then
        AddContact(ckBrick, I, Hit);
    Plane(FConfig.Height - FBall.Y, -FBall.VelocityY, 0, -1, ckLoss);
    if Count = 0 then
    begin
      FBall.X := FBall.X + FBall.VelocityX * Remaining;
      FBall.Y := FBall.Y + FBall.VelocityY * Remaining;
      Exit;
    end;
    FBall.X := FBall.X + FBall.VelocityX * Earliest;
    FBall.Y := FBall.Y + FBall.VelocityY * Earliest;
    Remaining := Max(0.0, Remaining - Earliest);
    for I := 0 to Count - 1 do
    begin
      if Abs(Contacts[I].Hit.Time - Earliest) > TimeEpsilon then Continue;
      Hit := Contacts[I].Hit;
      case Contacts[I].Kind of
        ckLoss:
          begin
            LoseLife;
            Exit;
          end;
        ckPaddle:
          begin
            Speed := Hypot(FBall.VelocityX, FBall.VelocityY);
            Offset := (FBall.X + Radius - FPaddle.X - FPaddle.Width / 2) /
              (FPaddle.Width / 2);
            PaddleVelocity(Offset, Speed, FBall.VelocityX,
              FConfig.MinPaddleAngle, FConfig.MaxPaddleAngle,
              FBall.VelocityX, FBall.VelocityY);
          end;
      else
        ReflectVelocity(FBall.VelocityX, FBall.VelocityY, Hit.NormalX, Hit.NormalY);
      end;
      FBall.X := FBall.X + Hit.NormalX * (Hit.Penetration + PositionEpsilon);
      FBall.Y := FBall.Y + Hit.NormalY * (Hit.Penetration + PositionEpsilon);
      if Contacts[I].Kind = ckBrick then
      begin
        J := Contacts[I].BrickIndex;
        FBricks[J].Active := False;
        Inc(FScore, FBricks[J].Points);
        FLastHitBrickId := FBricks[J].Id;
      end;
    end;
    if CountActiveBricks = 0 then
    begin
      if FLevel = FConfig.LevelCount then FState := gsVictory
      else FState := gsLevelComplete;
      Exit;
    end;
    if Remaining <= TimeEpsilon then Exit;
  end;
  { Pathological traps stop at the last safe contact. Never advance unchecked
    through solids when the bounded collision budget has been exhausted. }
  Inc(FCollisionLimitCount);
  FCollisionDiscardedSeconds := FCollisionDiscardedSeconds + Remaining;
end;

procedure TGame.LoseLife;
begin
  Dec(FLives);
  ResetPositions;
  if FLives = 0 then FState := gsGameOver else FState := gsReady;
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
  Result.LevelCount := FConfig.LevelCount;
  Result.Seed := FSeed;
  Result.ActiveBricks := CountActiveBricks;
  Result.LastHitBrickId := FLastHitBrickId;
  Result.CollisionLimitCount := FCollisionLimitCount;
  Result.CollisionDiscardedSeconds := FCollisionDiscardedSeconds;
  Result.Ball := FBall;
  Result.Paddle := FPaddle;
  { The caller cannot mutate the live board through a shared dynamic array. }
  Result.Bricks := Copy(FBricks);
end;

end.
