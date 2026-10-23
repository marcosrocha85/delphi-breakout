unit Breakout.Presentation;

interface

uses Breakout.Types;

const
  BrickFadeDurationMs = 250;
  ScoreCountIntervalMs = 10;
  ScoreCountStep = 1;
  DebugRefreshSeconds = 0.2;

type
  TVisualConfig = record
    FadeDurationMs, CountIntervalMs: Double;
    CountStep: Integer;
    class function Default: TVisualConfig; static;
  end;

  TBrickFade = record
    Brick: TBrick;
    AgeSeconds: Double;
    Active: Boolean;
  end;

  TViewport = record
    Scale, OffsetX, OffsetY, Width, Height: Double;
    class function Fit(ClientWidth, ClientHeight: Integer;
      LogicalWidth: Double = 688; LogicalHeight: Double = 453): TViewport; static;
    function ToLogicalX(ClientX: Double): Double;
  end;

  { No VCL and no OS clock. Sync/Advance mutate presentation; painting only reads. }
  TGamePresentation = class
  private
    FConfig: TVisualConfig;
    FSnapshot: TGameSnapshot;
    FFades: TArray<TBrickFade>;
    FDisplayedScore: Integer;
    FCountRemainder: Double;
    FInitialized: Boolean;
    function GetFade(Index: Integer): TBrickFade;
    function GetFadeCount: Integer;
    function GetPending: Boolean;
  public
    constructor Create(const Config: TVisualConfig);
    procedure Reset(const Snapshot: TGameSnapshot);
    procedure Sync(const Snapshot: TGameSnapshot);
    procedure Advance(ElapsedSeconds: Double; Frozen: Boolean);
    function FadeOpacity(Index: Integer): Double;
    property Snapshot: TGameSnapshot read FSnapshot;
    property DisplayedScore: Integer read FDisplayedScore;
    property FadeCapacity: Integer read GetFadeCount;
    property Fades[Index: Integer]: TBrickFade read GetFade;
    property HasPending: Boolean read GetPending;
  end;

implementation

uses System.SysUtils, System.Math;

class function TVisualConfig.Default: TVisualConfig;
begin
  Result.FadeDurationMs := BrickFadeDurationMs;
  Result.CountIntervalMs := ScoreCountIntervalMs;
  Result.CountStep := ScoreCountStep;
end;

class function TViewport.Fit(ClientWidth, ClientHeight: Integer;
  LogicalWidth, LogicalHeight: Double): TViewport;
begin
  Result := Default(TViewport);
  if (ClientWidth <= 0) or (ClientHeight <= 0) or
     (LogicalWidth <= 0) or (LogicalHeight <= 0) then Exit;
  Result.Scale := Min(ClientWidth / LogicalWidth, ClientHeight / LogicalHeight);
  Result.Width := LogicalWidth * Result.Scale;
  Result.Height := LogicalHeight * Result.Scale;
  Result.OffsetX := (ClientWidth - Result.Width) / 2;
  Result.OffsetY := (ClientHeight - Result.Height) / 2;
end;

function TViewport.ToLogicalX(ClientX: Double): Double;
begin
  if Scale <= 0 then Exit(0);
  Result := (ClientX - OffsetX) / Scale;
end;

constructor TGamePresentation.Create(const Config: TVisualConfig);
begin
  inherited Create;
  if IsNan(Config.FadeDurationMs) or IsInfinite(Config.FadeDurationMs) or
     IsNan(Config.CountIntervalMs) or IsInfinite(Config.CountIntervalMs) or
     (Config.FadeDurationMs <= 0) or (Config.CountIntervalMs <= 0) or
     (Config.CountStep <= 0) then raise EArgumentException.Create('Invalid visual configuration');
  FConfig := Config;
end;

procedure TGamePresentation.Reset(const Snapshot: TGameSnapshot);
begin
  FSnapshot := Snapshot;
  FSnapshot.Bricks := Copy(Snapshot.Bricks);
  FFades := nil;
  SetLength(FFades, Length(Snapshot.Bricks));
  FDisplayedScore := Snapshot.Score;
  FCountRemainder := 0;
  FInitialized := True;
