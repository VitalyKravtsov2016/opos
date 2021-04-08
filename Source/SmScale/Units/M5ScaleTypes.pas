unit M5ScaleTypes;

interface

uses
  // VCL
  Windows, SysUtils;

type
  TBaudRates = array [0..6] of Integer;

  { TM5Params }

  TM5Params = record
    Port: Integer;
    BaudRate: Integer;
    Timeout: Integer;
  end;

  { TM5StatusFlags }

  TM5StatusFlags = record
    Value: Integer;
    isWeightFixed: Boolean;      // ��� 0 - ������� �������� ����
    isAutoZeroOn: Boolean;       // ��� 1 - ������� ������ ��������
    isChannelEnabled: Boolean;   // ��� 2 - "0"- ����� ��������, "1"- ����� �������.
    isTareSet: Boolean;          // ��� 3 - ������� ����
    isWeightStable: Boolean;     // ��� 4 - ������� ���������� ����
    isAutoZeroError: Boolean;    // ��� 5 - ������ �������� ��� ���������
    isOverweight: Boolean;       // ��� 6 - ���������� �� ����
    isReadWeightError: Boolean;  // ��� 7 - ������ ��� ��������� ���������
    isWeightTooLow: Boolean;     // ��� 8 - ���� �����������
    isADCNotResponding: Boolean; // ��� 9 - ��� ������ �� ���
  end;

  { TM5Status }

  TM5Status = record
    Flags: TM5StatusFlags;
    Weight: Integer; // ��� (4 ����� �� ������), �������� -���..���.
    Tare: Integer; // ���� (2 �����), �������� 0..���� (�������� ������ � ��������������� ������).
  end;

  { TGraduationPoint }

  TGraduationPoint = record
    Number: Integer;
    Weight: Integer;
  end;

  { TGraduationStatus }

  TGraduationStatus = record
    ChannelNumber: Integer; // ����� ������ (1 ����): ������� ��������� ������� �����.
    PointNumber: Integer; // �������� ����� (2 �����) : ��� � ������� �������� �����.
    PointStatus: Integer; // ��������� �������� ����� (1 ����):
  end;

  { TScaleChannel }

  TScaleChannel = record
    Number: Integer;
    Flags: Integer; // ����� (1 ����) :
    ChannelType: Integer;
    isTareSampling: Boolean;  // ��� 2 - ������� ����� ���� �� ��������� �����������.
    isRangeFlag1: Boolean; // ���3 - +2e ��� ������������ ����������.
    isRangeFlag2: Boolean; // ���4 - ��� +9�.
    PointPosition: Integer; // ��������� ���������� ����� (1 ����) : �������� 0..6.
    Power: ShortInt; // ������� (1 ����), ��������: -127..128.
    MaxWeight: Integer;
    MinWeight: Integer;
    MaxTare: Integer;
    Range1: Integer; // ��������1 (2 �����), �������� 0..65535
    Range2: Integer; // ��������2 (2 �����), �������� 0..65535
    Range3: Integer; // ��������3 (2 �����), �������� 0..65535
    Discreteness1: Integer; // ������������1 (1 ����), �������� 0..255
    Discreteness2: Integer; // ������������2 (1 ����), �������� 0..255
    Discreteness3: Integer; // ������������3 (1 ����), �������� 0..255
    Discreteness4: Integer; // ������������4 (1 ����), �������� 0..255
    PointCount: Integer; // ���������� �������������� �����
    CalibrationsCount: Integer;
  end;

  { TDeviceMetrics }

  TDeviceMetrics = record
    MajorType: Integer;
    MinorType: Integer;
    MajorVersion: Integer;
    MinorVersion: Integer;
    Model: Integer;
    Language: Integer;
    Name: string;
  end;

  { TM5Status2  }

  TM5Status2 = record
    Mode: Integer;
    Weight: Integer;
    Tare: Integer;
    ItemType: Integer;   // 0..1
    Quantity: Integer;   // 0..99
    Price: Integer;
    Amount: Integer;
    LastKey: Integer;
  end;

  { TM5WareItem }

  TM5WareItem = record
    ItemType: Integer;
    Quantity: Integer;
    Price: Integer;
  end;

  { TM5PowerReport }

  TM5PowerReport = record
    Voltage5: Integer;
    Voltage12: Integer;
    VoltageX: Integer;
    VoltageFlags: Integer;
    VoltageX1: Integer;
  end;

  { IM5ScaleDevice }

  IM5ScaleDevice = interface
  ['{FE8BEB3C-373A-4A99-B5F4-990E31A3EE9F}']
    function LockKeyboard: Integer;
    function UnlockKeyboard: Integer;
    function WriteMode(Mode: Integer): Integer;
    function SendKeyCode(Code: Integer): Integer;
    function ReadMode(var Mode: Integer): Integer;
    function ReadParams(var P: TM5Params): Integer;
    function WriteParams(const P: TM5Params): Integer;
    function WritePassword(const NewPassword: Integer): Integer;
    function Zero: Integer;
    function Tare: Integer;
    function WriteTareValue(Value: Integer): Integer;
    function ReadStatus(var R: TM5Status): Integer;
    function WriteGraduationPoint(const P: TGraduationPoint): Integer;
    function ReadGraduationPoint(var R: TGraduationPoint): Integer;
    function StartGraduation: Integer;
    function StopGraduation: Integer;
    function ReadGraduationStatus(var R: TGraduationStatus): Integer;
    function ReadADC(var R: Integer): Integer;
    function ReadKeyboardStatus(var R: Integer): Integer;
    function ReadChannelCount(var Count: Integer): Integer;
    function SelectChannel(const Number: Integer): Integer;
    function EnableChannel: Integer;
    function DisableChannel: Integer;
    function ReadChannel(var R: TScaleChannel): Integer;
    function WriteChannel(const R: TScaleChannel): Integer;
    function ReadChannelNumber(var Number: Integer): Integer;
    function ResetChannel: Integer;
    function Reset: Integer;
    function ReadDeviceMetrics(var R: TDeviceMetrics): Integer;
    function GetErrorText(Code: Integer): string;
    function GetCommandText(Code: Integer): string;
    function GetFullErrorText(Code: Integer): string;
    function GetPointStatusText(Code: Integer): string;
    function GetCommandTimeout: Integer;
    function GetPassword: Integer;
    function WriteWare(const P: TM5WareItem): Integer;
    function ReadFirmwareCRC(var R: Integer): Integer;
    function ReadPowerReport(var R: TM5PowerReport): Integer;
    function TestGet(var R: string): Integer;
    function TestClr: Integer;
    procedure Check(Code: Integer);
    procedure SetPassword(const Value: Integer);
    procedure SetCommandTimeout(const Value: Integer);
    function ReadStatus2(var R: TM5Status2): Integer;
    function SendCommand(const Command: string; var Answer: string): Integer;
    function HandleException(E: Exception): Integer;
    function GetResultCode: Integer;
    function GetResultText: WideString;
    function ClearResult: Integer;
    function GetModeText(Mode: Integer): WideString;
    function GetLanguageText(Code: Integer): WideString;
    function GetBaudRates: TBaudRates;
    function ReadWeightFactor: Double;

    property ResultCode: Integer read GetResultCode;
    property BaudRates: TBaudRates read GetBaudRates;
    property ResultText: WideString read GetResultText;
    property Password: Integer read GetPassword write SetPassword;
    property CommandTimeout: Integer read GetCommandTimeout write SetCommandTimeout;
  end;

  { IScaleUIController }

  IScaleUIController = interface
  ['{FC5210F5-33FE-47A6-B971-2B20EC4ABF0C}']
    procedure ShowScaleDlg;
  end;


