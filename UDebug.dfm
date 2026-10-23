object FrmDebug: TFrmDebug
  Left = 192
  Top = 114
  BorderStyle = bsDialog
  Caption = 'Debug Form'
  ClientHeight = 686
  ClientWidth = 300
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 13
  object VLE: TValueListEditor
    Left = 0
    Top = 0
    Width = 300
    Height = 686
    TabStop = False
    Align = alClient
    Color = clWindow
    Ctl3D = False
    FixedColor = clWhite
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect, goThumbTracking]
    ParentCtl3D = False
    ScrollBars = ssVertical
    TabOrder = 0
    TitleCaptions.Strings = (
      'Componente'
      'Valor')
    ExplicitWidth = 248
    ExplicitHeight = 445
    ColWidths = (
      160
      136)
  end
end
