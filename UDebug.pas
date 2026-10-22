unit UDebug;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, Forms, Grids, ValEdit;

const
  DebugLives = 'Lives';
  DebugScore = 'Score';
  DebugPlayerLeft = 'Player Left';
  DebugPlayerTop = 'Player Top';
  DebugBallLeft = 'Ball Left';
  DebugBallTop = 'Ball Top';
  DebugBarLeft = 'Bar Left';
  DebugBarTop = 'Bar Top';
  DebugBarName = 'Bar Name';

type
  TFrmDebug = class(TForm)
    VLE: TValueListEditor;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  end;

var
  FrmDebug: TFrmDebug;

implementation

{$R *.dfm}

procedure TFrmDebug.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Perform(WM_NEXTDLGCTL, 0, 0);
    Key := 0;
  end;
end;

procedure TFrmDebug.FormShow(Sender: TObject);
begin
  VLE.Strings.BeginUpdate;
  try
    VLE.Strings.Clear;
    VLE.InsertRow(DebugLives, '', True);
    VLE.InsertRow(DebugScore, '', True);
    VLE.InsertRow(DebugPlayerLeft, '', True);
    VLE.InsertRow(DebugPlayerTop, '', True);
    VLE.InsertRow(DebugBallLeft, '', True);
    VLE.InsertRow(DebugBallTop, '', True);
    VLE.InsertRow(DebugBarLeft, '', True);
    VLE.InsertRow(DebugBarTop, '', True);
    VLE.InsertRow(DebugBarName, '', True);
  finally
    VLE.Strings.EndUpdate;
  end;
end;

end.
