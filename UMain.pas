unit UMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Menus, ImgList, Math, AppEvnts, System.ImageList;

type
  TFrmMain = class(TForm)
    Timer1: TTimer;
    Ball: TImage;
    VLives: TImage;
    Image: TImageList;
    ApplicationEvents1: TApplicationEvents;
    Player: TPanel;
    ImgPlayerL: TImage;
    ImgPlayerR: TImage;
    ImgPlayerM: TImage;
    procedure PlayerClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormClick(Sender: TObject);
    procedure ApplicationEvents1Deactivate(Sender: TObject);
  private
    { Private declarations }
    { We have to known if is Playing to do Pause or not }
    bPlaying, bPaused: Boolean;
    { if Y equals to 0 (zero) then go down else go up, if X equals to 0 then go left else go right }
    bX,bY: Smallint;
    { bA angle of the ball: min 5 max 25 (10 to 10) | bV min 5 máx 15 (5 to 5) }
    bA,bV: Smallint;
    { Stores how many lifes the player have }
    Lives: Smallint;
    { Stores the Score and used to resize the lives image }
    Score: Integer;
    procedure CreateLives;
    { reposition the Player and the Ball to Center }
    procedure Reposition;
    { Pauses the Game }
    procedure Pause(const lPause: Boolean);
    { Fill score with some Zeroes }
    function  StrZero(const N: Integer): String;
    { Create the Blocks according by Levels }
    procedure CreateBars(const Level: Smallint);
    { Increment Score. if SetZero is True, set score to 0 (Zero) }
    procedure RefreshScore(const I: Integer; const SetZero: Boolean = False);
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

const
  Down  : Byte = 0;
  Up    : Byte = 1;
  Left  : Byte = 0;
  Right : Byte = 1;
  
implementation

uses UDebug, UDM;

{$R *.dfm}

procedure TFrmMain.PlayerClick(Sender: TObject);
begin
  { Is game over? }
  if Lives = 0 then
    Exit;
  if not Timer1.Enabled then
  begin
    Reposition;
    Timer1.Enabled := not Timer1.Enabled;
  end;
end;

procedure TFrmMain.Timer1Timer(Sender: TObject);
var
  I: Integer;
  Bar: TImage;
