unit UE4ViewChecks;

interface
function RunE4ViewChecks(const OutputDirectory: string): Boolean;

implementation

uses System.SysUtils, System.Math, System.JSON, System.IOUtils,
  Winapi.Windows, Vcl.Graphics, Vcl.Imaging.pngimage, UMain, UDebug,
  Breakout.Types, Breakout.Game, Breakout.Loop, Breakout.TestScenarios,
  Breakout.Presentation, Breakout.Renderer.Vcl;

type
  TViewProbe = class(TGameProbe)
    procedure SetCounters(State: TGameState; Score: Integer);
    procedure SetWidth(Width: Double);
    procedure SetFinalLevel;
  end;

procedure TViewProbe.SetCounters(State: TGameState; Score: Integer);
begin FState := State; FScore := Score; end;
procedure TViewProbe.SetWidth(Width: Double);
begin FPaddle.Width := Width; end;
procedure TViewProbe.SetFinalLevel;
begin FLevel := Snapshot.LevelCount; end;

function SamePixels(A, B: TBitmap; AX, AY, BX, BY, W, H: Integer): Boolean;
var X, Y: Integer;
begin
  for Y := 0 to H-1 do for X := 0 to W-1 do
    if A.Canvas.Pixels[AX+X, AY+Y] <> B.Canvas.Pixels[BX+X, BY+Y] then Exit(False);
  Result := True;
end;

