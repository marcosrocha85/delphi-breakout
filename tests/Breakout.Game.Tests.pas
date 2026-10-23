unit Breakout.Game.Tests;

interface

function RunEngineTests(const OutputDirectory: string): Boolean;

implementation

uses System.SysUtils, System.JSON, System.IOUtils, System.Math,
  Breakout.Types, Breakout.Game, Breakout.Levels, Breakout.Bricks, Breakout.TestScenarios;

type
  TEngineTests = class
  private
    FResults: TJSONArray;
    FBalance: TJSONArray;
    FFailures: Integer;
    procedure Check(const Name: string; Passed: Boolean; const Detail: string = '');
    procedure States;
    procedure LivesAndPoints;
    procedure Completion;
    procedure Determinism;
    procedure Campaign;
    procedure LevelDefinitions;
    procedure ClassBalance;
    procedure SpeedPolicy;
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
    Check('hit_deactivates_brick_and_adds_its_points', (View.Score = 100) and
      (View.ActiveBricks = 1) and not View.Bricks[0].Active and
      (View.LastHitBrickId = 0));
    Check('inactive_brick_retains_stable_id_and_slot',
      (Length(View.Bricks) = 2) and (View.Bricks[0].Id = 0) and (View.Bricks[1].Id = 1));
    Game.PlaceBall(310, 82);
    Game.Step;
    Check('inactive_brick_cannot_score_again', Game.Snapshot.Score = 100);
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
      (Before.ActiveBricks = 0) and (Before.Score = 100) and (Before.Lives = 2));
    Check('completion_terminates_the_step', (Before.Ball.X = 310) and SameValue(Before.Ball.Y, 83, 0.00001) and (Before.Ball.VelocityY < 0));
    Game.Step;
    Game.Execute(gcDebugStep);
    Game.Execute(gcTogglePause);
    Game.MovePaddle(0);
    After := Game.Snapshot;
    Check('level_complete_waits_without_moving_or_scoring',
      (After.State = gsLevelComplete) and (After.Score = 100) and
      (After.Ball.X = Before.Ball.X) and (After.Ball.Y = Before.Ball.Y));
    Game.Execute(gcLaunch);
    After := Game.Snapshot;
    Check('continue_loads_next_level_ready_preserving_lives_and_score',
      (After.State = gsReady) and (After.Level = 2) and (After.Score = 100) and
      (After.Lives = 2) and (After.ActiveBricks = 20));
    Game.Execute(gcLaunch);
    Game.Fixture(True);
    Game.SetBall(310, 82, 0, 240);
    Game.Step;
    After := Game.Snapshot;
    Check('last_level_enters_victory', (After.State = gsVictory) and
      (After.Score = 200) and (After.Lives = 2) and (After.Level = 2));
    Game.Execute(gcLaunch);
    Game.Execute(gcTogglePause);
    Game.Execute(gcDebugStep);
    Game.Step;
    Check('victory_ignores_launch_pause_and_steps', (Game.Snapshot.State = gsVictory) and
      (Game.Snapshot.Score = 200) and (Game.Snapshot.Ball.X = 310));
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
const
  ExpectedPoints: array[TBrickKind] of Integer = (100, 150, 200, 250, 400, 500);
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
          (A.Bricks[I].Points = ExpectedPoints[A.Bricks[I].Kind]);
      end;
      Check('same_seed_generates_same_board_and_launch', Same);
      Check('board_has_unique_stable_ids_and_valid_points', Valid);
      Other := GenerateLevel(54321, 1);
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

procedure TEngineTests.LevelDefinitions;
const
  ExpectedMaps: array[2..3, 0..4] of string = (
    ('.##......##.', '.##......##.', '.##..##..##.', '.##..##..##.', '............'),
    ('.....##.....', '....####....', '..########..', '....####....', '.....##.....'));
var
  A, B, Geometry, Other: TArray<TBrick>;
  I, J, Row, Col, Slot, Level: Integer;
  Valid, Same, Raised, SameGeometry, Different: Boolean;
  Definition: TBrickDefinition;
