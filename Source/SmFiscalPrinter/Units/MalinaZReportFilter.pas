unit MalinaZReportFilter;

interface

uses
  // VCL
  SysUtils,
  // 3'd
  TntSysUtils,
  // This
  FiscalPrinterImpl, LogFile, MalinaCard, PrinterTypes, FiscalPrinterTypes,
  NonfiscalDoc, FptrFilter, CustomReceipt, MalinaParams, PrinterParameters,
  StringUtils;

type
  { TDepartmentTotals }

  TDepartmentTotals = record
    Sale: Int64;
    Buy: Int64;
    RetSale: Int64;
    RetBuy: Int64;
  end;

  { TMalinaZReportFilter }

  TMalinaZReportFilter = class(TFptrFilter)
  private
    function GetDevice: IFiscalPrinterDevice;
    procedure PrintDepartmentReport;
    procedure ReadDepartmentReport;
    procedure PrintSeparator;
    procedure PrintDiscounts;
  private
    FParams: TMalinaParams;
    FPrinter: ISharedPrinter;
    FHasDepartments: Boolean;
    FTaxTotals: TTaxTotals;
    FTaxAmounts: array [0..3] of TTaxTotals;
    FTotals: array [1..16] of TDepartmentTotals;
    FItemCount: array [1..16] of TDepartmentTotals;
    FChargeAmount: array [0..3] of Int64;
    FDiscountAmount: array [0..3] of Int64;
    FChargeCount: array [0..3] of Integer;
    FDiscountCount: array [0..3] of Integer;

    procedure ReadDiscounts;
    procedure ReadTaxAmounts;
    procedure PrintTaxAmounts;
    procedure PrintAmount(const Text: WideString; Count, Totals: Int64);

    property Printer: ISharedPrinter read FPrinter;
    property Device: IFiscalPrinterDevice read GetDevice;
  public
    constructor Create(AOwner: TFptrFilters; APrinter: ISharedPrinter; AParams: TMalinaParams);
    destructor Destroy; override;

    procedure BeforeXReport; override;
    procedure AfterXReport; override;
    procedure BeforeZReport; override;
    procedure AfterZReport; override;
  end;

implementation

const
  RecName: array [0..3] of WideString = (
    '������', '������','������� �������', '������� �������');

{ TMalinaZReportFilter }

constructor TMalinaZReportFilter.Create(AOwner: TFptrFilters; APrinter: ISharedPrinter;
  AParams: TMalinaParams);
begin
  inherited Create(AOwner);
  FPrinter := APrinter;
  FParams := AParams;
end;

destructor TMalinaZReportFilter.Destroy;
begin
  FPrinter := nil;
  inherited Destroy;
end;


(*
// ����� ������� �� �����
// ������
// ��� 18.00%           =205.04

 225.���������� �� ������ � � ������ � �����                  : 9.92
 226.���������� �� ������ � � ������� � �����                 : 0.00
 227.���������� �� ������ � � �������� ������ � �����         : 0.00
 228.���������� �� ������ � � �������� ������� � �����        : 0.00
 229.���������� �� ������ � � ������ � �����                  : 0.00
 230.���������� �� ������ � � ������� � �����                 : 0.00
 231.���������� �� ������ � � �������� ������ � �����         : 0.00
 232.���������� �� ������ � � �������� ������� � �����        : 0.00
 233.���������� �� ������ � � ������ � �����                  : 0.00
 234.���������� �� ������ � � ������� � �����                 : 0.00
 235.���������� �� ������ � � �������� ������ � �����         : 0.00
 236.���������� �� ������ � � �������� ������� � �����        : 0.00
 237.���������� �� ������ � � ������ � �����                  : 0.00
 238.���������� �� ������ � � ������� � �����                 : 0.00
 239.���������� �� ������ � � �������� ������ � �����         : 0.00
 240.���������� �� ������ � � �������� ������� � �����        : 0.00

*)

procedure TMalinaZReportFilter.ReadTaxAmounts;
var
  RecType: Integer;
  TaxType: Integer;
  TaxAmount: Int64;
  TaxTotal: Int64;
begin
  for RecType := 0 to 3 do
  begin
    TaxTotal := 0;
    for TaxType := 0 to 3 do
    begin
      TaxAmount := Device.ReadCashRegister(225 + TaxType*4 + RecType);
      FTaxAmounts[RecType][TaxType] := TaxAmount;
      TaxTotal := TaxTotal + TaxAmount;
    end;
    FTaxTotals[RecType] := TaxTotal;
  end;
end;

procedure TMalinaZReportFilter.PrintTaxAmounts;
var
  Line: WideString;
  HasTax: Boolean;
  RecType: Integer;
  TaxType: Integer;
  TaxAmount: Int64;
begin
  HasTax := False;
  for RecType := 0 to 3 do
  begin
    if FTaxTotals[RecType] > 0 then
    begin
      HasTax := True;
      Break;
    end;
  end;
  if HasTax then
  begin
    Printer.PrintText('����� ������� �� �����');
    for RecType := 0 to 3 do
    begin
      if FTaxTotals[RecType] <> 0 then
      begin
        Printer.PrintText(RecName[RecType]);
      end;
      for TaxType := 0 to 3 do
      begin
        TaxAmount := FTaxAmounts[RecType][TaxType];
        if TaxAmount <> 0 then
        begin
          Line := Device.FormatLines(Device.GetTaxInfo(TaxType+1).Name,
            '=' + AmountToStr(TaxAmount/100));
          Printer.PrintText(Line);
        end;
      end;
    end;
    PrintSeparator;
  end;
