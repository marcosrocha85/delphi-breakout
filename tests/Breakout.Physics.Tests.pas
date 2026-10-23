unit Breakout.Physics.Tests;

interface

function RunPhysicsTests(const OutputDirectory: string): Boolean;

implementation

uses System.SysUtils, System.Math, System.JSON, System.IOUtils,
  Breakout.Types, Breakout.Physics, Breakout.Game, Breakout.Loop,
  Breakout.TestScenarios;

type
  TPhysicsTests = class
  private
    FResults: TJSONArray;
    FFailures: Integer;
    procedure Check(const Name: string; Passed: Boolean; const Detail: string = '');
    procedure Geometry;
    procedure Impacts;
    procedure Paddle;
    procedure Timing;
    procedure Replay;
  public
    function Run(const OutputDirectory: string): Boolean;
  end;

function Near(A, B: Double): Boolean;
begin
  Result := Abs(A - B) < 0.00001;
end;

procedure TPhysicsTests.Check(const Name: string; Passed: Boolean; const Detail: string);
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

procedure TPhysicsTests.Geometry;
var
  Rect: TPhysicsRect;
  Hit: TCircleHit;
  I, SX, SY: Integer;
  X, Y, VX, VY, CornerX, CornerY: Double;
begin
  Rect := TPhysicsRect.Create(100, 100, 50, 20);
  Check('geometry_left_face_time_and_normal',
    SweepCircleRect(80, 110, 5, 100, 0, 1, Rect, Hit) and
    Near(Hit.Time, 0.15) and Near(Hit.NormalX, -1) and Near(Hit.NormalY, 0));
  Check('geometry_right_face_time_and_normal',
    SweepCircleRect(170, 110, 5, -100, 0, 1, Rect, Hit) and
    Near(Hit.Time, 0.15) and Near(Hit.NormalX, 1) and Near(Hit.NormalY, 0));
  Check('geometry_top_face_time_and_normal',
    SweepCircleRect(125, 80, 5, 0, 100, 1, Rect, Hit) and
    Near(Hit.Time, 0.15) and Near(Hit.NormalX, 0) and Near(Hit.NormalY, -1));
  Check('geometry_bottom_face_time_and_normal',
    SweepCircleRect(125, 140, 5, 0, -100, 1, Rect, Hit) and
    Near(Hit.Time, 0.15) and Near(Hit.NormalX, 0) and Near(Hit.NormalY, 1));
  for I := 0 to 3 do
  begin
    if I mod 2 = 0 then SX := -1 else SX := 1;
    if I div 2 = 0 then SY := -1 else SY := 1;
    if SX < 0 then CornerX := 100 else CornerX := 150;
    if SY < 0 then CornerY := 100 else CornerY := 120;
    X := CornerX + SX * 10;
    Y := CornerY + SY * 10;
    VX := -SX * 10;
    VY := -SY * 10;
    Check('geometry_circular_corner_' + IntToStr(I),
      SweepCircleRect(X, Y, 5, VX, VY, 1, Rect, Hit) and
      Near(Hit.Time, 1 - 1 / Sqrt(8)) and
      Near(Hit.NormalX, SX / Sqrt(2)) and Near(Hit.NormalY, SY / Sqrt(2)));
    ReflectVelocity(VX, VY, Hit.NormalX, Hit.NormalY);
    Check('corner_reflection_preserves_speed_' + IntToStr(I),
      Near(VX, SX * 10) and Near(VY, SY * 10) and Near(Hypot(VX, VY), Sqrt(200)));
  end;
  Check('expanded_aabb_corner_is_not_a_circle_contact',
    not SweepCircleRect(95.1, 95.1, 5, -10, 0, 0.1, Rect, Hit));
  Check('swept_near_corner_miss_has_no_false_contact',
    not SweepCircleRect(94, 95.1, 5, 1, 0, 1, Rect, Hit));
  Check('exact_tangent_does_not_reflect_or_stick',
    not SweepCircleRect(90, 95, 5, 100, 0, 0.6, Rect, Hit));
  Check('stationary_noncontact_has_no_hit',
    not SweepCircleRect(80, 110, 5, 0, 0, 1, Rect, Hit));
  Check('moving_away_from_touching_face_has_no_hit',
    not SweepCircleRect(95, 110, 5, -100, 0, 1, Rect, Hit));
  Check('initial_overlap_returns_minimum_separation',
    SweepCircleRect(98, 110, 5, -100, 0, 1, Rect, Hit) and
    Near(Hit.Time, 0) and Near(Hit.Penetration, 3) and Near(Hit.NormalX, -1));
  VX := -100;
  VY := 20;
  ReflectVelocity(VX, VY, Hit.NormalX, Hit.NormalY);
  Check('separating_overlap_preserves_outward_velocity', Near(VX, -100) and Near(VY, 20));
  Check('center_inside_rectangle_has_deterministic_exit',
    SweepCircleRect(125, 110, 5, 0, 0, 1, Rect, Hit) and
    Near(Hit.Penetration, 15) and Near(Hit.NormalY, -1));
  Check('contact_after_time_window_is_rejected',
    not SweepCircleRect(80, 110, 5, 100, 0, 0.1, Rect, Hit));
  Rect := TPhysicsRect.Create(300, 420, 50, 15);
  Check('rounded_paddle_center_has_flat_top',
    SweepCirclePaddle(325, 400, 8.5, 0, 240, 0.1, Rect, Hit) and
    Near(Hit.Time, 11.5 / 240) and Near(Hit.NormalY, -1));
  Check('rounded_paddle_left_tip_uses_combined_radii',
    SweepCirclePaddle(300, 400, 8.5, 0, 240, 0.1, Rect, Hit) and
    Near(Hit.Time, (27.5 - Sqrt(256 - 56.25)) / 240) and (Hit.NormalX < 0));
  Check('rounded_paddle_right_tip_is_symmetric',
    SweepCirclePaddle(350, 400, 8.5, 0, 240, 0.1, Rect, Hit) and
    Near(Hit.Time, (27.5 - Sqrt(256 - 56.25)) / 240) and (Hit.NormalX > 0));
  Check('empty_paddle_bounding_box_corner_does_not_bounce',
    not SweepCirclePaddle(292, 412, 8.5, -20, 20, 0.01, Rect, Hit));