begin
  for Level := 1 to CampaignLevelCount do
  begin
    A := GenerateLevel(12345, Level);
    B := GenerateLevel(12345, Level);
    Other := GenerateLevel(54321, Level);
    Different := False;
    Same := Length(A) = Length(B);
    Valid := ((Level = 1) and (Length(A) = 96)) or
      ((Level > 1) and (Length(A) = 20));
    for I := 0 to High(A) do
    begin
      Definition := BrickDefinition(A[I].Kind);
      Different := Different or (A[I].Kind <> Other[I].Kind);
      Same := Same and (A[I].X = B[I].X) and (A[I].Y = B[I].Y) and
        (A[I].Kind = B[I].Kind) and (A[I].Points = B[I].Points) and
        (A[I].SpriteIndex = B[I].SpriteIndex) and (A[I].Id = B[I].Id) and
        (A[I].Width = B[I].Width) and (A[I].Height = B[I].Height) and
        (A[I].Active = B[I].Active);
      Valid := Valid and (A[I].Id = I) and A[I].Active and
        (A[I].Points = Definition.Points) and (A[I].SpriteIndex = Definition.SpriteIndex) and
        (A[I].X >= 0) and (A[I].X + A[I].Width <= 688) and (A[I].Y >= 0) and
        (A[I].Y + A[I].Height < 395) and (A[I].Width > 0) and (A[I].Height > 0);
      for J := 0 to I - 1 do
        Valid := Valid and ((A[I].X >= B[J].X + B[J].Width) or
          (A[I].X + A[I].Width <= B[J].X) or (A[I].Y >= B[J].Y + B[J].Height) or
          (A[I].Y + A[I].Height <= B[J].Y));
    end;
    Check('level_' + IntToStr(Level) + '_same_seed_repeats_classes_and_geometry', Same);
    Check('level_' + IntToStr(Level) + '_geometry_ids_rewards', Valid);
    Check('level_' + IntToStr(Level) + '_different_seed_changes_classes', Different);
    SameGeometry := True;
    if Level = 1 then
    begin
      Geometry := GenerateLegacyLevel(12345, 1);
      for I := 0 to High(A) do
        SameGeometry := SameGeometry and (A[I].X = Geometry[I].X) and
          (A[I].Y = Geometry[I].Y) and (A[I].Width = Geometry[I].Width) and
          (A[I].Height = Geometry[I].Height) and (A[I].Id = Geometry[I].Id);
    end
    else
    begin
      Slot := 0;
      for Row := 0 to 4 do
        for Col := 1 to 12 do
          if ExpectedMaps[Level, Row][Col] = '#' then
          begin
            SameGeometry := SameGeometry and (Slot < Length(A));
            if Slot < Length(A) then
              SameGeometry := SameGeometry and (A[Slot].X = 10 + (Col - 1) * 56) and
                (A[Slot].Y = 40 + Row * 24) and (A[Slot].Width = 50) and
                (A[Slot].Height = 20) and (A[Slot].Id = Slot);
            Inc(Slot);
          end;
      SameGeometry := SameGeometry and (Slot = Length(A));
    end;
    Check('level_' + IntToStr(Level) + '_preserves_approved_formation', SameGeometry);
    A[0].Active := False;
    A := GenerateLevel(12345, Level);
    Check('level_' + IntToStr(Level) + '_fresh_array', A[0].Active and B[0].Active);
  end;
  for Level := 0 to CampaignLevelCount + 1 do
    if (Level = 0) or (Level > CampaignLevelCount) then
    begin
      Raised := False;
      try A := GenerateLevel(1, Level);
      except on E: EArgumentOutOfRangeException do Raised := True; end;
      Check('unsupported_level_' + IntToStr(Level) + '_rejected', Raised);
    end;
end;

procedure TEngineTests.ClassBalance;
const
  SeedCount = 1024;
  BandNames: array[0..2] of string = ('top', 'middle', 'bottom');
