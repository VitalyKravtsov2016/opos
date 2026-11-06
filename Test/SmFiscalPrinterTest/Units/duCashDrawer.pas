unit duCashDrawer;

interface

uses
  // VCL
  Windows, SysUtils, Classes,
  // DUnit
  TestFramework,
  // Opos
  Opos, Oposhi,
  // This
  SharedPrinter, FiscalPrinterTypes, oleCashDrawer, SmFiscalPrinterLib_TLB,
  CashDrawerParameters, LogFile, oleFiscalPrinter, PrinterParameters,
  PrinterParametersX, MockFiscalPrinterDevice, DefaultModel, DriverTypes;

type
  { TCashDrawerTest }

  TCashDrawerTest = class(TTestCase)
  published
    procedure TestCashDrawer;
    procedure TestFiscalPrinterAndCashDrawerShareDevice;
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


procedure TCashDrawerTest.TestFiscalPrinterAndCashDrawerShareDevice;
const
  DeviceName = 'SharedFiscalPrinterDevice';
var
  ResultCode: Integer;
  Device: TMockFiscalPrinterDevice;
  CashDrawer: ICashDrawer;
  FiscalPrinter: ToleFiscalPrinter;
  FiscalPrinterService: IFiscalPrinterService_1_12;
  SPrinter: ISharedPrinter;
  DrawerParams: TCashDrawerParameters;
  PrinterParams: TPrinterParameters;
  Logger: ILogFile;
  Model: TPrinterModelRec;
begin
  // The cash drawer must point to the same fiscal printer device.
  DrawerParams := TCashDrawerParameters.Create(TLogFile.Create);
  try
    DrawerParams.SetDefaults;
    DrawerParams.FptrDeviceName := DeviceName;
    DrawerParams.DrawerNumber := 1;
    DrawerParams.Save('OposCashDrawer');
  finally
    DrawerParams.Free;
  end;

  // Fiscal printer parameters for the shared device.
  Logger := TLogFile.Create;
  PrinterParams := TPrinterParameters.Create(Logger);
  try
    PrinterParams.SetDefaults;
    SaveParameters(PrinterParams, DeviceName, Logger);
  finally
    PrinterParams.Free;
    Logger := nil;
  end;

  // Create the shared device object once and inject a mock,
  // so both COM objects use the same device without a real COM port.
  Device := TMockFiscalPrinterDevice.Create;
  try
    Model := PrinterModelDefault;
    Model.NumHeaderLines := 0;
    Model.NumTrailerLines := 0;
    Device.Model := Model;

    SPrinter := SharedPrinter.GetPrinter(DeviceName);
    SPrinter.Device := Device;

    // Create both COM objects.
    FiscalPrinter := ToleFiscalPrinter.Create(nil);
    FiscalPrinterService := FiscalPrinter;
    CashDrawer := ToleCashDrawer.Create;
    try
      // Open
      ResultCode := FiscalPrinter.Open('FiscalPrinter', DeviceName, nil);
      CheckEquals(0, ResultCode, 'FiscalPrinter.Open');

      ResultCode := CashDrawer.Open('CashDrawer', 'OposCashDrawer', nil);
      CheckEquals(0, ResultCode, 'CashDrawer.Open');

      // Both objects must share one device (one COM port).
      CheckEquals(1, GetPrintersCount, 'GetPrintersCount <> 1');

      // Claim
      ResultCode := FiscalPrinter.Claim(0);
      CheckEquals(0, ResultCode, 'FiscalPrinter.Claim');

      ResultCode := CashDrawer.Claim(0);
      CheckEquals(0, ResultCode, 'CashDrawer.Claim');

      // Enable
      FiscalPrinter.SetPropertyNumber(PIDX_DeviceEnabled, 1);
      CheckEquals(1, FiscalPrinter.GetPropertyNumber(PIDX_DeviceEnabled),
        'FiscalPrinter.DeviceEnabled');

      CashDrawer.SetPropertyNumber(PIDX_DeviceEnabled, 1);
      CheckEquals(1, CashDrawer.GetPropertyNumber(PIDX_DeviceEnabled),
        'CashDrawer.DeviceEnabled');

      // The shared physical device must be connected only once.
      CheckEquals(1, Device.ConnectCount, 'Device.ConnectCount <> 1');

      // The cash drawer must be able to work through the shared device.
      ResultCode := CashDrawer.OpenDrawer;
      CheckEquals(0, ResultCode, 'CashDrawer.OpenDrawer');

      // The fiscal printer must still work after the drawer was opened.
      ResultCode := FiscalPrinter.CheckHealth(OPOS_CH_INTERNAL);
      CheckEquals(0, ResultCode, 'FiscalPrinter.CheckHealth');
    finally
      CashDrawer := nil;
      FiscalPrinterService := nil;
      SPrinter := nil;
    end;
  finally
    Device.Free;
  end;

  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0 after release');
end;

initialization
  RegisterTest('', TCashDrawerTest.Suite);

end.
