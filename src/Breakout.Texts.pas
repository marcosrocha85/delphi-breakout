{** Player-facing resource strings, separated for future localization. }
unit Breakout.Texts;

interface

{ Player-facing text stays in resources, ready for Delphi resource translation.
  The engine owns no labels, language selection or presentation strings. }
resourcestring
  SReady = 'Ready - click or press Space to launch';
  SGameOver = 'Game over - press F2 to restart';
  SPaused = 'Paused - press F3 to resume';
  SLevelComplete = 'Level complete - click or press Space for the next level';
  SVictory = 'Victory! All levels cleared - press F2 to restart';
  SLevel = 'Level %d / %d';
  SScore = 'Score:';
  SLives = 'Lives:';

implementation

end.