type
  TBandCounts = record
    Count, Points, LowValue, MiddleValue, Premium: Integer;
    Classes: array[TBrickKind] of Integer;
  end;
var
  Counts: array[0..2] of TBandCounts;
  A: TArray<TBrick>;
  Seed, Level, I, J, Band: Integer;
  Kind: TBrickKind;
  Top, Bottom, DX, DY: Double;
  SideSafe, MixedDiagonal, AllClasses: Boolean;
  PremiumRates: array[0..2] of Double;
  LevelReport, BandReport, ClassReport: TJSONObject;
  Bands: TJSONArray;
begin
  for Level := 1 to CampaignLevelCount do
  begin
    FillChar(Counts, SizeOf(Counts), 0);
    SideSafe := True;
    MixedDiagonal := False;
    for Seed := 0 to SeedCount - 1 do
    begin
      A := GenerateLevel(Cardinal(Seed), Level);
      Top := A[0].Y;
      Bottom := A[High(A)].Y;
      for I := 0 to High(A) do
      begin
        { Independent row-center classification over occupied rows. }
        Band := Trunc(3 * (A[I].Y - Top + 12) / (Bottom - Top + 24));
        Inc(Counts[Band].Count);
        Inc(Counts[Band].Points, A[I].Points);
        Inc(Counts[Band].Classes[A[I].Kind]);
        if A[I].Kind in [bkGreen, bkYellow] then Inc(Counts[Band].LowValue);
        if A[I].Kind in [bkYellow, bkCyan, bkRed] then Inc(Counts[Band].MiddleValue);
        if not (A[I].Kind in [bkSilver, bkGold]) then Continue;
        Inc(Counts[Band].Premium);
        for J := 0 to I - 1 do
          if A[J].Kind in [bkSilver, bkGold] then
          begin
            DX := Abs(A[I].X - A[J].X);
            DY := Abs(A[I].Y - A[J].Y);
            SideSafe := SideSafe and not (((DX = 56) and (DY = 0)) or
              ((DX = 0) and (DY = 24)));
            if (DX = 56) and (DY = 24) and (A[I].Kind <> A[J].Kind) then
              MixedDiagonal := True;
          end;
      end;
    end;
    Check('balance_' + IntToStr(Level) + '_1024_seeds_no_premium_side_neighbors', SideSafe);
    Check('balance_' + IntToStr(Level) + '_allows_silver_gold_diagonals', MixedDiagonal);
    AllClasses := True;
    for Band := 0 to 2 do
    begin
      PremiumRates[Band] := Counts[Band].Premium / Counts[Band].Count;
      for Kind := Low(TBrickKind) to High(TBrickKind) do
        AllClasses := AllClasses and (Counts[Band].Classes[Kind] > 0);
    end;
    Check('balance_' + IntToStr(Level) + '_all_classes_possible_in_each_band', AllClasses);
    Check('balance_' + IntToStr(Level) + '_bottom_predominantly_green_yellow',
      Counts[2].LowValue / Counts[2].Count > 0.85);
    Check('balance_' + IntToStr(Level) + '_bottom_cheaper_than_top',
      Counts[2].LowValue / Counts[2].Count > Counts[0].LowValue / Counts[0].Count + 0.3);
    Check('balance_' + IntToStr(Level) + '_premium_more_likely_at_top',
      (PremiumRates[0] > 2 * PremiumRates[1]) and (PremiumRates[0] > 3 * PremiumRates[2]));
    Check('balance_' + IntToStr(Level) + '_middle_predominantly_yellow_cyan_red',
      Counts[1].MiddleValue / Counts[1].Count > 0.7);
    Check('balance_' + IntToStr(Level) + '_mean_reward_increases_upwards',
      (Counts[0].Points / Counts[0].Count > Counts[1].Points / Counts[1].Count + 15) and
      (Counts[1].Points / Counts[1].Count > Counts[2].Points / Counts[2].Count + 15));
    LevelReport := TJSONObject.Create;
    LevelReport.AddPair('level', TJSONNumber.Create(Level));
    LevelReport.AddPair('seeds', TJSONNumber.Create(SeedCount));
    Bands := TJSONArray.Create;
    LevelReport.AddPair('bands', Bands);
    FBalance.AddElement(LevelReport);
    for Band := 0 to 2 do
    begin
      BandReport := TJSONObject.Create;
      BandReport.AddPair('band', BandNames[Band]);
      BandReport.AddPair('bricks', TJSONNumber.Create(Counts[Band].Count));
      BandReport.AddPair('mean_points', TJSONNumber.Create(Counts[Band].Points / Counts[Band].Count));
      BandReport.AddPair('premium_fraction', TJSONNumber.Create(PremiumRates[Band]));
      ClassReport := TJSONObject.Create;
      BandReport.AddPair('class_counts_green_yellow_cyan_red_silver_gold', ClassReport);
      for Kind := Low(TBrickKind) to High(TBrickKind) do
        ClassReport.AddPair(IntToStr(Ord(Kind)), TJSONNumber.Create(Counts[Band].Classes[Kind]));
      Bands.AddElement(BandReport);
    end;
  end;