begin
  bPlaying := True;
  { control to hinder exceeds the horizontal limits }
  if Ball.Left <= 0 then
  begin
    Ball.Left := 0;
    bX := 1;
  end
  else if Ball.Left >= ClientWidth - Ball.Width then
  begin
    Ball.Left := ClientWidth - Ball.Width;
    bX := 0;
  end;
  { control to hinder exceeds the vertical limits }
  if Ball.Top <= 0 then
  begin
    Ball.Top := 0;
    bY := 0; // down
  end
  else if (Ball.Left > Player.Left-5) and (Ball.Left < (Player.Left + Player.Width + 5)) and
    (bY = 0) and (Ball.Top >= Player.Top - (Ball.Height + 5)) then // if the Ball is hitting the Player
  begin
    { Up }
    bY := 1;
    { Velocity and Angle control depending where the Ball hits the Player
      Here the Ball is divided in 3 parts but the intention is divide at last 5 parts }
    if (Ball.Left > Player.Left-5) and (Ball.Left < Player.Left+17) then // hitting to the left
    begin
      bX := 0;  // left
      bV := 15; // max speed
      bA := 15; // reasonable angle
    end
    else if (Ball.Left > (Player.Left+Player.Width)-17) and (Ball.Left < Player.Left + Player.Width + 5) then // hitting to the right
    begin
      bX := 1;  // right
      bV := 15; // max speed
      bA := 15; // reasonable angle
    end
    else if (Ball.Left > Player.Left+17) and (Ball.Left < (Player.Left+Player.Width)-17) then // hitting at middle
    begin
      bV := 5; // minimun speed
      bA := 5; // minimum angle
    end;
  end
  { if the Ball is passed the Player }
  else if (Ball.Top > Player.Top) and ((Ball.Left < Player.Left-5) or
    (Ball.Left > (Player.Left + Player.Width + 5))) then
  begin
    Reposition;
    Dec(Lives);
    CreateLives;
  end;
  if FrmDebug <> nil then
  begin
    FrmDebug.VLE.Values['Lives']       := IntToStr(Lives);
    FrmDebug.VLE.Values['Score']       := IntToStr(Score);
    FrmDebug.VLE.Values['Player Left'] := IntToStr(Player.Left);
    FrmDebug.VLE.Values['Player Top']  := IntToStr(Player.Top);
    FrmDebug.VLE.Values['Ball Left']   := IntToStr(Ball.Left);
    FrmDebug.VLE.Values['Ball Top']    := IntToStr(Ball.Top);
  end;
  { Checking if the Ball beat in some Bar }
  for I := 0 to Self.ComponentCount - 1 do
  begin
    { if is a Bar }
    if (Self.Components[I] is TImage) and ((Self.Components[I] as TImage).Tag > 0) then
    begin
      { if the Ball is hitting the Bar }
      if (Ball.Top  <= (Self.Components[I] as TImage).Top + (Self.Components[I] as TImage).Height) and
         (Ball.Top + Ball.Height >= (Self.Components[I] as TImage).Top) and
         (Ball.Left <= (Self.Components[I] as TImage).Left + (Self.Components[I] as TImage).Width) and
         (Ball.Left + Ball.Width >= (Self.Components[I] as TImage).Left) then
      begin
        Bar := (Self.Components[I] as TImage);
        if FrmDebug <> nil then
        begin
          FrmDebug.VLE.Values['Name of Bar'] := Bar.Name;
          FrmDebug.VLE.Values['Left of Bar'] := IntToStr(Bar.Left);
          FrmDebug.VLE.Values['Top  of Bar'] := IntToStr(Bar.Top);
        end;
        { if the Ball is hitting Underside }
        if (Ball.Top  <= Bar.Top  + Bar.Height) and
           (Ball.Left <= (Bar.Left + Bar.Width) - 5) and
           (Ball.Left + Ball.Width >= Bar.Left + 5) then
          bY := Down
        { if the Ball is hitting Upside }
        else if (Ball.Top + Ball.Height >= Bar.Top) and
           (Ball.Left <= (Bar.Left + Bar.Width) - 5) and
           (Ball.Left + Ball.Width >= Bar.Left + 5) then
          bY := Up;
        { if the Ball is hitting Left Side }
        if (Ball.Top + Ball.Height <= Bar.Top + Bar.Height) and
           (Ball.Top               >= Bar.Top) and
           (Ball.Left <= Bar.Left + Bar.Width) then
          bX := Left
        { if the Ball is hitting Right Side }
        else if (Ball.Top  + Ball.Height <= Bar.Top + Bar.Height) and
           (Ball.Top               >= Bar.Top) and
           (Ball.Left + Ball.Width >= Bar.Left) then
          bX := Right;
{        if (Trunc((Bola.Top+Bola.Height)/2) <= (Trunc(Bar.Top + Bar.Height)/2)) and
           (Bola.Left <= Bar.Left + Bar.Width) then
          bX := Left
        else // se estiver batendo à direita
        if (Trunc((Bola.Top+Bola.Height)/2) <= (Trunc(Bar.Top + Bar.Height)/2)) and
           (Bola.Left + Bola.Width >= Bar.Left) then
          bX := Right;}
        Bar.Visible := False;
        RefreshScore(Bar.Tag);
      end;
    end;
  end;
  { Known who I can "Kill" }
  I := Self.ComponentCount - 1;
  while I > 0 do
  begin
    { Is it a Bar? Is it Invisible? }
    if (Self.Components[I] is TImage) and ((Self.Components[I] as TImage).Tag > 0) and
      (not (Self.Components[I] as TImage).Visible) then
        (Self.Components[I] as TImage).Free;
    Dec(I);
  end;
  if bX = 0 then { if 0 left else 1 right }
    Ball.Left := Ball.Left - bA
  else
    Ball.Left := Ball.Left + bA;
  if bY = 0 then { if 0 down else 1 up }
    Ball.Top := Ball.Top + bV
  else
    Ball.Top := Ball.Top - bV;  
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  Language := TLanguage.Create(nil);
  Language.Load(False);
  Cursor := crNone;
  ImgPlayerL.Cursor := crNone;
  ImgPlayerM.Cursor := crNone;
  ImgPlayerR.Cursor := crNone;
  Lives := 3;
  RefreshScore(0,True);
  CreateBars(1);
  CreateLives;
  Reposition;
end;

