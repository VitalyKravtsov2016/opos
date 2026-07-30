unit FiscalPrinterEmulator;

{ Serial fiscal printer emulator (Protocol 1) for acceptance tests.
  Listens on a COM port (one side of Com0Com) and answers Shtrih/FS commands. }

interface

uses
  // VCL
  Windows, Classes, SysUtils, SyncObjs,
  // This
  StringUtils;

type
  { TFiscalPrinterEmulator }

  TFiscalPrinterEmulator = class
  private
    FPortNumber: Integer;
    FBaudRate: Integer;
    FHandle: THandle;
    FThread: THandle;
    FThreadId: DWORD;
    FStop: Boolean;
    FLock: TCriticalSection;
    FCommands: TStringList;
    FPendingAnswer: AnsiString;
    FMode: Byte;
    FSubMode: Byte;
    FFlags: Word;
    FDocNumber: Word;
    FDayNumber: Word;
    FOperator: Byte;
    FReceiptOpened: Boolean;
    FReceiptTotal: Int64;
    FLastMarkCode: AnsiString;
    FFSDocNumber: Integer;
    FTimeoutMs: DWORD;

    procedure OpenPort;
    procedure ClosePort;
    procedure PurgePort;
    procedure WritePort(const Data: AnsiString);
    function ReadByte(var B: Byte; TimeoutMs: DWORD): Boolean;
    function ReadBytes(Count: Integer; var Data: AnsiString; TimeoutMs: DWORD): Boolean;
    function EncodeFrame(const Data: AnsiString): AnsiString;
    function FrameCRC(const LenAndData: AnsiString): Byte;
    function ProcessPayload(const Payload: AnsiString): AnsiString;
    function BuildAnswer(CommandCode: Integer; const Body: AnsiString): AnsiString;
    procedure LogCommand(CommandCode: Integer; const Payload: AnsiString);
    procedure HandleSession;
    function ThreadProc: DWORD;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start(APortNumber: Integer; ABaudRate: Integer = 115200);
    procedure Stop;

    procedure ClearLog;
    function GetCommandLog: string;
    function GetCommandLogLines: TStrings;

    property PortNumber: Integer read FPortNumber;
    function IsRunning: Boolean;
  end;

function EmulatorThreadFunc(Param: Pointer): DWORD; stdcall;

implementation

const
  STX = $02;
  ENQ = $05;
  ACK = $06;
  NAK = $15;

  MODE_24NOTOVER = $02;
  MODE_CLOSED    = $04;
  MODE_REC       = $08;

function EmulatorThreadFunc(Param: Pointer): DWORD; stdcall;
begin
  Result := TFiscalPrinterEmulator(Param).ThreadProc;
end;

{ TFiscalPrinterEmulator }

constructor TFiscalPrinterEmulator.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FCommands := TStringList.Create;
  FHandle := INVALID_HANDLE_VALUE;
  FThread := 0;
  FMode := MODE_24NOTOVER;
  FSubMode := 0;
  FFlags := $0002; // receipt paper present (typical)
  FDocNumber := 1;
  FDayNumber := 1;
  FOperator := 1;
  FTimeoutMs := 50;
  FFSDocNumber := 1;
end;

destructor TFiscalPrinterEmulator.Destroy;
begin
  Stop;
  FCommands.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TFiscalPrinterEmulator.ClearLog;
begin
  FLock.Enter;
  try
    FCommands.Clear;
  finally
    FLock.Leave;
  end;
end;

function TFiscalPrinterEmulator.GetCommandLog: string;
begin
  FLock.Enter;
  try
    Result := FCommands.Text;
  finally
    FLock.Leave;
  end;
end;

function TFiscalPrinterEmulator.GetCommandLogLines: TStrings;
begin
  Result := FCommands;
end;

function TFiscalPrinterEmulator.IsRunning: Boolean;
begin
  Result := FThread <> 0;
end;

procedure TFiscalPrinterEmulator.OpenPort;
var
  PortName: string;
  DCB: TDCB;
  Touts: TCommTimeouts;