end;

procedure TEngineTests.Campaign;
var
  Game: TGameProbe;
  Board: TArray<TBrick>;
  Before, After: TGameSnapshot;
  I, Level, ExpectedScore: Integer;
  Valid: Boolean;
begin
  Game := TGameProbe.Create(TGameConfig.Default, 12345);
  try
    ExpectedScore := 0;
    for Level := 1 to CampaignLevelCount do
    begin
      Before := Game.Snapshot;
      Check('campaign_ready_' + IntToStr(Level), (Before.State = gsReady) and
        (Before.Level = Level) and (Before.LevelCount = CampaignLevelCount) and
        (Before.Score = ExpectedScore) and (Before.Lives = 4 - Level) and
        SameValue(Hypot(Before.Ball.VelocityX, Before.Ball.VelocityY),
          240 * Power(1.05, Level - 1), 1.0E-8));
      Game.Execute(gcLaunch);
      Board := Before.Bricks;
      Valid := True;
      { Arrange isolated top impacts on every real campaign brick, in row order.
        The board is never replaced; this verifies generation + collision + flow. }
      for I := 0 to High(Board) do
      begin
        Game.SetBall(Board[I].X + (Board[I].Width - Before.Ball.Size) / 2,
          Board[I].Y - Before.Ball.Size - 1, 0, 240);
        Game.Step;
        Inc(ExpectedScore, Board[I].Points);
        After := Game.Snapshot;
        Valid := Valid and not After.Bricks[I].Active and
          (After.Score = ExpectedScore) and (After.ActiveBricks = Length(Board) - I - 1);
      end;
      Check('campaign_all_bricks_score_once_' + IntToStr(Level), Valid);
      if Level < CampaignLevelCount then
      begin
        Check('campaign_explicit_completion_' + IntToStr(Level), After.State = gsLevelComplete);
        Game.Execute(gcLaunch);
        Check('campaign_continue_does_not_launch_' + IntToStr(Level), Game.State = gsReady);
        Game.Execute(gcLaunch);
        Game.PrepareFall;
        Game.Step;
        After := Game.Snapshot;
        Check('campaign_loss_preserves_score_level_speed_' + IntToStr(Level),
          (After.State = gsReady) and (After.Score = ExpectedScore) and
          (After.Level = Level + 1) and (After.Lives = 3 - Level) and
          SameValue(Hypot(After.Ball.VelocityX, After.Ball.VelocityY),
            240 * Power(1.05, Level), 1.0E-8));
      end;
    end;
    Before := Game.Snapshot;
    Game.Execute(gcLaunch); Game.Execute(gcDeactivate);
    Game.Execute(gcTogglePause); Game.Execute(gcDebugStep); Game.Step;
    After := Game.Snapshot;
    Check('campaign_final_victory_is_terminal', (After.State = gsVictory) and
      (After.Score = ExpectedScore) and (After.Level = 3) and (After.Lives = 1) and
      (Before.Ball.X = After.Ball.X) and (Before.Ball.Y = After.Ball.Y));
    Game.Execute(gcRestart);
    After := Game.Snapshot;
    Check('campaign_restart_restores_board_speed_and_counters', (After.State = gsReady) and
      (After.Level = 1) and (After.Lives = 3) and (After.Score = 0) and
      (After.ActiveBricks = 96) and (After.LastHitBrickId = -1) and
      SameValue(Hypot(After.Ball.VelocityX, After.Ball.VelocityY), 240, 1.0E-8));
  finally Game.Free; end;
