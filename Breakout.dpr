program Breakout;

uses
  Forms,
  UMain in 'UMain.pas' {FrmMain},
  UDebug in 'UDebug.pas' {FrmDebug},
  Breakout.Types in 'src\Breakout.Types.pas',
  Breakout.Texts in 'src\Breakout.Texts.pas',
  Breakout.Levels in 'src\Breakout.Levels.pas',
  Breakout.Game in 'src\Breakout.Game.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Delphi Breakout';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
