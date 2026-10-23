program BaselineRunner;

{$APPTYPE GUI}

uses
  Winapi.Windows, Winapi.PsAPI, System.SysUtils, System.Classes,
  System.Math, System.Diagnostics, System.Generics.Collections,
  Vcl.Forms, Vcl.ExtCtrls,
  UMain in '..\..\UMain.pas',
  UDebug in '..\..\UDebug.pas',
  UE1Checks in '..\e1\UE1Checks.pas',
  Breakout.Types in '..\..\src\Breakout.Types.pas',
  Breakout.Texts in '..\..\src\Breakout.Texts.pas',
  Breakout.Levels in '..\..\src\Breakout.Levels.pas',
  Breakout.Game in '..\..\src\Breakout.Game.pas',
  Breakout.TestScenarios in '..\..\tests\Breakout.TestScenarios.pas',
  UE2ViewChecks in '..\e2\UE2ViewChecks.pas';

type
  TTickSample = record
    Phase: Integer;
    TimeMs, IntervalMs, DurationMs: Double;
    X, Y: Integer;
  end;

  TBaseline = class
  private
    FControl: TTimer;
    FOriginalTick: TNotifyEvent;
    FSamples: TList<TTickSample>;
    FResults, FResources: TStringList;
    FOutput: string;
    FStart, FLastTick: Int64;
    FPhase: Integer;
    FE1Only, FE2Only: Boolean;
    procedure Key(AKey: Word);
    procedure Reset;
    procedure Fixture;
    procedure PrimeDown;
    function BrickCount: Integer;
    procedure Observe(const Name: string; DX, DY: Integer);
    procedure ResourceSample(const Name: string);
    procedure Scenarios;
    procedure Tick(Sender: TObject);
    procedure Control(Sender: TObject);
    procedure Export;
  public
    constructor Create;
    destructor Destroy; override;
  end;

function Stamp: Int64;
begin
  Result := TStopwatch.GetTimeStamp;
end;

function Ms(Ticks: Int64): Double;
begin
  Result := Ticks * 1000.0 / TStopwatch.Frequency;
end;

function DecNumber(Value: Double): string;
begin
  Result := FloatToStrF(Value, ffFixed, 18, 4, TFormatSettings.Invariant);
end;

constructor TBaseline.Create;
var
  Root, Parent: string;
begin
  inherited;
  FE1Only := SameText(ParamStr(1), '--e1');
  FE2Only := SameText(ParamStr(1), '--e2');
  if FE1Only or FE2Only then FOutput := ParamStr(2)
  else FOutput := ParamStr(1);
  if FOutput = '' then
  begin
    Root := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
    while not FileExists(Root + '\Breakout.dpr') do
    begin
      Parent := ExtractFileDir(Root);
      if Parent = Root then raise Exception.Create('Repository root not found');
      Root := Parent;
    end;
    if FE2Only then FOutput := Root + '\build\e2\latest'
    else if FE1Only then FOutput := Root + '\build\e1\latest'
    else FOutput := Root + '\build\baseline-runs\' +
      FormatDateTime('yyyymmdd-hhnnsszzz', Now);
  end;
  ForceDirectories(FOutput);
  FSamples := TList<TTickSample>.Create;
  FResults := TStringList.Create;
  FResources := TStringList.Create;
  FResults.Add('scenario,ball_x,ball_y,dx,dy,paddle_x,lives_width,bricks,timer_enabled,message_visible,message,score');
  FResources.Add('phase,time_ms,cpu_ms,working_set_bytes,private_bytes,handles,gdi_objects,user_objects');
  FOriginalTick := FrmMain.Timer1.OnTimer;
  FrmMain.Timer1.OnTimer := Tick;
  FControl := TTimer.Create(nil);
  FControl.Enabled := False;
  FControl.Interval := 100;
  FControl.OnTimer := Control;
  FPhase := -1;
  FControl.Enabled := True;
end;

destructor TBaseline.Destroy;
begin
  FControl.Free;
  FSamples.Free;
  FResults.Free;
  FResources.Free;
  inherited;
end;

procedure TBaseline.Key(AKey: Word);
begin
  FrmMain.FormKeyDown(nil, AKey, []);
end;

procedure TBaseline.Reset;
begin
  Key(VK_F2);
end;

function TBaseline.BrickCount: Integer;
begin
  Result := FrmMain.Game.Snapshot.ActiveBricks;
end;

procedure TBaseline.Fixture;
begin
  { A second distant brick keeps the scenario away from level completion. }
  TGameProbe(FrmMain.Game).Fixture;
  FrmMain.RefreshView;
end;

