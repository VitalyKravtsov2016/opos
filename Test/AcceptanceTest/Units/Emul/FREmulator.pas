unit FREmulator;

interface

uses
  Classes, SysUtils,
  PrinterEmulator, EmulTables, EmulSerialPort, EmulProtocolServer;

const
  DEF_EMUL_PORT = 'COM8';
  DEF_DRIVER_PORT = 'COM7';
  DEF_BAUD_RATE = 7;

type
  TFREmulator = class
  private
    FDevice: TPrinterEmulator;
    FTables: TEmulTables;
    FPort: TEmulSerialPort;
    FServer: TEmulProtocolServer;
    FPortName: string;
    FBaudRate: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadTables(const FileName: string);
    procedure Start(const APortName: string = DEF_EMUL_PORT; ABaudRate: Integer = DEF_BAUD_RATE);
    procedure Stop;
    function Running: Boolean;
    property Device: TPrinterEmulator read FDevice;
    property Tables: TEmulTables read FTables;
    property PortName: string read FPortName;
  end;

implementation

{ TFREmulator }

constructor TFREmulator.Create;
begin
  inherited Create;
  FDevice := TPrinterEmulator.Create;
  FTables := TEmulTables.Create;
  FPort := TEmulSerialPort.Create;
  FPortName := DEF_EMUL_PORT;
  FBaudRate := DEF_BAUD_RATE;
end;

destructor TFREmulator.Destroy;
begin
  Stop;
  FPort.Free;
  FTables.Free;
  FDevice.Free;
  inherited Destroy;
end;

procedure TFREmulator.LoadTables(const FileName: string);
begin
  FTables.LoadFromFile(FileName);
  FDevice.ApplyTables(FTables);
end;

procedure TFREmulator.Start(const APortName: string; ABaudRate: Integer);
begin
  Stop;
  FPortName := APortName;
  FBaudRate := ABaudRate;
  FPort.Open(APortName, ABaudRate);
  FServer := TEmulProtocolServer.Create(FDevice, FPort);
  FServer.Resume;
end;

procedure TFREmulator.Stop;
begin
  if FServer <> nil then
  begin
    FServer.StopServer;
    FServer.Free;
    FServer := nil;
  end;
  FPort.Close;
end;

function TFREmulator.Running: Boolean;
begin
  Result := (FServer <> nil) and FServer.Active;
end;

end.
