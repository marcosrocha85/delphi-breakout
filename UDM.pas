unit UDM;

interface

uses
  SysUtils, Classes, Forms, StdCtrls, Graphics;

type
  TLanguage = class(TComponent)
  public
    Messages, Score, Lives: TLabel;
    LangGameOver, LangPaused, LangScore, LangLives: string;
    constructor Create(AOwner: TComponent); override;
    procedure Load;
  end;

  TDM = class(TDataModule)
  end;

var
  DM: TDM;
  Language: TLanguage;

implementation

{$R *.dfm}

constructor TLanguage.Create(AOwner: TComponent);
var
  Host: TForm;
begin
  inherited;
  if not (AOwner is TForm) then
    raise EArgumentException.Create('Language requires a form owner');
  Host := TForm(AOwner);
  Messages := TLabel.Create(Self);
  Messages.Parent := Host;
  Messages.AutoSize := False;
  Messages.Alignment := taCenter;
  Messages.SetBounds(0, 220, Host.ClientWidth, 13);
  Messages.Font.Color := clWhite;
  Messages.Font.Style := [fsBold];
  Score := TLabel.Create(Self);
  Score.Parent := Host;
  Score.AutoSize := False;
  Score.SetBounds(576, 437, 105, 13);
  Score.Font.Color := clWhite;
  Score.Font.Style := [fsBold];
  Lives := TLabel.Create(Self);
  Lives.Parent := Host;
  Lives.AutoSize := False;
  Lives.SetBounds(5, 437, 35, 13);
  Lives.Font.Color := clWhite;
  Lives.Font.Style := [fsBold];
end;

procedure TLanguage.Load;
begin
  LangGameOver := 'Game Over, Press F2 to Start a New Game . . .';
  LangPaused := 'Game Paused, Press F3 to Continue . . .';
  LangScore := 'Score:';
  LangLives := 'Lives:';
  Messages.Caption := '';
  Score.Caption := LangScore;
  Lives.Caption := LangLives;
end;

end.
