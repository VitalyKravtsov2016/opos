unit FiscalPrinterCommand;

interface

uses
  // VCL
  Windows, SysUtils, Classes,
  // This
  PrinterCommand, PrinterFrame, PrinterProtocol, PrinterTypes,
  BinStream, StringUtils, SerialPort, PrinterTable, AppLog;

type
  { TCommandRec }

  TCommandRec = record
    Code: Byte;                 // command code
    TxData: string;             // tx data
    RxData: string;             // rx data
    ResultCode: Byte;           // result code
    RepeatFlag: Boolean;        // repeat command
    Timeout: Integer;           // command timeout
  end;

  TCommandEvent = procedure(Sender: TObject; var Command: TCommandRec) of object;

  { TFiscalPrinterCommand }

  TFiscalPrinterCommand = class
  private
    FPort: TSerialPort;
    FEnabled: Boolean;
    FTaxPassword: DWORD;        // tax officer password
    FSysPassword: DWORD;        // system administrator password
    FUsrPassword: DWORD;       // regular user password
    FPrintWidth: Integer;
    FTables: TPrinterTables;
    FFields: TPrinterFields;
    FProtocol: TPrinterProtocol;
    FOnCommand: TCommandEvent;

    function GetLine(const Text: string): string;
    function DecodeEJFlags(Flags: Byte): TEJFlags;
    class function ByteToTimeout(Value: Byte): DWORD;
    class function TimeoutToByte(Value: Integer): Byte;
    function ReadTableInfo(Table: Byte): TPrinterTableRec;
    class function BaudRateToCode(BaudRate: Integer): Integer;
    class function CodeToBaudRate(BaudRate: Integer): Integer;
    function FieldToStr(FieldInfo: TPrinterFieldRec; const Value: string): string;
    function FieldToInt(FieldInfo: TPrinterFieldRec; const Value: string): Integer;
    function GetFieldValue(FieldInfo: TPrinterFieldRec; const Value: string): string;
    function ReadFieldInfo(Table, Field: Byte): TPrinterFieldRec;
    function ExecuteData(const Data: string; var RxData: string): Integer;
    function ExecuteCommand(var Command: TCommandRec): Integer;

    property Tables: TPrinterTables read FTables;
    property Fields: TPrinterFields read FFields;
    property Protocol: TPrinterProtocol read FProtocol;
    function SendCommand(var Command: TCommandRec): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure OpenPort;
    procedure ClosePort;
    function GetLineLength(const Text: string; MaxLength: Integer): string;
    function StartDump(DeviceCode: Integer): Integer;
    function GetDumpBlock: TDumpBlock;
    procedure StopDump;
    function LongFisc(NewPassword: DWORD; PrinterID, FiscalID: Int64): TLongFiscResult;
    procedure SetLongSerial(Serial: Int64);
    function GetLongSerial: TGetLongSerial;
    function GetShortStatus: TPrinterShortStatus;
    function GetStatus: TPrinterStatus;
    function GetFMFlags(Flags: Byte): TFMFlags;
    function GetPrinterFlags(Flags: Word): TPrinterFlags;
    function PrintBoldString(Flags: Byte; const Text: string): Integer;
    function Beep: Integer;
    function GetPortParams(Port: Byte): TPortParams;
    procedure SetPortParams(Port: Byte; const PortParams: TPortParams);
    procedure PrintDocHeader(const DocName: string; DocNumber: Word);
    procedure StartTest(Interval: Byte);
    function ReadCashTotalizer(ID: Byte): Int64;
    function ReadActnTotalizer(ID: Byte): Word;
    procedure WriteLicense(License: Int64);
    function ReadLicense: Int64;
    procedure WriteTableInt(Table, Row, Field, Value: Integer);
    procedure DoWriteTable(Table, Row, Field: Integer; const FieldValue: string);
    procedure WriteTable(Table, Row, Field: Integer; const FieldValue: string);
    function ReadTableBin(Table, Row, Field: Integer): string;
    function ReadTableStr(Table, Row, Field: Integer): string;
    function ReadTableInt(Table, Row, Field: Integer): Integer;
    procedure SetPointPosition(PointPosition: Byte);
    procedure SetTime(const Time: TPrinterTime);
    procedure SetDate(const Date: TPrinterDate);
    procedure ConfirmDate(const Date: TPrinterDate);
    procedure InitializeTables;
    procedure CutPaper(CutType: Byte);
    function ReadFontInfo(FontNumber: Byte): TFontInfo;
    procedure ResetFiscalMemory;
    procedure ResetTotalizers;
    procedure OpenDrawer(DrawerNumber: Byte);
    procedure FeedPaper(Station: Byte; Lines: Byte);
    procedure EjectSlip(Direction: Byte);
    procedure StopTest;
    procedure PrintActnTotalizers;
    procedure PrintStringFont(Station, Font: Byte; const Line: string);
    procedure PrintXReport;
    procedure PrintZReport;
    procedure PrintDepartmentsReport;
    procedure PrintTaxReport;
    procedure PrintHeader;
    procedure PrintDocTrailer(Flags: Byte);
    procedure PrintTrailer;
    procedure WriteSerial(Serial: DWORD);
    procedure InitFiscalMemory;
    function ReadFMTotals(Flags: Byte): TFMTotals;
    function ReadFMLastRecordDate: TFMRecordDate;
    function ReadShiftsRange: TShiftRange;
    function Fiscalization(Password, PrinterID, FiscalID: Int64): TFiscalizationResult;
    function ReportOnDateRange(ReportType: Byte; Range: TShiftDateRange): TShiftRange;
    function ReportOnNumberRange(ReportType: Byte; Range: TShiftNumberRange): TShiftRange;
    procedure InterruptReport;
    function ReadFiscInfo(FiscNumber: Byte): TFiscInfo;
    function OpenSlipDoc(Params: TSlipParams): TDocResult;
    function OpenStdSlip(Params: TStdSlipParams): TDocResult;
    function SlipOperation(Params: TSlipOperation; Operation: TPriceReg): Integer;
    function SlipStdOperation(LineNumber: Byte; Operation: TPriceReg): Integer;
    function SlipDiscount(Params: TSlipDiscountParams; Discount: TSlipDiscount): Integer;
    function SlipStdDiscount(Discount: TSlipDiscount): Integer;
    function SlipClose(Params: TCloseReceiptParams): TCloseReceiptResult;
    function ContinuePrint: Integer;
    function LoadGraphics(Line: Byte; Data: string): Integer;
    function PrintGraphics(Line1, Line2: Byte): Integer;
    function PrintBarcode(Barcode: Int64): Integer;
    function PrintGraphics2(Line1, Line2: Word): Integer;
    function LoadGraphics2(Line: Word; Data: string): Integer;
    function PrintBarLine(Height: Word; Data: string): Integer;
    function GetDeviceMetrics: TDeviceMetrics;
    function GetDayDiscountTotal: Int64;
    function GetRecDiscountTotal: Int64;
    function GetDayItemTotal: Int64;
    function GetRecItemTotal: Int64;
    function GetDayItemVoidTotal: Int64;
    function GetRecItemVoidTotal: Int64;
    function ReadTableStructure(Table: Byte): TPrinterTableRec;
    function ReadFieldStructure(Table, Field: Byte): TPrinterFieldRec;
    function GetEJSesssionResult(Number: Word; var Text: string): Integer;
    function GetEJReportLine(var Line: string): Integer;
    function EJReportStop: Integer;
    procedure Check(Value: Integer);
    function GetEJStatus1(var Status: TEJStatus1): Integer;
    procedure PrintString(Stations: Byte; const Text: string);
    function Execute(const Data: string): string;
    function ExecuteStream(Stream: TBinStream): Integer;
    function ExecutePrinterCommand(Command: TPrinterCommand): Integer;
    function GetEnabled: Boolean;
    function GetPrintWidth: Integer;
    function GetSysPassword: DWORD;
    function GetTaxPassword: DWORD;
    function GetUsrPassword: DWORD;
    procedure SetEnabled(const Value: Boolean);
    procedure SetSysPassword(const Value: DWORD);
    procedure SetTaxPassword(const Value: DWORD);
    procedure SetUsrPassword(const Value: DWORD);

    procedure CashIn(Amount: Int64);
    procedure CashOut(Amount: Int64);
    function Sale(Operation: TPriceReg): Integer;
    function Buy(Operation: TPriceReg): Integer;
    function RetSale(Operation: TPriceReg): Integer;
    function RetBuy(Operation: TPriceReg): Integer;
    function Storno(Operation: TPriceReg): Integer;
    function ReceiptClose(Params: TCloseReceiptParams): TCloseReceiptResult;
    function ReceiptDiscount(Operation: TAmountOperation): Integer;
    function ReceiptCharge(Operation: TAmountOperation): Integer;
    function ReceiptCancel: Integer;
    function GetSubtotal: Int64;
    function ReceiptStornoDiscount(Operation: TAmountOperation): Integer;
    function ReceiptStornoCharge(Operation: TAmountOperation): Integer;
    function PrintReceiptCopy: Integer;
    function OpenReceipt(ReceiptType: Byte): Integer;
    function FormatLines(const Line1, Line2: string): string;
    function FormatBoldLines(const Line1, Line2: string): string;

    property Port: TSerialPort read FPort;
    property PrintWidth: Integer read GetPrintWidth;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property OnCommand: TCommandEvent read FOnCommand write FOnCommand;
    property TaxPassword: DWORD read GetTaxPassword write SetTaxPassword;
    property SysPassword: DWORD read GetSysPassword write SetSysPassword;
    property UsrPassword: DWORD read GetUsrPassword write SetUsrPassword;
  end;

  { EDisabledException }

  EDisabledException = class(Exception);
  EFiscalPrinterException = class(Exception);

const
  PrinterBaudRates: array [0..6] of Integer = (
    CBR_2400,
    CBR_4800,
    CBR_9600,
    CBR_19200,
    CBR_38400,
    CBR_57600,
    CBR_115200);

function FormatLineLength(const Text: string; MaxLength: Integer): string;

implementation

const
  MinLineWidth = 40;

function TestBit(Value, Bit: Integer): Boolean;
begin
  Result := (Value and (1 shl Bit)) <> 0;
end;

function PrinterDateToBin(Value: TPrinterDate): string;
begin
  SetLength(Result, Sizeof(Value));
  Move(Value, Result[1], Sizeof(Value));
end;

procedure CheckMinLength(const Data: string; MinLength: Integer);
begin
  if Length(Data) < MinLength then
    raise ECommunicationError.Create('������������� ����� ������ ������');
end;

function PrinterTimeToStr(Time: TPrinterTime): string;
begin
  Result := Format('%.2d:%.2d:%.2d)', [Time.Hour, Time.Min, Time.Sec]);
end;

function PrinterDateToStr(Date: TPrinterDate): string;
begin
  Result := Format('%.2d.%.2d.%.4d)', [Date.Day, Date.Month, Date.Year + 2000]);
end;

function FormatLineLength(const Text: string; MaxLength: Integer): string;
begin
  Result := Copy(Text, 1, MaxLength);
  Result := Result + StringOfChar(' ', MaxLength - Length(Result));
end;

{ TFiscalPrinterCommand }

constructor TFiscalPrinterCommand.Create;
begin
  inherited Create;
  FPort := TSerialPort.Create;
  FProtocol := TPrinterProtocol.Create(FPort);
  FFields := TPrinterFields.Create;
  FTables := TPrinterTables.Create;
end;

destructor TFiscalPrinterCommand.Destroy;
begin
  FPort.Free;
  FFields.Free;
  FTables.Free;
  FProtocol.Free;
  inherited Destroy;
end;

function TFiscalPrinterCommand.GetLine(const Text: string): string;
begin
  Result := GetLineLength(Text, PrintWidth);
end;

