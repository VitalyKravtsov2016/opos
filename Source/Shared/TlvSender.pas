unit TlvSender;

interface

uses
  // VCL
  Windows, SysUtils,
  // This
  FileUtils;

type
  TTlvInit = function (const fn: PAnsiChar; size: Integer): Integer; cdecl;
  TTlvStart = function (const host: PAnsiChar; const port: PAnsiChar): Integer; cdecl;
  TTlvStop = procedure; cdecl;
  TTlvSendPacket = function(const container: PAnsiChar; size: Integer): Integer; cdecl;

  { TTlvSender }

  TTlvSender = class
  private
    FHandle: THandle;
    FInit: TTlvInit;
    FStart: TTlvStart;
    FStop: TTlvStop;
    FSendPacket: TTlvSendPacket;
    procedure OpenDll;
    procedure CloseDll;
  public
    destructor Destroy; override;

    procedure Stop;
    procedure Init(const Serial: string);
    procedure Start(const Host, Port: string);
    procedure SendPacket(const Data: string);
    procedure Check(const name: string; Code: Integer);
  end;

implementation

const
  TlvDllName = 'tlv_sender.dll';

{ TTlvSender }

destructor TTlvSender.Destroy;
begin
  CloseDll;
  inherited Destroy;
end;

procedure TTlvSender.OpenDll;

  function FindProc(const ProcName: string): Pointer;
  begin
    Result := GetProcAddress(FHandle, PAnsiChar(ProcName));
    if Result = nil then
      raise Exception.CreateFmt('Function %s not found in %s.', [ProcName, TlvDllName]);
  end;

const
  SLibNotFound = 'Failed to load tlv_sender.dll';
var
  DllName: string;
begin
  if FHandle <> 0 then Exit;
  DllName := GetModulePath + TlvDllName;
  FHandle := LoadLibrary(PAnsiChar(DllName));
  if FHandle = 0 then
    raise Exception.Create(SLibNotFound);

  FInit := FindProc('tlvSenderInit');
  FStart := FindProc('tlvSenderStart');
  FStop := FindProc('tlvSenderStop');
  FSendPacket := FindProc('tlvSenderSendPacket');
end;

procedure TTlvSender.CloseDll;
begin
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  FHandle := 0;
end;

procedure TTlvSender.Check(const Name: string; Code: Integer);
begin
  if Code <> 0 then
    raise Exception.CreateFmt('%s failed, error code=%d', [Name, Code]);
end;

(**
 * @brief ������������� ����������
 * @param fnSerial �������� ����� ����������� ����������
 * @param sz - ����� ������ fn. ���� ����� ����� 10 ��������, ����������� ����� ������� ��������� (\0)
 * @return 0 ��� �������� ����������, ��� ��� ������

    function tlvSenderInit(const fn: PAnsiChar; size: Integer): Integer; cdecl;
 *)


procedure TTlvSender.Init(const Serial: string);
var
  S: string;
begin
  OpenDll;
  S := StringOfChar(#0, 10-Length(Serial)) + Serial;
  Check('Init', FInit(PChar(S), Length(S)));
end;

(**
 * @brief ������ ������� ���������
 * @param host ���� ���. ���� ������ NULL, ������������ �������� �� ��������� "k-server.test-naofd.ru"
 * @param port ���� ���. ���� ������ NULL, ������������ �������� �� ��������� "7777"
 * @return 0 ��� �������� ����������, ��� ��� ������
function tlvSenderStart(const host: PAnsiChar; const port: PAnsiChar): Integer; cdecl;
 *)

procedure TTlvSender.Start(const Host, Port: string);
begin
  OpenDll;
  Check('Start', FStart(PAnsiChar(Host), PAnsiChar(Port)));
end;

(**
 * @brief ������� ����� � ���
 * @param container ��������� � ��������� ��������������� ������� P-���������
 * @param sz - ������ ����������
 * @return 0 ��� �������� ����������, ��� ��� ������
function tlvSenderSendPacket(const container: PAnsiChar; size: Integer): Integer; cdecl;
 *)

procedure TTlvSender.SendPacket(const Data: string);
begin
  OpenDll;
  Check('SendPacket', FSendPacket(PChar(Data), Length(Data)));
end;

(**
 * @brief ���������� ������ ����������. ���������� ������� ����� ���������
procedure tlvSenderStop; cdecl;
 *)

procedure TTlvSender.Stop;
begin
  OpenDll;
  FStop;
end;


end.
