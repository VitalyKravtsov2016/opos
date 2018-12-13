unit TLVTags;

interface

Uses
  // VCL
  Windows, SysUtils, Classes, ActiveX, StrUtils, DateUtils,
  // Tnt
  TntSysUtils,
  // This
  WException, ByteUtils, StringUtils, gnugettext;

type
  TTagType = (ttByte, ttUint16, ttUInt32, ttVLN, ttFVLN, ttBitMask,
    ttUnixTime, ttString, ttSTLV, ttByteArray);
  TTLVTag = class;

  { TTLVTags }

  TTLVTags = class
  private
    FList: TList;
    procedure CreateTags;
    procedure InsertItem(AItem: TTLVTag);
    procedure RemoveItem(AItem: TTLVTag);
    function GetItem(Index: Integer): TTLVTag;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Add: TTLVTag;
    procedure AddTag(ANumber: Integer; const ADescription: AnsiString;
      const AShortDescription: AnsiString; AType: TTagType;
      ALength: Integer; AFixedLength: Boolean = False);
    procedure Clear;
    function Find(ANumber: Integer): TTLVTag;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TTLVTag read GetItem; default;
  end;

  { TTLVTag }

  TTLVTag = class
  private
    FOwner: TTLVTags;
    FTag: Integer;
    FLength: Integer;
    FTagType: TTagType;
    FDescription: AnsiString;
    FShortDescription: AnsiString;
    FFixedLength: Boolean;

    procedure SetOwner(AOwner: TTLVTags);
  public
    constructor Create(AOwner: TTLVTags);
    destructor Destroy; override;

    function GetStrValue(AData: AnsiString): AnsiString;
    class function Format(t: TTagType; v: Variant): AnsiString;
    class function Int2ValueTLV(aValue: Int64; aSizeInBytes: Integer): AnsiString;
    class function VLN2ValueTLV(aValue: Int64): AnsiString;
    class function VLN2ValueTLVLen(aValue: Int64; ALen: Integer): AnsiString;
    class function FVLN2ValueTLV(aValue: Currency): AnsiString;
    class function FVLN2ValueTLVLen(aValue: Currency; ALength: Integer): AnsiString;
    class function ValueTLV2FVLNstr(s: AnsiString): AnsiString;
    class function UnixTime2ValueTLV(d: TDateTime): AnsiString;
    class function ASCII2ValueTLV(aValue: WideString): AnsiString;

    class function ValueTLV2UnixTime(s: AnsiString): TDateTime;
    class function ValueTLV2Int(s: AnsiString): Int64;
    class function ValueTLV2VLN(s: AnsiString): Int64;
    class function ValueTLV2FVLN(s: AnsiString): Currency;
    class function ValueTLV2ASCII(s: AnsiString): WideString;
    class function Int2Bytes(Value: UInt64; SizeInBytes: Integer): AnsiString;

    function ValueToBin(const Data: AnsiString): AnsiString;

    property Tag: Integer read FTag write FTag;
    property Length: Integer read FLength write FLength;
    property TagType: TTagType read FTagType write FTagType;
    property Description: AnsiString read FDescription write FDescription;
    property FixedLength: Boolean read FFixedLength write FFixedLength;
    property ShortDescription: AnsiString read FShortDescription write FShortDescription;
  end;

function TLVDocTypeToStr(ATag: Integer): WideString;

implementation

function TLVDocTypeToStr(ATag: Integer): WideString;
begin
  case ATag of
    1: Result := _('����� � �����������');
    11: Result := _('����� �� ��������� ���������� �����������');
    2: Result := _('����� �� �������� �����');
    21: Result := _('����� � ������� ��������� ��������');
    3: Result := _('�������� ���');
    31: Result := _('�������� ��� ���������');
    4: Result := _('����� ������� ����������');
    41: Result := _('����� ������� ���������� ���������');
    5: Result := _('����� � �������� �����');
    6: Result := _('����� � �������� ��');
    7: Result := _('������������� ���������');
  else
    Result := Tnt_WideFormat('%s: %d', [_('����������� ��� ���������'), ATag]);
  end;
end;

function CalcTypeToStr(AType: Integer): AnsiString;
begin
  case AType of
    1: Result := _('������');
    2: Result := _('������� �������');
    3: Result := _('������');
    4: Result := _('������� �������');
  else
    Result := _('�����. ���: ')  + IntToStr(AType);
  end;