function TFiscalPrinterCommand.GetLineLength(const Text: string; MaxLength: Integer): string;
begin
  Result := Copy(Text, 1, MaxLength);
  Result := Result + StringOfChar(#0, MaxLength - Length(Result));
end;

function TFiscalPrinterCommand.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TFiscalPrinterCommand.GetPrintWidth: Integer;
begin
  Result := FPrintWidth;
end;

function TFiscalPrinterCommand.GetSysPassword: DWORD;
begin
  Result := FSysPassword;
end;

function TFiscalPrinterCommand.GetTaxPassword: DWORD;
begin
  Result := FTaxPassword;
end;

function TFiscalPrinterCommand.GetUsrPassword: DWORD;
begin
  Result := FUsrPassword;
end;

procedure TFiscalPrinterCommand.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
end;

procedure TFiscalPrinterCommand.SetSysPassword(const Value: DWORD);
begin
  FSysPassword := Value;
end;

procedure TFiscalPrinterCommand.SetTaxPassword(const Value: DWORD);
begin
  FTaxPassword := Value;
end;

procedure TFiscalPrinterCommand.SetUsrPassword(const Value: DWORD);
begin
  FUsrPassword := Value;
end;

function TFiscalPrinterCommand.ReadFieldStructure(Table, Field: Byte): TPrinterFieldRec;
var
  AField: TPrinterField;
begin
  Logger.Debug('TFiscalPrinterCommand.ReadFieldStructure');
  AField := Fields.Find(Table, Field);
  if AField <> nil then
  begin
    Result := AField.Data;
  end else
  begin
    Result := ReadFieldInfo(Table, Field);
    TPrinterField.Create(Fields, Result);
  end;
end;

function TFiscalPrinterCommand.ReadTableStructure(Table: Byte): TPrinterTableRec;
var
  ATable: TPrinterTable;
begin
  Logger.Debug('TFiscalPrinterCommand.ReadTableStructure');
  ATable := Tables.ItemByNumber(Table);
  if ATable <> nil then
  begin
    Result := ATable.Data;
  end else
  begin
    Result := ReadTableInfo(Table);
    TPrinterTable.Create(Tables, Result);
  end;
end;

class function TFiscalPrinterCommand.BaudRateToCode(BaudRate: Integer): Integer;
begin
  case BaudRate of
    CBR_2400    : Result := 0;
    CBR_4800    : Result := 1;
    CBR_9600    : Result := 2;
    CBR_19200   : Result := 3;
    CBR_38400   : Result := 4;
    CBR_57600   : Result := 5;
    CBR_115200  : Result := 6;
  else
    Result := 1;
  end;
end;

class function TFiscalPrinterCommand.CodeToBaudRate(BaudRate: Integer): Integer;
begin
  case BaudRate of
    0: Result := CBR_2400;
    1: Result := CBR_4800;
    2: Result := CBR_9600;
    3: Result := CBR_19200;
    4: Result := CBR_38400;
    5: Result := CBR_57600;
    6: Result := CBR_115200;
  else
    Result := CBR_4800;
  end;
end;

class function TFiscalPrinterCommand.ByteToTimeout(Value: Byte): DWORD;
begin
  case Value of
    0..150   : Result := Value;
    151..249 : Result := (Value-149)*150;
  else
    Result := (Value-248)*15000;
  end;
end;

class function TFiscalPrinterCommand.TimeoutToByte(Value: Integer): Byte;
begin
  case Value of
    0..150        : Result := Value;
    151..15000    : Result := Round(Value/150) + 149;
    15001..105000 : Result := Round(Value/15000) + 248;
  else
    Result := Value;
  end;
end;

procedure TFiscalPrinterCommand.Check(Value: Integer);
begin
  if Value <> 0 then
    raise EFiscalPrinterException.Create(GetErrorText(Value));
end;

function TFiscalPrinterCommand.SendCommand(var Command: TCommandRec): Integer;
var
  CommandCode: Byte;
begin
  Command.RxData := Protocol.Send(Command.Timeout, Command.TxData);
  Command.RxData := Copy(Command.RxData, 3, Length(Command.RxData)-3);
  CommandCode := Ord(Command.RxData[1]);
  if CommandCode <> Command.Code then
    raise ECommunicationError.Create('Invalid answer code');

  Result := Ord(Command.RxData[2]);
  Command.ResultCode := Result;
  Command.RxData := Copy(Command.RxData, 3, Length(Command.RxData));
end;

function TFiscalPrinterCommand.ExecuteCommand(var Command: TCommandRec): Integer;
begin
  repeat
    Command.RepeatFlag := False;
    SendCommand(Command);
    if Assigned(FOnCommand) then FOnCommand(Self, Command);
    Result := Command.ResultCode;
    if not Command.RepeatFlag then Break;
  until false;
end;

function TFiscalPrinterCommand.ExecuteData(const Data: string; var RxData: string): Integer;
var
  Command: TCommandRec;
begin
  Command.Code := Ord(Data[1]);
  Command.Timeout := 10000; { !!! }
  Command.TxData := TPrinterFrame.Encode(Data);
  Result := ExecuteCommand(Command);
  RxData := Command.RxData;
end;

function TFiscalPrinterCommand.Execute(const Data: string): string;
begin
  Check(ExecuteData(Data, Result));
end;

function TFiscalPrinterCommand.ExecuteStream(Stream: TBinStream): Integer;
var
  RxData: string;
  TxData: string;
begin
  RxData := '';
  TxData := Stream.Data;
  Result := ExecuteData(TxData, RxData);
  Stream.Data := RxData;
end;

function TFiscalPrinterCommand.ExecutePrinterCommand(Command: TPrinterCommand): Integer;
var
  RxData: string;
  TxData: string;
  Stream: TBinStream;
begin
  Stream := TBinStream.Create;
  try
    Command.Encode(Stream);
    TxData := Chr(Command.GetCode) + Stream.Data;
    Result := ExecuteData(TxData, RxData);
    Stream.Data := RxData;
    Command.ResultCode := Result;
    if Command.ResultCode = 0 then
      Command.Decode(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TFiscalPrinterCommand.CashIn(Amount: Int64);
var
  Command: TCashInCommand;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.CashIn(%d)', [Amount]));

  Command := TCashInCommand.Create;
  try
    Command.Password := UsrPassword;
    Command.Amount := Amount;
    Check(ExecutePrinterCommand(Command));
  finally
    Command.Free;
  end;
end;

procedure TFiscalPrinterCommand.CashOut(Amount: Int64);
var
  Command: TCashOutCommand;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.CashOut(%d)', [Amount]));

  Command := TCashOutCommand.Create;
  try
    Command.Password := UsrPassword;
    Command.Amount := Amount;
    Check(ExecutePrinterCommand(Command));
  finally
    Command.Free;
  end;
end;

function TFiscalPrinterCommand.StartDump(DeviceCode: Integer): Integer;
var
  Command: TStartDumpCommand;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.StartDump(%d)', [DeviceCode]));

  Command := TStartDumpCommand.Create;
  try
    Command.Password := SysPassword;
    Command.DeviceCode := DeviceCode;
    Check(ExecutePrinterCommand(Command));
    Result := Command.BlockCount;
  finally
    Command.Free;
  end;
end;

function TFiscalPrinterCommand.GetDumpBlock: TDumpBlock;
var
  Command: TGetDumpBlockCommand;
begin
  Logger.Debug('TFiscalPrinterCommand.GetDumpBlock');

  Command := TGetDumpBlockCommand.Create;
  try
    Command.Password := SysPassword;
    Check(ExecutePrinterCommand(Command));
    Result := Command.DumpBlock;
  finally
    Command.Free;
  end;
end;

procedure TFiscalPrinterCommand.StopDump;
var
  Command: TStopDumpCommand;
begin
  Logger.Debug('TFiscalPrinterCommand.StopDump');

  Command := TStopDumpCommand.Create;
  try
    Command.Password := SysPassword;
    Check(ExecutePrinterCommand(Command));
  finally
    Command.Free;
  end;
end;

function TFiscalPrinterCommand.LongFisc(NewPassword: DWORD;
  PrinterID, FiscalID: Int64): TLongFiscResult;
var
  Command: TLongFiscalizationCommand;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.LongFisc(%d,%d,%d)',
    [NewPassword, PrinterID, FiscalID]));

  Command := TLongFiscalizationCommand.Create;
  try
    Command.TaxPassword := TaxPassword;
    Command.NewPassword := NewPassword;
    Command.PrinterID := PrinterID;
    Command.FiscalID := FiscalID;
    Check(ExecutePrinterCommand(Command));
    Result := Command.FiscResult;
  finally
    Command.Free;
  end;
end;

procedure TFiscalPrinterCommand.SetLongSerial(Serial: Int64);
var
  Command: TSetLongSerialCommand;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.SetLongSerial(%d)', [Serial]));

  Command := TSetLongSerialCommand.Create;
  try
    Command.Password := 0;
    Command.Serial := Serial;
    Check(ExecutePrinterCommand(Command));
  finally
    Command.Free;
  end;
end;

(******************************************************************************

  Get Long Serial Number And Long ECRRN

  Command:	0FH. Length: 5 bytes.
  �	Operator password (4 bytes)
  Answer:		0FH. Length: 16 bytes.
  �	Result Code (1 byte)
  �	Long Serial Number (7 bytes) 00000000000000�99999999999999
  �	Long ECRRN (7 bytes) 00000000000000�99999999999999

******************************************************************************)

function TFiscalPrinterCommand.GetLongSerial: TGetLongSerial;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.GetLongSerial');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte(COMMAND_GET_LONG_SERIAL);
    Stream.WriteDWORD(UsrPassword);

    Check(ExecuteStream(Stream));
    Stream.Read(Result, Sizeof(Result));
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  Get Short FP Status

  Command:	10H. Length: 5 bytes.
  �	Operator password (4 bytes)

  Answer:		10H. Length: 16 bytes.
  �	Result Code (1 byte)
  �	Operator index number (1 byte) 1�30
  �	FP flags (2 bytes)
  �	FP mode (1 byte)
  �	FP submode (1 byte)
  �	Quantity of operations on the current receipt (1 byte) lower byte of a two-byte digit (see below)
  �	Battery voltage (1 byte)
  �	Power source voltage (1 byte)
  �	Fiscal Memory error code (1 byte)
  �	EKLZ error code (1 byte) EKLZ=Electronic Cryptographic Journal
  �	Quantity of operations on the current receipt (1 byte) upper byte of a two-byte digit (see below)
  �	Reserved (3 bytes)

******************************************************************************)

function TFiscalPrinterCommand.GetShortStatus: TPrinterShortStatus;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.GetShortStatus');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte(COMMAND_GET_SHORT_STATUS);
    Stream.WriteDWORD(UsrPassword);

    Check(ExecuteStream(Stream));
    Stream.Read(Result, Sizeof(Result));
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  Get FP Status
  Command:	11H. Length: 5 bytes.
  �	Operator password (4 bytes)
  Answer:		11H. Length: 48 bytes.
  �	Result Code (1 byte)
  �	Operator index number (1 byte) 1�30
  �	FP firmware version (2 bytes)
  �	FP firmware build (2 bytes)
  �	FP firmware date (3 bytes) DD-MM-YY
  �	Number of FP in checkout line (1 byte)
  �	Current receipt number (2 bytes)
  �	FP flags (2 bytes)
  �	FP mode (1 byte)
  �	FP submode (1 byte)
  �	FP port (1 byte)
  �	FM firmware version (2 bytes)
  �	FM firmware build (2 bytes)
  �	FM firmware date (3 bytes) DD-MM-YY
  �	Current date (3 bytes) DD-MM-YY
  �	Current time (3 bytes) HH-MM-SS
  �	FM flags (1 byte)
  �	Serial number (4 bytes)
  �	Number of last daily totals record in FM (2 bytes) 0000�2100
  �	Quantity of free daily totals records left in FM (2 bytes)
  �	Last fiscalization/refiscalization record number in FM (1 byte) 1�16
  �	Quantity of free fiscalization/refiscalization records left in FM (1 byte) 0�15
  �	Taxpayer ID (6 bytes)

******************************************************************************)

function TFiscalPrinterCommand.GetStatus: TPrinterStatus;
var
  Command: TGetEcrStatusCommand;
begin
  Logger.Debug('TFiscalPrinterCommand.GetStatus');

  Command := TGetEcrStatusCommand.Create;
  try
    Command.Password := UsrPassword;
    Check(ExecutePrinterCommand(Command));
    Result := Command.Status;
  finally
    Command.Free;
  end;
end;

