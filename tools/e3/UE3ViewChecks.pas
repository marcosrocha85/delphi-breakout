unit UE3ViewChecks;

interface

function RunE3ViewChecks(const OutputDirectory: string): Boolean;

implementation

uses System.SysUtils, System.JSON, System.IOUtils, System.Diagnostics,
  Winapi.Windows, Vcl.ExtCtrls, UMain, UDebug, UE2ViewChecks,
  Breakout.Types, Breakout.Texts, Breakout.TestScenarios;

function RunE3ViewChecks(const OutputDirectory: string): Boolean;
var
  Report: TJSONObject;
  Results: TJSONArray;
  Failures, I: Integer;
  Before, After: TGameSnapshot;
  Key: Word;
  Count: Int64;
  procedure Check(const Name: string; Passed: Boolean);
  var
    Item: TJSONObject;
  begin
    Item := TJSONObject.Create;
    Item.AddPair('name', Name);
    Item.AddPair('passed', TJSONBool.Create(Passed));
    Results.AddElement(Item);
    if not Passed then Inc(Failures);
  end;
  procedure Press(Value: Word);
  begin
    Key := Value;
    FrmMain.FormKeyDown(nil, Key, []);
  end;
begin
  RunE2ViewChecks(OutputDirectory);
  Report := TJSONObject.ParseJSONValue(TFile.ReadAllText(
    TPath.Combine(OutputDirectory, 'checks.json'), TEncoding.UTF8)) as TJSONObject;
  try
    Results := Report.GetValue<TJSONArray>('results');
    Failures := Report.GetValue<Integer>('failures');
    try
      Check('timer_requests_frames_every_16ms', FrmMain.Timer1.Interval = 16);
      Press(VK_SPACE);
      Before := FrmMain.Game.Snapshot;
      Count := FrmMain.GameLoop.Diagnostics.TotalSteps;
      Sleep(30); // test only: exercise the real stopwatch adapter, no message pumping
      FrmMain.Timer1Timer(nil);
      After := FrmMain.Game.Snapshot;
      Check('real_timer_uses_elapsed_time_for_multiple_fixed_steps',
        (FrmMain.GameLoop.Diagnostics.TotalSteps >= Count + 3) and
        (FrmMain.GameLoop.Diagnostics.LastSteps <= MaxStepsPerCallback) and
        (After.Ball.Y < Before.Ball.Y));
      Press(VK_F3);
      Before := FrmMain.Game.Snapshot;
      Sleep(120);
      Press(VK_F3);
      FrmMain.Timer1Timer(nil);
      Check('resume_resets_real_timestamp_without_catchup',
        (FrmMain.GameLoop.Diagnostics.LastSteps <= 1) and
        (Abs(FrmMain.Game.Snapshot.Ball.Y - Before.Ball.Y) < 2));
      for I := 0 to 2 do
      begin
        Press(VK_F2);
        TGameProbe(FrmMain.Game).Fixture;
        Press(VK_SPACE);
        case I of
          0: TGameProbe(FrmMain.Game).SetBall(310, 82, 120, 600);
          1: TGameProbe(FrmMain.Game).SetBall(280, 100, 600, 120);
          2: TGameProbe(FrmMain.Game).SetBall(353, 100, -600, -120);
        end;
        FrmMain.AdvanceFrame(FixedDeltaSeconds);
        After := FrmMain.Game.Snapshot;
        Check('collision_' + IntToStr(I) + '_updates_sprite_and_score',
          not TImage(FrmMain.FindComponent('Bar0')).Visible and
          (FrmMain.ScoreLabel.Caption = SScore + ' 000000010'));
        { The renderer must use the resulting physical position, rounded once. }
        Check('collision_' + IntToStr(I) + '_renders_reflected_ball',
          (FrmMain.Ball.Left = Round(After.Ball.X)) and
          (FrmMain.Ball.Top = Round(After.Ball.Y)) and (After.Score = 10));
      end;
      Press(VK_F10);
      FrmMain.AdvanceFrame(0.5);
      Check('diagnostic_displays_velocity_and_timing_limits',
        (FrmDebug.VLE.Strings.Count = 23) and
        (FrmDebug.VLE.Values[DebugVelocityX] <> '') and
        (StrToInt(FrmDebug.VLE.Values[DebugLimited]) > 0) and
        (StrToInt(FrmDebug.VLE.Values[DebugFrameSteps]) <= MaxStepsPerCallback));
      Press(VK_F3);
      Before := FrmMain.Game.Snapshot;
      Press(VK_F1);
      After := FrmMain.Game.Snapshot;
      Check('diagnostic_step_uses_fixed_seconds', (After.State = gsPaused) and
        (Abs(After.Ball.X - Before.Ball.X - Before.Ball.VelocityX / 120) < 0.00001));
    except
      on E: Exception do
      begin
        Check('unhandled_e3_view_exception', False);
        Report.AddPair('e3_exception', E.ClassName + ': ' + E.Message);
      end;
    end;
    Press(VK_F2);
    Result := Failures = 0;
    Report.RemovePair('suite').Free;
    Report.RemovePair('passed').Free;
    Report.RemovePair('checks').Free;
    Report.RemovePair('failures').Free;
    Report.AddPair('suite', 'E3 stopwatch VCL adapter plus E1/E2 regressions');
    Report.AddPair('passed', TJSONBool.Create(Result));
    Report.AddPair('checks', TJSONNumber.Create(Results.Count));
    Report.AddPair('failures', TJSONNumber.Create(Failures));
    TFile.WriteAllText(TPath.Combine(OutputDirectory, 'checks.json'), Report.Format, TEncoding.UTF8);
  finally
    Report.Free;
  end;
end;

end.
