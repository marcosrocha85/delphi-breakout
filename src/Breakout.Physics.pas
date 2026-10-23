unit Breakout.Physics;

interface

type
  TPhysicsRect = record
    Left, Top, Right, Bottom: Double;
    class function Create(X, Y, Width, Height: Double): TPhysicsRect; static;
  end;

  TCircleHit = record
    Time, NormalX, NormalY, Penetration: Double;
  end;

const
  PositionEpsilon = 1.0E-6;
  TimeEpsilon = 1.0E-10;

{ Center coordinates, radius and velocity/second. The rounded boundary consists
  of four face segments and four circular arcs, not an expanded AABB. }
function SweepCircleRect(CX, CY, Radius, VX, VY, MaxTime: Double;
  const Rect: TPhysicsRect; out Hit: TCircleHit): Boolean;
function SweepCirclePaddle(CX, CY, Radius, VX, VY, MaxTime: Double;
  const Rect: TPhysicsRect; out Hit: TCircleHit): Boolean;
procedure ReflectVelocity(var VX, VY: Double; NX, NY: Double);
procedure PaddleVelocity(Offset, Speed, IncomingVX, MinAngle, MaxAngle: Double;
  out VX, VY: Double);

implementation

uses System.Math;

function SweepCirclePaddle(CX, CY, Radius, VX, VY, MaxTime: Double;
  const Rect: TPhysicsRect; out Hit: TCircleHit): Boolean;
var
  CapRadius: Double;
  Core: TPhysicsRect;
begin
  { The 50x15 sprite is a horizontal capsule. Sweep the ball against its
    center segment, dilated by the sum of the ball and end-cap radii. }
  CapRadius := (Rect.Bottom - Rect.Top) / 2;
  Core := TPhysicsRect.Create(Rect.Left + CapRadius, Rect.Top + CapRadius,
    Rect.Right - Rect.Left - 2 * CapRadius, 0);
  Result := SweepCircleRect(CX, CY, Radius + CapRadius, VX, VY, MaxTime, Core, Hit);
end;

class function TPhysicsRect.Create(X, Y, Width, Height: Double): TPhysicsRect;
begin
  Result.Left := X;
  Result.Top := Y;
  Result.Right := X + Width;
  Result.Bottom := Y + Height;
end;

procedure ReflectVelocity(var VX, VY: Double; NX, NY: Double);
var
  Dot: Double;
begin
  Dot := VX * NX + VY * NY;
  if Dot >= 0 then Exit; // a separating overlap must never bounce back inside
  VX := VX - 2 * Dot * NX;
  VY := VY - 2 * Dot * NY;
end;

procedure PaddleVelocity(Offset, Speed, IncomingVX, MinAngle, MaxAngle: Double;
  out VX, VY: Double);
var
  Angle: Double;
begin
  Angle := EnsureRange(Offset, -1.0, 1.0) * MaxAngle;
  if Abs(Angle) < MinAngle then
  begin
    if (Angle < 0) or ((Abs(Angle) < TimeEpsilon) and (IncomingVX < 0)) then
      Angle := -MinAngle
    else Angle := MinAngle;
  end;
  Angle := DegToRad(Angle);
  VX := Speed * Sin(Angle);
  VY := -Speed * Cos(Angle);
end;

function SweepCircleRect(CX, CY, Radius, VX, VY, MaxTime: Double;
  const Rect: TPhysicsRect; out Hit: TCircleHit): Boolean;