function TFiscalPrinterCommand.GetFMFlags(Flags: Byte): TFMFlags;
begin
  Result.FM1Present := TestBit(Flags, 0);
  Result.FM2Present := TestBit(Flags, 1);
  Result.LicenseEntered := TestBit(Flags, 2);
  Result.Overflow := TestBit(Flags, 3);
  Result.LowBattery := TestBit(Flags, 4);
  Result.LastRecordCorrupted := TestBit(Flags, 5);
  Result.DayOpened := TestBit(Flags, 6);
  Result.Is24HoursLeft := TestBit(Flags, 7);
end;

function TFiscalPrinterCommand.GetPrinterFlags(Flags: Word): TPrinterFlags;
begin
  Result.JrnNearEnd := not TestBit(Flags, 0);
  Result.RecNearEnd := not TestBit(Flags, 1);
  Result.SlpUpSensor := TestBit(Flags, 2);
  Result.SlpLoSensor := TestBit(Flags, 3);
  Result.DecimalPosition := TestBit(Flags, 4);
  Result.EJPresent := not TestBit(Flags, 5);
  Result.JrnEmpty := not TestBit(Flags, 6);
  Result.RecEmpty := not TestBit(Flags, 7);
  Result.JrnLeverUp := not TestBit(Flags, 8);
  Result.RecLeverUp := not TestBit(Flags, 9);
  Result.CoverOpened := TestBit(Flags, 10);
  Result.DrawerOpened := TestBit(Flags, 11);
  Result.Bit12 := TestBit(Flags, 12);
  Result.Bit13 := TestBit(Flags, 13);
  Result.EJNearEnd := TestBit(Flags, 14);
  Result.Bit15 := TestBit(Flags, 15);
end;

(******************************************************************************

  ������ ������ ������

  �������:	12H. ����� ���������: 26 ����.
  �	������ ��������� (4 �����)
  �	����� (1 ����) ��� 0 - ����������� �����, ��� 1 - ������� �����.
  �	���������� ������� (20 ����)
  �����:		12H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30
  ����������: ���������� ������� - ������� � ������� �������� WIN1251.
  ������� � ������ 0�31 �� ������������.

******************************************************************************)

function TFiscalPrinterCommand.PrintBoldString(Flags: Byte; const Text: string): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.PrintBoldString(%d,''%s'')',
    [Flags, Text]));

  Stream := TBinStream.Create;
  try
    Stream.WriteByte(COMMAND_PRINT_BOLD_LINE);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteByte(Flags);
    Stream.WriteString(Text, PrintWidth div 2);

    Check(ExecuteStream(Stream));
    Stream.Read(Result, Sizeof(Result));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  �����
  �������:	13H. ����� ���������: 5 ����.
  �	������ ��������� (4 �����)
  �����:		13H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.Beep: Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.Beep');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte(COMMAND_BEEP);
    Stream.WriteDWORD(UsrPassword);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ��������� ���������� ������
  �������:	14H. ����� ���������: 8 ����.
  �	������ ���������� �������������� (4 �����)
  �	����� ����� (1 ����) 0�255
  �	��� �������� ������ (1 ����) 0�6
  �	���� ��� ������ ����� (1 ����) 0�255
  �����:		14H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.SetPortParams(Port: Byte;
  const PortParams: TPortParams);
var
  Stream: TBinStream;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.SetPortParams(%d,%d,%d)',
    [Port, PortParams.BaudRate, PortParams.Timeout]));

  Stream := TBinStream.Create;
  try
    Stream.WriteByte(COMMAND_SET_PORT_PARAMS);
    Stream.WriteDWORD(SysPassword);
    Stream.WriteByte(Port);
    Stream.WriteByte(BaudRateToCode(PortParams.BaudRate));
    Stream.WriteByte(TimeoutToByte(PortParams.Timeout));
    Check(ExecuteStream(Stream));
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������ ���������� ������
  �������:	15H. ����� ���������: 6 ����.
  �	������ ���������� �������������� (4 �����)
  �	����� ����� (1 ����) 0�255
  �����:		15H. ����� ���������: 4 �����.
  �	��� ������ (1 ����)
  �	��� �������� ������ (1 ����) 0�6
  �	���� ��� ������ ����� (1 ����) 0�255

******************************************************************************)


function TFiscalPrinterCommand.GetPortParams(Port: Byte): TPortParams;
var
  Stream: TBinStream;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.GetPortParams(%d)',  [Port]));

  Stream := TBinStream.Create;
  try
    Stream.WriteByte(COMMAND_GET_PORT_PARAMS);
    Stream.WriteDWORD(SysPassword);
    Stream.WriteByte(Port);
    Check(ExecuteStream(Stream));
    Result.BaudRate := CodeToBaudRate(Stream.ReadByte);
    Result.Timeout := ByteToTimeout(Stream.ReadByte);
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ��������������� ���������
  �������:	16H. ����� ���������: 1 ����.
  �����:		16H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.ResetFiscalMemory;
begin
  Logger.Debug('TFiscalPrinterCommand.ResetFiscalMemory');
  Execute(Chr(COMMAND_RESETFM));
end;

(******************************************************************************

  ������ ������
  �������:	17H. ����� ���������: 46 ����.
  �	������ ��������� (4 �����)
  �	����� (1 ����) ��� 0 - ����������� �����, ��� 1 - ������� �����.
  �	���������� ������� (40 ����)
  �����:		17H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintString(Stations: Byte; const Text: string);
var
  Line: string;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.PrintString(%d,''%s'')',
    [Stations, Text]));

  Line := Text;
  if Line = '' then Line := ' ';
  Execute(#$17 + IntToBin(UsrPassword, 4) + Chr(Stations) + GetLine(Line));
end;

(******************************************************************************

  ������ ��������� ���������
  �������:	18H. ����� ���������: 37 ����.
  �	������ ��������� (4 �����)
  �	������������ ��������� (30 ����)
  �	����� ��������� (2 �����)
  �����:		18H. ����� ���������: 5 ����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30
  �	�������� ����� ��������� (2 �����)

******************************************************************************)

procedure TFiscalPrinterCommand.PrintDocHeader(const DocName: string; DocNumber: Word);
var
  Stream: TBinStream;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.PrintDocHeader(''%s'', %d)',
    [DocName, DocNumber]));

  Stream := TBinStream.Create;
  try
    Stream.WriteByte(COMMAND_PRINT_DOC_HEADER);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteString(DocName, 30);
    Stream.WriteInt(DocNumber, 2);

    Check(ExecuteStream(Stream));
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  �������� ������
  �������:	19H. ����� ���������: 6 ����.
  �	������ ��������� (4 �����)
  �	������ ������ � ������� (1 ����) 1�99
  �����:		19H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.StartTest(Interval: Byte);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.StartTest(%d)', [Interval]));

  Execute(#$19 + IntToBin(UsrPassword, 4) + Chr(Interval));
end;

(******************************************************************************

  ������ ��������� ��������
  �������:	1AH. ����� ���������: 6 ����.
  �	������ ��������� (4 �����)
  �	����� �������� (1 ����) 0� 255
  �����:		1AH. ����� ���������: 9 ����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30
  �	���������� �������� (6 ����)

******************************************************************************)

function TFiscalPrinterCommand.ReadCashTotalizer(ID: Byte): Int64;
var
  Stream: TBinStream;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReadCashTotalizer(%d)', [ID]));

  Stream := TBinStream.Create;
  try
    Stream.WriteByte(COMMAND_READ_CASH_TOTALIZER);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteByte(ID);
    Check(ExecuteStream(Stream));

    Stream.ReadByte;                    // ����� ���������
    Result := Stream.ReadInt(6);
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������ ������������� ��������
  �������:	1BH. ����� ���������: 6 ����.
  �	������ ��������� (4 �����)
  �	����� �������� (1 ����) 0� 255
  �����:		1BH. ����� ���������: 5 ����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30
  �	���������� �������� (2 �����)

******************************************************************************)

function TFiscalPrinterCommand.ReadActnTotalizer(ID: Byte): Word;
var
  Data: string;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReadActnTotalizer(%d)', [ID]));

  Data := Execute(#$1B + IntToBin(UsrPassword, 4) + Chr(ID));
  Result := BinToInt(Data, 2, 2);
end;


(******************************************************************************

  ������ ��������
  �������:	1CH. ����� ���������: 10 ����.
  �	������ ���������� �������������� (4 �����)
  �	�������� (5 ����) 0000000000�9999999999
  �����:		1CH. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.WriteLicense(License: Int64);
var
  Command: TWriteLicenseCommand;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.WriteLicense(%d)', [License]));

  Command := TWriteLicenseCommand.Create;
  try
    Command.SysPassword := SysPassword;
    Command.License := License;
    Check(ExecutePrinterCommand(Command));
  finally
    Command.Free;
  end;
end;

(******************************************************************************

  ������ ��������
  �������:	1DH. ����� ���������: 5 ����.
  �	������ ���������� �������������� (4 �����)
  �����:		1DH. ����� ���������: 7 ����.
  �	��� ������ (1 ����)
  �	�������� (5 ����) 0000000000�9999999999

******************************************************************************)

function TFiscalPrinterCommand.ReadLicense: Int64;
var
  Command: TReadLicenseCommand;
begin
  Logger.Debug('TFiscalPrinterCommand.ReadLicense');

  Command := TReadLicenseCommand.Create;
  try
    Command.SysPassword := SysPassword;
    Check(ExecutePrinterCommand(Command));
    Result := Command.License;
  finally
    Command.Free;
  end;
end;

(******************************************************************************
******************************************************************************)

procedure TFiscalPrinterCommand.DoWriteTable(Table, Row, Field: Integer;
  const FieldValue: string);
var
  Command: TWriteTableCommand;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.DoWriteTable(%d,%d,%d,%s)',
    [Table, Row, Field, FieldValue]));

  Command := TWriteTableCommand.Create;
  try
    Command.SysPassword := SysPassword;
    Command.Table := Table;
    Command.Row := Row;
    Command.Field := Field;
    Command.FieldValue := FieldValue;
    Check(ExecutePrinterCommand(Command));
  finally
    Command.Free;
  end;
end;

(******************************************************************************

  ������ �������
  �������:	1FH. ����� ���������: 9 ����.
  �	������ ���������� �������������� (4 �����)
  �	������� (1 ����)
  �	��� (2 �����)
  �	���� (1 ����)
  �����:		1FH. ����� ���������: (2+X) ����.
  �	��� ������ (1 ����)
  �	�������� (X ����) �� 40 ����

******************************************************************************)

function TFiscalPrinterCommand.ReadTableBin(Table, Row,
  Field: Integer): string;
var
  Command: TReadTableCommand;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReadTableBin(%d,%d,%d)',
    [Table, Row, Field]));

  Command := TReadTableCommand.Create;
  try
    Command.SysPassword := SysPassword;
    Command.Table := Table;
    Command.Row := Row;
    Command.Field := Field;
    Check(ExecutePrinterCommand(Command));
    Result := Command.FieldValue;
  finally
    Command.Free;
  end;
end;

(******************************************************************************

  ������ ��������� ���������� �����
  �������:	20H. ����� ���������: 6 ����.
  �	������ ���������� �������������� (4 �����)
  �	��������� ���������� ����� (1 ����) "0"- 0 ������, "1"- 2 ������
  �����:		20H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)


******************************************************************************)

procedure TFiscalPrinterCommand.SetPointPosition(PointPosition: Byte);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.SetPointPosition(%d)',
    [PointPosition]));

  Execute(#$20 + IntToBin(SysPassword, 4) + Chr(PointPosition));
end;

(******************************************************************************

  ���������������� �������
  �������:	21H. ����� ���������: 8 ����.
  �	������ ���������� �������������� (4 �����)
  �	����� (3 �����) ��-��-��
  �����:		21H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.SetTime(const Time: TPrinterTime);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.SetTime(%s)',
    [PrinterTimeToStr(Time)]));

  Execute(#$21 + IntToBin(SysPassword, 4) +
    Chr(Time.Hour) + Chr(Time.Min) + Chr(Time.Sec));
end;

(******************************************************************************

  ���������������� ����
  �������:	22H. ����� ���������: 8 ����.
  �	������ ���������� �������������� (4 �����)
  �	���� (3 �����) ��-��-��
  �����:		22H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.SetDate(const Date: TPrinterDate);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.SetDate(%s)',
    [PrinterDateToStr(Date)]));

  Execute(#$22 + IntToBin(SysPassword, 4) +
    Chr(Date.Day) + Chr(Date.Month) + Chr(Date.Year));
