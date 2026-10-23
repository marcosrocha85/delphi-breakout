unit Breakout.Game.Tests;

interface

function RunEngineTests(const OutputDirectory: string): Boolean;

implementation

uses System.SysUtils, System.JSON, System.IOUtils, System.Math,
  Breakout.Types, Breakout.Game, Breakout.Levels, Breakout.TestScenarios;

type
  TEngineTests = class
  private
    FResults: TJSONArray;
    FFailures: Integer;
    procedure Check(const Name: string; Passed: Boolean; const Detail: string = '');
    procedure States;
    procedure LivesAndPoints;
    procedure Completion;
    procedure Determinism;
  public
    function Run(const OutputDirectory: string): Boolean;
  end;

procedure TEngineTests.Check(const Name: string; Passed: Boolean; const Detail: string);
var
  Item: TJSONObject;
begin
  Item := TJSONObject.Create;
  Item.AddPair('name', Name);
  Item.AddPair('passed', TJSONBool.Create(Passed));
  Item.AddPair('detail', Detail);
  FResults.AddElement(Item);
  if not Passed then Inc(FFailures);
end;

procedure TEngineTests.States;
var
  Game: TGame;
  Before, After: TGameSnapshot;
begin
  Game := TGame.Create(TGameConfig.Default, 12345);
  try
    Before := Game.Snapshot;
    Check('initial_state_and_counters', (Before.State = gsReady) and
      (Before.Lives = 3) and (Before.Score = 0) and (Before.Level = 1) and
      (Before.ActiveBricks = 96) and (Before.Seed = 12345));
    Game.Step;
    Game.Execute(gcDebugStep);
    Game.Execute(gcTogglePause);
    Game.Execute(gcDeactivate);
    After := Game.Snapshot;
    Check('ready_ignores_tick_debug_pause_and_deactivation',
      (After.State = gsReady) and (After.Ball.X = Before.Ball.X) and
      (After.Ball.Y = Before.Ball.Y));
    Game.MovePaddle(-1000);
    After := Game.Snapshot;
    Check('paddle_clamps_left_and_carries_ready_ball',
      (After.Paddle.X = 0) and (After.Ball.X = 16.5));
    Game.MovePaddle(10000);
    After := Game.Snapshot;
    Check('paddle_clamps_right', (After.Paddle.X = 638) and (After.Ball.X = 654.5));
    Game.MovePaddle(125);
    Before := Game.Snapshot;
    Game.Execute(gcLaunch);
    After := Game.Snapshot;
    Check('launch_preserves_prepared_position', (After.State = gsPlaying) and
      (After.Paddle.X = 100) and (After.Ball.X = Before.Ball.X) and
      (After.Ball.Y = Before.Ball.Y));
    Game.Execute(gcDebugStep);
    Game.Execute(gcLaunch);
    After := Game.Snapshot;
    Check('playing_ignores_debug_step_and_repeated_launch',
      (After.Ball.X = Before.Ball.X) and (After.Ball.Y = Before.Ball.Y));
    Game.Execute(gcTogglePause);
    After := Game.Snapshot;
    Check('immediate_pause_needs_no_timer', After.State = gsPaused);
    Game.Execute(gcLaunch);
    Game.MovePaddle(600);
    Game.Step;
    After := Game.Snapshot;
    Check('paused_ignores_launch_move_and_tick', (After.State = gsPaused) and
      (After.Paddle.X = 100) and (After.Ball.X = Before.Ball.X) and
      (After.Ball.Y = Before.Ball.Y));
    Game.Execute(gcDebugStep);
    After := Game.Snapshot;
    Check('debug_step_advances_once_and_preserves_pause', (After.State = gsPaused) and
      SameValue(After.Ball.X, Before.Ball.X + Before.Ball.VelocityX * FixedDeltaSeconds, 1.0E-8) and
      SameValue(After.Ball.Y, Before.Ball.Y + Before.Ball.VelocityY * FixedDeltaSeconds, 1.0E-8));
    Before := After;
    Game.Execute(gcTogglePause);
    After := Game.Snapshot;
    Check('resume_preserves_position_and_steps', (After.State = gsPlaying) and
      (After.Ball.X = Before.Ball.X) and (After.Ball.Y = Before.Ball.Y) and
      (After.Ball.VelocityX = Before.Ball.VelocityX) and (After.Ball.VelocityY = Before.Ball.VelocityY));
    Game.Execute(gcDeactivate);
    Game.Execute(gcDeactivate);
    After := Game.Snapshot;
    Check('deactivation_is_idempotent_pause', (After.State = gsPaused) and
      (After.Ball.X = Before.Ball.X) and (After.Ball.Y = Before.Ball.Y));
    Game.Execute(gcRestart);
    After := Game.Snapshot;
    Check('restart_from_pause_restores_ready', (After.State = gsReady) and
      (After.Score = 0) and (After.Lives = 3) and (After.ActiveBricks = 96));
    Game.Execute(gcLaunch);
    Game.Execute(gcRestart);
    Check('restart_from_play_restores_ready', Game.Snapshot.State = gsReady);
  finally
    Game.Free;
  end;
