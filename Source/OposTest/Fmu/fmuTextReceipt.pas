unit fmuTextreceipt;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  // 3'd
  PngImage,
  // This
  untPages, Opos, OposUtils, OposFiscalPrinter, OposFptr, OposFptrUtils,
  UniposReader;

type
  TfmTextReceipt = class(TPage)
    memBlock1: TMemo;
    btnSave: TButton;
    lblBlock1: TLabel;
    memBlock2: TMemo;
    lblBlock2: TLabel;
    btnLoad: TButton;
    chbNewCheck: TCheckBox;
    btnSetDefaults: TButton;
    btnPrint: TButton;
    procedure btnSaveClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSetDefaultsClick(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
  private
    FReader: TUniposReader;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  fmTextReceipt: TfmTextReceipt;

implementation

{$R *.dfm}

const
  CRLF = #13#10;

  DefNewChequeText =
    '-----------------------------------------' + CRLF +
    ' ���������� �� �����                     ' + CRLF +
    ' �����:                            123456' + CRLF +
    ' ��������:                         123456' + CRLF +
    ' ���� � �����:                      12:34' + CRLF +
    ' ������� ������� �� �����:        10 ���.' + CRLF +
    ' ��������� ��� ��������:          10 ���.' + CRLF +
    ' ������� �� ����� � ������:       10 ���.' + CRLF +
    '                                         ' + CRLF +
    '-----------------------------------------';

  DefNewChequeText1 =
    'ChequeBlock2, Line1' + CRLF +
    'ChequeBlock2, Line2' + CRLF +
    'ChequeBlock2, Line3';


{ TfmTextBlock }

constructor TfmTextReceipt.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FReader := TUniposReader.Create(FiscalPrinter.Logger);
  memBlock1.Text := DefNewChequeText;
  memBlock2.Text := DefNewChequeText1;
end;

destructor TfmTextReceipt.Destroy;
begin
  FReader.Free;
  inherited Destroy;
end;

(*

-------------------------------------------
���������� �� �����
�����:                               123456
��������:                            123456
���� � �����:                         12:34
������� ������� �� �����:           10 ���.
� ��� ����� ��������� ��� ��������: 10 ���.
������� ������� �� ����� � ������:  10 ���.

-------------------------------------------

*)

procedure TfmTextReceipt.btnSaveClick(Sender: TObject);
var
  Data: TTextReceiptRec;
begin
  Data.NewChequeText := memBlock1.Text;
  Data.NewChequeText1 := memBlock2.Text;
  Data.NewChequeFlag := chbNewCheck.Checked;
  FReader.WriteTextReceipt(Data);
end;

procedure TfmTextReceipt.btnLoadClick(Sender: TObject);
var
  Data: TTextReceiptRec;
begin
  Data := FReader.ReadTextReceipt;
  memBlock1.Text := Data.NewChequeText;
  memBlock2.Text := Data.NewChequeText1;
  chbNewCheck.Checked := Data.NewChequeFlag;
end;

procedure TfmTextReceipt.btnSetDefaultsClick(Sender: TObject);
begin
  chbNewCheck.Checked := True;
  memBlock1.Text := DefNewChequeText;
  memBlock2.Text := DefNewChequeText1;
end;

procedure TfmTextReceipt.btnPrintClick(Sender: TObject);
var
  TickCount: Integer;
  Data: TTextReceiptRec;
begin
  Data.NewChequeFlag := True;
  Data.NewChequeText := memBlock1.Text;
  Data.NewChequeText1 := memBlock2.Text;
  FReader.WriteTextReceipt(Data);

  TickCount := GetTickCount + 5000; // 5 seconds
  repeat
    Data := FReader.ReadTextReceipt;
    if (Data.NewChequeText = '')and(Data.NewChequeText1 = '') and(not Data.NewChequeFlag) then
    begin
      MessageBox(Handle, 'Receipt printed and registry keys are cleared.',
        'Print result', MB_OK or MB_ICONINFORMATION);
      Exit;
    end;
    Sleep(100);
  until Integer(GetTickCount) > TickCount;
  MessageBox(Handle, 'Timeout waiting for registry keys to be cleared.',
    'Print result', MB_OK or MB_ICONEXCLAMATION);
end;

end.
