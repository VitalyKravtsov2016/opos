unit EmulProtocolServer;

interface

uses
  Classes, SysUtils, Windows,
  PrinterEmulator, EmulSerialPort;

const
  STX = #2;
  ENQ = #5;
  ACK = #6;
  NAK = #21;

type
  TEmulProtocolServer = class(TThread)
  private
    FPort: TEmulSerialPort;
    FDevice: TPrinterEmulator;
    FActive: Boolean;
    FResponse: AnsiString;
    FHasResponse: Boolean;
    function GetCRC(const Data: AnsiString): Byte;
    function EncodeFrame(const Data: AnsiString): AnsiString;
    function ReadExact(Count: Integer): AnsiString;
    procedure WriteByte(B: AnsiChar);
    procedure ProcessCommand(const Command: AnsiString);
    function NeedsResponse(const Command, Response: AnsiString): Boolean;
    procedure SendResponse;
  protected
    procedure Execute; override;
  public
    constructor Create(ADevice: TPrinterEmulator; APort: TEmulSerialPort);
    procedure StopServer;
    property Active: Boolean read FActive;
  end;

implementation

{ TEmulProtocolServer }

constructor TEmulProtocolServer.Create(ADevice: TPrinterEmulator; APort: TEmulSerialPort);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FDevice := ADevice;
  FPort := APort;
  FActive := False;
  FHasResponse := False;
  Priority := tpHigher;
end;

procedure TEmulProtocolServer.StopServer;
begin
  FActive := False;
  Terminate;
  WaitFor;
end;

function TEmulProtocolServer.GetCRC(const Data: AnsiString): Byte;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(Data) do
    Result := Result xor Ord(Data[i]);
end;

function TEmulProtocolServer.EncodeFrame(const Data: AnsiString): AnsiString;
var
  Payload: AnsiString;
begin
  Payload := AnsiChar(Length(Data)) + Data;
  Result := STX + Payload + AnsiChar(GetCRC(Payload));
end;

function TEmulProtocolServer.ReadExact(Count: Integer): AnsiString;
begin
  Result := FPort.ReadExact(Count, FPort.Timeout);
end;

procedure TEmulProtocolServer.WriteByte(B: AnsiChar);
begin
  FPort.WriteData(B);
end;

procedure TEmulProtocolServer.ProcessCommand(const Command: AnsiString);
begin
  FResponse := FDevice.Execute(Command, 3000);
  FHasResponse := NeedsResponse(Command, FResponse);
end;

function TEmulProtocolServer.NeedsResponse(const Command,
  Response: AnsiString): Boolean;
begin
  Result := Length(Response) > 0;
  if Result and (Length(Command) >= 2) and (Ord(Command[1]) = $FE) and
    (Ord(Command[2]) = $FB) then
    Result := False;
end;

procedure TEmulProtocolServer.SendResponse;
var
  C: AnsiChar;
begin
  if not FHasResponse then
    Exit;
  FPort.WriteData(EncodeFrame(FResponse));
  if FPort.ReadCharTimeout(C, 5000) and (C = ACK) then
    FHasResponse := False;
end;

procedure TEmulProtocolServer.Execute;
var
  C: AnsiChar;
  Command: AnsiString;
  DataLen: Integer;
  Payload: AnsiString;
begin
  FActive := True;
  while not Terminated do
  begin
    if not FPort.ReadCharTimeout(C, 500) then
      Continue;

    if C = ENQ then
    begin
      if FHasResponse then
      begin
        WriteByte(ACK);
        SendResponse;
      end
      else
        WriteByte(NAK);
      Continue;
    end;

    if C <> STX then
      Continue;

    if not FPort.ReadChar(C) then
      Continue;
    DataLen := Ord(C);
    Payload := ReadExact(DataLen + 1);
    Command := Copy(Payload, 1, DataLen);
    if GetCRC(AnsiChar(DataLen) + Command) <> Ord(Payload[DataLen + 1]) then
    begin
      WriteByte(NAK);
      Continue;
    end;
    WriteByte(ACK);
    ProcessCommand(Command);
    if FHasResponse then
      SendResponse;
  end;
  FActive := False;
end;

end.
