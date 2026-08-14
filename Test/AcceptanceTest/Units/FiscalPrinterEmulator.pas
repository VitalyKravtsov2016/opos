unit FiscalPrinterEmulator;

{ Serial fiscal printer emulators (Protocol 1) for acceptance tests.
  Transport/framing is shared; model-specific command sets live in subclasses
  (close receipt codes, F7 layout, FC model id, serial tables, etc.). }

interface

uses
  // VCL
  Windows, Classes, SysUtils, SyncObjs,
  // This
  StringUtils;

type
  TFrEmulatorKind = (
    ekShtrih,       // Internal / generic SHTRIH-M
    ekPosCenter,    // PosCenter DrvKKT — close Ex4 = FF7B
    ekTorgBalance,  // TorgBalance DrvFR5 — close Ex4 = FF78
    ekRRElectro     // RR-Electro KKTDrv
  );

  { TFiscalPrinterEmulator — Protocol 1 base (default = SHTRIH-M profile) }

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
    procedure LogCommand(CommandCode: Integer; const Payload: AnsiString);
    procedure HandleSession;
    function ThreadProc: DWORD;
  protected
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

    function BuildAnswer(CommandCode: Integer; const Body: AnsiString): AnsiString;
    function AnswerCloseReceipt(CommandCode: Integer): AnsiString;
    function IsCharTableField(Table, Field: Integer): Boolean; virtual;
    function ReadTableValue(Table, Row, Field: Integer): AnsiString; virtual;

    { Model profile }
    function GetModelID: Byte; virtual;
    function GetDeviceName: AnsiString; virtual;
    function GetSerialNumber: AnsiString; virtual;
    function BuildF7Flags: Int64; virtual;
    function BuildF7Body: AnsiString; virtual;
    function IsCloseReceiptCommand(CommandCode: Integer): Boolean; virtual;
    function GetEmulatorKind: TFrEmulatorKind; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Start(APortNumber: Integer; ABaudRate: Integer = 115200);
    procedure Stop;

    procedure ClearLog;
    function GetCommandLog: string;
    function GetCommandLogLines: TStrings;

    property PortNumber: Integer read FPortNumber;
    property EmulatorKind: TFrEmulatorKind read GetEmulatorKind;
    function IsRunning: Boolean;
  end;

  { Internal / generic SHTRIH-M: FF45 / FF76 }

  TShtrihFrEmulator = class(TFiscalPrinterEmulator)
  protected
    function GetEmulatorKind: TFrEmulatorKind; override;
    function IsCloseReceiptCommand(CommandCode: Integer): Boolean; override;
    function BuildF7Body: AnsiString; override;
  end;

  { PosCenter DrvKKT: FF45 / FF76 / FF7B (Ex4), model 247, extended F7 + license bits }

  TPosCenterFrEmulator = class(TFiscalPrinterEmulator)
  protected
    function GetEmulatorKind: TFrEmulatorKind; override;
    function GetModelID: Byte; override;
    function GetDeviceName: AnsiString; override;
    function BuildF7Body: AnsiString; override;
    function IsCloseReceiptCommand(CommandCode: Integer): Boolean; override;
    function IsCharTableField(Table, Field: Integer): Boolean; override;
  end;

  { TorgBalance DrvFR5: FF45 / FF76 / FF78 (Ex4 on wire) }

  TTorgBalanceFrEmulator = class(TFiscalPrinterEmulator)
  protected
    function GetEmulatorKind: TFrEmulatorKind; override;
    function IsCloseReceiptCommand(CommandCode: Integer): Boolean; override;
  end;

  { RR-Electro KKTDrv: model 3 = РР-01Ф (см. Номера моделей ККТ) }

  TRRElectroFrEmulator = class(TFiscalPrinterEmulator)
  protected
    function GetEmulatorKind: TFrEmulatorKind; override;
    function GetModelID: Byte; override;
    function GetDeviceName: AnsiString; override;
    function IsCloseReceiptCommand(CommandCode: Integer): Boolean; override;
  end;