end;

procedure TEngineTests.LivesAndPoints;
var
  Game: TGameProbe;
  View: TGameSnapshot;
  I: Integer;
begin
  Game := TGameProbe.Create(TGameConfig.Default, 42);
  try
    for I := 1 to 3 do
    begin
      Game.Execute(gcLaunch);
      Game.PrepareFall;
      Game.Step;
      View := Game.Snapshot;
      Check('fall_' + IntToStr(I) + '_loses_exactly_one_life', View.Lives = 3-I);
      Check('fall_' + IntToStr(I) + '_terminates_without_extra_motion',
        (View.Ball.X = 335.5) and (View.Ball.Y = 395) and (View.Paddle.X = 319));
      Game.Step;
      Game.Execute(gcDebugStep);
      View := Game.Snapshot;
      Check('idle_after_fall_' + IntToStr(I) + '_does_not_advance',
        (View.Lives = 3-I) and (View.Ball.X = 335.5) and (View.Ball.Y = 395));
    end;
    Check('third_fall_enters_game_over', View.State = gsGameOver);
    Game.Execute(gcLaunch);
    Game.Execute(gcTogglePause);
    Game.Execute(gcDeactivate);
    Game.Execute(gcDebugStep);
    Game.MovePaddle(0);
    Game.Step;
    View := Game.Snapshot;
    Check('game_over_rejects_simulation_commands', (View.State = gsGameOver) and
      (View.Lives = 0) and (View.Ball.X = 335.5) and (View.Ball.Y = 395));
    Game.Execute(gcRestart);
    View := Game.Snapshot;
    Check('restart_after_game_over_restores_board', (View.State = gsReady) and
      (View.Lives = 3) and (View.Score = 0) and (View.ActiveBricks = 96));
    Game.Fixture;
    Game.Execute(gcLaunch);
    Game.SetBall(310, 82, 0, 240);
    Game.Step;
    View := Game.Snapshot;
    Check('hit_deactivates_brick_and_adds_its_points', (View.Score = 10) and
      (View.ActiveBricks = 1) and not View.Bricks[0].Active and
      (View.LastHitBrickId = 0));
    Check('inactive_brick_retains_stable_id_and_slot',
      (Length(View.Bricks) = 2) and (View.Bricks[0].Id = 0) and (View.Bricks[1].Id = 1));
    Game.PlaceBall(310, 82);
    Game.Step;
    Check('inactive_brick_cannot_score_again', Game.Snapshot.Score = 10);
    Game.Execute(gcRestart);
    Check('restart_clears_score_and_last_hit', (Game.Snapshot.Score = 0) and
      (Game.Snapshot.LastHitBrickId = -1));
  finally
    Game.Free;
  end;
end;

procedure TEngineTests.Completion;
var
  Config: TGameConfig;
  Game: TGameProbe;
  Before, After: TGameSnapshot;
