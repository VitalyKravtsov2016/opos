unit fmuMalina;

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
  MalinaCard;

type
  TfmMalina = class(TPage)
    Image1: TImage;
    btnMalinaSalesReceipt: TTntButton;
    Memo: TTntMemo;
    btnSalesReceipt: TTntButton;
    btnMalinaRefundReceipt: TTntButton;
    btnRefundReceipt: TTntButton;
    procedure btnMalinaSalesReceiptClick(Sender: TObject);
    procedure btnSalesReceiptClick(Sender: TObject);
    procedure btnMalinaRefundReceiptClick(Sender: TObject);
    procedure btnRefundReceiptClick(Sender: TObject);
  private
    procedure PrintSalesReceipt;
    procedure PrintRefundReceipt;
    procedure AddLine(const S: string);
    procedure Check(AResultCode: Integer);
    procedure SaveMalinaOperation;
  end;

var
  fmMalina: TfmMalina;

implementation

{$R *.dfm}

{ TfmMalina }

procedure TfmMalina.AddLine(const S: string);
begin
  Memo.Lines.Add(S);
end;

procedure TfmMalina.Check(AResultCode: Integer);
begin
  if AResultCode <> OPOS_SUCCESS then
  begin
    AddLine(Format('%d, %s', [AResultCode, GetResultCodeText(AResultCode)]));
    AddLine(Format('ResultCodeExtended: %d', [Integer(FiscalPrinter.ResultCodeExtended)]));
    AddLine(Format('ErrorString: %s', [String(FiscalPrinter.ErrorString)]));
    AddLine(Format('PrinterState: %s', [PrinterStateToStr(FiscalPrinter.PrinterState)]));
    Abort;
  end;
end;

(*
     �� ����������� (��� 009)
  ��� "���-�� �������� �������"
  �������� ��., 2, ���. 332-72-56

��� 00019976 ��� 007802411512  #8552
22.08.10 23:14
�������                        �1283
��� 4: ������ 95          ���  41457
                      23.59 X 51.710
1                           =1219.84
����� �����:        6393000039070330
------------------------------------
�������:                     1219.84
- 1.5%
������                        =18.30
����������� ������
1                             =18.30

��������: ������� �.�. ID: 254889
����                        =1219.84
���������                   =1500.00
�����                        =280.16
------------ �� --------------------
                     ���� 0670467138
                    00102672 #056284
       ������� �������
     �������� ����� ����

*)

procedure TfmMalina.PrintSalesReceipt;
begin
  Memo.Clear;
  FiscalPrinter.FiscalReceiptStation := FPTR_RS_RECEIPT;
  FiscalPrinter.FiscalReceiptType := FPTR_RT_SALES;
  Check(FiscalPrinter.BeginFiscalReceipt(False));
  AddLine('PrintRecItem');
  Check(FiscalPrinter.PrintRecItem('��� 4: ������ 95          ���  41457',
    0, 51710, 0, 23.59, ''));
  AddLine('PrintRecTotal');
  Check(FiscalPrinter.PrintRecTotal(1220, 1220, '0'));
  //FiscalPrinter.PrintNormal(2, '��������: ������� �.�. ID: 254889');
  AddLine('EndFiscalReceipt');
  Check(FiscalPrinter.EndFiscalReceipt(False));
end;

procedure TfmMalina.PrintRefundReceipt;
begin
  Memo.Clear;
  FiscalPrinter.FiscalReceiptStation := FPTR_RS_RECEIPT;
  FiscalPrinter.FiscalReceiptType := FPTR_RT_SALES;
  Check(FiscalPrinter.BeginFiscalReceipt(False));
  AddLine('PrintRecRefund');
  Check(FiscalPrinter.PrintRecRefund('��� 4: ������ 95          ���  41457',
    1219.84, 0));
  AddLine('PrintRecTotal');
  Check(FiscalPrinter.PrintRecTotal(1220, 1220, '0'));
  //FiscalPrinter.PrintNormal(2, '��������: ������� �.�. ID: 254889');
  AddLine('EndFiscalReceipt');
  Check(FiscalPrinter.EndFiscalReceipt(False));
end;

const
  REGSTR_UNIPOS_MALINA = 'SOFTWARE\Unipos\Malina';

procedure TfmMalina.SaveMalinaOperation;
var
  Operation: TMalinaCard;
begin
  Operation := TMalinaCard.Create(FiscalPrinter.Logger);
  try
    Operation.CardNumber := '83465837456';
    Operation.DateTime := '73465467';
    Operation.Amount := 121984;
    Operation.OperationType := 0;
    Operation.Save(REGSTR_UNIPOS_MALINA);
  finally
    Operation.Free;
  end;
end;

procedure TfmMalina.btnMalinaSalesReceiptClick(Sender: TObject);
begin
  btnMalinaSalesReceipt.Enabled := False;
  try
    SaveMalinaOperation;
    PrintSalesReceipt;
  finally
    btnMalinaSalesReceipt.Enabled := True;
    btnMalinaSalesReceipt.SetFocus;
  end;
end;

procedure TfmMalina.btnMalinaRefundReceiptClick(Sender: TObject);
begin
  btnMalinaRefundReceipt.Enabled := False;
  try
    SaveMalinaOperation;
    PrintRefundReceipt;
  finally
    btnMalinaRefundReceipt.Enabled := True;
    btnMalinaRefundReceipt.SetFocus;
  end;
end;

procedure TfmMalina.btnSalesReceiptClick(Sender: TObject);
begin
  btnSalesReceipt.Enabled := False;
  try
    PrintSalesReceipt;
  finally
    btnSalesReceipt.Enabled := True;
    btnSalesReceipt.SetFocus;
  end;
end;

procedure TfmMalina.btnRefundReceiptClick(Sender: TObject);
begin
  btnRefundReceipt.Enabled := False;
  try
    PrintRefundReceipt;
  finally
    btnRefundReceipt.Enabled := True;
    btnRefundReceipt.SetFocus;
  end;
end;

end.