end;

procedure TPhysicsTests.Impacts;
var
  Game: TGameProbe;
  View: TGameSnapshot;
  Bricks: TArray<TBrick>;
  I, Direction: Integer;
begin
  Game := TGameProbe.Create(TGameConfig.Default, 123);
  try
    for I := 0 to 5 do
    begin
      Game.Execute(gcRestart);
      Game.Fixture;
      Game.Execute(gcLaunch);
      case I of
        0: Game.SetBall(310, 82, 120, 600); // descending into top
        1: Game.SetBall(310, 122, -120, -600); // rising into bottom
        2: Game.SetBall(280, 100, 600, 120);
        3: Game.SetBall(280, 100, 600, -120);
        4: Game.SetBall(353, 100, -600, 120);
        5: Game.SetBall(353, 100, -600, -120);
      end;
      Game.Step;
      View := Game.Snapshot;
      Check('brick_face_' + IntToStr(I) + '_scores_once',
        (View.Score = 10) and (View.ActiveBricks = 1) and not View.Bricks[0].Active);
      case I of
        0: Check('descending_ball_bounces_up_from_top', Near(View.Ball.VelocityX, 120) and
          Near(View.Ball.VelocityY, -600) and (View.Ball.Y < 83));
        1: Check('rising_ball_bounces_down_from_bottom', Near(View.Ball.VelocityX, -120) and
          Near(View.Ball.VelocityY, 600) and (View.Ball.Y > 120));
      else
        if I < 4 then Direction := -1 else Direction := 1;
        Check('lateral_face_' + IntToStr(I) + '_reverses_only_horizontal',
          Near(View.Ball.VelocityX, Direction * 600) and
          Near(View.Ball.VelocityY, IfThen(I mod 2 = 0, 120.0, -120.0)));
      end;
      Game.SetBall(310, 82, 0, 600);
      Game.Step;
      Check('removed_brick_' + IntToStr(I) + '_cannot_score_or_bounce_again',
        (Game.Snapshot.Score = 10) and Near(Game.Snapshot.Ball.VelocityY, 600));
    end;
    Game.Execute(gcRestart);
    Game.Fixture;
    Game.Execute(gcLaunch);
    Game.SetBall(310, 30, 0, 12000);
    Game.Step;
    View := Game.Snapshot;
    Check('high_speed_top_hit_does_not_tunnel', (View.Score = 10) and
      (View.Ball.VelocityY < 0) and (View.Ball.Y < 83));
    Game.Execute(gcRestart);
    Game.Fixture;
    Game.Execute(gcLaunch);
    Game.SetBall(200, 100, 20000, 0);
    Game.Step;
    Check('high_speed_side_hit_uses_remaining_time_after_bounce',
      (Game.Snapshot.Score = 10) and Near(Game.Snapshot.Ball.VelocityX, -20000) and
      (Game.Snapshot.Ball.X < 283));
    Game.Execute(gcRestart);
    Game.Fixture;
    Game.Execute(gcLaunch);
    Game.SetBall(310, 84, 0, -240);
    Game.Step;
    Check('initial_overlap_separates_without_inverting_outward_ball',
      (Game.Snapshot.Score = 10) and (Game.Snapshot.Ball.Y < 83) and
      Near(Game.Snapshot.Ball.VelocityY, -240));
    Game.Execute(gcRestart);
    Game.Fixture;
    Bricks := Game.Snapshot.Bricks;
    SetLength(Bricks, 3);
    Bricks[2] := Bricks[1];
    Bricks[2].Id := 2;
    Bricks[1] := Bricks[0];
    Bricks[1].Id := 1;
    Bricks[1].X := 350;
    Game.SetBricks(Bricks);
    Game.Execute(gcLaunch);
    Game.SetBall(341.5, 82, 0, 600);
    Game.Step;
    View := Game.Snapshot;
    Check('seam_hits_both_bricks_but_reflects_once', (View.Score = 20) and
      (View.ActiveBricks = 1) and Near(View.Ball.VelocityY, -600) and
      (View.LastHitBrickId = 1));
    Game.Execute(gcRestart);
    Game.Fixture;
    Game.Execute(gcLaunch);
    Game.SetBall(1, 1, -600, -600);
    Game.Step;
    Check('simultaneous_left_top_wall_contact_reflects_both_axes',
      Near(Game.Snapshot.Ball.VelocityX, 600) and Near(Game.Snapshot.Ball.VelocityY, 600) and
      (Game.Snapshot.Ball.X > 0) and (Game.Snapshot.Ball.Y > 0));
    Game.SetBall(670, 250, 600, 0);
    Game.Step;
    Check('right_wall_reflects_inside_field', Near(Game.Snapshot.Ball.VelocityX, -600) and
      (Game.Snapshot.Ball.X < 671));
    Game.SetBall(300, 250, 12000000, 0);
    Game.Step;
    View := Game.Snapshot;
    Check('collision_budget_stops_at_safe_contact_and_reports_discard',
      (View.CollisionLimitCount = 1) and (View.CollisionDiscardedSeconds > 0) and
      (View.Ball.X >= 0) and (View.Ball.X <= 671));
    Game.Execute(gcRestart);
    Game.Execute(gcLaunch);
    Game.SetBall(335.5, 440, 0, 240);
    Game.Step;
    Check('ball_below_paddle_is_not_rescued_and_not_lost_early',
      (Game.Snapshot.Lives = 3) and Near(Game.Snapshot.Ball.VelocityY, 240));
    Game.SetBall(335.5, 452, 0, 240);
    Game.Step;
    Check('lower_loss_line_works_even_directly_under_paddle',
      (Game.State = gsReady) and (Game.Snapshot.Lives = 2) and
      Near(Game.Snapshot.Ball.Y, 395));
  finally
    Game.Free;
  end;
