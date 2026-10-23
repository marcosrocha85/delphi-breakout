unit UE4ViewChecks;

interface
function RunE4ViewChecks(const OutputDirectory: string): Boolean;

implementation

uses System.SysUtils, System.Math, System.JSON, System.IOUtils,
  Winapi.Windows, Vcl.Graphics, Vcl.Imaging.pngimage, UMain, UDebug,
  Breakout.Types, Breakout.TestScenarios, Breakout.Presentation, Breakout.Renderer.Vcl;

type
  TViewProbe = class(TGameProbe)
    procedure SetCounters(State: TGameState; Score: Integer);
    procedure SetWidth(Width: Double);
  end;

procedure TViewProbe.SetCounters(State: TGameState; Score: Integer);
begin FState := State; FScore := Score; end;
procedure TViewProbe.SetWidth(Width: Double);
begin FPaddle.Width := Width; end;

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
  Failures, I, X, Y, BaseGdi, BaseUser, Updates, Resizes: Integer;
  Count: Int64;
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
      for I := 1 to 10 do FrmMain.AdvanceFrame(0.1);
      Check('score_reaches_target_after_1_second', FrmMain.Presentation.DisplayedScore = 100);
      Press(VK_F2); Probe.Fixture(True); FrmMain.RefreshView; Press(VK_SPACE);
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
      Press(VK_F3); Count := FrmMain.GameLoop.Diagnostics.TotalSteps; Press(VK_F1);
      Check('f1_debug_step_only_one_fixed_step', FrmMain.GameLoop.Diagnostics.TotalSteps = Count+1);
      Press(VK_F10); Press(VK_F2);
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
    Report.AddPair('suite','E4 VCL and bitmap');
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