end;

//
{
0 �����
1 ���������� �����
2 ���������� ����� ����� ������
3 ������ ����� �� ��������� �����
4 ������ �������������������� �����
5 ��������� ������� ���������������}

function TaxSystemToStr(AType: Integer): AnsiString;
begin
  If AType = 0 then
  begin
    Result := '���';
    Exit;
  end;
  if TestBit(AType, 0) then
    Result := _('���.');

  if TestBit(AType, 1) then
    Result := Result + _('+��');

  if TestBit(AType, 2) then
    Result := Result + _('+����');

  if TestBit(AType, 3) then
    Result := Result + _('+����');

  if TestBit(AType, 4) then
    Result := Result + _('+����');

  if TestBit(AType, 5) then
    Result := Result + _('+���');
end;

{ TTLVTags }

constructor TTLVTags.Create;
begin
  inherited Create;
  FList := TList.Create;
  CreateTags;
end;

destructor TTLVTags.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TTLVTags.Clear;
begin
  while Count > 0 do Items[0].Free;
end;

function TTLVTags.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TTLVTags.GetItem(Index: Integer): TTLVTag;
begin
  Result := FList[Index];
end;

procedure TTLVTags.InsertItem(AItem: TTLVTag);
begin
  FList.Add(AItem);
  AItem.FOwner := Self;
end;

procedure TTLVTags.RemoveItem(AItem: TTLVTag);
begin
  AItem.FOwner := nil;
  FList.Remove(AItem);
end;

function TTLVTags.Add: TTLVTag;
begin
  Result := TTLVTag.Create(Self);
end;

procedure TTLVTags.AddTag(ANumber: Integer; const ADescription: AnsiString;
  const AShortDescription: AnsiString; AType: TTagType; ALength: Integer;
  AFixedLength: Boolean = False);
var
  T: TTLVTag;
begin
  T := Add;
  T.FTag := ANumber;
  T.FLength := ALength;
  T.FDescription := ADescription;
  T.FShortDescription := AShortDescription;
  T.FixedLength := AFixedLength;
  T.FTagType := AType;

  if T.FTagType <> ttString then
  begin
    T.FixedLength := True;
  end;
end;

