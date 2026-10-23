program Breakout;

uses
  Forms,
  UMain in 'UMain.pas' {FrmMain},
  UDebug in 'UDebug.pas' {FrmDebug},
  Breakout.Bricks in 'src\Breakout.Bricks.pas',
  Breakout.Presentation in 'src\Breakout.Presentation.pas',
  Breakout.Renderer.Vcl in 'src\Breakout.Renderer.Vcl.pas',
  Breakout.Types in 'src\Breakout.Types.pas',
  Breakout.Texts in 'src\Breakout.Texts.pas',
  Breakout.Levels in 'src\Breakout.Levels.pas',
  Breakout.Physics in 'src\Breakout.Physics.pas',
  Breakout.Loop in 'src\Breakout.Loop.pas',
  Breakout.Game in 'src\Breakout.Game.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Delphi Breakout';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