end;

procedure TEngineTests.SpeedPolicy;
var
  Config: TGameConfig;
  Game: TGameProbe;
  View: TGameSnapshot;
  I, Level: Integer;
  Raised: Boolean;
begin
  for I := 0 to 2 do
  begin
    Config := TGameConfig.Default;
    case I of
      0: Config.MaxBallSpeed := 250;
      1: Config.LevelSpeedIncrease := 0;
      2: Config.LevelSpeedIncrease := 1.0E300;
    end;
    Game := TGameProbe.Create(Config, 1);
    try
      for Level := 1 to CampaignLevelCount do
      begin
        View := Game.Snapshot;
        if (Level = 1) or (I = 1) then
          Check('speed_policy_' + IntToStr(I) + '_level_' + IntToStr(Level),
            SameValue(Hypot(View.Ball.VelocityX, View.Ball.VelocityY), 240, 1.0E-8))
        else Check('speed_policy_' + IntToStr(I) + '_level_' + IntToStr(Level),
          SameValue(Hypot(View.Ball.VelocityX, View.Ball.VelocityY), Config.MaxBallSpeed, 1.0E-8));
        Game.Execute(gcLaunch); Game.Fixture(True); Game.SetBall(310, 82, 0, 240); Game.Step;
        if Level < CampaignLevelCount then Game.Execute(gcLaunch);
      end;
    finally Game.Free; end;
  end;
  for I := 0 to 6 do
  begin
    Config := TGameConfig.Default;
    case I of
      0: Config.LevelCount := CampaignLevelCount + 1;
      1: Config.LevelSpeedIncrease := -0.05;
      2: Config.LevelSpeedIncrease := NaN;
      3: Config.LevelSpeedIncrease := Infinity;
      4: Config.MaxBallSpeed := Config.BallSpeed - 1;
      5: Config.MaxBallSpeed := NaN;
      6: Config.MaxBallSpeed := Infinity;
    end;
    Raised := False;
    try Game := TGameProbe.Create(Config, 1); Game.Free;
    except on E: EArgumentException do Raised := True; end;
    Check('invalid_campaign_config_' + IntToStr(I) + '_rejected', Raised);
  end;
end;

function TEngineTests.Run(const OutputDirectory: string): Boolean;
var
  Report: TJSONObject;
begin
  FResults := TJSONArray.Create;
  FBalance := TJSONArray.Create;
  Report := TJSONObject.Create;
  try
    try
      States;
      LivesAndPoints;
      Completion;
      Determinism;
      LevelDefinitions;
      ClassBalance;
      Campaign;
      SpeedPolicy;
    except
      on E: Exception do Check('unhandled_exception', False, E.ClassName + ': ' + E.Message);
    end;
    Result := FFailures = 0;
    Report.AddPair('suite', 'E5 campaign and engine regressions without VCL');
    Report.AddPair('passed', TJSONBool.Create(Result));
    Report.AddPair('checks', TJSONNumber.Create(FResults.Count));
    Report.AddPair('failures', TJSONNumber.Create(FFailures));
    Report.AddPair('results', FResults);
    FResults := nil;
    Report.AddPair('class_balance', FBalance);
    FBalance := nil;
    ForceDirectories(OutputDirectory);
    TFile.WriteAllText(TPath.Combine(OutputDirectory, 'engine.json'), Report.Format, TEncoding.UTF8);
  finally
    FResults.Free;
    FBalance.Free;
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