procedure TTLVTags.CreateTags;
begin
  AddTag(1000, '������������ ���������', '����. ���.',	ttString, 0);
  AddTag(1001, '������� ��������������� ������', '�����. �����. ���.', ttByte, 1);
  AddTag(1002, '������� ����������� ������', '�����. ��������. ���.', ttByte, 1);
  AddTag(1005, '����� ��������� ��������', '���. ����. ��������', ttString, 256);
  AddTag(1008, '������� ��� ����������� ����� ����������', '���. ��� EMAIL ����������', ttString, 64);
  AddTag(1009, '����� ��������', '���.��������', ttString, 256);
  // ������ ����
  AddTag(1010, '������ �������������� ����������� ������', '������ �������. ����. ������', ttVLN, 8);
  AddTag(1011, '������ �������������� ���������� ������', '������ �������. ����. ������', ttVLN, 8);

  AddTag(1012, '����, �����', '����, �����', ttUnixTime, 4);
  AddTag(1013, '��������� ����� ���', '���. ����� ���', ttString, 20);
  AddTag(1016, '��� ��������� ��������', '��� ��������� ��������', ttString, 12, True);
  AddTag(1017, '��� ���', '��� ���', ttString, 12, True);
  AddTag(1018, '��� ������������', '��� �����.', ttString, 12, True);
  AddTag(1020, '����� �������, ���������� � ���� (���)', '����� ������� � ����(���)', ttVLN, 6);
  AddTag(1021, '������', '������', ttString, 64);
  AddTag(1022, '��� ������ ���', '��� ������ ���', ttByte, 1);
  AddTag(1023, '���������� �������� �������', '���-�� �����. �������', ttFVLN, 8);
  AddTag(1026, '������������ ��������� ��������', '������. ����. ��������', ttString, 64);
  AddTag(1030, '������������ �������� �������', '������. �����. �������', ttString, 128);
  AddTag(1031, '����� �� ���� (���) ���������', '����� �� ���� ��� (���)', ttVLN, 6);
  AddTag(1036, '����� ��������', '����� ��������', ttString, 20);
  AddTag(1037, '��������������� ����� ���', '���. ����� ���', ttString, 20, True);
  AddTag(1038, '����� �����', '����� �����', ttUInt32, 4);
  AddTag(1040, '����� ��', '����� ��', ttUInt32, 4);
  AddTag(1041, '����� ��', '����� ��', ttString, 16, True);
  AddTag(1042, '����� ���� �� �����', '����� ���� �� �����', ttUInt32, 4);
  AddTag(1043, '��������� �������� �������', '�����. �����. �������', ttVLN, 6);
  AddTag(1044, '�������� ���������� ������', '�������� ����. ������', ttString, 24);
  // ������ ���
  AddTag(1045, '�������� ����������� ���������', '�������� ����. ���������', ttString, 24);

  AddTag(1046, '������������ ���', '������. ���', ttString, 256);
  AddTag(1048, '������������ ������������', '������. �����.', ttString, 256);
  AddTag(1050, '������� ���������� ������� ��', '�����. ������. ������� ��', ttByte, 1);
  AddTag(1051, '������� ������������� ������� ������ ��', '�����. �����. �����. ������ ��', ttByte, 1);
  AddTag(1052, '������� ������������ ������ ��', '�����. ��������. ������ ��', ttByte, 1);
  AddTag(1053, '������� ���������� ������� �������� ������ ���', '����� ������. ������� ����. ���. ���', ttByte, 1);
  AddTag(1054, '������� �������', '�����. �������', ttByte, 1);
  AddTag(1055, '����������� ������� ���������������', '������. ����. ���������������', ttByte, 1);
  AddTag(1056, '������� ����������', '�����. ����������', ttByte, 1);
  AddTag(1057, '������� ���������� ������', '�����. ����. ������', ttByte, 1);
  AddTag(1059, '������� �������', '�����. �������', ttSTLV, 1024);
  AddTag(1060, '����� ����� ���', '���. ����� ���', ttString, 256);
  AddTag(1062, '������� ���������������', '������� ���������.', ttByte, 1);
  AddTag(1068, '��������� ��������� ��� ��', '�����. ��������� ��� ��', ttSTLV, 9);
  AddTag(1073, '������� ���������� ������', '���. ����. ������', ttString, 19);
  AddTag(1074, '������� ��������� �� ������ ��������', '��� ����. �� ������ ��������', ttString, 19);
  AddTag(1075, '������� ��������� ��������', '���. ����. ��������', ttString, 19);
  AddTag(1077, '�� ���������', '�� ���������', ttByteArray, 6);
  AddTag(1078, '�� ���������', '�� ���������', ttByteArray, 16);
  AddTag(1079, '���� �� ������� �������� �������', '���� �� ��. �����. ����.', ttVLN, 6);
  AddTag(1080, '��������� ��� EAN 13', '�� EAN 13', ttString, 16);
  AddTag(1081, '����� �� ���� (���) ������������', '����� �� ���� ������������(���)', ttVLN, 6);
  // ������ ����
  AddTag(1082, '������� ����������� ���������', '���. ����. ���������', ttString, 19);
  AddTag(1083, '������� ���������� ���������', '���. ����. ���������', ttString, 19);


  AddTag(1084, '�������������� �������� ������������', '���. �������� �������.', ttSTLV, 320);
  AddTag(1085, '������������ ��������������� ��������� ������������', '������. ���. ��������. �������.', ttString, 64);
  AddTag(1086, '�������� ��������������� ��������� ������������', '����. ���. ��������. �������.', ttString, 256);
  AddTag(1097, '���������� ������������ ��', '���-�� ������������ ��', ttUInt32, 4);
  AddTag(1098, '���� � ����� ������� �� ������������ ��', '���� � ����� ������� ����������. ��', ttUnixTime, 4);
  AddTag(1101, '��� ������� ���������������', '��� ������� �����������.', ttByte, 1);
  AddTag(1102, '����� ��� ���� �� ������ 18%', '����� ��� ���� 18%', ttVLN, 6);
  AddTag(1103, '����� ��� ���� �� ������ 10%', '����� ��� ���� 10%', ttVLN, 6);
  AddTag(1104, '����� ������� �� ���� � ��� �� ������ 0%', '����� ����. �� ���� 0%', ttVLN, 6);
  AddTag(1105, '����� ������� �� ���� ��� ���', '����� ����. �� ���� ��� ���', ttVLN, 6);
  AddTag(1106, '����� ��� ���� �� ����. ������ 18/118', '����� ��� ���� �� ����. ������ 18/118', ttVLN, 6);
  AddTag(1107, '����� ��� ���� �� ����. ������ 10/110', '����� ��� ���� �� ����. ������ 10/110', ttVLN, 6);
  AddTag(1108, '������� ��� ��� �������� ������ � ��������', '�����. ��� ��� ����. ������ � ��������', ttByte, 1);
  AddTag(1109, '������� �������� �� ������', '�����. ����. �� ������', ttByte, 1);
  AddTag(1110, '������� �� ���', '�����. �� ���', ttByte, 1);
  AddTag(1111, '����� ���������� �� �� �����', '���. ��-�� �� �� �����', ttUInt32, 4);
  AddTag(1116, '����� ������� ������������� ���������', '����� ������� ����������. ���-��', ttUInt32, 4);
  AddTag(1117, '����� ����������� ����� ����������� ����', '���. ��. ����� ������. ����', ttString, 64);
  AddTag(1118, '���������� �������� ����� (���) �� �����', '���-�� �������� ����� �� �����(���)', ttUInt32, 4);
  // ������ ���
  AddTag(1119, '������� ��������� �� ������ ��������', '���. ����. �� ������ ����.', ttString, 19);

  AddTag(1126, '������� ���������� �������', '�����. ���������� �������', ttByte, 1);
  AddTag(1129, '�������� �������� �������', '�������� ����. "������"', ttSTLV, 116);
  AddTag(1130, '�������� �������� �������� �������', '�������� ����. "�����. �������"', ttSTLV, 116);
  AddTag(1131, '�������� �������� �������', '�������� ����. "������"', ttSTLV, 116);
  AddTag(1132, '�������� �������� �������� �������', '�������� ����. "�����. �������"', ttSTLV, 116);
  AddTag(1133, '�������� �������� �� ����� ���������', '�������� ���� �� ����� ����.', ttSTLV, 216);
  AddTag(1134, '���������� ����� (���) �� ����� ���������� ��������', '���-�� ����� ��� �� ����� �����. ����.', ttUInt32, 4);
  AddTag(1135, '���������� ����� �� �������� ��������', '���-�� ����� �� �����. ����.', ttUInt32, 4);
  AddTag(1136, '�������� ����� � ����� (���) ���������', '����. ����. � ����� ��� ���.', ttVLN, 8);
  AddTag(1138, '�������� ����� � ����� (���) ������������', '���� ����� � ����� ��� ������.', ttVLN, 8);
  AddTag(1139, '����� ��� �� ������ 18%', '����� ��� 18%', ttVLN, 8);
  AddTag(1140, '����� ��� �� ������ 10%', '����� ��� 10%', ttVLN, 8);
  AddTag(1141, '����� ��� �� ����. ������ 18/118', '����� ��� �� ����. ������ 18/118', ttVLN, 8);
  AddTag(1142, '����� ��� �� ����. ������ 10/110', '����� ��� �� ����. ������ 10/110', ttVLN, 8);
  AddTag(1143, '����� �������� � ��� �� ������ 0%', '����� ����. � ��� 0%', ttVLN, 8);
  AddTag(1144, '���������� ����� ���������', '���-�� ����� ��������', ttUInt32, 4);
  AddTag(1145, '�������� ��������� �������', '�����. ��������� "������"', ttSTLV, 100);
  AddTag(1146, '�������� ��������� �������', '�����. ��������� "������"', ttSTLV, 100);
  AddTag(1148, '���������� ��������������� �������������', '���-�� ������. �������������', ttUInt32, 4);
  AddTag(1149, '���������� ������������� �� �����������', '���-�� ������������� �� �������.', ttUInt32, 4);
  AddTag(1151, '����� ��������� ��� �� ������ 18%', '����� ��������� ��� 18%', ttVLN, 8);
  AddTag(1152, '����� ��������� ��� �� ������ 10%', '����� ��������� ��� 10%', ttVLN, 8);
  AddTag(1153, '����� ��������� ��� �� ����. ������ 18/118', '����� ��������� ��� �� ����. ��. 18/110', ttVLN, 8);
  AddTag(1154, '����� ��������� ��� ����. ������ 10/110', '����� ��������� ��� �� ���. ��. 10/110', ttVLN, 8);
  AddTag(1155, '����� ��������� � ��� �� ������ 0%', '����� ��������� ��� 0%', ttVLN, 8);
  AddTag(1157, '�������� ������ ��', '�������� ������ ��', ttSTLV, 708);
  AddTag(1158, '�������� ������ ������������ ��', '����� ������ �������. ��', ttSTLV, 708);
  AddTag(1162, '��� �������� ������������', '��� ������. �������.', ttByteArray, 32);
  AddTag(1171, '������� ����������', '���. ����������', ttString, 19);
  AddTag(1173, '��� ���������', '��� ���������', ttByte, 1);
  AddTag(1174, '��������� ��� ���������', '��������� ��� ���������', ttSTLV, 292);
  AddTag(1177, '������������ ��������� ��� ���������', '������. ���. ��� �������', ttString, 256);
  AddTag(1178, '���� ��������� ��������� ��� ���������', '���� ���-�� ���. ��� �������', ttUnixTime, 4);
  AddTag(1179, '����� ��������� ��������� ��� ���������', '����� ���-�� ���. ��� �������', ttString, 32);
  AddTag(1183, '����� �������� ��� ���', '����� ����. ��� ���', ttVLN, 8);
  AddTag(1184, '����� ��������� ��� ���', '����� �������. ��� ���', ttVLN, 8);
  AddTag(1187, '����� ��������', '����� ��������', ttString, 256);
  AddTag(1188, '������ ���', '������ ���', ttString, 8);
  AddTag(1189, '������ ��� ���', '������ ��� ���', ttByte, 1);
  AddTag(1190, '������ ��� ��', '������ ��� ��', ttByte, 1);
  AddTag(1191, '�������������� �������� �������� �������', '���. ����. �����. �������', ttString, 64);
  AddTag(1192, '�������������� �������� ���� (���)', '���. ����. ���� ���', ttString, 16);
  AddTag(1193, '������� ���������� �������� ���', '�����. ������. ������. ���', ttByte, 1);
  AddTag(1194, '�������� ������ �����', '�������� ������ �����', ttSTLV, 708);
  AddTag(1196, 'QR-���', 'QR-���', ttString, 0);
  AddTag(1197, '������� ��������� �������� �������', '��. �����. �������� ����.', ttString, 16);
  AddTag(1198, '������ ��� �� ������� �������� �������', '����. ��� �� ��. �����. ����.', ttVLN, 6);
  AddTag(1199, '������ ��� ', '������ ���', ttByte, 1);
  AddTag(1200, '����� ��� �� ������� �������', '����� ��� �� �����. ����.', ttVLN, 6);
  AddTag(1201, '����� �������� ����� � ����� (���)', '���. ����. ����� � ����� ���', ttVLN, 8);
  AddTag(1203, '��� �������', '��� �������', ttString, 12, True);
  AddTag(1205, '���� ������ ��������� �������� � ���', '���� ������� ���. ����. � ���', ttBitMask, 4);
  AddTag(1206, '��������� ���������', '�����. ����.', ttBitMask, 1);
  AddTag(1207, '������� �������� ������������ ��������', '�����. �������� ���������. ��������', ttByte, 1);
  AddTag(1208, '���� �����', '���� �����', ttString, 256);
  AddTag(1209, '������ ���', '������ ���', ttByte, 1);
  AddTag(1212, '������� �������� �������', '�����. �������� ����.', ttByte, 1);
  AddTag(1213, '������ ������ ��', '������ ������ ��', ttUInt16, 2);
  AddTag(1214, '������� ������� �������', '�����. ������� ����.', ttByte, 1);
  AddTag(1215, '����� �� ���� (���) ����������� (������� ������))', '����� �� ���� ��� �������.', ttVLN, 6);
  AddTag(1216, '����� �� ���� (���) ����������� (� ������)', '����� �� ���� ��� �������.', ttVLN, 6);
  AddTag(1217, '����� �� ���� (���) ��������� ���������������', '����� �� ���� ��� �������. �������.', ttVLN, 6);
  AddTag(1218, '�������� ����� � ����� (���) ������������ (��������)', '����. ����� � ����� ��� �������.', ttVLN, 8);
  AddTag(1219, '�������� ����� � ����� (���) ������������ (���������)', '����. ����� � ����� ��� �������.', ttVLN, 8);
  AddTag(1220, '�������� ����� � ����� (���) ���������� ����������������', '����. ����� � ����� ��� �������. �������.', ttVLN, 8);
  AddTag(1221, '������� ��������� �������� � ��������', '�����. ��������� �������� � ��������', ttByte, 1);
  AddTag(1222, '������� ������ �� �������� �������', '�����. ��. �� �����. ����', ttByte, 1);
  AddTag(1223, '������ ������', '������ ������', ttSTLV, 512);
  AddTag(1224, '������ ����������', '������ ����������', ttSTLV, 512);
  AddTag(1225, '������������ ����������', '������. ����������', ttString, 256);
  AddTag(1226, '��� ����������', '��� ����������', ttString, 12, True);
