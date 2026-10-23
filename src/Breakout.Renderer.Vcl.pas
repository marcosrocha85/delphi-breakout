{** VCL/GDI backend: cached sprites, persistent back buffer and HUD layering. }
unit Breakout.Renderer.Vcl;

interface

uses System.Classes, Vcl.Graphics, Breakout.Types, Breakout.Presentation;

type
  {** CPU-side times in ms. IntervalMs spans starts of consecutive Paint
      calls; PaintCount counts completed presentations, not monitor refreshes.
      DrawMs measures composition; PresentMs measures the BitBlt call. }
  TRenderMetrics = record
    DrawMs, PresentMs, IntervalMs: Double;
    PaintCount: Int64;
    BufferResizes: Integer;
  end;

  {** Owns all sprite bitmaps and Buffer. Draws field first and opaque HUD
      last. The supplied presentation remains owned by the caller. }
  TGameRenderer = class
  private
    FBuffer, FBall, FLife: Vcl.Graphics.TBitmap;
    FPaddle: array[0..2] of Vcl.Graphics.TBitmap;
    FBricks: array[0..5] of Vcl.Graphics.TBitmap;
    FViewport: TViewport;
    FMetrics: TRenderMetrics;
    FLastPaint: Int64;
    function ClientX(LogicalX: Double): Integer;
    function ClientY(LogicalY: Double): Integer;
    procedure LoadAssets;
    procedure DrawSprite(Sprite: Vcl.Graphics.TBitmap; X, Y, W, H: Double; Opacity: Byte = 255);
    procedure DrawPaddle(const Paddle: TPaddle);
    procedure DrawHud(const View: TGamePresentation);
  public
    constructor Create;
    destructor Destroy; override;
    {** Composes a complete frame, resizing the buffer only when needed.
        Reads presentation without advancing time. Width/Height are client pixels. }
    procedure Compose(const View: TGamePresentation; Width, Height: Integer);
    {** Composes then presents once to Target and updates paint metrics.
        This is a CPU/GDI measurement; no monitor/vsync completion is measured. }
    procedure Paint(Target: TCanvas; const View: TGamePresentation; Width, Height: Integer);
    {** Borrowed bitmap owned by the renderer; valid until it is destroyed. }
    property Buffer: Vcl.Graphics.TBitmap read FBuffer;
    property Viewport: TViewport read FViewport;
    property Metrics: TRenderMetrics read FMetrics;
  end;

{** Formats with at least nine decimal digits; larger values are not truncated. }
function FormatGameScore(Value: Integer): string;
{** Returns the localized overlay message, or an empty string for normal play. }
function GameMessage(State: TGameState): string;

implementation

uses Winapi.Windows, System.SysUtils, System.Math, System.Diagnostics,
  Vcl.ImgList, Vcl.Controls, Breakout.Texts;

{$R '..\resources\Breakout.Sprites.res' '..\resources\Breakout.Sprites.rc'}

type
  TImageListAccess = class(TImageList);
  TPixel = packed record B, G, R, A: Byte; end;
  {$POINTERMATH ON}
  PPixel = ^TPixel;

const
  { Logical layout preserves the E5 pixels. Related positions share anchors;
    client conversion and rounding always go through ClientX/ClientY. }
  HudHeight = 18;
  HudTop = LogicalFieldHeight - HudHeight;
  HudMargin = 5;
  HudTextTop = HudTop + 2;
  HudFontName = 'MS Sans Serif';
  HudFontHeight = 11;
  LifeIconWidth = 15;
  LifeIconHeight = 10;
  LifeIconStartX = 48;
  LifeIconTop = HudTop + 5;
  LifeIconSpacing = LifeIconWidth;
  MessageBandHeight = 24;
  { Keep the historical center, 1.5 units below the exact field midpoint. }
  MessageCenterY = LogicalFieldHeight / 2 + 1.5;
  MessageBandTop = MessageCenterY - MessageBandHeight / 2;
  MessageBandBottom = MessageBandTop + MessageBandHeight;

function FormatGameScore(Value: Integer): string;
begin
  Result := FormatFloat('000000000', Value);
end;

function GameMessage(State: TGameState): string;
begin
  case State of
    gsReady: Result := SReady;
    gsPaused: Result := SPaused;
    gsGameOver: Result := SGameOver;
    gsLevelComplete: Result := SLevelComplete;
    gsVictory: Result := SVictory;
  else Result := '';
  end;
end;

procedure PrepareAlpha(Bitmap: Vcl.Graphics.TBitmap);
var
  X, Y: Integer;
  Row: PPixel;
begin
  Bitmap.PixelFormat := pf32bit;
  for Y := 0 to Bitmap.Height - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to Bitmap.Width - 1 do
      if (Row[X].R = 0) and (Row[X].G = 0) and (Row[X].B = 0) then Row[X].A := 0
      else Row[X].A := 255;
  end;
  Bitmap.AlphaFormat := afPremultiplied;
end;

function LoadBitmap(const Name: string): Vcl.Graphics.TBitmap;
var
  Stream: TResourceStream;