end;

procedure TPhysicsTests.Paddle;
var
  Game: TGameProbe;
  View: TGameSnapshot;
  I: Integer;
  Offset, Angle, LastAngle, X, VX, VY: Double;
begin
  LastAngle := -90;
  for I := -4 to 4 do
  begin
    Offset := I / 4;
    PaddleVelocity(Offset, 240, 120, 5, 60, VX, VY);
    Angle := RadToDeg(ArcTan2(VX, -VY));
    Check('paddle_angle_' + IntToStr(I) + '_speed_and_vertical_bounds',
      Near(Hypot(VX, VY), 240) and (VY <= -120 + 0.00001) and (Angle > LastAngle));
    if I <> 0 then Check('paddle_angle_' + IntToStr(I) + '_proportional', Near(Angle, Offset * 60));
    LastAngle := Angle;
  end;
  PaddleVelocity(0, 240, -120, 5, 60, VX, VY);
  Check('paddle_center_preserves_incoming_left_sign_and_min_angle',
    Near(RadToDeg(ArcTan2(VX, -VY)), -5));
  PaddleVelocity(0, 240, 120, 5, 60, VX, VY);
  Check('paddle_center_preserves_incoming_right_sign_and_min_angle',
    Near(RadToDeg(ArcTan2(VX, -VY)), 5));
  Game := TGameProbe.Create(TGameConfig.Default, 123);
  try
    for I := -1 to 1 do
    begin
      Game.Execute(gcRestart);
      Game.Execute(gcLaunch);
      X := 344 + I * 20 - 8.5;
      Game.SetBall(X, 402, 0, 240);
      Game.Step;
      View := Game.Snapshot;
      Check('paddle_actual_contact_' + IntToStr(I), (View.Ball.VelocityY < 0) and
        Near(Hypot(View.Ball.VelocityX, View.Ball.VelocityY), 240) and
        (View.Ball.Y < 403) and (View.Lives = 3));
      if I <> 0 then Check('paddle_actual_offset_' + IntToStr(I),
        Near(RadToDeg(ArcTan2(View.Ball.VelocityX, -View.Ball.VelocityY)), I * 48));
    end;
    Game.SetBall(335.5, 404, 0, -240);
    Game.Step;
    Check('ascending_ball_is_not_reflected_by_paddle', Near(Game.Snapshot.Ball.VelocityY, -240));
    Game.SetBall(335.5, 350, 0, 10000);
    Game.Step;
    Check('fast_ball_cannot_tunnel_through_paddle', (Game.Snapshot.Ball.VelocityY < 0) and
      (Game.Snapshot.Lives = 3));
  finally
    Game.Free;
  end;