var
  QX, QY, DX, DY, Distance, T, AtContact, BestDistance: Double;

  procedure Candidate(Time, NX, NY: Double);
  begin
    if (Time < -TimeEpsilon) or (Time > MaxTime + TimeEpsilon) or
       (VX * NX + VY * NY >= -TimeEpsilon) then Exit;
    Time := EnsureRange(Time, 0.0, MaxTime);
    if Result and (Time >= Hit.Time - TimeEpsilon) then Exit;
    Result := True;
    Hit.Time := Time;
    Hit.NormalX := NX;
    Hit.NormalY := NY;
    Hit.Penetration := 0;
  end;

  procedure InsideFace(D, NX, NY: Double);
  begin
    if D >= BestDistance then Exit;
    BestDistance := D;
    Hit.NormalX := NX;
    Hit.NormalY := NY;
  end;

  procedure Corner(X, Y, SX, SY: Double);
  var
    OX, OY, A, B, C, Discriminant, CT, NX, NY, LengthN: Double;
  begin
    OX := CX - X;
    OY := CY - Y;
    A := VX * VX + VY * VY;
    if A <= TimeEpsilon * TimeEpsilon then Exit;
    B := OX * VX + OY * VY;
    C := OX * OX + OY * OY - Radius * Radius;
    Discriminant := B * B - A * C;
    if Discriminant < 0 then Exit;
    CT := (-B - Sqrt(Discriminant)) / A;
    if (CT < -TimeEpsilon) or (CT > MaxTime + TimeEpsilon) then Exit;
    NX := CX + VX * CT - X;
    NY := CY + VY * CT - Y;
    if (NX * SX < -PositionEpsilon) or (NY * SY < -PositionEpsilon) then Exit;
    LengthN := Hypot(NX, NY);
    if LengthN <= TimeEpsilon then Exit;
    Candidate(CT, NX / LengthN, NY / LengthN);
  end;

begin
  Result := False;
  Hit := Default(TCircleHit);
  QX := EnsureRange(CX, Rect.Left, Rect.Right);
  QY := EnsureRange(CY, Rect.Top, Rect.Bottom);
  DX := CX - QX;
  DY := CY - QY;
  Distance := Hypot(DX, DY);
  if Distance < Radius - TimeEpsilon then
  begin
    Result := True;
    if Distance > TimeEpsilon then
    begin
      Hit.NormalX := DX / Distance;
      Hit.NormalY := DY / Distance;
      Hit.Penetration := Radius - Distance;
    end
    else
    begin
      { Center inside: shortest deterministic exit; ties prefer left/right/top. }
      BestDistance := MaxDouble;
      InsideFace(CX - Rect.Left + Radius, -1, 0);
      InsideFace(Rect.Right - CX + Radius, 1, 0);
      InsideFace(CY - Rect.Top + Radius, 0, -1);
      InsideFace(Rect.Bottom - CY + Radius, 0, 1);
      Hit.Penetration := BestDistance;
    end;
    Exit;
  end;
  if VX > TimeEpsilon then
  begin
    T := (Rect.Left - Radius - CX) / VX;
    AtContact := CY + VY * T;
    if (AtContact >= Rect.Top) and (AtContact <= Rect.Bottom) then Candidate(T, -1, 0);
  end
  else if VX < -TimeEpsilon then
  begin
    T := (Rect.Right + Radius - CX) / VX;
    AtContact := CY + VY * T;
    if (AtContact >= Rect.Top) and (AtContact <= Rect.Bottom) then Candidate(T, 1, 0);
  end;
  if VY > TimeEpsilon then
  begin
    T := (Rect.Top - Radius - CY) / VY;
    AtContact := CX + VX * T;
    if (AtContact >= Rect.Left) and (AtContact <= Rect.Right) then Candidate(T, 0, -1);
  end
  else if VY < -TimeEpsilon then
  begin
    T := (Rect.Bottom + Radius - CY) / VY;
    AtContact := CX + VX * T;
    if (AtContact >= Rect.Left) and (AtContact <= Rect.Right) then Candidate(T, 0, 1);
  end;
  Corner(Rect.Left, Rect.Top, -1, -1);
  Corner(Rect.Right, Rect.Top, 1, -1);
  Corner(Rect.Left, Rect.Bottom, -1, 1);
  Corner(Rect.Right, Rect.Bottom, 1, 1);
end;

end.