end;

function TTLVTags.Find(ANumber: Integer): TTLVTag;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if Items[i].Tag = ANumber then
    begin
      Result := Items[i];
      Break;
    end;
  end;
end;

{ TTLVTag }

constructor TTLVTag.Create(AOwner: TTLVTags);
begin
  inherited Create;
  SetOwner(AOwner);
end;

destructor TTLVTag.Destroy;
begin
  SetOwner(nil);
  inherited Destroy;
end;

function TTLVTag.GetStrValue(AData: AnsiString): AnsiString;
var
  saveSeparator: Char;
begin
  Result := '';
  saveSeparator := DecimalSeparator;
  DecimalSeparator := '.';
  try
    case TagType of
      ttByte: begin
                case Tag of
                  1054: Result := CalcTypeToStr(TTLVTag.ValueTLV2Int(AData));
                  1055, 1062: Result := TaxSystemToStr(TTLVTag.ValueTLV2Int(AData));
                else
                  Result := IntToStr(TTLVTag.ValueTLV2Int(AData));
                end;
              end;
      ttByteArray: begin
                     case Tag of
                       1077: Result := IntToStr(Cardinal(TTLVTag.ValueTLV2Int(ReverseString(Copy(AData, 3, 4)))));
                     else
                       Result := StrToHex(AData);
                     end;
                   end;
      ttUInt32: Result := IntToStr(Cardinal(TTLVTag.ValueTLV2Int(AData)));
      ttUInt16: Result := IntToStr(Cardinal(TTLVTag.ValueTLV2Int(AData)));
      ttUnixTime: Result := DateTimeToStr(TTLVTag.ValueTLV2UnixTime(AData));
      ttVLN: Result := SysUtils.Format('%.2f', [TTLVTag.ValueTLV2VLN(AData) / 100]);
      ttFVLN: Result := TTLVTag.ValueTLV2FVLNstr(AData);
      ttString: Result := TrimRight(TTLVTag.ValueTLV2ASCII(AData));
    end;
  finally
    DecimalSeparator := saveSeparator;
  end;