const
  /////////////////////////////////////////////////////////////////////////////
  // Mode constants

  M5SCALE_MODE_NORMAL = 0; // Normal mode
  M5SCALE_MODE_CALIBR = 1; // Graduation mode
  M5SCALE_MODE_DATA   = 2; // Data mode

  /////////////////////////////////////////////////////////////////////////////
  // Mode text constants

  S_M5SCALE_MODE_NORMAL  = 'Normal mode';
  S_M5SCALE_MODE_CALIBR  = 'Graduation mode';
  S_M5SCALE_MODE_DATA    = 'Data mode';
  S_M5SCALE_MODE_UNKNOWN = 'Unknown mode';

  /////////////////////////////////////////////////////////////////////////////
  // ResultCode constants

  E_M5SCALE_NOERROR       = 0;
  E_M5SCALE_NOCONNECTION  = -1;
  E_M5SCALE_ANSWERLENGTH  = -2;
  E_M5SCALE_UNKNOWN       = -100;

  /////////////////////////////////////////////////////////////////////////////
  // Command names

  S_COMMAND_07h = '������� � �����';
  S_COMMAND_08h = '�������� ����������';
  S_COMMAND_09h = '����������/������������� ����������';
  S_COMMAND_11h = '������ �������� ������ �������� ������ 2';
  S_COMMAND_12h = '������ �������� ������ �������� ������';
  S_COMMAND_14h = '��������� ���������� ������';
  S_COMMAND_15h = '������ ���������� ������';
  S_COMMAND_16h = '��������� ������ ��������������';
  S_COMMAND_30h = '���������� ����';
  S_COMMAND_31h = '���������� ����';
  S_COMMAND_32h = '������ ����';
  S_COMMAND_33h = '�������� ��������� ������';
  S_COMMAND_3Ah = '������ ��������� �������� ������';
  S_COMMAND_70h = '�������� �������������� �����';
  S_COMMAND_71h = '��������� �������������� �����';
  S_COMMAND_72h = '������ �����������';
  S_COMMAND_73h = '������ ��������� �������� �����������';
  S_COMMAND_74h = '�������� ������� �����������';
  S_COMMAND_75h = '�������� ��������� ��� ��� �������� ������';
  S_COMMAND_90h = '������ ��������� ����������';
  S_COMMAND_E5h = '��������� ���������� ������� �������';
  S_COMMAND_E6h = '������� ������� �����';
  S_COMMAND_E7h = '�������� / ��������� ������� ������� �����';
  S_COMMAND_E8h = '��������� �������������� �������� ������';
  S_COMMAND_E9h = '�������� �������������� �������� ������';
  S_COMMAND_EAh = '�������� ����� �������� �������� ������';
  S_COMMAND_EFh = '���������� �������� �������� ������';
  S_COMMAND_F0h = '�����';
  S_COMMAND_F1h = '���� 1';
  S_COMMAND_F2h = '��������� CRC ��������';
  S_COMMAND_F3h = '��������� ����� � �������';
  S_COMMAND_F8h = '���� 2';
  S_COMMAND_FCh = '�������� ��� ����������';
  S_COMMAND_UNKNOWN = '����������� �������';


  /////////////////////////////////////////////////////////////////////////////
  // Error text

  S_ERROR_00  = '������ ���';
  S_ERROR_17  = '������ � �������� ����';
  S_ERROR_120 = '����������� �������';
  S_ERROR_121 = '�������� ����� ������ �������';
  S_ERROR_122 = '�������� ������';
  S_ERROR_123 = '������� �� ����������� � ������ ������';
  S_ERROR_124 = '�������� �������� ���������';
  S_ERROR_150 = '������ ��� ������� ��������� ����';
  S_ERROR_151 = '������ ��� ��������� ����';
  S_ERROR_152 = '��� �� ����������';
  S_ERROR_166 = '���� ����������������� ������';
  S_ERROR_167 = '������� �� ����������� �����������';
  S_ERROR_170 = '�������� ����� ������� ��������� � �������� �������';
  S_ERROR_180 = '����� ����������� ���������� �������������� ��������������';
  S_ERROR_181 = '���������� �������������';
  S_ERROR_182 = '������ �������� ��� �������� ������';
  S_ERROR_183 = '������ ��������� ������� �����';
  S_ERROR_184 = '� ������ ������� ������ ������ ������';
  S_ERROR_185 = '�������� ����� ������';
  S_ERROR_186 = '��� ������ �� ���';

  S_ERROR_UNKNOWN = '����������� ������';
  S_ERROR_ANSWERLENGTH = 'Answer data length is too short';

  /////////////////////////////////////////////////////////////////////////////
  // Point status

  S_POINT_STATUS_0 = '����� ������ ��� ���������';
  S_POINT_STATUS_1 = '����� ����������, ���������� ���';
  S_POINT_STATUS_2 = '����� ����������, ���������� ����';
  S_POINT_STATUS_3 = '����������� ��������� �������';
  S_POINT_STATUS_4 = '����������� ��������� � �������';
  S_POINT_STATUS_UNKNOWN = '����������� ��������� �����';


const
  M5BaudRates: TBaudRates =
  (
    CBR_2400,
    CBR_4800,
    CBR_9600,
    CBR_19200,
    CBR_38400,
    CBR_57600,
    CBR_115200
  );



function IntToBaudRate(Value: Integer): Integer;
function BaudRateToInt(Value: Integer): Integer;

implementation

function BaudRateToInt(Value: Integer): Integer;
begin
  case Value of
    CBR_2400   : Result := 0;
    CBR_4800   : Result := 1;
    CBR_9600   : Result := 2;
    CBR_19200  : Result := 3;
    CBR_38400  : Result := 4;
    CBR_57600  : Result := 5;
    CBR_115200 : Result := 6;
  else
    Result := 1;
  end;
end;

function IntToBaudRate(Value: Integer): Integer;
begin
  case Value of
    0: Result := CBR_2400;
    1: Result := CBR_4800;
    2: Result := CBR_9600;
    3: Result := CBR_19200;
    4: Result := CBR_38400;
    5: Result := CBR_57600;
    6: Result := CBR_115200;
  else
    Result := 1;
  end;
end;

end.
