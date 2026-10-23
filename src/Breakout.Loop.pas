{** Fixed-step accumulator with bounded catch-up and explicit diagnostics. }
unit Breakout.Loop;

interface

uses Breakout.Types, Breakout.Game;

type
  {** Times are seconds; TotalSteps is cumulative. ResetClock clears the
      accumulator and LastSteps, preserving cumulative diagnostics. }
  TLoopDiagnostics = record
    AccumulatorSeconds, DiscardedSeconds: Double;
    LastSteps, LimitedCallbacks: Integer;
    TotalSteps: Int64;
  end;

  {** Caller owns Game and supplies measured elapsed time. No OS clock or VCL.
      Game must outlive this loop; destroying the loop does not free Game. }
  TGameLoop = class
  private
    FGame: TGame;
    FDiagnostics: TLoopDiagnostics;
  public
    constructor Create(Game: TGame);
    {** Drops pending fractional time, e.g. across pause/resume. }
    procedure ResetClock;
    {** Forwards intent and resets pending time on lifecycle transitions. }
    procedure Execute(Command: TGameCommand);
    {** Accumulates measured time and executes complete 1/120 s quanta.
        Time above MaxElapsedSeconds and excess complete steps are recorded
        as discarded; a fractional remainder survives for the next callback.
        @param(ElapsedSeconds Finite, nonnegative real elapsed seconds.)
        Raises @code(EArgumentOutOfRangeException) on invalid elapsed time. }
    procedure Advance(ElapsedSeconds: Double);
    property Diagnostics: TLoopDiagnostics read FDiagnostics;
  end;

implementation

uses System.SysUtils, System.Math;

constructor TGameLoop.Create(Game: TGame);
begin
  inherited Create;
  if Game = nil then raise EArgumentNilException.Create('Game');
  FGame := Game;
end;

procedure TGameLoop.ResetClock;
begin
  FDiagnostics.AccumulatorSeconds := 0;
  FDiagnostics.LastSteps := 0;
end;

procedure TGameLoop.Execute(Command: TGameCommand);
var
  Before: TGameState;
begin
  Before := FGame.State;
  FGame.Execute(Command);
  if (Before <> FGame.State) or (Command in [gcRestart, gcDebugStep]) then ResetClock;
  if (Command = gcDebugStep) and (Before = gsPaused) then
    Inc(FDiagnostics.TotalSteps);
end;

procedure TGameLoop.Advance(ElapsedSeconds: Double);
var
  Discarded, WholeSteps: Double;
begin
  if IsNan(ElapsedSeconds) or IsInfinite(ElapsedSeconds) or (ElapsedSeconds < 0) then
    raise EArgumentOutOfRangeException.Create('Elapsed time must be finite and nonnegative');
  FDiagnostics.LastSteps := 0;
  if FGame.State <> gsPlaying then
  begin
    ResetClock;
    Exit;
  end;
  Discarded := Max(0.0, ElapsedSeconds - MaxElapsedSeconds);
  FDiagnostics.AccumulatorSeconds := FDiagnostics.AccumulatorSeconds +
    Min(ElapsedSeconds, MaxElapsedSeconds);
  while (FDiagnostics.LastSteps < MaxStepsPerCallback) and
    (FDiagnostics.AccumulatorSeconds + 1.0E-10 >= FixedDeltaSeconds) do
  begin
    FDiagnostics.AccumulatorSeconds := Max(0.0,
      FDiagnostics.AccumulatorSeconds - FixedDeltaSeconds);
    FGame.Step;
    Inc(FDiagnostics.LastSteps);
    Inc(FDiagnostics.TotalSteps);
    if FGame.State <> gsPlaying then
    begin
      FDiagnostics.AccumulatorSeconds := 0;
      Break;
    end;
  end;
  WholeSteps := Trunc((FDiagnostics.AccumulatorSeconds + 1.0E-10) / FixedDeltaSeconds);
  if WholeSteps > 0 then
  begin
    Discarded := Discarded + WholeSteps * FixedDeltaSeconds;
    FDiagnostics.AccumulatorSeconds := Max(0.0,
      FDiagnostics.AccumulatorSeconds - WholeSteps * FixedDeltaSeconds);
  end;
  if Discarded > 0 then
  begin
    Inc(FDiagnostics.LimitedCallbacks);
    FDiagnostics.DiscardedSeconds := FDiagnostics.DiscardedSeconds + Discarded;
  end;
end;

end.