function RunE4ViewChecks(const OutputDirectory: string): Boolean;
const Scales: array[0..3] of Double = (1, 1.25, 1.5, 2);
var
  Report, Row: TJSONObject;
  Results: TJSONArray;
  Failures, I, J, Level, X, Y, BaseGdi, BaseUser, Updates, Resizes, SavedScore: Integer;
  Count: Int64;
  SavedFadeAge, SavedOpacity: Double;
  Before, S: TGameSnapshot;
  V: TGamePresentation;
  R: TGameRenderer;
  Ref: TBitmap;
  Png: TPngImage;
  Probe: TViewProbe;
  Passed: Boolean;
  procedure Check(const Name: string; Value: Boolean);
  var Item: TJSONObject;
  begin
    Item := TJSONObject.Create; Item.AddPair('name', Name);
    Item.AddPair('passed', TJSONBool.Create(Value)); Results.AddElement(Item);
    if not Value then Inc(Failures);
  end;
  procedure Press(Key: Word);
  begin FrmMain.FormKeyDown(nil, Key, []); end;
  procedure SaveFrame(const Name: string);
  begin
    Png.Assign(R.Buffer); Png.SaveToFile(TPath.Combine(OutputDirectory, Name + '.png'));
  end;
  procedure CheckWindowResizing;
  const
    Sizes: array[0..3, 0..1] of Integer =
      ((1000, 453), (688, 900), (1376, 906), (1101, 733));
    Names: array[0..3] of string = ('wide', 'tall', 'double', 'fractional');
  var
    InitialWidth, InitialHeight, N, AllocationCount, Gdi, User: Integer;
    A, B: TGameSnapshot;
    Viewport: TViewport;
    Reference: TGame;
    ReferenceLoop: TGameLoop;
    Age: Double;
    Steps: Int64;
    Score: Integer;
    Clamped, Clear: Boolean;
    procedure ResizeClient(W, H: Integer);
    begin
      FrmMain.ClientWidth := W;
      FrmMain.ClientHeight := H;
      FrmMain.FormPaint(nil);
    end;
    function SameModel(const First, Second: TGameSnapshot): Boolean;
    var K: Integer;
    begin
      Result := (First.State = Second.State) and (First.Seed = Second.Seed) and
        (First.Score = Second.Score) and (First.Lives = Second.Lives) and
        (First.Level = Second.Level) and (First.ActiveBricks = Second.ActiveBricks) and
        (First.Ball.X = Second.Ball.X) and (First.Ball.Y = Second.Ball.Y) and
        (First.Ball.VelocityX = Second.Ball.VelocityX) and
        (First.Ball.VelocityY = Second.Ball.VelocityY) and
        (First.Paddle.X = Second.Paddle.X) and (First.Paddle.Width = Second.Paddle.Width) and
        (Length(First.Bricks) = Length(Second.Bricks));
      if not Result then Exit;
      for K := 0 to High(First.Bricks) do
        Result := Result and (First.Bricks[K].Active = Second.Bricks[K].Active) and
          (First.Bricks[K].X = Second.Bricks[K].X) and
          (First.Bricks[K].Y = Second.Bricks[K].Y) and
          (First.Bricks[K].Kind = Second.Bricks[K].Kind);
    end;
  begin
    InitialWidth := FrmMain.ClientWidth; InitialHeight := FrmMain.ClientHeight;
    Reference := nil; ReferenceLoop := nil;
    try
      Check('window_has_native_resize_and_maximize',
        (GetWindowLong(FrmMain.Handle, GWL_STYLE) and WS_THICKFRAME <> 0) and
        (GetWindowLong(FrmMain.Handle, GWL_STYLE) and WS_MAXIMIZEBOX <> 0));
      FrmMain.SetBounds(FrmMain.Left, FrmMain.Top, 1, 1);
      Check('window_minimum_preserves_initial_client',
        (FrmMain.ClientWidth = InitialWidth) and (FrmMain.ClientHeight = InitialHeight));
      for N := 0 to High(Sizes) do
      begin
        A := FrmMain.Game.Snapshot; Steps := FrmMain.GameLoop.Diagnostics.TotalSteps;
        ResizeClient(Sizes[N, 0], Sizes[N, 1]);
        Viewport := FrmMain.Renderer.Viewport;
        Check('window_resize_viewport_' + Names[N],
          (FrmMain.ClientWidth = Sizes[N, 0]) and (FrmMain.ClientHeight = Sizes[N, 1]) and
          SameValue(Viewport.Width / Viewport.Height, 688.0 / 453, 1.0E-8) and
          SameValue(Viewport.Width + 2 * Viewport.OffsetX, Sizes[N, 0], 1.0E-8) and
          SameValue(Viewport.Height + 2 * Viewport.OffsetY, Sizes[N, 1], 1.0E-8));
        Check('window_resize_and_paint_preserve_match_' + Names[N],
          SameModel(A, FrmMain.Game.Snapshot) and
          (FrmMain.GameLoop.Diagnostics.TotalSteps = Steps) and not FrmMain.Timer1.Enabled);
        AllocationCount := FrmMain.Renderer.Metrics.BufferResizes;
        FrmMain.FormPaint(nil);
        Check('window_buffer_size_and_reuse_' + Names[N],
          (FrmMain.Renderer.Buffer.Width = Sizes[N, 0]) and
          (FrmMain.Renderer.Buffer.Height = Sizes[N, 1]) and
          (FrmMain.Renderer.Metrics.BufferResizes = AllocationCount));
        Clear := True;
        if Viewport.OffsetX > 0 then
          Clear := FrmMain.Renderer.Buffer.Canvas.Pixels[Round(Viewport.OffsetX/2),
            Round(Viewport.OffsetY + 100*Viewport.Scale)] = clBlack;
        if Viewport.OffsetY > 0 then
          Clear := Clear and (FrmMain.Renderer.Buffer.Canvas.Pixels[
            Round(Viewport.OffsetX + 100*Viewport.Scale), Round(Viewport.OffsetY/2)] = clBlack);
        Check('window_letterbox_is_black_' + Names[N], Clear);
        FrmMain.FormMouseMove(nil, [], Round(Viewport.OffsetX + 325*Viewport.Scale), 400);
        B := FrmMain.Game.Snapshot;
        Check('window_mouse_and_ready_ball_alignment_' + Names[N],
          (Abs(B.Paddle.X + B.Paddle.Width/2 - 325) <= 0.5/Viewport.Scale + 1.0E-8) and
          SameValue(B.Ball.X + B.Ball.Size/2, B.Paddle.X + B.Paddle.Width/2, 1.0E-8));
        FrmMain.FormMouseMove(nil, [], -100, 400);
        Clamped := FrmMain.Game.Snapshot.Paddle.X = 0;
        FrmMain.FormMouseMove(nil, [], Sizes[N, 0] + 100, 400);
        Check('window_mouse_clamps_both_edges_' + Names[N], Clamped and
          (FrmMain.Game.Snapshot.Paddle.X = 638));
        FrmMain.FormPaint(nil);
        Png.Assign(FrmMain.Renderer.Buffer);
        Png.SaveToFile(TPath.Combine(OutputDirectory, 'window-' + Names[N] + '.png'));
      end;
      Press(VK_F2);
      Reference := TGame.Create(TGameConfig.Default, FrmMain.Game.Snapshot.Seed);
      ReferenceLoop := TGameLoop.Create(Reference);
      Press(VK_SPACE); ReferenceLoop.Execute(gcLaunch);
      for N := 0 to High(Sizes) do
      begin
        ResizeClient(Sizes[N, 0], Sizes[N, 1]);
        FrmMain.AdvanceFrame(2.5*FixedDeltaSeconds);
        ReferenceLoop.Advance(2.5*FixedDeltaSeconds);
        Check('resizing_preserves_trajectory_and_fractional_time_' + Names[N],
          SameModel(FrmMain.Game.Snapshot, Reference.Snapshot) and
          SameValue(FrmMain.GameLoop.Diagnostics.AccumulatorSeconds,
            ReferenceLoop.Diagnostics.AccumulatorSeconds, 1.0E-8));
      end;
      Press(VK_F2); Probe.Fixture; FrmMain.RefreshView; Press(VK_SPACE);
      Probe.SetBall(310,82,0,240); FrmMain.AdvanceFrame(FixedDeltaSeconds);
      FrmMain.AdvanceFrame(0.1); Press(VK_F10); Press(VK_F3);
      A := FrmMain.Game.Snapshot; Steps := FrmMain.GameLoop.Diagnostics.TotalSteps;
      Age := FrmMain.Presentation.Fades[0].AgeSeconds;
      Score := FrmMain.Presentation.DisplayedScore;
      ResizeClient(1101,733);
      Check('resize_preserves_paused_fade_and_score',
        SameModel(A, FrmMain.Game.Snapshot) and
        (FrmMain.Presentation.Fades[0].AgeSeconds = Age) and
        (FrmMain.Presentation.DisplayedScore = Score) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Steps) and not FrmMain.Timer1.Enabled);
      Press(VK_F1);
      Check('debug_visual_step_survives_resize',
        SameValue(FrmMain.Presentation.Fades[0].AgeSeconds, Age + FixedDeltaSeconds, 1.0E-8) and
        (FrmMain.Presentation.DisplayedScore = Score+1) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Steps+1) and not FrmMain.Timer1.Enabled);
      Press(VK_F10); Press(VK_F2);
      ResizeClient(InitialWidth,InitialHeight);
      Gdi := GetGuiResources(GetCurrentProcess,GR_GDIOBJECTS);
      User := GetGuiResources(GetCurrentProcess,GR_USEROBJECTS);
      for N := 1 to 30 do
        if Odd(N) then ResizeClient(1000,453) else ResizeClient(InitialWidth,InitialHeight);
      Check('repeated_resizes_keep_gui_resources_bounded',
        (GetGuiResources(GetCurrentProcess,GR_GDIOBJECTS) <= DWORD(Gdi+2)) and
        (GetGuiResources(GetCurrentProcess,GR_USEROBJECTS) <= DWORD(User+2)));
    finally
      ReferenceLoop.Free; Reference.Free;
      if Assigned(FrmDebug) then FreeAndNil(FrmDebug);
      Press(VK_F2); ResizeClient(InitialWidth,InitialHeight);
    end;
  end;
