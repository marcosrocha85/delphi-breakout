unit Breakout.Types;

interface

type
  TGameState = (gsReady, gsPlaying, gsPaused, gsLevelComplete, gsGameOver, gsVictory);
  TGameCommand = (gcLaunch, gcRestart, gcTogglePause, gcDeactivate, gcDebugStep);

  TBall = record
    X, Y, Size: Double;
    VelocityX, VelocityY: Double; // logical units per second
  end;

  TPaddle = record
    X, Y, Width, Height: Double;
  end;

  TBrick = record
    Id: Integer;
    X, Y, Width, Height: Double;
    SpriteIndex, Points: Integer;
    Active: Boolean;
  end;

  TGameConfig = record
    Width, Height, PaddleWidth, PaddleHeight, PaddleY, BallSize: Double;
    BallGap, BallSpeed, MaxPaddleAngle, MinPaddleAngle: Double;
    InitialLives, LevelCount: Integer;
    class function Default: TGameConfig; static;
  end;

  TGameSnapshot = record
    State: TGameState;
    Lives, Score, Level, ActiveBricks, LastHitBrickId: Integer;
    Seed: Cardinal;
    Ball: TBall;
    Paddle: TPaddle;
    Bricks: TArray<TBrick>;
    CollisionLimitCount: Integer;
    CollisionDiscardedSeconds: Double;
  end;

const
  FixedDeltaSeconds = 1.0 / 120.0;
  MaxElapsedSeconds = 0.1;
  MaxStepsPerCallback = 12;
  MaxImpactsPerStep = 8;

type

  TSeededRandom = record
  private
    FState: Cardinal;
  public
    procedure Reset(Seed: Cardinal);
    function Next(Count: Integer): Integer;
  end;

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
  Result.MaxPaddleAngle := 60;
  Result.MinPaddleAngle := 5;
  Result.InitialLives := 3;
  Result.LevelCount := 1;
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
