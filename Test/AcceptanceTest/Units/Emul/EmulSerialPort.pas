unit EmulSerialPort;

interface

uses
  Windows, SysUtils, Classes;

type
  TEmulSerialPort = class
  private
    FHandle: THandle;
    FPortName: string;
    FBaudRate: Integer;
    FTimeout: Integer;
    procedure ApplyCommState;
    procedure CheckOpened;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Open(const APortName: string; ABaudRate: Integer);
    procedure Close;
    function Opened: Boolean;
    procedure Purge;
    procedure WriteData(const Data: AnsiString);
    function ReadChar(var C: AnsiChar): Boolean;
    function ReadCharTimeout(var C: AnsiChar; ATimeout: Integer): Boolean;
    function ReadExact(Count: Integer; ATimeout: Integer): AnsiString;
    property PortName: string read FPortName;
    property BaudRate: Integer read FBaudRate;
    property Timeout: Integer read FTimeout write FTimeout;
  end;

implementation

const
  CBR_9600 = 9600;
  CBR_19200 = 19200;
  CBR_38400 = 38400;
  CBR_57600 = 57600;
  CBR_115200 = 115200;

function BaudRateCodeToValue(Code: Integer): Integer;
begin
  case Code of
    0: Result := 1200;
    1: Result := 2400;
    2: Result := 4800;
    3: Result := CBR_9600;
    4: Result := CBR_19200;
    5: Result := CBR_38400;
    6: Result := CBR_57600;
    7: Result := CBR_115200;
  else
    Result := CBR_115200;
  end;
end;

{ TEmulSerialPort }

constructor TEmulSerialPort.Create;
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FTimeout := 3000;
end;

destructor TEmulSerialPort.Destroy;
begin
  Close;
  inherited Destroy;
end;

procedure TEmulSerialPort.CheckOpened;
begin
  if FHandle = INVALID_HANDLE_VALUE then
    raise Exception.Create('Serial port is not opened');
end;

procedure TEmulSerialPort.ApplyCommState;
var
  DCB: TDCB;
  Timeouts: TCommTimeOuts;
  Baud: Integer;
begin
  FillChar(DCB, SizeOf(DCB), 0);
  DCB.DCBlength := SizeOf(DCB);
  if not GetCommState(FHandle, DCB) then
    raise Exception.Create(SysErrorMessage(GetLastError));
  Baud := BaudRateCodeToValue(FBaudRate);
  DCB.BaudRate := Baud;
  DCB.ByteSize := 8;
  DCB.Parity := NOPARITY;
  DCB.StopBits := ONESTOPBIT;
  DCB.Flags := $01;
  if not SetCommState(FHandle, DCB) then
    raise Exception.Create(SysErrorMessage(GetLastError));

  FillChar(Timeouts, SizeOf(Timeouts), 0);
  Timeouts.ReadIntervalTimeout := MAXDWORD;
  Timeouts.ReadTotalTimeoutMultiplier := 0;
  Timeouts.ReadTotalTimeoutConstant := FTimeout;
  Timeouts.WriteTotalTimeoutMultiplier := 0;
  Timeouts.WriteTotalTimeoutConstant := FTimeout;
  if not SetCommTimeouts(FHandle, Timeouts) then
    raise Exception.Create(SysErrorMessage(GetLastError));
end;

procedure TEmulSerialPort.Open(const APortName: string; ABaudRate: Integer);
var
  DeviceName: string;
begin
  Close;
  FPortName := APortName;
  FBaudRate := ABaudRate;
  DeviceName := '\\.\' + APortName;
  FHandle := CreateFile(PChar(DeviceName), GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if FHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('Cannot open port %s: %s', [APortName, SysErrorMessage(GetLastError)]);
  ApplyCommState;
  PurgeComm(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);
end;

procedure TEmulSerialPort.Close;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
end;

function TEmulSerialPort.Opened: Boolean;
begin
  Result := FHandle <> INVALID_HANDLE_VALUE;
end;

procedure TEmulSerialPort.Purge;
begin
  if Opened then
    PurgeComm(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);
end;

procedure TEmulSerialPort.WriteData(const Data: AnsiString);
var
  Written: DWORD;
begin
  CheckOpened;
  if Data = '' then
    Exit;
  if not WriteFile(FHandle, Data[1], Length(Data), Written, nil) then
    raise Exception.Create(SysErrorMessage(GetLastError));
end;

function TEmulSerialPort.ReadChar(var C: AnsiChar): Boolean;
var
  ReadCount: DWORD;
begin
  Result := False;
  CheckOpened;
  if ReadFile(FHandle, C, 1, ReadCount, nil) and (ReadCount = 1) then
    Result := True;
end;

function TEmulSerialPort.ReadCharTimeout(var C: AnsiChar; ATimeout: Integer): Boolean;
var
  OldTimeout: Integer;
begin
  OldTimeout := FTimeout;
  try
    FTimeout := ATimeout;
    ApplyCommState;
    Result := ReadChar(C);
  finally
    FTimeout := OldTimeout;
    if Opened then
      ApplyCommState;
  end;
end;

function TEmulSerialPort.ReadExact(Count: Integer; ATimeout: Integer): AnsiString;
var
  i: Integer;
  C: AnsiChar;
begin
  SetLength(Result, Count);
  for i := 1 to Count do
  begin
    if not ReadCharTimeout(C, ATimeout) then
      raise Exception.Create('Serial read timeout');
    Result[i] := C;
  end;
end;

end.
