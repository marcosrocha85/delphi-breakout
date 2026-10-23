{** Three fixed formations with seeded height-weighted classes and premium spacing. }
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
    Keeps legacy-grid/twin-gates/diamond geometry; all three boards use seeded
    class weights by relative formation height. Silver/gold cannot occupy
    horizontal/vertical neighboring cells, including mixed pairs; diagonals
    are allowed. Conflicting premium draws become a weighted nonpremium class.
    Restart with the same Seed/Level reproduces the entire board. The historical
    GenerateLegacyLevel remains available as a reference, without rebalancing.
    Raises EArgumentOutOfRangeException outside 1..CampaignLevelCount. }
function GenerateLevel(Seed: Cardinal; Level: Integer): TArray<TBrick>;

implementation

uses System.SysUtils, System.Math, Breakout.Bricks;

const
  ColumnPitch = 56;
  RowPitch = 24;

type
  THeightBand = (hbTop, hbMiddle, hbBottom);

const
  { Initial draw percentages: green, yellow, cyan, red, silver, gold.
    Spacing can replace premium draws, so final proportions are not quotas. }
  ClassWeights: array[THeightBand, TBrickKind] of Integer = (
    (10, 15, 20, 30, 18, 7),
    (15, 30, 30, 20, 4, 1),
    (60, 30, 6, 2, 1, 1));

function DrawKind(var Random: TSeededRandom; Band: THeightBand;
  AllowPremium: Boolean): TBrickKind;
var
  Kind: TBrickKind;
  Total, Ticket: Integer;
begin
  Total := 0;
  for Kind := Low(TBrickKind) to High(TBrickKind) do
    if AllowPremium or not (Kind in [bkSilver, bkGold]) then
      Inc(Total, ClassWeights[Band, Kind]);
  Ticket := Random.Next(Total);
  for Kind := Low(TBrickKind) to High(TBrickKind) do
    if AllowPremium or not (Kind in [bkSilver, bkGold]) then
    begin
      Dec(Ticket, ClassWeights[Band, Kind]);
      if Ticket < 0 then Exit(Kind);
    end;
  Result := bkGreen; // Positive fixed weights make this fallback unreachable.
end;

procedure BalanceClasses(var Bricks: TArray<TBrick>; Seed: Cardinal; Level: Integer);
var
  Random: TSeededRandom;
  I, J: Integer;
  Top, Bottom, BandPosition: Double;
  Band: THeightBand;
  Kind: TBrickKind;
  Definition: TBrickDefinition;
  PremiumNeighbor: Boolean;
begin
  if Length(Bricks) = 0 then Exit;
  Top := Bricks[0].Y;
  Bottom := Top;
  for I := 1 to High(Bricks) do
  begin
    Top := Min(Top, Bricks[I].Y);
    Bottom := Max(Bottom, Bricks[I].Y);
  end;
  Random.Reset(Seed xor Cardinal(Level));
  for I := 0 to High(Bricks) do
  begin
    { Band the center of each occupied row over the formation's full row span.
      Empty outer rows and the field/window height cannot shift the bands. }
    BandPosition := (Bricks[I].Y - Top + RowPitch / 2) / (Bottom - Top + RowPitch);
    Band := THeightBand(Trunc(3 * BandPosition));
    Kind := DrawKind(Random, Band, True);
    if Kind in [bkSilver, bkGold] then
    begin
      PremiumNeighbor := False;
      { Only earlier assignments count. Cell pitch includes the sprite gaps;
        diagonal cells and missing cells in a formation remain independent. }
      for J := 0 to I - 1 do
        if (Bricks[J].Kind in [bkSilver, bkGold]) and
          (((Bricks[I].Y = Bricks[J].Y) and
            (Abs(Bricks[I].X - Bricks[J].X) = ColumnPitch)) or
           ((Bricks[I].X = Bricks[J].X) and
            (Abs(Bricks[I].Y - Bricks[J].Y) = RowPitch))) then
        begin
          PremiumNeighbor := True;
          Break;
        end;
      if PremiumNeighbor then Kind := DrawKind(Random, Band, False);
    end;
    Definition := BrickDefinition(Kind);
    Bricks[I].Kind := Definition.Kind;
    Bricks[I].SpriteIndex := Definition.SpriteIndex;
    Bricks[I].Points := Definition.Points;
  end;
end;

function GenerateLevel(Seed: Cardinal; Level: Integer): TArray<TBrick>;
const
  { Occupancy only: # is a brick, . is empty. Classes are assigned separately. }
  TwinGates: array[0..4] of string = (
    '.##......##.',
    '.##......##.',
    '.##..##..##.',
    '.##..##..##.',
    '............');
  Diamond: array[0..4] of string = (
    '.....##.....',
    '....####....',
    '..########..',
    '....####....',
    '.....##.....');
  OriginX = 10;
  OriginY = 40;
  BrickWidth = 50;
  BrickHeight = 20;
var
  Row, Col, Count: Integer;
  Cells: string;
begin
  if (Level < 1) or (Level > CampaignLevelCount) then
    raise EArgumentOutOfRangeException.Create('Level is outside the campaign');
  if Level = 1 then
  begin
    Result := GenerateLegacyLevel(Seed, 1);
    BalanceClasses(Result, Seed, Level);
    Exit;
  end;
  SetLength(Result, Length(TwinGates) * Length(TwinGates[0]));
  Count := 0;
  for Row := 0 to High(TwinGates) do
  begin
    if Level = 2 then Cells := TwinGates[Row] else Cells := Diamond[Row];
    for Col := 1 to Length(Cells) do
      if Cells[Col] <> '.' then
      begin
        Result[Count].Id := Count;
        Result[Count].X := OriginX + (Col - 1) * ColumnPitch;
        Result[Count].Y := OriginY + Row * RowPitch;
        Result[Count].Width := BrickWidth;
        Result[Count].Height := BrickHeight;
        Result[Count].Active := True;
        Inc(Count);
      end;
  end;
  SetLength(Result, Count);
  BalanceClasses(Result, Seed, Level);
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