end;

procedure TTLVTag.SetOwner(AOwner: TTLVTags);
begin
  if AOwner <> FOwner then
  begin
    if FOwner <> nil then FOwner.RemoveItem(Self);
    if AOwner <> nil then AOwner.InsertItem(Self);
  end;
end;

class function TTLVTag.Int2ValueTLV(aValue: Int64; aSizeInBytes: Integer): AnsiString;
var
  d: Int64;
  i, c: Integer;
begin
  if (aSizeInBytes > 8) or (aSizeInBytes < 1) then
    raiseException(_('Too large data'));

  SetLength(Result, aSizeInBytes);

  c := 0;
  d := $FF;

  for i := 1 to aSizeInBytes do
  begin
    Result[i] := Char((aValue and d) shr c);
    c := c + 8;
    d := d shl 8;
  end;
end;

class function TTLVTag.VLN2ValueTLV(aValue: Int64): AnsiString;
var
  d: Int64;
  i, c: Integer;
begin
  Result := '';

  c := 0;
  d := $FF;

  for i := 1 to 8 do
  begin
    Result := Result + Char((aValue and d) shr c);
    c := c + 8;
    d := d shl 8;
    if (aValue shr c) = 0 then
      Break;
  end;
end;

class function TTLVTag.FVLN2ValueTLV(aValue: Currency): AnsiString;
var
  i: Int64;
  k: Byte;
  c: Currency;