begin
  Result := Vcl.Graphics.TBitmap.Create;
  try
    Stream := TResourceStream.Create(HInstance, Name, RT_RCDATA);
    try Result.LoadFromStream(Stream); finally Stream.Free; end;
  except
    Result.Free;
    raise;
  end;
end;

constructor TGameRenderer.Create;
begin
  inherited;
  FBuffer := Vcl.Graphics.TBitmap.Create;
  FBuffer.PixelFormat := pf32bit;
  LoadAssets;
end;

destructor TGameRenderer.Destroy;
var
  Sprite: Vcl.Graphics.TBitmap;
begin
  for Sprite in FBricks do Sprite.Free;
  FLife.Free;
  for Sprite in FPaddle do Sprite.Free;
  FBall.Free;
  FBuffer.Free;
  inherited;
end;

procedure TGameRenderer.LoadAssets;
var
  Images: TImageListAccess;
  Stream: TResourceStream;
  Lives: Vcl.Graphics.TBitmap;
  I: Integer;
const
  Parts: array[0..2] of string = ('BO_PADDLE_L', 'BO_PADDLE_M', 'BO_PADDLE_R');
begin
  FBall := LoadBitmap('BO_BALL');
  PrepareAlpha(FBall);
  for I := 0 to High(Parts) do
  begin
    FPaddle[I] := LoadBitmap(Parts[I]);
    PrepareAlpha(FPaddle[I]);
  end;
  Lives := LoadBitmap('BO_LIVES');
  try
    FLife := Vcl.Graphics.TBitmap.Create;
    FLife.SetSize(LifeIconWidth, LifeIconHeight);
    FLife.Canvas.CopyRect(Rect(0, 0, LifeIconWidth, LifeIconHeight),
      Lives.Canvas, Rect(0, 0, LifeIconWidth, LifeIconHeight));
    PrepareAlpha(FLife);
  finally Lives.Free; end;
  Images := TImageListAccess.Create(nil);
  try
    Stream := TResourceStream.Create(HInstance, 'BO_BRICKS', RT_RCDATA);
    try Images.ReadData(Stream); finally Stream.Free; end;
    if Images.Count <> Length(FBricks) then raise EInvalidGraphic.Create('Invalid brick atlas');
    for I := 0 to High(FBricks) do
    begin
      FBricks[I] := Vcl.Graphics.TBitmap.Create;
      Images.GetBitmap(I, FBricks[I]);
      PrepareAlpha(FBricks[I]);
    end;
  finally Images.Free; end;
end;

function TGameRenderer.ClientX(LogicalX: Double): Integer;
begin
  Result := Round(FViewport.OffsetX + LogicalX * FViewport.Scale);
end;

function TGameRenderer.ClientY(LogicalY: Double): Integer;
begin
  Result := Round(FViewport.OffsetY + LogicalY * FViewport.Scale);
end;

procedure TGameRenderer.DrawSprite(Sprite: Vcl.Graphics.TBitmap; X, Y, W, H: Double; Opacity: Byte);
var
  Blend: TBlendFunction;
  L, T, R, B: Integer;
begin
  if Opacity = 0 then Exit;
  L := ClientX(X);
  T := ClientY(Y);
  R := ClientX(X + W);
  B := ClientY(Y + H);
  if (R <= L) or (B <= T) then Exit;
  Blend.BlendOp := AC_SRC_OVER;
  Blend.BlendFlags := 0;
  Blend.SourceConstantAlpha := Opacity;
  Blend.AlphaFormat := AC_SRC_ALPHA;
  Winapi.Windows.AlphaBlend(FBuffer.Canvas.Handle, L, T, R-L, B-T,
    Sprite.Canvas.Handle, 0, 0, Sprite.Width, Sprite.Height, Blend);
end;

procedure TGameRenderer.DrawPaddle(const Paddle: TPaddle);
var
  CapWidth: Double;
begin
  { Original Player's three images: width changes stretch only the striped body.
    Rounded ends keep their aspect ratio, including at a different viewport DPI. }
  CapWidth := Min(Paddle.Width / 2, FPaddle[0].Width * Paddle.Height / FPaddle[0].Height);
  DrawSprite(FPaddle[0], Paddle.X, Paddle.Y, CapWidth, Paddle.Height);
  DrawSprite(FPaddle[1], Paddle.X + CapWidth, Paddle.Y,
    Max(0.0, Paddle.Width - 2 * CapWidth), Paddle.Height);
  DrawSprite(FPaddle[2], Paddle.X + Paddle.Width - CapWidth, Paddle.Y, CapWidth, Paddle.Height);
end;

procedure TGameRenderer.DrawHud(const View: TGamePresentation);
var
  R: TRect;
  Text: string;
  I, Saved: Integer;
