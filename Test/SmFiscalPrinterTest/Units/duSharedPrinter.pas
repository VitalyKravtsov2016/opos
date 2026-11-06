unit duSharedPrinter;

interface

uses
  // VCL
  Windows, SysUtils, Classes,
  // DUnit
  TestFramework,
  // This
  SharedPrinter, FiscalPrinterTypes, oleCashDrawer, SmFiscalPrinterLib_TLB,
  CashDrawerParameters, LogFile, oleFiscalPrinter, FileUtils, MockFiscalPrinterDevice;

type
  { TSharedPrinterTest }

  TSharedPrinterTest = class(TTestCase)
  published
    procedure TestGetPrinter;
    procedure TestCashDrawer;
    procedure TestFiscalPrinter;
    procedure TestCashDrawer2;
    procedure TestLogger;
    procedure TestConnectDisconnectRefCount;
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

procedure TSharedPrinterTest.TestConnectDisconnectRefCount;
var
  Device: TMockFiscalPrinterDevice;
  Printer: ISharedPrinter;
begin
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');

  Device := TMockFiscalPrinterDevice.Create;
  try
    Printer := GetPrinter('RefCountDevice');
    Printer.Device := Device;

    // Two clients (fiscal printer + cash drawer) share the same device.
    Printer.Connect;
    Printer.Connect;
    CheckEquals(1, Device.ConnectCount,
      'Device.Connect must be called once for the first client');

    // Disconnecting the first client must not disconnect the shared device
    // because the second client is still connected.
    Printer.Disconnect;
    CheckEquals(0, Device.DisconnectCount,
      'Device.Disconnect must not be called while other clients are connected');

    // Disconnecting the last client disconnects the device.
    Printer.Disconnect;
    CheckEquals(1, Device.DisconnectCount,
      'Device.Disconnect must be called once after the last client disconnects');
  finally
    Printer := nil;
    Device.Free;
  end;

  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0 after release');
end;

initialization
  RegisterTest('', TSharedPrinterTest.Suite);

end.