begin
  i := Round(aValue);
  c := aValue;

  for k := 0 to 4 do
  begin
    if i = c then
      Break;

    c := c * 10;
    i := Round(c)
  end;

  Result := Char(k) + VLN2ValueTLV(i);
end;

class function TTLVTag.UnixTime2ValueTLV(d: TDateTime): AnsiString;
var
  c: Int64;
begin
  //c := Round((d - EncodeDateTime(1970, 1, 1, 3, 0, 0, 0)) * 86400);
//  c := Round((d - 25569) * 86400);

  c := Round((d - EncodeDateTime(1970, 1, 1, 0, 0, 0, 0)) * 86400);
  SetLength(Result, 4);
  Result[4] := Char((c and $FF000000) shr 24);
  Result[3] := Char((c and $FF0000) shr 16);
  Result[2] := Char((c and $FF00) shr 8);
  Result[1] := Char((c and $FF));
end;

class function TTLVTag.ValueTLV2UnixTime(s: AnsiString): TDateTime;
begin
  Result := 0;
  if System.Length(s) <> 4 then
    Exit;

  Result := (((Byte(s[4]) shl 24) or (Byte(s[3]) shl 16) or (Byte(s[2]) shl 8) or Byte(s[1])) / 86400) + EncodeDateTime(1970, 1, 1, 0, 0, 0, 0);