end;

(******************************************************************************

  ������������� ���������������� ����
  �������:	23H. ����� ���������: 8 ����.
  �	������ ���������� �������������� (4 �����)
  �	���� (3 �����) ��-��-��
  �����:		23H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.ConfirmDate(const Date: TPrinterDate);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ConfirmDate(%.2d.%.2d.%.4d)',
    [Date.Day, Date.Month, Date.Year + 2000]));

  Execute(#$23 + IntToBin(SysPassword, 4) +
    Chr(Date.Day) + Chr(Date.Month) + Chr(Date.Year));
end;

(******************************************************************************

  ������������� ������ ���������� ����������
  �������:	24H. ����� ���������: 5 ����.
  �	������ ���������� �������������� (4 �����)
  �����:		24H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.InitializeTables;
begin
  Logger.Debug('TFiscalPrinterCommand.InitializeTables');
  Execute(#$24 + IntToBin(SysPassword, 4));
end;

(******************************************************************************

  ������� ����
  �������:	25H. ����� ���������: 6 ����.
  �	������ ��������� (4 �����)
  �	��� ������� (1 ����) "0" - ������, "1" - ��������
  �����:		25H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.CutPaper(CutType: Byte);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.CutPaper(%d)', [CutType]));
  Execute(#$25 + IntToBin(UsrPassword, 4) + Chr(CutType));
end;

(******************************************************************************

  ��������� ��������� ������
  �������:	26H. ����� ���������: 6 ����.
  �	������ ���������� �������������� (4 �����)
  �	����� ������ (1 ����)
  �����:		26H. ����� ���������: 7 ����.
  �	��� ������ (1 ����)
  �	������ ������� ������ � ������ (2 �����)
  �	������ ������� � ������ �������������� ��������� � ������ (1 ����)
  �	������ ������� � ������ ������������ ��������� � ������ (1 ����)
  �	���������� ������� � �� (1 ����)

******************************************************************************)

function TFiscalPrinterCommand.ReadFontInfo(FontNumber: Byte): TFontInfo;
var
  Data: string;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReadFontInfo(%d)', [FontNumber]));

  Data := Execute(#$26 + IntToBin(SysPassword, 4) + Chr(FontNumber));
  //CheckMinLength(Data, Sizeof(Result)); { !!! }
  Move(Data[1], Result, Sizeof(Result));
end;

(******************************************************************************

  ����� �������
  �������:	27H. ����� ���������: 5 ����.
  �	������ ���������� �������������� (4 �����)
  �����:		27H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.ResetTotalizers;
begin
  Logger.Debug('TFiscalPrinterCommand.ResetTotalizers');
  Execute(#$27 + IntToBin(SysPassword, 4));
end;

(******************************************************************************

  ������� �������� ����
  �������:	28H. ����� ���������: 6 ����.
  �	������ ��������� (4 �����)
  �	����� ��������� ����� (1 ����) 0, 1
  �����:		28H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.OpenDrawer(DrawerNumber: Byte);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.OpenDrawer(%d)', [DrawerNumber]));
  Execute(#$28 + IntToBin(UsrPassword, 4) + Chr(DrawerNumber));
end;

(******************************************************************************

  ��������
  �������:	29H. ����� ���������: 7 ����.
  �	������ ��������� (4 �����)
  �	����� (1 ����)
        ��� 0 - ����������� �����,
        ��� 1 - ������� �����,
        ��� 2 - ���������� ��������.

  �	���������� ����� (1 ����) 1�255 - ������������ ���������� �����
        �������������� �������� ������ ������, �� �� ��������� 255

  �����:		29H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.FeedPaper(Station: Byte; Lines: Byte);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.FeedPaper(%d,%d)',
    [Station, Lines]));

  Execute(#$29 + IntToBin(UsrPassword, 4) + Chr(Station) + Chr(Lines));
end;

(******************************************************************************

  ������ ����������� ���������
  �������:	2AH. ����� ���������: 6 ����.
  �	������ ��������� (4 �����)
  �	����������� ������� ����������� ��������� (1 ����) "0" - ����, "1" - �����
  �����:		2AH. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.EjectSlip(Direction: Byte);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.EjectSlip(%d)',
    [Direction]));

  Execute(#$2A + IntToBin(UsrPassword, 4) + Chr(Direction));
end;

(******************************************************************************

  ���������� ��������� �������
  �������:	2BH. ����� ���������: 5 ����.
  �	������ ��������� (4 �����)
  �����:		2BH. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.StopTest;
begin
  Logger.Debug('TFiscalPrinterCommand.StopTest');

  Execute(#$2B + IntToBin(UsrPassword, 4));
end;

(******************************************************************************

������ ��������� ������������ ���������
�������:	2�H. ����� ���������: 5 ����.
�	������ �������������� ��� ���������� �������������� (4 �����)
�����:		2�H. ����� ���������: 3 �����.
�	��� ������ (1 ����)
�	���������� ����� ��������� (1 ����) 29, 30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintActnTotalizers;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintActnTotalizers');

  Execute(#$2C + IntToBin(SysPassword, 4));
end;

(******************************************************************************

  ������ ��������� �������
  �������:	2DH. ����� ���������: 6 ����.
  �	������ ���������� �������������� (4 �����)
  �	����� ������� (1 ����)
  �����:		2DH. ����� ���������: 45 ����.
  �	��� ������ (1 ����)
  �	�������� ������� (40 ����)
  �	���������� ����� (2 �����)
  �	���������� ����� (1 ����)

******************************************************************************)

function TFiscalPrinterCommand.ReadTableInfo(Table: Byte): TPrinterTableRec;
var
  Data: string;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReadTableInfo(%d)', [Table]));

  Data := Execute(#$2D + IntToBin(SysPassword, 4) + Chr(Table));
  CheckMinLength(Data, 43);
  Result.Number := Table;
  Result.Name := Copy(Data, 1, 40);
  Result.RowCount := BinToInt(Data, 41, 2);
  Result.FieldCount := BinToInt(Data, 43, 1);
end;

(******************************************************************************

  ������ ��������� ����
  �������:	2EH. ����� ���������: 7 ����.
  �	������ ���������� �������������� (4 �����)
  �	����� ������� (1 ����)
  �	����� ���� (1 ����)
  �����:		2EH. ����� ���������: (44+X+X) ����.
  �	��� ������ (1 ����)
  �	�������� ���� (40 ����)
  �	��� ���� (1 ����) "0" - BIN, "1" - CHAR
  �	���������� ���� - X (1 ����)
  �	����������� �������� ���� - ��� ����� ���� BIN (X ����)
  �	������������ �������� ���� - ��� ����� ���� BIN (X ����)

******************************************************************************)

function TFiscalPrinterCommand.ReadFieldInfo(Table, Field: Byte): TPrinterFieldRec;
var
  Data: string;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReadFieldInfo(%d,%d)', [Table, Field]));

  Data := Execute(#$2E + IntToBin(SysPassword, 4) + Chr(Table) + Chr(Field));
  CheckMinLength(Data, 42);

  Result.Table := Table;
  Result.Field := Field;
  Result.Name := Copy(Data, 1, 40);
  Result.FieldType := Ord(Data[41]);
  Result.Size := Ord(Data[42]);
  if (Result.FieldType = 0)and(Length(Data) >= (42 + Result.Size*2)) then
  begin
    Result.MinValue := 0;
    Move(Data[43], Result.MinValue, Result.Size);
    Result.MaxValue := 0;
    Move(Data[43 + Result.Size], Result.MaxValue, Result.Size);
  end;
end;

(******************************************************************************

  ������ ������ ������ �������
  �������:	2FH. ����� ���������: 47 ����.
  �	������ ��������� (4 �����)
  �	����� (1 ����) ��� 0 - ����������� �����, ��� 1 - ������� �����.
  �	����� ������ (1 ����) 0�255
  �	���������� ������� (40 ����)
  �����:		2FH. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintStringFont(Station, Font: Byte;
  const Line: string);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.PrintStringFont(%d,%d)',
    [Station, Font]));

  Execute(#$2F + IntToBin(UsrPassword, 4) + Chr(Station) + Chr(Font) + GetLine(Line));
end;

(******************************************************************************

  �������� ����� ��� �������
  �������:	40H. ����� ���������: 5 ����.
  �	������ �������������� ��� ���������� �������������� (4 �����)
  �����:		40H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 29, 30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintXReport;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintXReport');

  Execute(#$40 + IntToBin(SysPassword, 4));
end;

(******************************************************************************

  �������� ����� � ��������
  �������:	41H. ����� ���������: 5 ����.
  �	������ �������������� ��� ���������� �������������� (4 �����)
  �����:		41H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 29, 30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintZReport;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintZReport');
  Execute(#$41 + IntToBin(SysPassword, 4));
end;

(******************************************************************************

  ����� �� �������
  �������:	42H. ����� ���������: 5 ����.
  �	������ �������������� ��� ���������� �������������� (4 �����)
  �����:		42H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 29, 30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintDepartmentsReport;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintDepartmentsReport');
  Execute(#$42 + IntToBin(SysPassword, 4));
end;

(******************************************************************************

  ����� �� �������
  �������:	43H. ����� ���������: 5 ����.
  �	������ �������������� ��� ���������� �������������� (4 �����)
  �����:		43H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 29, 30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintTaxReport;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintTaxReport');
  Execute(#$43 + IntToBin(SysPassword, 4));
end;

(******************************************************************************

  ������ �����
  �������:	52H. ����� ���������: 5 ����.
  �	������ ��������� (4 �����)
  �����:		52H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintHeader;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintHeader');
  Execute(#$43 + IntToBin(UsrPassword, 4));
end;

(******************************************************************************

  ����� ���������
  �������:	53H. ����� ���������: 6 ����.
  �	������ ��������� (4 �����)
  �	�������� (1 ����)
  �	0- ��� ���������� ������
  �	1 - � ��������� ������
  �����:		53H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintDocTrailer(Flags: Byte);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.PrintDocTrailer(%d)', [Flags]));
  Execute(#$53 + IntToBin(UsrPassword, 4) + Chr(Flags));
end;

(******************************************************************************

  ������ ���������� ������
  �������:	54H. ����� ���������:5 ����.
  �	������ ��������� (4 �����)
  �����:		54H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

procedure TFiscalPrinterCommand.PrintTrailer;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintTrailer');
  Execute(#$54 + IntToBin(UsrPassword, 4));
end;

(******************************************************************************

  ���� ���������� ������
  �������:	60H. ����� ���������: 9 ����.
  �	������ (4 �����) (������ "0")
  �	��������� ����� (4 �����) 00000000�99999999
  �����:		60H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.WriteSerial(Serial: DWORD);
begin
  Logger.Debug(Format('TFiscalPrinterCommand.WriteSerial(%d)', [Serial]));
  Execute(#$60 + IntToBin(0, 4) + IntToBin(Serial, 4));
end;

(******************************************************************************

  ������������� ��
  �������:	61H. ����� ���������: 1 ����.
  �����:		61H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.InitFiscalMemory;
begin
  Logger.Debug('TFiscalPrinterCommand.InitFiscalMemory');
  Execute(#$61);
end;

(******************************************************************************

������ ����� ������� � ��
�������:	62H. ����� ���������: 6 ����.
�	������ �������������� ��� ���������� �������������� (4 �����)
�	��� ������� (1 ����) "0" - ����� ���� �������, "1" - ����� ������� ����� ��������� ���������������
�����:		62H. ����� ���������: 29 ����.
�	��� ������ (1 ����)
�	���������� ����� ��������� (1 ����) 29, 30
�	����� ������� ������ ������ (8 ����)
�	����� ������� ���� ������� (6 ����) ��� ���������� �� 2: FFh FFh FFh FFh FFh FFh
�	����� ������� ��������� ������ (6 ����) ��� ���������� �� 2: FFh FFh FFh FFh FFh FFh
�	����� ������� ��������� ������� (6 ����) ��� ���������� �� 2: FFh FFh FFh FFh FFh FFh

******************************************************************************)

function TFiscalPrinterCommand.ReadFMTotals(Flags: Byte): TFMTotals;
var
  Data: string;
  Stream: TBinStream;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReadFMTotals(%d)', [Flags]));

  Data := Execute(#$62 + IntToBin(SysPassword, 4) + Chr(Flags));
  CheckMinLength(Data, 27);

  Stream := TBinStream.Create;
  try
    Stream.Data := Data;
    Result.OperatorNumber := Stream.ReadByte;
    Result.SaleTotal := Stream.ReadInt(8);
    Result.BuyTotal := Stream.ReadInt(6);
    Result.RetSale := Stream.ReadInt(6);
    Result.RetBuy := Stream.ReadInt(6);
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������ ���� ��������� ������ � ��
  �������:	63H. ����� ���������: 5 ����.
  �	������ ���������� ���������� (4 �����)
  �����:		63H. ����� ���������: 7 ����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 29, 30
  �	��� ��������� ������ (1 ����) "0" - ������������ (���������������), "1" - ������� ����
  �	���� (3 �����) ��-��-��

******************************************************************************)

function TFiscalPrinterCommand.ReadFMLastRecordDate: TFMRecordDate;
var
  Data: string;
begin
  Logger.Debug('TFiscalPrinterCommand.ReadFMLastRecordDate');

  Data := Execute(#$63 + IntToBin(TaxPassword, 4));
  CheckMinLength(Data, Sizeof(Result));
  Move(Data[1], Result, Sizeof(Result));
end;

(******************************************************************************

  ������ ��������� ��� � ����
  �������:	64H. ����� ���������: 5 ����.
  �	������ ���������� ���������� (4 �����)
  �����:		64H. ����� ���������: 12 ����.
  �	��� ������ (1 ����)
  �	���� ������ ����� (3 �����) ��-��-��
  �	���� ��������� ����� (3 �����) ��-��-��
  �	����� ������ ����� (2 �����) 0000�2100
  �	����� ��������� ����� (2 �����) 0000�2100

******************************************************************************)

function TFiscalPrinterCommand.ReadShiftsRange: TShiftRange;
var
  Data: string;
begin
  Logger.Debug('TFiscalPrinterCommand.ReadShiftsRange');

  Data := Execute(#$64 + IntToBin(TaxPassword, 4));
  CheckMinLength(Data, Sizeof(Result));
  Move(Data[1], Result, Sizeof(Result));
end;

(******************************************************************************

  ������������ (���������������)
  �������:	65H. ����� ���������: 20 ����.
  �	������ ������ (4 �����)
  �	������ ����� (4 �����)
  �	��� (5 ����) 0000000000�9999999999
  �	��� (6 ����) 000000000000�999999999999
  �����:		65H. ����� ���������: 9 ����.
  �	��� ������ (1 ����)
  �	����� ������������ (���������������) (1 ����) 1�16
  �	���������� ���������� ��������������� (1 ����) 0�15
  �	����� ��������� �������� ����� (2 �����) 0000�2100
  �	���� ������������ (���������������) (3 �����) ��-��-��

******************************************************************************)

function TFiscalPrinterCommand.Fiscalization(Password, PrinterID,
  FiscalID: Int64): TFiscalizationResult;
var
  Data: string;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.Fiscalization(%d,%d,%d)',
    [Password, PrinterID, FiscalID]));

  Data := Execute(#$65 +
    IntToBin(TaxPassword, 4) +
    IntToBin(Password, 4) +
    IntToBin(PrinterID, 4) +
    IntToBin(FiscalID, 4));

  CheckMinLength(Data, Sizeof(Result));
  Move(Data[1], Result, Sizeof(Result));
end;

(******************************************************************************

  ���������� ����� �� ��������� ���

  �������:	66H. ����� ���������: 12 ����.
  �	������ ���������� ���������� (4 �����)
  �	��� ������ (1 ����) "0" - ��������, "1" - ������
  �	���� ������ ����� (3 �����) ��-��-��
  �	���� ��������� ����� (3 �����) ��-��-��
  �����:		66H. ����� ���������: 12 ����.
  �	��� ������ (1 ����)
  �	���� ������ ����� (3 �����) ��-��-��
  �	���� ��������� ����� (3 �����) ��-��-��
  �	����� ������ ����� (2 �����) 0000�2100
  �	����� ��������� ����� (2 �����) 0000�2100

******************************************************************************)

function TFiscalPrinterCommand.ReportOnDateRange(ReportType: Byte;
  Range: TShiftDateRange): TShiftRange;
var
  Data: string;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReportOnDateRange(%d,%s,%s)',
    [ReportType, PrinterDateToStr(Range.Date1), PrinterDateToStr(Range.Date2)]));

  Data := Execute(#$66 +
    IntToBin(TaxPassword, 4) +
    Chr(ReportType) +
    PrinterDateToBin(Range.Date1) +
    PrinterDateToBin(Range.Date2));

  CheckMinLength(Data, Sizeof(Result));
  Move(Data[1], Result, Sizeof(Result));
end;

(******************************************************************************

  ���������� ����� �� ��������� ����

  �������:	67H. ����� ���������: 10 ����.
  �	������ ���������� ���������� (4 �����)
  �	��� ������ (1 ����) "0" - ��������, "1" - ������
  �	����� ������ ����� (2 �����) 0000�2100
  �	����� ��������� ����� (2 �����) 0000�2100
  �����:		67H. ����� ���������: 12 ����.
  �	��� ������ (1 ����)
  �	���� ������ ����� (3 �����) ��-��-��
  �	���� ��������� ����� (3 �����) ��-��-��
  �	����� ������ ����� (2 �����) 0000�2100
  �	����� ��������� ����� (2 �����) 0000�2100

******************************************************************************)

function TFiscalPrinterCommand.ReportOnNumberRange(ReportType: Byte;
  Range: TShiftNumberRange): TShiftRange;
var
  Data: string;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReportOnDateRange(%d,%d,%d)',
    [ReportType, Range.Number1, Range.Number2]));

  Data := Execute(#$67 +
    IntToBin(TaxPassword, 4) +
    Chr(ReportType) +
    IntToBin(Range.Number1, 2) +
    IntToBin(Range.Number2, 2));

  CheckMinLength(Data, Sizeof(Result));
  Move(Data[1], Result, Sizeof(Result));
end;

(******************************************************************************

  ���������� ������� ������
  �������:	68H. ����� ���������: 5 ����.
  �	������ ���������� ���������� (4 �����)
  �����:		68H. ����� ���������: 2 �����.
  �	��� ������ (1 ����)

******************************************************************************)

procedure TFiscalPrinterCommand.InterruptReport;
begin
  Logger.Debug('TFiscalPrinterCommand.InterruptReport');

  Execute(#$68 + IntToBin(TaxPassword, 4));
end;

(******************************************************************************

������ ���������� ������������ (���������������)
�������:	69H. ����� ���������: 6 ����.
�	������ ���������� ����������, ��� ������� ���� ��������� ������ ������������ (4 �����)
�	����� ������������ (���������������) (1 ����) 1�16
�����:		69H. ����� ���������: 22 �����.
�	��� ������ (1 ����)
�	������ (4 �����)
�	��� (5 ����) 0000000000�9999999999
�	��� (6 ����) 000000000000�999999999999
�	����� ����� ����� ������������� (����������������) (2 �����) 0000�2100
�	���� ������������ (���������������) (3 �����) ��-��-��

******************************************************************************)

function TFiscalPrinterCommand.ReadFiscInfo(FiscNumber: Byte): TFiscInfo;
var
  Stream: TBinStream;
begin
  Logger.Debug(Format('TFiscalPrinterCommand.ReadFiscInfo((%d)',
    [FiscNumber]));

  Stream := TBinStream.Create;
  try
    Stream.Data := Execute(#$69 + IntToBin(TaxPassword, 4) + Chr(FiscNumber));

    Result.Password := Stream.ReadInt(4);
    Result.PrinterID := Stream.ReadInt(5);
    Result.FiscalID := Stream.ReadInt(6);
    Result.ShiftNumber := Stream.ReadInt(2);
    Stream.Read(Result.Date, Sizeof(Result.Date));
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������� ���������� ���������� ��������
  �������:	70H. ����� ���������: 26 ����.
  �	������ ��������� (4 �����)
  �	��� ��������� (1 ����) "0" - �������, "1" - �������, "2" - ������� �������, "3" - ������� �������
  �	������������ ������ (���������, ���������) (1 ����) "0" - �������, "1" - ����� �����
  �	���������� ������ (1 ����) 0�5
  �	�������� ����� ���������� � 1-�� ������ ������ (1 ����) *
  �	�������� ����� 1-�� � 2-�� ������� ������ (1 ����) *
  �	�������� ����� 2-�� � 3-�� ������� ������ (1 ����) *
  �	�������� ����� 3-�� � 4-�� ������� ������ (1 ����) *
  �	�������� ����� 4-�� � 5-�� ������� ������ (1 ����) *
  �	����� ������ ����� (1 ����)
  �	����� ������ ��������� ��������� (1 ����)
  �	����� ������ ������ ���� (1 ����)
  �	����� ������ �������� ��� � ������ ��� (1 ����)
  �	����� ������ ����� (1 ����)
  �	����� ������ ��������� ��������� (1 ����)
  �	����� ������ ������ ���� (1 ����)
  �	����� ������ �������� ������� ��������� (1 ����)
  �	�������� ����� � ������ (1 ����)
  �	�������� ��������� ��������� � ������ (1 ����)
  �	�������� ������ ���� � ������ (1 ����)
  �	�������� ��� � ������ ��� � ������ (1 ����)
  �	�������� �������� ������� ��������� � ������ (1 ����)
  �����:		70H. ����� ���������: 5 ����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30
  �	�������� ����� ��������� (2 �����)

******************************************************************************)

function TFiscalPrinterCommand.OpenSlipDoc(Params: TSlipParams): TDocResult;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.OpenSlipDoc');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($70);
    Stream.WriteDWORD(UsrPassword);
    Stream.Write(Params, Sizeof(Params));
    Check(ExecuteStream(Stream));
    Stream.Read(Result, Sizeof(Result));
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

������� ����������� ���������� ���������� ��������
�������:	71H. ����� ���������: 13 ����.
�	������ ��������� (4 �����)
�	��� ��������� (1 ����) "0" - �������, "1" - �������, "2" - ������� �������, "3" - ������� �������
�	������������ ������ (���������, ���������) (1 ����) "0" - �������, "1" - ����� �����
�	���������� ������ (1 ����) 0�5
�	�������� ����� ���������� � 1-�� ������ ������ (1 ����) *
�	�������� ����� 1-�� � 2-�� ������� ������ (1 ����) *
�	�������� ����� 2-�� � 3-�� ������� ������ (1 ����) *
�	�������� ����� 3-�� � 4-�� ������� ������ (1 ����) *
�	�������� ����� 4-�� � 5-�� ������� ������ (1 ����) *
�����:		71H. ����� ���������: 5 ����.
�	��� ������ (1 ����)
�	���������� ����� ��������� (1 ����) 1�30
�	�������� ����� ��������� (2 �����)

******************************************************************************)

function TFiscalPrinterCommand.OpenStdSlip(Params: TStdSlipParams): TDocResult;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.OpenStdSlip');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($71);
    Stream.WriteDWORD(UsrPassword);
    Stream.Write(Params, Sizeof(Params));
    Check(ExecuteStream(Stream));
    Stream.Read(Result, Sizeof(Result));
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������������ �������� �� ���������� ���������
  �������:	72H. ����� ���������: 82 �����.
  �	������ ��������� (4 �����)
  �	������ ������ ���������� (1 ����) "0" - ��� ���� ����� �������, "1" - � ������� ����� �������
  �	���������� ����� � �������� (1 ����) 1�3
  �	����� ��������� ������ � �������� (1 ����) 0�3, "0" - �� ��������
  �	����� ������ ������������ ���������� �� ���� � �������� (1 ����) 0�3, "0" - �� ��������
  �	����� ������ ����� � �������� (1 ����) 1�3
  �	����� ������ ������ � �������� (1 ����) 1�3
  �	����� ������ ��������� ������ (1 ����)
  �	����� ������ ���������� (1 ����)
  �	����� ������ ����� ��������� ���������� �� ���� (1 ����)
  �	����� ������ ���� (1 ����)
  �	����� ������ ����� (1 ����)
  �	����� ������ ������ (1 ����)
  �	���������� �������� ���� ��������� ������ (1 ����)
  �	���������� �������� ���� ���������� (1 ����)
  �	���������� �������� ���� ���� (1 ����)
  �	���������� �������� ���� ����� (1 ����)
  �	���������� �������� ���� ������ (1 ����)
  �	�������� ���� ��������� ������ � ������ (1 ����)
  �	�������� ���� ������������ ���������� �� ���� � ������ (1 ����)
  �	�������� ���� ����� � ������ (1 ����)
  �	�������� ���� ������ � ������ (1 ����)
  �	����� ������ �� � ������ ������� ����� �������� (1 ����)
  �	���������� (5 ����)
  �	���� (5 ����)
  �	����� (1 ����) 0�16
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		72H. ����� ���������: 3 ����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.SlipOperation(Params: TSlipOperation;
  Operation: TPriceReg): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.SlipOperation');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($72);
    Stream.WriteDWORD(UsrPassword);
    Stream.Write(Params, Sizeof(Params));
    Stream.WriteInt(Operation.Quantity, 5);
    Stream.WriteInt(Operation.Price, 5);
    Stream.WriteInt(Operation.Department, 1);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

������������ ����������� �������� �� ���������� ���������
�������:	73H. ����� ���������: 61 ����.
�	������ ��������� (4 �����)
�	����� ������ �� � ������ ������� ����� �������� (1 ����)
�	���������� (5 ����)
�	���� (5 ����)
�	����� (1 ����) 0�16
�	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� (40 ����)
�����:		73H. ����� ���������: 3 �����.
�	��� ������ (1 ����)
�	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.SlipStdOperation(LineNumber: Byte;
  Operation: TPriceReg): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.SlipStdOperation');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($73);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteByte(LineNumber);
    Stream.WriteInt(Operation.Quantity, 5);
    Stream.WriteInt(Operation.Price, 5);
    Stream.WriteInt(Operation.Department, 1);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������������ ������/�������� �� ���������� ���������
  �������:	74H. ����� ���������: 68 ����.
  �	������ ��������� (4 �����)
  �	���������� ����� � �������� (1 ����) 1�2
  �	����� ��������� ������ � �������� (1 ����) 0�2, "0" - �� ��������
  �	����� ������ �������� �������� � �������� (1 ����) 1�2
  �	����� ������ ����� � �������� (1 ����) 1�2
  �	����� ������ ��������� ������ (1 ����)
  �	����� ������ �������� �������� (1 ����)
  �	����� ������ ����� (1 ����)
  �	���������� �������� ���� ��������� ������ (1 ����)
  �	���������� �������� ���� ����� (1 ����)
  �	�������� ���� ��������� ������ � ������ (1 ����)
  �	�������� ���� �������� �������� � ������ (1 ����)
  �	�������� ���� ����� � ������ (1 ����)
  �	��� �������� (1 ����) "0" - ������, "1" - ��������
  �	����� ������ �� � ������ ������� ����� ������/�������� (1 ����)
  �	����� (5 ����)
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		74H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.SlipDiscount(Params: TSlipDiscountParams;
  Discount: TSlipDiscount): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.SlipDiscount');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($74);
    Stream.WriteDWORD(UsrPassword);
    Stream.Write(Params, Sizeof(Params));
    Stream.WriteByte(Discount.OperationType);
    Stream.WriteByte(Discount.LineNumber);
    Stream.WriteInt(Discount.Amount, 5);
    Stream.WriteInt(Discount.Department, 1);
    Stream.WriteInt(Discount.Tax1, 1);
    Stream.WriteInt(Discount.Tax2, 1);
    Stream.WriteInt(Discount.Tax3, 1);
    Stream.WriteInt(Discount.Tax4, 1);
    Stream.WriteString(Discount.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������������ ����������� ������/�������� �� ���������� ���������
  �������:	75H. ����� ���������: 56 ����.
  �	������ ��������� (4 �����)
  �	��� �������� (1 ����) "0" - ������, "1" - ��������
  �	����� ������ �� � ������ ������� ����� ������/�������� (1 ����)
  �	����� (5 ����)
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		75H. ����� ���������: 3 ����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.SlipStdDiscount(Discount: TSlipDiscount): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.SlipStdDiscount');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($75);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteByte(Discount.OperationType);
    Stream.WriteByte(Discount.LineNumber);
    Stream.WriteInt(Discount.Amount, 5);
    Stream.WriteInt(Discount.Department, 1);
    Stream.WriteInt(Discount.Tax1, 1);
    Stream.WriteInt(Discount.Tax2, 1);
    Stream.WriteInt(Discount.Tax3, 1);
    Stream.WriteInt(Discount.Tax4, 1);
    Stream.WriteString(Discount.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

������������ �������� ���� �� ���������� ���������
�������:	76H. ����� ���������: 182 �����.
�	������ ��������� (4 �����)
�	���������� ����� � �������� (1 ����) 1�17
�	����� ������ ����� � �������� (1 ����) 1�17
�	����� ��������� ������ � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ �������� � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ���� ������ 2 � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ���� ������ 3 � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ���� ������ 4 � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ����� � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ������� �� ������ � � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ������� �� ������ � � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ������� �� ������ � � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ������� �� ������ � � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ����� �� ������ � � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ����� �� ������ � � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ����� �� ������ � � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ����� �� ������ � � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ����� �� ���������� ������ � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ����� ������ � �������� (1 ����) 0�17, "0" - �� ��������
�	����� ������ ��������� ������ (1 ����)
�	����� ������ "����" (1 ����)
�	����� ������ ����� ����� (1 ����)
�	����� ������ "���������" (1 ����)
�	����� ������ ����� �������� (1 ����)
�	����� ������ �������� ���� ������ 2 (1 ����)
�	����� ������ ����� ���� ������ 2 (1 ����)
�	����� ������ �������� ���� ������ 3 (1 ����)
�	����� ������ ����� ���� ������ 3 (1 ����)
�	����� ������ �������� ���� ������ 4 (1 ����)
�	����� ������ ����� ���� ������ 4 (1 ����)
�	����� ������ "�����" (1 ����)
�	����� ������ ����� ����� (1 ����)
�	����� ������ �������� ������ � (1 ����)
�	����� ������ ������� ������ � (1 ����)
�	����� ������ ������ ������ � (1 ����)
�	����� ������ ����� ������ � (1 ����)
�	����� ������ �������� ������ � (1 ����)
�	����� ������ ������� ������ � (1 ����)
�	����� ������ ������ ������ � (1 ����)
�	����� ������ ����� ������ � (1 ����)
�	����� ������ �������� ������ � (1 ����)
�	����� ������ ������� ������ � (1 ����)
�	����� ������ ������ ������ � (1 ����)
�	����� ������ ����� ������ � (1 ����)
�	����� ������ �������� ������ � (1 ����)
�	����� ������ ������� ������ � (1 ����)
�	����� ������ ������ ������ � (1 ����)
�	����� ������ ����� ������ � (1 ����)
�	����� ������ "�����" (1 ����)
�	����� ������ ����� �� ���������� ������ (1 ����)
�	����� ������ "������ ��.�� %" (1 ����)
�	����� ������ ����� ������ �� ��� (1 ����)
�	���������� �������� ���� ��������� ������ (1 ����)
�	���������� �������� ���� ����� ����� (1 ����)
�	���������� �������� ���� ����� �������� (1 ����)
�	���������� �������� ���� ����� ���� ������ 2 (1 ����)
�	���������� �������� ���� ����� ���� ������ 3 (1 ����)
�	���������� �������� ���� ����� ���� ������ 4 (1 ����)
�	���������� �������� ���� ����� ����� (1 ����)
�	���������� �������� ���� �������� ������ � (1 ����)
�	���������� �������� ���� ������� ������ � (1 ����)
�	���������� �������� ���� ������ ������ � (1 ����)
�	���������� �������� ���� ����� ������ � (1 ����)
�	���������� �������� ���� �������� ������ � (1 ����)
�	���������� �������� ���� ������� ������ � (1 ����)
�	���������� �������� ���� ������ ������ � (1 ����)
�	���������� �������� ���� ����� ������ � (1 ����)
�	���������� �������� ���� �������� ������ � (1 ����)
�	���������� �������� ���� ������� ������ � (1 ����)
�	���������� �������� ���� ������ ������ � (1 ����)
�	���������� �������� ���� ����� ������ � (1 ����)
�	���������� �������� ���� �������� ������ � (1 ����)
�	���������� �������� ���� ������� ������ � (1 ����)
�	���������� �������� ���� ������ ������ � (1 ����)
�	���������� �������� ���� ����� ������ � (1 ����)
�	���������� �������� ���� ����� �� ���������� ������ (1 ����)
�	���������� �������� ���� ���������� ������ �� ��� (1 ����)
�	���������� �������� ���� ����� ������ �� ��� (1 ����)
�	�������� ���� ��������� ������ � ������ (1 ����)
�	�������� ���� "����" � ������ (1 ����)
�	�������� ���� ����� ����� � ������ (1 ����)
�	�������� ���� "���������" � ������ (1 ����)
�	�������� ���� ����� �������� � ������ (1 ����)
�	�������� ���� �������� ���� ������ 2 � ������ (1 ����)
�	�������� ���� ����� ���� ������ 2 � ������ (1 ����)
�	�������� ���� �������� ���� ������ 3 � ������ (1 ����)
�	�������� ���� ����� ���� ������ 3 � ������ (1 ����)
�	�������� ���� �������� ���� ������ 4 � ������ (1 ����)
�	�������� ���� ����� ���� ������ 4 � ������ (1 ����)
�	�������� ���� "�����" � ������ (1 ����)
�	�������� ���� ����� ����� � ������ (1 ����)
�	�������� ���� �������� ������ � � ������ (1 ����)
�	�������� ���� ������� ������ � � ������ (1 ����)
�	�������� ���� ������ ������ � � ������ (1 ����)
�	�������� ���� ����� ������ � � ������ (1 ����)
�	�������� ���� �������� ������ � � ������ (1 ����)
�	�������� ���� ������� ������ � � ������ (1 ����)
�	�������� ���� ������ ������ � � ������ (1 ����)
�	�������� ���� ����� ������ � � ������ (1 ����)
�	�������� ���� �������� ������ � � ������ (1 ����)
�	�������� ���� ������� ������ � � ������ (1 ����)
�	�������� ���� ������ ������ � � ������ (1 ����)
�	�������� ���� ����� ������ � � ������ (1 ����)
�	�������� ���� �������� ������ � � ������ (1 ����)
�	�������� ���� ������� ������ � � ������ (1 ����)
�	�������� ���� ������ ������ � � ������ (1 ����)
�	�������� ���� ����� ������ � � ������ (1 ����)
�	�������� ���� "�����" � ������ (1 ����)
�	�������� ���� ����� �� ���������� ������ � ������ (1 ����)
�	�������� ���� "������ ��.�� %" � ������ (1 ����)
�	�������� ���� ����� ������ � ������ (1 ����)
�	����� ������ �� � ������ ������� ����� �������� (1 ����)
�	����� �������� (5 ����)
�	����� ���� ������ 2 (5 ����)
�	����� ���� ������ 3 (5 ����)
�	����� ���� ������ 4 (5 ����)
�	������ � % �� ��� �� 0 �� 99,99 % (2 �����) 0000�9999
�	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� (40 ����)
�����:		76H. ����� ���������: 8 ����.
�	��� ������ (1 ����)
�	���������� ����� ��������� (1 ����) 1�30
�	����� (5 ����) 0000000000�9999999999

******************************************************************************)

function TFiscalPrinterCommand.SlipClose(Params: TCloseReceiptParams): TCloseReceiptResult;
begin
  Logger.Debug('TFiscalPrinterCommand.SlipClose');
(*
  Stream := TBinStream.Create;
  try
    Stream.WriteByte($76);
    Stream.WriteDWORD(UsrPassword);
    Stream.Write(Params, sizeof(Params));

    Stream.WriteByte(Discount.OperationType);
    Stream.WriteByte(Discount.LineNumber);
    Stream.WriteInt(Discount.Amount, 5);
    Stream.WriteInt(Discount.Department, 1);
    Stream.WriteInt(Discount.Tax1, 1);
    Stream.WriteInt(Discount.Tax2, 1);
    Stream.WriteInt(Discount.Tax3, 1);
    Stream.WriteInt(Discount.Tax4, 1);
    Stream.WriteString(Discount.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
  *)
end;


(******************************************************************************

  �������
  �������:	80H. ����� ���������: 60 ����.
  �	������ ��������� (4 �����)
  �	���������� (5 ����) 0000000000�9999999999
  �	���� (5 ����) 0000000000�9999999999
  �	����� ������ (1 ����) 0�16
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		80H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.Sale(Operation: TPriceReg): Integer;
var
  Stream: TBinStream;
begin

  Logger.Debug('TFiscalPrinterCommand.Sale');
  Stream := TBinStream.Create;
  try
    Stream.WriteByte($80);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Operation.Quantity, 5);
    Stream.WriteInt(Operation.Price, 5);
    Stream.WriteInt(Operation.Department, 1);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  �������
  �������:	81H. ����� ���������: 60 ����.
  �	������ ��������� (4 �����)
  �	���������� (5 ����) 0000000000�9999999999
  �	���� (5 ����) 0000000000�9999999999
  �	����� ������ (1 ����) 0�16
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		81H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.Buy(Operation: TPriceReg): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.Buy');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($81);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Operation.Quantity, 5);
    Stream.WriteInt(Operation.Price, 5);
    Stream.WriteInt(Operation.Department, 1);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������� �������
  �������:	82H. ����� ���������: 60 ����.
  �	������ ��������� (4 �����)
  �	���������� (5 ����) 0000000000�9999999999
  �	���� (5 ����) 0000000000�9999999999
  �	����� ������ (1 ����) 0�16
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		82H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.RetSale(Operation: TPriceReg): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.RetSale');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($82);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Operation.Quantity, 5);
    Stream.WriteInt(Operation.Price, 5);
    Stream.WriteInt(Operation.Department, 1);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������� �������
  �������:	83H. ����� ���������: 60 ����.
  �	������ ��������� (4 �����)
  �	���������� (5 ����) 0000000000�9999999999
  �	���� (5 ����) 0000000000�9999999999
  �	����� ������ (1 ����) 0�16
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		83H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.RetBuy(Operation: TPriceReg): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.RetBuy');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($83);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Operation.Quantity, 5);
    Stream.WriteInt(Operation.Price, 5);
    Stream.WriteInt(Operation.Department, 1);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������
  �������:	84H. ����� ���������: 60 ����.
  �	������ ��������� (4 �����)
  �	���������� (5 ����) 0000000000�9999999999
  �	���� (5 ����) 0000000000�9999999999
  �	����� ������ (1 ����) 0�16
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		84H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.Storno(Operation: TPriceReg): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.Storno');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($84);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Operation.Quantity, 5);
    Stream.WriteInt(Operation.Price, 5);
    Stream.WriteInt(Operation.Department, 1);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  �������� ����
  �������:	85H. ����� ���������: 71 ����.
  �	������ ��������� (4 �����)
  �	����� �������� (5 ����) 0000000000�9999999999
  �	����� ���� ������ 2 (5 ����) 0000000000�9999999999
  �	����� ���� ������ 3 (5 ����) 0000000000�9999999999
  �	����� ���� ������ 4 (5 ����) 0000000000�9999999999
  �	������/��������(� ������ �������������� ��������) � % �� ��� �� 0 �� 99,99 % (2 ����� �� ������) -9999�9999
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		85H. ����� ���������: 8 ����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30
  �	����� (5 ����) 0000000000�9999999999

******************************************************************************)

function TFiscalPrinterCommand.ReceiptClose(Params: TCloseReceiptParams): TCloseReceiptResult;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.ReceiptClose');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($85);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Params.CashAmount, 5);
    Stream.WriteInt(Params.Amount2, 5);
    Stream.WriteInt(Params.Amount3, 5);
    Stream.WriteInt(Params.Amount4, 5);
    Stream.WriteInt(Params.PercentDiscount, 2);
    Stream.WriteInt(Params.Tax1, 1);
    Stream.WriteInt(Params.Tax2, 1);
    Stream.WriteInt(Params.Tax3, 1);
    Stream.WriteInt(Params.Tax4, 1);
    Stream.WriteString(Params.Text, PrintWidth);
    Check(ExecuteStream(Stream));
    Stream.Read(Result, sizeof(Result));
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������
  �������:	86H. ����� ���������: 54 ����.
  �	������ ��������� (4 �����)
  �	����� (5 ����) 0000000000�9999999999
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		86H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.ReceiptDiscount(
  Operation: TAmountOperation): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.ReceiptDiscount');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($86);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Operation.Amount, 5);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ��������
  �������:	87H. ����� ���������: 54 ����.
  �	������ ��������� (4 �����)
  �	����� (5 ����) 0000000000�9999999999
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		87H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.ReceiptCharge(
  Operation: TAmountOperation): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.ReceiptCharge');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($87);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Operation.Amount, 5);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������������� ����
  �������:	88H. ����� ���������: 5 ����.
  �	������ ��������� (4 �����)
  �����:		88H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.ReceiptCancel: Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.ReceiptCancel');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($88);
    Stream.WriteDWORD(UsrPassword);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������� ����
  �������:	89H. ����� ���������: 5 ����.
  �	������ ��������� (4 �����)
  �����:		89H. ����� ���������: 8 ����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30
  �	������� ���� (5 ����) 0000000000�9999999999

******************************************************************************)

function TFiscalPrinterCommand.GetSubtotal: Int64;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.GetSubtotal');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($89);
    Stream.WriteDWORD(UsrPassword);
    Check(ExecuteStream(Stream));
    Stream.ReadByte;
    Result := Stream.ReadInt(5);
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

������ ������
�������:	8AH. ����� ���������: 54 �����.
�	������ ��������� (4 �����)
�	����� (5 ����) 0000000000�9999999999
�	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
�	����� (40 ����)
�����:		8AH. ����� ���������: 3 �����.
�	��� ������ (1 ����)
�	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.ReceiptStornoDiscount(
  Operation: TAmountOperation): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.ReceiptStornoDiscount');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($8A);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Operation.Amount, 5);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������ ��������
  �������:	8BH. ����� ���������: 54 �����.
  �	������ ��������� (4 �����)
  �	����� (5 ����) 0000000000�9999999999
  �	����� 1 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 2 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 3 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� 4 (1 ����) "0" - ���, "1"�"4" - ��������� ������
  �	����� (40 ����)
  �����:		8BH. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.ReceiptStornoCharge(
  Operation: TAmountOperation): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.ReceiptStornoCharge');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($8B);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Operation.Amount, 5);
    Stream.WriteInt(Operation.Tax1, 1);
    Stream.WriteInt(Operation.Tax2, 1);
    Stream.WriteInt(Operation.Tax3, 1);
    Stream.WriteInt(Operation.Tax4, 1);
    Stream.WriteString(Operation.Text, PrintWidth);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������ ���������
  �������:	8CH. ����� ���������: 5 ����.
  �	������ ��������� (4 �����)
  �����:		8CH. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.PrintReceiptCopy: Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintReceiptCopy');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($8C);
    Stream.WriteDWORD(UsrPassword);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������� ���
  �������:	8DH. ����� ���������: 6 ����.
  �	������ ��������� (4 �����)
  �	��� ��������� (1 ����):  0 - �������;
  1 - �������;
  2 - ������� �������;
  3 - ������� �������
  �����:		8DH. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.OpenReceipt(ReceiptType: Byte): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.OpenReceipt');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($8D);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteByte(ReceiptType);

    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ����������� ������
  �������:	B0H. ����� ���������: 5 ����.
  �	������ ���������, �������������� ��� ���������� �������������� (4 �����)
  �����:		B0H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.ContinuePrint: Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.ContinuePrint');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($B0);
    Stream.WriteDWORD(UsrPassword);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  �������� �������
  �������: 	C0H. ����� ���������: 46 ����.
  �	������ ��������� (4 �����)
  �	����� ����� (1 ����) 0�199
  �	����������� ���������� (40 ����)
  �����:		C0H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.LoadGraphics(Line: Byte; Data: string): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.LoadGraphics');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($C0);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteByte(Line);
    Stream.WriteString(Data, 40);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������ �������
  �������:	C1H. ����� ���������: 7 ����.
  �	������ ��������� (4 �����)
  �	��������� ����� (1 ����) 1�200
  �	�������� ����� (1 ����) 1�200
  �����:		�1H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.PrintGraphics(Line1, Line2: Byte): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintGraphics');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($C1);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteByte(Line1);
    Stream.WriteByte(Line2);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������ �����-����
  �������:	C2H. ����� ���������: 10 ����.
  �	������ ��������� (4 �����)
  �	�����-��� (5 ����) 000000000000�999999999999
  �����:		�2H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.PrintBarcode(Barcode: Int64): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintBarcode');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($C2);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Barcode, 5);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������ ����������� �������
  �������:	C3H. ����� ���������: 9 ����.
  �	������ ��������� (4 �����)
  �	��������� ����� (2 �����) 1�1200
  �	�������� ����� (2 �����) 1�1200
  �����:		C3H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.PrintGraphics2(Line1, Line2: Word): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintGraphics2');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($C3);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Line1, 2);
    Stream.WriteInt(Line2, 2);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  �������� ����������� �������
  �������: 	C4H. ����� ���������: 47 ����.
  �	������ ��������� (4 �����)
  �	����� ����� (2 �����) 0�1199
  �	����������� ���������� (40 ����)
  �����:		�4H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.LoadGraphics2(Line: Word; Data: string): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.LoadGraphics2');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($C4);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Line, 2);
    Stream.WriteString(Data, 40);
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  ������ �����
  �������: 	C5H. ����� ���������: X + 7 ����.
  �	������ ��������� (4 �����)
  �	���������� �������� (2 �����)
  �	����������� ���������� (X ����)
  �����:		C5H. ����� ���������: 3 �����.
  �	��� ������ (1 ����)
  �	���������� ����� ��������� (1 ����) 1�30

******************************************************************************)

function TFiscalPrinterCommand.PrintBarLine(Height: Word; Data: string): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.PrintBarLine');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($C5);
    Stream.WriteDWORD(UsrPassword);
    Stream.WriteInt(Height, 2);
    Stream.WriteString(Data, Length(Data));
    Check(ExecuteStream(Stream));
    Result := Stream.ReadByte;
  finally
    Stream.Free;
  end;
end;

(******************************************************************************

  �������� ��� ����������
  �������:	FCH. ����� ���������: 1 ����.
  �����:		FCH. ����� ���������: (8+X) ����.
  �	��� ������ (1 ����)
  �	��� ���������� (1 ����) 0�255
  �	������ ���������� (1 ����) 0�255
  �	������ ��������� ��� ������� ���������� (1 ����) 0�255
  �	��������� ��������� ��� ������� ���������� (1 ����) 0�255
  �	������ ���������� (1 ����) 0�255
  �	���� ���������� (1 ����) 0�255 ������� - 0; ���������� - 1;
  �	�������� ���������� - ������ �������� � ��������� WIN1251.
  ���������� ����, ��������� ��� �������� ����������, ������������ �
  ������ ���������� ������ �������������� �������������� ���������� (X ����)

******************************************************************************)

function TFiscalPrinterCommand.GetDeviceMetrics: TDeviceMetrics;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.GetDeviceMetrics');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($FC);
    Check(ExecuteStream(Stream));
    Result.DeviceType := Stream.ReadByte;
    Result.DeviceSubType := Stream.ReadByte;
    Result.ProtocolVersion := Stream.ReadByte;
    Result.ProtocolSubVersion := Stream.ReadByte;
    Result.Model := Stream.ReadByte;
    Result.Language := Stream.ReadByte;
    Result.DeviceName := Stream.ReadString;
  finally
    Stream.Free;
  end;
  FPrintWidth := GetModelDescription(Result.Model).PrintWidth;
end;

function TFiscalPrinterCommand.FieldToInt(FieldInfo: TPrinterFieldRec;
  const Value: string): Integer;
begin
  case FieldInfo.FieldType of
    PRINTER_FIELD_TYPE_INT: Result := BinToInt(Value, 1, FieldInfo.Size);
    PRINTER_FIELD_TYPE_STR: raise Exception.Create('Field type is not integer');
  else
    raise Exception.Create('Invalid field type');
  end;
end;

function TFiscalPrinterCommand.FieldToStr(FieldInfo: TPrinterFieldRec;
  const Value: string): string;
begin
  case FieldInfo.FieldType of
    PRINTER_FIELD_TYPE_INT: raise Exception.Create('Field type is not string');
    PRINTER_FIELD_TYPE_STR: Result := Value;
  else
    raise Exception.Create('Invalid field type');
  end;
end;

function TFiscalPrinterCommand.GetFieldValue(FieldInfo: TPrinterFieldRec; const Value: string): string;
begin
  case FieldInfo.FieldType of
    PRINTER_FIELD_TYPE_INT: Result := IntToBin(StrToInt(Value), FieldInfo.Size);
    PRINTER_FIELD_TYPE_STR: Result := GetLineLength(Value, FieldInfo.Size);
  else
    raise Exception.Create('Invalid field type');
  end;
end;

procedure TFiscalPrinterCommand.WriteTable(Table, Row, Field: Integer;
  const FieldValue: string);
var
  Data: string;
  FieldInfo: TPrinterFieldRec;
begin
  FieldInfo := ReadFieldStructure(Table, Field);
  Data := GetFieldValue(FieldInfo, FieldValue);
  DoWriteTable(Table, Row, Field, Data);
end;

procedure TFiscalPrinterCommand.WriteTableInt(Table, Row, Field, Value: Integer);
begin
  WriteTable(Table, Row, Field, IntToStr(Value));
end;

function TFiscalPrinterCommand.ReadTableInt(Table, Row, Field: Integer): Integer;
var
  Data: string;
  FieldInfo: TPrinterFieldRec;
begin
  FieldInfo := ReadFieldStructure(Table, Field);
  Data := ReadTableBin(Table, Row, Field);
  Result := FieldToInt(FieldInfo, Data);
end;

function TFiscalPrinterCommand.ReadTableStr(Table, Row, Field: Integer): string;
var
  Data: string;
  FieldInfo: TPrinterFieldRec;
begin
  FieldInfo := ReadFieldStructure(Table, Field);
  Data := ReadTableBin(Table, Row, Field);
  Result := TrimRight(FieldToStr(FieldInfo, Data));
end;

(*******************************************************************************

  ������ ����� ������ � �����

  185, ���������� ������ � ������ � �����
  186, ���������� ������ � ������� � �����
  187, ���������� ������ � �������� ������ � �����
  188, ���������� ������ � �������� ������� � �����

*******************************************************************************)

function TFiscalPrinterCommand.GetDayDiscountTotal: Int64;
begin
  Result :=
    ReadCashTotalizer(185) +
    ReadCashTotalizer(188) -
    ReadCashTotalizer(186) -
    ReadCashTotalizer(187);
end;

(*******************************************************************************

  ���������� ������ � ����

  64, ���������� ������ � ������ � ����
  65, ���������� ������ � ������� � ����
  66, ���������� ������ � �������� ������ � ����
  67, ���������� ������ � �������� ������� � ����

*******************************************************************************)

function TFiscalPrinterCommand.GetRecDiscountTotal: Int64;
begin
  Result :=
    ReadCashTotalizer(64) +
    ReadCashTotalizer(67) -
    ReadCashTotalizer(65) -
    ReadCashTotalizer(66);
end;

(*******************************************************************************

  ���������� ������ � �����

    121, ���������� ������ � 1 ����� � �����
    125, ���������� ������ � 2 ����� � �����
    129, ���������� ������ � 3 ����� � �����
    133, ���������� ������ � 4 ����� � �����
    137, ���������� ������ � 5 ����� � �����
    141, ���������� ������ � 6 ����� � �����
    145, ���������� ������ � 7 ����� � �����
    149, ���������� ������ � 8 ����� � �����
    153, ���������� ������ � 9 ����� � �����
    157, ���������� ������ � 10 ����� � �����
    161, ���������� ������ � 11 ����� � �����
    165, ���������� ������ � 12 ����� � �����
    169, ���������� ������ � 13 ����� � �����
    173, ���������� ������ � 14 ����� � �����
    177, ���������� ������ � 15 ����� � �����
    181, ���������� ������ � 16 ����� � �����

*******************************************************************************)

function TFiscalPrinterCommand.GetDayItemTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + ReadCashTotalizer(121 + 4*i);
end;

(*******************************************************************************

  ���������� ������ � ����

    0, ���������� ������ � 1 ����� � ����
    4, ���������� ������ � 2 ����� � ����
    8, ���������� ������ � 3 ����� � ����
    12, ���������� ������ � 4 ����� � ����
    16, ���������� ������ � 5 ����� � ����
    20, ���������� ������ � 6 ����� � ����
    24, ���������� ������ � 7 ����� � ����
    28, ���������� ������ � 8 ����� � ����
    32, ���������� ������ � 9 ����� � ����
    36, ���������� ������ � 10 ����� � ����
    40, ���������� ������ � 11 ����� � ����
    44, ���������� ������ � 12 ����� � ����
    48, ���������� ������ � 13 ����� � ����
    52, ���������� ������ � 14 ����� � ����
    56, ���������� ������ � 15 ����� � ����
    60, ���������� ������ � 16 ����� � ����

*******************************************************************************)

function TFiscalPrinterCommand.GetRecItemTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + ReadCashTotalizer(4*i);
end;

(*******************************************************************************

  ���������� ��������� ������ � �����

    123, ���������� ��������� ������ � 1 ����� � �����
    127, ���������� ��������� ������ � 2 ����� � �����
    131, ���������� ��������� ������ � 3 ����� � �����
    135, ���������� ��������� ������ � 4 ����� � �����
    139, ���������� ��������� ������ � 5 ����� � �����
    143, ���������� ��������� ������ � 6 ����� � �����
    147, ���������� ��������� ������ � 7 ����� � �����
    151, ���������� ��������� ������ � 8 ����� � �����
    155, ���������� ��������� ������ � 9 ����� � �����
    159, ���������� ��������� ������ � 10 ����� � �����
    163, ���������� ��������� ������ � 11 ����� � �����
    167, ���������� ��������� ������ � 12 ����� � �����
    171, ���������� ��������� ������ � 13 ����� � �����
    175, ���������� ��������� ������ � 14 ����� � �����
    179, ���������� ��������� ������ � 15 ����� � �����
    183, ���������� ��������� ������ � 16 ����� � �����

*******************************************************************************)

function TFiscalPrinterCommand.GetDayItemVoidTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + ReadCashTotalizer(123 + 4*i);
end;

(*******************************************************************************

  ���������� ��������� ������ � ����

    2, ���������� ��������� ������ � 1 ����� � ����
    6, ���������� ��������� ������ � 2 ����� � ����
    10, ���������� ��������� ������ � 3 ����� � ����
    14, ���������� ��������� ������ � 4 ����� � ����
    18, ���������� ��������� ������ � 5 ����� � ����
    22, ���������� ��������� ������ � 6 ����� � ����
    26, ���������� ��������� ������ � 7 ����� � ����
    30, ���������� ��������� ������ � 8 ����� � ����
    34, ���������� ��������� ������ � 9 ����� � ����
    38, ���������� ��������� ������ � 10 ����� � ����
    42, ���������� ��������� ������ � 11 ����� � ����
    46, ���������� ��������� ������ � 12 ����� � ����
    50, ���������� ��������� ������ � 13 ����� � ����
    54, ���������� ��������� ������ � 14 ����� � ����
    58, ���������� ��������� ������ � 15 ����� � ����
    62, ���������� ��������� ������ � 16 ����� � ����

*******************************************************************************)

function TFiscalPrinterCommand.GetRecItemVoidTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + ReadCashTotalizer(2 + 4*i);
end;

(*******************************************************************************

  ������ � ���� ������ ����� �� ������ �����
  �������:	BAH. ����� ���������: 7 ����.
  "	������ ���������� �������������� (4 �����)
  "	����� ����� (2 �����) 0000�2100
  �����:		BAH. ����� ���������: 18 ����.
  "	��� ������ (1 ����)
  "	��� ��� - ������ �������� � ��������� WIN1251 (16 ����)
  ����������: ����� ���������� ������� - �� 40 ������.

*******************************************************************************)

function TFiscalPrinterCommand.GetEJSesssionResult(Number: Word;
  var Text: string): Integer;
var
  Data: string;
begin
  Data := #$BA + IntToBin(SysPassword, 4) + IntToBin(Number, 2);
  Result := ExecuteData(Data, Text);
end;

(*******************************************************************************

  ������ ������ ������ ����
  �������:	B3H. ����� ���������: 5 ����.
  "	������ ���������� �������������� (4 �����)
  �����:		B3H. ����� ���������: (2+�) ����.
  "	��� ������ (1 ����)
  "	������ ��� �������� ������ (��. ������������ ����) (X ����)

*******************************************************************************)

function TFiscalPrinterCommand.GetEJReportLine(var Line: string): Integer;
begin
  Result := ExecuteData(#$B3 + IntToBin(SysPassword, 4), Line);
end;

(*******************************************************************************

  ����������� ����
  �������:	ACH. ����� ���������: 5 ����.
  "	������ ���������� �������������� (4 �����)
  �����:		ACH. ����� ���������: 2 �����.
  "	��� ������ (1 ����)

*******************************************************************************)

function TFiscalPrinterCommand.EJReportStop: Integer;
var
  RxData: string;
begin
  Result := ExecuteData(#$AC + IntToBin(SysPassword, 4), RxData);
end;

function TFiscalPrinterCommand.DecodeEJFlags(Flags: Byte): TEJFlags;
begin
  Result.DocType := Flags and $03;      // bits 0,1
  Result.ArcOpened := TestBit(Flags, 2);
  Result.Activated := TestBit(Flags, 3);
  Result.ReportMode := TestBit(Flags, 4);
  Result.DocOpened := TestBit(Flags, 5);
  Result.DayOpened := TestBit(Flags, 6);
  Result.ErrorFlag := TestBit(Flags, 7);
end;

(*******************************************************************************

  ������ ��������� �� ���� 1 ����
  �������:	ADH. ����� ���������: 5 ����.
  "	������ ���������� �������������� (4 �����)
  �����:		ADH. ����� ���������: 22 �����.
  "	��� ������ (1 ����)
  "	���� ��������� ���������� ��� (5 ����) 0000000000�9999999999
  "	���� ���������� ��� (3 �����) ��-��-��
  "	����� ���������� ��� (2 �����) ��-��
  "	����� ���������� ��� (4 �����) 00000000�99999999
  "	����� ���� (5 ����) 0000000000�9999999999
  "	����� ���� (��. �������� ����) (1 ����)

*******************************************************************************)

function TFiscalPrinterCommand.GetEJStatus1(var Status: TEJStatus1): Integer;
var
  Stream: TBinStream;
begin
  Logger.Debug('TFiscalPrinterCommand.GetLongSerial');

  Stream := TBinStream.Create;
  try
    Stream.WriteByte($AC);
    Stream.WriteDWORD(SysPassword);
    Result := ExecuteStream(Stream);
    if Result = 0 then
    begin
      Status.DocAmount := Stream.ReadInt(5);
      Stream.Read(Status.DocDate, sizeof(Status.DocDate));
      Stream.Read(Status.DocTime, sizeof(Status.DocTime));
      Stream.Read(Status.DocNumber, sizeof(Status.DocNumber));
      Status.EJNumber := Stream.ReadInt(5);
      Status.Flags := DecodeEJFlags(Stream.ReadByte);
    end;
  finally
    Stream.Free;
  end;
end;

procedure TFiscalPrinterCommand.ClosePort;
begin
  Port.Close;
end;

procedure TFiscalPrinterCommand.OpenPort;
begin
  Port.Open;
end;

function TFiscalPrinterCommand.FormatLines(const Line1, Line2: string): string;
begin
  Result := FormatLineLength(Line1, PrintWidth - Length(Line2)) + Line2;
end;

function TFiscalPrinterCommand.FormatBoldLines(const Line1, Line2: string): string;
begin
  Result := FormatLineLength(Line1, (PrintWidth div 2) - Length(Line2)) + Line2;
end;

end.
