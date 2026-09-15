object fmWebKassa: TfmWebKassa
  Left = 614
  Top = 369
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = 'WebKassa'
  ClientHeight = 394
  ClientWidth = 424
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblPositionType: TLabel
    Left = 32
    Top = 40
    Width = 99
    Height = 13
    Caption = 'Default position type:'
  end
  object chbWebKassaEnabled: TTntCheckBox
    Left = 8
    Top = 8
    Width = 329
    Height = 17
    Caption = 'WebKassa print module support'
    TabOrder = 0
  end
  object cbPositionType: TTntComboBox
    Left = 144
    Top = 40
    Width = 153
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 1
    Items.Strings = (
      '0. Goods'
      '1. Work'
      '2. Service')
  end
end