end;

procedure TPhysicsTests.Timing;
const
  Rates: array[0..2] of Integer = (30, 60, 144);
var
  Game: TGameProbe;
  Loop: TGameLoop;
  Reference, View, Before: TGameSnapshot;
  I, Frame, Second: Integer;
  Count: Int64;
  Config: TGameConfig;
  Same: Boolean;
begin
  Reference := Default(TGameSnapshot);
  for I := 0 to High(Rates) do
  begin
    Config := TGameConfig.Default;
    Config.Height := 5000;
    Config.PaddleY := 4900;
    Game := TGameProbe.Create(Config, 12345);
    Game.Fixture;
    Game.SetBall(310, 82, 120, 240);
    Loop := TGameLoop.Create(Game);
    try
      Loop.Execute(gcLaunch);
      for Second := 1 to 3 do
      begin
        Game.MovePaddle(200 + Second * 40); // same input at shared time boundaries
        for Frame := 1 to Rates[I] do Loop.Advance(1.0 / Rates[I]);
      end;
      View := Game.Snapshot;
      Check('schedule_' + IntToStr(Rates[I]) + '_runs_360_fixed_steps',
        (Loop.Diagnostics.TotalSteps = 360) and (Loop.Diagnostics.LimitedCallbacks = 0));
      if I = 0 then Reference := View
      else
      begin
        Same := Near(View.Ball.X, Reference.Ball.X) and Near(View.Ball.Y, Reference.Ball.Y) and
          Near(View.Ball.VelocityX, Reference.Ball.VelocityX) and
          Near(View.Ball.VelocityY, Reference.Ball.VelocityY) and
          (View.State = Reference.State) and (View.Score = Reference.Score) and
          (View.Lives = Reference.Lives);
        for Frame := 0 to High(View.Bricks) do
          Same := Same and (View.Bricks[Frame].Active = Reference.Bricks[Frame].Active);
        Check('schedule_' + IntToStr(Rates[I]) + '_matches_30hz_trajectory_and_board', Same);
      end;
    finally
      Loop.Free;
      Game.Free;
    end;
  end;
  Game := TGameProbe.Create(TGameConfig.Default, 123);
  Loop := TGameLoop.Create(Game);
  try
    Loop.Execute(gcLaunch);
    Loop.Advance(1.5);
    Check('long_callback_accepts_100ms_at_most_12_steps_reports_1400ms_discard',
      (Loop.Diagnostics.LastSteps = 12) and (Loop.Diagnostics.TotalSteps = 12) and
      (Loop.Diagnostics.LimitedCallbacks = 1) and Near(Loop.Diagnostics.DiscardedSeconds, 1.4));
    Loop.Advance(FixedDeltaSeconds / 2);
    Before := Game.Snapshot;
    Loop.Execute(gcTogglePause);
    Loop.Advance(30);
    Loop.Execute(gcTogglePause);
    Loop.Advance(FixedDeltaSeconds / 2);
    View := Game.Snapshot;
    Check('pause_discards_fraction_and_wall_time_without_jump',
      Near(View.Ball.X, Before.Ball.X) and Near(View.Ball.Y, Before.Ball.Y) and
      (Loop.Diagnostics.LastSteps = 0));
    Loop.Advance(FixedDeltaSeconds / 2);
    Check('resume_restarts_with_fresh_accumulator', Loop.Diagnostics.LastSteps = 1);
    Loop.Advance(FixedDeltaSeconds / 2);
    Loop.Execute(gcDeactivate);
    Loop.Execute(gcTogglePause);
    Loop.Advance(FixedDeltaSeconds / 2);
    Check('deactivation_resets_accumulator', Loop.Diagnostics.LastSteps = 0);
    Loop.Execute(gcRestart);
    Loop.Execute(gcLaunch);
    Loop.Advance(FixedDeltaSeconds / 2);
    Check('restart_resets_accumulator', Loop.Diagnostics.LastSteps = 0);
    Game.PrepareFall;
    Count := Loop.Diagnostics.TotalSteps;
    Loop.Advance(0.1);
    Check('life_loss_stops_catchup_after_one_step_and_resets_fraction',
      (Game.State = gsReady) and (Game.Snapshot.Lives = 2) and
      (Loop.Diagnostics.TotalSteps = Count + 1) and Near(Loop.Diagnostics.AccumulatorSeconds, 0));
    Loop.Execute(gcLaunch);
    Loop.Advance(FixedDeltaSeconds / 2);
    Check('life_relaunch_has_no_old_remainder', Loop.Diagnostics.LastSteps = 0);
    Game.Fixture(True);
    Game.SetBall(310, 82, 0, 600);
    Count := Loop.Diagnostics.TotalSteps;
    Loop.Advance(0.1);
    Check('victory_stops_catchup_and_clears_accumulator',
      (Game.State = gsVictory) and (Game.Snapshot.Score = 10) and
      (Loop.Diagnostics.TotalSteps = Count + 1) and Near(Loop.Diagnostics.AccumulatorSeconds, 0));
    Loop.Execute(gcRestart);
    Loop.Execute(gcLaunch);
    Loop.Execute(gcTogglePause);
    Before := Game.Snapshot;
    Loop.Execute(gcDebugStep);
    View := Game.Snapshot;
    Check('manual_step_is_one_120th_second_with_no_clock_debt',
      (Game.State = gsPaused) and Near(View.Ball.X - Before.Ball.X,
        Before.Ball.VelocityX / 120) and Near(Loop.Diagnostics.AccumulatorSeconds, 0));
  finally
    Loop.Free;
    Game.Free;
  end;
  Config := TGameConfig.Default;
  Config.LevelCount := 2;
  Game := TGameProbe.Create(Config, 1);
  Loop := TGameLoop.Create(Game);
  try
    Loop.Execute(gcLaunch);
    Game.Fixture(True);
    Game.SetBall(310, 82, 0, 600);
    Loop.Advance(0.1);
    Check('level_completion_stops_catchup_and_clears_fraction',
      (Game.State = gsLevelComplete) and (Loop.Diagnostics.LastSteps = 1) and
      Near(Loop.Diagnostics.AccumulatorSeconds, 0));
    Loop.Execute(gcLaunch);
    Loop.Execute(gcLaunch);
    Loop.Advance(FixedDeltaSeconds / 2);
    Check('next_level_launch_has_no_old_clock_debt', (Game.Snapshot.Level = 2) and
      (Loop.Diagnostics.LastSteps = 0));
  finally
    Loop.Free;
    Game.Free;
  end;
