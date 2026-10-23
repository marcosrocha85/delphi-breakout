program BreakoutTests;

{$APPTYPE CONSOLE}

uses System.SysUtils, System.IOUtils,
  Breakout.Bricks in '..\src\Breakout.Bricks.pas',
  Breakout.Presentation in '..\src\Breakout.Presentation.pas',
  Breakout.Presentation.Tests in 'Breakout.Presentation.Tests.pas',
  Breakout.Types in '..\src\Breakout.Types.pas',
  Breakout.Levels in '..\src\Breakout.Levels.pas',
  Breakout.Physics in '..\src\Breakout.Physics.pas',
  Breakout.Loop in '..\src\Breakout.Loop.pas',
  Breakout.Game in '..\src\Breakout.Game.pas',
  Breakout.TestScenarios in 'Breakout.TestScenarios.pas',
  Breakout.Game.Tests in 'Breakout.Game.Tests.pas',
  Breakout.Physics.Tests in 'Breakout.Physics.Tests.pas';

var
  Folder, Parent: string;
  EnginePassed, PhysicsPassed, PresentationPassed: Boolean;
begin
  try
    Folder := ParamStr(1);
    if Folder = '' then
    begin
      Folder := ExtractFileDir(ParamStr(0));
      while not FileExists(TPath.Combine(Folder, 'Breakout.dpr')) do
      begin
        Parent := ExtractFileDir(Folder);
        if Parent = Folder then raise Exception.Create('Repository root not found');
        Folder := Parent;
      end;
      Folder := TPath.Combine(Folder, 'build\e4\latest');
    end;
    Folder := ExpandFileName(Folder);
    EnginePassed := RunEngineTests(Folder);
    PhysicsPassed := RunPhysicsTests(Folder);
    PresentationPassed := RunPresentationTests(Folder);
    if EnginePassed and PhysicsPassed and PresentationPassed then
    begin
      Writeln('E4 checks passed: ', TPath.Combine(Folder, 'engine.json'));
      ExitCode := 0;
    end
    else
    begin
      Writeln('E4 checks failed: ', TPath.Combine(Folder, 'engine.json'));
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 2;
    end;
  end;
end.
