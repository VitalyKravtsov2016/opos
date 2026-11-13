unit duFiscalPrinterCashDrawer;

{ Acceptance test: TOPOSFiscalPrinter (fiscal printer) and TOPOSCashDrawer
  (cash drawer) are created as COM control objects from the OPOS Common
  Control type libraries and share one FR device over a real Com0Com serial
  port pair.

  The FR side is emulated by TFREmulator (it supports the $28 OpenDrawer
  command that the cash drawer needs). The fiscal printer is configured for
  the SHTRIH-M DrvFR driver. The controls instantiate the already built and
  registered SmFiscalPrinter service object. }

interface

uses
  // VCL
  Windows, SysUtils, Classes, ActiveX,
  // DUnit
  TestFramework,
  // Opos
  Opos, OposFiscalPrinter_1_11_Lib_TLB, OposCashDrawer_1_13_Lib_TLB,
  // This
  FREmulator, CashDrawerParameters, LogFile, PrinterParameters,
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
  CashDrawerDeviceName = 'OposCashDrawer';

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
    Params.Save(CashDrawerDeviceName);
  finally
    Params.Free;
  end;
end;

procedure TFiscalPrinterCashDrawerTest.FiscalPrinterAndCashDrawerShareComPort;
var
  ResultCode: Integer;
  FiscalPrinter: TOPOSFiscalPrinter;
  CashDrawer: TOPOSCashDrawer;
begin
  FiscalPrinter := TOPOSFiscalPrinter.Create(nil);
  CashDrawer := TOPOSCashDrawer.Create(nil);
  try
    // Open: the control resolves the logical device name and instantiates
    // the registered service object (the already built SmFiscalPrinter driver).
    ResultCode := FiscalPrinter.Open(DeviceName);
    CheckEquals(0, ResultCode, 'FiscalPrinter.Open');

    ResultCode := CashDrawer.Open(CashDrawerDeviceName);
    CheckEquals(0, ResultCode, 'CashDrawer.Open');

    // Claim
    ResultCode := FiscalPrinter.ClaimDevice(0);
    CheckEquals(0, ResultCode, 'FiscalPrinter.ClaimDevice');

    ResultCode := CashDrawer.ClaimDevice(0);
    CheckEquals(0, ResultCode, 'CashDrawer.ClaimDevice');

    // Enable
    FiscalPrinter.DeviceEnabled := True;
    Check(Boolean(FiscalPrinter.DeviceEnabled), 'FiscalPrinter.DeviceEnabled');

    CashDrawer.DeviceEnabled := True;
    Check(Boolean(CashDrawer.DeviceEnabled), 'CashDrawer.DeviceEnabled');

    // Cash drawer must work through the shared port.
    ResultCode := CashDrawer.OpenDrawer;
    CheckEquals(0, ResultCode, 'CashDrawer.OpenDrawer');

    // Fiscal printer must still work after the drawer was opened.
    ResultCode := FiscalPrinter.CheckHealth(OPOS_CH_INTERNAL);
    CheckEquals(0, ResultCode, 'FiscalPrinter.CheckHealth');
  finally
    CashDrawer.Close;
    FiscalPrinter.Close;
    CashDrawer.Free;
    FiscalPrinter.Free;
  end;
end;

initialization
  RegisterTest('', TFiscalPrinterCashDrawerTest.Suite);

end.
