unit duSharedPrinter;

interface

uses
  // VCL
  Windows, SysUtils, Classes,
  // DUnit
  TestFramework,
  // This
  SharedPrinter, FiscalPrinterTypes, oleCashDrawer, SmFiscalPrinterLib_TLB,
  CashDrawerParameters, LogFile, oleFiscalPrinter, FileUtils;

type
  { TSharedPrinterTest }

  TSharedPrinterTest = class(TTestCase)
  published
    procedure TestGetPrinter;
    procedure TestCashDrawer;
    procedure TestFiscalPrinter;
    procedure TestCashDrawer2;
    procedure TestLogger;
  end;

implementation

{ TSharedPrinterTest }

procedure TSharedPrinterTest.TestCashDrawer;
var
  ResultCode: Integer;
  CashDrawer: ICashDrawer;
begin
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
  CashDrawer := ToleCashDrawer.Create;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
  ResultCode := CashDrawer.Open('CashDrawer', 'OposCashDrawer', nil);
  CheckEquals(0, ResultCode, 'CashDrawer.Open');
  CheckEquals(1, GetPrintersCount, 'GetPrintersCount <> 1');
  CashDrawer := nil;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
end;

procedure TSharedPrinterTest.TestFiscalPrinter;
var
  ResultCode: Integer;
  FiscalPrinter: IFiscalPrinterService_1_12;
begin
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
  FiscalPrinter := ToleFiscalPrinter.Create(nil);
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
  ResultCode := FiscalPrinter.Open('FiscalPrinter', 'OposFiscalPrinter', nil);
  CheckEquals(0, ResultCode, 'FiscalPrinter.Open');
  CheckEquals(1, GetPrintersCount, 'GetPrintersCount <> 1');
  FiscalPrinter := nil;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
end;

procedure TSharedPrinterTest.TestCashDrawer2;
var
  ResultCode: Integer;
  CashDrawer: ICashDrawer;
  FiscalPrinter: IFiscalPrinterService_1_12;
  DrawerParams: TCashDrawerParameters;
begin
  DrawerParams := TCashDrawerParameters.Create(TLogFile.Create);
  try
    DrawerParams.FptrDeviceName := 'OposFiscalPrinter2';
    DrawerParams.Save('OposCashDrawer');
  finally
    DrawerParams.Free;
  end;

  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
  FiscalPrinter := ToleFiscalPrinter.Create(nil);
  CashDrawer := ToleCashDrawer.Create;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');

  ResultCode := FiscalPrinter.Open('FiscalPrinter', 'OposFiscalPrinter', nil);
  CheckEquals(0, ResultCode, 'FiscalPrinter.Open');

  ResultCode := CashDrawer.Open('CashDrawer', 'OposCashDrawer', nil);
  CheckEquals(0, ResultCode, 'CashDrawer.Open');

  CheckEquals(2, GetPrintersCount, 'GetPrintersCount <> 2');
  CashDrawer := nil;
  FiscalPrinter := nil;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
end;

procedure TSharedPrinterTest.TestGetPrinter;
var
  Printer1: ISharedPrinter;
  Printer2: ISharedPrinter;
begin
  // One Printer
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
  Printer1 := GetPrinter('DeviceName');
  CheckEquals(1, GetPrintersCount, 'GetPrintersCount <> 1');
  Printer1 := nil;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');

  // One Printers
  Printer1 := GetPrinter('DeviceName');
  CheckEquals(1, GetPrintersCount, 'GetPrintersCount <> 1');
  Printer2 := GetPrinter('DeviceName');
  CheckEquals(1, GetPrintersCount, 'GetPrintersCount <> 1');
  Printer1 := nil;
  Printer2 := nil;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');

  // Two printers
  Printer1 := GetPrinter('DeviceName1');
  CheckEquals(1, GetPrintersCount, 'GetPrintersCount <> 1');
  Printer2 := GetPrinter('DeviceName2');
  CheckEquals(2, GetPrintersCount, 'GetPrintersCount <> 2');
  Printer1 := nil;
  Printer2 := nil;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
end;

procedure TSharedPrinterTest.TestLogger;
var
  FileName: string;
  Printer: ISharedPrinter;
begin
  Printer := TSharedPrinter.Create('DeviceName');
  try
    FileName := Printer.Context.Logger.FileName;
    if FileExists(FileName) then
      Check(DeleteFile(FileName), 'DeleteFile.0');

    Printer.Context.Logger.Enabled := True;
    Printer.Context.Logger.DeviceName := 'Device1';
    Printer.Context.Logger.Write('Test');
  finally
    Printer := nil;
  end;
  CheckEquals('Test', ReadFileData(FileName), 'ReadFileData');
  Check(DeleteFile(FileName), 'DeleteFile.1');
end;

initialization
  RegisterTest('', TSharedPrinterTest.Suite);

end.