function EmulatorThreadFunc(Param: Pointer): DWORD; stdcall;
function CreateFrEmulator(Kind: TFrEmulatorKind): TFiscalPrinterEmulator;
function FrEmulatorKindToName(Kind: TFrEmulatorKind): string;

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

function FrEmulatorKindToName(Kind: TFrEmulatorKind): string;
begin
  case Kind of
    ekPosCenter:   Result := 'PosCenter';
    ekTorgBalance: Result := 'TorgBalance';
    ekRRElectro:   Result := 'RR-Electro';
  else
    Result := 'SHTRIH-M';
  end;
end;

function CreateFrEmulator(Kind: TFrEmulatorKind): TFiscalPrinterEmulator;
begin
  case Kind of
    ekPosCenter:   Result := TPosCenterFrEmulator.Create;
    ekTorgBalance: Result := TTorgBalanceFrEmulator.Create;
    ekRRElectro:   Result := TRRElectroFrEmulator.Create;
  else
    Result := TShtrihFrEmulator.Create;
  end;
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
  FFlags := $0002; // receipt paper present
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

function TFiscalPrinterEmulator.GetEmulatorKind: TFrEmulatorKind;
begin
  Result := ekShtrih;
end;

function TFiscalPrinterEmulator.GetModelID: Byte;
begin
  Result := 27; // FN-capable
end;

function TFiscalPrinterEmulator.GetDeviceName: AnsiString;
begin
  Result := 'SHTRIH-M FR';
end;

function TFiscalPrinterEmulator.GetSerialNumber: AnsiString;
begin
  Result := '0212280008053991';
end;

function TFiscalPrinterEmulator.BuildF7Flags: Int64;
begin
  // Protocol F7 type=1, bits 57/58 (PosCenter v1.23 / RR A.2.0):
  // 57 — commercial license valid
  // 58 — legislative license valid
  // Also enable common FN capabilities used by DrvFR/KKTDrv.
  Result :=
    (Int64(1) shl 22) or  // CapNonfiscalDoc
    (Int64(1) shl 23) or  // CapCashCore
    (Int64(1) shl 43) or  // CapFN
    (Int64(1) shl 47) or  // CapFN1.1
    (Int64(1) shl 54) or  // CapVAT22
    (Int64(1) shl 57) or  // commercial license valid
    (Int64(1) shl 58);    // legislative license valid
end;

function TFiscalPrinterEmulator.BuildF7Body: AnsiString;
begin
  // F7 type=1 body: 8-byte flags + fonts/passwords/graphics
  Result :=
    IntToBin(BuildF7Flags, 8) +
    #42 + #42 +
    #0 +
    #12 + #12 +
    #12 + #12 +
    IntToBin(0, 4) +
    IntToBin(30, 4) +
    #0 +
    #1 +
    IntToBin(64, 2) +
    #40 +
    #64 +
    IntToBin(200, 2);
end;

function TFiscalPrinterEmulator.IsCloseReceiptCommand(CommandCode: Integer): Boolean;
begin
  Result := (CommandCode = $FF45) or (CommandCode = $FF76);
end;

function TFiscalPrinterEmulator.IsCharTableField(Table, Field: Integer): Boolean;
begin
  Result := (Table = 0) or ((Table = 6) and (Field = 2));
end;

function TFiscalPrinterEmulator.ReadTableValue(Table, Row, Field: Integer): AnsiString;
begin
  if Table = 0 then
    Result := Copy(GetSerialNumber + StringOfChar(' ', 40), 1, 40)
  else if IsCharTableField(Table, Field) then
    Result := Copy('STRING' + StringOfChar(' ', 40), 1, 40)
  else
    Result := #0#0#0#0;
end;

function TFiscalPrinterEmulator.AnswerCloseReceipt(CommandCode: Integer): AnsiString;
var
  Body: AnsiString;
