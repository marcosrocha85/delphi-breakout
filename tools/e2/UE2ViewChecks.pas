unit UE2ViewChecks;

interface

function RunE2ViewChecks(const OutputDirectory: string): Boolean;

implementation

uses System.SysUtils, System.JSON, System.IOUtils, Winapi.Windows, Vcl.ExtCtrls,
  UMain, UDebug, UE1Checks, Breakout.Types, Breakout.Texts, Breakout.TestScenarios;

function RunE2ViewChecks(const OutputDirectory: string): Boolean;
var
  Report: TJSONObject;
  Results: TJSONArray;
  Failures: Integer;
  Before, After: TGameSnapshot;
  BrickView: TImage;
  Components: Integer;
  Key: Word;
  procedure Check(const Name: string; Passed: Boolean);
  var
    Item: TJSONObject;
  begin
    Item := TJSONObject.Create;
    Item.AddPair('name', Name);
    Item.AddPair('passed', TJSONBool.Create(Passed));
    Item.AddPair('detail', '');
    Results.AddElement(Item);
    if not Passed then Inc(Failures);
  end;
begin
  RunE1Checks(OutputDirectory);
  Report := TJSONObject.ParseJSONValue(TFile.ReadAllText(
    TPath.Combine(OutputDirectory, 'checks.json'), TEncoding.UTF8)) as TJSONObject;
  try
    Results := Report.GetValue<TJSONArray>('results');
    Failures := Report.GetValue<Integer>('failures');
    try
      Before := FrmMain.Game.Snapshot;
      FrmMain.Ball.Left := -999;
      FrmMain.Player.Left := 999;
      BrickView := TImage(FrmMain.FindComponent('Bar0'));
      BrickView.Visible := False;
      BrickView.Tag := 999;
      FrmMain.RefreshView;
      After := FrmMain.Game.Snapshot;
      Check('view_changes_cannot_change_model', (After.Ball.X = Before.Ball.X) and
        (After.Paddle.X = Before.Paddle.X) and (After.Score = Before.Score) and
        After.Bricks[0].Active);
      Check('refresh_restores_controls_from_model',
        (FrmMain.Ball.Left = Round(Before.Ball.X)) and
        (FrmMain.Player.Left = Round(Before.Paddle.X)) and BrickView.Visible);
      FrmMain.Timer1.Enabled := True;
      FrmMain.Timer1Timer(nil);
      After := FrmMain.Game.Snapshot;
      Check('timer_cannot_advance_ready_model', (After.State = gsReady) and
        (After.Ball.X = Before.Ball.X) and (After.Ball.Y = Before.Ball.Y) and
        not FrmMain.Timer1.Enabled);
      Key := VK_F10;
      FrmMain.FormKeyDown(nil, Key, []);
      Check('debug_displays_model_state_seed_and_level',
        (FrmDebug.VLE.Values[DebugState] = 'Ready') and
        (FrmDebug.VLE.Values[DebugSeed] = UIntToStr(Before.Seed)) and
        (FrmDebug.VLE.Values[DebugLevel] = '1') and
        (FrmDebug.VLE.Values[DebugActiveBricks] = '96'));
      After := FrmMain.Game.Snapshot;
      Check('opening_debug_preserves_engine_state', (After.State = Before.State) and
        (After.Ball.X = Before.Ball.X) and (After.Ball.Y = Before.Ball.Y) and
        (After.Ball.StepX = Before.Ball.StepX));
      Key := VK_F10;
      FrmMain.FormKeyDown(nil, Key, []);
      TGameProbe(FrmMain.Game).Fixture;
      FrmMain.RefreshView;
      BrickView := TImage(FrmMain.FindComponent('Bar0'));
      Components := FrmMain.ComponentCount;
      FrmMain.PlayerClick(nil);
      TGameProbe(FrmMain.Game).SetBall(310, 84, 5, 5);
      FrmMain.Timer1Timer(nil);
      Check('hit_hides_view_without_destroying_control_or_id',
        (FrmMain.FindComponent('Bar0') = BrickView) and not BrickView.Visible and
        (FrmMain.ComponentCount = Components) and (FrmMain.Game.Snapshot.LastHitBrickId = 0));
      Before := FrmMain.Game.Snapshot;
      FrmMain.RefreshView;
      FrmMain.RefreshView;
      Check('painting_does_not_score_or_advance_model',
        (FrmMain.Game.Snapshot.Score = Before.Score) and
        (FrmMain.Game.Snapshot.Ball.X = Before.Ball.X) and
        (FrmMain.ScoreLabel.Caption = SScore + ' 000000010'));
      Key := VK_F2;
      FrmMain.FormKeyDown(nil, Key, []);
      FrmMain.PlayerClick(nil);
      TGameProbe(FrmMain.Game).Fixture(True);
      TGameProbe(FrmMain.Game).SetBall(310, 84, 5, 5);
      FrmMain.Timer1Timer(nil);
      Check('victory_snapshot_updates_message_and_stops_timer',
        (FrmMain.Game.Snapshot.State = gsVictory) and not FrmMain.Timer1.Enabled and
        FrmMain.MessageLabel.Visible and (FrmMain.MessageLabel.Caption = SVictory));
      Key := VK_SPACE;
      FrmMain.FormKeyDown(nil, Key, []);
      Check('space_cannot_relaunch_after_victory',
        (FrmMain.Game.Snapshot.State = gsVictory) and not FrmMain.Timer1.Enabled);
    except
      on E: Exception do
      begin
        Check('unhandled_view_exception', False);
        Report.AddPair('exception', E.ClassName + ': ' + E.Message);
      end;
    end;
    Key := VK_F2;
    FrmMain.FormKeyDown(nil, Key, []);
    Result := Failures = 0;
    Report.RemovePair('suite').Free;
    Report.RemovePair('passed').Free;
    Report.RemovePair('checks').Free;
    Report.RemovePair('failures').Free;
    Report.AddPair('suite', 'E2 VCL adapter and E1 flow regressions');
    Report.AddPair('passed', TJSONBool.Create(Result));
    Report.AddPair('checks', TJSONNumber.Create(Results.Count));
    Report.AddPair('failures', TJSONNumber.Create(Failures));
    TFile.WriteAllText(TPath.Combine(OutputDirectory, 'checks.json'), Report.Format, TEncoding.UTF8);
  finally
    Report.Free;
  end;
end;

end.