procedure TFrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  I: Integer;
begin
  if Key = VK_F1 then
    Timer1Timer(nil)
  else if Key = VK_F2 then
  begin
    Reposition;
    Lives := 3;
    CreateLives;    
    RefreshScore(0,True);
    I := Self.ComponentCount - 1;
    { Kill all Bars to restart Level }
    while I > 0 do
    begin
      if (Self.Components[I] is TImage) and ((Self.Components[I] as TImage).Tag > 0) then
        (Self.Components[I] as TImage).Free;
      Dec(I);
    end;
    { Create the Bars of Level again }
    CreateBars(1);
  end
  else
  if (Key = VK_F3) and (Lives > 0) and (bPlaying) then
    Pause(Timer1.Enabled)
  else if Key = VK_F10 then
  begin
    if FrmDebug = nil then
    begin
      Application.CreateForm(TFrmDebug, FrmDebug);
      FrmDebug.Left := 0;
      Left := FrmDebug.Width + 5;
      FrmDebug.Top  := Top;
      FrmDebug.Show;
      SetFocus;
    end
    else
    begin
      Left := 192;
      FreeAndNil(FrmDebug);
    end;
  end
  else
  if (Key = VK_SPACE) and (not Timer1.Enabled) then
    PlayerClick(nil);
end;

procedure TFrmMain.CreateLives;
var
  nI: Integer;
begin
  VLives.Width := 0;
  for nI := 1 to Lives do
    VLives.Width := VLives.Width + 15;
  Language.Messages.Caption := Language.LangGameOver;//Game Over, Press F2 to Start a New Game...;
  Language.Messages.Visible := Lives = 0;
end;

procedure TFrmMain.Reposition;
begin
  if Random(2) = 1 then
    bX := Left // right or left?
  else
    bX := Right;
  bA := 5; // Initial angle
  bV := 5; // Minumum speed
  bY := Up;
  Ball.Top   := 395;
  Ball.Left  := 335;
  Player.Left := 319;
  Timer1.Enabled := False; // stop the game
  bPlaying := False;
  bPaused := False;
end;

procedure TFrmMain.Pause(const lPause: Boolean);
begin
  Timer1.Enabled := not lPause;
  Language.Messages.Caption := Language.LangPaused;
  Language.Messages.Visible := lPause;
  bPaused := lPause;
end;

procedure TFrmMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if ((Mouse.CursorPos.X - Left) - 25 > 0) and ((Mouse.CursorPos.X - Left) + 31 < Width) and
     (not bPaused) then
  begin
    Player.Left := Mouse.CursorPos.X - Left - 25;
    if not bPlaying then
      Ball.Left := Mouse.CursorPos.X - Left - 8;
  end;
end;

function TFrmMain.StrZero(const N: Integer): String;
var
  I: Integer;
  S: String;
begin
  S := IntToStr(N);
  if Length(S) > 9 then
    Result := S;
  for I := 1 to 9-Length(S) do
    Result := Result + '0';
  Result := Result + S;
end;

procedure TFrmMain.CreateBars(const Level: Smallint);
const
  // Probabilities of Bars to each Level
  lv1: array[0..34] of integer = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,2,3,3,3,4,4,5);
var
  X, Y: Integer;
  Bar: TImage;
begin
  case Level of
    1:
    begin
      Y := 16;
      X := 10;
      while Y < 208 do
      begin
        while X < 633 do
        begin
          Bar := TImage.Create(FrmMain);
          Bar.Height := 20;
          Bar.Width  := 50;
          Bar.Name := 'Bar'+IntToStr(X)+'x'+IntToStr(Y);
          Randomize;
          Bar.Tag := RandomFrom(lv1); // Choose the color
          Image.GetBitmap(Bar.Tag, Bar.Picture.Bitmap);
          Bar.Tag := ((Bar.Tag+1)*10); // Defines the points that the Bar gives
          Bar.Parent := FrmMain;
          Bar.Top  := Y;
          Bar.Left := X;
          Bar.OnClick     := FormClick;
          Bar.OnMouseMove := FormMouseMove;
          X := X + 56;
        end;
        X := 10;
        Y := Y + 24;
      end;
    end;
    2:
    begin

    end;
    3:
    begin

    end;
    4:
    begin

    end;
    5:
    begin

    end;
  end;
end;

procedure TFrmMain.FormClick(Sender: TObject);
begin
  if (not Timer1.Enabled) and (not bPaused) then
    PlayerClick(nil);
end;

procedure TFrmMain.ApplicationEvents1Deactivate(Sender: TObject);
begin
  if (Timer1.Enabled) and (not bPaused) then
    Pause(True);
end;

procedure TFrmMain.RefreshScore(const I: Integer; const SetZero: Boolean = False);
begin
  if SetZero then
    Score := 0;
  Score := Score + I;
  Language.Score.Caption := Language.LangScore + ' ' + StrZero(Score);
  Application.ProcessMessages;
end;

end.
