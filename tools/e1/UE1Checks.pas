unit UE1Checks;

interface

function RunE1Checks(const OutputDirectory: string): Boolean;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.JSON,
  System.IOUtils, Vcl.ExtCtrls, UMain, UDebug, Breakout.Types, Breakout.Texts,
  Breakout.TestScenarios;

type
  TE1Checks = class
  private
    FItems: TJSONArray;
    FFailures: Integer;
    procedure Check(const Name: string; Passed: Boolean; const Detail: string = '');
    function Key(Value: Word): Word;
    procedure Reset;
    procedure StartForStep;
    function BrickCount: Integer;
    procedure Run;
  public
    constructor Create;
    destructor Destroy; override;
    function Execute(const OutputDirectory: string): Boolean;
  end;

constructor TE1Checks.Create;
begin
  inherited;
  FItems := TJSONArray.Create;
end;

destructor TE1Checks.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TE1Checks.Check(const Name: string; Passed: Boolean; const Detail: string);
var
  Item: TJSONObject;
begin
  Item := TJSONObject.Create;
  Item.AddPair('name', Name);
  Item.AddPair('passed', TJSONBool.Create(Passed));
  Item.AddPair('detail', Detail);
  FItems.AddElement(Item);
  if not Passed then
    Inc(FFailures);
end;

function TE1Checks.Key(Value: Word): Word;
begin
  FrmMain.FormKeyDown(nil, Value, []);
  Result := Value;
end;

procedure TE1Checks.Reset;
begin
  if Assigned(FrmDebug) then
    Key(VK_F10);
  Key(VK_F2);
end;

procedure TE1Checks.StartForStep;
begin
  FrmMain.PlayerClick(nil);
  { Drive ticks synchronously without waiting for OS timers. }
  FrmMain.Timer1.Enabled := False;
end;

function TE1Checks.BrickCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FrmMain.ComponentCount - 1 do
    if (FrmMain.Components[I] is TImage) and
       (Copy(FrmMain.Components[I].Name, 1, 3) = 'Bar') and TImage(FrmMain.Components[I]).Visible then
      Inc(Result);
end;

procedure TE1Checks.Run;
var
  X, Y, I, Components, WindowLeft, FirstDirection, SecondDirection: Integer;
  ExpectedPlayer, ExpectedBallX, ExpectedBallY: Integer;