end;

procedure TGamePresentation.Sync(const Snapshot: TGameSnapshot);
var
  I: Integer;
  NewBoard: Boolean;
begin
  if not FInitialized or (Snapshot.Score < FDisplayedScore) then
  begin
    Reset(Snapshot);
    Exit;
  end;
  NewBoard := (Snapshot.Level <> FSnapshot.Level) or (Snapshot.Seed <> FSnapshot.Seed) or
    (Length(Snapshot.Bricks) <> Length(FSnapshot.Bricks));
  if not NewBoard then
    for I := 0 to High(Snapshot.Bricks) do
      if Snapshot.Bricks[I].Id <> FSnapshot.Bricks[I].Id then NewBoard := True;
  if NewBoard then
  begin
    FFades := nil;
    SetLength(FFades, Length(Snapshot.Bricks));
  end
  else
    for I := 0 to High(Snapshot.Bricks) do
      if FSnapshot.Bricks[I].Active and not Snapshot.Bricks[I].Active then
      begin
        FFades[I].Brick := FSnapshot.Bricks[I];
        FFades[I].AgeSeconds := 0;
        FFades[I].Active := True;
      end;
  FSnapshot := Snapshot;
  FSnapshot.Bricks := Copy(Snapshot.Bricks);
end;

procedure TGamePresentation.Advance(ElapsedSeconds: Double; Frozen: Boolean);
var
  I: Integer;
  Interval, AvailableTicks: Double;
  Increment, Debt: Int64;
begin
  if IsNan(ElapsedSeconds) or IsInfinite(ElapsedSeconds) or (ElapsedSeconds < 0) then
    raise EArgumentOutOfRangeException.Create('Invalid visual elapsed time');
  if Frozen then Exit;
  for I := 0 to High(FFades) do
    if FFades[I].Active then
    begin
      FFades[I].AgeSeconds := FFades[I].AgeSeconds + ElapsedSeconds;
      if FFades[I].AgeSeconds + 1.0E-10 >= FConfig.FadeDurationMs / 1000 then
        FFades[I].Active := False;
    end;
  if FDisplayedScore >= FSnapshot.Score then
  begin
    FCountRemainder := 0;
    Exit;
  end;
  Interval := FConfig.CountIntervalMs / 1000;
  FCountRemainder := FCountRemainder + ElapsedSeconds;
  Debt := Int64(FSnapshot.Score) - FDisplayedScore;
  { Arithmetic catch-up, bounded by the target: no loop or overflow per point. }
  AvailableTicks := Floor(Min((FCountRemainder + 1.0E-10) / Interval,
    Ceil(Debt / FConfig.CountStep)));
  Increment := Trunc(Min(AvailableTicks, Ceil(Debt / FConfig.CountStep))) * FConfig.CountStep;
  FDisplayedScore := FDisplayedScore + Integer(Min(Increment, Debt));
  if FDisplayedScore = FSnapshot.Score then FCountRemainder := 0
  else FCountRemainder := Max(0.0, FCountRemainder - AvailableTicks * Interval);
end;

function TGamePresentation.GetFade(Index: Integer): TBrickFade;
begin
  Result := FFades[Index];
end;

function TGamePresentation.GetFadeCount: Integer;
begin
  Result := Length(FFades);
end;

function TGamePresentation.FadeOpacity(Index: Integer): Double;
begin
  if not FFades[Index].Active then Exit(0);
  Result := Max(0.0, 1 - FFades[Index].AgeSeconds * 1000 / FConfig.FadeDurationMs);
end;

function TGamePresentation.GetPending: Boolean;
var
  Fade: TBrickFade;
begin
  if FDisplayedScore < FSnapshot.Score then Exit(True);
  for Fade in FFades do if Fade.Active then Exit(True);
  Result := False;
end;

end.