procedure TBaseline.PrimeDown;
begin
  FrmMain.PlayerClick(nil);
  FrmMain.Timer1.Enabled := False;
  TGameProbe(FrmMain.Game).PlaceBall(20, -10);
  FrmMain.Timer1Timer(nil);
end;

procedure TBaseline.Observe(const Name: string; DX, DY: Integer);
begin
  FrmMain.RefreshView;
  FResults.Add(Format('%s,%d,%d,%d,%d,%d,%d,%d,%s,%s,"%s","%s"',
    [Name, FrmMain.Ball.Left, FrmMain.Ball.Top, DX, DY,
     FrmMain.Player.Left, FrmMain.VLives.Width, BrickCount,
     BoolToStr(FrmMain.Timer1.Enabled, True),
     BoolToStr(FrmMain.MessageLabel.Visible, True),
     FrmMain.MessageLabel.Caption, FrmMain.ScoreLabel.Caption]));
end;

procedure TBaseline.ResourceSample(const Name: string);
var
  Creation, ExitTime, KernelTime, UserTime: TFileTime;
  Memory: TProcessMemoryCountersEx;
  KernelTicks, UserTicks: UInt64;
  Handles: DWORD;
begin
  GetProcessTimes(GetCurrentProcess, Creation, ExitTime, KernelTime, UserTime);
  KernelTicks := (UInt64(KernelTime.dwHighDateTime) shl 32) or KernelTime.dwLowDateTime;
  UserTicks := (UInt64(UserTime.dwHighDateTime) shl 32) or UserTime.dwLowDateTime;
  ZeroMemory(@Memory, SizeOf(Memory));
  Memory.cb := SizeOf(Memory);
  GetProcessMemoryInfo(GetCurrentProcess, @Memory, SizeOf(Memory));
  GetProcessHandleCount(GetCurrentProcess, Handles);
  FResources.Add(Format('%s,%s,%s,%s,%s,%d,%d,%d',
    [Name, DecNumber(Ms(Stamp - FStart)),
     DecNumber((KernelTicks + UserTicks) / 10000.0),
     UIntToStr(Memory.WorkingSetSize), UIntToStr(Memory.PrivateUsage),
     Handles, GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS),
     GetGuiResources(GetCurrentProcess, GR_USEROBJECTS)]));
end;

procedure TBaseline.Scenarios;
var
  X, Y, I: Integer;
  Hits: array[0..2] of Integer;
begin
  Observe('initial', 0, 0);
  X := FrmMain.Ball.Left;
  Y := FrmMain.Ball.Top;
  Key(VK_F1);
  Observe('f1_before_launch', FrmMain.Ball.Left-X, FrmMain.Ball.Top-Y);
  Reset;
  FrmMain.PlayerClick(nil);
  Observe('launch_click', 0, 0);
  TGameProbe(FrmMain.Game).PlaceBall(500, 300);
  FrmMain.Timer1Timer(nil);
  Key(VK_F3);
  Observe('pause_f3', 0, 0);
  Key(VK_SPACE);
  Observe('space_while_paused', 0, 0);
  { The immediate-pause case must not depend on space having relaunched. }
  Reset;
  FrmMain.PlayerClick(nil);
  Key(VK_F3);
  Observe('f3_immediately_after_launch', 0, 0);
  Key(VK_F3);
  FrmMain.Timer1Timer(nil);
  Key(VK_F3);
  Observe('pause_after_first_tick', 0, 0);
  X := FrmMain.Ball.Left;
  Y := FrmMain.Ball.Top;
  Key(VK_F3);
  Observe('resume_f3', FrmMain.Ball.Left-X, FrmMain.Ball.Top-Y);
  FrmMain.ApplicationEvents1Deactivate(nil);
  Observe('deactivate_handler', 0, 0);
  Reset;
  Key(VK_SPACE);
  Observe('launch_space', 0, 0);
  Reset;
  Fixture;
  PrimeDown;
  TGameProbe(FrmMain.Game).PlaceBall(310, 84);
  FrmMain.Timer1Timer(nil);
  Observe('brick_top_downward', FrmMain.Ball.Left-310, FrmMain.Ball.Top-84);
  Reset;
  Fixture;
  FrmMain.PlayerClick(nil);
  FrmMain.Timer1.Enabled := False;
  TGameProbe(FrmMain.Game).PlaceBall(310, 119);
  FrmMain.Timer1Timer(nil);
  Observe('brick_bottom_upward', FrmMain.Ball.Left-310, FrmMain.Ball.Top-119);
  Hits[0] := 296;
  Hits[1] := 320;
  Hits[2] := 340;
  for I := 0 to 2 do
  begin
    Reset;
    Fixture;
    PrimeDown;
    FrmMain.Game.MovePaddle(325);
    TGameProbe(FrmMain.Game).PlaceBall(Hits[I], 398);
    FrmMain.Timer1Timer(nil);
    Observe('paddle_region_' + IntToStr(I), FrmMain.Ball.Left-Hits[I], FrmMain.Ball.Top-398);
  end;
  Reset;
  Fixture;
  PrimeDown;
  for I := 1 to 3 do
  begin
    FrmMain.PlayerClick(nil);
    FrmMain.Timer1.Enabled := False;
    TGameProbe(FrmMain.Game).PlaceBall(20, 440);
    FrmMain.Timer1Timer(nil);
    Observe('lose_life_' + IntToStr(I), FrmMain.Ball.Left-335, FrmMain.Ball.Top-395);
  end;
  FrmMain.PlayerClick(nil);
  Observe('click_at_game_over', 0, 0);
  Key(VK_F1);
  Observe('f1_at_game_over', 0, 0);
  Reset;
  Observe('restart_f2', 0, 0);
