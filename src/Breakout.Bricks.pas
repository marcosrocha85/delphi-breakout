{** Explicit block classification: identity, original sprite index and points. }
unit Breakout.Bricks;

interface

uses Breakout.Types;

type
  {** Immutable definition copied into each generated brick instance. }
  TBrickDefinition = record
    Kind: TBrickKind;
    SpriteIndex, Points: Integer;
  end;

{** Returns the central scoring/sprite definition for a valid enum value.
    Green=100, yellow=150, cyan=200, red=250, silver=400, gold=500. }
function BrickDefinition(Kind: TBrickKind): TBrickDefinition;

implementation

const
  Definitions: array[TBrickKind] of TBrickDefinition = (
    (Kind: bkGreen; SpriteIndex: 0; Points: 100),
    (Kind: bkYellow; SpriteIndex: 1; Points: 150),
    (Kind: bkCyan; SpriteIndex: 2; Points: 200),
    (Kind: bkRed; SpriteIndex: 3; Points: 250),
    (Kind: bkSilver; SpriteIndex: 4; Points: 400),
    (Kind: bkGold; SpriteIndex: 5; Points: 500));

function BrickDefinition(Kind: TBrickKind): TBrickDefinition;
begin
  Result := Definitions[Kind];
end;

end.
