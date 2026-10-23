unit Breakout.Levels;

interface

uses Breakout.Types;

function GenerateLegacyLevel(Seed: Cardinal; Level: Integer): TArray<TBrick>;

implementation

uses Breakout.Bricks;

function GenerateLegacyLevel(Seed: Cardinal; Level: Integer): TArray<TBrick>;
const
  Colors: array[0..34] of Integer =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,2,3,3,3,4,4,5);
var
  Random: TSeededRandom;
  Row, Col, I: Integer;
  Definition: TBrickDefinition;
begin
  Random.Reset(Seed xor Cardinal(Level));
  SetLength(Result, 96);
  for Row := 0 to 7 do
    for Col := 0 to 11 do
    begin
      I := Row * 12 + Col;
      Result[I].Id := I;
      Result[I].X := 10 + Col * 56;
      Result[I].Y := 16 + Row * 24;
      Result[I].Width := 50;
      Result[I].Height := 20;
      Definition := BrickDefinition(TBrickKind(Colors[Random.Next(Length(Colors))]));
      Result[I].Kind := Definition.Kind;
      Result[I].SpriteIndex := Definition.SpriteIndex;
      Result[I].Points := Definition.Points;
      Result[I].Active := True;
    end;
end;

end.
