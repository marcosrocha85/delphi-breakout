program Breakout;

uses
  Forms,
  UMain in 'UMain.pas' {FrmMain},
  UDebug in 'UDebug.pas' {FrmDebug},
  UDM in 'UDM.pas' {DM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Delphi Breakout';
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
