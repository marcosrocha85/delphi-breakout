unit Breakout.Bricks;

interface

uses Breakout.Types;

type
  TBrickDefinition = record
    Kind: TBrickKind;
    SpriteIndex, Points: Integer;
  end;

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
