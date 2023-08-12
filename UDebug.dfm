object FrmDebug: TFrmDebug
  Left = 192
  Top = 114
  BorderStyle = bsDialog
  Caption = 'Debug Form'
  ClientHeight = 446
  ClientWidth = 252
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object VLE: TValueListEditor
    Left = 0
    Top = 0
    Width = 252
    Height = 446
    TabStop = False
    Align = alClient
    Color = clBackground
    Ctl3D = False
    FixedColor = clWhite
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect, goThumbTracking]
    ParentCtl3D = False
    ScrollBars = ssVertical
    TabOrder = 0
    TitleCaptions.Strings = (
      'Componente'
      'Valor')
    ColWidths = (
      150
      98)
  end
end