begin
  PortName := Format('\\.\COM%d', [FPortNumber]);
  FHandle := CreateFile(PChar(PortName), GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, 0, 0);
  if FHandle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;

  FillChar(DCB, SizeOf(DCB), 0);
  DCB.DCBlength := SizeOf(DCB);
  if not GetCommState(FHandle, DCB) then
    RaiseLastOSError;
  DCB.BaudRate := FBaudRate;
  DCB.ByteSize := 8;
  DCB.Parity := NOPARITY;
  DCB.StopBits := ONESTOPBIT;
  DCB.Flags := 1; // binary
  if not SetCommState(FHandle, DCB) then
    RaiseLastOSError;

  FillChar(Touts, SizeOf(Touts), 0);
  Touts.ReadIntervalTimeout := MAXDWORD;
  Touts.ReadTotalTimeoutMultiplier := 0;
  Touts.ReadTotalTimeoutConstant := FTimeoutMs;
  Touts.WriteTotalTimeoutMultiplier := 0;
  Touts.WriteTotalTimeoutConstant := 1000;
  if not SetCommTimeouts(FHandle, Touts) then
    RaiseLastOSError;

  PurgePort;
end;

procedure TFiscalPrinterEmulator.ClosePort;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
end;

procedure TFiscalPrinterEmulator.PurgePort;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    PurgeComm(FHandle, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR);
end;

procedure TFiscalPrinterEmulator.WritePort(const Data: AnsiString);
var
  Written: DWORD;
begin
  if (FHandle = INVALID_HANDLE_VALUE) or (Data = '') then
    Exit;
  if not WriteFile(FHandle, Data[1], Length(Data), Written, nil) then
    RaiseLastOSError;
end;

function TFiscalPrinterEmulator.ReadByte(var B: Byte; TimeoutMs: DWORD): Boolean;
var
  Buf: array[0..0] of Byte;
  ReadCount: DWORD;
  Touts: TCommTimeouts;
begin
  Result := False;
  if FHandle = INVALID_HANDLE_VALUE then
    Exit;

  GetCommTimeouts(FHandle, Touts);
  Touts.ReadIntervalTimeout := MAXDWORD;
  Touts.ReadTotalTimeoutMultiplier := 0;
  Touts.ReadTotalTimeoutConstant := TimeoutMs;
  SetCommTimeouts(FHandle, Touts);

  if not ReadFile(FHandle, Buf, 1, ReadCount, nil) then
    Exit;
  if ReadCount = 1 then
  begin
    B := Buf[0];
    Result := True;
  end;
end;

function TFiscalPrinterEmulator.ReadBytes(Count: Integer; var Data: AnsiString;
  TimeoutMs: DWORD): Boolean;
var
  i: Integer;
  B: Byte;
begin
  Data := '';
  Result := False;
  for i := 1 to Count do
  begin
    if not ReadByte(B, TimeoutMs) then
      Exit;
    Data := Data + AnsiChar(B);
  end;
  Result := True;
end;

function TFiscalPrinterEmulator.FrameCRC(const LenAndData: AnsiString): Byte;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(LenAndData) do
    Result := Result xor Ord(LenAndData[i]);
end;

function TFiscalPrinterEmulator.EncodeFrame(const Data: AnsiString): AnsiString;
var
  Body: AnsiString;
begin
  Body := AnsiChar(Length(Data)) + Data;
  Result := AnsiChar(STX) + Body + AnsiChar(FrameCRC(Body));
end;

function TFiscalPrinterEmulator.BuildAnswer(CommandCode: Integer;
  const Body: AnsiString): AnsiString;
begin
  if CommandCode >= $FF00 then
    Result := #$FF + AnsiChar(CommandCode and $FF) + Body
  else
    Result := AnsiChar(CommandCode) + Body;
end;

procedure TFiscalPrinterEmulator.LogCommand(CommandCode: Integer;
  const Payload: AnsiString);
var
  Line: string;
begin
  // Skip only short status poll from comparison log (keep long status for diag)
  if CommandCode = $10 then
    Exit;

  if CommandCode >= $FF00 then
    Line := Format('FF%.2X %s', [CommandCode and $FF, StrToHex(Payload)])
  else
    Line := Format('%.2X %s', [CommandCode, StrToHex(Payload)]);

  FLock.Enter;
  try
    FCommands.Add(Trim(Line));
  finally
    FLock.Leave;
  end;