begin
  { Layer 1: opaque HUD backing and text are always above every field object. }
  R := Rect(ClientX(0), ClientY(HudTop), ClientX(LogicalFieldWidth), ClientY(LogicalFieldHeight));
  FBuffer.Canvas.Brush.Color := clBlack;
  FBuffer.Canvas.FillRect(R);
  FBuffer.Canvas.Font.Name := HudFontName;
  FBuffer.Canvas.Font.Height := -Max(1, Round(HudFontHeight * FViewport.Scale));
  FBuffer.Canvas.Font.Style := [fsBold];
  FBuffer.Canvas.Font.Color := clWhite;
  FBuffer.Canvas.Brush.Style := bsClear;
  FBuffer.Canvas.TextOut(ClientX(HudMargin), ClientY(HudTextTop), SLives);
  for I := 0 to View.Snapshot.Lives - 1 do
    DrawSprite(FLife, LifeIconStartX + I * LifeIconSpacing, LifeIconTop,
      LifeIconWidth, LifeIconHeight);
  Text := Format(SLevel, [View.Snapshot.Level, View.Snapshot.LevelCount]);
  FBuffer.Canvas.TextOut((R.Left + R.Right - FBuffer.Canvas.TextWidth(Text)) div 2,
    ClientY(HudTextTop), Text);
  Text := SScore + ' ' + FormatGameScore(View.DisplayedScore);
  Saved := SaveDC(FBuffer.Canvas.Handle);
  try
    IntersectClipRect(FBuffer.Canvas.Handle, R.Left, R.Top, R.Right, R.Bottom);
    FBuffer.Canvas.TextOut(R.Right - Round(HudMargin * FViewport.Scale) - FBuffer.Canvas.TextWidth(Text),
      ClientY(HudTextTop), Text);
  finally RestoreDC(FBuffer.Canvas.Handle, Saved); end;
  Text := GameMessage(View.Snapshot.State);
  if Text <> '' then
  begin
    R := Rect(ClientX(0), ClientY(MessageBandTop),
      ClientX(LogicalFieldWidth), ClientY(MessageBandBottom));
    FBuffer.Canvas.Brush.Style := bsSolid;
    FBuffer.Canvas.Brush.Color := clBlack;
    FBuffer.Canvas.FillRect(R);
    FBuffer.Canvas.Brush.Style := bsClear;
    DrawText(FBuffer.Canvas.Handle, PChar(Text), Length(Text), R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
  FBuffer.Canvas.Brush.Style := bsSolid;
end;

procedure TGameRenderer.Compose(const View: TGamePresentation; Width, Height: Integer);
var
  Started: Int64;
  Brick: TBrick;
  Fade: TBrickFade;
  I, Saved: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;
  Started := TStopwatch.GetTimeStamp;
  if (FBuffer.Width <> Width) or (FBuffer.Height <> Height) then
  begin
    FBuffer.SetSize(Width, Height);
    Inc(FMetrics.BufferResizes);
  end;
  FViewport := TViewport.Fit(Width, Height);
  FBuffer.Canvas.Brush.Style := bsSolid;
  FBuffer.Canvas.Brush.Color := clBlack;
  FBuffer.Canvas.FillRect(Rect(0, 0, Width, Height));
  Saved := SaveDC(FBuffer.Canvas.Handle);
  try
    IntersectClipRect(FBuffer.Canvas.Handle, Round(FViewport.OffsetX), Round(FViewport.OffsetY),
      Round(FViewport.OffsetX + FViewport.Width), Round(FViewport.OffsetY + FViewport.Height));
    for Brick in View.Snapshot.Bricks do
      if Brick.Active then DrawSprite(FBricks[Brick.SpriteIndex], Brick.X, Brick.Y, Brick.Width, Brick.Height);
    for I := 0 to View.FadeCapacity - 1 do
    begin
      Fade := View.Fades[I];
      if Fade.Active then
        DrawSprite(FBricks[Fade.Brick.SpriteIndex], Fade.Brick.X, Fade.Brick.Y,
          Fade.Brick.Width, Fade.Brick.Height, Round(View.FadeOpacity(I) * 255));
    end;
    DrawPaddle(View.Snapshot.Paddle);
    DrawSprite(FBall, View.Snapshot.Ball.X, View.Snapshot.Ball.Y,
      View.Snapshot.Ball.Size, View.Snapshot.Ball.Size);
    DrawHud(View);
  finally RestoreDC(FBuffer.Canvas.Handle, Saved); end;
  FMetrics.DrawMs := (TStopwatch.GetTimeStamp - Started) * 1000 / TStopwatch.Frequency;
end;

procedure TGameRenderer.Paint(Target: TCanvas; const View: TGamePresentation; Width, Height: Integer);
var
  Started: Int64;
begin
  if (Width <= 0) or (Height <= 0) then Exit;
  Started := TStopwatch.GetTimeStamp;
  if FLastPaint <> 0 then FMetrics.IntervalMs := (Started - FLastPaint) * 1000 / TStopwatch.Frequency;
  FLastPaint := Started;
  Compose(View, Width, Height);
  Started := TStopwatch.GetTimeStamp;
  BitBlt(Target.Handle, 0, 0, Width, Height, FBuffer.Canvas.Handle, 0, 0, SRCCOPY);
  FMetrics.PresentMs := (TStopwatch.GetTimeStamp - Started) * 1000 / TStopwatch.Frequency;
  Inc(FMetrics.PaintCount);
end;

end.
