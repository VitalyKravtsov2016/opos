unit TlvSenderStatic;

interface

(**
 * @brief ������������� ����������
 * @param fnSerial �������� ����� ����������� ����������
 * @param sz - ����� ������ fn. ���� ����� ����� 10 ��������, ����������� ����� ������� ��������� (\0)
 * @return 0 ��� �������� ����������, ��� ��� ������
 *)

function tlvSenderInit(const fn: PAnsiChar; size: Integer): Integer; cdecl;


(**
 * @brief ������ ������� ���������
 * @param host ���� ���. ���� ������ NULL, ������������ �������� �� ��������� "k-server.test-naofd.ru"
 * @param port ���� ���. ���� ������ NULL, ������������ �������� �� ��������� "7777"
 * @return 0 ��� �������� ����������, ��� ��� ������
 *)
function tlvSenderStart(const host: PAnsiChar; const port: PAnsiChar): Integer; cdecl;

(**
 * @brief ���������� ������ ����������. ���������� ������� ����� ���������
 *)
procedure tlvSenderStop; cdecl;

(**
 * @brief ������� ����� � ���
 * @param container ��������� � ��������� ��������������� ������� P-���������
 * @param sz - ������ ����������
 * @return 0 ��� �������� ����������, ��� ��� ������
 *)
function tlvSenderSendPacket(const container: PAnsiChar; size: Integer): Integer; cdecl;


implementation

const
  tlvapi32 = '';

function tlvSenderInit; external tlvapi32 name 'tlvSenderInit';
function tlvSenderStart; external tlvapi32 name 'tlvSenderStart';
procedure tlvSenderStop; external tlvapi32 name 'tlvSenderStop';
function tlvSenderSendPacket; external tlvapi32 name 'tlvSenderSendPacket';

end.
