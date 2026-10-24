unit Breakout.Presentation.Tests;

interface

function RunPresentationTests(const OutputDirectory: string): Boolean;

implementation

uses System.SysUtils, System.Math, System.JSON, System.IOUtils,
  Breakout.Types, Breakout.Bricks, Breakout.Game, Breakout.Presentation;

function RunPresentationTests(const OutputDirectory: string): Boolean;
const
  ExpectedPoints: array[TBrickKind] of Integer = (100, 150, 200, 250, 400, 500);
  Rates: array[0..2] of Integer = (30, 60, 144);
  Durations: array[0..2] of Integer = (250, 350, 500);
  WindowSizes: array[0..3, 0..1] of Integer =
    ((1000, 453), (688, 900), (1376, 906), (1101, 733));
var
  Results: TJSONArray;
  Report: TJSONObject;
  Failures, I, J, Duration, Rate, SavedScore: Integer;
  Game: TGame;
  View: TGamePresentation;
  S, Original: TGameSnapshot;
  Config: TVisualConfig;
  Definition: TBrickDefinition;
  Kind: TBrickKind;
  V: TViewport;
  Scale: Double;
  Raised: Boolean;
  procedure Check(const Name: string; Passed: Boolean);
  var Row: TJSONObject;
  begin
    Row := TJSONObject.Create;
    Row.AddPair('name', Name);
    Row.AddPair('passed', TJSONBool.Create(Passed));
    Results.AddElement(Row);
    if not Passed then Inc(Failures);
  end;