begin
  FReceiptOpened := False;
  FMode := MODE_24NOTOVER;
  Inc(FDocNumber);
  Inc(FFSDocNumber);
  Body := #0 + IntToBin(0, 5) + IntToBin(FFSDocNumber, 4) + IntToBin(1, 4);
  Result := BuildAnswer(CommandCode, Body);
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
  Result := (FThread <> 0) and (not FStop);
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
  else if CommandCode >= $FE00 then
    // PosCenter DrvFR treats answer as: FE <error> <data...>
    // (subcommand is not echoed; echoing it makes error=0xE7=231).
    Result := #$FE + Body
  else
    Result := AnsiChar(CommandCode) + Body;
end;

procedure TFiscalPrinterEmulator.LogCommand(CommandCode: Integer;
  const Payload: AnsiString);
var
  Line: string;
begin
  if CommandCode = $10 then
    Exit;

  if CommandCode >= $FF00 then
    Line := Format('FF%.2X %s', [CommandCode and $FF, StrToHex(Payload)])
  else if CommandCode >= $FE00 then
    Line := Format('FE%.2X %s', [CommandCode and $FF, StrToHex(Payload)])
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
  Table, Field: Integer;
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
  if Ord(Payload[1]) = $FE then
  begin
    // Extended FE-prefix commands (license etc.): FE <sub> <data...>
    if Length(Payload) < 2 then
      Exit;
    Code := $FE00 + Ord(Payload[2]);
    Data := Copy(Payload, 3, MaxInt);
  end else
  begin
    Code := Ord(Payload[1]);
    Data := Copy(Payload, 2, MaxInt);
  end;

  LogCommand(Code, Data);

  if IsCloseReceiptCommand(Code) then
  begin
    Result := AnswerCloseReceipt(Code);
    Exit;
  end;

  case Code of
    $10:
      begin
        Body := #0 + AnsiChar(FOperator) +
          IntToBin(FFlags, 2) +
          AnsiChar(FMode) +
          AnsiChar(FSubMode) +
          #0 + #100 + #220 + #0 + #0 + #0 + #0#0#0;
        Result := BuildAnswer(Code, Body);
      end;

    $11:
      begin
        NowDT := Now;
        DecodeDate(NowDT, Y, M, D);
        DecodeTime(NowDT, H, N, S, MS);
        Body := #0 + AnsiChar(FOperator) +
          '1' + '0' +
          IntToBin(100, 2) +
          AnsiChar(D) + AnsiChar(M) + AnsiChar(Y mod 100) +
          #1 +
          IntToBin(FDocNumber, 2) +
          IntToBin(FFlags, 2) +
          AnsiChar(FMode) +
          AnsiChar(FSubMode) +
          #1 +
          '1' + '0' +
          IntToBin(1, 2) +
          AnsiChar(D) + AnsiChar(M) + AnsiChar(Y mod 100) +
          AnsiChar(D) + AnsiChar(M) + AnsiChar(Y mod 100) +
          AnsiChar(H) + AnsiChar(N) + AnsiChar(S) +
          // FMFlags: bit0 FM1, bit2 LicenseEntered, bit6 DayOpened/IsFMSessionOpen
          #$45 +
          IntToBin(123456, 4) +
          IntToBin(FDayNumber, 2) +
          IntToBin(2000, 2) +
          #1 + #15 +
          #0#0#0#0#0#0 +
          // With F7 bit23 (CashCore) PosCenter expects 50-byte 11h answer:
          // +2 bytes = high word of 6-byte serial.
          #0#0;
        Result := BuildAnswer(Code, Body);
      end;

    $62:
      begin
        Body := #0 + AnsiChar(FOperator) +
          IntToBin(0, 8) +
          StringOfChar(#$FF, 6) +
          StringOfChar(#$FF, 6) +
          StringOfChar(#$FF, 6);
        Result := BuildAnswer(Code, Body);
      end;

    $FC:
      begin
        Body := #0 +
          #0 + #0 +
          #1 + #4 +
          AnsiChar(GetModelID) +
          #0 +
          GetDeviceName;
        Result := BuildAnswer(Code, Body);
      end;

    $F7:
      begin
        Body := #0 + BuildF7Body;
        Result := BuildAnswer(Code, Body);
      end;

    $8D:
      begin
        FReceiptOpened := True;
        FReceiptTotal := 0;
        FMode := MODE_REC;
        if Length(Data) >= 5 then
        begin
          case Ord(Data[5]) of
            0: FMode := $08;
            1: FMode := $18;
            2: FMode := $28;
            3: FMode := $38;
          end;
        end;
        Body := #0 + AnsiChar(FOperator);
        Result := BuildAnswer(Code, Body);
      end;

    $85:
      begin
        FReceiptOpened := False;
        FMode := MODE_24NOTOVER;
        Inc(FDocNumber);
        Body := #0 + AnsiChar(FOperator) + IntToBin(0, 5);
        Result := BuildAnswer(Code, Body);
      end;

    $89:
      begin
        Body := #0 + AnsiChar(FOperator) + IntToBin(FReceiptTotal, 5);
        Result := BuildAnswer(Code, Body);
      end;

    $E0:
      begin
        FMode := MODE_24NOTOVER;
        Body := #0 + AnsiChar(FOperator);
        Result := BuildAnswer(Code, Body);
      end;

    $2D:
      begin
        Body := #0 +
          Copy('TABLE' + StringOfChar(' ', 40), 1, 40) +
          IntToBin(16, 2) +
          #10;
        Result := BuildAnswer(Code, Body);
      end;

    $2E:
      begin
        Table := 0;
        Field := 1;
        if Length(Data) >= 6 then
        begin
          Table := Ord(Data[5]);
          Field := Ord(Data[6]);
        end;
        if IsCharTableField(Table, Field) then
          Body := #0 + Copy('NAME' + StringOfChar(' ', 40), 1, 40) + #1 + #40
        else
          Body := #0 + Copy('FIELD' + StringOfChar(' ', 40), 1, 40) +
            #0 + #4 + IntToBin(0, 4) + IntToBin($7FFFFFFF, 4);
        Result := BuildAnswer(Code, Body);
      end;

    $1F:
      begin
        Table := 0;
        Field := 1;
        if Length(Data) >= 8 then
        begin
          Table := Ord(Data[5]);
          Field := Ord(Data[8]);
        end;
        Body := #0 + ReadTableValue(Table, 1, Field);
        Result := BuildAnswer(Code, Body);
      end;

    $26:
      begin
        Body := #0 + IntToBin(42, 2) + #12 + #24 + #1;
        Result := BuildAnswer(Code, Body);
      end;

    $FF01:
      begin
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

    $FF46:
      begin
        if Length(Data) >= 21 then
          FReceiptTotal := FReceiptTotal + BinToInt(Data, 17, 5);
        Body := #0;
        Result := BuildAnswer(Code, Body);
      end;

    $FF61:
      begin
        Body := #0 + #0 + #0 + #0 + #0;
        Result := BuildAnswer(Code, Body);
      end;

    $FF67:
      begin
        if Length(Data) >= 5 then
        begin
          MarkLen := Ord(Data[5]);
          FLastMarkCode := Copy(Data, 6, MarkLen);
        end;
        Body := #0 + IntToBin(1, 2) + #0 + #0 + #0 + #0 + #0;
        Result := BuildAnswer(Code, Body);
      end;

    $FF69:
      begin
        Body := #0;
        Result := BuildAnswer(Code, Body);
      end;

    // FE-prefix license/feature queries (see FREmul EmulFECommands;
    // PosCenter answer framing: FE <error> <data>, without subcode echo).
    $FEE6:
      begin
        // WriteFeatureLicenses: accept and ACK
        Body := #0;
        Result := BuildAnswer(Code, Body);
      end;
    $FEE7:
      begin
        // ReadFeatureLicenses: error + 64 data bytes
        Body := #0 + StringOfChar(#0, 64);
        Result := BuildAnswer(Code, Body);
      end;
    $FEEF:
      begin
        Body := #0 + StringOfChar(#0, 60);
        Result := BuildAnswer(Code, Body);
      end;
    $FEEC:
      begin
        Body := #0 + IntToBin(153, 4);
        Result := BuildAnswer(Code, Body);
      end;
    $FEF4:
      begin
        Body := #0 +
          IntToBin(0, 8) + IntToBin(0, 8) + IntToBin(0, 8) + IntToBin(0, 8);
        Result := BuildAnswer(Code, Body);
      end;

  else
    begin
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
          WritePort(FPendingAnswer);
          FPendingAnswer := '';
        end;
      end;
  else
    // ignore noise
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

{ TShtrihFrEmulator }

function TShtrihFrEmulator.GetEmulatorKind: TFrEmulatorKind;
begin
  Result := ekShtrih;
end;

function TShtrihFrEmulator.IsCloseReceiptCommand(CommandCode: Integer): Boolean;
begin
  Result := (CommandCode = $FF45) or (CommandCode = $FF76);
end;

function TShtrihFrEmulator.BuildF7Body: AnsiString;
begin
  Result := inherited BuildF7Body;
end;

{ TPosCenterFrEmulator }

function TPosCenterFrEmulator.GetEmulatorKind: TFrEmulatorKind;
begin
  Result := ekPosCenter;
end;

function TPosCenterFrEmulator.GetModelID: Byte;
begin
  // ModelID=0 matches PosCenter DrvFR licensed model name (ШТРИХ-M-01Ф).
  Result := 0;
end;

function TPosCenterFrEmulator.GetDeviceName: AnsiString;
begin
  // cp1251: ШТРИХ-M-01Ф + padding (as in DrvKKT.log)
  Result := #$D8#$D2#$D0#$C8#$D5'-M-01'#$D4'         ';
end;

function TPosCenterFrEmulator.BuildF7Body: AnsiString;
var
  Flags: Int64;
begin
  // Real PosCenter F7 dump (5A A0 40 03 20 EC C1 01 ...) plus:
  // bit23 CapCashCore, bit57 commercial license, bit58 legislative license.
  Flags := $01C1EC200340A05A;
  Flags := Flags or
    (Int64(1) shl 23) or
    (Int64(1) shl 57) or
    (Int64(1) shl 58);
  Result :=
    IntToBin(Flags, 8) +
    #$0C#$18#$01#$0C#$10 +
    #$00#$00#$00#$00#$00 +
    #$00#$1E#$00#$00#$00 +
    #$00#$06#$FF#$00#$48#$40#$B6#$03 +
    #$12#$13#$18#$11#$11#$19#$11 +
    #$47#$30#$30#$33#$02#$01#$01#$00;
end;

function TPosCenterFrEmulator.IsCloseReceiptCommand(CommandCode: Integer): Boolean;
begin
  // Protocol v1.23: FF45 / FF76 / FF7B (Ex4)
  Result := (CommandCode = $FF45) or (CommandCode = $FF76) or
    (CommandCode = $FF7B);
end;

function TPosCenterFrEmulator.IsCharTableField(Table, Field: Integer): Boolean;
begin
  Result := inherited IsCharTableField(Table, Field) or (Table = 18);
end;

{ TTorgBalanceFrEmulator }

function TTorgBalanceFrEmulator.GetEmulatorKind: TFrEmulatorKind;
begin
  Result := ekTorgBalance;
end;

function TTorgBalanceFrEmulator.IsCloseReceiptCommand(CommandCode: Integer): Boolean;
begin
  // Observed on wire: Ex4 = FF78 (not PosCenter FF7B)
  Result := (CommandCode = $FF45) or (CommandCode = $FF76) or
    (CommandCode = $FF78);
end;

{ TRRElectroFrEmulator }

function TRRElectroFrEmulator.GetEmulatorKind: TFrEmulatorKind;
begin
  Result := ekRRElectro;
end;

function TRRElectroFrEmulator.GetModelID: Byte;
begin
  // Код модели ККТ 0003 = РР-01Ф
  // (Номера моделей_только_ККТ_271125.docx)
  Result := 3;
end;

function TRRElectroFrEmulator.GetDeviceName: AnsiString;
begin
  // cp1251: РР-01Ф + padding
  Result := #$D0#$D0'-01'#$D4'              ';
end;

function TRRElectroFrEmulator.IsCloseReceiptCommand(CommandCode: Integer): Boolean;
begin
  Result := (CommandCode = $FF45) or (CommandCode = $FF76);
end;

end.