begin
  Config := TGameConfig.Default;
  Config.LevelCount := 2;
  Game := TGameProbe.Create(Config, 123);
  try
    Game.Execute(gcLaunch);
    Game.PrepareFall;
    Game.Step;
    Game.Execute(gcLaunch);
    Game.Fixture(True);
    Game.SetBall(310, 82, 0, 240);
    Game.Step;
    Before := Game.Snapshot;
    Check('last_brick_enters_level_complete_once', (Before.State = gsLevelComplete) and
      (Before.ActiveBricks = 0) and (Before.Score = 10) and (Before.Lives = 2));
    Check('completion_terminates_the_step', (Before.Ball.X = 310) and SameValue(Before.Ball.Y, 83, 0.00001) and (Before.Ball.VelocityY < 0));
    Game.Step;
    Game.Execute(gcDebugStep);
    Game.Execute(gcTogglePause);
    Game.MovePaddle(0);
    After := Game.Snapshot;
    Check('level_complete_waits_without_moving_or_scoring',
      (After.State = gsLevelComplete) and (After.Score = 10) and
      (After.Ball.X = Before.Ball.X) and (After.Ball.Y = Before.Ball.Y));
    Game.Execute(gcLaunch);
    After := Game.Snapshot;
    Check('continue_loads_next_level_ready_preserving_lives_and_score',
      (After.State = gsReady) and (After.Level = 2) and (After.Score = 10) and
      (After.Lives = 2) and (After.ActiveBricks = 96));
    Game.Execute(gcLaunch);
    Game.Fixture(True);
    Game.SetBall(310, 82, 0, 240);
    Game.Step;
    After := Game.Snapshot;
    Check('last_level_enters_victory', (After.State = gsVictory) and
      (After.Score = 20) and (After.Lives = 2) and (After.Level = 2));
    Game.Execute(gcLaunch);
    Game.Execute(gcTogglePause);
    Game.Execute(gcDebugStep);
    Game.Step;
    Check('victory_ignores_launch_pause_and_steps', (Game.Snapshot.State = gsVictory) and
      (Game.Snapshot.Score = 20) and (Game.Snapshot.Ball.X = 310));
    Game.Execute(gcRestart);
    Check('restart_from_victory_resets_level_and_counters',
      (Game.Snapshot.State = gsReady) and (Game.Snapshot.Level = 1) and
      (Game.Snapshot.Score = 0) and (Game.Snapshot.Lives = 3));
    Game.Execute(gcLaunch);
    Game.Fixture(True);
    Game.SetBall(310, 82, 0, 240);
    Game.Execute(gcTogglePause);
    Game.Execute(gcDebugStep);
    Check('debug_completion_keeps_terminal_state', Game.Snapshot.State = gsLevelComplete);
    Game.Execute(gcRestart);
    Check('restart_from_level_complete_restores_ready', Game.Snapshot.State = gsReady);
  finally
    Game.Free;
  end;
end;

procedure TEngineTests.Determinism;
var
  First, Second: TGame;
  A, B: TGameSnapshot;
  Other: TArray<TBrick>;
  I: Integer;
  Same, Valid, Different: Boolean;
  Config: TGameConfig;