end;

procedure TPhysicsTests.Replay;
var
  Game: TGame;
  View: TGameSnapshot;
  Seed, Tick: Integer;
  Valid: Boolean;
begin
  for Seed := 1 to 10 do
  begin
    Game := TGame.Create(TGameConfig.Default, Cardinal(Seed));
    try
      Valid := True;
      for Tick := 1 to 3600 do
      begin
        if Game.State = gsReady then Game.Execute(gcLaunch);
        View := Game.Snapshot;
        Game.MovePaddle(View.Ball.X + View.Ball.Size / 2);
        Game.Step;
        View := Game.Snapshot;
        Valid := Valid and (View.CollisionLimitCount = 0) and
          not IsNan(View.Ball.X) and not IsNan(View.Ball.Y) and
          Near(Hypot(View.Ball.VelocityX, View.Ball.VelocityY), 240) and
          (View.Ball.X >= -PositionEpsilon) and (View.Ball.X <= 671 + PositionEpsilon) and
          (View.Ball.Y >= -PositionEpsilon) and (View.Lives > 0);
      end;
      Check('seed_' + IntToStr(Seed) + '_30s_replay_preserves_speed_bounds_and_collision_budget', Valid);
    finally
      Game.Free;
    end;
  end;
end;

function TPhysicsTests.Run(const OutputDirectory: string): Boolean;
var
  Report: TJSONObject;
begin
  FResults := TJSONArray.Create;
  Report := TJSONObject.Create;
  try
    try
      Geometry;
      Impacts;
      Paddle;
      Timing;
      Replay;
    except
      on E: Exception do Check('unhandled_physics_exception', False, E.ClassName + ': ' + E.Message);
    end;
    Result := FFailures = 0;
    Report.AddPair('suite', 'E3 continuous collisions and fixed timestep');
    Report.AddPair('passed', TJSONBool.Create(Result));
    Report.AddPair('checks', TJSONNumber.Create(FResults.Count));
    Report.AddPair('failures', TJSONNumber.Create(FFailures));
    Report.AddPair('results', FResults);
    FResults := nil;
    ForceDirectories(OutputDirectory);
    TFile.WriteAllText(TPath.Combine(OutputDirectory, 'physics.json'), Report.Format, TEncoding.UTF8);
  finally
    FResults.Free;
    Report.Free;
  end;
end;

function RunPhysicsTests(const OutputDirectory: string): Boolean;
var
  Tests: TPhysicsTests;
begin
  Tests := TPhysicsTests.Create;
  try
    Result := Tests.Run(OutputDirectory);
  finally
    Tests.Free;
  end;
end;

end.
