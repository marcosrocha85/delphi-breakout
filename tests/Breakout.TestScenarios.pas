unit Breakout.TestScenarios;

interface

uses Breakout.Game, Breakout.Types;

type
  { Test-only arrangement. Never linked into Breakout.dpr. No VCL required. }
  TGameProbe = class(TGame)
  public
    procedure PlaceBall(X, Y: Double);
    procedure SetBall(X, Y, VelocityX, VelocityY: Double);
    procedure Fixture(OnlyOneBrick: Boolean = False);
    procedure PrepareFall;
    procedure SetBricks(const Bricks: TArray<TBrick>);
  end;

implementation

procedure TGameProbe.SetBricks(const Bricks: TArray<TBrick>);
begin
  FBricks := Copy(Bricks);
end;

procedure TGameProbe.PlaceBall(X, Y: Double);
begin
  FBall.X := X;
  FBall.Y := Y;
end;

procedure TGameProbe.SetBall(X, Y, VelocityX, VelocityY: Double);
begin
  PlaceBall(X, Y);
  FBall.VelocityX := VelocityX;
  FBall.VelocityY := VelocityY;
end;

procedure TGameProbe.Fixture(OnlyOneBrick: Boolean);
var
  I: Integer;
begin
  if OnlyOneBrick then SetLength(FBricks, 1) else SetLength(FBricks, 2);
  for I := 0 to High(FBricks) do
  begin
    FBricks[I].Id := I;
    FBricks[I].X := 300 + I * 300;
    FBricks[I].Y := 100 + I * 200;
    FBricks[I].Width := 50;
    FBricks[I].Height := 20;
    FBricks[I].SpriteIndex := 0;
    FBricks[I].Kind := bkGreen;
    FBricks[I].Points := 100;
    FBricks[I].Active := True;
  end;
  FLastHitBrickId := -1;
end;

procedure TGameProbe.PrepareFall;
begin
  FPaddle.X := 300;
  SetBall(20, 454, 0, 240);
end;

end.
