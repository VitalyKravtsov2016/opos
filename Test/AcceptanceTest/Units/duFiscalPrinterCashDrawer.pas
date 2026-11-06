unit duFiscalPrinterCashDrawer;

{ Acceptance test: ToleFiscalPrinter (fiscal printer) and ToleCashDrawer
  (cash drawer) share one FR device over a real Com0Com serial port pair.

  The FR side is emulated by TFREmulator, copied from the FREmulDelphi
  project (it supports the $28 OpenDrawer command that the cash drawer
  needs). The fiscal printer is configured for the SHTRIH-M DrvFR driver. }

interface

uses
  // VCL
  Windows, SysUtils, Classes, ActiveX, ComObj,
  // DUnit
  TestFramework,
  // Opos
  Opos, Oposhi,
  // This
  FREmulator, oleFiscalPrinter, oleCashDrawer, SmFiscalPrinterLib_TLB,
  SharedPrinter, CashDrawerParameters, LogFile, PrinterParameters,
  PrinterParametersX;

type
  { TFiscalPrinterCashDrawerTest }

  TFiscalPrinterCashDrawerTest = class(TTestCase)
  private
    FEmulator: TFREmulator;

    procedure SaveDrvFrParameters(const DeviceName: WideString);
    procedure SaveDrawerParameters(const DeviceName: WideString);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure FiscalPrinterAndCashDrawerShareComPort;
  end;

implementation

const
  // Com0Com pair (RealPortName): driver <-> emulator
  DriverPort = 20;
  EmulatorPort = 21;
  BaudRate = 115200;
  EmulatorBaudCode = 7; // TEmulSerialPort code: 7 -> 115200
  DeviceName = 'SHTRIH-M-ACCEPTANCE';

function TablesFileName: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'Data\Tables\' +
    'SHTRIH-ON-LINE_0289610204000839_PosCenter.csv';
end;

{ TFiscalPrinterCashDrawerTest }

procedure TFiscalPrinterCashDrawerTest.SetUp;
begin
  CoInitialize(nil);

  // Start the FR emulator on the emulator side of the Com0Com pair.
  FEmulator := TFREmulator.Create;
  FEmulator.LoadTables(TablesFileName);
  FEmulator.Start(Format('COM%d', [EmulatorPort]), EmulatorBaudCode);
  Sleep(300);

  // Fiscal printer talks to the emulator via the DrvFR driver.
  SaveDrvFrParameters(DeviceName);
  // Cash drawer points to the same fiscal printer device.
  SaveDrawerParameters(DeviceName);
end;

procedure TFiscalPrinterCashDrawerTest.TearDown;
begin
  if FEmulator <> nil then
  begin
    FEmulator.Stop;
    FEmulator.Free;
    FEmulator := nil;
  end;
  CoUninitialize;
end;

procedure TFiscalPrinterCashDrawerTest.SaveDrvFrParameters(
  const DeviceName: WideString);
var
  Logger: ILogFile;
  Params: TPrinterParameters;
begin
  Logger := TLogFile.Create;
  Params := TPrinterParameters.Create(Logger);
  try
    Params.SetDefaults;
    Params.DriverType := DriverTypeShtrihDriver;
    Params.ConnectionType := 0; // local serial
    Params.PortNumber := DriverPort;
    Params.BaudRate := BaudRate;
    Params.ByteTimeout := 1000;
    Params.MaxRetryCount := 3;
    Params.UsrPassword := 1;
    Params.SysPassword := 30;
    Params.PrinterProtocol := 0; // Protocol 1.0
    Params.SearchByPortEnabled := False;
    Params.SearchByBaudRateEnabled := False;
    Params.OpenReceiptEnabled := True;
    Params.CheckItemCodeEnabled := False;
    // Let the DrvFR driver take UModel from the FC answer.
    Params.ModelID := -1;
    Params.ReceiptReportEnabled := False;
    SaveParameters(Params, DeviceName, Logger);
  finally
    Params.Free;
    Logger := nil;
  end;
end;

procedure TFiscalPrinterCashDrawerTest.SaveDrawerParameters(
  const DeviceName: WideString);
var
  Params: TCashDrawerParameters;
begin
  Params := TCashDrawerParameters.Create(TLogFile.Create);
  try
    Params.SetDefaults;
    Params.FptrDeviceName := DeviceName;
    Params.DrawerNumber := 1;
    Params.Save('OposCashDrawer');
  finally
    Params.Free;
  end;
end;

procedure TFiscalPrinterCashDrawerTest.FiscalPrinterAndCashDrawerShareComPort;
var
  ResultCode: Integer;
  FiscalPrinter: ToleFiscalPrinter;
  FiscalPrinterService: IFiscalPrinterService_1_12;
  CashDrawer: ICashDrawer;
begin
  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0');

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

    // Cash drawer must work through the shared port.
    ResultCode := CashDrawer.OpenDrawer;
    CheckEquals(0, ResultCode, 'CashDrawer.OpenDrawer');

    // Fiscal printer must still work after the drawer was opened.
    ResultCode := FiscalPrinter.CheckHealth(OPOS_CH_INTERNAL);
    CheckEquals(0, ResultCode, 'FiscalPrinter.CheckHealth');
  finally
    CashDrawer := nil;
    FiscalPrinterService := nil;
  end;

  CheckEquals(0, GetPrintersCount, 'GetPrintersCount <> 0 after release');
end;

initialization
  RegisterTest('', TFiscalPrinterCashDrawerTest.Suite);

end.