end;

procedure TBaseline.Tick(Sender: TObject);
var
  S: TTickSample;
  Began: Int64;
begin
  Began := Stamp;
  S.Phase := FPhase;
  S.TimeMs := Ms(Began-FStart);
  if FLastTick = 0 then S.IntervalMs := 0
  else S.IntervalMs := Ms(Began-FLastTick);
  FLastTick := Began;
  FOriginalTick(Sender);
  S.DurationMs := Ms(Stamp-Began);
  S.X := FrmMain.Ball.Left;
  S.Y := FrmMain.Ball.Top;
  if FPhase in [0, 1] then FSamples.Add(S);
end;

procedure TBaseline.Export;
var
  Lines: TStringList;
  S: TTickSample;
begin
  FResults.SaveToFile(FOutput + '\scenarios.csv', TEncoding.UTF8);
  FResources.SaveToFile(FOutput + '\resources.csv', TEncoding.UTF8);
  Lines := TStringList.Create;
  try
    Lines.Add('phase,time_ms,interval_ms,handler_ms,ball_x,ball_y');
    for S in FSamples do
      Lines.Add(Format('%d,%s,%s,%s,%d,%d', [S.Phase,
        DecNumber(S.TimeMs), DecNumber(S.IntervalMs),
        DecNumber(S.DurationMs), S.X, S.Y]));
    Lines.SaveToFile(FOutput + '\timer.csv', TEncoding.UTF8);
  finally
    Lines.Free;
  end;
end;

procedure TBaseline.Control(Sender: TObject);
begin
  if FPhase = -1 then
  begin
    FControl.Enabled := False;
    if FE1Only or FE2Only then
    begin
      FPhase := 2;
      if FE2Only then
      begin
        if RunE2ViewChecks(FOutput) then
          FrmMain.Caption := 'Breakout E2 - checks passed'
        else
          FrmMain.Caption := 'Breakout E2 - checks failed';
      end
      else if RunE1Checks(FOutput) then
        FrmMain.Caption := 'Breakout E1 - checks passed'
      else
        FrmMain.Caption := 'Breakout E1 - checks failed';
      Exit;
    end;
    Scenarios;
    FStart := Stamp;
    FLastTick := 0;
    FPhase := 0;
    FrmMain.Caption := 'Breakout E0 - sampling without debug';
    ResourceSample('without_debug_start');
    FrmMain.PlayerClick(nil);
    FControl.Enabled := True;
  end
  else if (FPhase = 0) and (Ms(Stamp-FStart) >= 20000) then
  begin
    ResourceSample('without_debug_end');
    Reset;
    Key(VK_F10);
    FPhase := 1;
    FLastTick := 0;
    FrmMain.Caption := 'Breakout E0 - sampling with debug';
    ResourceSample('with_debug_start');
    FrmMain.PlayerClick(nil);
  end
  else if (FPhase = 1) and (Ms(Stamp-FStart) >= 40000) then
  begin
    ResourceSample('with_debug_end');
    FControl.Enabled := False;
    FPhase := 2;
    Key(VK_F10);
    Reset;
    FrmMain.Caption := 'Breakout E0 - ready for manual checks';
    Export;
  end
  else
  begin
    { Test driver keeps the paddle below the ball; it is not production input. }
    FrmMain.Game.MovePaddle(FrmMain.Game.Snapshot.Ball.X + 8);
    if not FrmMain.Timer1.Enabled then FrmMain.PlayerClick(nil);
    ResourceSample('sample_' + IntToStr(FPhase));
  end;
end;

var
  Baseline: TBaseline;
begin
  Application.Initialize;
  { Harness only: expose the legacy form as a targetable taskbar window. }
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Breakout E0';
  Application.CreateForm(TFrmMain, FrmMain);
  Baseline := TBaseline.Create;
  try
    Application.Run;
  finally
    Baseline.Free;
  end;
end.
