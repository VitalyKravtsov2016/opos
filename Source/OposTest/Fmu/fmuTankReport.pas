unit fmuTankReport;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  // Tnt
  TntStdCtrls, TntSysUtils,
  // 3's
  PngImage,
  // This
  untPages, Opos, OposUtils, OposFiscalPrinter, OposFptr, OposFptrUtils,
  TankReader, UniposTank;

type
  TfmTankReport = class(TPage)
    memTankReport: TTntMemo;
    lblTankReport: TTntLabel;
    btnSetDefaults: TTntButton;
    btnPrint: TTntButton;
    procedure btnSetDefaultsClick(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure SaveTanks;
  end;

var
  fmTankReport: TfmTankReport;

implementation

{$R *.dfm}

const
  CRLF = #13#10;

  DefTankReport: WideString =
    '******************************************' + CRLF +
    ' ����� � ��������� �����������            ' + CRLF +
    ' ���� ������:            2010-04-10 18:00 ' + CRLF +
    ' ���� ���������:         2010-04-10 15:00 ' + CRLF +
    '                                          ' + CRLF +
    ' ��������� 1 : [A�-95]                    ' + CRLF +
    ' �����:  100000 �       �������: 1.500 �� ' + CRLF +
    ' ����:   0 �                �������: 0 �� ' + CRLF +
    ' �����������:  500000 �                   ' + CRLF +
    ' �����������:  18 �                       ' + CRLF +
    ' ���������:  0.69                         ' + CRLF +
    ' ��������� ����� : 400000�                ' + CRLF +
    '                                          ' + CRLF +
    ' ��������� 2:  [A�-92]                    ' + CRLF +
    ' �����:  100000 �       �������: 1.500 �� ' + CRLF +
    ' ����:   0 �                �������: 0 �� ' + CRLF +
    ' �����������:                    500000 � ' + CRLF +
    '******************************************';


{ TfmTankReport }

procedure TfmTankReport.btnSetDefaultsClick(Sender: TObject);
begin
  memTankReport.Text := DefTankReport;
end;

procedure TfmTankReport.btnPrintClick(Sender: TObject);
begin
  EnableButtons(False);
  try
    SaveTanks;
    Check(FiscalPrinter.BeginNonFiscal);
    FiscalPrinter.PrintNormal(FPTR_S_RECEIPT, memTankReport.Text);
    Check(FiscalPrinter.EndNonFiscal);
  finally
    EnableButtons(True);
  end;
end;

procedure TfmTankReport.SaveTanks;
var
  i: Integer;
  Tank: TUniposTank;
  Reader: TTankReader;
const
  MaxTanks = 2;
  GradeNames: array [0..2] of string =
    ('A�-76', 'A�-92', 'A�-95');
begin
  Reader := TTankReader.Create;
  try
    Reader.Clear;
    Reader.DataReady := True;
    Reader.TransactionDate := DateToStr(Now);

    for i := 1 to MaxTanks do
    begin
      Tank := Reader.Tanks.Add('Tank' + IntToStr(i));
      Tank.Values.Values[REGSTR_VAL_TIME_MANUAL] := TimeToStr(Time);
      Tank.Values.Values[REGSTR_VAL_TANK_NAME] := WideFormat('��������� �%d', [i]);
      Tank.Values.Values[REGSTR_VAL_GRADENAME] := GradeNames[i];
      Tank.Values.Values[REGSTR_VAL_CLOSE_QTY] := '1500000';
      Tank.Values.Values[REGSTR_VAL_DENSITY] := '0.69';
      Tank.Values.Values[REGSTR_VAL_TANK_TEMP] := '18';
      Tank.Values.Values[REGSTR_VAL_NET_STICK] := '123';
      Tank.Values.Values[REGSTR_VAL_MANUAL_NET] := '234';
      Tank.Values.Values[REGSTR_VAL_WATER_VOLUME] := '345';
      Tank.Values.Values[REGSTR_VAL_WATER_STICK] := '45';
      Tank.Values.Values[REGSTR_VAL_MANUAL_WATER] := '879';
      Tank.Values.Values[REGSTR_VAL_VOLUME_QTY] := '6378';
      Tank.Values.Values[REGSTR_VAL_EMPTY_VOLUME] := '877';
    end;
    Reader.Save;
  finally
    Reader.Free;
  end;
end;

procedure TfmTankReport.FormCreate(Sender: TObject);
begin
  memTankReport.Text := DefTankReport;
end;

end.
