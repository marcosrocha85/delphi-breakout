program BaselineRunner;

{$APPTYPE GUI}

uses
  Winapi.Windows, Winapi.PsAPI, System.SysUtils, System.Classes,
  System.Math, System.Diagnostics, Vcl.Forms, Vcl.ExtCtrls,
  UMain in '..\..\UMain.pas',
  UDebug in '..\..\UDebug.pas',
  Breakout.Types in '..\..\src\Breakout.Types.pas',
  Breakout.Texts in '..\..\src\Breakout.Texts.pas',
  Breakout.Bricks in '..\..\src\Breakout.Bricks.pas',
  Breakout.Presentation in '..\..\src\Breakout.Presentation.pas',
  Breakout.Renderer.Vcl in '..\..\src\Breakout.Renderer.Vcl.pas',
  Breakout.Levels in '..\..\src\Breakout.Levels.pas',
  Breakout.Physics in '..\..\src\Breakout.Physics.pas',
  Breakout.Loop in '..\..\src\Breakout.Loop.pas',
  Breakout.Game in '..\..\src\Breakout.Game.pas',
  Breakout.TestScenarios in '..\..\tests\Breakout.TestScenarios.pas',
  UE4ViewChecks in '..\e4\UE4ViewChecks.pas';

type
  TBaseline = class
  private
    FControl: TTimer;
    FOriginalTick, FOriginalPaint: TNotifyEvent;
    FTicks, FPaints, FResources: TStringList;
    FOutput: string;
    FStart, FLastTick, FLastPaint: Int64;
    FPhase: Integer;
    FBenchmark: Boolean;
    procedure Key(Value: Word);
    procedure Tick(Sender: TObject);
    procedure Paint(Sender: TObject);
    procedure Control(Sender: TObject);
    procedure ResourceSample(const Name: string);
    procedure Export;
  public
    constructor Create;
    destructor Destroy; override;
  end;

function Stamp: Int64;
begin Result := TStopwatch.GetTimeStamp; end;
function Ms(Ticks: Int64): Double;
begin Result := Ticks * 1000.0 / TStopwatch.Frequency; end;
function DecNumber(Value: Double): string;
begin Result := FloatToStrF(Value, ffFixed, 18, 4, TFormatSettings.Invariant); end;

constructor TBaseline.Create;
var Root, Parent: string;
begin
  inherited;
  FBenchmark := SameText(ParamStr(1), '--benchmark');
  if FBenchmark and (ParamStr(3) <> '') then FrmMain.Timer1.Interval := StrToInt(ParamStr(3));
  if FBenchmark or SameText(ParamStr(1), '--e4') then FOutput := ParamStr(2)
  else FOutput := ParamStr(1);
  if FOutput = '' then
  begin
    Root := ExtractFileDir(ParamStr(0));
    while not FileExists(Root + '\Breakout.dpr') do
    begin
      Parent := ExtractFileDir(Root);
      if Parent = Root then raise Exception.Create('Repository root not found');
      Root := Parent;
    end;
    FOutput := Root + '\build\e4\latest';
  end;
  ForceDirectories(FOutput);
  FTicks := TStringList.Create; FPaints := TStringList.Create; FResources := TStringList.Create;
  FTicks.Add('phase,time_ms,interval_ms,handler_ms,simulation_ms');
  FPaints.Add('phase,time_ms,interval_ms,draw_ms,present_ms,total_ms');
  FResources.Add('phase,time_ms,cpu_ms,working_set_bytes,private_bytes,handles,gdi_objects,user_objects');
  FOriginalTick := FrmMain.Timer1.OnTimer; FrmMain.Timer1.OnTimer := Tick;
  FOriginalPaint := FrmMain.OnPaint; FrmMain.OnPaint := Paint;
  FControl := TTimer.Create(nil); FControl.Enabled := False;
  FControl.Interval := 100; FControl.OnTimer := Control;
  FPhase := -1; FControl.Enabled := True;