end;

class function TTLVTag.ASCII2ValueTLV(aValue: WideString): AnsiString;
var
  l: Integer;
  P: PChar;
begin
  Result := '';
  if aValue = '' Then
    Exit;

  l := WideCharToMultiByte(CP_OEMCP, WC_COMPOSITECHECK Or WC_DISCARDNS Or WC_SEPCHARS Or WC_DEFAULTCHAR, @aValue[1], -1, Nil, 0, Nil, Nil);
  if l > 1 then
  begin
    GetMem(P, l);
    SetLength(Result, l);
    WideCharToMultiByte(CP_OEMCP, WC_COMPOSITECHECK Or WC_DISCARDNS Or WC_SEPCHARS Or WC_DEFAULTCHAR, @aValue[1], -1, P, l - 1, Nil, Nil);
    P[l - 1] := #0;
    Result := Copy(P, 1, l - 1);
    FreeMem(P, l);
  end;
end;

class function TTLVTag.ValueTLV2ASCII(s: AnsiString): WideString;
var
  l: Integer;
begin
  l := MultiByteToWideChar(CP_OEMCP, MB_PRECOMPOSED, PChar(@s[1]), -1, nil, 0);
  SetLength(Result, l - 1);
  if l > 1 then
    MultiByteToWideChar(CP_OEMCP, MB_PRECOMPOSED, PChar(@s[1]), -1, PWideChar(@Result[1]), l - 1);
end;

class function TTLVTag.ValueTLV2Int(s: AnsiString): Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := System.Length(s) downto 1 do
  begin
    Result := Result * $100 + Byte(s[i]);
  end;
end;

class function TTLVTag.ValueTLV2VLN(s: AnsiString): Int64;
begin
  Result := ValueTLV2Int(s);
end;

class function TTLVTag.ValueTLV2FVLN(s: AnsiString): Currency;
var
  i: Byte;
begin
  if Byte(s[1]) > 8 then
    raiseException(_('�������� ����� FVLN'));

  if System.Length(s) < 2 then
    raiseException(_('�������� ����� FVLN'));

  Result := ValueTLV2Int(Copy(s, 2, System.Length(s) - 1));
  for i := 1 to Byte(s[1]) do
    Result := Result / 10;
end;

class function TTLVTag.VLN2ValueTLVLen(aValue: Int64;
  ALen: Integer): AnsiString;
var
  d: Int64;
  i, c: Integer;
begin
  Result := '';

  c := 0;
  d := $FF;

  for i := 1 to ALen do
  begin
    Result := Result + Char((aValue and d) shr c);
    c := c + 8;
    d := d shl 8;
//    if (aValue shr c) = 0 then
//      Break;
  end;
end;

class function TTLVTag.FVLN2ValueTLVLen(aValue: Currency; ALength: Integer): AnsiString;
var
  i: Int64;
  k: Byte;
  c: Currency;
