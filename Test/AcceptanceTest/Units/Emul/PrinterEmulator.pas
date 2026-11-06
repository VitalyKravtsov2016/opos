unit PrinterEmulator;

interface

uses
  Windows, Classes, SysUtils,
  FptrTypes, EmulBinUtils, EmulTables;

type
  TFptrTable = class;
  TFptrTables = class;
  TFptrCommand = class;
  TFptrCommands = class;
  TFptrPrintItem = class;
  TFptrPrintItems = class;

  { TFptrOperatorRec }

  TFptrOperatorRec = packed record
    Name: AnsiString;
    Password: Integer;
  end;

  { TFptrDepartmentRec }

  TFptrDepartmentRec = packed record
    Total: Int64;
  end;

  { TFptrReceipt }

  TFptrReceipt = class
  private
    FOpened: Boolean;
    FCharge: Int64;
    FDiscount: Int64;
    FRecType: Integer;
    FOperator: Integer;
    FOperations: Short;
    FDepartments: array [1..16] of TFptrDepartmentRec;

    procedure AddItem(AOperator: Integer; const Item: TFptrItemRec;
      ARecType: Integer);
    function GetDepartment(Value: Integer): Integer;
    function GetTotal: Int64;
  public
    procedure Reset;
    procedure Cancel(AOperator: Integer);
    procedure Open(AOperator, ARecType: Integer);
    procedure Buy(AOperator: Integer; const Item: TFptrItemRec);
    procedure Sale(AOperator: Integer; const Item: TFptrItemRec);
    procedure RetBuy(AOperator: Integer; const Item: TFptrItemRec);
    procedure RetSale(AOperator: Integer; const Item: TFptrItemRec);
    procedure Storno(AOperator: Integer; const Item: TFptrItemRec);
    function Close(AOperator: Integer; const Params: TFptrCloseReceipt): Int64;
    procedure MakeCharge(AOperator: Integer; const Charge: TFptrDiscount);
    procedure StornoCharge(AOperator: Integer; const Charge: TFptrDiscount);
    procedure MakeDiscount(AOperator: Integer; const Discount: TFptrDiscount);
    procedure StornoDiscount(AOperator: Integer; const Discount: TFptrDiscount);

    property Total: Int64 read GetTotal;
    property Opened: Boolean read FOpened;
    property RecType: Integer read FRecType;
    property Operator: Integer read FOperator;
    property Operations: Short read FOperations;
    property Charge: Int64 read FCharge;
    property Discount: Int64 read FDiscount;
  end;

  { TFptrEJournalRec }

  TFptrEJournalRec = packed record
    ErrorCode: Byte;
  end;

  { TFptrFirmwareRec }

  TFptrFirmwareRec = packed record
    Version: AnsiString;
    Build: Short;
    Date: TPrinterDate;
  end;

  { TFptrFiscalIDRec }

  TFptrFiscalIDRec = packed record
    Number: Int64;
    Valid: Boolean;
  end;

  { TFMRecord }

  TFMRecord = record
    RecType: Integer;
    Date: TPrinterDate;
  end;

  { TFMRecordResult }

  TFMRecordResult = record
    Operator: Byte;
    Data: TFMRecord;
  end;

  { TFptrFiscalMemoryRec }

  TFptrFiscalMemoryRec = packed record
    Flags: Byte;
    ErrorCode: Byte;
    Firmware: TFptrFirmwareRec;
    DayNumber: Short;
    FreeRecords: Short;
    FiscNumber: Short;
    LeftFiscNumber: Short;
    FiscalID: TFptrFiscalIDRec;

    SaleTotal: Int64;
    BuyTotal: Int64;
    RetSaleTotal: Int64;
    RetBuyTotal: Int64;

    GlobalSaleTotal: Int64;
    GlobalBuyTotal: Int64;
    GlobalRetSaleTotal: Int64;
    GlobalRetBuyTotal: Int64;


    LastRecord: TFMRecord;
  end;

  { TFptrSerialRec }

  TFptrSerialRec = packed record
    Valid: Boolean;
    Number: Integer;
  end;

  { TFptrPasswordRec }

  TFptrPasswordRec = packed record
    Valid: Boolean;
    Password: Integer;
  end;

  { TFptrLicenseRec }

  TFptrLicenseRec = record
    Valid: Boolean;
    Value: Int64;
  end;

  { TFptrPortRec }

  TFptrPortRec = record
    Number: Byte;
    BaudRate: Byte;
    Timeout: Byte;
  end;

  { TFptrAmountRegRec }

  TFptrAmountRegRec = record
    Operator: Byte;
    RegValue: Int64;
  end;

  { TFptrOperatingRegRec }

  TFptrOperatingRegRec = record
    Operator: Byte;
    RegValue: Word;
  end;

  { TFptrFieldRec }

  TFptrFieldRec = record
    Table: Integer;
    Row: Integer;
    Field: Integer;
    Value: AnsiString;
  end;

  { TFptrTableRec }

  TFptrTableRec = record
    Name: AnsiString;
    Number: Integer;
    RowCount: Integer;
    FieldCount: Integer;
  end;

  { TPrinterEmulator }

  TPrinterEmulator = class
  private
    FFlags: Short;
    FMode: Integer;
    FPort: TFptrPortRec;
    FStoreID: Integer;
    FSubMode: Integer;
    FDocNumber: Integer;
    FDate: TPrinterDate;
    FTime: TPrinterTime;
    FPortNumber: Integer;
    FReceipt: TFptrReceipt;
    FPowerVoltage: Integer;
    FSerial: TFptrSerialRec;
    FBatteryVoltage: Integer;
    FEJournal: TFptrEJournalRec;
    FFirmware: TFptrFirmwareRec;
    FCommands: TFptrCommands;
    FServicePassword: TFptrPasswordRec;
    FFiscalMemory: TFptrFiscalMemoryRec;
    FDeviceDumps: array [1..7] of string;
    FOperators: array [1..30] of TFptrOperatorRec;
    FReceiptLines: TFptrPrintItems;
    FJournalLines: TFptrPrintItems;
    FSlipLines: TFptrPrintItems;
    FAmountRegisters: array [Byte] of Int64;
    FOperatingRegisters: array [Byte] of Integer;
    FLicense: TFptrLicenseRec;
    FPointPosition: Integer;
    FDrawerOpened: Boolean;
    FFonts: array [1..7] of TFptrFontRec;
    FTables: TFptrTables;
    FDeviceMetrics: TFptrDeviceMetricsRec;
    FDayOpened: Boolean;
    FCashAmount: Int64;
    FEmulTables: TObject;
    FTableStorage: TObject;
    FFNState: TObject;
    FLongSerial: Int64;
    FSavedDumpMode: Integer;
    FReportInProgress: Boolean;

    function GetDeviceDump(Index: Integer): AnsiString;
    function GetMode4: Integer;
    function GetAmountRegister(Index: Integer): Int64;
    function GetOperatingRegister(Index: Integer): Integer;
    procedure WriteTablePassword(const Field: TFptrFieldRec);
    function GetOperator(Index: Integer): TFptrOperatorRec;
    function ReadTablePassword(const Field: TFptrFieldRec): TFptrFieldRec;
    procedure SetOperator(Index: Integer; const Value: TFptrOperatorRec);
    class function ValidTime(const Time: TPrinterTime): Boolean;
    class function ValidDate(const Date: TPrinterDate): Boolean;
    procedure InitializeTables;
    function GetFont(Index: Integer): TFptrFontRec;
    procedure SetFont(Index: Integer; const Value: TFptrFontRec);
    procedure CheckItem(const Item: TFptrItemRec);
    procedure CheckReceiptOpened;
    function GetDate: TPrinterDate;
    function GetTime: TPrinterTime;
    function GetSerial: TFptrSerialRec;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Reset;
    procedure SaveToFile(const FileName: AnsiString);
    procedure LoadFromFile(const FileName: AnsiString);
    procedure ApplyTables(ATables: TObject);
    procedure ApplyOperatorPasswords;
    function ReadFieldStruct(Password, TableNumber, FieldNumber: Integer;
      out Def: TEmulFieldDef): Boolean;
    procedure SendCommand(var Data: AnsiString; Timeout: Integer);
    function Execute(const Data: AnsiString; Timeout: Integer): AnsiString;
    procedure PrintBoldLine(Flags: Byte; const Line: AnsiString);
    procedure PrintLine(Flags: Byte; const Line: AnsiString; Font: Byte);
    function FindOperator(Password, MinIndex: Integer): Integer;
    procedure PrintDocHeader(const DocName: AnsiString; DocNumber: Integer);
    procedure ResetStatus;
    function StartTest(Password, Period: Integer): Integer;
    function Beep(Password: Integer): Integer;
    function ReadCashReg(Password, RegNumber: Integer): TFptrAmountRegRec;
    function ReadOperatingReg(Password, RegNumber: Integer): TFptrOperatingRegRec;
    procedure WriteLicense(Password: Integer; ALicense: Int64);
    function ReadLicense(Password: Integer): Int64;
    procedure WriteTable(Password: Integer; const Field: TFptrFieldRec);
    function ReadTable(Password: Integer; const Field: TFptrFieldRec): TFptrFieldRec;
    procedure SetPointPosition(Password, APointPosition: Integer);
    procedure SetTime(Password: Integer; const ATime: TPrinterTime);
    procedure SetDate(Password: Integer; const ADate: TPrinterDate);
    procedure ConfirmDate(Password: Integer; const ADate: TPrinterDate);
    procedure InitTables(Password: Integer);
    function CutPaper(Password, CutType: Integer): Integer;
    function ReadFont(Password, FontNumber: Integer): TFptrFontRec;
    procedure TotalReset(Password: Integer);
    function OpenDrawer(Password, DrawerNumber: Integer): Integer;
    procedure CloseDrawer;
    function FeedPaper(Password, Flags, LineCount: Integer): Integer;
    function StopTest(Password: Integer): Integer;
    function PrintOperatingRegisters(Password: Integer): Integer;
    function ReadTableDef(Password, TableNumber: Integer): TFptrTableRec;
    procedure WriteServicePassword(OldPassword, NewPassword: Integer);
    function PrintBarcode(Password: Integer; Barcode: Int64): Integer;
    function OpenReceipt(Password, RecType: Integer): Integer;
    function PrintCopy(Password: Integer): Integer;
    function Sale(Password: Integer; const Item: TFptrItemRec): Integer;
    function Buy(Password: Integer; const Item: TFptrItemRec): Integer;
    function RetSale(Password: Integer; const Item: TFptrItemRec): Integer;
    function RetBuy(Password: Integer; const Item: TFptrItemRec): Integer;
    function Storno(Password: Integer; const Item: TFptrItemRec): Integer;
    function CloseReceipt(Password: Integer;
      const CloseReceipt: TFptrCloseReceipt): TFptrCloseReceiptResult;
    function Discount(Password: Integer; const Discount: TFptrDiscount): Integer;
    function StornoDiscount(Password: Integer; const Discount: TFptrDiscount): Integer;
    function Charge(Password: Integer; const Discount: TFptrDiscount): Integer;
    function StornoCharge(Password: Integer; const Discount: TFptrDiscount): Integer;
    function CancelReceipt(Password: Integer): Integer;
    function ReadSubtotal(Password: Integer): TFptrSubtotal;
    function XReport(Password: Integer): Integer;
    function ZReport(Password: Integer): Integer;
    function TaxReport(Password: Integer): Integer;
    function DepReport(Password: Integer): Integer;
    function CashIn(Password: Integer; Amount: Int64): TFptrDocResult;
    function CashOut(Password: Integer; Amount: Int64): TFptrDocResult;
    function PrintHeader(Password: Integer): Integer;
    function PrintDocEnd(Password, Parameter: Integer): Integer;
    function PrintTrailer(Password: Integer): Integer;
    procedure WriteSerial(Password, ASerial: Integer);
    function ReadFMTotals(Password, RequestType: Integer): TFMTotals;
    function OpenSession(Password: Integer): Integer;
    function ExecuteFNCommand(Code: Integer; const Data: AnsiString): AnsiString;
    function ExecuteFECommand(Code: Integer; const Data: AnsiString): AnsiString;
    function GetSessionNumber: Word;
    function GetFNKKTRegNumber: AnsiString;
    function GetFNINN: AnsiString;
    procedure ApplyFiscalFromTables;
    procedure ClearSlipDocument;

    property Flags: Short read FFlags;
    property Mode4: Integer read GetMode4;
    property Port: TFptrPortRec read FPort;
    property Tables: TFptrTables read FTables;
    property Date: TPrinterDate read GetDate;
    property StoreID: Integer read FStoreID;
    property SubMode: Integer read FSubMode;
    property DocNumber: Integer read FDocNumber;
    property PortNumber: Integer read FPortNumber;
    property Mode: Integer read FMode write FMode;
    property SlipLines: TFptrPrintItems read FSlipLines;
    property Serial: TFptrSerialRec read GetSerial;
    property Receipt: TFptrReceipt read FReceipt;
    property License: TFptrLicenseRec read FLicense;
    property PowerVoltage: Integer read FPowerVoltage;
    property EJournal: TFptrEJournalRec read FEJournal;
    property Firmware: TFptrFirmwareRec read FFirmware;
    property ReceiptLines: TFptrPrintItems read FReceiptLines;
    property JournalLines: TFptrPrintItems read FJournalLines;
    property BatteryVoltage: Integer read FBatteryVoltage;
    property DeviceDumps[Index: Integer]: AnsiString read GetDeviceDump;
    property AmountRegisters[Index: Integer]: Int64 read GetAmountRegister;
    property Time: TPrinterTime read GetTime;
    property PointPosition: Integer read FPointPosition write FPointPosition;
    property OperatingRegisters[Index: Integer]: Integer read GetOperatingRegister;
    property FiscalMemory: TFptrFiscalMemoryRec read FFiscalMemory write FFiscalMemory;
    property Operators[Index: Integer]: TFptrOperatorRec read GetOperator write SetOperator;
    property Fonts[Index: Integer]: TFptrFontRec read GetFont write SetFont;
    property DrawerOpened: Boolean read FDrawerOpened;
    property DeviceMetrics: TFptrDeviceMetricsRec read FDeviceMetrics;
    property ServicePassword: TFptrPasswordRec read FServicePassword write FServicePassword;
    property LongSerial: Int64 read FLongSerial write FLongSerial;
    property SavedDumpMode: Integer read FSavedDumpMode write FSavedDumpMode;
    property ReportInProgress: Boolean read FReportInProgress write FReportInProgress;
    property DayOpened: Boolean read FDayOpened;
    property CashAmount: Int64 read FCashAmount;
  end;

  { TFptrTable }

  TFptrTable = class
  private
    FOwner: TFptrTables;
    FData: TFptrTableRec;
    procedure SetOwner(AOwner: TFptrTables);
  public
    constructor Create(AOwner: TFptrTables; const AData: TFptrTableRec);
    destructor Destroy; override;

    property Data: TFptrTableRec read FData;
    property Name: AnsiString read FData.Name;
    property Number: Integer read FData.Number;
    property RowCount: Integer read FData.RowCount;
    property FieldCount: Integer read FData.FieldCount;
  end;

  { TFptrTables }

  TFptrTables = class
  private
    FList: TList;
    procedure Clear;
    function GetCount: Integer;
    procedure InsertItem(AItem: TFptrTable);
    procedure RemoveItem(AItem: TFptrTable);
    function GetItem(Index: Integer): TFptrTable;
  public
    constructor Create;
    destructor Destroy; override;
    function ItemByNumber(Number: Integer): TFptrTable;
    function Add(const AData: TFptrTableRec): TFptrTable;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TFptrTable read GetItem; default;
  end;

  { TFptrPrintItem }

  TFptrPrintItem = class
  private
    FOwner: TFptrPrintItems;
    procedure SetOwner(AOwner: TFptrPrintItems);
  public
    constructor Create(AOwner: TFptrPrintItems); virtual;
    destructor Destroy; override;
  end;

  { TFptrLine }

  TFptrLine = class(TFptrPrintItem)
  private
    FFont: Byte;
    FLine: AnsiString;
  public
    constructor Create2(AOwner: TFptrPrintItems; const ALine: AnsiString; AFont: Integer);
    property Font: Byte read FFont;
    property Line: AnsiString read FLine;
  end;

  { TFptrBarcode }

  TFptrBarcode = class(TFptrPrintItem)
  private
    FBarcode: Int64;
  public
    constructor Create2(AOwner: TFptrPrintItems; ABarcode: Int64);
    property Barcode: Int64 read FBarcode;
  end;

  { TFptrCut }

  TFptrCut = class(TFptrPrintItem)
  private
    FCutType: Integer;
  public
    constructor Create2(AOwner: TFptrPrintItems; ACutType: Integer);
    property CutType: Integer read FCutType;
  end;

  { TFptrFeed }

  TFptrFeed = class(TFptrPrintItem)
  private
    FLineCount: Integer;
  public
    constructor Create2(AOwner: TFptrPrintItems; ALineCount: Integer);
    property LineCount: Integer read FLineCount;
  end;

  { TFptrPrintItems }

  TFptrPrintItems = class
  private
    FList: TList;
    procedure Clear;
    function GetCount: Integer;
    procedure InsertItem(AItem: TFptrPrintItem);
    procedure RemoveItem(AItem: TFptrPrintItem);
    function GetItem(Index: Integer): TFptrPrintItem;
  public
    constructor Create;
    destructor Destroy; override;
    function AddCut(ACutType: Integer): TFptrCut;
    function AddFeed(ALineCount: Integer): TFptrFeed;
    function AddBarcode(ABarcode: Int64): TFptrBarcode;
    function AddLine(const ALine: AnsiString; AFont: Integer): TFptrLine;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TFptrPrintItem read GetItem; default;
  end;

  { TFptrCommand }

  TFptrCommand = class
  private
    FOwner: TFptrCommands;
    procedure SetOwner(AOwner: TFptrCommands);
  public
    constructor Create(AOwner: TFptrCommands);
    destructor Destroy; override;

    function GetCode: Integer; virtual; abstract;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; virtual; abstract;

    property Code: Integer read GetCode;
  end;

  { TFptrCommands }

  TFptrCommands = class
  private
    FList: TList;
    procedure Clear;
    function GetCount: Integer;
    function GetItem(Index: Integer): TFptrCommand;
    procedure InsertItem(AItem: TFptrCommand);
    procedure RemoveItem(AItem: TFptrCommand);
  public
    constructor Create;
    destructor Destroy; override;
    function ItemByCode(Code: Integer): TFptrCommand;

    property Count: Integer read GetCount;
    property Items[Index: Integer]: TFptrCommand read GetItem; default;
  end;

  { TFptrFrame }

  TFptrFrame = class
  private
    class function GetCRC(const Data: AnsiString): Byte;
  public
    class function Encode(const Data: AnsiString): AnsiString;
    class function Decode(const Data: AnsiString): AnsiString;
  end;

  { EFptrError }

  EFptrError = class(Exception)
  private
   FErrorCode: Byte;
  public
    constructor Create2(Code: Byte; const Msg: AnsiString);
    property ErrorCode: Byte read FErrorCode write FErrorCode;
  end;

  { TFptrCommand_01h }

  TFptrCommand_01h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_02h }

  TFptrCommand_02h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_10h }

  TFptrCommand_10h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_11h }

  TFptrCommand_11h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_12h }

  TFptrCommand_12h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_13h }

  TFptrCommand_13h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_14h }

  TFptrCommand_14h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_15h }

  TFptrCommand_15h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_16h }

  TFptrCommand_16h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_17h }

  TFptrCommand_17h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_18h }

  TFptrCommand_18h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_19h }

  TFptrCommand_19h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Ah }

  TFptrCommand_1Ah = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Bh }

  TFptrCommand_1Bh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Ch }

  TFptrCommand_1Ch = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Dh }

  TFptrCommand_1Dh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Eh }

  TFptrCommand_1Eh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_1Fh }

  TFptrCommand_1Fh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_20h }

  TFptrCommand_20h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_21h }

  TFptrCommand_21h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_22h }

  TFptrCommand_22h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_23h }

  TFptrCommand_23h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_24h }

  TFptrCommand_24h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_25h }

  TFptrCommand_25h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_26h }

  TFptrCommand_26h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_27h }

  TFptrCommand_27h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_28h }

  TFptrCommand_28h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_29h }

  TFptrCommand_29h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Bh }

  TFptrCommand_2Bh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Ch }

  TFptrCommand_2Ch = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Dh }

  TFptrCommand_2Dh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Eh }

  TFptrCommand_2Eh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_2Fh }

  TFptrCommand_2Fh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_40h }

  TFptrCommand_40h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_41h }

  TFptrCommand_41h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_42h }

  TFptrCommand_42h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_43h }

  TFptrCommand_43h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_50h }

  TFptrCommand_50h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_51h }

  TFptrCommand_51h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_52h }

  TFptrCommand_52h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_53h }

  TFptrCommand_53h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_54h }

  TFptrCommand_54h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_60h }

  TFptrCommand_60h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_62h }

  TFptrCommand_62h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_63h }

  TFptrCommand_63h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_F3h }

  TFptrCommand_F3h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_FCh }

  TFptrCommand_FCh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_C2h }

  TFptrCommand_C2h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_8Dh }

  TFptrCommand_8Dh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_8Ch }

  TFptrCommand_8Ch = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_80h }

  TFptrCommand_80h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_81h }

  TFptrCommand_81h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_82h }

  TFptrCommand_82h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_83h }

  TFptrCommand_83h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_84h }

  TFptrCommand_84h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_85h }

  TFptrCommand_85h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_86h }

  TFptrCommand_86h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_87h }

  TFptrCommand_87h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_88h }

  TFptrCommand_88h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_89h }

  TFptrCommand_89h = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_8Ah }

  TFptrCommand_8Ah = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

  { TFptrCommand_8Bh }

  TFptrCommand_8Bh = class(TFptrCommand)
  public
    function GetCode: Integer; override;
    function Execute(Device: TPrinterEmulator; const Data: AnsiString): AnsiString; override;
  end;

