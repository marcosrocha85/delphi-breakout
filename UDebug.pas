unit UDebug;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, ValEdit;

type
  TFrmDebug = class(TForm)
    VLE: TValueListEditor;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmDebug: TFrmDebug;

implementation

{$R *.dfm}

procedure TFrmDebug.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
    Perform(WM_NEXTDLGCTL,0,0);
end;

procedure TFrmDebug.FormShow(Sender: TObject);
begin
  VLE.Strings.Clear;
  VLE.InsertRow('Lives','',False);
  VLE.InsertRow('Score','',False);
  VLE.InsertRow('Player Left','',False);
  VLE.InsertRow('Player Top','',False);
  VLE.InsertRow('Ball Left','',False);
  VLE.InsertRow('Ball Top','',False);
  VLE.InsertRow('Bar Left','',False);
  VLE.InsertRow('Bar Top','',False);
  VLE.InsertRow('Bar Name','',False);
end;

end.