begin
  Report := TJSONObject.Create; Results := TJSONArray.Create; Failures := 0;
  V := TGamePresentation.Create(TVisualConfig.Default); R := TGameRenderer.Create;
  Ref := TBitmap.Create; Png := TPngImage.Create;
  Probe := TViewProbe(FrmMain.Game);
  ForceDirectories(OutputDirectory);
  try
    try
      FrmMain.ApplicationEvents1Activate(nil); Press(VK_F2);
      Check('single_surface_no_entity_controls', (FrmMain.ControlCount = 0) and
        (FrmMain.ComponentCount = 2));
      Check('timer_15ms_and_idle_ready', (FrmMain.Timer1.Interval = 15) and not FrmMain.Timer1.Enabled);
      Press(VK_F1); Check('f1_without_debug_does_not_launch', FrmMain.Game.State = gsReady);
      FrmMain.FormClick(nil); Check('click_launch', FrmMain.Game.State = gsPlaying);
      Before := FrmMain.Game.Snapshot;
      Count := FrmMain.GameLoop.Diagnostics.TotalSteps;
      Sleep(30); FrmMain.Timer1Timer(nil);
      Check('real_stopwatch_drives_fixed_steps', (FrmMain.GameLoop.Diagnostics.TotalSteps >= Count+3) and
        (FrmMain.Game.Snapshot.Ball.Y < Before.Ball.Y));
      Press(VK_F3); Before := FrmMain.Game.Snapshot;
      Press(VK_SPACE); FrmMain.FormClick(nil); FrmMain.AdvanceFrame(0.1);
      Check('pause_freezes_launch_and_movement', (FrmMain.Game.State = gsPaused) and
        (FrmMain.Game.Snapshot.Ball.Y = Before.Ball.Y) and not FrmMain.Timer1.Enabled);
      Sleep(120); Press(VK_F3); FrmMain.Timer1Timer(nil);
      Check('resume_resets_timestamp', FrmMain.GameLoop.Diagnostics.LastSteps <= 1);
      FrmMain.ApplicationEvents1Deactivate(nil);
      Check('deactivate_pauses_and_disables_timer', (FrmMain.Game.State = gsPaused) and not FrmMain.Timer1.Enabled);
      FrmMain.ApplicationEvents1Activate(nil); Press(VK_F3);
      Check('explicit_resume_after_activate', FrmMain.Game.State = gsPlaying);
      for I := 0 to 2 do
      begin
        Press(VK_F2); Probe.Fixture; Press(VK_SPACE);
        case I of
          0: Probe.SetBall(310, 82, 120, 600);
          1: Probe.SetBall(280, 100, 600, 120);
          2: Probe.SetBall(353, 100, -600, -120);
        end;
        FrmMain.AdvanceFrame(FixedDeltaSeconds); S := FrmMain.Game.Snapshot;
        Check('impact_' + IntToStr(I) + '_inactive_and_scored', not S.Bricks[0].Active and (S.Score = 100));
        Check('impact_' + IntToStr(I) + '_fade_and_deferred_score',
          FrmMain.Presentation.Fades[0].Active and (FrmMain.Presentation.DisplayedScore = 0));
        if I = 0 then Passed := S.Ball.VelocityY < 0
        else if I = 1 then Passed := S.Ball.VelocityX < 0 else Passed := S.Ball.VelocityX > 0;
        Check('impact_' + IntToStr(I) + '_reflected', Passed);
      end;
      Press(VK_F3); Before := FrmMain.Presentation.Snapshot;
      FrmMain.AdvanceFrame(0.1);
      Check('paused_visual_age_frozen', FrmMain.Presentation.Fades[0].AgeSeconds = 0);
      FrmMain.FormPaint(nil); FrmMain.FormPaint(nil);
      Check('painting_read_only', (FrmMain.Presentation.Fades[0].AgeSeconds = 0) and
        (FrmMain.Game.Snapshot.Ball.X = Before.Ball.X));
      Press(VK_F3);
      for I := 1 to 5 do FrmMain.AdvanceFrame(0.1);
      Check('score_reaches_target_after_half_second', FrmMain.Presentation.DisplayedScore = 100);
      Press(VK_F2); Probe.SetFinalLevel; Probe.Fixture(True); FrmMain.RefreshView; Press(VK_SPACE);
      Probe.SetBall(310, 82, 120, 600); FrmMain.AdvanceFrame(FixedDeltaSeconds);
      Check('victory_keeps_visual_timer_alive', (FrmMain.Game.State = gsVictory) and FrmMain.Timer1.Enabled);
      for I := 1 to 21 do FrmMain.AdvanceFrame(0.1);
      Check('victory_stops_timer_when_effects_finish', not FrmMain.Timer1.Enabled);
      Press(VK_F2); Check('f2_clears_pending', not FrmMain.Presentation.HasPending and
        (FrmMain.Presentation.DisplayedScore = 0));
      for I := 1 to 3 do
      begin
        Press(VK_SPACE); Probe.PrepareFall; FrmMain.AdvanceFrame(FixedDeltaSeconds);
        Check('one_life_per_fall_' + IntToStr(I), FrmMain.Game.Snapshot.Lives = 3-I);
      end;
      Press(VK_SPACE); Check('game_over_cannot_launch', FrmMain.Game.State = gsGameOver);
      Press(VK_F2); Probe.SetWidth(100); FrmMain.FormMouseMove(nil, [], 300, 400);
      Check('wide_paddle_centered_on_input', FrmMain.Game.Snapshot.Paddle.X = 250);
      FrmMain.FormMouseMove(nil, [], -100, 400);
      Check('wide_paddle_clamps_left', FrmMain.Game.Snapshot.Paddle.X = 0);
      FrmMain.FormMouseMove(nil, [], 2000, 400);
      Check('wide_paddle_clamps_right', FrmMain.Game.Snapshot.Paddle.X = 588);
      Press(VK_F2);
      for I := 1 to 5 do begin Press(VK_F10); Press(VK_F10); end;
      BaseGdi := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
      BaseUser := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
      for I := 1 to 50 do begin Press(VK_F2); Press(VK_F10); Press(VK_F10); end;
      Check('50_restarts_and_debug_toggles_stable_gdi',
        GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= DWORD(BaseGdi+2));
      Check('50_restarts_and_debug_toggles_stable_user',
        GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= DWORD(BaseUser+2));
      Press(VK_F10); Press(VK_SPACE); Updates := FrmMain.DebugUpdates;
      for I := 1 to 20 do FrmMain.AdvanceFrame(0.05);
      Check('debug_throttled_to_5hz', (FrmMain.DebugUpdates-Updates >= 4) and
        (FrmMain.DebugUpdates-Updates <= 5) and (FrmDebug.VLE.Strings.Count = 30));
      Press(VK_F3); Count := FrmMain.GameLoop.Diagnostics.TotalSteps;
      Before := FrmMain.Game.Snapshot;
      FrmMain.FormMouseMove(nil, [], 300, 400);
      S := FrmMain.Game.Snapshot;
      Check('paused_debug_mouse_moves_paddle_without_advancing',
        (S.State = gsPaused) and (S.Paddle.X = 275) and
        (S.Ball.X = Before.Ball.X) and (S.Ball.Y = Before.Ball.Y) and
        (S.Score = Before.Score) and (S.Lives = Before.Lives) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count) and not FrmMain.Timer1.Enabled);
      Check('paused_debug_mouse_refreshes_presentation',
        (FrmMain.Presentation.Snapshot.Paddle.X = S.Paddle.X) and
        (FrmMain.Presentation.Snapshot.Ball.Y = Before.Ball.Y));
      Press(VK_F1);
      Check('f1_debug_step_only_one_fixed_step', FrmMain.GameLoop.Diagnostics.TotalSteps = Count+1);
      Before := FrmMain.Game.Snapshot;
      FrmMain.FormMouseMove(nil, [], 500, 400);
      S := FrmMain.Game.Snapshot;
      Check('paused_debug_mouse_moves_again_after_f1',
        (S.State = gsPaused) and (S.Paddle.X = 475) and
        (S.Ball.X = Before.Ball.X) and (S.Ball.Y = Before.Ball.Y) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count+1) and not FrmMain.Timer1.Enabled);
      FrmMain.FormMouseMove(nil, [], -100, 400);
      Check('paused_debug_mouse_clamps_left', FrmMain.Game.Snapshot.Paddle.X = 0);
      FrmMain.FormMouseMove(nil, [], 2000, 400);
      Check('paused_debug_mouse_clamps_right', FrmMain.Game.Snapshot.Paddle.X = 638);
      Press(VK_F10); Before := FrmMain.Game.Snapshot;
      FrmMain.FormMouseMove(nil, [], 300, 400); Press(VK_F1);
      S := FrmMain.Game.Snapshot;
      Check('closing_debug_restores_frozen_paddle_and_blocks_f1',
        (S.State = gsPaused) and (S.Paddle.X = Before.Paddle.X) and
        (S.Ball.X = Before.Ball.X) and (S.Ball.Y = Before.Ball.Y) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count+1) and not FrmMain.Timer1.Enabled);
      Press(VK_F2);
      { F1 advances existing visual feedback by the same quantum as physics.
        New impacts start at full opacity, as in the normal frame ordering. }
      Probe.Fixture; FrmMain.RefreshView; Press(VK_F10); Press(VK_SPACE);
      Probe.SetBall(310, 82, 0, 240); Press(VK_F3);
      Count := FrmMain.GameLoop.Diagnostics.TotalSteps; Press(VK_F1);
      Check('f1_impact_creates_fresh_fade_and_score_debt',
        (FrmMain.Game.State = gsPaused) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count+1) and
        FrmMain.Presentation.Fades[0].Active and
        (FrmMain.Presentation.Fades[0].AgeSeconds = 0) and
        (FrmMain.Presentation.FadeOpacity(0) = 1) and
        (FrmMain.Presentation.DisplayedScore = 0) and
        (FrmMain.Game.Snapshot.Score = 100));
      Press(VK_F3); FrmMain.AdvanceFrame(0.1);
      SavedFadeAge := FrmMain.Presentation.Fades[0].AgeSeconds;
      SavedOpacity := FrmMain.Presentation.FadeOpacity(0);
      SavedScore := FrmMain.Presentation.DisplayedScore;
      Count := FrmMain.GameLoop.Diagnostics.TotalSteps; Press(VK_F1);
      Check('f1_while_playing_does_not_advance_visuals',
        (FrmMain.Presentation.Fades[0].AgeSeconds = SavedFadeAge) and
        (FrmMain.Presentation.DisplayedScore = SavedScore) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count));
      Press(VK_F3); Before := FrmMain.Game.Snapshot;
      FrmMain.AdvanceFrame(1); FrmMain.FormPaint(nil);
      FrmMain.FormMouseMove(nil, [], 500, 400); FrmMain.RefreshView;
      Check('paused_mid_fade_freezes_between_debug_steps',
        SameValue(SavedFadeAge, 0.1, 1.0E-8) and
        (FrmMain.Presentation.Fades[0].AgeSeconds = SavedFadeAge) and
        (FrmMain.Presentation.FadeOpacity(0) = SavedOpacity) and
        (FrmMain.Presentation.DisplayedScore = SavedScore) and
        (FrmMain.Game.Snapshot.Ball.Y = Before.Ball.Y) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count) and not FrmMain.Timer1.Enabled);
      Press(VK_F1);
      Check('f1_advances_existing_fade_and_score_by_one_quantum',
        SameValue(FrmMain.Presentation.Fades[0].AgeSeconds,
          SavedFadeAge + FixedDeltaSeconds, 1.0E-8) and
        (FrmMain.Presentation.FadeOpacity(0) < SavedOpacity) and
        (FrmMain.Presentation.DisplayedScore = SavedScore+1) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count+1) and
        (FrmMain.Game.State = gsPaused) and not FrmMain.Timer1.Enabled);
      Press(VK_F1); Press(VK_F1);
      Check('three_debug_quanta_reach_half_fade_and_five_points',
        SameValue(FrmMain.Presentation.FadeOpacity(0), 0.5, 1.0E-8) and
        (FrmMain.Presentation.DisplayedScore = SavedScore+5) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count+3));
      SavedFadeAge := FrmMain.Presentation.Fades[0].AgeSeconds;
      FrmMain.AdvanceFrame(1); FrmMain.FormPaint(nil);
      Check('debug_visuals_freeze_again_after_stepping',
        (FrmMain.Presentation.Fades[0].AgeSeconds = SavedFadeAge) and
        (FrmMain.Presentation.DisplayedScore = SavedScore+5) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count+3));
      for I := 1 to 15 do Press(VK_F1);
      Check('debug_steps_finish_fade_without_resuming_match',
        not FrmMain.Presentation.Fades[0].Active and
        (FrmMain.Presentation.FadeOpacity(0) = 0) and
        (FrmMain.Presentation.DisplayedScore = SavedScore+30) and
        FrmMain.Presentation.HasPending and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count+18) and
        (FrmMain.Game.State = gsPaused) and not FrmMain.Timer1.Enabled);
      Press(VK_F10); SavedFadeAge := FrmMain.Presentation.Fades[0].AgeSeconds;
      Press(VK_F1); FrmMain.AdvanceFrame(1);
      Check('f1_without_debug_leaves_visuals_frozen',
        (FrmMain.Presentation.Fades[0].AgeSeconds = SavedFadeAge) and
        (FrmMain.Presentation.DisplayedScore = SavedScore+30) and
        (FrmMain.GameLoop.Diagnostics.TotalSteps = Count+18));
      Press(VK_F2);
      Check('restart_clears_stepped_visual_feedback',
        not FrmMain.Presentation.HasPending and
        (FrmMain.Presentation.DisplayedScore = 0) and not FrmMain.Timer1.Enabled);
      CheckWindowResizing;
      { E5: drive the real form/loop/presentation across every campaign board.
        Fixture shortens each board to one collision; console tests clear all
        136 real bricks separately. No production skip-level command is added. }
      for Level := 1 to 3 do
      begin
        S := FrmMain.Game.Snapshot;
        Check('campaign_ready_board_' + IntToStr(Level), (S.State = gsReady) and
          (S.Level = Level) and (S.LevelCount = 3) and
          (((Level = 1) and (S.ActiveBricks = 96)) or ((Level > 1) and (S.ActiveBricks = 20))));
        Passed := True;
        for I := 0 to High(S.Bricks) do
          if S.Bricks[I].Kind in [bkSilver, bkGold] then
            for J := 0 to I - 1 do
              if S.Bricks[J].Kind in [bkSilver, bkGold] then
                Passed := Passed and not
                  (((S.Bricks[I].Y = S.Bricks[J].Y) and
                    (Abs(S.Bricks[I].X - S.Bricks[J].X) = 56)) or
                   ((S.Bricks[I].X = S.Bricks[J].X) and
                    (Abs(S.Bricks[I].Y - S.Bricks[J].Y) = 24)));
        Check('campaign_premium_spacing_' + IntToStr(Level), Passed);
        V.Reset(S); R.Compose(V,688,453); SaveFrame('level-' + IntToStr(Level) + '-ready');
        Check('ready_message_and_level_feedback_' + IntToStr(Level),
          (GameMessage(S.State) <> '') and (Pos('Space', GameMessage(S.State)) > 0));
        Probe.Fixture(True); FrmMain.RefreshView; FrmMain.FormClick(nil);
        Probe.SetBall(310,82,0,240); FrmMain.AdvanceFrame(0.1);
        S := FrmMain.Game.Snapshot;
        Check('campaign_terminal_visuals_' + IntToStr(Level), (S.Score = Level * 100) and
          FrmMain.Timer1.Enabled and FrmMain.Presentation.Fades[0].Active and
          (FrmMain.GameLoop.Diagnostics.LastSteps = 1) and
          (FrmMain.GameLoop.Diagnostics.AccumulatorSeconds = 0));
        V.Reset(S); R.Compose(V,688,453); SaveFrame('level-' + IntToStr(Level) + '-complete');
        if Level < 3 then
        begin
          Check('campaign_level_complete_waits_' + IntToStr(Level), S.State = gsLevelComplete);
          SavedScore := FrmMain.Presentation.DisplayedScore;
          Press(VK_SPACE);
          Check('campaign_continue_keeps_score_debt_' + IntToStr(Level),
            (FrmMain.Game.State = gsReady) and
            (FrmMain.Game.Snapshot.Score = Level * 100) and
            (FrmMain.Game.Snapshot.Lives = 3) and
            (FrmMain.Presentation.DisplayedScore = SavedScore) and FrmMain.Presentation.HasPending);
          Passed := True;
          for J := 0 to FrmMain.Presentation.FadeCapacity - 1 do
            Passed := Passed and not FrmMain.Presentation.Fades[J].Active;
          Check('campaign_continue_removes_old_fades_' + IntToStr(Level), Passed);
          for J := 1 to 10 do FrmMain.AdvanceFrame(0.1);
          Check('campaign_ready_finishes_debt_then_idles_' + IntToStr(Level),
            (FrmMain.Presentation.DisplayedScore = Level * 100) and not FrmMain.Timer1.Enabled);
        end
        else
        begin
          Press(VK_SPACE); FrmMain.FormClick(nil); Press(VK_F3);
          Check('campaign_victory_rejects_continue', FrmMain.Game.State = gsVictory);
          for J := 1 to 10 do FrmMain.AdvanceFrame(0.1);
          Check('campaign_victory_settles_score', (FrmMain.Presentation.DisplayedScore = 300) and
            not FrmMain.Timer1.Enabled);
        end;
      end;
      Press(VK_F2);
      Check('campaign_f2_resets_presentation_and_match',
        (FrmMain.Game.Snapshot.Level = 1) and (FrmMain.Game.Snapshot.Score = 0) and
        (FrmMain.Game.Snapshot.Lives = 3) and (FrmMain.Presentation.DisplayedScore = 0) and
        not FrmMain.Presentation.HasPending and not FrmMain.Timer1.Enabled);
      S := FrmMain.Game.Snapshot; V.Reset(S); R.Compose(V,688,453); SaveFrame('original-size');
      SetLength(S.Bricks,0); S.Paddle.X := 100; S.Ball.X := 400; S.Ball.Y := 350;
      V.Reset(S); R.Compose(V,688,453); Ref.Assign(R.Buffer);
      S.Paddle.Width := 100; V.Reset(S); R.Compose(V,688,453); SaveFrame('paddle-100');
      Check('wide_paddle_caps_preserve_original_pixels',
        SamePixels(Ref,R.Buffer,100,420,100,420,7,15) and
        SamePixels(Ref,R.Buffer,143,420,193,420,7,15));
      Passed := True;
      for Y := 420 to 434 do for X := 107 to 192 do
        Passed := Passed and (R.Buffer.Canvas.Pixels[X,Y] = Ref.Canvas.Pixels[120,Y]);
      Check('wide_paddle_stripes_extend_without_seams', Passed);
      Ref.Assign(R.Buffer);
      SetLength(S.Bricks,1); S.Bricks[0] := Default(TBrick); S.Bricks[0].Active := True;
      S.Bricks[0].X := 0; S.Bricks[0].Y := 435; S.Bricks[0].Width := 688; S.Bricks[0].Height := 18;
      S.Ball.X := 10; S.Ball.Y := 438; S.Paddle.Y := 438;
      V.Reset(S); R.Compose(V,688,453);
      Check('hud_above_all_field_objects', SamePixels(Ref,R.Buffer,0,435,0,435,688,18));
      S.Bricks[0].X := 100; S.Bricks[0].Y := 100; S.Bricks[0].Width := 50; S.Bricks[0].Height := 20;
      S.Ball.Y := 350; S.Paddle.Y := 420; V.Reset(S); R.Compose(V,688,453); Ref.Assign(R.Buffer);
      S.Bricks[0].Active := False; V.Sync(S); R.Compose(V,688,453);
      Check('fade_start_same_pixels_as_active', SamePixels(Ref,R.Buffer,100,100,100,100,50,20));
      V.Advance(BrickFadeDurationMs / 2000.0,False); R.Compose(V,688,453); SaveFrame('fade-half');
      Check('fade_half_darker', GetGValue(ColorToRGB(R.Buffer.Canvas.Pixels[125,110])) <
        GetGValue(ColorToRGB(Ref.Canvas.Pixels[125,110])));
      V.Advance(BrickFadeDurationMs / 2000.0,False); R.Compose(V,688,453);
      Check('fade_end_restores_background', R.Buffer.Canvas.Pixels[125,110] = clBlack);
      for I := 0 to High(Scales) do
      begin
        V.Reset(FrmMain.Game.Snapshot); R.Compose(V,Round(688*Scales[I]),Round(453*Scales[I]));
        SaveFrame('scale-'+IntToStr(Round(Scales[I]*100)));
        Check('dpi_buffer_' + IntToStr(I), (R.Buffer.Width = Round(688*Scales[I])) and
          (Abs(R.Viewport.ToLogicalX(R.Viewport.OffsetX+325*R.Viewport.Scale)-325)<1.0E-8));
      end;
      R.Compose(V,688,453); Resizes := R.Metrics.BufferResizes;
      for I := 1 to 1000 do R.Compose(V,688,453);
      Check('1000_frames_reuse_buffer', R.Metrics.BufferResizes = Resizes);
      Check('score_format_long_values', (FormatGameScore(42) = '000000042') and
        (FormatGameScore(1000000000) = '1000000000'));
    except on E: Exception do
      begin
        Row := TJSONObject.Create; Row.AddPair('exception',E.ClassName+': '+E.Message);
        Results.AddElement(Row); Inc(Failures);
      end;
    end;
    Report.AddPair('suite','E5 progression with E4 VCL and bitmap regressions');
    Report.AddPair('checks',TJSONNumber.Create(Results.Count));
    Report.AddPair('failures',TJSONNumber.Create(Failures));
    Report.AddPair('results',Results); Results := nil;
    TFile.WriteAllText(TPath.Combine(OutputDirectory,'view.json'),Report.Format,TEncoding.UTF8);
    Result := Failures=0;
  finally
    if Assigned(FrmDebug) then FreeAndNil(FrmDebug);
    Press(VK_F2); FrmMain.Timer1.Enabled := False;
    Report.Free; Results.Free; R.Free; V.Free; Ref.Free; Png.Free;
  end;
end;

end.
