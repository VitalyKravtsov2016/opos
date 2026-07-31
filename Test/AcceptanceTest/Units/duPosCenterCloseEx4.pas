unit duPosCenterCloseEx4;

{ PosCenter (Addin.DrvFR / TFiscalPrinterDriver): ReceiptClose2 must send
  FF7Bh (FNCloseCheckEx4) with TaxValue11/12 per protocol v1.23. }

interface

uses
  Windows, SysUtils, Classes, ActiveX,
  TestFramework,
  FiscalPrinterEmulator, FiscalPrinterTypes, FiscalPrinterDriver,
  DriverContext, PrinterParameters, PrinterTypes, StringUtils, LogFile;

type
  TPosCenterCloseEx4Test = class(TTestCase)
  private
    FEmu: TFiscalPrinterEmulator;
    FContext: TDriverContext;
    function FindCloseLine(const Log: TStrings): string;
    function BinAt(const HexPayload: string; Offset, Count: Integer): Int64;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure CloseReceiptSendsFF7BWithTax11Tax12;
  end;

implementation

const
  DriverPort = 12;
  EmulatorPort = 13;
  BaudRate = 115200;
  Tax11 = 2200; // kopecks
  Tax12 = 1803;
  CashPay = 10000;

{ TPosCenterCloseEx4Test }

procedure TPosCenterCloseEx4Test.SetUp;
begin
  CoInitialize(nil);
  FEmu := CreateFrEmulator(ekPosCenter);
  FEmu.Start(EmulatorPort, BaudRate);
  Sleep(200);

  FContext := TDriverContext.Create;
  FContext.Parameters.ConnectionType := 0;
  FContext.Parameters.PortNumber := DriverPort;
  FContext.Parameters.BaudRate := BaudRate;
  FContext.Parameters.ByteTimeout := 1000;
  FContext.Parameters.MaxRetryCount := 3;
  FContext.Parameters.UsrPassword := 1;
  FContext.Parameters.SysPassword := 30;
  FContext.Parameters.PrinterProtocol := 0;
  FContext.Parameters.SearchByPortEnabled := False;
  FContext.Parameters.SearchByBaudRateEnabled := False;
  FContext.Parameters.OpenReceiptEnabled := True;
  FContext.Parameters.DriverType := DriverTypeShtrihDriver;
  // Do not force ModelID: PosCenter 5.21 may reject OpenCheck/ExchangeBytes
  // for some synthetic ModelID values ("command not supported by driver", -70).
  FContext.Parameters.ModelID := -1;
  FContext.Logger.Enabled := True;
end;

procedure TPosCenterCloseEx4Test.TearDown;
begin
  FContext.Free;
  FContext := nil;
  if FEmu <> nil then
  begin
    FEmu.Stop;
    FEmu.Free;
    FEmu := nil;
  end;
  CoUninitialize;
end;

function TPosCenterCloseEx4Test.FindCloseLine(const Log: TStrings): string;
var
  i: Integer;
  Line: string;
begin
  Result := '';
  for i := 0 to Log.Count - 1 do
  begin
    Line := UpperCase(Trim(Log[i]));
    if Pos('FF7B', Line) = 1 then
    begin
      Result := Line;
      Exit;
    end;
  end;
end;

function TPosCenterCloseEx4Test.BinAt(const HexPayload: string; Offset, Count: Integer): Int64;
{ Offset is 1-based byte index in binary payload (after FF7B). }
var
  Compact, Chunk: string;
  i: Integer;
  B: Byte;
begin
  Compact := StringReplace(HexPayload, ' ', '', [rfReplaceAll]);
  Result := 0;
  for i := 0 to Count - 1 do
  begin
    Chunk := Copy(Compact, (Offset - 1 + i) * 2 + 1, 2);
    Check(Length(Chunk) = 2, Format('FF7B payload too short at byte %d', [Offset + i]));
    B := StrToInt('$' + Chunk);
    Result := Result + (Int64(B) shl (8 * i));
  end;
end;

procedure TPosCenterCloseEx4Test.CloseReceiptSendsFF7BWithTax11Tax12;
var
  Obj: TFiscalPrinterDriver;
  Device: IFiscalPrinterDevice;
  CloseP: TFSCloseReceiptParams2;
  CloseR: TFSCloseReceiptResult2;
  Line, Payload: string;
  i: Integer;
  Password, Pay0, Discount, T11, T12, TaxSystem: Int64;
  LogPath: string;
  OpenCheckRC, Ex8D, CloseRC: Integer;
begin
  Obj := TFiscalPrinterDriver.Create(FContext);
  Device := Obj;
  try
    Device.Open;
    Device.ClaimDevice(5000);
    Device.OpenPort;
    Device.Connect;
    Device.CapFiscalStorage := True;

    try
      Device.OpenDay;
    except
    end;

    // Prefer a normal open; if PosCenter rejects OpenCheck/8D on emulator,
    // still exercise ReceiptClose2 wire format (FNCloseCheckEx4 → FF7B).
    Obj.Driver.Password := 1;
    Obj.Driver.CheckType := 0;
    OpenCheckRC := Obj.Driver.OpenCheck;
    if OpenCheckRC <> 0 then
    begin
      Obj.Driver.BinaryConversion := 1;
      Obj.Driver.TransferBytes := '8D0100000000';
      Ex8D := Obj.Driver.ExchangeBytes;
    end else
      Ex8D := 0;

    FillChar(CloseP, SizeOf(CloseP), 0);
    FillChar(CloseR, SizeOf(CloseR), 0);
    CloseP.Payments[0] := CashPay;
    for i := 1 to High(CloseP.Payments) do
      CloseP.Payments[i] := 0;
    CloseP.TaxAmount[11] := Tax11;
    CloseP.TaxAmount[12] := Tax12;
    CloseP.TaxSystem := 1;
    CloseP.Text := '';

    CloseRC := Device.ReceiptClose2(CloseP, CloseR);
    CheckEquals(0, CloseRC, Format('ReceiptClose2 rc=%d desc=%s',
      [CloseRC, Obj.Driver.ResultCodeDescription]));

    Device.ClosePort;
    Device.ReleaseDevice;
    Device.Close;
  finally
    Device := nil;
    Obj := nil;
  end;

  LogPath := ExtractFilePath(ParamStr(0)) + 'poscenter_close_ex4.tx';
  FEmu.GetCommandLogLines.SaveToFile(LogPath);

  Line := FindCloseLine(FEmu.GetCommandLogLines);
  Check(Line <> '', 'Expected FF7B close command in TX log (saved ' + LogPath + ')');

  // "FF7B <hex payload...>"
  Payload := Trim(Copy(Line, 5, MaxInt));
  Password := BinAt(Payload, 1, 4);
  Pay0 := BinAt(Payload, 5, 5);
  Discount := BinAt(Payload, 85, 1);
  T11 := BinAt(Payload, 136, 5);
  T12 := BinAt(Payload, 141, 5);
  TaxSystem := BinAt(Payload, 146, 1);

  CheckEquals(1, Password, 'Password');
  CheckEquals(CashPay, Pay0, 'Summ1/cash');
  CheckEquals(0, Discount, 'RoundingSumm');
  CheckEquals(Tax11, T11, 'TaxValue11 (VAT 22%)');
  CheckEquals(Tax12, T12, 'TaxValue12 (VAT 22/122)');
  CheckEquals(1, TaxSystem, 'TaxType/SNO');
end;

initialization
  RegisterTest('', TPosCenterCloseEx4Test.Suite);

end.
