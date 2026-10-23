unit UDebug;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Grids, ValEdit,
  Breakout.Types, Breakout.Loop;

const
  DebugLives = 'Lives';
  DebugScore = 'Score';
  DebugPlayerLeft = 'Player Left';
  DebugPlayerTop = 'Player Top';
  DebugBallLeft = 'Ball Left';
  DebugBallTop = 'Ball Top';
  DebugBarLeft = 'Bar Left';
  DebugBarTop = 'Bar Top';
  DebugBarName = 'Bar Name';
  DebugState = 'State';
  DebugLevel = 'Level';
  DebugSeed = 'Seed';
  DebugVelocityX = 'Velocity X /s';
  DebugVelocityY = 'Velocity Y /s';
  DebugActiveBricks = 'Active Bricks';
  DebugFixedStep = 'Fixed step ms';
  DebugFrameSteps = 'Frame steps';
  DebugTotalSteps = 'Total steps';
  DebugAccumulator = 'Accumulator ms';
  DebugDiscarded = 'Discarded ms';
  DebugLimited = 'Limited callbacks';
  DebugCollisionLimit = 'Collision limits';
  DebugCollisionDiscarded = 'Collision lost ms';


type
  TFrmDebug = class(TForm)
    VLE: TValueListEditor;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  public
    procedure UpdateFrom(const Snapshot: TGameSnapshot; const Timing: TLoopDiagnostics);
  end;

var
  FrmDebug: TFrmDebug;

implementation

{$R *.dfm}

procedure TFrmDebug.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Perform(WM_NEXTDLGCTL, 0, 0);
    Key := 0;
  end;
end;

procedure TFrmDebug.FormShow(Sender: TObject);
begin
  VLE.Strings.BeginUpdate;
  try
    VLE.Strings.Clear;
    VLE.InsertRow(DebugLives, '', True);
    VLE.InsertRow(DebugScore, '', True);
    VLE.InsertRow(DebugPlayerLeft, '', True);
    VLE.InsertRow(DebugPlayerTop, '', True);
    VLE.InsertRow(DebugBallLeft, '', True);
    VLE.InsertRow(DebugBallTop, '', True);
    VLE.InsertRow(DebugBarLeft, '', True);
    VLE.InsertRow(DebugBarTop, '', True);
    VLE.InsertRow(DebugBarName, '', True);
    VLE.InsertRow(DebugState, '', True);
    VLE.InsertRow(DebugLevel, '', True);
    VLE.InsertRow(DebugSeed, '', True);
    VLE.InsertRow(DebugVelocityX, '', True);
    VLE.InsertRow(DebugVelocityY, '', True);
    VLE.InsertRow(DebugActiveBricks, '', True);
    VLE.InsertRow(DebugFixedStep, '', True);
    VLE.InsertRow(DebugFrameSteps, '', True);
    VLE.InsertRow(DebugTotalSteps, '', True);
    VLE.InsertRow(DebugAccumulator, '', True);
    VLE.InsertRow(DebugDiscarded, '', True);
    VLE.InsertRow(DebugLimited, '', True);
    VLE.InsertRow(DebugCollisionLimit, '', True);
    VLE.InsertRow(DebugCollisionDiscarded, '', True);

  finally
    VLE.Strings.EndUpdate;
  end;
end;

procedure TFrmDebug.UpdateFrom(const Snapshot: TGameSnapshot; const Timing: TLoopDiagnostics);
var
  Brick: TBrick;
begin
  VLE.Strings.BeginUpdate;
  try
    VLE.Values[DebugLives] := IntToStr(Snapshot.Lives);
    VLE.Values[DebugScore] := IntToStr(Snapshot.Score);
    VLE.Values[DebugPlayerLeft] := IntToStr(Round(Snapshot.Paddle.X));
    VLE.Values[DebugPlayerTop] := IntToStr(Round(Snapshot.Paddle.Y));
    VLE.Values[DebugBallLeft] := IntToStr(Round(Snapshot.Ball.X));
    VLE.Values[DebugBallTop] := IntToStr(Round(Snapshot.Ball.Y));
    VLE.Values[DebugBarName] := '';
    VLE.Values[DebugBarLeft] := '';
    VLE.Values[DebugBarTop] := '';
    for Brick in Snapshot.Bricks do
      if Brick.Id = Snapshot.LastHitBrickId then
      begin
        VLE.Values[DebugBarName] := 'Bar' + IntToStr(Brick.Id);
        VLE.Values[DebugBarLeft] := IntToStr(Round(Brick.X));
        VLE.Values[DebugBarTop] := IntToStr(Round(Brick.Y));
        Break;
      end;
    VLE.Values[DebugState] := GameStateName(Snapshot.State);
    VLE.Values[DebugLevel] := IntToStr(Snapshot.Level);
    VLE.Values[DebugSeed] := UIntToStr(Snapshot.Seed);
    VLE.Values[DebugVelocityX] := FloatToStr(Snapshot.Ball.VelocityX);
    VLE.Values[DebugVelocityY] := FloatToStr(Snapshot.Ball.VelocityY);
    VLE.Values[DebugActiveBricks] := IntToStr(Snapshot.ActiveBricks);
    VLE.Values[DebugFixedStep] := FloatToStrF(FixedDeltaSeconds * 1000, ffFixed, 12, 3);
    VLE.Values[DebugFrameSteps] := IntToStr(Timing.LastSteps);
    VLE.Values[DebugTotalSteps] := IntToStr(Timing.TotalSteps);
    VLE.Values[DebugAccumulator] := FloatToStrF(Timing.AccumulatorSeconds * 1000, ffFixed, 12, 3);
    VLE.Values[DebugDiscarded] := FloatToStrF(Timing.DiscardedSeconds * 1000, ffFixed, 12, 3);
    VLE.Values[DebugLimited] := IntToStr(Timing.LimitedCallbacks);
    VLE.Values[DebugCollisionLimit] := IntToStr(Snapshot.CollisionLimitCount);
    VLE.Values[DebugCollisionDiscarded] := FloatToStrF(Snapshot.CollisionDiscardedSeconds * 1000, ffFixed, 12, 3);
  finally
    VLE.Strings.EndUpdate;
  end;
end;

end.
