unit duMarkedReceiptDrivers;

{ Acceptance test: print a marked receipt via IFiscalPrinterDevice
  implementations and compare protocol bytes captured by TFiscalPrinterEmulator
  on Com0Com. Baseline = FiscalPrinterDevice (Internal). }

interface

uses
  // VCL
  Windows, SysUtils, Classes, ActiveX,
  // DUnit
  TestFramework,
  // This
  FiscalPrinterEmulator, FiscalPrinterTypes, FiscalPrinterDevice,
  FiscalPrinterDriver, FiscalPrinterDriverRR, FiscalPrinterDriverTB,
  DriverContext, PrinterParameters,
  PrinterTypes, PrinterProtocol1, SerialPort, PrinterPort, PrinterConnection,
  StringUtils, LogFile, FileUtils;

type
  { TMarkedReceiptDriversTest }

  TMarkedReceiptDriversTest = class(TTestCase)
  private
    FEmu: TFiscalPrinterEmulator;
    FContext: TDriverContext;
    FLogs: array[0..3] of TStringList;

    function CreateDevice(DriverType: Integer): IFiscalPrinterDevice;
    procedure ConfigureParameters;
    procedure PrintMarkedReceipt(Device: IFiscalPrinterDevice);
    function NormalizeLog(const Src: TStrings): string;
    procedure SaveLogsOnFail;
    procedure CheckResultCode(Code: Integer; const Op: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure CheckMarkedReceiptOnDrivers;
  end;

implementation

const
  // Com0Com pair (setupc RealPortName): driver <-> emulator
  DriverPort = 12;
  EmulatorPort = 13;
  BaudRate = 115200;
  // Fixed GS1 / DataMatrix-like mark code for comparison
  TestMarkCode = '010460406000000021N4N57RSCBUZTQ';
  TestItemText = 'Marked item';
  TestPrice = 1000; // kopecks = 10.00

{ TMarkedReceiptDriversTest }

procedure TMarkedReceiptDriversTest.SetUp;
var
  i: Integer;
begin
  CoInitialize(nil);

  for i := Low(FLogs) to High(FLogs) do
    FLogs[i] := TStringList.Create;

  FEmu := TFiscalPrinterEmulator.Create;
  FEmu.Start(EmulatorPort, BaudRate);
  Sleep(200);

  FContext := TDriverContext.Create;
  ConfigureParameters;
end;

procedure TMarkedReceiptDriversTest.TearDown;
var
  i: Integer;
begin
  FContext.Free;
  FContext := nil;

  if FEmu <> nil then
  begin
    FEmu.Stop;
    FEmu.Free;
    FEmu := nil;
  end;

  for i := Low(FLogs) to High(FLogs) do
  begin
    FLogs[i].Free;
    FLogs[i] := nil;
  end;

  CoUninitialize;
end;

procedure TMarkedReceiptDriversTest.ConfigureParameters;
begin
  FContext.Parameters.ConnectionType := 0; // local
  FContext.Parameters.PortNumber := DriverPort;
  FContext.Parameters.BaudRate := BaudRate;
  FContext.Parameters.ByteTimeout := 1000;
  FContext.Parameters.MaxRetryCount := 3;
  FContext.Parameters.UsrPassword := 1;
  FContext.Parameters.SysPassword := 30;
  FContext.Parameters.PrinterProtocol := 0; // Protocol 1.0
  FContext.Parameters.SearchByPortEnabled := False;
  FContext.Parameters.SearchByBaudRateEnabled := False;
  FContext.Parameters.OpenReceiptEnabled := True;
  FContext.Parameters.CheckItemCodeEnabled := False;
  // FN-capable model for DrvFR/KKTDrv (must match emulator $FC model)
  FContext.Parameters.ModelID := 27;
  FContext.Logger.Enabled := True;
end;

function TMarkedReceiptDriversTest.CreateDevice(DriverType: Integer): IFiscalPrinterDevice;
var
  Port: IPrinterPort;
  Conn: IPrinterConnection;
begin
  FContext.Parameters.DriverType := DriverType;
  case DriverType of
    DriverTypeShtrihDriver:
      Result := TFiscalPrinterDriver.Create(FContext);
    DriverTypeRRElectro:
      Result := TFiscalPrinterDriverRR.Create(FContext);
    DriverTypeTorgBalance:
      // TorgBalance DrvFR5: c:\Program Files (x86)\TorgBalance\DrvFR5\Bin\DrvFR.dll
      Result := TFiscalPrinterDriverTB.Create(FContext);
  else
    Port := GetSerialPort(DriverPort, FContext.Logger);
    Port.BaudRate := BaudRate;
    Conn := TPrinterProtocol1.Create(FContext.Logger, Port);
    Result := TFiscalPrinterDevice.Create(FContext, Conn);
  end;
end;

procedure TMarkedReceiptDriversTest.CheckResultCode(Code: Integer; const Op: string);
begin
  CheckEquals(0, Code, Format('%s failed, ResultCode=%d', [Op, Code]));
end;

procedure TMarkedReceiptDriversTest.PrintMarkedReceipt(Device: IFiscalPrinterDevice);
var
  Sale: TFSSale2;
  Bind: TFSBindItemCode;
  BindResult: TFSBindItemCodeResult;
  CloseP: TFSCloseReceiptParams2;
  CloseR: TFSCloseReceiptResult2;
  i: Integer;
  Step: string;
begin
  Step := 'Open';
  try
    Device.Open;
    Step := 'ClaimDevice';
    Device.ClaimDevice(5000);
    Step := 'OpenPort';
    Device.OpenPort;
    Step := 'Connect';
    Device.Connect;
    Step := 'UpdateInfo';
    // Avoid UpdateInfo against stub FR (fonts/tables/model probe). CapCloseReceipt3
    // stays false so all drivers close via FF45 — comparable TX logs.
    Device.CapFiscalStorage := True;

    Step := 'OpenDay';
    try
      Device.OpenDay;
    except
      on E: Exception do
        ; // optional if day already open / command unsupported on stub
    end;

    Step := 'FSClearMCCheckResults';
    Device.FSClearMCCheckResults;

    Step := 'OpenReceipt';
    CheckResultCode(Device.OpenReceipt(0), 'OpenReceipt');

    FillChar(Sale, SizeOf(Sale), 0);
    Sale.RecType := 1;
    Sale.Quantity := 1.0;
    Sale.Price := TestPrice;
    Sale.Total := TestPrice;
    Sale.Tax := 1;
    Sale.Department := 1;
    Sale.PaymentType := 4;
    Sale.PaymentItem := 1;
    Sale.Text := TestItemText;
    Step := 'FSSale2';
    CheckResultCode(Device.FSSale2(Sale), 'FSSale2');

    FillChar(Bind, SizeOf(Bind), 0);
    FillChar(BindResult, SizeOf(BindResult), 0);
    Bind.Code := TestMarkCode;
    Bind.IsAccounted := False;
    Step := 'FSBindItemCode';
    CheckResultCode(Device.FSBindItemCode(Bind, BindResult), 'FSBindItemCode');

    FillChar(CloseP, SizeOf(CloseP), 0);
    FillChar(CloseR, SizeOf(CloseR), 0);
    CloseP.Payments[0] := TestPrice;
    for i := 1 to High(CloseP.Payments) do
      CloseP.Payments[i] := 0;
    CloseP.TaxSystem := 1;
    CloseP.Text := '';
    Step := 'ReceiptClose2';
    CheckResultCode(Device.ReceiptClose2(CloseP, CloseR), 'ReceiptClose2');

    Step := 'ClosePort';
    Device.ClosePort;
    Step := 'ReleaseDevice';
    Device.ReleaseDevice;
    Step := 'Close';
    Device.Close;
  except
    on E: Exception do
      raise Exception.CreateFmt('[%s] %s', [Step, E.Message]);
  end;
end;

function TMarkedReceiptDriversTest.NormalizeLog(const Src: TStrings): string;
var
  i: Integer;
  Line: string;
  Code: string;
begin
  Result := '';
  for i := 0 to Src.Count - 1 do
  begin
    Line := Trim(Src[i]);
    if Line = '' then
      Continue;
    Code := UpperCase(Copy(Line, 1, 4));
    if (Copy(Code, 1, 2) = '8D') or
       (Copy(Code, 1, 2) = '80') or
       (Copy(Code, 1, 2) = '85') or
       (Copy(Code, 1, 2) = 'E0') or
       (Pos('FF46', Code) = 1) or
       (Pos('FF67', Code) = 1) or
       (Pos('FF69', Code) = 1) or
       (Pos('FF61', Code) = 1) or
       (Pos('FF45', Code) = 1) or
       (Pos('FF76', Code) = 1) then
    begin
      Result := Result + Line + #13#10;
    end;
  end;
end;

procedure TMarkedReceiptDriversTest.SaveLogsOnFail;
var
  Path: string;
begin
  Path := GetModulePath;
  FLogs[0].SaveToFile(Path + 'baseline_internal.tx');
  FLogs[1].SaveToFile(Path + 'shtrih_drvfr.tx');
  FLogs[2].SaveToFile(Path + 'rr_kktdrv.tx');
  FLogs[3].SaveToFile(Path + 'torgbalance_drvfr.tx');
end;

procedure TMarkedReceiptDriversTest.CheckMarkedReceiptOnDrivers;
var
  Device: IFiscalPrinterDevice;
  Baseline, Other: string;
  i: Integer;
  DriverTypes: array[0..3] of Integer;
  Names: array[0..3] of string;
  Raw: string;
  MarkHex: string;
begin
  DriverTypes[0] := DriverTypeInternal;
  DriverTypes[1] := DriverTypeShtrihDriver;
  DriverTypes[2] := DriverTypeRRElectro;
  DriverTypes[3] := DriverTypeTorgBalance;
  Names[0] := 'Internal';
  Names[1] := 'SHTRIH-M DrvFR';
  Names[2] := 'RR-Electro KKTDrv';
  Names[3] := 'TorgBalance DrvFR5';
  MarkHex := StrToHexText(AnsiString(TestMarkCode));

  for i := Low(DriverTypes) to High(DriverTypes) do
  begin
    FEmu.ClearLog;
    Device := CreateDevice(DriverTypes[i]);
    try
      try
        PrintMarkedReceipt(Device);
      except
        on E: Exception do
        begin
          FLogs[i].Text := FEmu.GetCommandLog;
          FLogs[i].SaveToFile(GetModulePath + Format('fail_%s.tx', [
            StringReplace(Names[i], ' ', '_', [rfReplaceAll])]));
          raise Exception.CreateFmt('%s: %s (emu cmds=%d)',
            [Names[i], E.Message, FLogs[i].Count]);
        end;
      end;
    finally
      Device := nil;
    end;
    Sleep(100);
    FLogs[i].Text := FEmu.GetCommandLog;
    Raw := StringReplace(UpperCase(FLogs[i].Text), ' ', '', [rfReplaceAll]);

    Check(FLogs[i].Count > 0,
      Format('%s: FR TX log is empty', [Names[i]]));
    Check(Pos(MarkHex, Raw) > 0,
      Format('%s: mark code not found in FR TX log', [Names[i]]));
  end;

  Baseline := NormalizeLog(FLogs[0]);
  Check(Baseline <> '', 'Baseline (Internal) significant command log is empty');
  Check(Pos('FF67', UpperCase(Baseline)) > 0,
    'Baseline must contain FF67 (bind marking)');

  for i := 1 to High(DriverTypes) do
  begin
    Other := NormalizeLog(FLogs[i]);
    if Baseline <> Other then
      SaveLogsOnFail;
    CheckEquals(Baseline, Other,
      Format('%s TX log differs from Internal baseline (see *.tx in Bin)', [Names[i]]));
  end;
end;

initialization
  RegisterTest('', TMarkedReceiptDriversTest.Suite);

end.