end;

function TFiscalPrinterEmulator.ProcessPayload(const Payload: AnsiString): AnsiString;
var
  Code: Integer;
  Data: AnsiString;
  Body: AnsiString;
  MarkLen: Integer;
  NowDT: TDateTime;
  Y, M, D, H, N, S, MS: Word;
begin
  Result := '';
  if Length(Payload) < 1 then
    Exit;

  if Ord(Payload[1]) = $FF then
  begin
    if Length(Payload) < 2 then
      Exit;
    Code := $FF00 + Ord(Payload[2]);
    Data := Copy(Payload, 3, MaxInt);
  end else
  begin
    Code := Ord(Payload[1]);
    Data := Copy(Payload, 2, MaxInt);
  end;

  LogCommand(Code, Data);

  case Code of
    $10: // Short status (answer LEN=16: cmd+result+14 fields)
      begin
        Body := #0 + AnsiChar(FOperator) +
          IntToBin(FFlags, 2) +
          AnsiChar(FMode) +
          AnsiChar(FSubMode) +
          #0 +              // ops lo
          #100 +            // battery
          #220 +            // power
          #0 +              // FM error
          #0 +              // EKLZ error
          #0 +              // ops hi
          #0#0#0;           // reserved
        Result := BuildAnswer(Code, Body);
      end;

    $11: // Long status (result + 47 bytes fields ≈ 48 total)
      begin
        NowDT := Now;
        DecodeDate(NowDT, Y, M, D);
        DecodeTime(NowDT, H, N, S, MS);
        Body := #0 + AnsiChar(FOperator) +
          '1' + '0' +                     // firmware version hi/lo
          IntToBin(100, 2) +              // build
          AnsiChar(D) + AnsiChar(M) + AnsiChar(Y mod 100) +
          #1 +                            // logical number
          IntToBin(FDocNumber, 2) +
          IntToBin(FFlags, 2) +
          AnsiChar(FMode) +
          AnsiChar(FSubMode) +
          #1 +                            // port
          '1' + '0' +                     // FM version
          IntToBin(1, 2) +
          AnsiChar(D) + AnsiChar(M) + AnsiChar(Y mod 100) +
          AnsiChar(D) + AnsiChar(M) + AnsiChar(Y mod 100) +
          AnsiChar(H) + AnsiChar(N) + AnsiChar(S) +
          #$40 +                          // FM flags: day opened
          IntToBin(123456, 4) +           // serial
          IntToBin(FDayNumber, 2) +
          IntToBin(2000, 2) +             // free records
          #1 +                            // last fisc number (1 byte)
          #15 +                           // free fisc records (1 byte)
          #0#0#0#0#0#0;                   // INN
        Result := BuildAnswer(Code, Body);
      end;

    $62: // FM totals
      begin
        Body := #0 + AnsiChar(FOperator) +
          IntToBin(0, 8) +
          StringOfChar(#$FF, 6) +
          StringOfChar(#$FF, 6) +
          StringOfChar(#$FF, 6);
        Result := BuildAnswer(Code, Body);
      end;

    $FC: // Device metrics
      begin
        Body := #0 +
          #0 + #0 +       // type/subtype
          #1 + #4 +       // protocol 1.4
          #27 +           // model with FN (IsModelType2)
          #0 +            // language RU
          'SHTRIH-M FR';
        Result := BuildAnswer(Code, Body);
      end;

    $F7: // Read printer parameters / flags (F7 01)
      begin
        // Flags(8) + Font1 + Font2 + GraphStart + InnDigits + RnmDigits +
        // LongRnm + LongSerial + DefTaxPwd(4) + DefSysPwd(4) + BT + TaxField +
        // MaxCmdLen(2) + GraphWidth + Graph512Width + Graph512Height(2)
        Body := #0 +
          IntToBin(0, 8) +  // flags
          #42 + #42 +       // font widths
          #0 +              // graphics start line
          #12 + #12 +       // INN/RNM digits
          #12 + #12 +       // long RNM/serial digits
          IntToBin(0, 4) +  // def tax password
          IntToBin(30, 4) + // def sys password
          #0 +              // bluetooth table
          #1 +              // tax field number
          IntToBin(64, 2) + // max command length
          #40 +             // graphics width bytes
          #64 +             // graphics 512 width
          IntToBin(200, 2); // graphics 512 height
        Result := BuildAnswer(Code, Body);
      end;

    $8D: // Open receipt
      begin
        FReceiptOpened := True;
        FReceiptTotal := 0;
        FMode := MODE_REC; // sale receipt
        if Length(Data) >= 5 then
        begin
          case Ord(Data[5]) of
            0: FMode := $08; // sell
            1: FMode := $18; // buy
            2: FMode := $28; // ret sell
            3: FMode := $38; // ret buy
          end;
        end;
        Body := #0 + AnsiChar(FOperator);
        Result := BuildAnswer(Code, Body);
      end;

    $85: // Close receipt (classic)
      begin
        FReceiptOpened := False;
        FMode := MODE_24NOTOVER;
        Inc(FDocNumber);
        Body := #0 + AnsiChar(FOperator) + IntToBin(0, 5);
        Result := BuildAnswer(Code, Body);
      end;

    $89: // Subtotal
      begin
        Body := #0 + AnsiChar(FOperator) + IntToBin(FReceiptTotal, 5);
        Result := BuildAnswer(Code, Body);
      end;

    $E0: // Open session / day
      begin
        FMode := MODE_24NOTOVER;
        Body := #0 + AnsiChar(FOperator);
        Result := BuildAnswer(Code, Body);
      end;

    $2D: // Table structure
      begin
        Body := #0 +
          Copy('TABLE' + StringOfChar(' ', 40), 1, 40) +
          IntToBin(16, 2) +
          #10;
        Result := BuildAnswer(Code, Body);
      end;

    $2E: // Field structure (type: 0=BIN, 1=CHAR)
      begin
        // Table 0 (DrvFR model probe) and tax name → CHAR; else BIN
        if (Length(Data) >= 6) and (
             (Ord(Data[5]) = 0) or
             ((Ord(Data[5]) = 6) and (Ord(Data[6]) = 2))) then
        begin
          Body := #0 +
            Copy('NAME' + StringOfChar(' ', 40), 1, 40) +
            #1 + #40;
        end else
        begin
          Body := #0 +
            Copy('FIELD' + StringOfChar(' ', 40), 1, 40) +
            #0 + #4 +
            IntToBin(0, 4) +
            IntToBin($7FFFFFFF, 4);
        end;
        Result := BuildAnswer(Code, Body);
      end;

    $1F: // Read table value
      begin
        if (Length(Data) >= 8) and (
             (Ord(Data[5]) = 0) or
             ((Ord(Data[5]) = 6) and (Ord(Data[8]) = 2))) then
          Body := #0 + Copy('RETAIL-01F' + StringOfChar(' ', 40), 1, 40)
        else
          Body := #0 + #0#0#0#0;
        Result := BuildAnswer(Code, Body);
      end;

    $26: // Font metrics (no operator; ends with FontCount)
      begin
        Body := #0 +
          IntToBin(42, 2) +  // print width
          #12 +              // char width
          #24 +              // char height
          #1;                // font count
        Result := BuildAnswer(Code, Body);
      end;

    $FF01: // FS state (FSReadState layout, 30 bytes after result)
      begin
        // State Document DocReceived DayOpened WarningFlags
        // Date(YMD) Time(HM) FSNumber(16) DocNumber(4)
        NowDT := Now;
        DecodeDate(NowDT, Y, M, D);
        DecodeTime(NowDT, H, N, S, MS);
        Body := #0 +
          #1 + #0 + #0 + #1 + #0 +
          AnsiChar(Y mod 100) + AnsiChar(M) + AnsiChar(D) +
          AnsiChar(H) + AnsiChar(N) +
          '9999078900012345' +
          IntToBin(FFSDocNumber, 4);
        Result := BuildAnswer(Code, Body);
      end;

    $FF45, $FF76: // FS close receipt
      begin
        FReceiptOpened := False;
        FMode := MODE_24NOTOVER;
        Inc(FDocNumber);
        Inc(FFSDocNumber);
        // Result + Change(5) + FSDocNum(4) + FiscalSign(4)
        Body := #0 + IntToBin(0, 5) + IntToBin(FFSDocNumber, 4) + IntToBin(1, 4);
        Result := BuildAnswer(Code, Body);
      end;

    $FF46: // FS sale V2
      begin
        // pwd(4)+type(1)+qty(6)+price(5)+total(5)...
        if Length(Data) >= 21 then
          FReceiptTotal := FReceiptTotal + BinToInt(Data, 17, 5);
        Body := #0;
        Result := BuildAnswer(Code, Body);
      end;

    $FF61: // Check item code
      begin
        // LocalCheckResult, LocalCheckError, SymbolicType, DataLength(+optional)
        Body := #0 + #0 + #0 + #0 + #0;
        Result := BuildAnswer(Code, Body);
      end;

    $FF67: // Bind marking code
      begin
        if Length(Data) >= 5 then
        begin
          MarkLen := Ord(Data[5]);
          FLastMarkCode := Copy(Data, 6, MarkLen);
        end;
        // ItemCode(2) + CodeType(1) + optional check block
        Body := #0 + IntToBin(1, 2) + #0 + #0 + #0 + #0 + #0;
        Result := BuildAnswer(Code, Body);
      end;

    $FF69: // Accept / clear MC
      begin
        Body := #0;
        Result := BuildAnswer(Code, Body);
      end;

  else
    begin
      // Unknown command: success + padding (no operator — many cmds lack it)
      Body := #0 + StringOfChar(#0, 128);
      Result := BuildAnswer(Code, Body);
    end;
  end;
end;

procedure TFiscalPrinterEmulator.HandleSession;
var
  B: Byte;
  DataLen: Byte;
  FrameData: AnsiString;
  CRC: Byte;
  Payload: AnsiString;
  Answer: AnsiString;
  ExpectedCRC: Byte;
begin
  if not ReadByte(B, FTimeoutMs) then
    Exit;

  case B of
    ENQ:
      begin
        if FPendingAnswer <> '' then
        begin
          WritePort(AnsiChar(ACK));
          WritePort(FPendingAnswer);
          FPendingAnswer := '';
        end else
          WritePort(AnsiChar(NAK));
      end;

    STX:
      begin
        if not ReadByte(DataLen, 500) then
          Exit;
        if not ReadBytes(DataLen + 1, FrameData, 1000) then
          Exit;
        if Length(FrameData) < DataLen + 1 then
          Exit;

        CRC := Ord(FrameData[Length(FrameData)]);
        Payload := Copy(FrameData, 1, DataLen);
        ExpectedCRC := FrameCRC(AnsiChar(DataLen) + Payload);
        if CRC <> ExpectedCRC then
        begin
          WritePort(AnsiChar(NAK));
          Exit;
        end;

        WritePort(AnsiChar(ACK));
        Answer := ProcessPayload(Payload);
        if Answer <> '' then
        begin
          FPendingAnswer := EncodeFrame(Answer);
          // Host usually reads answer immediately after ACK of command
          WritePort(FPendingAnswer);
          FPendingAnswer := '';
        end;
      end;
  else
    // ignore noise / $FF
  end;
end;

function TFiscalPrinterEmulator.ThreadProc: DWORD;
begin
  Result := 0;
  try
    while not FStop do
    begin
      try
        HandleSession;
      except
        // keep running; host may reopen port
        Sleep(10);
      end;
    end;
  finally
    ClosePort;
  end;
end;

procedure TFiscalPrinterEmulator.Start(APortNumber, ABaudRate: Integer);
begin
  Stop;
  FPortNumber := APortNumber;
  FBaudRate := ABaudRate;
  FStop := False;
  FPendingAnswer := '';
  ClearLog;
  OpenPort;
  FThread := CreateThread(nil, 0, @EmulatorThreadFunc, Self, 0, FThreadId);
  if FThread = 0 then
  begin
    ClosePort;
    RaiseLastOSError;
  end;
end;

procedure TFiscalPrinterEmulator.Stop;
var
  Code: DWORD;
begin
  FStop := True;
  if FThread <> 0 then
  begin
    WaitForSingleObject(FThread, 3000);
    GetExitCodeThread(FThread, Code);
    CloseHandle(FThread);
    FThread := 0;
  end;
  ClosePort;
end;

end.