begin
  Results := TJSONArray.Create;
  Failures := 0;
  Game := TGame.Create(TGameConfig.Default, 12345);
  View := nil;
  Report := TJSONObject.Create;
  try
    Original := Game.Snapshot;
    for Kind := Low(TBrickKind) to High(TBrickKind) do
    begin
      Definition := BrickDefinition(Kind);
      Check('class_' + IntToStr(Ord(Kind)), (Definition.Kind = Kind) and
        (Definition.SpriteIndex = Ord(Kind)) and (Definition.Points = ExpectedPoints[Kind]));
    end;
    for I := 0 to High(Original.Bricks) do
    begin
      Definition := BrickDefinition(Original.Bricks[I].Kind);
      if (Original.Bricks[I].SpriteIndex <> Definition.SpriteIndex) or
        (Original.Bricks[I].Points <> Definition.Points) then Inc(Failures);
    end;
    Check('level_uses_class_definitions', Failures = 0);
    View := TGamePresentation.Create(TVisualConfig.Default);
    S := Game.Snapshot;
    S.Score := 10150;
    View.Reset(S);
    S.Score := 10250;
    View.Sync(S);
    Check('score_target_immediate_display_deferred', (View.Snapshot.Score = 10250) and
      (View.DisplayedScore = 10150) and View.HasPending);
    View.Advance(0.004, False);
    Check('score_waits_for_interval', View.DisplayedScore = 10150);
    View.Advance(0.001, False);
    Check('score_increments_by_one', View.DisplayedScore = 10151);
    for I := 2 to 100 do
    begin
      SavedScore := View.DisplayedScore;
      View.Advance(0.005, False);
      if View.DisplayedScore <> SavedScore + 1 then Inc(Failures);
    end;
    Check('score_reaches_10250_without_overshoot', (View.DisplayedScore = 10250) and not View.HasPending);
    for Rate in Rates do
    begin
      S.Score := 0; View.Reset(S);
      S.Score := 400; View.Sync(S);
      for I := 1 to Rate do View.Advance(1.0 / Rate, False);
      Check('score_rate_' + IntToStr(Rate), View.DisplayedScore = 200);
    end;
    S.Score := 0; View.Reset(S);
    S.Score := 100; View.Sync(S); View.Advance(0.25, False);
    S.Score := 700; View.Sync(S); View.Advance(0.25, False);
    Check('new_hit_accumulates_target', (View.DisplayedScore = 100) and (View.Snapshot.Score = 700));
    View.Advance(1.0E100, False);
    Check('large_elapsed_bounded_by_target', (View.DisplayedScore = 700) and not View.HasPending);
    for Duration in Durations do
    begin
      FreeAndNil(View);
      Config := TVisualConfig.Default; Config.FadeDurationMs := Duration;
      View := TGamePresentation.Create(Config);
      S := Game.Snapshot; View.Reset(S);
      S.Bricks[0].Active := False; S.Bricks[1].Active := False;
      S.Score := S.Bricks[0].Points + S.Bricks[1].Points;
      View.Sync(S);
      Check('multi_hit_fades_start_' + IntToStr(Duration), View.Fades[0].Active and
        View.Fades[1].Active and (View.FadeOpacity(0) = 1) and not View.Snapshot.Bricks[0].Active);
      View.Advance(Duration / 2000.0, False);
      Check('fade_half_' + IntToStr(Duration), Abs(View.FadeOpacity(0) - 0.5) < 1.0E-8);
      SavedScore := View.DisplayedScore;
      View.Advance(10, True);
      Check('pause_freezes_both_' + IntToStr(Duration),
        (View.DisplayedScore = SavedScore) and (Abs(View.FadeOpacity(1) - 0.5) < 1.0E-8));
      View.Advance(Duration / 2000.0, False);
      Check('fade_end_' + IntToStr(Duration), not View.Fades[0].Active and
        not View.Fades[1].Active and (View.FadeOpacity(0) = 0));
    end;
    S := Game.Snapshot; View.Reset(S);
    S.Bricks[0].Active := False; S.Score := 100; View.Sync(S);
    View.Advance(0.1, False);
    SavedScore := View.DisplayedScore;
    S.Level := 2; S.Bricks[0].Active := True; View.Sync(S);
    Check('next_level_clears_fades_keeps_count_debt', not View.Fades[0].Active and
      (View.DisplayedScore = SavedScore) and View.HasPending);
    View.Reset(Game.Snapshot);
    Check('restart_clears_counter_and_fades', (View.DisplayedScore = 0) and not View.HasPending);
    S := Game.Snapshot; View.Reset(S); S.Bricks[0].Active := False;
    Check('presentation_detaches_snapshot', View.Snapshot.Bricks[0].Active);
    S.Score := 100; View.Sync(S); View.Sync(S); View.Advance(0.2, False); View.Sync(S);
    Check('repeated_sync_does_not_restart_fade', Abs(View.Fades[0].AgeSeconds-0.2) < 1.0E-8);
    for I := 0 to 3 do
    begin
      case I of 0: Scale := 1; 1: Scale := 1.25; 2: Scale := 1.5; else Scale := 2; end;
      V := TViewport.Fit(Round(688*Scale), Round(453*Scale));
      Check('viewport_inverse_scale_' + IntToStr(I),
        Abs(V.ToLogicalX(V.OffsetX + 325*V.Scale) - 325) < 1.0E-8);
    end;
    V := TViewport.Fit(1000, 453);
    Check('letterbox_uniform_and_centered', (V.Scale = 1) and (V.OffsetX = 156) and
      (V.ToLogicalX(481) = 325));
    V := TViewport.Fit(0, 0);
    Check('empty_viewport_safe', V.ToLogicalX(100) = 0);
    for I := 0 to High(WindowSizes) do
    begin
      V := TViewport.Fit(WindowSizes[I, 0], WindowSizes[I, 1]);
      Check('window_viewport_fits_and_centers_' + IntToStr(I),
        (V.Scale > 0) and (V.OffsetX >= 0) and (V.OffsetY >= 0) and
        SameValue(V.Width / V.Height, 688.0 / 453, 1.0E-8) and
        SameValue(V.Width + 2 * V.OffsetX, WindowSizes[I, 0], 1.0E-8) and
        SameValue(V.Height + 2 * V.OffsetY, WindowSizes[I, 1], 1.0E-8) and
        ((V.OffsetX < 1.0E-8) or (V.OffsetY < 1.0E-8)));
      Check('window_viewport_round_trip_with_pixel_rounding_' + IntToStr(I),
        Abs(V.ToLogicalX(Round(V.OffsetX + 325 * V.Scale)) - 325) <=
          0.5 / V.Scale + 1.0E-8);
    end;
    V := TViewport.Fit(0, 453);
    Check('zero_width_viewport_safe', (V.Scale = 0) and (V.ToLogicalX(100) = 0));
    V := TViewport.Fit(688, -1);
    Check('negative_height_viewport_safe', (V.Scale = 0) and (V.Width = 0));
    for J := 0 to 1 do
    begin
      Raised := False;
      try
        if J = 0 then View.Advance(-1, False) else View.Advance(NaN, False);
      except on E: EArgumentOutOfRangeException do Raised := True; end;
      Check('invalid_elapsed_rejected_' + IntToStr(J), Raised);
    end;
    Config := TVisualConfig.Default; Config.FadeDurationMs := 0;
    Raised := False;
    try
      with TGamePresentation.Create(Config) do Free;
    except on E: EArgumentException do Raised := True; end;
    Check('invalid_config_rejected', Raised);
    Report.AddPair('suite', 'E4 presentation');
    Report.AddPair('count', TJSONNumber.Create(Results.Count));
    Report.AddPair('failures', TJSONNumber.Create(Failures));
    Report.AddPair('cases', Results); Results := nil;
    ForceDirectories(OutputDirectory);
    TFile.WriteAllText(TPath.Combine(OutputDirectory, 'presentation.json'), Report.Format, TEncoding.UTF8);
    Result := Failures = 0;
  finally
    Report.Free; Results.Free; View.Free; Game.Free;
  end;
end;

end.