begin
  First := TGame.Create(TGameConfig.Default, 12345);
  try
    RandSeed := 987654;
    Second := TGame.Create(TGameConfig.Default, 12345);
    try
      A := First.Snapshot;
      B := Second.Snapshot;
      Same := A.Ball.VelocityX = B.Ball.VelocityX;
      Valid := Length(A.Bricks) = 96;
      for I := 0 to High(A.Bricks) do
      begin
        Same := Same and (A.Bricks[I].SpriteIndex = B.Bricks[I].SpriteIndex);
        Valid := Valid and (A.Bricks[I].Id = I) and A.Bricks[I].Active and
          (A.Bricks[I].SpriteIndex >= 0) and (A.Bricks[I].SpriteIndex <= 5) and
          (A.Bricks[I].Points = (A.Bricks[I].SpriteIndex + 1) * 10);
      end;
      Check('same_seed_generates_same_board_and_launch', Same);
      Check('board_has_unique_stable_ids_and_valid_points', Valid);
      Other := GenerateLegacyLevel(54321, 1);
      Different := False;
      for I := 0 to High(Other) do
        Different := Different or (Other[I].SpriteIndex <> A.Bricks[I].SpriteIndex);
      Check('different_seed_changes_board', Different);
      A.Bricks[0].Active := False;
      A.Bricks[0].Points := MaxInt;
      A.Ball.X := -999;
      B := First.Snapshot;
      Check('snapshot_is_detached_from_live_model', B.Bricks[0].Active and
        (B.Bricks[0].Points < MaxInt) and (B.Ball.X = 335.5));
      Same := True;
      for I := 1 to 200 do
      begin
        if First.Snapshot.State = gsReady then First.Execute(gcLaunch);
        if Second.Snapshot.State = gsReady then Second.Execute(gcLaunch);
        First.MovePaddle(First.Snapshot.Ball.X + 8);
        Second.MovePaddle(Second.Snapshot.Ball.X + 8);
        First.Step;
        RandSeed := I;
        Random(1000);
        Other := GenerateLegacyLevel(Cardinal(I), 1);
        Second.Step;
        A := First.Snapshot;
        B := Second.Snapshot;
        Same := Same and (A.State = B.State) and (A.Score = B.Score) and
          (A.Lives = B.Lives) and (A.Ball.X = B.Ball.X) and
          (A.Ball.Y = B.Ball.Y) and (A.ActiveBricks = B.ActiveBricks);
      end;
      Check('replay_ignores_global_random_and_external_level_generation', Same);
      First.Execute(gcRestart);
      Second.Execute(gcRestart);
      A := First.Snapshot;
      B := Second.Snapshot;
      Check('restart_repeats_seeded_board', (A.Seed = 12345) and
        (A.Ball.VelocityX = B.Ball.VelocityX) and (A.Bricks[0].SpriteIndex = B.Bricks[0].SpriteIndex));
    finally
      Second.Free;
    end;
  finally
    First.Free;
  end;
  First := TGame.Create(TGameConfig.Default, High(Cardinal));
  try
    Check('full_cardinal_seed_works_with_overflow_checking', First.Snapshot.ActiveBricks = 96);
  finally
    First.Free;
  end;
  Config := TGameConfig.Default;
  Config.InitialLives := 0;
  Valid := False;
  try
    First := TGame.Create(Config, 0);
    First.Free;
  except
    on E: EArgumentException do Valid := True;
  end;
  Check('invalid_configuration_is_rejected', Valid);
end;

function TEngineTests.Run(const OutputDirectory: string): Boolean;
var
  Report: TJSONObject;
begin
  FResults := TJSONArray.Create;
  Report := TJSONObject.Create;
  try
    try
      States;
      LivesAndPoints;
      Completion;
      Determinism;
    except
      on E: Exception do Check('unhandled_exception', False, E.ClassName + ': ' + E.Message);
    end;
    Result := FFailures = 0;
    Report.AddPair('suite', 'E3 engine flow regressions without VCL');
    Report.AddPair('passed', TJSONBool.Create(Result));
    Report.AddPair('checks', TJSONNumber.Create(FResults.Count));
    Report.AddPair('failures', TJSONNumber.Create(FFailures));
    Report.AddPair('results', FResults);
    FResults := nil;
    ForceDirectories(OutputDirectory);
    TFile.WriteAllText(TPath.Combine(OutputDirectory, 'engine.json'), Report.Format, TEncoding.UTF8);
  finally
    FResults.Free;
    Report.Free;
  end;
end;

function RunEngineTests(const OutputDirectory: string): Boolean;
var
  Tests: TEngineTests;
begin
  Tests := TEngineTests.Create;
  try
    Result := Tests.Run(OutputDirectory);
  finally
    Tests.Free;
  end;
end;

end.