begin
  i := Round(aValue);
  c := aValue;

  for k := 0 to 4 do
  begin
    if i = c then
      Break;

    c := c * 10;
    i := Round(c)
  end;

  Result := Char(k) + VLN2ValueTLVLen(i, Alength - 1);
end;

class function TTLVTag.ValueTLV2FVLNstr(s: AnsiString): AnsiString;
var
  i: Byte;
  R: Double;
  saveSeparator: Char;
begin
  Result := '';
  if System.Length(S) < 1 then Exit;
  if Byte(s[1]) > 8 then
    raiseException(_('�������� ����� FVLN'));

  if System.Length(s) < 2 then
    raiseException(_('�������� ����� FVLN'));

  R := ValueTLV2Int(Copy(s, 2, System.Length(s) - 1));
  for i := 1 to Byte(s[1]) do
    R := R / 10;

  saveSeparator := DecimalSeparator;
  DecimalSeparator := '.';
  try
    Result := sysutils.Format('%.*f', [Byte(s[1]), R]);
  finally
    DecimalSeparator := saveSeparator;
  end;
end;

class function TTLVTag.Int2Bytes(Value: UInt64; SizeInBytes: Integer): AnsiString;
var
  V: Int64;
  i: Integer;
begin
  Result := '';
  if not (SizeInBytes in [1..8]) then Exit;

  for i := 0 to SizeInBytes-1 do
  begin
    V := Value shr (i*8);
    if V = 0 then Break;
    Result := Chr(V and $FF) + Result;
  end;
  Result := StringOfChar(#0, SizeInBytes - System.Length(Result)) + Result;
end;

class function TTLVTag.Format(t: TTagType; v: Variant): AnsiString;
begin
  case t of
    ttByte      : Result := Int2ValueTLV(v, 1);
    ttUInt32    : Result := Int2ValueTLV(v, 4);
    ttUInt16    : Result := Int2ValueTLV(v, 2);
    ttSTLV      : Result := '';
    ttUnixTime  : Result := UnixTime2ValueTLV(v);
    ttVLN       : Result := VLN2ValueTLV(v);
    ttFVLN      : Result := FVLN2ValueTLV(v);
    ttString    : Result := ASCII2ValueTLV(v);
  end;
end;

function TTLVTag.ValueToBin(const Data: AnsiString): AnsiString;
var
  S: AnsiString;
begin
  case TagType of
    ttByte: Result := Int2ValueTLV(Tag, 2) +
      Int2ValueTLV(1, 2) + Int2ValueTLV(StrToInt(Data), 1);

    ttUint16: Result := Int2ValueTLV(Tag, 2) +
      Int2ValueTLV(2, 2) + Int2ValueTLV(StrToInt(Data), 2);

    ttUInt32: Result := Int2ValueTLV(Tag, 2) +
      Int2ValueTLV(4, 2) + Int2ValueTLV(StrToInt(Data), 4);

    ttVLN: Result := Int2ValueTLV(Tag, 2) + Int2ValueTLV(Length, 2) +
      VLN2ValueTLVLen(StrToInt(Data), Length);

    ttFVLN: Result := Int2ValueTLV(Tag, 2) +
      Int2ValueTLV(Length, 2) + FVLN2ValueTLVLen(StrToDouble(Data), Length);

    ttBitMask: Result := Int2ValueTLV(Tag, 2) +
      Int2ValueTLV(Length, 2) + Int2ValueTLV(StrToInt(Data), Length);

    ttUnixTime: Result := Int2ValueTLV(Tag, 2) +
      Int2ValueTLV(4, 2) + UnixTime2ValueTLV(StrToDateTime(Data));

    ttByteArray:
    begin
      S := HexToStr(Data);
      Result := Int2ValueTLV(Tag, 2) + Int2ValueTLV(System.Length(S), 2) + S;
    end;

    ttString:
    begin
      if FixedLength then
        Result := Int2ValueTLV(Tag, 2) +
          Int2ValueTLV(Length, 2) + ASCII2ValueTLV(AddTrailingSpaces(Data, Length))
      else
        Result := Int2ValueTLV(Tag, 2) +
          Int2ValueTLV(System.Length(Data), 2) + ASCII2ValueTLV(Data);
    end
    else
      Result := Data;
  end;
end;

end.
