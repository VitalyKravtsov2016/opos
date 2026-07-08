unit duCashDrawer;

interface

uses
  // VCL
  Windows, SysUtils, Classes,
  // DUnit
  TestFramework,
  // This
  SharedPrinter, FiscalPrinterTypes, oleCashDrawer, SmFiscalPrinterLib_TLB,
  CashDrawerParameters, LogFile, oleFiscalPrinter, PrinterParameters,
  PrinterParametersX;

type
  { TCashDrawerTest }

  TCashDrawerTest = class(TTestCase)
  published
    procedure TestCashDrawer;
  end;

implementation

{ TCashDrawerTest }

procedure TCashDrawerTest.TestCashDrawer;
var
  ResultCode: Integer;
  CashDrawer: ICashDrawer;
  FiscalPrinter: ToleFiscalPrinter;
  FiscalPrinterService: IFiscalPrinterService_1_12;
  DrawerParams: TCashDrawerParameters;
  PrinterParams: TPrinterParameters;
  Logger: ILogFile;
  FileName: string;
  Lines: TStrings;
  Text: string;
  P: Integer;
begin
  DrawerParams := TCashDrawerParameters.Create(TLogFile.Create);
  try
    DrawerParams.SetDefaults;
    DrawerParams.FptrDeviceName := 'OposFiscalPrinter';
    DrawerParams.Save('OposCashDrawer');
  finally
    DrawerParams.Free;
  end;

  Logger := TLogFile.Create;
  PrinterParams := TPrinterParameters.Create(Logger);
  try
    PrinterParams.SetDefaults;
    SaveParameters(PrinterParams, 'OposFiscalPrinter', Logger);
  finally
    PrinterParams.Free;
    Logger := nil;
  end;


  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');
  FiscalPrinter := ToleFiscalPrinter.Create(nil);
  FiscalPrinterService := FiscalPrinter;
  CashDrawer := ToleCashDrawer.Create;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');

  ResultCode := FiscalPrinter.Open('FiscalPrinter', 'OposFiscalPrinter', nil);
  CheckEquals(0, ResultCode, 'FiscalPrinter.Open');
  FileName := FiscalPrinter.Logger.FileName;

  ResultCode := CashDrawer.Open('CashDrawer', 'OposCashDrawer', nil);
  CheckEquals(0, ResultCode, 'CashDrawer.Open');

  CheckEquals(1, GetPrintersCount, 'GetPrintersCount <> 1');
  CashDrawer := nil;
  FiscalPrinterService := nil;
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');


  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    Check(Lines.Count > 0, 'Lines.Count <= 0');
    Text := Lines.Text;

    // ToleCashDrawer.Open(CashDrawer, OposCashDrawer) = 0
    P := Pos('ToleCashDrawer.Open(CashDrawer, OposCashDrawer) = 0', Text);
    Check(P <> 0, 'ToleCashDrawer.Open(CashDrawer, OposCashDrawer) = 0');

    // ToleCashDrawer.Close = 0
    P := Pos('ToleCashDrawer.Close = 0', Text);
    Check(P <> 0, 'ToleCashDrawer.Close = 0');
  finally
    Lines.Free;
  end;
end;


initialization
  RegisterTest('', TCashDrawerTest.Suite);

end.
