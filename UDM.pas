unit UDM;

interface

uses
  SysUtils, Classes, Forms, StdCtrls, ComCtrls, Dialogs, Graphics;

type
  TLanguage = class(TComponent)
  private
    IsLabelsCreated: Boolean;
  public
    Messages: TLabel;
    Score: TLabel;
    Lives: TLabel;
    LangGameOver: String;
    LangPaused: String;
    LangScore: String;
    LangLives: String;
    constructor Create(AOwner: TComponent); override;    
    procedure Load(const ShowProgress: Boolean = True);
  end;
  TDM = class(TDataModule)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DM: TDM;
  Language: TLanguage;

implementation

uses UMain;

{$R *.dfm}

{ TLanguage }

constructor TLanguage.Create(AOwner: TComponent);
begin
  inherited;
  if Messages = nil then
  begin
    Messages := TLabel.Create(FrmMain);
    Messages.Parent    := FrmMain;
    Messages.AutoSize  := False;
    Messages.Alignment := taCenter;
    Messages.Top   := 220;
    Messages.Left  := 0;
    Messages.Width := FrmMain.ClientWidth;
    Messages.Font.Color := clWhite;
    Messages.Font.Style := [fsBold];
  end;
  if Score = nil then
  begin
    Score := TLabel.Create(FrmMain);
    Score.Parent   := FrmMain;
    Score.AutoSize := False;
    Score.Top    := 437;
    Score.Left   := 576;
    Score.Width  := 105;
    Score.Font.Color := clWhite;
    Score.Font.Style := [fsBold];
  end;
  if Lives = nil then
  begin
    Lives := TLabel.Create(FrmMain);
    Lives.Parent   := FrmMain;
    Lives.AutoSize := False;
    Lives.Top    := 437;
    Lives.Left   := 5;
    Lives.Width  := 35;
    Lives.Font.Color := clWhite;
    Lives.Font.Style := [fsBold];
  end;
end;

procedure TLanguage.Load(const ShowProgress: Boolean);
var
  fProgress:    TForm;
  Label1:       TLabel;
  ProgressBar1: TProgressBar;
  SList: TStringList;
  I: Integer;
begin
  LangGameOver := 'Game Over, Press F2 to Start a New Game . . .';
  LangPaused   := 'Game Paused, Press F3 to Continue . . .';
  LangScore    := 'Score:';
  LangLives    := 'Lives:';
  Messages.Caption := LangPaused;
  Score.Caption    := LangScore;
  Lives.Caption    := LangLives;
end;

end.