end;

destructor TBaseline.Destroy;
begin
  FControl.Free; FTicks.Free; FPaints.Free; FResources.Free;
  inherited;
end;
procedure TBaseline.Key(Value: Word);
begin FrmMain.FormKeyDown(nil,Value,[]); end;

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

procedure TBaseline.Tick(Sender: TObject);
var Began: Int64; Interval: Double;
begin
  Began := Stamp;
  if FLastTick = 0 then Interval := 0 else Interval := Ms(Began-FLastTick);
  FLastTick := Began;
  FOriginalTick(Sender);
  if FPhase in [0,1] then
    FTicks.Add(Format('%d,%s,%s,%s,%s',[FPhase,DecNumber(Ms(Began-FStart)),
      DecNumber(Interval),DecNumber(Ms(Stamp-Began)),DecNumber(FrmMain.SimulationMs)]));
end;

procedure TBaseline.Paint(Sender: TObject);
var Began: Int64; Interval: Double;
begin
  Began := Stamp;
  if FLastPaint = 0 then Interval := 0 else Interval := Ms(Began-FLastPaint);
  FLastPaint := Began;
  FOriginalPaint(Sender);
  if FPhase in [0,1] then
    FPaints.Add(Format('%d,%s,%s,%s,%s,%s',[FPhase,DecNumber(Ms(Began-FStart)),
      DecNumber(Interval),DecNumber(FrmMain.Renderer.Metrics.DrawMs),
      DecNumber(FrmMain.Renderer.Metrics.PresentMs),DecNumber(Ms(Stamp-Began))]));
end;

procedure TBaseline.Export;
begin
  FTicks.SaveToFile(FOutput+'\timer.csv',TEncoding.UTF8);
  FPaints.SaveToFile(FOutput+'\paint.csv',TEncoding.UTF8);
  FResources.SaveToFile(FOutput+'\resources.csv',TEncoding.UTF8);
end;

procedure TBaseline.Control(Sender: TObject);
begin
  if FPhase = -1 then
  begin
    FControl.Enabled := False;
    if not FBenchmark then
    begin
      FPhase := 2;
      if RunE4ViewChecks(FOutput) then FrmMain.Caption := 'Breakout E4 checks PASSED'
      else FrmMain.Caption := 'Breakout E4 checks FAILED';
      Exit;
    end;
    FStart := Stamp; FPhase := 0; FLastTick := 0; FLastPaint := 0;
    Key(VK_F2); FrmMain.Caption := 'Breakout E4 - sampling without debug';
    ResourceSample('without_debug_start'); Key(VK_SPACE); FControl.Enabled := True;
  end
  else if (FPhase = 0) and (Ms(Stamp-FStart) >= 20000) then
  begin
    ResourceSample('without_debug_end'); Key(VK_F2); Key(VK_F10);
    FPhase := 1; FLastTick := 0; FLastPaint := 0;
    FrmMain.Caption := 'Breakout E4 - sampling with debug';
    ResourceSample('with_debug_start'); Key(VK_SPACE);
  end
  else if (FPhase = 1) and (Ms(Stamp-FStart) >= 40000) then
  begin
    ResourceSample('with_debug_end'); FControl.Enabled := False; FPhase := 2;
    Key(VK_F10); Key(VK_F2); FrmMain.Caption := 'Breakout E4 - ready for manual checks'; Export;
  end
  else
  begin
    { Test driver only: same tracking policy as the E3 baseline. }
    FrmMain.Game.MovePaddle(FrmMain.Game.Snapshot.Ball.X+8);
    if FrmMain.Game.State in [gsReady,gsLevelComplete] then Key(VK_SPACE);
    ResourceSample('sample_'+IntToStr(FPhase));
  end;
end;

var Baseline: TBaseline;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Breakout E4';
  Application.CreateForm(TFrmMain,FrmMain);
  Baseline := TBaseline.Create;
  try Application.Run; finally Baseline.Free; end;
end.