implementation

uses
  EmulProtocolCommands, EmulFNState, EmulFECommands;

function GetStrLen(const S: AnsiString; Len: Integer): AnsiString;
begin
  Result := Copy(S, 1, Len);
  Result := Result + StringOfChar(#0, Len - Length(Result));
end;

function FptrFont(PrintWidth: Word; CharWidth, CharHeight,
  FontCount: Byte): TFptrFontRec;
begin
  Result.PrintWidth := PrintWidth;
  Result.CharWidth := CharWidth;
  Result.CharHeight := CharHeight;
  Result.FontCount := FontCount;
end;

function DataToBin(const P; Size: Integer): AnsiString;
begin
  SetLength(Result, Size);
  Move(P, Result[1], Size);
end;

function DateToBin(const Value: TPrinterDate): AnsiString;
begin
  Result := DataToBin(Value, Sizeof(Value));
end;

function TimeToBin(const Value: TPrinterTime): AnsiString;
begin
  Result := DataToBin(Value, Sizeof(Value));
end;

function FiscalIDToBin(const Value: TFptrFiscalIDRec): AnsiString;
begin
  if Value.Valid then
    Result := IntToBin(Value.Number, 6)
  else
    Result := #$FF#$FF#$FF#$FF#$FF#$FF;
end;

function SerialToBin(const Value: TFptrSerialRec): AnsiString;
begin
  if Value.Valid then
    Result := IntToBin(Value.Number, 4)
  else
    Result := #$FF#$FF#$FF#$FF;
end;

procedure RaiseFptrError(Code: Byte);
begin
  raise EFptrError.Create2(Code, '');
end;

procedure CheckMinLength(const Data: AnsiString; MinLength: Integer);
begin
  if Length(Data) < MinLength then
    RaiseFptrError(FPTR_E_INVALID_CMD_LEN);
end;

function PrinterDate(Day, Month, Year: Byte): TPrinterDate;
begin
  Result.Day := Day;
  Result.Month := Month;
  Result.Year := Year;
end;

{ EFptrError }

constructor EFptrError.Create2(Code: Byte; const Msg: AnsiString);
begin
  inherited Create(Msg);
  FErrorCode := Code;
end;

const
  STX = #2;

{ TFptrFrame }

class function TFptrFrame.GetCRC(const Data: AnsiString): Byte;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(Data) do

    Result := Result xor Ord(Data[i]);
end;

class function TFptrFrame.Encode(const Data: AnsiString): AnsiString;
var
  DataLen: Integer;
begin
  DataLen := Length(Data);
  Result := AnsiChar(DataLen) + Data;
  Result := STX + Result + AnsiChar(GetCRC(Result));
end;

class function TFptrFrame.Decode(const Data: AnsiString): AnsiString;
var
  S: AnsiString;
  DataCrc: Byte;
  DataLen: Integer;
begin
  if Length(Data) < 3 then
    raise Exception.Create('Invalid data length');

  if Data[1] <> STX then
    raise Exception.Create('First byte is not STX');

  DataLen := Ord(Data[2]);
  S := Copy(Data, 2, DataLen+1);
  Result := Copy(Data, 3, DataLen);
  if Length(Result) <> DataLen then
    raise Exception.Create('Invalid data length');

  DataCrc := Ord(Data[Length(Data)]);
  if DataCrc <> GetCRC(S) then
    raise Exception.Create('Invalid CRC');
end;

{ TFptrCommands }

constructor TFptrCommands.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TFptrCommands.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TFptrCommands.Clear;
begin
  while Count > 0 do Items[0].Free;
end;

function TFptrCommands.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TFptrCommands.GetItem(Index: Integer): TFptrCommand;
begin
  Result := FList[Index];
end;

procedure TFptrCommands.InsertItem(AItem: TFptrCommand);
begin
  FList.Add(AItem);
  AItem.FOwner := Self;
end;

procedure TFptrCommands.RemoveItem(AItem: TFptrCommand);
begin
  AItem.FOwner := nil;
  FList.Remove(AItem);
end;

function TFptrCommands.ItemByCode(Code: Integer): TFptrCommand;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
  begin
    Result := Items[i];
    if Result.Code = Code then Exit;
  end;
  Result := nil;
end;

{ TFptrCommand }

constructor TFptrCommand.Create(AOwner: TFptrCommands);
begin
  inherited Create;
  SetOwner(AOwner);
end;

destructor TFptrCommand.Destroy;
begin
  SetOwner(nil);
  inherited Destroy;
end;

procedure TFptrCommand.SetOwner(AOwner: TFptrCommands);
begin
  if AOwner <> FOwner then
  begin
    if FOwner <> nil then FOwner.RemoveItem(Self);
    if AOwner <> nil then AOwner.InsertItem(Self);
  end;
end;

{ TFptrPrintItems }

constructor TFptrPrintItems.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TFptrPrintItems.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TFptrPrintItems.Clear;
begin
  while Count > 0 do Items[0].Free;
end;

function TFptrPrintItems.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TFptrPrintItems.GetItem(Index: Integer): TFptrPrintItem;
begin
  Result := FList[Index];
end;

procedure TFptrPrintItems.InsertItem(AItem: TFptrPrintItem);
begin
  FList.Add(AItem);
  AItem.FOwner := Self;
end;

procedure TFptrPrintItems.RemoveItem(AItem: TFptrPrintItem);
begin
  AItem.FOwner := nil;
  FList.Remove(AItem);
end;

function TFptrPrintItems.AddLine(const ALine: AnsiString; AFont: Integer): TFptrLine;
begin
  Result := TFptrLine.Create2(Self, ALine, AFont);
end;

function TFptrPrintItems.AddCut(ACutType: Integer): TFptrCut;
begin
  Result := TFptrCut.Create2(Self, ACutType);
end;

function TFptrPrintItems.AddFeed(ALineCount: Integer): TFptrFeed;
begin
  Result := TFptrFeed.Create2(Self, ALineCount);
end;

function TFptrPrintItems.AddBarcode(ABarcode: Int64): TFptrBarcode;
begin
  Result := TFptrBarcode.Create2(Self, ABarcode);
end;

{ TFptrTables }

constructor TFptrTables.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TFptrTables.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TFptrTables.Clear;
begin
  while Count > 0 do Items[0].Free;
end;

function TFptrTables.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TFptrTables.GetItem(Index: Integer): TFptrTable;
begin
  Result := FList[Index];
end;

procedure TFptrTables.InsertItem(AItem: TFptrTable);
begin
  FList.Add(AItem);
  AItem.FOwner := Self;
end;

procedure TFptrTables.RemoveItem(AItem: TFptrTable);
begin
  AItem.FOwner := nil;
  FList.Remove(AItem);
end;

function TFptrTables.Add(const AData: TFptrTableRec): TFptrTable;
begin
  Result := TFptrTable.Create(Self, AData);
end;

function TFptrTables.ItemByNumber(Number: Integer): TFptrTable;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
  begin
    Result := Items[i];
    if Result.Number = Number then Exit;
  end;
  Result := nil;
end;

{ TFptrTable }

constructor TFptrTable.Create(AOwner: TFptrTables; const AData: TFptrTableRec);
begin
  inherited Create;
  SetOwner(AOwner);
  FData := AData;
end;

destructor TFptrTable.Destroy;
begin
  SetOwner(nil);
  inherited Destroy;
end;

procedure TFptrTable.SetOwner(AOwner: TFptrTables);
begin
  if AOwner <> FOwner then
  begin
    if FOwner <> nil then FOwner.RemoveItem(Self);
    if AOwner <> nil then AOwner.InsertItem(Self);
  end;
end;

{ TFptrPrintItem }

constructor TFptrPrintItem.Create(AOwner: TFptrPrintItems);
begin
  inherited Create;
  SetOwner(AOwner);
end;

destructor TFptrPrintItem.Destroy;
begin
  SetOwner(nil);
  inherited Destroy;
end;

procedure TFptrPrintItem.SetOwner(AOwner: TFptrPrintItems);
begin
  if AOwner <> FOwner then
  begin
    if FOwner <> nil then FOwner.RemoveItem(Self);
    if AOwner <> nil then AOwner.InsertItem(Self);
  end;
end;

{ TFptrBarcode }

constructor TFptrBarcode.Create2(AOwner: TFptrPrintItems; ABarcode: Int64);
begin
  inherited Create(AOwner);
  FBarcode := ABarcode;
end;

{ TFptrLine }

constructor TFptrLine.Create2(AOwner: TFptrPrintItems; const ALine: AnsiString;
  AFont: Integer);
begin
  inherited Create(AOwner);
  FLine := ALine;
  FFont := AFont;
end;

{ TFptrCut }

constructor TFptrCut.Create2(AOwner: TFptrPrintItems; ACutType: Integer);
begin
  inherited Create(AOwner);
  FCutType := ACutType;
end;

{ TFptrFeed }

constructor TFptrFeed.Create2(AOwner: TFptrPrintItems; ALineCount: Integer);
begin
  inherited Create(AOwner);
  FLineCount := ALineCount;
end;

{ TPrinterEmulator }

constructor TPrinterEmulator.Create;
begin
  inherited Create;
  FTables := TFptrTables.Create;
  FReceipt := TFptrReceipt.Create;
  FSlipLines := TFptrPrintItems.Create;
  FReceiptLines := TFptrPrintItems.Create;
  FJournalLines := TFptrPrintItems.Create;
  FCommands := TFptrCommands.Create;
  FFNState := TEmulFNState.Create;
  TFptrCommand_01h.Create(FCommands);
  TFptrCommand_10h.Create(FCommands);
  TFptrCommand_11h.Create(FCommands);
  TFptrCommand_12h.Create(FCommands);
  TFptrCommand_13h.Create(FCommands);
  TFptrCommand_14h.Create(FCommands);
  TFptrCommand_15h.Create(FCommands);
  TFptrCommand_16h.Create(FCommands);
  TFptrCommand_17h.Create(FCommands);
  TFptrCommand_18h.Create(FCommands);
  TFptrCommand_19h.Create(FCommands);
  TFptrCommand_1Ah.Create(FCommands);
  TFptrCommand_1Bh.Create(FCommands);
  TFptrCommand_1Ch.Create(FCommands);
  TFptrCommand_1Dh.Create(FCommands);
  TFptrCommand_1Eh.Create(FCommands);
  TFptrCommand_1Fh.Create(FCommands);
  TFptrCommand_20h.Create(FCommands);
  TFptrCommand_21h.Create(FCommands);
  TFptrCommand_22h.Create(FCommands);
  TFptrCommand_23h.Create(FCommands);
  TFptrCommand_24h.Create(FCommands);
  TFptrCommand_25h.Create(FCommands);
  TFptrCommand_26h.Create(FCommands);
  TFptrCommand_27h.Create(FCommands);
  TFptrCommand_28h.Create(FCommands);
  TFptrCommand_29h.Create(FCommands);
  TFptrCommand_2Bh.Create(FCommands);
  TFptrCommand_2Ch.Create(FCommands);
  TFptrCommand_2Dh.Create(FCommands);
  TFptrCommand_2Eh.Create(FCommands);
  TFptrCommand_2Fh.Create(FCommands);

  TFptrCommand_40h.Create(FCommands);
  TFptrCommand_41h.Create(FCommands);
  TFptrCommand_42h.Create(FCommands);
  TFptrCommand_43h.Create(FCommands);
  TFptrCommand_50h.Create(FCommands);
  TFptrCommand_51h.Create(FCommands);
  TFptrCommand_52h.Create(FCommands);
  TFptrCommand_53h.Create(FCommands);
  TFptrCommand_54h.Create(FCommands);

  TFptrCommand_60h.Create(FCommands);
  TFptrCommand_62h.Create(FCommands);

  TFptrCommand_F3h.Create(FCommands);
  TFptrCommand_FCh.Create(FCommands);

  TFptrCommand_C2h.Create(FCommands);
  TFptrCommand_02h.Create(FCommands);
  TFptrCommand_63h.Create(FCommands);

  TFptrCommand_8Ch.Create(FCommands);
  TFptrCommand_8Dh.Create(FCommands);
  TFptrCommand_80h.Create(FCommands);
  TFptrCommand_81h.Create(FCommands);
  TFptrCommand_82h.Create(FCommands);
  TFptrCommand_83h.Create(FCommands);
  TFptrCommand_84h.Create(FCommands);
  TFptrCommand_85h.Create(FCommands);
  TFptrCommand_86h.Create(FCommands);
  TFptrCommand_87h.Create(FCommands);
  TFptrCommand_88h.Create(FCommands);
  TFptrCommand_89h.Create(FCommands);
  TFptrCommand_8Ah.Create(FCommands);
  TFptrCommand_8Bh.Create(FCommands);

  RegisterAllProtocolCommands(FCommands);

  Reset;
end;

destructor TPrinterEmulator.Destroy;
begin
  if FTableStorage <> nil then
    TEmulTables(FTableStorage).Free;
  FTables.Free;
  FReceipt.Free;
  FCommands.Free;
  FSlipLines.Free;
  FReceiptLines.Free;
  FJournalLines.Free;
  FFNState.Free;
  inherited Destroy;
end;

procedure TPrinterEmulator.SendCommand(var Data: AnsiString; Timeout: Integer);
begin
  Data := Execute(Data, Timeout);
  Data := TFptrFrame.Encode(Data);
end;

function TPrinterEmulator.Execute(const Data: AnsiString; Timeout: Integer): AnsiString;
var
  CommandCode: Byte;
  LookupCode: Integer;
  CommandData: AnsiString;
  Command: TFptrCommand;
  PrefixLen: Integer;
begin
  if Length(Data) = 0 then
    raise Exception.Create('Invalid command length');

  CommandCode := Ord(Data[1]);
  LookupCode := CommandCode;
  PrefixLen := 1;
  CommandData := Copy(Data, 2, Length(Data));

  if CommandCode in [$FE, $FF] then
  begin
    if Length(Data) < 2 then
      raise Exception.Create('Invalid extended command length');
    LookupCode := (CommandCode shl 8) or Ord(Data[2]);
    CommandData := Copy(Data, 3, Length(Data));
    PrefixLen := 2;
  end;

  Command := FCommands.ItemByCode(LookupCode);
  if Command <> nil then
  begin
    try
      Result := Command.Execute(Self, CommandData);
    except
      on E: EFptrError do
      begin
        Result := AnsiChar(E.ErrorCode);
      end;
    end;
  end else
  begin
    Result := AnsiChar(FPTR_E_CMD_NOT_SUPPORT);
  end;

  if PrefixLen = 2 then
    Result := AnsiChar(CommandCode) + AnsiChar(LookupCode and $FF) + Result
  else
    Result := AnsiChar(CommandCode) + Result;
end;

procedure TPrinterEmulator.LoadFromFile(const FileName: AnsiString);
var
  Tables: TEmulTables;
begin
  if FTableStorage <> nil then
    TEmulTables(FTableStorage).Free;
  Tables := TEmulTables.Create;
  FTableStorage := Tables;
  Tables.LoadFromFile(FileName);
  ApplyTables(Tables);
end;

procedure TPrinterEmulator.ApplyTables(ATables: TObject);
var
  Tables: TEmulTables;
  i: Integer;
  TableDef: TEmulTableDef;
  TableRec: TFptrTableRec;
begin
  FEmulTables := ATables;
  if ATables = nil then
    Exit;
  Tables := TEmulTables(ATables);

  FTables.Clear;
  for i := 0 to Tables.TableCount - 1 do
  begin
    TableDef := Tables.Tables[i];
    TableRec.Number := TableDef.Number;
    TableRec.Name := TableDef.Name;
    TableRec.RowCount := TableDef.RowCount;
    TableRec.FieldCount := TableDef.FieldCount;
    FTables.Add(TableRec);
  end;
  ApplyOperatorPasswords;
  ApplyFiscalFromTables;
end;

procedure TPrinterEmulator.ApplyOperatorPasswords;
var
  Tables: TEmulTables;
  i: Integer;
  Def: TEmulFieldDef;
begin
  if FEmulTables = nil then
    Exit;
  Tables := TEmulTables(FEmulTables);
  for i := 0 to Tables.FieldCount - 1 do
  begin
    Def := Tables.Fields[i];
    if (Def.Table = 2) and (Def.Field = 1) and (Def.Row in [1..30]) then
      FOperators[Def.Row].Password := StrToIntDef(Def.Value, Def.Row);
  end;
end;

function PadRightAnsi(const S: AnsiString; Len: Integer): AnsiString;
begin
  Result := Copy(S, 1, Len);
  if Length(Result) < Len then
    Result := Result + StringOfChar(' ', Len - Length(Result));
end;

procedure TPrinterEmulator.ApplyFiscalFromTables;
var
  Tables: TEmulTables;
  Def: TEmulFieldDef;
  FN: TEmulFNState;
begin
  if FEmulTables = nil then
    Exit;
  Tables := TEmulTables(FEmulTables);
  FN := TEmulFNState(FFNState);
  if Tables.ReadFieldDef(18, 1, 1, Def) then
  begin
    FLongSerial := StrToInt64Def(Trim(Def.Value), FLongSerial);
    FSerial.Valid := True;
    FSerial.Number := FLongSerial mod 1000000000;
  end;
  if Tables.ReadFieldDef(18, 1, 2, Def) then
    FN.INN := PadRightAnsi(Trim(Def.Value), 12);
  if Tables.ReadFieldDef(18, 1, 3, Def) then
    FN.KKTRegNumber := PadRightAnsi(Trim(Def.Value), 20);
  if FN.KKTRegNumber <> '' then
  begin
    FFiscalMemory.FiscalID.Valid := True;
    FFiscalMemory.FiscalID.Number := StrToInt64Def(Trim(FN.KKTRegNumber), 0);
  end;
end;

function TPrinterEmulator.GetSessionNumber: Word;
begin
  if FFNState <> nil then
    Result := TEmulFNState(FFNState).SessionNumber
  else
    Result := 0;
end;

function TPrinterEmulator.GetFNKKTRegNumber: AnsiString;
begin
  if FFNState <> nil then
    Result := TEmulFNState(FFNState).KKTRegNumber
  else
    Result := '';
end;

function TPrinterEmulator.GetFNINN: AnsiString;
begin
  if FFNState <> nil then
    Result := TEmulFNState(FFNState).INN
  else
    Result := '';
end;

procedure TPrinterEmulator.ClearSlipDocument;
begin
  FSlipLines.Clear;
end;

procedure TPrinterEmulator.SaveToFile(const FileName: AnsiString);
begin

end;

procedure TPrinterEmulator.Reset;
begin
  Receipt.Reset;
  if FFNState <> nil then
    TEmulFNState(FFNState).Reset;
  FMode := FPTR_MODE_DAY_CLOSED;
  FSubMode := FPTR_SUBMODE_IDLE;

  SlipLines.Clear;
  ReceiptLines.Clear;
  JournalLines.Clear;
  FPort.Number := 0;
  FPort.BaudRate := 3;
  FPort.Timeout := 100;
  FLicense.Valid := False;
  FLicense.Value := $FFFFFFFFFF;

  InitializeTables;

  FFonts[1] := FptrFont(600, 12, 12, 7);
  FFonts[2] := FptrFont(600, 24, 22, 7);
  FFonts[3] := FptrFont(600, 12, 12, 7);
  FFonts[4] := FptrFont(600, 24, 25, 7);
  FFonts[5] := FptrFont(600, 10, 19, 7);
  FFonts[6] := FptrFont(600, 12, 12, 7);
  FFonts[7] := FptrFont(600, 12, 12, 7);

  //Tables.Add('')

  FDeviceMetrics.DeviceType := 0;
  FDeviceMetrics.DeviceSubtype := 0;
  FDeviceMetrics.ProtocolVersion := 1;
  FDeviceMetrics.ProtocolSubVersion := 4;
  FDeviceMetrics.Model := 1;
  FDeviceMetrics.Language := 0;
  FDeviceMetrics.DeviceName := '?????-??-?';
  FDayOpened := False;
  FLongSerial := 289610204000839;
  FSavedDumpMode := FPTR_MODE_DAY_CLOSED;
  FReportInProgress := False;

  FFirmware.Version := 'A4';
  FFirmware.Build := 1234;
  FFirmware.Date := PrinterDate(26,08, 10);

  FFiscalMemory.Flags := 0;
  FFiscalMemory.ErrorCode := 0;
  FFiscalMemory.Firmware.Version := '12';
  FFiscalMemory.Firmware.Build := 8776;
  FFiscalMemory.Firmware.Date := PrinterDate(15, 04, 08);
  FFiscalMemory.DayNumber := 0;
  FFiscalMemory.FiscNumber := 0;
  FFiscalMemory.FreeRecords := 3000;
  FFiscalMemory.LeftFiscNumber := 16;
  FFiscalMemory.FiscalID.Number := 0;
  FFiscalMemory.FiscalID.Valid := False;
end;

procedure TPrinterEmulator.InitializeTables;
var
  i: Integer;
begin
  // Table 2
  for i := 1 to 28 do
  begin
    FOperators[i].Password := i;
    FOperators[i].Name := '?????? ' + IntToStr(i);
  end;
  FOperators[29].Password := 29;
  FOperators[29].Name := '?????????????';
  FOperators[30].Password := 30;
  FOperators[30].Name := '????.?????????????';
end;

function TPrinterEmulator.FindOperator(Password, MinIndex: Integer): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to 30 do
  begin
    if i >= MinIndex then
    begin
      if FOperators[i].Password = Password then
      begin
        Result := i;
        Exit;
      end;
    end;
  end;
  RaiseFptrError(FPTR_E_INVALID_PASSWORD);
end;


{ TFptrCommand_10h }

(******************************************************************************

  Get Short FP Status

  Command:	10H. Length: 5 bytes.
  ?	Operator password (4 bytes)

  Answer:		10H. Length: 16 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30
  ?	FP flags (2 bytes)
  ?	FP mode (1 byte)
  ?	FP submode (1 byte)
  ?	Quantity of operations on the current receipt (1 byte) lower byte of a two-byte digit (see below)
  ?	Battery voltage (1 byte)
  ?	Power source voltage (1 byte)
  ?	Fiscal Memory error code (1 byte)
  ?	EKLZ error code (1 byte) EKLZ=Electronic Cryptographic Journal
  ?	Quantity of operations on the current receipt (1 byte) upper byte of a two-byte digit (see below)
  ?	Reserved (3 bytes)

******************************************************************************)

function TFptrCommand_10h.GetCode: Integer;
begin
  Result := $10;
end;

function TFptrCommand_10h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := #0 +
    AnsiChar(Operator) +
    IntToBin(Device.Flags, 2) +
    AnsiChar(Device.Mode) +
    AnsiChar(Device.SubMode) +
    AnsiChar(Lo(Device.Receipt.Operations)) +
    AnsiChar(Device.BatteryVoltage) +
    AnsiChar(Device.PowerVoltage) +
    AnsiChar(Device.FiscalMemory.ErrorCode) +
    AnsiChar(Device.EJournal.ErrorCode) +
    AnsiChar(Hi(Device.Receipt.Operations)) +
    #0#0#0;
end;

{ TFptrCommand_11h }

(******************************************************************************

  Get FP Status
  Command:	11H. Length: 5 bytes.
  ?	Operator password (4 bytes)
  Answer:		11H. Length: 48 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30
  ?	FP firmware version (2 bytes)
  ?	FP firmware build (2 bytes)
  ?	FP firmware date (3 bytes) DD-MM-YY
  ?	Number of FP in checkout line (1 byte)
  ?	Current receipt number (2 bytes)
  ?	FP flags (2 bytes)
  ?	FP mode (1 byte)
  ?	FP submode (1 byte)
  ?	FP port (1 byte)
  ?	FM firmware version (2 bytes)
  ?	FM firmware build (2 bytes)
  ?	FM firmware date (3 bytes) DD-MM-YY
  ?	Current date (3 bytes) DD-MM-YY
  ?	Current time (3 bytes) HH-MM-SS
  ?	FM flags (1 byte)
  ?	Serial number (4 bytes)
  ?	Number of last daily totals record in FM (2 bytes) 0000?2100
  ?	Quantity of free daily totals records left in FM (2 bytes)
  ?	Last fiscalization/refiscalization record number in FM (1 byte) 1?16
  ?	Quantity of free fiscalization/refiscalization records left in FM (1 byte) 0?15
  ?	Taxpayer ID (6 bytes)

******************************************************************************)


function TFptrCommand_11h.GetCode: Integer;
begin
  Result := $11;
end;

function TFptrCommand_11h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Result := #0 +
    AnsiChar(Operator) +
    Device.Firmware.Version +
    IntToBin(Device.Firmware.Build, 2) +
    DateToBin(Device.Firmware.Date) +
    AnsiChar(Device.StoreID) +
    IntToBin(Device.DocNumber, 2) +
    IntToBin(Device.Flags, 2) +
    AnsiChar(Device.Mode) +
    AnsiChar(Device.SubMode) +
    AnsiChar(Device.PortNumber) +
    Device.FiscalMemory.Firmware.Version +
    IntToBin(Device.FiscalMemory.Firmware.Build, 2) +
    DateToBin(Device.FiscalMemory.Firmware.Date) +
    DateToBin(Device.Date) +
    TimeToBin(Device.Time) +
    AnsiChar(Device.FiscalMemory.Flags) +
    SerialToBin(Device.Serial) +
    IntToBin(Device.FiscalMemory.DayNumber, 2) +
    IntToBin(Device.FiscalMemory.FreeRecords, 2) +
    IntToBin(Device.FiscalMemory.FiscNumber, 2) +
    IntToBin(Device.FiscalMemory.LeftFiscNumber, 2) +
    FiscalIDToBin(Device.FiscalMemory.FiscalID);
end;

function TPrinterEmulator.GetDeviceDump(Index: Integer): AnsiString;
begin
  Result := FDeviceDumps[Index];
end;

procedure TPrinterEmulator.PrintLine(Flags: Byte; const Line: AnsiString; Font: Byte);
begin
  if IsRecStation(Flags) then
    ReceiptLines.AddLine(Line, Font);

  if IsJrnStation(Flags) then
    JournalLines.AddLine(Line, Font);
end;

procedure TPrinterEmulator.PrintBoldLine(Flags: Byte; const Line: AnsiString);
begin
  PrintLine(Flags, Line, FPTR_FONT_BOLD);
end;

procedure TPrinterEmulator.ResetStatus;
begin
  { !!! }
end;

function TPrinterEmulator.GetMode4: Integer;
begin
  Result := Mode and $0F;
end;

procedure TPrinterEmulator.PrintDocHeader(const DocName: AnsiString;
  DocNumber: Integer);
begin
  { !!! }
  Inc(FDocNumber);
end;

function TPrinterEmulator.Beep(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
end;

function TPrinterEmulator.StartTest(Password, Period: Integer): Integer;
begin
  if not (Period in [1..99]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Result := FindOperator(Password, 0);
  case Mode4 of
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_POINTPOS,
    FPTR_MODE_TECH: ;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  FMode := FPTR_MODE_TEST;
end;

function TPrinterEmulator.ReadCashReg(Password,
  RegNumber: Integer): TFptrAmountRegRec;
begin
  if not (RegNumber in [0..$FF]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Result.Operator := FindOperator(Password, 0);
  Result.RegValue := FAmountRegisters[RegNumber];
end;

function TPrinterEmulator.ReadOperatingReg(Password,
  RegNumber: Integer): TFptrOperatingRegRec;
begin
  if not (RegNumber in [0..$FF]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Result.Operator := FindOperator(Password, 0);
  Result.RegValue := FOperatingRegisters[RegNumber];
end;

function TPrinterEmulator.GetAmountRegister(Index: Integer): Int64;
begin
  Result := FAmountRegisters[Index];
end;

function TPrinterEmulator.GetOperatingRegister(Index: Integer): Integer;
begin
  Result := FOperatingRegisters[Index];
end;

procedure TPrinterEmulator.WriteLicense(Password: Integer;
  ALicense: Int64);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  if (ALicense < 0000000000) or (ALicense > 9999999999) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  FLicense.Valid := True;
  FLicense.Value := ALicense;
end;

function TPrinterEmulator.ReadLicense(Password: Integer): Int64;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Result := License.Value;
end;

function TPrinterEmulator.GetOperator(Index: Integer): TFptrOperatorRec;
begin
  Result := FOperators[Index];
end;

procedure TPrinterEmulator.WriteTablePassword(const Field: TFptrFieldRec);
begin
  if not (Field.Row in [1..30]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  case Field.Field of
    1: FOperators[Field.Row].Password := BinToInt(Field.Value, 1, 4);
    2: FOperators[Field.Row].Name := Copy(Field.Value, 1, 21);
  else
    RaiseFptrError(FPTR_E_INVALID_PARAM);
  end;
end;

function TPrinterEmulator.ReadTablePassword(const Field: TFptrFieldRec): TFptrFieldRec;
begin
  Result := Field;
  if not (Field.Row in [1..30]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  case Field.Field of
    1: Result.Value := IntToBin(FOperators[Field.Row].Password, 4);
    2: Result.Value := FOperators[Field.Row].Name;
  else
    RaiseFptrError(FPTR_E_INVALID_PARAM);
  end;
end;

function TPrinterEmulator.ReadFieldStruct(Password, TableNumber,
  FieldNumber: Integer; out Def: TEmulFieldDef): Boolean;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  if FEmulTables = nil then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);
  Result := TEmulTables(FEmulTables).ReadFieldDef(TableNumber, 1, FieldNumber, Def);
  if not Result then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);
end;

function FieldValueToBin(const Def: TEmulFieldDef): AnsiString;
begin
  if Def.FieldType = 0 then
    Result := IntToBin(StrToInt64Def(Def.Value, 0), Def.Size)
  else
    Result := GetStrLen(Def.Value, Def.Size);
end;

procedure TPrinterEmulator.WriteTable(Password: Integer;
  const Field: TFptrFieldRec);
var
  Tables: TEmulTables;
  Def: TEmulFieldDef;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if Field.Table = 2 then
  begin
    WriteTablePassword(Field);
    Exit;
  end;

  if FEmulTables = nil then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);

  Tables := TEmulTables(FEmulTables);
  if not Tables.ReadFieldDef(Field.Table, Field.Row, Field.Field, Def) then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);
  if Def.FieldType = 0 then
    Tables.WriteFieldValue(Field.Table, Field.Row, Field.Field,
      IntToStr(BinToInt(Field.Value, 1, Def.Size)))
  else
    Tables.WriteFieldValue(Field.Table, Field.Row, Field.Field, TrimRight(Field.Value));
end;

function TPrinterEmulator.ReadTable(Password: Integer;
  const Field: TFptrFieldRec): TFptrFieldRec;
var
  Tables: TEmulTables;
  Def: TEmulFieldDef;
begin
  Result := Field;
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if Field.Table = 2 then
  begin
    Result := ReadTablePassword(Field);
    Exit;
  end;

  if FEmulTables = nil then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);

  Tables := TEmulTables(FEmulTables);
  if not Tables.ReadFieldDef(Field.Table, Field.Row, Field.Field, Def) then
    RaiseFptrError(FPTR_E_TABLE_NOT_DEFINE);
  Result.Value := FieldValueToBin(Def);
end;

procedure TPrinterEmulator.SetOperator(Index: Integer;
  const Value: TFptrOperatorRec);
begin
  FOperators[Index] := Value;
end;

procedure TPrinterEmulator.SetPointPosition(Password,
  APointPosition: Integer);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if not(APointPosition in [0..1]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  if Mode4 <> FPTR_MODE_POINTPOS then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  FPointPosition := APointPosition;
end;

class function TPrinterEmulator.ValidTime(const Time: TPrinterTime): Boolean;
begin
  Result :=
    (Time.Hour in [0..23])and
    (Time.Min in [0..59]) and
    (Time.Sec in [0..59]);
end;

class function TPrinterEmulator.ValidDate(const Date: TPrinterDate): Boolean;
begin
  Result :=
    (Date.Day in [1..31])and
    (Date.Month in [1..12]) and
    (Date.Year in [0..99]);
end;

procedure TPrinterEmulator.SetTime(Password: Integer;
  const ATime: TPrinterTime);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if not ValidTime(ATime) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  FTime := ATime;
end;

procedure TPrinterEmulator.SetDate(Password: Integer;
  const ADate: TPrinterDate);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if not ValidDate(ADate) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  FDate := ADate;
  FMode := FPTR_MODE_WAITDATE;
end;

procedure TPrinterEmulator.ConfirmDate(Password: Integer;
  const ADate: TPrinterDate);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if not ValidDate(ADate) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  if ComparePrinterDate(Date, ADate) <> 0 then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  if Mode <> FPTR_MODE_WAITDATE then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  FMode := FPTR_MODE_DAY_CLOSED;
end;

procedure TPrinterEmulator.InitTables(Password: Integer);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  if Mode <> FPTR_MODE_DAY_CLOSED then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  InitializeTables;
end;

function TPrinterEmulator.CutPaper(Password, CutType: Integer): Integer;
begin
  Result := FindOperator(Password, 0);

  if not (CutType in [0..1]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  ReceiptLines.AddCut(CutType);
end;

function TPrinterEmulator.ReadFont(Password,
  FontNumber: Integer): TFptrFontRec;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  if not (FontNumber in [1..7]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Result := FFonts[FontNumber];
end;

function TPrinterEmulator.GetFont(Index: Integer): TFptrFontRec;
begin
  Result := FFonts[Index];
end;

procedure TPrinterEmulator.SetFont(Index: Integer;
  const Value: TFptrFontRec);
begin
  FFonts[Index] := Value;
end;

procedure TPrinterEmulator.TotalReset(Password: Integer);
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  { !!! }
end;

function TPrinterEmulator.OpenDrawer(Password,
  DrawerNumber: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  FDrawerOpened := True;
end;

procedure TPrinterEmulator.CloseDrawer;
begin
  FDrawerOpened := False;
end;

function TPrinterEmulator.FeedPaper(Password, Flags,
  LineCount: Integer): Integer;
begin
  Result := FindOperator(Password, 0);

  if IsRecStation(Flags) then
    ReceiptLines.AddFeed(LineCount);

  if IsJrnStation(Flags) then
    JournalLines.AddFeed(LineCount);

  if IsSlpStation(Flags) then
    SlipLines.AddFeed(LineCount);
end;

function TPrinterEmulator.StopTest(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);

  if Mode <> FPTR_MODE_TEST then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  FMode := FPTR_MODE_DAY_CLOSED;
end;

function TPrinterEmulator.PrintOperatingRegisters(
  Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  { !!! }
end;

function TPrinterEmulator.ReadTableDef(Password,
  TableNumber: Integer): TFptrTableRec;
var
  Table: TFptrTable;
begin
  FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  Table := Tables.ItemByNumber(TableNumber);
  if Table = nil then
    RaiseFptrError($93);

  Result := Table.Data;
end;

procedure TPrinterEmulator.WriteServicePassword(OldPassword,
  NewPassword: Integer);
begin
  if ServicePassword.Valid then
  begin
    if OldPassword <> ServicePassword.Password then
      RaiseFptrError(FPTR_E_INVALID_PASSWORD);
  end;

  FServicePassword.Valid := True;
  FServicePassword.Password := NewPassword;
end;

function TPrinterEmulator.PrintBarcode(Password: Integer;
  Barcode: Int64): Integer;
begin
  Result := FindOperator(Password, 0);
  ReceiptLines.AddBarcode(Barcode);
end;

function TPrinterEmulator.OpenReceipt(Password, RecType: Integer): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  case Mode of
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      Receipt.Open(Operator, RecType);
      FMode := FPTR_MODE4_REC + (RecType shl 4);
      TEmulFNState(FFNState).OnLegacyReceiptOpen(RecType);
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.PrintCopy(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  { !!! }
end;

procedure TPrinterEmulator.CheckItem(const Item: TFptrItemRec);
begin

end;

function TPrinterEmulator.Sale(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  case Mode of
    FPTR_MODE_RECSALE,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      FReceipt.Sale(Operator, Item);
      FMode := FPTR_MODE_RECSALE;
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.RetSale(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  case Mode of
    FPTR_MODE_RECRETSALE,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      FReceipt.RetSale(Operator, Item);
      FMode := FPTR_MODE_RECRETSALE;
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.Buy(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  case Mode of
    FPTR_MODE_RECBUY,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      FReceipt.Buy(Operator, Item);
      FMode := FPTR_MODE_RECBUY;
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.RetBuy(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  case Mode of
    FPTR_MODE_RECRETBUY,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED:
    begin
      FReceipt.RetBuy(Operator, Item);
      FMode := FPTR_MODE_RECRETBUY;
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result := Operator;
end;

function TPrinterEmulator.Storno(Password: Integer;
  const Item: TFptrItemRec): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckItem(Item);

  if Mode4 <> FPTR_MODE4_REC then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  FReceipt.Storno(Operator, Item);
  Result := Operator;
end;

procedure TPrinterEmulator.CheckReceiptOpened;
begin
  if Mode4 <> FPTR_MODE4_REC then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
end;

function TPrinterEmulator.CloseReceipt(Password: Integer;
  const CloseReceipt: TFptrCloseReceipt): TFptrCloseReceiptResult;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Result.Change := Receipt.Close(Operator, CloseReceipt);
  Result.Operator := Operator;

  TEmulFNState(FFNState).OnLegacyReceiptClosed(Receipt.Total);
  FDayOpened := True;
  FMode := FPTR_MODE_DAY_OPENED;
end;

function TPrinterEmulator.Discount(Password: Integer;
  const Discount: TFptrDiscount): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Receipt.MakeDiscount(Operator, Discount);
  Result := Operator;
end;

function TPrinterEmulator.Charge(Password: Integer;
  const Discount: TFptrDiscount): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Receipt.MakeCharge(Operator, Discount);
  Result := Operator;
end;

function TPrinterEmulator.CancelReceipt(Password: Integer): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckReceiptOpened;
  Receipt.Cancel(Operator);
  Result := Operator;

  if FDayOpened then
    FMode := FPTR_MODE_DAY_OPENED
  else
    FMode := FPTR_MODE_DAY_CLOSED;
end;

function TPrinterEmulator.ReadSubtotal(Password: Integer): TFptrSubtotal;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);
  CheckReceiptOpened;

  Result.Operator := Operator;
  Result.Subtotal := Receipt.Total;
end;

function TPrinterEmulator.StornoCharge(Password: Integer;
  const Discount: TFptrDiscount): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Receipt.StornoCharge(Operator, Discount);
  Result := Operator;
end;

function TPrinterEmulator.StornoDiscount(Password: Integer;
  const Discount: TFptrDiscount): Integer;
var
  Operator: Integer;
begin
  Operator := FindOperator(Password, 0);

  CheckReceiptOpened;
  Receipt.StornoDiscount(Operator, Discount);
  Result := Operator;
end;

function TPrinterEmulator.OpenSession(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  case Mode of
    FPTR_MODE_DAY_CLOSED:
    begin
      FMode := FPTR_MODE_DAY_OPENED;
      FDayOpened := True;
    end;
    FPTR_MODE_DAY_OPENED:
      ;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  TEmulFNState(FFNState).OnLegacySessionOpen;
end;

function TPrinterEmulator.ExecuteFNCommand(Code: Integer;
  const Data: AnsiString): AnsiString;
begin
  Result := TEmulFNState(FFNState).ExecuteCommand(Code, Self, Data);
end;

function TPrinterEmulator.ExecuteFECommand(Code: Integer;
  const Data: AnsiString): AnsiString;
begin
  Result := EmulFEExecute(Self, Code, Data);
end;

function TPrinterEmulator.XReport(Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_CLOSED: ;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
end;

function TPrinterEmulator.ZReport(Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_OPENED:;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  TEmulFNState(FFNState).OnLegacySessionClose;
  FDayOpened := False;
  FMode := FPTR_MODE_DAY_CLOSED;
  Inc(FFiscalMemory.DayNumber);
end;

function TPrinterEmulator.DepReport(Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
end;

function TPrinterEmulator.TaxReport(Password: Integer): Integer;
begin
  Result := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
end;

function TPrinterEmulator.CashIn(Password: Integer;
  Amount: Int64): TFptrDocResult;
begin
  Result.Operator := FindOperator(Password, 0);

  case Mode of
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:
    begin
      FCashAmount := FCashAmount + Amount;
      Inc(FDocNumber);
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result.DocNumber := DocNumber;
end;

function TPrinterEmulator.CashOut(Password: Integer;
  Amount: Int64): TFptrDocResult;
begin
  Result.Operator := FindOperator(Password, 0);

  case Mode of
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:
    begin
      if Amount > FCashAmount then
        RaiseFptrError(FPTR_E_SMENA_CASH_MINUS);

      FCashAmount := FCashAmount - Amount;
      Inc(FDocNumber);
    end;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Result.DocNumber := DocNumber;
end;

function TPrinterEmulator.PrintHeader(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  case Mode of
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_DAY_OPENED:;
  else
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
  end;
  Inc(FDocNumber);
end;

function TPrinterEmulator.PrintDocEnd(Password,
  Parameter: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
  if not (Parameter in [0..1]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);
end;

function TPrinterEmulator.PrintTrailer(Password: Integer): Integer;
begin
  Result := FindOperator(Password, 0);
end;

procedure TPrinterEmulator.WriteSerial(Password, ASerial: Integer);
begin
  FindOperator(Password, 0);
  FSerial.Valid := True;
  FSerial.Number := ASerial;
end;

function TPrinterEmulator.ReadFMTotals(Password,
  RequestType: Integer): TFMTotals;
begin
  Result.Operator := FindOperator(Password, TABLE_PASSWORDS_INDEX_ADMIN);
  case RequestType of
    0:
    begin
      Result.SaleTotal := FFiscalMemory.GlobalSaleTotal;
      Result.BuyTotal := FFiscalMemory.GlobalBuyTotal;
      Result.RetSaleTotal := FFiscalMemory.GlobalRetSaleTotal;
      Result.RetBuyTotal := FFiscalMemory.GlobalRetBuyTotal;
    end;
    1:
    begin
      Result.SaleTotal := FFiscalMemory.SaleTotal;
      Result.BuyTotal := FFiscalMemory.BuyTotal;
      Result.RetSaleTotal := FFiscalMemory.RetSaleTotal;
      Result.RetBuyTotal := FFiscalMemory.RetBuyTotal;
    end;
  else
    RaiseFptrError(FPTR_E_INVALID_PARAM);
  end;
end;

function TPrinterEmulator.GetDate: TPrinterDate;
var
  y, m, d: Word;
begin
  DecodeDate(Now, y, m, d);
  Result.Day := d;
  Result.Month := m;
  Result.Year := y - 2000;
end;

function TPrinterEmulator.GetTime: TPrinterTime;
var
  h, m, s, ms: Word;
begin
  DecodeTime(Now, h, m, s, ms);
  Result.Hour := h;
  Result.Min := m;
  Result.Sec := s;
end;

function TPrinterEmulator.GetSerial: TFptrSerialRec;
begin
  Result.Valid := True;
  Result.Number := 12345678;
end;

{ TFptrReceipt }

procedure TFptrReceipt.Reset;
var
  i: Integer;
begin
  FOpened := False;
  FRecType := 0;
  FOperator := 0;
  FOperations := 0;
  for i := 1 to 16 do
    FDepartments[i].Total := 0;
  FCharge := 0;
  FDiscount := 0;
end;

procedure TFptrReceipt.Open(AOperator, ARecType: Integer);
begin
  if not (ARecType in [0..3]) then
    RaiseFptrError(FPTR_E_INVALID_PARAM);

  Reset;
  FOpened := True;
  FRecType := ARecType;
  FOperator := AOperator;
end;

function TFptrReceipt.GetDepartment(Value: Integer): Integer;
begin
  Result := Value;
  if Result = 0 then Result := 1;
end;

procedure TFptrReceipt.AddItem(AOperator: Integer; const Item: TFptrItemRec;
  ARecType: Integer);
var
  Amount: Int64;
  Department: Integer;
begin
  if Opened then
  begin
    if RecType <> ARecType then
      RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

    if FOperator <> AOperator then
      RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);
  end else
  begin
    Open(AOperator, ARecType);
  end;
  Department := GetDepartment(Item.Department);
  FOperations := FOperations + 1;
  Amount := Round(Item.Price*Item.Quantity/1000);
  FDepartments[Department].Total :=
    FDepartments[Department].Total + Amount;
end;

procedure TFptrReceipt.Sale(AOperator: Integer; const Item: TFptrItemRec);
begin
  AddItem(AOperator, Item, FPTR_RECTYPE_SALE);
end;

procedure TFptrReceipt.Buy(AOperator: Integer; const Item: TFptrItemRec);
begin
  AddItem(AOperator, Item, FPTR_RECTYPE_BUY);
end;

procedure TFptrReceipt.RetBuy(AOperator: Integer;
  const Item: TFptrItemRec);
begin
  AddItem(AOperator, Item, FPTR_RECTYPE_RETBUY);
end;

procedure TFptrReceipt.RetSale(AOperator: Integer;
  const Item: TFptrItemRec);
begin
  AddItem(AOperator, Item, FPTR_RECTYPE_RETSALE);
end;

procedure TFptrReceipt.Storno(AOperator: Integer;
  const Item: TFptrItemRec);
var
  Amount: Int64;
  Department: Integer;
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  FOperations := FOperations + 1;

  Amount := Round(Item.Price*Item.Quantity/1000);
  Department := GetDepartment(Item.Department);
  if Amount > FDepartments[Department].Total then
    RaiseFptrError(FPTR_E_PLACE_CASH_MINUS);

  FDepartments[Department].Total := FDepartments[Department].Total - Amount;
end;

function TFptrReceipt.GetTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to 16 do
    Result := Result + FDepartments[i].Total;
  Result := Result + FCharge - FDiscount;
end;

function TFptrReceipt.Close(AOperator: Integer;
  const Params: TFptrCloseReceipt): Int64;
var
  Amount: Int64;
  CashlessAmount: Int64;
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  CashlessAmount := Params.Amount2 + Params.Amount3 + Params.Amount4;
  Amount := Params.Amount1 + Params.Amount2 + Params.Amount3 + Params.Amount4;

  if Amount < Total then
    RaiseFptrError(FPTR_E_ALLSUMM_LESS_ITOG);

  if CashlessAmount > Total then
    RaiseFptrError(FPTR_E_BEZNAL_MORE_CHECK_SUMM);

  Result := Amount - Total;
  Reset;
end;

procedure TFptrReceipt.MakeDiscount(AOperator: Integer; const Discount: TFptrDiscount);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  if Discount.Amount > Total then
    RaiseFptrError(FPTR_E_CHECK_ITOG_MINUS);

  FOperations := FOperations + 1;
  FDiscount := FDiscount + Discount.Amount;
end;

procedure TFptrReceipt.MakeCharge(AOperator: Integer; const Charge: TFptrDiscount);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  FOperations := FOperations + 1;
  FCharge := FCharge + Charge.Amount;
end;

procedure TFptrReceipt.Cancel(AOperator: Integer);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  Reset;
end;

procedure TFptrReceipt.StornoCharge(AOperator: Integer;
  const Charge: TFptrDiscount);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  if Charge.Amount > FCharge then
    RaiseFptrError(FPTR_E_CHECK_ITOG_MINUS);

  FOperations := FOperations + 1;
  FCharge := FCharge - Charge.Amount;
end;

procedure TFptrReceipt.StornoDiscount(AOperator: Integer;
  const Discount: TFptrDiscount);
begin
  if not Opened then
    RaiseFptrError(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);

  if FOperator <> AOperator then
    RaiseFptrError(FPTR_E_DOC_OPEN_ANOTHER_USER);

  if Discount.Amount > FDiscount then
    RaiseFptrError(FPTR_E_CHECK_ITOG_MINUS);

  FOperations := FOperations + 1;
  FDiscount := FDiscount - Discount.Amount;
end;

{ TFptrCommand_01h }

function TFptrCommand_01h.GetCode: Integer;
begin
  Result := $01;
end;

function TFptrCommand_01h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  DeviceCode: Byte;
  BlockCount: Word;
  Password: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  DeviceCode := Ord(Data[5]);
  if not(DeviceCode in [1..7]) then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;

  case Device.Mode and $0F of
    FPTR_MODE_DAY_OPENED,
    FPTR_MODE_DAY_OVER,
    FPTR_MODE_DAY_CLOSED,
    FPTR_MODE_LOCKED:;
  else
    Result := AnsiChar(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
    Exit;
  end;

  BlockCount := (Length(Device.DeviceDumps[DeviceCode]) + DUMP_BLOCK_SIZE -1)
    div DUMP_BLOCK_SIZE;
  Result := #$00 + IntToBin(BlockCount, 2);
  Device.SavedDumpMode := Device.Mode;
  Device.Mode := FPTR_MODE_DUMP;
end;

{ TFptrCommand_02h }

function TFptrCommand_02h.GetCode: Integer;
begin
  Result := $02;
end;

function TFptrCommand_02h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  DeviceCode: Byte;
  BlockCount: Word;
  Password: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  DeviceCode := Ord(Data[5]);
  if not(DeviceCode in [1..7]) then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;

  BlockCount := (Length(Device.DeviceDumps[DeviceCode]) + DUMP_BLOCK_SIZE -1)
    div DUMP_BLOCK_SIZE;

  Result := #$00 + IntToBin(BlockCount, 2);
end;

{ TFptrCommand_13h }

function TFptrCommand_13h.GetCode: Integer;
begin
  Result := $13;
end;

function TFptrCommand_13h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.Beep(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_12h }

function TFptrCommand_12h.GetCode: Integer;
begin
  Result := $12;
end;

function TFptrCommand_12h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Flags: Byte;
  Line: AnsiString;
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Flags := Ord(Data[5]);
  Line := Copy(Data, 6, Length(Data));
  Device.PrintBoldLine(Flags, Line);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_14h }

function TFptrCommand_14h.GetCode: Integer;
begin
  Result := $14;
end;

function TFptrCommand_14h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Port: TFptrPortRec;
  Password: Integer;
begin
  CheckMinLength(Data, 7);
  Password := BinToInt(Data, 1, 4);
  Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  Port.Number := Ord(Data[5]);
  if Port.Number <> 0 then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;
  Port.BaudRate := Ord(Data[6]);
  if not(Port.BaudRate in [0..6]) then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;
  Port.Timeout := Ord(Data[7]);
  Device.FPort := Port;
  Result := #$00;
end;

{ TFptrCommand_15h }

function TFptrCommand_15h.GetCode: Integer;
begin
  Result := $15;
end;

function TFptrCommand_15h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Port: TFptrPortRec;
  Password: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Device.FindOperator(Password, TABLE_PASSWORDS_INDEX_SYS_ADMIN);

  Port.Number := Ord(Data[5]);
  if Port.Number <> 0 then
  begin
    Result := AnsiChar(FPTR_E_INVALID_PARAM);
    Exit;
  end;
  Result := #$00 + AnsiChar(Device.Port.BaudRate) + AnsiChar(Device.Port.Timeout);
end;

{ TFptrCommand_16h }

function TFptrCommand_16h.GetCode: Integer;
begin
  Result := $16;
end;

function TFptrCommand_16h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
begin
  if Device.Mode4 <> FPTR_MODE_TECH then
  begin
    Result := AnsiChar(FPTR_E_CMD_NOT_SUPPORT_CURRENT_STATE);
    Exit;
  end;

  Device.ResetStatus;
  Result := #$00;
end;

{ TFptrCommand_17h }

function TFptrCommand_17h.GetCode: Integer;
begin
  Result := $17;
end;

function TFptrCommand_17h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Flags: Byte;
  Line: AnsiString;
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  Flags := Ord(Data[5]);
  Line := Copy(Data, 6, Length(Data));
  Device.PrintLine(Flags, Line, FPTR_FONT_DEFAULT);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_18h }

function TFptrCommand_18h.GetCode: Integer;
begin
  Result := $18;
end;

function TFptrCommand_18h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  DocName: AnsiString;
  DocNumber: Integer;
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 36);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.FindOperator(Password, 0);
  DocName := Copy(Data, 5, 30);
  DocNumber := BinToInt(Data, 35, 2);
  Device.PrintDocHeader(DocName, DocNumber);
  Result := #$00 + AnsiChar(Operator) + IntToBin(Device.DocNumber, 2);
end;

{ TFptrCommand_19h }

function TFptrCommand_19h.GetCode: Integer;
begin
  Result := $19;
end;

function TFptrCommand_19h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Period: Integer;
  Password: Integer;
  Operator: Byte;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Period := Ord(Data[5]);
  Operator := Device.StartTest(Password, Period);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_1Ah }

function TFptrCommand_1Ah.GetCode: Integer;
begin
  Result := $1A;
end;

function TFptrCommand_1Ah.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  RegNumber: Integer;
  Password: Integer;
  CashReg: TFptrAmountRegRec;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  RegNumber := Ord(Data[5]);
  CashReg := Device.ReadCashReg(Password, RegNumber);
  Result := #$00 + AnsiChar(CashReg.Operator) + IntToBin(CashReg.RegValue, 6);
end;

{ TFptrCommand_1Bh }

function TFptrCommand_1Bh.GetCode: Integer;
begin
  Result := $1B;
end;

function TFptrCommand_1Bh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  RegNumber: Integer;
  Reg: TFptrOperatingRegRec;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  RegNumber := Ord(Data[5]);
  Reg := Device.ReadOperatingReg(Password, RegNumber);
  Result := #$00 + AnsiChar(Reg.Operator) + IntToBin(Reg.RegValue, 2);
end;

{ TFptrCommand_1Ch }

function TFptrCommand_1Ch.GetCode: Integer;
begin
  Result := $1C;
end;

function TFptrCommand_1Ch.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  License: Int64;
  Password: Integer;
begin
  CheckMinLength(Data, 9);
  Password := BinToInt(Data, 1, 4);
  License := BinToInt(Data, 5, 5);
  Device.WriteLicense(Password, License);
  Result := #$00;
end;

{ TFptrCommand_1Dh }

function TFptrCommand_1Dh.GetCode: Integer;
begin
  Result := $1D;
end;

function TFptrCommand_1Dh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  License: Int64;
  Password: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  License := Device.ReadLicense(Password);
  Result := #$00 + IntToBin(License, 5);
end;

{ TFptrCommand_1Eh }

function TFptrCommand_1Eh.GetCode: Integer;
begin
  Result := $1E;
end;

function TFptrCommand_1Eh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Field: TFptrFieldRec;
  Password: Integer;
begin
  CheckMinLength(Data, 8);
  Password := BinToInt(Data, 1, 4);
  Field.Table := Ord(Data[5]);
  Field.Row := BinToInt(Data, 6, 2);
  Field.Field := Ord(Data[8]);
  Field.Value := Copy(Data, 9, Length(Data));
  Device.WriteTable(Password, Field);
  Result := #$00;
end;

{ TFptrCommand_1Fh }

function TFptrCommand_1Fh.GetCode: Integer;
begin
  Result := $1F;
end;

function TFptrCommand_1Fh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Field: TFptrFieldRec;
  Password: Integer;
begin
  CheckMinLength(Data, 8);
  Password := BinToInt(Data, 1, 4);
  Field.Table := Ord(Data[5]);
  Field.Row := BinToInt(Data, 6, 2);
  Field.Field := Ord(Data[8]);
  Field.Value := '';
  Field := Device.ReadTable(Password, Field);
  Result := #$00 + Field.Value;
end;

{ TFptrCommand_20h }

function TFptrCommand_20h.GetCode: Integer;
begin
  Result := $20;
end;

function TFptrCommand_20h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  PointPosition: Byte;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  PointPosition := Ord(Data[5]);
  Device.SetPointPosition(Password, PointPosition);
  Result := #$00;
end;

{ TFptrCommand_21h }

function TFptrCommand_21h.GetCode: Integer;
begin
  Result := $21;
end;

function TFptrCommand_21h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Time: TPrinterTime;
begin
  CheckMinLength(Data, 7);
  Password := BinToInt(Data, 1, 4);
  Time.Hour := Ord(Data[5]);
  Time.Min := Ord(Data[6]);
  Time.Sec := Ord(Data[7]);
  Device.SetTime(Password, Time);
  Result := #$00;
end;

{ TFptrCommand_22h }

function TFptrCommand_22h.GetCode: Integer;
begin
  Result := $22;
end;

function TFptrCommand_22h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Date: TPrinterDate;
begin
  CheckMinLength(Data, 7);
  Password := BinToInt(Data, 1, 4);
  Date.Day := Ord(Data[5]);
  Date.Month := Ord(Data[6]);
  Date.Year := Ord(Data[7]);
  Device.SetDate(Password, Date);
  Result := #$00;
end;

{ TFptrCommand_23h }

function TFptrCommand_23h.GetCode: Integer;
begin
  Result := $23;
end;

function TFptrCommand_23h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Date: TPrinterDate;
begin
  CheckMinLength(Data, 7);
  Password := BinToInt(Data, 1, 4);
  Date.Day := Ord(Data[5]);
  Date.Month := Ord(Data[6]);
  Date.Year := Ord(Data[7]);
  Device.ConfirmDate(Password, Date);
  Result := #$00;
end;

{ TFptrCommand_24h }

function TFptrCommand_24h.GetCode: Integer;
begin
  Result := $24;
end;

function TFptrCommand_24h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Device.InitTables(Password);
  Result := #$00;
end;

{ TFptrCommand_25h }

function TFptrCommand_25h.GetCode: Integer;
begin
  Result := $25;
end;

function TFptrCommand_25h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  CutType: Byte;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  CutType := Ord(Data[5]);
  Operator := Device.CutPaper(Password, CutType);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_26h }

function TFptrCommand_26h.GetCode: Integer;
begin
  Result := $26;
end;

function TFptrCommand_26h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  FontNumber: Byte;
  Password: Integer;
  Font: TFptrFontRec;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  FontNumber := Ord(Data[5]);
  Font := Device.ReadFont(Password, FontNumber);

  Result := #$00 + IntToBin(Font.PrintWidth, 2) +
    AnsiChar(Font.CharWidth) +
    AnsiChar(Font.CharHeight) +
    AnsiChar(Font.FontCount);
end;

{ TFptrCommand_27h }

function TFptrCommand_27h.GetCode: Integer;
begin
  Result := $27;
end;

function TFptrCommand_27h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Device.TotalReset(Password);
  Result := #$00;
end;

{ TFptrCommand_28h }

function TFptrCommand_28h.GetCode: Integer;
begin
  Result := $28;
end;

function TFptrCommand_28h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  DrawerNumber: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  DrawerNumber := Ord(Data[5]);
  Operator := Device.OpenDrawer(Password, DrawerNumber);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_29h }

function TFptrCommand_29h.GetCode: Integer;
begin
  Result := $29;
end;

function TFptrCommand_29h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Flags: Integer;
  LineCount: Integer;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 6);
  Password := BinToInt(Data, 1, 4);
  Flags := Ord(Data[5]);
  LineCount := Ord(Data[6]);
  Operator := Device.FeedPaper(Password, Flags, LineCount);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_2Bh }

function TFptrCommand_2Bh.GetCode: Integer;
begin
  Result := $2B;
end;

function TFptrCommand_2Bh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.StopTest(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_2Ch }

function TFptrCommand_2Ch.GetCode: Integer;
begin
  Result := $2C;
end;

function TFptrCommand_2Ch.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.PrintOperatingRegisters(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_2Dh }

function TFptrCommand_2Dh.GetCode: Integer;
begin
  Result := $2D;
end;

function TFptrCommand_2Dh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  TableNumber: Byte;
  Table: TFptrTableRec;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  TableNumber := Ord(Data[5]);
  Table := Device.ReadTableDef(Password, TableNumber);
  Result := #$00 + GetStrLen(Table.Name, 40) +
    IntToBin(Table.RowCount, 2) + AnsiChar(Table.FieldCount);
end;

{ TFptrCommand_2Eh }

function TFptrCommand_2Eh.GetCode: Integer;
begin
  Result := $2E;
end;

function TFptrCommand_2Eh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  TableNumber: Byte;
  FieldNumber: Byte;
  Def: TEmulFieldDef;
begin
  CheckMinLength(Data, 6);
  Password := BinToInt(Data, 1, 4);
  TableNumber := Ord(Data[5]);
  FieldNumber := Ord(Data[6]);
  Device.ReadFieldStruct(Password, TableNumber, FieldNumber, Def);
  Result := #$00 + GetStrLen(Def.Name, 40) + AnsiChar(Def.FieldType);
  if Def.FieldType = 0 then
    Result := Result + AnsiChar(Def.Size) +
      IntToBin(Def.MinValue, Def.Size) + IntToBin(Def.MaxValue, Def.Size)
  else
    Result := Result + AnsiChar(Def.Size);
end;

{ TFptrCommand_2Fh }

(******************************************************************************

  ?????? ?????? ?????? ???????

  ???????:	2FH. ????? ?????????: 47 ????.
  ?????? ????????? (4 ?????)
  ????? (1 ????) ??? 0 - ??????????? ?????, ??? 1 - ??????? ?????.
  ????? ?????? (1 ????) 0?255
  ?????????? ??????? (40 ????)

  ?????:		2FH. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_2Fh.GetCode: Integer;
begin
  Result := $2F;
end;

function TFptrCommand_2Fh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Font: Integer;
  Flags: Integer;
  Password: Integer;
  Operator: Integer;
  Line: AnsiString;
begin
  CheckMinLength(Data, 6);
  Password := BinToInt(Data, 1, 4);
  Flags := Ord(Data[5]);
  Font := Ord(Data[6]);
  Line := Copy(Data, 7, Length(Data));
  Operator := Device.FindOperator(Password, 0);
  Device.PrintLine(Flags, Line, Font);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_F3h }

function TFptrCommand_F3h.GetCode: Integer;
begin
  Result := $F3;
end;

function TFptrCommand_F3h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  OldPassword: Integer;
  NewPassword: Integer;
begin
  CheckMinLength(Data, 8);
  OldPassword := BinToInt(Data, 1, 4);
  NewPassword := BinToInt(Data, 5, 4);
  Device.WriteServicePassword(OldPassword, NewPassword);
  Result := #$00;
end;

{ TFptrCommand_FCh }

function TFptrCommand_FCh.GetCode: Integer;
begin
  Result := $FC;
end;

function TFptrCommand_FCh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
begin
  Result := #$00 +
    AnsiChar(Device.DeviceMetrics.DeviceType) +
    AnsiChar(Device.DeviceMetrics.DeviceSubtype) +
    AnsiChar(Device.DeviceMetrics.ProtocolVersion) +
    AnsiChar(Device.DeviceMetrics.ProtocolSubVersion) +
    AnsiChar(Device.DeviceMetrics.Model) +
    AnsiChar(Device.DeviceMetrics.Language) +
    Device.DeviceMetrics.DeviceName;
end;

{ TFptrCommand_C2h }

function TFptrCommand_C2h.GetCode: Integer;
begin
  Result := $C2;
end;

function TFptrCommand_C2h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Barcode: Int64;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 9);
  Password := BinToInt(Data, 1, 4);
  Barcode := BinToInt(Data, 5, 5);
  Operator := Device.PrintBarcode(Password, Barcode);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_8Dh }

function TFptrCommand_8Dh.GetCode: Integer;
begin
  Result := $8D;
end;

function TFptrCommand_8Dh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  RecType: Integer;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  RecType := Ord(Data[5]);
  Operator := Device.OpenReceipt(Password, RecType);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_8Ch }

function TFptrCommand_8Ch.GetCode: Integer;
begin
  Result := $8C;
end;

function TFptrCommand_8Ch.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.PrintCopy(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_80h }

(*
???????
???????: 80H. ????? ?????????: 60 ????.
?????? ????????? (4 ?????)
?????????? (5 ????) 0000000000?9999999999
???? (5 ????) 0000000000?9999999999
????? ?????? (1 ????) 0?16
????? 1 (1 ????) ?0? ? ???, ?1???4? ? ????????? ??????
????? 2 (1 ????) ?0? ? ???, ?1???4? ? ????????? ??????
????? 3 (1 ????) ?0? ? ???, ?1???4? ? ????????? ??????
????? 4 (1 ????) ?0? ? ???, ?1???4? ? ????????? ??????
????? (40 ????)
?????: 80H. ????? ?????????: 3 ?????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30
*)

function TFptrCommand_80h.GetCode: Integer;
begin
  Result := $80;
end;

function TFptrCommand_80h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.Sale(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;


{ TFptrCommand_81h }

function TFptrCommand_81h.GetCode: Integer;
begin
  Result := $81;
end;

function TFptrCommand_81h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.Buy(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_82h }

function TFptrCommand_82h.GetCode: Integer;
begin
  Result := $82;
end;

function TFptrCommand_82h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.RetSale(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_83h }

function TFptrCommand_83h.GetCode: Integer;
begin
  Result := $83;
end;

function TFptrCommand_83h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.RetBuy(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_84h }

function TFptrCommand_84h.GetCode: Integer;
begin
  Result := $84;
end;

function TFptrCommand_84h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Item: TFptrItemRec;
  Operator: Integer;
begin
  CheckMinLength(Data, 19);
  Password := BinToInt(Data, 1, 4);
  Item.Quantity := BinToInt(Data, 5, 5);
  Item.Price := BinToInt(Data, 10, 5);
  Item.Department := Ord(Data[15]);
  Item.Tax1 := Ord(Data[16]);
  Item.Tax2 := Ord(Data[17]);
  Item.Tax3 := Ord(Data[18]);
  Item.Tax4 := Ord(Data[19]);
  Item.Text := Copy(Data, 20, 40);
  Operator := Device.Storno(Password, Item);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_85h }

(******************************************************************************

???????? ????

???????:	85H. ????? ?????????: 71 ????.
?????? ????????? (4 ?????)
????? ???????? (5 ????) 0000000000?9999999999
????? ???? ?????? 2 (5 ????) 0000000000?9999999999
????? ???? ?????? 3 (5 ????) 0000000000?9999999999
????? ???? ?????? 4 (5 ????) 0000000000?9999999999
??????/????????(? ?????? ?????????????? ????????) ? % ?? ??? ?? 0 ?? 99,99 % (2 ????? ?? ??????) -9999?9999
????? 1 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 2 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 3 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 4 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? (40 ????)

?????:		85H. ????? ?????????: 8 ????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30
????? (5 ????) 0000000000?9999999999


*******************************************************************************)

function TFptrCommand_85h.GetCode: Integer;
begin
  Result := $85;
end;

function TFptrCommand_85h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  CloseReceipt: TFptrCloseReceipt;
  CloseResult: TFptrCloseReceiptResult;
begin
  CheckMinLength(Data, 30);
  Password := BinToInt(Data, 1, 4);
  CloseReceipt.Amount1 := BinToInt(Data, 5, 5);
  CloseReceipt.Amount2 := BinToInt(Data, 10, 5);
  CloseReceipt.Amount3 := BinToInt(Data, 15, 5);
  CloseReceipt.Amount4 := BinToInt(Data, 20, 5);
  CloseReceipt.Discount := BinToInt(Data, 25, 2);
  CloseReceipt.Tax1 := Ord(Data[27]);
  CloseReceipt.Tax2 := Ord(Data[28]);
  CloseReceipt.Tax3 := Ord(Data[29]);
  CloseReceipt.Tax4 := Ord(Data[30]);
  CloseReceipt.Text := Copy(Data, 31, Length(Data));
  CloseResult := Device.CloseReceipt(Password, CloseReceipt);
  Result := #$00 +
    AnsiChar(CloseResult.Operator) +
    IntToBin(CloseResult.Change, 5);
end;

{ TFptrCommand_86h }

(******************************************************************************

??????
???????:	86H. ????? ?????????: 54 ????.
?????? ????????? (4 ?????)
????? (5 ????) 0000000000?9999999999
????? 1 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 2 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 3 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? 4 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
????? (40 ????)
?????:		86H. ????? ?????????: 3 ?????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_86h.GetCode: Integer;
begin
  Result := $86;
end;

function TFptrCommand_86h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  Discount: TFptrDiscount;
begin
  CheckMinLength(Data, 13);
  Password := BinToInt(Data, 1, 4);
  Discount.Amount := BinToInt(Data, 5, 5);
  Discount.Tax1 := Ord(Data[10]);
  Discount.Tax2 := Ord(Data[11]);
  Discount.Tax3 := Ord(Data[12]);
  Discount.Tax4 := Ord(Data[13]);
  Discount.Text := Copy(Data, 14, Length(Data));
  Operator := Device.Discount(Password, Discount);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_87h }

function TFptrCommand_87h.GetCode: Integer;
begin
  Result := $87;
end;

function TFptrCommand_87h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  Charge: TFptrDiscount;
begin
  CheckMinLength(Data, 13);
  Password := BinToInt(Data, 1, 4);
  Charge.Amount := BinToInt(Data, 5, 5);
  Charge.Tax1 := Ord(Data[10]);
  Charge.Tax2 := Ord(Data[11]);
  Charge.Tax3 := Ord(Data[12]);
  Charge.Tax4 := Ord(Data[13]);
  Charge.Text := Copy(Data, 14, Length(Data));
  Operator := Device.Charge(Password, Charge);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_88h }

(******************************************************************************

????????????? ????
???????:	88H. ????? ?????????: 5 ????.
?????? ????????? (4 ?????)
?????:		88H. ????? ?????????: 3 ?????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_88h.GetCode: Integer;
begin
  Result := $88;
end;

function TFptrCommand_88h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.CancelReceipt(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_89h }

(******************************************************************************

??????? ????
???????:	89H. ????? ?????????: 5 ????.
?????? ????????? (4 ?????)
?????:		89H. ????? ?????????: 8 ????.
??? ?????? (1 ????)
?????????? ????? ????????? (1 ????) 1?30
??????? ???? (5 ????) 0000000000?9999999999

******************************************************************************)

function TFptrCommand_89h.GetCode: Integer;
begin
  Result := $89;
end;

function TFptrCommand_89h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Subtotal: TFptrSubtotal;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Subtotal := Device.ReadSubtotal(Password);
  Result := #$00 + AnsiChar(Subtotal.Operator) +
    IntToBin(Subtotal.Subtotal, 5);
end;

{ TFptrCommand_8Ah }

(******************************************************************************

  ?????? ??????

  ???????:	8AH. ????? ?????????: 54 ?????.
  ?????? ????????? (4 ?????)
  ????? (5 ????) 0000000000?9999999999
  ????? 1 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 2 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 3 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 4 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? (40 ????)

  ?????:		8AH. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_8Ah.GetCode: Integer;
begin
  Result := $8A;
end;

function TFptrCommand_8Ah.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  Discount: TFptrDiscount;
begin
  CheckMinLength(Data, 13);
  Password := BinToInt(Data, 1, 4);
  Discount.Amount := BinToInt(Data, 5, 5);
  Discount.Tax1 := Ord(Data[10]);
  Discount.Tax2 := Ord(Data[11]);
  Discount.Tax3 := Ord(Data[12]);
  Discount.Tax4 := Ord(Data[13]);
  Discount.Text := Copy(Data, 14, Length(Data));
  Operator := Device.StornoDiscount(Password, Discount);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_8Bh }

(******************************************************************************

  ?????? ????????

  ???????:	8BH. ????? ?????????: 54 ?????.
  ?????? ????????? (4 ?????)
  ????? (5 ????) 0000000000?9999999999
  ????? 1 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 2 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 3 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? 4 (1 ????) "0" - ???, "1"?"4" - ????????? ??????
  ????? (40 ????)

  ?????:		8BH. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_8Bh.GetCode: Integer;
begin
  Result := $8B;
end;

function TFptrCommand_8Bh.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
  Discount: TFptrDiscount;
begin
  CheckMinLength(Data, 13);
  Password := BinToInt(Data, 1, 4);
  Discount.Amount := BinToInt(Data, 5, 5);
  Discount.Tax1 := Ord(Data[10]);
  Discount.Tax2 := Ord(Data[11]);
  Discount.Tax3 := Ord(Data[12]);
  Discount.Tax4 := Ord(Data[13]);
  Discount.Text := Copy(Data, 14, Length(Data));
  Operator := Device.StornoCharge(Password, Discount);
  Result := #$00 + AnsiChar(Operator);
end;


{ TFptrCommand_40h }

function TFptrCommand_40h.GetCode: Integer;
begin
  Result := $40;
end;

function TFptrCommand_40h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.XReport(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_41h }

function TFptrCommand_41h.GetCode: Integer;
begin
  Result := $41;
end;

function TFptrCommand_41h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.ZReport(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_42h }

(******************************************************************************

  ????? ?? ???????

  ???????:	42H. ????? ?????????: 5 ????.
  ?????? ?????????????? ??? ?????????? ?????????????? (4 ?????)

  ?????:		42H. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 29, 30

******************************************************************************)

function TFptrCommand_42h.GetCode: Integer;
begin
  Result := $42;
end;

function TFptrCommand_42h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.DepReport(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_43h }

(******************************************************************************

  ????? ?? ???????

  ???????:	43H. ????? ?????????: 5 ????.
  ?????? ?????????????? ??? ?????????? ?????????????? (4 ?????)

  ?????:		43H. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 29, 30

******************************************************************************)

function TFptrCommand_43h.GetCode: Integer;
begin
  Result := $43;
end;

function TFptrCommand_43h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.TaxReport(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_50h }

(******************************************************************************

  ????????

  ???????:	50H. ????? ?????????: 10 ????.
  ?????? ????????? (4 ?????)
  ????? (5 ????)

  ?????:		50H. ????? ?????????: 5 ????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30
  ???????? ????? ????????? (2 ?????)

******************************************************************************)

function TFptrCommand_50h.GetCode: Integer;
begin
  Result := $50;
end;

function TFptrCommand_50h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Amount: Int64;
  Password: Integer;
  DocResult: TFptrDocResult;
begin
  CheckMinLength(Data, 9);
  Password := BinToInt(Data, 1, 4);
  Amount := BinToInt(Data, 5, 5);
  DocResult := Device.CashIn(Password, Amount);
  Result := #$00 + AnsiChar(DocResult.Operator) + IntToBin(DocResult.DocNumber, 2);
end;

{ TFptrCommand_51h }

(******************************************************************************

  ???????

  ???????:	51H. ????? ?????????: 10 ????.
  ?????? ????????? (4 ?????)
  ????? (5 ????)

  ?????:		51H. ????? ?????????: 5 ????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30
  ???????? ????? ????????? (2 ?????)

******************************************************************************)

function TFptrCommand_51h.GetCode: Integer;
begin
  Result := $51;
end;

function TFptrCommand_51h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Amount: Int64;
  Password: Integer;
  DocResult: TFptrDocResult;
begin
  CheckMinLength(Data, 9);
  Password := BinToInt(Data, 1, 4);
  Amount := BinToInt(Data, 5, 5);
  DocResult := Device.CashOut(Password, Amount);
  Result := #$00 + AnsiChar(DocResult.Operator) + IntToBin(DocResult.DocNumber, 2);
end;

{ TFptrCommand_52h }

(******************************************************************************

  ?????? ?????

  ???????:	52H. ????? ?????????: 5 ????.
  ?????? ????????? (4 ?????)

  ?????:		52H. ????? ?????????: 3 ?????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 1?30

******************************************************************************)

function TFptrCommand_52h.GetCode: Integer;
begin
  Result := $52;
end;

function TFptrCommand_52h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.PrintHeader(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_53h }

function TFptrCommand_53h.GetCode: Integer;
begin
  Result := $53;
end;

function TFptrCommand_53h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Parameter: Byte;
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  Parameter := Ord(Data[5]);
  Operator := Device.PrintDocEnd(Password, Parameter);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_54h }

function TFptrCommand_54h.GetCode: Integer;
begin
  Result := $54;
end;

function TFptrCommand_54h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  Operator: Integer;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  Operator := Device.PrintTrailer(Password);
  Result := #$00 + AnsiChar(Operator);
end;

{ TFptrCommand_60h }

function TFptrCommand_60h.GetCode: Integer;
begin
  Result := $60;
end;

function TFptrCommand_60h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Serial: DWORD;
  Password: Integer;
begin
  CheckMinLength(Data, 8);
  Password := BinToInt(Data, 1, 4);
  Serial := BinToInt(Data, 5, 4);
  Device.WriteSerial(Password, Serial);
  Result := #$00;
end;

{ TFptrCommand_62h }

(******************************************************************************

  ?????? ????? ??????? ? ??

  ???????:	62H. ????? ?????????: 6 ????.
  ?????? ?????????????? ??? ?????????? ?????????????? (4 ?????)
  ??? ??????? (1 ????)
    "0" - ????? ???? ???????,
    "1" - ????? ??????? ????? ????????? ???????????????

  ?????:		62H. ????? ?????????: 29 ????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 29, 30
  ????? ??????? ?????? ?????? (8 ????)
  ????? ??????? ???? ??????? (6 ????) ??? ?????????? ?? 2: FFh FFh FFh FFh FFh FFh
  ????? ??????? ????????? ?????? (6 ????) ??? ?????????? ?? 2: FFh FFh FFh FFh FFh FFh
  ????? ??????? ????????? ??????? (6 ????) ??? ?????????? ?? 2: FFh FFh FFh FFh FFh FFh

*******************************************************************************)

function TFptrCommand_62h.GetCode: Integer;
begin
  Result := $62;
end;

function TFptrCommand_62h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  RequestType: Byte;
  FMTotals: TFMTotals;
begin
  CheckMinLength(Data, 5);
  Password := BinToInt(Data, 1, 4);
  RequestType := Ord(Data[5]);
  FMTotals := Device.ReadFMTotals(Password, RequestType);
  Result := #$00 +
    AnsiChar(FMTotals.Operator) +
    IntToBin(FMTotals.SaleTotal, 8) +
    IntToBin(FMTotals.BuyTotal, 6) +
    IntToBin(FMTotals.RetSaleTotal, 6) +
    IntToBin(FMTotals.RetBuyTotal, 6);
end;

{ TFptrCommand_63h }

(******************************************************************************

  ?????? ???? ????????? ?????? ? ??

  ???????:	63H. ????? ?????????: 5 ????.
  ?????? ?????????????? ??? ?????????? ?????????????? (4 ?????)

  ?????:		63H. ????? ?????????: 7 ????.
  ??? ?????? (1 ????)
  ?????????? ????? ????????? (1 ????) 29, 30
  ??? ????????? ?????? (1 ????) "0" - ???????????? (???????????????), "1" - ??????? ????
  ???? (3 ?????) ??-??-??

*******************************************************************************)

function TFptrCommand_63h.GetCode: Integer;
begin
  Result := $63;
end;

function TFptrCommand_63h.Execute(Device: TPrinterEmulator;
  const Data: AnsiString): AnsiString;
var
  Password: Integer;
  FMRecordResult: TFMRecordResult;
begin
  CheckMinLength(Data, 4);
  Password := BinToInt(Data, 1, 4);
  FMRecordResult.Operator := Device.FindOperator(Password,
    TABLE_PASSWORDS_INDEX_SYS_ADMIN);
  FMRecordResult.Data.RecType := 0;
  FMRecordResult.Data.Date := Device.Date;
  Result := #$00 +
    AnsiChar(FMRecordResult.Operator) +
    AnsiChar(FMRecordResult.Data.RecType) +
    AnsiChar(FMRecordResult.Data.Date.Day) +
    AnsiChar(FMRecordResult.Data.Date.Month) +
    AnsiChar(FMRecordResult.Data.Date.Year);
end;

end.