end;

procedure TMalinaZReportFilter.ReadDepartmentReport;
var
  i: Integer;
  Count: Integer;
  Number: Integer;
begin
  FHasDepartments := False;
  for i := 1 to 16 do
  begin
    Number := 121 + (i-1)*4;
    FTotals[i].Sale := Printer.Device.ReadCashRegister(Number);
    FTotals[i].Buy := Printer.Device.ReadCashRegister(Number + 1);
    FTotals[i].RetSale := Printer.Device.ReadCashRegister(Number + 2);
    FTotals[i].RetBuy := Printer.Device.ReadCashRegister(Number + 3);

    Number := 72 + (i-1)*4;
    FItemCount[i].Sale := Printer.Device.ReadOperatingRegister(Number);
    FItemCount[i].Buy := Printer.Device.ReadOperatingRegister(Number + 1);
    FItemCount[i].RetSale := Printer.Device.ReadOperatingRegister(Number + 2);
    FItemCount[i].RetBuy := Printer.Device.ReadOperatingRegister(Number + 3);

    Count := FItemCount[i].Sale + FItemCount[i].Buy +
      FItemCount[i].RetSale + FItemCount[i].RetBuy;
    if Count > 0 then
      FHasDepartments := True;
  end;
end;

procedure TMalinaZReportFilter.PrintAmount(const Text: WideString; Count, Totals: Int64);
var
  Line1: WideString;
  Line2: WideString;
begin
  Line1 := Tnt_WideFormat('%.4d %s', [Count, Text]);
  Line2 := '=' + AmountToStr(Totals/100);
  Printer.PrintLines(Line1, Line2);
end;

procedure TMalinaZReportFilter.PrintSeparator;
begin
  Printer.PrintText(StringOfChar('-', Printer.PrintWidth));
end;

procedure TMalinaZReportFilter.PrintDepartmentReport;
var
  i: Integer;
  Count: Integer;
begin
  if not FHasDepartments then Exit;

  for i := 1 to 16 do
  begin
    Count := FItemCount[i].Sale + FItemCount[i].Buy +
      FItemCount[i].RetSale + FItemCount[i].RetBuy;

    if Count <> 0 then
    begin
      Printer.PrintLines('������', IntToStr(i));
      PrintAmount('�������', FItemCount[i].Sale, FTotals[i].Sale);
      PrintAmount('�������', FItemCount[i].Buy, FTotals[i].Buy);
      PrintAmount('�����.�������', FItemCount[i].RetSale, FTotals[i].RetSale);
      PrintAmount('�����.�������', FItemCount[i].RetBuy, FTotals[i].RetBuy);
    end;
  end;
  PrintSeparator;
end;

procedure TMalinaZReportFilter.BeforeZReport;
begin
  ReadDiscounts;
  ReadTaxAmounts;
  ReadDepartmentReport;
end;

procedure TMalinaZReportFilter.BeforeXReport;
begin
  ReadDiscounts;
  ReadTaxAmounts;
  ReadDepartmentReport;
end;

procedure TMalinaZReportFilter.AfterZReport;
begin
  PrintDiscounts;
  PrintTaxAmounts;
  PrintDepartmentReport;
end;

procedure TMalinaZReportFilter.AfterXReport;
begin
  PrintDiscounts;
  PrintTaxAmounts;
  PrintDepartmentReport;
end;

function TMalinaZReportFilter.GetDevice: IFiscalPrinterDevice;
begin
  Result := Printer.Device;
end;
(*
 185.���������� ������ � ������ � �����                       : 0.00
 186.���������� ������ � ������� � �����                      : 0.00
 187.���������� ������ � �������� ������ � �����              : 0.00
 188.���������� ������ � �������� ������� � �����             : 0.00
 189.���������� �������� �� ������� � �����                   : 0.00
 190.���������� �������� �� ������� � �����                   : 0.00
 191.���������� �������� �� �������� ������ � �����           : 0.00
 192.���������� �������� �� �������� ������� � �����          : 0.00

 136.���������� ������ � ������ � �����                 : 0
 137.���������� ������ � ������� � �����                : 0
 138.���������� ������ � �������� ������ � �����        : 0
 139.���������� ������ � �������� ������� � �����       : 0
 140.���������� �������� �� ������� � �����             : 0
 141.���������� �������� �� ������� � �����             : 0
 142.���������� �������� �� �������� ������ � �����     : 0
 143.���������� �������� �� �������� ������� � �����    : 0

*)

procedure TMalinaZReportFilter.ReadDiscounts;
var
  i: Integer;
begin
  for i := 0 to 3 do
  begin
    FDiscountAmount[i] := Device.ReadCashRegister(185 + i);
    FDiscountCount[i] := Device.ReadOperatingRegister(136 + i);

    FChargeAmount[i] := Device.ReadCashRegister(189 + i);
    FChargeCount[i] := Device.ReadOperatingRegister(140 + i);
  end;
end;

procedure TMalinaZReportFilter.PrintDiscounts;
var
  i: integer;
begin
  PrintSeparator;
  Printer.PrintText('            ������');
  for i := 0 to 3 do
  begin
    PrintAmount(RecName[i], FDiscountCount[i], FDiscountAmount[i]);
  end;
  Printer.PrintText('            ��������');
  for i := 0 to 3 do
  begin
    PrintAmount(RecName[i], FChargeCount[i], FChargeAmount[i]);
  end;
  PrintSeparator;
end;

end.
