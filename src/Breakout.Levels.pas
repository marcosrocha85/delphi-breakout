{** Finite three-level campaign: the seeded legacy grid and two fixed maps. }
unit Breakout.Levels;

interface

uses Breakout.Types;

const
  {** Number of available boards; LevelCount may select a prefix of them. }
  CampaignLevelCount = 3;

{** Creates 96 active bricks, with stable IDs and definitions from Breakout.Bricks.
    The local random stream starts at Seed xor Level. This is one legacy grid
    recipe, not a template library or endless-level system.
    @returns(A newly allocated array owned through normal dynamic-array lifetime.) }
function GenerateLegacyLevel(Seed: Cardinal; Level: Integer): TArray<TBrick>;

{** Creates an independent board with row-major IDs and centralized rewards.
    Level 1 delegates unchanged to GenerateLegacyLevel; levels 2/3 use fixed
    class maps (independent of Seed). Raises EArgumentOutOfRangeException
    outside 1..CampaignLevelCount. }
function GenerateLevel(Seed: Cardinal; Level: Integer): TArray<TBrick>;

implementation

uses System.SysUtils, Breakout.Bricks;

function GenerateLevel(Seed: Cardinal; Level: Integer): TArray<TBrick>;
const
  { Digits are TBrickKind ordinals; dots are empty cells. Each map is 12 x 5. }
  TwinGates: array[0..4] of string = (
    '.44......44.',
    '.23......32.',
    '.12..55..21.',
    '.00..00..00.',
    '............');
  Diamond: array[0..4] of string = (
    '.....55.....',
    '....4334....',
    '..32100123..',
    '....2112....',
    '.....00.....');
  OriginX = 10;
  OriginY = 40;
  ColumnPitch = 56;
  RowPitch = 24;
  BrickWidth = 50;
  BrickHeight = 20;
var
  Row, Col, Count: Integer;
  Cells: string;
  Definition: TBrickDefinition;
begin
  if (Level < 1) or (Level > CampaignLevelCount) then
    raise EArgumentOutOfRangeException.Create('Level is outside the campaign');
  if Level = 1 then Exit(GenerateLegacyLevel(Seed, 1));
  SetLength(Result, Length(TwinGates) * Length(TwinGates[0]));
  Count := 0;
  for Row := 0 to High(TwinGates) do
  begin
    if Level = 2 then Cells := TwinGates[Row] else Cells := Diamond[Row];
    for Col := 1 to Length(Cells) do
      if Cells[Col] <> '.' then
      begin
        Definition := BrickDefinition(TBrickKind(Ord(Cells[Col]) - Ord('0')));
        Result[Count].Id := Count;
        Result[Count].X := OriginX + (Col - 1) * ColumnPitch;
        Result[Count].Y := OriginY + Row * RowPitch;
        Result[Count].Width := BrickWidth;
        Result[Count].Height := BrickHeight;
        Result[Count].Kind := Definition.Kind;
        Result[Count].SpriteIndex := Definition.SpriteIndex;
        Result[Count].Points := Definition.Points;
        Result[Count].Active := True;
        Inc(Count);
      end;
  end;
  SetLength(Result, Count);
end;

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
