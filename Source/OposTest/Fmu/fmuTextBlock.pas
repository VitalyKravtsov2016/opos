unit fmuTextBlock;

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
  UniposReader;

type
  TfmTextBlock = class(TPage)
    btnSaveBlock: TTntButton;
    memHeader: TTntMemo;
    btnSalesReceipt: TTntButton;
    btnLoadBlock: TTntButton;
    btnRefundReceipt: TTntButton;
    lblHeader: TTntLabel;
    memTrailer: TTntMemo;
    lblTrailer: TTntLabel;
    chbInvalidTime: TTntCheckBox;
    Memo: TTntMemo;
    lblResult: TTntLabel;
    btnDefaultBlocks: TTntButton;
    procedure btnSaveBlockClick(Sender: TObject);
    procedure btnSalesReceiptClick(Sender: TObject);
    procedure btnRefundReceiptClick(Sender: TObject);
    procedure btnLoadBlockClick(Sender: TObject);
    procedure btnDefaultBlocksClick(Sender: TObject);
  private
    FStartTime: TDateTime;
    FReader: TUniposReader;

    procedure LoadTextBlocks;
    procedure SaveTextBlocks;
    procedure PrintSalesReceipt;
    procedure PrintRefundReceipt;
    procedure AddLine(const S: WideString);
    procedure Check(AResultCode: Integer);
    procedure CheckTextBlocks;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  fmTextBlock: TfmTextBlock;

implementation

{$R *.dfm}

function GetDaySeconds: Integer;
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(Now, Hour, Min, Sec, MSec);
  Result := Hour*3600 + Min*60 + Sec;
end;

{ TfmTextBlock }


constructor TfmTextBlock.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FReader := TUniposReader.Create(FiscalPrinter.Logger);
end;

destructor TfmTextBlock.Destroy;
begin
  FReader.Free;
  inherited Destroy;
end;

procedure TfmTextBlock.AddLine(const S: WideString);
begin
  Memo.Lines.Add(S);
end;

procedure TfmTextBlock.Check(AResultCode: Integer);
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

procedure TfmTextBlock.PrintSalesReceipt;
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

procedure TfmTextBlock.PrintRefundReceipt;
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

procedure TfmTextBlock.btnSaveBlockClick(Sender: TObject);
begin
  SaveTextBlocks;
end;

procedure TfmTextBlock.CheckTextBlocks;
var
  HasErrors: Boolean;
  Block: TTextBlockRec;
  Report: TPrintReportRec;
begin
  HasErrors := False;
  Block := FReader.ReadHeaderBlock;
  if Block.Text <> '' then
  begin
    Memo.Lines.Add(Format('HeaderBlock.Text = "%s"', [Block.Text]));
    HasErrors := True;
  end;
  Block := FReader.ReadTrailerBlock;
  if Block.Text <> '' then
  begin
    Memo.Lines.Add(Format('TrailerBlock.Text = "%s"', [Block.Text]));
    HasErrors := True;
  end;
  if not HasErrors then
    Memo.Lines.Add('Text blocks are cleared');

  Report := FReader.ReadPrintReport;
  if not Report.Successful then
    Memo.Lines.Add('ERROR: Report is not successful');
  if not((Report.PrintTime >= FStartTime)and(Report.PrintTime <= Time)) then
  begin
    Memo.Lines.Add('ERROR: Invalid report time: ' + TimeToStr(Report.PrintTime));
    Memo.Lines.Add('StartTime: ' + TimeToStr(FStartTime));
    Memo.Lines.Add('EndTime: ' + TimeToStr(Now));
  end;
end;

procedure TfmTextBlock.btnSalesReceiptClick(Sender: TObject);
begin
  btnSalesReceipt.Enabled := False;
  try
    FReader.ClearPrintReport;
    FStartTime := Time;

    SaveTextBlocks;
    PrintSalesReceipt;
    CheckTextBlocks;
  finally
    btnSalesReceipt.Enabled := True;
    btnSalesReceipt.SetFocus;
  end;
end;

procedure TfmTextBlock.btnRefundReceiptClick(Sender: TObject);
begin
  btnRefundReceipt.Enabled := False;
  try
    FReader.ClearPrintReport;
    FStartTime := Now;

    SaveTextBlocks;
    PrintRefundReceipt;
    CheckTextBlocks;
  finally
    btnRefundReceipt.Enabled := True;
    btnRefundReceipt.SetFocus;
  end;
end;

procedure TfmTextBlock.LoadTextBlocks;
begin
  memHeader.Text := FReader.ReadHeaderBlock.Text;
  memTrailer.Text := FReader.ReadTrailerBlock.Text;
end;

procedure TfmTextBlock.SaveTextBlocks;
var
  Block: TTextBlockRec;
begin
  if chbInvalidTime.Checked then
    Block.SecondsOfDay := GetDaySeconds - 1
  else
    Block.SecondsOfDay := GetDaySeconds + 100;

  // Header
  Block.Text := memHeader.Text;
  FReader.WriteHeaderBlock(Block);
  // Trailer
  Block.Text := memTrailer.Text;
  FReader.WriteTrailerBlock(Block);
end;

procedure TfmTextBlock.btnLoadBlockClick(Sender: TObject);
begin
  LoadTextBlocks;
end;

procedure TfmTextBlock.btnDefaultBlocksClick(Sender: TObject);
begin
  memHeader.Clear;
  memHeader.Lines.Add('ChequeBlock1, Line1');
  memHeader.Lines.Add('ChequeBlock1, Line2');
  memHeader.Lines.Add('ChequeBlock1, Line3');

  memTrailer.Clear;
  memTrailer.Lines.Add('ChequeBlock2, Line1');
  memTrailer.Lines.Add('ChequeBlock2, Line2');
  memTrailer.Lines.Add('ChequeBlock2, Line3');
end;

end.