begin
  Reset;
  ExpectedPlayer := (FrmMain.ClientWidth - FrmMain.Player.Width) div 2;
  ExpectedBallX := ExpectedPlayer + (FrmMain.Player.Width - FrmMain.Ball.Width) div 2;
  ExpectedBallY := FrmMain.Player.Top - FrmMain.Ball.Height - 8;
  Check('ready_has_96_bricks_and_three_lives',
    (BrickCount = 96) and (FrmMain.VLives.Width = 45));
  Check('ready_has_no_message_or_running_timer',
    not (FrmMain.Timer1.Enabled or FrmMain.MessageLabel.Visible));
  X := FrmMain.Ball.Left;
  Y := FrmMain.Ball.Top;
  Key(VK_F1);
  FrmMain.Timer1Timer(nil);
  Key(VK_F3);
  Check('ready_ignores_step_tick_and_pause',
    (FrmMain.Ball.Left = X) and (FrmMain.Ball.Top = Y) and
    not FrmMain.Timer1.Enabled and not FrmMain.MessageLabel.Visible);

  FrmMain.Game.MovePaddle(125);
  FrmMain.RefreshView;
  X := FrmMain.Ball.Left;
  FrmMain.FormClick(nil);
  Check('click_launch_preserves_paddle_and_ball',
    FrmMain.Timer1.Enabled and (FrmMain.Player.Left = 100) and
    (FrmMain.Ball.Left = X));
  Check('f3_consumes_key_and_pauses_immediately',
    (Key(VK_F3) = 0) and not FrmMain.Timer1.Enabled and FrmMain.MessageLabel.Visible);
  X := FrmMain.Ball.Left;
  Y := FrmMain.Ball.Top;
  Check('space_consumes_key_while_paused', Key(VK_SPACE) = 0);
  FrmMain.FormClick(nil);
  FrmMain.PlayerClick(nil);
  Key(VK_F1);
  FrmMain.Timer1Timer(nil);
  Check('all_launch_paths_and_ticks_preserve_pause',
    not FrmMain.Timer1.Enabled and FrmMain.MessageLabel.Visible and
    (FrmMain.Ball.Left = X) and (FrmMain.Ball.Top = Y));
  Key(VK_F3);
  Check('resume_preserves_position_and_hides_message',
    FrmMain.Timer1.Enabled and not FrmMain.MessageLabel.Visible and
    (FrmMain.Ball.Left = X) and (FrmMain.Ball.Top = Y));
  FrmMain.ApplicationEvents1Deactivate(nil);
  Check('deactivation_pauses', not FrmMain.Timer1.Enabled and FrmMain.MessageLabel.Visible);
  Key(VK_F3);
  Check('resume_after_deactivation_preserves_position',
    FrmMain.Timer1.Enabled and not FrmMain.MessageLabel.Visible and
    (FrmMain.Ball.Left = X) and (FrmMain.Ball.Top = Y));
  Key(VK_F2);
  Check('f2_during_play_returns_to_ready',
    not FrmMain.Timer1.Enabled and not FrmMain.MessageLabel.Visible and (BrickCount = 96));
  Key(VK_SPACE);
  Check('space_launches_from_ready', FrmMain.Timer1.Enabled);
  Key(VK_F3);
  Key(VK_F2);
  Check('f2_during_pause_clears_pause_message',
    not FrmMain.Timer1.Enabled and not FrmMain.MessageLabel.Visible);

  for I := 1 to 3 do
  begin
    StartForStep;
    TGameProbe(FrmMain.Game).PrepareFall;
    FrmMain.Timer1Timer(nil);
    Check('fall_' + IntToStr(I) + '_removes_one_life',
      FrmMain.VLives.Width = (3 - I) * 15);
    Check('fall_' + IntToStr(I) + '_repositions_without_extra_motion',
      (FrmMain.Player.Left = ExpectedPlayer) and
      (FrmMain.Ball.Left = ExpectedBallX) and (FrmMain.Ball.Top = ExpectedBallY) and
      not FrmMain.Timer1.Enabled);
    FrmMain.Timer1Timer(nil);
    Check('idle_tick_after_fall_' + IntToStr(I) + '_is_ignored',
      (FrmMain.VLives.Width = (3 - I) * 15) and
      (FrmMain.Ball.Left = ExpectedBallX) and (FrmMain.Ball.Top = ExpectedBallY));
  end;
  Check('game_over_has_message', FrmMain.MessageLabel.Visible and
    (FrmMain.MessageLabel.Caption = SGameOver));
  FrmMain.FormClick(nil);
  FrmMain.PlayerClick(nil);
  Key(VK_SPACE);
  Key(VK_F1);
  FrmMain.Timer1Timer(nil);
  Check('game_over_ignores_launch_and_step', not FrmMain.Timer1.Enabled and
    (FrmMain.Ball.Left = ExpectedBallX) and (FrmMain.Ball.Top = ExpectedBallY));
  Reset;
  Check('restart_after_game_over_restores_score_lives_and_bricks',
    (FrmMain.VLives.Width = 45) and (BrickCount = 96) and
    (FrmMain.ScoreLabel.Caption = SScore + ' 000000000'));

  WindowLeft := FrmMain.Left;
  X := FrmMain.Ball.Left;
  Y := FrmMain.Ball.Top;
  Check('f10_consumes_key', Key(VK_F10) = 0);
  Check('debug_opens_with_form_owner_and_fifteen_keys', Assigned(FrmDebug) and
    (FrmDebug.Owner = FrmMain) and (FrmDebug.VLE.Strings.Count = 15));
  Check('debug_toggle_preserves_main_window_position', FrmMain.Left = WindowLeft);
  Key(VK_F1);
  Check('debug_cannot_step_ready', (FrmMain.Ball.Left = X) and (FrmMain.Ball.Top = Y));
  StartForStep;
  X := FrmMain.Ball.Left;
  Y := FrmMain.Ball.Top;
  Key(VK_F1);
  Check('debug_cannot_step_unpaused_game', (FrmMain.Ball.Left = X) and (FrmMain.Ball.Top = Y));
  Key(VK_F3);
  Key(VK_F1);
  Check('debug_can_step_paused_game_once', not FrmMain.Timer1.Enabled and
    FrmMain.MessageLabel.Visible and (Abs(FrmMain.Ball.Left-X) = 5) and
    (FrmMain.Ball.Top = Y-5));
  Check('debug_reports_post_step_position_with_stable_keys',
    (FrmDebug.VLE.Values[DebugBallLeft] = IntToStr(FrmMain.Ball.Left)) and
    (FrmDebug.VLE.Values[DebugBallTop] = IntToStr(FrmMain.Ball.Top)) and
    (FrmDebug.VLE.Values[DebugLives] = '3') and (FrmDebug.VLE.Strings.Count = 15));
  FrmDebug.Close;
  X := FrmMain.Ball.Left;
  Y := FrmMain.Ball.Top;
  Key(VK_F1);
  Check('hidden_debug_disables_manual_step', not FrmDebug.Visible and
    (FrmMain.Ball.Left = X) and (FrmMain.Ball.Top = Y));
  Key(VK_F10);
  Check('f10_reopens_hidden_debug_with_current_values', FrmDebug.Visible and
    (FrmDebug.VLE.Values[DebugBallLeft] = IntToStr(X)) and
    (FrmDebug.VLE.Values[DebugBallTop] = IntToStr(Y)) and
    (FrmDebug.VLE.Strings.Count = 15));
  Key(VK_F10);
  X := FrmMain.Ball.Left;
  Y := FrmMain.Ball.Top;
  Key(VK_F1);
  Check('closing_debug_disables_manual_step', not Assigned(FrmDebug) and
    (FrmMain.Ball.Left = X) and (FrmMain.Ball.Top = Y));

  Check('score_zero', TFrmMain.FormatScore(0) = '000000000');
  Check('score_42', TFrmMain.FormatScore(42) = '000000042');
  Check('score_nine_digits', TFrmMain.FormatScore(999999999) = '999999999');
  Check('score_ten_digits', TFrmMain.FormatScore(1000000000) = '1000000000');
  Check('score_max_integer', TFrmMain.FormatScore(MaxInt) = IntToStr(MaxInt));
  Check('hud_labels_have_form_owner',
    (FrmMain.MessageLabel.Owner = FrmMain) and (FrmMain.ScoreLabel.Owner = FrmMain) and
    (FrmMain.LivesLabel.Owner = FrmMain));

  FrmMain.Left := 0;
  RandSeed := 12345;
  Reset;
  StartForStep;
  TGameProbe(FrmMain.Game).PlaceBall(300, 300);
  FrmMain.Timer1Timer(nil);
  FirstDirection := FrmMain.Ball.Left - 300;
  FrmMain.Left := 200;
  RandSeed := 12345;
  Reset;
  StartForStep;
  TGameProbe(FrmMain.Game).PlaceBall(300, 300);
  FrmMain.Timer1Timer(nil);
  SecondDirection := FrmMain.Ball.Left - 300;
  FrmMain.Left := WindowLeft;
  Check('seeded_direction_is_independent_of_window_left',
    (FirstDirection = SecondDirection) and (Abs(FirstDirection) = 5));
  Reset;
  Components := FrmMain.ComponentCount;
  for I := 1 to 50 do
    Key(VK_F2);
  Check('fifty_restarts_keep_component_and_brick_counts',
    (FrmMain.ComponentCount = Components) and (BrickCount = 96) and
    (FrmMain.VLives.Width = 45) and not FrmMain.Timer1.Enabled);
end;

function TE1Checks.Execute(const OutputDirectory: string): Boolean;
var
  Report: TJSONObject;
begin
  try
    Run;
  except
    on E: Exception do
      Check('unhandled_exception', False, E.ClassName + ': ' + E.Message);
  end;
  Report := TJSONObject.Create;
  try
    Result := FFailures = 0;
    Report.AddPair('suite', 'E1 game-flow regressions');
    Report.AddPair('passed', TJSONBool.Create(Result));
    Report.AddPair('checks', TJSONNumber.Create(FItems.Count));
    Report.AddPair('failures', TJSONNumber.Create(FFailures));
    Report.AddPair('results', FItems);
    FItems := nil;
    TFile.WriteAllText(TPath.Combine(OutputDirectory, 'checks.json'), Report.Format,
      TEncoding.UTF8);
  finally
    Report.Free;
  end;
  Reset;
end;

function RunE1Checks(const OutputDirectory: string): Boolean;
var
  Checks: TE1Checks;
begin
  ForceDirectories(OutputDirectory);
  Checks := TE1Checks.Create;
  try
    Result := Checks.Execute(OutputDirectory);
  finally
    Checks.Free;
  end;
end;

end.
