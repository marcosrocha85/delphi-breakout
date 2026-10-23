{** Read model, time-driven feedback and uniform logical/client transform. }
unit Breakout.Presentation;

interface

uses Breakout.Types;

const
  {** Default duration of the image left by a destroyed brick, in ms. }
  BrickFadeDurationMs = 250;
  {** Default interval per score increment, in ms: 5 ms means 200 points/s. }
  ScoreCountIntervalMs = 5;
  {** Default number of points per logical score increment. }
  ScoreCountStep = 1;
  {** Diagnostic refresh period, independent of painting and simulation. }
  DebugRefreshSeconds = 0.2;

type
  {** Positive finite durations in milliseconds and positive integer step. }
  TVisualConfig = record
    FadeDurationMs, CountIntervalMs: Double;
    CountStep: Integer;
    class function Default: TVisualConfig; static;
  end;

  {** Visual residue only; Brick is no longer a collider. Age is seconds. }
  TBrickFade = record
    Brick: TBrick;
    AgeSeconds: Double;
    Active: Boolean;
  end;

  {** Uniform scale plus centered letterbox offsets in client pixels. }
  TViewport = record
    Scale, OffsetX, OffsetY, Width, Height: Double;
    {** Fits the logical field without stretching; nonpositive dimensions
        produce a zero viewport. This does not resize the application window. }
    class function Fit(ClientWidth, ClientHeight: Integer;
      LogicalWidth: Double = 688; LogicalHeight: Double = 453): TViewport; static;
    {** Inverts horizontal input; a zero viewport safely returns zero. }
    function ToLogicalX(ClientX: Double): Double;
  end;

  {** Owns a copied snapshot, bounded fade slots and a displayed score.
      Sync/Advance mutate presentation; painting only reads. No VCL or OS clock. }
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
    {** Validates positive finite durations and a positive count step.
        Raises @code(EArgumentException) on invalid visual configuration. }
    constructor Create(const Config: TVisualConfig);
    {** Copies state, clears fades/debt and sets displayed score to actual score. }
    procedure Reset(const Snapshot: TGameSnapshot);
    {** Copies state and detects active-to-inactive brick transitions.
        A new board clears old fades while preserving score debt; restart
        should explicitly call Reset. }
    procedure Sync(const Snapshot: TGameSnapshot);
    {** Advances fade ages and score using elapsed time, with arithmetic
        catch-up bounded by the target. The caller applies any elapsed cap.
        @param(ElapsedSeconds Finite, nonnegative elapsed seconds.)
        @param(Frozen When True, neither animation nor score advances.)
        Raises @code(EArgumentOutOfRangeException) on invalid elapsed time. }
    procedure Advance(ElapsedSeconds: Double; Frozen: Boolean);
    {** Returns linear opacity in [0,1], or zero for an inactive fade. }
    function FadeOpacity(Index: Integer): Double;
    property Snapshot: TGameSnapshot read FSnapshot;
    property DisplayedScore: Integer read FDisplayedScore;
    property FadeCapacity: Integer read GetFadeCount;
    property Fades[Index: Integer]: TBrickFade read GetFade;
    {** True while score debt or any active fade still needs visual time. }
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
