{** Value types, logical units and simulation budgets shared by the engine. }
unit Breakout.Types;

interface

type
  {** Explicit lifecycle; only gsPlaying advances through normal Step calls. }
  TGameState = (gsReady, gsPlaying, gsPaused, gsLevelComplete, gsGameOver, gsVictory);
  {** Input intent, independent of keyboard bindings or VCL events. }
  TGameCommand = (gcLaunch, gcRestart, gcTogglePause, gcDeactivate, gcDebugStep);
  {** Stable identities; scoring and sprite selection live in Breakout.Bricks. }
  TBrickKind = (bkGreen, bkYellow, bkCyan, bkRed, bkSilver, bkGold);

  {** X/Y are the top-left of the bounding square; Size is the diameter.
      Velocity is measured in logical units per second, with Y growing down.
      Collision routines receive the center, obtained by adding Size/2. }
  TBall = record
    X, Y, Size: Double;
    VelocityX, VelocityY: Double; // logical units per second
  end;

  {** Logical bounds of a horizontal capsule. Width may vary independently
      of the original three-part sprite; no powerup mechanic is implied. }
  TPaddle = record
    X, Y, Width, Height: Double;
  end;

  {** One axis-aligned solid. Active becomes False at impact, before its
      presentation fades. Id identifies it within the current board. }
  TBrick = record
    Id: Integer;
    Kind: TBrickKind;
    X, Y, Width, Height: Double;
    SpriteIndex, Points: Integer;
    Active: Boolean;
  end;

  {** Physical dimensions/speed in logical units and seconds; paddle angles
      in degrees. Defaults describe the original 688 by 453 field. }
  TGameConfig = record
    Width, Height, PaddleWidth, PaddleHeight, PaddleY, BallSize: Double;
    BallGap, BallSpeed, MaxPaddleAngle, MinPaddleAngle: Double;
    {** Fractional increase compounded per level (0.05 = 5%). The absolute
        speed cap must be at least BallSpeed. Life loss reapplies the level speed. }
    LevelSpeedIncrease, MaxBallSpeed: Double;
    InitialLives, LevelCount: Integer;
    class function Default: TGameConfig; static;
  end;

  {** Detached state returned by TGame.Snapshot. Its Bricks array is copied
      from the engine. Further record assignments still share that copy: use
      Copy when retaining an independently mutable array. }
  TGameSnapshot = record
    State: TGameState;
    Lives, Score, Level, LevelCount, ActiveBricks, LastHitBrickId: Integer;
    Seed: Cardinal;
    Ball: TBall;
    Paddle: TPaddle;
    Bricks: TArray<TBrick>;
    CollisionLimitCount: Integer;
    CollisionDiscardedSeconds: Double;
  end;

const
  {** Simulation quantum: 120 steps per simulated second. }
  FixedDeltaSeconds = 1.0 / 120.0;
  {** Maximum elapsed time accepted by one loop callback; excess is recorded. }
  MaxElapsedSeconds = 0.1;
  {** Work budget against unbounded catch-up after a stalled callback. }
  MaxStepsPerCallback = 12;
  {** Collision-iteration budget; unresolved remaining time is discarded. }
  MaxImpactsPerStep = 8;

type

  {** Local deterministic LCG, independent of the global Random state.
      Useful for reproducing a board; not a cryptographic generator. }
  TSeededRandom = record
  private
    FState: Cardinal;
  public
    {** Restarts the sequence at Seed. }
    procedure Reset(Seed: Cardinal);
    {** Advances once and returns a value in [0, Count).
        Raises @code(EArgumentOutOfRangeException) when Count is not positive. }
    function Next(Count: Integer): Integer;
  end;

{** Stable diagnostic name, independent of player-facing translations. }
function GameStateName(State: TGameState): string;

implementation

uses System.SysUtils;

class function TGameConfig.Default: TGameConfig;
begin
  Result.Width := 688;
  Result.Height := 453;
  Result.PaddleWidth := 50;
  Result.PaddleHeight := 15;
  Result.PaddleY := 420;
  Result.BallSize := 17;
  Result.BallGap := 8;
  Result.BallSpeed := 240;
  Result.LevelSpeedIncrease := 0.05;
  Result.MaxBallSpeed := 300;
  Result.MaxPaddleAngle := 60;
  Result.MinPaddleAngle := 5;
  Result.InitialLives := 3;
  Result.LevelCount := 3;
end;

procedure TSeededRandom.Reset(Seed: Cardinal);
begin
  FState := Seed;
end;

function TSeededRandom.Next(Count: Integer): Integer;
begin
  if Count <= 0 then
    raise EArgumentOutOfRangeException.Create('Random count must be positive');
  { Wide arithmetic also works with overflow checking enabled. }
  FState := Cardinal((UInt64(FState) * 1664525 + 1013904223) and $FFFFFFFF);
  Result := Integer(FState mod Cardinal(Count));
end;

function GameStateName(State: TGameState): string;
const
  Names: array[TGameState] of string =
    ('Ready', 'Playing', 'Paused', 'LevelComplete', 'GameOver', 'Victory');
begin
  Result := Names[State];
end;

end.
