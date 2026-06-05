unit FiscalPrinterDriver;

interface

uses
  // VCL
  Windows, SysUtils, Classes, Variants, SyncObjs, Graphics, Math, StrUtils,
  DateUtils,
  // 3'd
  TntClasses, JvGIF, JvPCX, PngImage, uZintBarcode, uZintInterface,
  // Opos
  Opos, OposException, OposFptr, OposFptrHi, OposUtils, OposFptrUtils,
  // This
  untDriver,

  PrinterTypes, BinStream, StringUtils,
  SerialPort, PrinterTable, LogFile, ByteUtils, FiscalPrinterTypes,
  DeviceTables, PrinterModel, XmlModelReader, PrinterConnection,
  CommunicationError, VersionInfo, DefaultModel, DriverTypes,
  TableParameter, DebugUtils, ClassLogger, DriverError,
  FiscalPrinterStatistics, ParameterValue, EJReportParser,
  PrinterParameters, DirectIOAPI, FileUtils,
  PrinterDeviceFilter, TLV, CsvPrinterTableFormat, MalinaParams, DriverContext,
  PrinterFonts, TLVParser, TLVTags, GS1Barcode, EKMClient, WException,
  TntSysUtils, gnugettext, RegExpr;

type
  { TFiscalPrinterDriver }

  TFiscalPrinterDriver = class(TInterfacedObject, IFiscalPrinterDevice)
  private
    FDriver: TDriver;
    FDriverConnected: Boolean;
    property Driver: TDriver read FDriver;
    procedure SetPrintFlags(Flags: Byte);
    function IntToAmount(Value: Int64): Currency;
    function IntToQuantity(Value: Int64): Double;
    function AmountToInt(Value: Currency): Int64;
    function GetDepartment(ADepartment: Integer): Integer;
    procedure ApplyDriverConnection;
    procedure EnsureConnected;
    procedure CheckDriver(Code: Integer);
    procedure SetDriverPassword(Password: DWORD);
    procedure MapLongStatusFromDriver(var Status: TLongPrinterStatus);
    procedure MapShortStatusFromDriver(var Status: TShortPrinterStatus);
    procedure SetPrinterStatusFromDriver;
  protected
    function ReceiptClose22(const P: TFSCloseReceiptParams2;
      var R: TFSCloseReceiptResult2): Integer;
  public
    FFFDVersion: TFFDVersion;
    FContext: TDriverContext;
    FCapSubtotalRound: Boolean;
    FCapDiscount: Boolean;
    FCapBarLine: Boolean;
    FCapScaleGraphics: Boolean;
    FCapBarcode2D: Boolean;
    FCapGraphics1: Boolean;
    FCapGraphics2: Boolean;
    FCapGraphics512: Boolean;
    FCapFiscalStorage: Boolean;
    FCapReceiptDiscount: Boolean;
    FCapFontInfo: Boolean;
    FDiscountMode: Integer;
    FDocPrintMode: Integer;
    FIsFiscalized: Boolean;
    FCapParameters2: Boolean;
    FCapCloseReceipt3: Boolean;
    FParameters2: TPrinterParameters2;
    FIsOnline: Boolean;
    FResultCode: Integer;
    FResultText: WideString;
    FLogger: TClassLogger;
    FTaxPassword: DWORD;        // tax officer password
    FSysPassword: DWORD;        // system administrator password
    FUsrPassword: DWORD;        // regular user password
    FModel: TPrinterModel;
    FModelData: TPrinterModelRec;
    FTables: TPrinterTables;
    FFields: TPrinterFields;
    FModels: TPrinterModels;
    FOnCommand: TCommandEvent;
    FOnPrinterStatus: TNotifyEvent;
    FBeforeCommand: TCommandEvent;
    FDeviceTables: TDeviceTables;
    FConnection: IPrinterConnection;
    FValidDeviceMetrics: Boolean;
    FDeviceMetrics: TDeviceMetrics;
    FLock: TCriticalSection;
    FStatistics: TFiscalPrinterStatistics;
    FOnConnect: TNotifyEvent;
    FOnDisconnect: TNotifyEvent;
    FFilter: TFiscalPrinterFilter;
    FAmountDecimalPlaces: Integer;
    FOnProgress: TProgressEvent;
    FFontInfo: TFontInfoList;
    FTaxInfo: TTaxInfoList;
    FPrinterStatus: TPrinterStatus;
    FLongStatus: TLongPrinterStatus;
    FShortStatus: TShortPrinterStatus;
    FCapFooterFlag: Boolean;
    FFooterFlag: Boolean;
    FCapEnablePrint: Boolean;
    FLastDocMac: Int64;
    FLastDocNumber: Int64;
    FLastDocTotal: Int64;
    FLastDocDate: TPrinterDate;
    FLastDocTime: TPrinterTime;
    FSTLVTag: TTLV;
    FSTLVStarted: Boolean;
    FTLVItems: TStrings;
    FCondensedFont: Boolean;
    FHeadToCutterDistanse: Integer;
    FCutterToCombDistanse: Integer;

    procedure PrintLineFont(const Data: TTextRec);
    procedure SetPrinterStatus(Value: TPrinterStatus);
    procedure WriteLogModelParameters(const Model: TPrinterModelRec);

    function GetModelsFileName: WideString;
    function SelectModel: TPrinterModel;
    function GetPrinterModel: TPrinterModel;
    function GetDeviceMetrics: TDeviceMetrics;
    function MinProtocolVersion(V1, V2: Integer): Boolean;
    function CenterLine(const Line: WideString): WideString;
    function AlignLine(const Line: WideString; PrintWidth: Integer;
      Alignment: TTextAlignment = taLeft): WideString;
    procedure SplitText(const Text: WideString; Font: Integer;
      Lines: TTntStrings);
    function ValidFieldValue(const FieldInfo: TPrinterFieldRec;
      const FieldValue: WideString): Boolean;
    function GetStatistics: TFiscalPrinterStatistics;
    function GetResultCode: Integer;
    function GetResultText: WideString;
    function ReadEJActivationText(MaxCount: Integer): WideString;
    function GetIsOnline: Boolean;
    function GetOnConnect: TNotifyEvent;
    function GetOnDisconnect: TNotifyEvent;
    procedure SetOnConnect(const Value: TNotifyEvent);
    procedure SetOnDisconnect(const Value: TNotifyEvent);
    procedure SetIsOnline(Value: Boolean);
    procedure OpenDay;
    procedure UpdateDepartment(var P: TPriceReg);
    procedure CheckGraphicsSize(Line: Word);
    function GetAmountDecimalPlaces: Integer;
    procedure SetAmountDecimalPlaces(const Value: Integer);
    procedure PrintBarcodeZInt(const Barcode: TBarcodeRec);
    function DrawScale(const P: TDrawScale): Integer;
    function Is1DBarcode(Symbology: Integer): Boolean;
    procedure LoadBitmap(StartLine: Integer; Bitmap: TBitmap);
    function GetLineData(Bitmap: TBitmap; Index: Integer): AnsiString;
    procedure ProgressEvent(Progress: Integer);
    function Is2DBarcode(Symbology: Integer): Boolean;
    procedure Connect;
    procedure Disconnect;
    function WaitForPrinting: TPrinterStatus;
    function ReadPrinterStatus: TPrinterStatus;
    procedure AlignBitmap(Bitmap: TBitmap; const Barcode: TBarcodeRec;
      HScale: Integer; PrintWidthInDots: Integer);
    function PrintBarcode2D(const Barcode: TBarcode2D): Integer;
    function LoadBarcode2D(const Data: TBarcode2DData): Integer;
    function PrintQRCode2D(Barcode: TBarcodeRec): Integer;
    function GetMaxGraphicsHeight: Integer;
    function GetMaxGraphicsWidth: Integer;
    procedure LoadBitmap320(StartLine: Integer; Bitmap: TBitmap);
    procedure LoadBitmap512(StartLine: Integer; Bitmap: TBitmap;
      Scale: Integer);
    function ReadEJDocumentText(MACNumber: Integer): WideString;
    function ReadEJDocument(MACNumber: Integer; var Line: WideString): Integer;
    function ParseEJDocument(const Text: WideString): TEJDocument;
    function FSSale(P: TFSSale): Integer;
    function FSSale2(P: TFSSale2): Integer;

    function ProcessLine(const Line: WideString): Boolean;
    function FSReadStatus(var R: TFSStatus): Integer;
    function FSFindDocument(DocNumber: Integer; var R: TFSDocument): Integer;
    function FSReadDocMac(var DocMac: Int64): Integer;

    function FSReadBlock(const P: TFSBlockRequest;
      var Block: AnsiString): Integer;
    function FSStartWrite(DataSize: Word; var BlockSize: Byte): Integer;
    function FSWriteBlock(const Block: TFSBlock): Integer;
    function FSReadBlockData: AnsiString;
    procedure FSWriteBlockData(const BlockData: AnsiString);
    function FSReadState(var R: TFSState): Integer;
    function ReadCapFiscalStorage: Boolean;
    function GetErrorText(Code: Integer): WideString;
    function OpenFiscalDay: Boolean;
    function GetCapFiscalStorage: Boolean;
    function GetCapReceiptDiscount: Boolean;
    procedure PrintCommStatus;
    procedure WriteFPParameter(ParamId: Integer; const Value: WideString);
    function GetDiscountMode: Integer;
    function GetIsFiscalized: Boolean;
    function ReadDayTotalsByReceiptType(Index: Integer): Int64;
    function ReadFPTotals(Flags: Integer): TFMTotals;
    function ReadDayTotals: TFMTotals;
    function LoadPicture(Picture: TPicture; StartLine: Integer): Integer;

    procedure PrintString(Flags: Byte; const Line: WideString);
    procedure WriteFields(Table: TPrinterTable);
    function FSReadTicket(var R: TFSTicket): Integer;
    function GetLogger: ILogFile;
    function GetMalinaParams: TMalinaParams;
    function GetCapDiscount: Boolean;
    function ReadLoaderVersion(var Version: WideString): Integer;
    function ReceiptCancelPassword(Password: Integer): Integer;
    function IsCapFooterFlag: Boolean;
    function GetPrintFlags(Flags: Integer): Integer;
    procedure SetFooterFlag(Value: Boolean);
    procedure PrintQRCode3(Barcode: TBarcodeRec);
    function GetBlockSize(BlockSize: Integer): Integer;
    function ReadFSDocument(Number: Integer): WideString;
    procedure PrintFSDocument(Number: Integer);
    function FSReadDocData(var P: TFSReadDocData): Integer;
    function FSReadDocument(var P: TFSReadDocument): Integer;
    function FSStartOpenDay: Integer;
    function IsMobilePrinter: Boolean;
    procedure EkmCheckBarcode(const Barcode: TGS1Barcode);
    function CheckItemCode(const Barcode: WideString): Integer;
    function LoadBarcodeData(BlockType: Integer; const Barcode: WideString): Integer;
    function SendItemBarcode(const Barcode: WideString;
      MarkType: Integer): Integer;
    function IsFSDocumentOpened: Boolean;
    function FSCancelDocument: Integer;
    function GetLastDocNumber: Int64;
    function GetLastDocMac: Int64;
    function GetLastDocTotal: Int64;
    function GetLastDocDate: TPrinterDate;
    function GetLastDocTime: TPrinterTime;
    function PrintItemText(const S: WideString): WideString;
    procedure WriteTLVItems;
    function ReadDocPrintMode: Integer;
    procedure Initialize;
    procedure CorrectDate;
    function ReadDocData: WideString;
    procedure CheckPrinterStatus;
    procedure SetCapFiscalStorage(const Value: Boolean);
    function FilterTLV(Data: AnsiString): AnsiString;
    function GetFFDVersion: TFFDVersion;
    function GetFont(Font: Integer): TFontInfo;
    function ValidFont(Font: Integer): Boolean;
  protected
    function GetMaxGraphicsWidthInBytes: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Lock;
    procedure Unlock;
    procedure FullCut;
    procedure StopDump;
    procedure UpdateInfo;
    procedure PartialCut;
    procedure LoadModels;
    procedure SaveModels;
    procedure ReadModelParameters;
    procedure CashIn(Amount: Int64);
    procedure CashOut(Amount: Int64);
    procedure SetLongSerial(Serial: Int64);
    procedure SetSysPassword(const Value: DWORD);
    procedure SetTaxPassword(const Value: DWORD);
    procedure SetUsrPassword(const Value: DWORD);
    procedure OpenPort(PortNumber, BaudRate, ByteTimeout: Integer);

    function Beep: Integer;
    function GetDumpBlock: TDumpBlock;
    function ReadLongStatus: TLongPrinterStatus;
    function GetFMFlags(Flags: Byte): TFMFlags;
    function ReadShortStatus: TShortPrinterStatus;
    function StartDump(DeviceCode: Integer): Integer;
    function PrintBoldString(Flags: Byte; const Text: WideString): Integer;
    function GetPortParams(Port: Byte): TPortParams;
    function SetPortParams(Port: Byte; const PortParams: TPortParams): Integer;
    procedure PrintDocHeader(const DocName: WideString; DocNumber: Word);
    procedure StartTest(Interval: Byte);
    function ReadCashRegister(ID: Integer): Int64;
    function ReadCashReg2(RegID: Integer): Int64;
    function ReadOperatingRegister(ID: Byte): Word;
    function ReadOperatingReg(ID: Byte; var R: TOperRegisterRec): Integer;
    procedure WriteLicense(License: Int64);
    function ReadLicense: Int64;
    function WriteTable(Table, Row, Field: Integer; const FieldValue: WideString): Integer;
    function WriteTableInt(Table, Row, Field, Value: Integer): Integer;
    function DoWriteTable(Table, Row, Field: Integer;
      const FieldValue: WideString): Integer;
    function ReadTableBin(Table, Row, Field: Integer): WideString;
    function ReadTableStr(Table, Row, Field: Integer): WideString;
    function ReadTableInt(Table, Row, Field: Integer): Integer;
    procedure SetPointPosition(PointPosition: Byte);
    procedure SetTime(const Time: TPrinterTime);
    procedure WriteDate(const Date: TPrinterDate);
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
    procedure PrintXReport;
    procedure PrintZReport;
    procedure PrintDepartmentsReport;
    procedure PrintTaxReport;
    procedure PrintHeader;
    procedure PrintDocTrailer(Flags: Byte);
    procedure PrintTrailer;
    procedure WriteSerial(Serial: DWORD);
    procedure InitFiscalMemory;
    function OpenSlipDoc(Params: TSlipParams): TDocResult;
    function OpenStdSlip(Params: TStdSlipParams): TDocResult;
    function SlipOperation(Params: TSlipOperation; Operation: TPriceReg): Integer;
    function SlipStdOperation(LineNumber: Byte; Operation: TPriceReg): Integer;
    function SlipDiscount(Params: TSlipDiscountParams; Discount: TSlipDiscount): Integer;
    function SlipStdDiscount(Discount: TSlipDiscount): Integer;
    function SlipClose(Params: TCloseReceiptParams): TCloseReceiptResult;
    function ReadFMTotals(Flags: Byte; var R: TFMTotals): Integer;
    function ContinuePrint: Integer;

    function PrintBarcode(const Barcode: WideString): Integer;
    function PrintGraphics(Line1, Line2: Word): Integer;
    function PrintGraphics1(Line1, Line2: Byte): Integer;
    function PrintGraphics2(Line1, Line2: Word): Integer;
    function PrintGraphics3(Line1, Line2: Word): Integer; overload;
    function PrintGraphics3(const P: TPrintGraphics3): Integer; overload;
    function LoadGraphics(Line: Word; Data: AnsiString): Integer;
    function LoadGraphics1(Line: Byte; Data: AnsiString): Integer;
    function LoadGraphics2(Line: Word; Data: AnsiString): Integer;
    function LoadGraphics3(Line: Word; Data: AnsiString): Integer; overload;
    function LoadGraphics3(const P: TLoadGraphics3): Integer; overload;
    function PrintBarLine(Height: Word; Data: AnsiString): Integer;
    function PrintGraphicsLine(Height: Word; Flags: Byte; Data: WideString): Integer;
    function ReadDeviceMetrics: TDeviceMetrics;
    function GetDayDiscountTotal: Int64;
    function GetRecDiscountTotal: Int64;
    function GetDayItemTotal: Int64;
    function GetRecItemTotal: Int64;
    function GetDayItemVoidTotal: Int64;
    function GetRecItemVoidTotal: Int64;
    function ReadTableInfo(Table: Byte; var R: TPrinterTableRec): Integer;
    function ReadTableStructure(Table: Byte; var R: TPrinterTableRec): Integer;
    function ReadFieldStructure(Table, Field: Byte): TPrinterFieldRec;
    function GetEJSesssionResult(Number: Word; var Text: WideString): Integer;
    function GetEJReportLine(var Line: WideString): Integer;
    function ReadEJActivation(var Line: WideString): Integer;
    function EJReportStop: Integer;
    procedure Check(Code: Integer);
    function GetEJStatus1(var Status: TEJStatus1): Integer;
    procedure PrintStringFont(Flags, Font: Byte; const Line: WideString);
    procedure PrintJournal(DayNumber: Integer);

    function GetSysPassword: DWORD;
    function GetTaxPassword: DWORD;
    function GetUsrPassword: DWORD;
    function GetPrintWidth: Integer; overload;
    function GetPrintWidth(Font: Integer): Integer; overload;

    function ExecuteStream(Stream: TBinStream): Integer;

    function GetSubtotal: Int64;
    function ReceiptCancel: Integer;
    procedure CancelReceipt;
    function Sale(Operation: TPriceReg): Integer;
    function Buy(Operation: TPriceReg): Integer;
    function RetSale(Operation: TPriceReg): Integer;
    function RetBuy(Operation: TPriceReg): Integer;
    function Storno(Operation: TPriceReg): Integer;
    function ReceiptClose(const P: TCloseReceiptParams;
      var R: TCloseReceiptResult): Integer;
    function ReceiptClose2(const P: TFSCloseReceiptParams2;
      var R: TFSCloseReceiptResult2): Integer;
    function ReceiptClose3(const P: TFSCloseReceiptParams2;
      var R: TFSCloseReceiptResult2): Integer;

    function ReceiptDiscount(Operation: TAmountOperation): Integer;
    function ReceiptDiscount2(Operation: TReceiptDiscount2): Integer;
    function ReceiptCharge(Operation: TAmountOperation): Integer;
    function ReceiptStornoDiscount(Operation: TAmountOperation): Integer;
    function ReceiptStornoCharge(Operation: TAmountOperation): Integer;
    function PrintReceiptCopy: Integer;
    function OpenReceipt(ReceiptType: Byte): Integer;
    function FormatLines(const Line1, Line2: WideString): WideString;
    procedure PrintLines(const Line1, Line2: WideString);
    function FormatBoldLines(const Line1, Line2: WideString): WideString;
    procedure EJTotalsReportDate(const Parameters: TDateReport);
    procedure EJTotalsReportNumber(const Parameters: TNumberReport);
    function ExecuteStream2(Stream: TBinStream): Integer;
    function GetFieldValue(FieldInfo: TPrinterFieldRec; const Value: WideString): AnsiString;
    function FieldToStr(FieldInfo: TPrinterFieldRec; const Value: WideString): WideString;
    function BinToFieldValue(FieldInfo: TPrinterFieldRec; const Value: WideString): WideString;
    class function ByteToTimeout(Value: Byte): DWORD;
    class function TimeoutToByte(Value: Integer): Byte;
    procedure InterruptReport;
    function ReadDaysRange: TDayRange;
    function ReadFMLastRecordDate: TFMRecordDate;
    function ReadFiscInfo(FiscNumber: Byte): TFiscInfo;
    function LongFisc(NewPassword: DWORD; PrinterID, FiscalID: Int64): TLongFiscResult;
    function Fiscalization(Password, PrinterID, FiscalID: Int64): TFiscalizationResult;
    function ReportOnDateRange(ReportType: Byte; Range: TDayDateRange): TDayRange;
    function ReportOnNumberRange(ReportType: Byte; Range: TDayNumberRange): TDayRange;
    function DecodeEJFlags(Flags: Byte): TEJFlags;
    function GetLine(const Text: WideString): WideString; overload;
    function GetLine(const Text: WideString; MinLength, MaxLength: Integer): WideString; overload;
    function GetText(const Text: WideString; MinLength: Integer): WideString;
    class function BaudRateToCode(BaudRate: Integer): Integer;
    class function CodeToBaudRate(BaudRate: Integer): Integer;
    function FieldToInt(FieldInfo: TPrinterFieldRec; const Value: WideString): Integer;
    function ReadFieldInfo(Table, Field: Byte; var R: TPrinterFieldRec): Integer;
    function ExecuteData(const TxData: AnsiString; var RxData: AnsiString): Integer; overload;
    function GetModel: TPrinterModelRec;
    function GetOnCommand: TCommandEvent;
    function GetOnPrinterStatus: TNotifyEvent;
    function GetBeforeCommand: TCommandEvent;
    procedure SetOnPrinterStatus(Value: TNotifyEvent);
    procedure SetOnCommand(Value: TCommandEvent);
    procedure SetBeforeCommand(Value: TCommandEvent);
    procedure PrintText(const Data: TTextRec); overload;
    procedure PrintText(Station: Integer; const Text: WideString); overload;
    function GetTables: TDeviceTables;
    procedure SetTables(const Value: TDeviceTables);

    procedure ClosePort;
    procedure Close;
    procedure Open(AConnection: IPrinterConnection);
    procedure ReleaseDevice;
    procedure ClaimDevice(PortNumber, Timeout: Integer);
    function CapGraphics: Boolean;
    function CapShortEcrStatus: Boolean;
    function CapPrintStringFont: Boolean;
    function CapParameter(ParamID: Integer): Boolean;
    function ReadParameter(ParamID: Integer): Integer;
    function ValidField(Table, Field: Integer): Boolean;
    function ValidParameter(const Parameter: TTableParameter): Boolean;
    function ValidRow(Table, Row: Integer): Boolean;
    procedure WriteParameter(ParamID, ValueID: Integer);
    procedure ReadModelData;
    procedure ReadModelTables;
    function QueryEJActivation: TEJActivation;
    procedure AddFilter(AFilter: IFiscalPrinterFilter);
    procedure RemoveFilter(AFilter: IFiscalPrinterFilter);
    function IsDayOpened(Mode: Integer): Boolean;
    procedure PrintBarcode2(const Barcode: TBarcodeRec);
    function GetStartLine: Integer;
    function LoadImage(const FileName: WideString; StartLine: Integer): Integer;
    procedure PrintImage(const FileName: WideString; StartLine: Integer);
    procedure PrintImageScale(const FileName: WideString; StartLine, Scale: Integer);
    procedure PrintTextFont(Station: Integer; Font: Integer; const Text: WideString);
    procedure LoadTables(const Path: WideString);
    procedure FSWriteTLV2(const TLVData: AnsiString);

    function FSWriteTLV(const TLVData: AnsiString): Integer;
    function FSPrintCalcReport(var R: TFSCalcReport): Integer;
    function FSReadCommStatus(var R: TFSCommStatus): Integer;
    function FSReadExpiration(var R: TCommandFF03): Integer;
    function FSReadFiscalResult(var R: TFSFiscalResult): Integer;
    function FSWriteTag(TagID: Integer; const Data: WideString): Integer;

    function ReadSysOperatorNumber: Integer;
    function ReadUsrOperatorNumber: Integer;
    function readOperatorNumber(Password: Integer): Integer;
    function WriteCustomerAddress(const Value: WideString): Integer;

    function ReadShortStatus2(Password: Integer): TShortPrinterStatus;
    function GetTaxInfo(Tax: Integer): TTaxInfo;
    function ReadDiscountMode: Integer;
    function ReadFPParameter(ParamId: Integer): WideString;
    function FSReadTotals(var R: TFMTotals): Integer;
    function FSReadCorrectionTotals(var R: TFMTotals): Integer;
    function FSReadTotalsByPayType(RecType: Byte; var R: TFSTotalsByPayType): Integer;
    function ReadFPDayTotals(Flags: Integer): TFMTotals;
    function ReadTotalsByReceiptType(Index: Integer): Int64;
    function FSPrintCorrectionReceipt(var Command: TFSCorrectionReceipt): Integer;
    function FSPrintCorrectionReceipt2(var Data: TFSCorrectionReceipt2): Integer;
    function GetParameters: TPrinterParameters;
    function GetContext: TDriverContext;
    function IsRecOpened: Boolean;
    function GetCapSubtotalRound: Boolean;
    function ReadParameters2(var R: TPrinterParameters2): Integer;
    function FSFiscalization(const P: TFSFiscalization; var R: TFDDocument): Integer;
    function FSReFiscalization(const P: TFSReFiscalization; var R: TFDDocument): Integer;
    function GetPrinterStatus: TPrinterStatus;
    function IsCapBarcode2D: Boolean;
    function IsCapEnablePrint: Boolean;
    function ReadCashReg(ID: Integer; var R: TCashRegisterRec): Integer;
    function FSWriteTLVOperation(const AData: AnsiString): Integer;
    function FSStartCorrectionReceipt: Integer;
    function FSReadLastDocNum: Int64;
    function FSReadLastDocNum2: Int64;
    function FSReadLastMacValue: Int64;
    function FSReadLastMacValue2: Int64;
    function FSCheckItemCode(P: TFSCheckItemCode;
      var R: TFSCheckItemResult): Integer;
    function FSSyncRegisters: Integer;
    function FSReadMemory(var R: TFSReadMemoryResult): Integer;
    function FSWriteTLVFromBuffer: Integer;
    function FSRandomData(var Data: AnsiString): Integer;
    function FSAuthorize(const DataToAuthorize: AnsiString): Integer;
    function FSAcceptItemCode(Action: Integer): Integer;
    function FSClearMCCheckResults: Integer;
    function FSBindItemCode(P: TFSBindItemCode;
      var R: TFSBindItemCodeResult): Integer;
    function FSReadTicketStatus(var R: TFSTicketStatus): Integer;
    function FSReadMarkStatus(var R: TFSMarkStatus): Integer;
    function FSStartReadTickets(var R: TFSTicketParams): Integer;
    function FSReadNextTicket(var R: TFSTicketData): Integer;
    function FSConfirmTicket(const P: TFSTicketNumber): Integer;
    function FSReadDeviceInfo(var R: string): Integer;
    function FSReadDocSize(var R: TFSDocSize): Integer;
    procedure STLVWrite;
    procedure STLVWriteOp;
    function STLVGetHex: string;
    procedure STLVBegin(TagID: Integer);
    procedure STLVAddTag(TagID: Integer; TagValue: string);
    procedure ResetPrinter;
    function BeginZReport: Integer;
    function GetDocPrintMode: Integer;
    function IsCorrectItemCode(const P: TFSCheckItemResult): Boolean;
    procedure CheckCorrectItemCode(const P: TFSCheckItemResult);
    function BarcodeTo1162Value(const Barcode: AnsiString): AnsiString;
    function FSReadRegTag(var R: TFSReadRegTagCommand): Integer;
    function GetHeaderHeight: Integer;
    function GetTrailerHeight: Integer;
    function GetTaxInfoList: TTaxInfoList;
    function GetTaxCount: Integer;
    function ReadTaxInfoList: TTaxInfoList;
    function ReadFontInfoList: TFontInfoList;
    procedure WriteTaxRate(Tax, Rate: Integer);
    procedure BarcodeToBitmap(const Barcode: TBarcodeRec; Bitmap: TBitmap);

    property IsOnline: Boolean read GetIsOnline;
    property Tables: TPrinterTables read FTables;
    property Fields: TPrinterFields read FFields;
    property Model: TPrinterModelRec read GetModel;
    property ResultText: WideString read GetResultText;
    property ResultCode: Integer read GetResultCode;
    property Connection: IPrinterConnection read FConnection write FConnection;
    property CapFiscalStorage: Boolean read GetCapFiscalStorage write SetCapFiscalStorage;
    property DiscountMode: Integer read GetDiscountMode;
    property CapReceiptDiscount: Boolean read GetCapReceiptDiscount;
    property PrinterModel: TPrinterModel read GetPrinterModel;
    property Statistics: TFiscalPrinterStatistics read GetStatistics;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnConnect: TNotifyEvent read GetOnConnect write SetOnConnect;
    property OnDisconnect: TNotifyEvent read GetOnDisconnect write SetOnDisconnect;
    property AmountDecimalPlaces: Integer read GetAmountDecimalPlaces write SetAmountDecimalPlaces;
    property Parameters: TPrinterParameters read GetParameters;
    property Logger: ILogFile read GetLogger;
    property MalinaParams: TMalinaParams read GetMalinaParams;
    property CapDiscount: Boolean read GetCapDiscount;
    property CapSubtotalRound: Boolean read GetCapSubtotalRound;
    property LastDocMac: Int64 read GetLastDocMac;
    property LastDocNumber: Int64 read GetLastDocNumber;
    property CondensedFont: Boolean read FCondensedFont;
    property TaxInfoList: TTaxInfoList read GetTaxInfoList;
    property TaxCount: Integer read GetTaxCount;
  end;

  { EDisabledException }

  EDisabledException = class(WideException);
  EFiscalPrinterException = class(WideException);

const
  PrinterBaudRates: array [0..6] of Integer = (
    CBR_2400,
    CBR_4800,
    CBR_9600,
    CBR_19200,
    CBR_38400,
    CBR_57600,
    CBR_115200);


procedure RenderBarcode(Bitmap: TBitmap; Symbol: PZintSymbol; Is1D: Boolean);

implementation

function GetDataBlock(const Data: AnsiString;
  MinLength, MaxLength: Integer): AnsiString;
begin
  Result := Copy(Data, 1, MaxLength);
  Result := Result + StringOfChar(#0, MinLength - Length(Result));
end;

function TLVToText(const TLVData: AnsiString): AnsiString;
var
  Parser: TTLVParser;
begin
  Parser := TTLVParser.Create;
  try
    Parser.ShowTagNumbers := True;
    Result := Parser.ParseTLV(TLVData);
  finally
    Parser.Free;
  end;
end;

procedure CheckParam(Value, Min, Max: Int64; const ParamName: WideString);
begin
  if (Value < Min)or(Value > Max) then
    raise Exception.Create(Format('%s, %s', [_('Invalid parameter value'), ParamName]));
end;

function IntToAlignment(Alignment: Integer): Integer;
begin
  Result := 1;
  case Alignment of
    BARCODE_ALIGNMENT_CENTER: Result := 1;
    BARCODE_ALIGNMENT_LEFT: Result := 0;
    BARCODE_ALIGNMENT_RIGHT: Result := 2;
  end;
end;

function CenterGraphicsLine(const Data: AnsiString; MaxLen, Scale: Integer): AnsiString;
begin
  if Scale = 0 then
    raiseException('Scale = 0');

  Result := Data;
  Result := Copy(Result, 1, MaxLen);
  Result := StringOfChar(#0, (MaxLen - Length(Result)*Scale) div (2 * Scale)) + Result;
  Result := Result + StringOfChar(#0, (MaxLen - Length(Result)*Scale) div (2 * Scale));
  Result := Copy(Result, 1, MaxLen);
end;

const
  MinLineWidth = 40;
  DrvFRConnectionLocal = 0;
  DrvFRConnectionTCP = 1;
  DrvFRConnectionDCOM = 2;
  DrvFRConnectionTCPSocket = 6;

function PrinterDateToBin(Value: TPrinterDate): AnsiString;
begin
  SetLength(Result, Sizeof(Value));
  Move(Value, Result[1], Sizeof(Value));
end;

procedure CheckMinLength(const Data: AnsiString; MinLength: Integer);
begin
  if Length(Data) < MinLength then
    raise ECommunicationError.Create(_('Answer data length is too short'));
end;

{ TFiscalPrinterDriver }

constructor TFiscalPrinterDriver.Create;
begin
  inherited Create;
  FDriver := TDriver.Create(nil);
  FDriverConnected := False;
  SetLength(FTaxInfo, 4);
  FTLVItems := TStringList.Create;
  FSTLVTag := TTLV.Create(nil);
  FContext := TDriverContext.Create;
  FLogger := TClassLogger.Create('TFiscalPrinterDriver', FContext.Logger);
  FLock := TCriticalSection.Create;
  FFields := TPrinterFields.Create;
  FTables := TPrinterTables.Create;
  FModels := TPrinterModels.Create;
  FStatistics := TFiscalPrinterStatistics.Create(Parameters.Logger);
  FFilter := TFiscalPrinterFilter.Create(Parameters.Logger);
  FAmountDecimalPlaces := 2;
  FCapReceiptDiscount := True;
  FCapGraphics1 := True;
  LoadModels;
  Initialize;
end;

destructor TFiscalPrinterDriver.Destroy;
begin
  try
    if FDriverConnected then
      FDriver.Disconnect;
  except
  end;
  FDriverConnected := False;
  FLock.Free;
  FFields.Free;
  FTables.Free;
  FModels.Free;
  FConnection := nil;
  FLogger.Free;
  FStatistics.Free;
  FFilter.Free;
  FContext.Free;
  FSTLVTag.Free;
  FTLVItems.Free;
  FDriver.Free;
  inherited Destroy;
end;

function TFiscalPrinterDriver.GetDepartment(ADepartment: Integer): Integer;
begin
  Result := ADepartment;
end;

function TFiscalPrinterDriver.IntToAmount(Value: Int64): Currency;
begin
  Result := Value / 100;
end;

function TFiscalPrinterDriver.IntToQuantity(Value: Int64): Double;
begin
  Result := Value / 1000;
end;

function TFiscalPrinterDriver.AmountToInt(Value: Currency): Int64;
begin
  Result := Round(Value * 100);
end;

function DateTimeToPrinterDate(Value: TDateTime): TPrinterDate;
var
  Year, Month, Day: Word;
begin
  DecodeDate(Value, Year, Month, Day);
  Result.Day := Day;
  Result.Month := Month;
  Result.Year := Year - 2000;
end;

function DateTimeToPrinterTime(Value: TDateTime): TPrinterTime;
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(Value, Hour, Min, Sec, MSec);
  Result.Hour := Hour;
  Result.Min := Min;
  Result.Sec := Sec;
end;

function DateTimeToPrinterDateTime(Value: TDateTime): TPrinterDateTime;
var
  D: TPrinterDate;
  T: TPrinterTime;
begin
  D := DateTimeToPrinterDate(Value);
  T := DateTimeToPrinterTime(Value);
  Result.Day := D.Day;
  Result.Month := D.Month;
  Result.Year := D.Year;
  Result.Hour := T.Hour;
  Result.Min := T.Min;
  Result.Sec := T.Sec;
end;

function DriverConnectionType(ConnectionType: Integer): Integer;
begin
  case ConnectionType of
    ConnectionTypeLocal:
      Result := DrvFRConnectionLocal;
    ConnectionTypeDCOM:
      Result := DrvFRConnectionDCOM;
    ConnectionTypeTCP:
      Result := DrvFRConnectionTCP;
    ConnectionTypeSocket:
      Result := DrvFRConnectionTCPSocket;
  else
    Result := DrvFRConnectionLocal;
  end;
end;

procedure TFiscalPrinterDriver.CheckDriver(Code: Integer);
begin
  Driver.Check(Code);
end;

procedure TFiscalPrinterDriver.SetDriverPassword(Password: DWORD);
begin
  Driver.Password := Password;
end;

procedure TFiscalPrinterDriver.ApplyDriverConnection;
begin
  Driver.Password := GetUsrPassword;
  Driver.ComNumber := Parameters.PortNumber;
  Driver.BaudRate := Parameters.BaudRate;
  Driver.Timeout := Parameters.ByteTimeout;
  Driver.ConnectionType := DriverConnectionType(Parameters.ConnectionType);
  Driver.UseIPAddress := Parameters.ConnectionType in
    [ConnectionTypeTCP, ConnectionTypeSocket];
  if Driver.UseIPAddress then
  begin
    Driver.IPAddress := Parameters.RemoteHost;
    Driver.TCPPort := Parameters.RemotePort;
  end;
end;

procedure TFiscalPrinterDriver.EnsureConnected;
begin
  ApplyDriverConnection;
  if not FDriverConnected then
  begin
    CheckDriver(Driver.Connect);
    FDriverConnected := True;
    FIsOnline := True;
    if Assigned(FOnConnect) then
      FOnConnect(Self);
  end;
end;

procedure VersionChars(const Version: WideString; var Hi, Lo: Char);
var
  S: AnsiString;
  P: Integer;
begin
  S := AnsiString(Version);
  P := Pos('.', S);
  if (P > 1) and (P < Length(S)) then
  begin
    Hi := S[1];
    Lo := S[P + 1];
  end else
  if Length(S) >= 2 then
  begin
    Hi := S[1];
    Lo := S[2];
  end else
  begin
    Hi := '0';
    Lo := '0';
  end;
end;

procedure SetPrinterFlagsFromWord(var Flags: TPrinterFlags; Value: Word);
begin
  FillChar(Flags, SizeOf(Flags), 0);
  Flags.Value := Value;
  Flags.JrnNearEnd := TestBit(Value, 0);
  Flags.RecNearEnd := TestBit(Value, 1);
  Flags.SlpUpSensor := TestBit(Value, 2);
  Flags.SlpLoSensor := TestBit(Value, 3);
  Flags.DecimalPosition := TestBit(Value, 4);
  Flags.EJPresent := TestBit(Value, 5);
  Flags.JrnEmpty := TestBit(Value, 6);
  Flags.RecEmpty := TestBit(Value, 7);
  Flags.JrnLeverUp := TestBit(Value, 8);
  Flags.RecLeverUp := TestBit(Value, 9);
  Flags.CoverOpened := TestBit(Value, 10);
  Flags.DrawerOpened := TestBit(Value, 11);
  Flags.Bit12 := TestBit(Value, 12);
  Flags.Bit13 := TestBit(Value, 13);
  Flags.EJNearEnd := TestBit(Value, 14);
  Flags.Bit15 := TestBit(Value, 15);
end;

procedure TFiscalPrinterDriver.MapShortStatusFromDriver(
  var Status: TShortPrinterStatus);
begin
  FillChar(Status, SizeOf(Status), 0);
  Status.OperatorNumber := Driver.OperatorNumber;
  Status.Flags := Driver.ECRFlags;
  Status.Mode := Driver.ECRMode;
  Status.AdvancedMode := Driver.ECRAdvancedMode;
end;

procedure TFiscalPrinterDriver.MapLongStatusFromDriver(
  var Status: TLongPrinterStatus);
begin
  FillChar(Status, SizeOf(Status), 0);
  Status.OperatorNumber := Driver.OperatorNumber;
  VersionChars(Driver.ECRSoftVersion,
    Status.FirmwareVersionHi, Status.FirmwareVersionLo);
  Status.FirmwareBuild := Driver.ECRBuild;
  Status.FirmwareDate := DateTimeToPrinterDate(Driver.ECRSoftDate);
  Status.LogicalNumber := Driver.LogicalNumber;
  Status.DocumentNumber := Driver.DocumentNumber;
  Status.Flags := Driver.ECRFlags;
  Status.Mode := Driver.ECRMode;
  Status.AdvancedMode := Driver.ECRAdvancedMode;
  Status.PortNumber := Driver.PortNumber;
  VersionChars(Driver.FMSoftVersion, Status.FMVersionHi, Status.FMVersionLo);
  Status.FMBuild := Driver.FMBuild;
  Status.FMFirmwareDate := DateTimeToPrinterDate(Driver.FMSoftDate);
  Status.Date := DateTimeToPrinterDate(Driver.ECRDate);
  Status.Time := DateTimeToPrinterTime(Driver.ECRTime);
  Status.FMFlags := Driver.FMFlags;
  Status.SerialNumber := Driver.SerialNumber;
  Status.DayNumber := Driver.SessionNumber;
  Status.RemainingFiscalMemory := Driver.FreeMemorySize;
  Status.RegistrationNumber := Driver.RegistrationNumber;
  Status.FreeRegistration := Driver.FreeRegistration;
  Status.FiscalID := Driver.INN;
end;

procedure TFiscalPrinterDriver.SetPrinterStatusFromDriver;
var
  Status: TPrinterStatus;
begin
  FillChar(Status, SizeOf(Status), 0);
  Status.OperatorNumber := Driver.OperatorNumber;
  Status.Mode := Driver.ECRMode;
  Status.AdvancedMode := Driver.ECRAdvancedMode;
  SetPrinterFlagsFromWord(Status.Flags, Driver.ECRFlags);
  SetPrinterStatus(Status);
end;

procedure TFiscalPrinterDriver.Disconnect;
begin
  if FDriverConnected then
  begin
    Driver.Disconnect;
    FDriverConnected := False;
    if Assigned(FOnDisconnect) then
      FOnDisconnect(Self);
  end;
  Initialize;
end;

procedure TFiscalPrinterDriver.Initialize;
begin
  Tables.Clear;
  Fields.Clear;
  FValidDeviceMetrics := False;
  FCapSubtotalRound := False;
  FCapDiscount := False;
  FCapBarLine := True;
  FCapScaleGraphics := False;
  FCapBarcode2D := False;
  FCapGraphics1 := True;
  FCapGraphics2 := True;
  FCapGraphics512 := False;
  FCapFiscalStorage := False;
  FCapReceiptDiscount := False;
  FCapFontInfo := False;
  FIsFiscalized := False;
  FCapParameters2 := False;
  FIsOnline := False;
  FCapFooterFlag := False;
  FFooterFlag := False;
  FCapEnablePrint := False;
  FFFDVersion := TFFDVersion(-1);
end;

function TFiscalPrinterDriver.GetCapSubtotalRound: Boolean;
begin
  Result := FCapSubtotalRound;
end;

function TFiscalPrinterDriver.GetCapDiscount: Boolean;
begin
  Result := FCapDiscount;
end;

function TFiscalPrinterDriver.GetParameters: TPrinterParameters;
begin
  Result := FContext.Parameters;
end;

function TFiscalPrinterDriver.GetLogger: ILogFile;
begin
  Result := FContext.Logger;
end;

function TFiscalPrinterDriver.GetMalinaParams: TMalinaParams;
begin
  Result := FContext.MalinaParams;
end;

function TFiscalPrinterDriver.GetCapReceiptDiscount: Boolean;
begin
  Result := FCapReceiptDiscount;
end;

procedure TFiscalPrinterDriver.AddFilter(AFilter: IFiscalPrinterFilter);
begin
  FFilter.AddFilter(AFilter);
end;

procedure TFiscalPrinterDriver.RemoveFilter(AFilter: IFiscalPrinterFilter);
begin
  FFilter.RemoveFilter(AFilter);
end;

function TFiscalPrinterDriver.GetResultCode: Integer;
begin
  Result := FResultCode;
end;

function TFiscalPrinterDriver.GetResultText: WideString;
begin
  Result := FResultText;
end;

function TFiscalPrinterDriver.GetStatistics: TFiscalPrinterStatistics;
begin
  Result := FStatistics;
end;

procedure TFiscalPrinterDriver.Lock;
begin
  FLock.Enter;
end;

procedure TFiscalPrinterDriver.Unlock;
begin
  FLock.Leave;
end;

function TFiscalPrinterDriver.GetModelsFileName: WideString;
begin
  Result := IncludeTrailingBackSlash(ExtractFilePath(GetDllFileName)) +
      ModelsFileName;
end;

procedure TFiscalPrinterDriver.LoadModels;
var
  Reader: TXmlModelReader;
begin
  Reader := TXmlModelReader.Create(FModels);
  try
    Reader.Load(GetModelsFileName);
  except
    on E: Exception do
      Logger.Error('TFiscalPrinterDriver.LoadModels', E);
  end;
  Reader.Free;
end;

procedure TFiscalPrinterDriver.ReadModelData;
begin
  ReadModelTables;
  ReadModelParameters;
end;

procedure TFiscalPrinterDriver.ReadModelTables;
var
  FieldValue: AnsiString;
  RowNumber: Integer;
  FieldNumber: Integer;
  ResultCode: Integer;
  TableNumber: Integer;
  Tables: TPrinterTables;
  Table: TPrinterTable;
  Field: TPrinterField;
  FieldRec: TPrinterFieldRec;
  TableRec: TPrinterTableRec;
begin
  Tables := GetPrinterModel.Tables;

  Tables.Clear;
  TableNumber := 1;
  repeat
    ResultCode := ReadTableStructure(TableNumber, TableRec);
    if ResultCode <> 0 then Break;

    Table := Tables.Add(TableRec);
    for RowNumber := 1 to Table.RowCount do
    begin
      for FieldNumber := 1 to Table.FieldCount do
      begin
        FieldRec := ReadFieldStructure(TableNumber, FieldNumber);
        FieldValue := ReadTableStr(TableNumber, RowNumber, FieldNumber);
        Field := Table.Fields.Add(FieldRec);
        Field.Value := FieldValue;
      end;
    end;
    Inc(TableNumber);
  until ResultCode <> 0;
end;

procedure TFiscalPrinterDriver.ReadModelParameters;
var
  Text: AnsiString;
  ParameterID: Integer;
  FieldValue: AnsiString;
  RowNumber: Integer;
  FieldNumber: Integer;
  ResultCode: Integer;
  TableNumber: Integer;
  FieldRec: TPrinterFieldRec;
  TableRec: TPrinterTableRec;

  Parameters: TTableParameters;
  ParameterRec: TTableParameterRec;
begin
  ParameterID := 1;
  Parameters := GetPrinterModel.Parameters;

  Parameters.Clear;
  TableNumber := 1;
  repeat
    ResultCode := ReadTableStructure(TableNumber, TableRec);
    if ResultCode <> 0 then Break;


    Text := Tnt_WideFormat('// %d, %s', [TableRec.Number, TableRec.Name]);
    OutputDebugString(PChar(Text));

    for RowNumber := 1 to TableRec.RowCount do
    begin
      for FieldNumber := 1 to TableRec.FieldCount do
      begin
        FieldRec := ReadFieldStructure(TableNumber, FieldNumber);
        FieldValue := ReadTableStr(TableNumber, RowNumber, FieldNumber);

        ParameterRec.ID := ParameterID;
        ParameterRec.Name := FieldRec.Name;
        ParameterRec.Table := TableNumber;
        ParameterRec.Row := RowNumber;
        ParameterRec.Field := FieldNumber;
        ParameterRec.Size := FieldRec.Size;
        ParameterRec.FieldType := FieldRec.FieldType;
        ParameterRec.MinValue := FieldRec.MinValue;
        ParameterRec.MaxValue := FieldRec.MaxValue;
        ParameterRec.DefValue := FieldValue;
        Parameters.Add(ParameterRec);

        Text := Tnt_WideFormat('PARAMID_%d = %d; // %d,%d,%d %s, "%s"', [
          ParameterID, ParameterID, TableNumber, RowNumber, FieldNumber,
          FieldRec.Name, FieldValue]);

        OutputDebugString(PChar(Text));
        Inc(ParameterID);
      end;
    end;
    Inc(TableNumber);
  until ResultCode <> 0;
end;

procedure TFiscalPrinterDriver.SaveModels;
var
  Reader: TXmlModelReader;
begin
  Reader := TXmlModelReader.Create(FModels);
  try
    //ReadModelParameters;
    Reader.SetDefaults;
    Reader.Save(GetModelsFileName);
  finally
    Reader.Free;
  end;
end;

function TFiscalPrinterDriver.GetLine(const Text: WideString): WideString;
begin
  Result := GetLine(Text, MinLineWidth, GetPrintWidth);
end;

function TFiscalPrinterDriver.GetLine(const Text: WideString;
  MinLength, MaxLength: Integer): WideString;
begin
  Result := Copy(Text, 1, MaxLength);
  Result := Result + StringOfChar(#0, MinLength - Length(Result));
end;

function TFiscalPrinterDriver.GetText(const Text: WideString;
  MinLength: Integer): WideString;
begin
  Result := Text;
  if Parameters.ItemTextMode = ItemTextModeTrim then
  begin
    if not FCapFiscalStorage then
      Result := Copy(Result, 1, GetPrintWidth);
  end else
  begin
    Result := Copy(Result, 1, 200);
  end;
  if Length(Result) < MinLength then
    Result := Result + StringOfChar(#0, MinLength - Length(Result));
end;

function TFiscalPrinterDriver.GetPrintWidth: Integer;
begin
  Result := GetPrintWidth(Parameters.FontNumber);
end;

function TFiscalPrinterDriver.ValidFont(Font: Integer): Boolean;
begin
  Result := (Font >= 1) and (Font <= Length(FFontInfo));
end;

function TFiscalPrinterDriver.GetPrintWidth(Font: Integer): Integer;
begin
  Result := 0;
  if ValidFont(Font) then
  begin
    if FFontInfo[Font-1].CharWidth <> 0 then
      Result := FFontInfo[Font-1].PrintWidth div FFontInfo[Font-1].CharWidth;
  end;
  if Result = 0 then Result := 40;
end;

function TFiscalPrinterDriver.GetSysPassword: DWORD;
begin
  Result := FSysPassword;
end;

function TFiscalPrinterDriver.GetTaxPassword: DWORD;
begin
  Result := FTaxPassword;
end;

function TFiscalPrinterDriver.GetUsrPassword: DWORD;
begin
  Result := FUsrPassword;
end;

procedure TFiscalPrinterDriver.SetSysPassword(const Value: DWORD);
begin
  FSysPassword := Value;
end;

procedure TFiscalPrinterDriver.SetTaxPassword(const Value: DWORD);
begin
  FTaxPassword := Value;
end;

procedure TFiscalPrinterDriver.SetUsrPassword(const Value: DWORD);
begin
  FUsrPassword := Value;
end;

function TFiscalPrinterDriver.ReadFieldStructure(Table, Field: Byte): TPrinterFieldRec;
var
  AField: TPrinterField;
begin
  AField := Fields.Find(Table, Field);
  if AField <> nil then
  begin
    Result := AField.Data;
  end else
  begin
    Check(ReadFieldInfo(Table, Field, Result));
    TPrinterField.Create(Fields, Result);
  end;
end;

function TFiscalPrinterDriver.ValidFieldValue(
  const FieldInfo: TPrinterFieldRec;
  const FieldValue: WideString): Boolean;
var
  I: Integer;
begin
  Result := True;
  if FieldInfo.FieldType = PRINTER_FIELD_TYPE_INT then
  begin
    I := StrToInt(FieldValue);
    Result := (I >= FieldInfo.MinValue)and(I <= FieldInfo.MaxValue);
  end;
end;


function TFiscalPrinterDriver.ReadTableStructure(Table: Byte;
  var R: TPrinterTableRec): Integer;
var
  ATable: TPrinterTable;
begin
  ATable := Tables.ItemByNumber(Table);
  if ATable <> nil then
  begin
    Result := 0;
    R := ATable.Data;
  end else
  begin
    Result := ReadTableInfo(Table, R);
    if Result = 0 then
      TPrinterTable.Create(Tables, R);
  end;
end;

class function TFiscalPrinterDriver.BaudRateToCode(BaudRate: Integer): Integer;
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

class function TFiscalPrinterDriver.CodeToBaudRate(BaudRate: Integer): Integer;
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

class function TFiscalPrinterDriver.ByteToTimeout(Value: Byte): DWORD;
begin
  case Value of
    0..150   : Result := Value;
    151..249 : Result := (Value-149)*150;
  else
    Result := (Value-248)*15000;
  end;
end;

class function TFiscalPrinterDriver.TimeoutToByte(Value: Integer): Byte;
begin
  case Value of
    0..150        : Result := Value;
    151..15000    : Result := Round(Value/150) + 149;
    15001..105000 : Result := Round(Value/15000) + 248;
  else
    Result := Value;
  end;
end;

procedure TFiscalPrinterDriver.SetIsOnline(Value: Boolean);
begin
  if Value <> IsOnline then
  begin
    FIsOnline := Value;
    if Value then
    begin
      if Assigned(FOnConnect) then FOnConnect(Self); { !!! }
    end else
    begin
      if Assigned(FOnDisconnect) then FOnDisconnect(Self); { !!! }
    end;
  end;
end;

function TFiscalPrinterDriver.GetErrorText(Code: Integer): WideString;
begin
  Result := PrinterTypes.GetErrorText(Code, FCapFiscalStorage);
end;

function TFiscalPrinterDriver.ExecuteData(const TxData: AnsiString;
  var RxData: AnsiString): Integer;
begin
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
  RxData := '';
end;

function TFiscalPrinterDriver.ExecuteStream(Stream: TBinStream): Integer;
begin
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
  Stream.Data := '';
end;

function TFiscalPrinterDriver.ExecuteStream2(Stream: TBinStream): Integer;
begin
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
  Stream.Data := Chr(Result);
end;

procedure TFiscalPrinterDriver.CashIn(Amount: Int64);
begin
  FLogger.Debug(Format('CashIn(%d)', [Amount]));
  FFilter.BeforeCashIn;
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.Summ1 := IntToAmount(Amount);
  CheckDriver(Driver.CashIncome);
  FFilter.CashIn(Amount);
end;

procedure TFiscalPrinterDriver.CashOut(Amount: Int64);
begin
  FLogger.Debug(Format('CashOut(%d)', [Amount]));
  FFilter.BeforeCashOut;
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.Summ1 := IntToAmount(Amount);
  CheckDriver(Driver.CashOutcome);
  FFilter.CashOut(Amount);
end;

function TFiscalPrinterDriver.StartDump(DeviceCode: Integer): Integer;
begin
  FLogger.Debug(Format('StartDump(%d)', [DeviceCode]));
  EnsureConnected;
  SetDriverPassword(GetTaxPassword);
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.GetDumpBlock: TDumpBlock;
begin
  FillChar(Result, SizeOf(Result), 0);
  EnsureConnected;
  SetDriverPassword(GetTaxPassword);
  Check(ERROR_COMMAND_NOT_SUPPORTED);
end;

procedure TFiscalPrinterDriver.StopDump;
begin
  EnsureConnected;
  SetDriverPassword(GetTaxPassword);
end;

function TFiscalPrinterDriver.LongFisc(NewPassword: DWORD;
  PrinterID, FiscalID: Int64): TLongFiscResult;
begin
  FLogger.Debug(Format('LongFisc(%d,%d,%d)',
    [NewPassword, PrinterID, FiscalID]));
  EnsureConnected;
  SetDriverPassword(GetTaxPassword);
  Driver.NewPasswordTI := NewPassword;
  Driver.RNM := IntToStr(PrinterID);
  Driver.INN := IntToStr(FiscalID);
  CheckDriver(Driver.FiscalizationWithLongRNM);
  Result.FiscNumber := Driver.RegistrationNumber;
  Result.LeftNumber := Driver.FreeRegistration;
  Result.DayNumber := Driver.SessionNumber;
  Result.Date := DateTimeToPrinterDate(Driver.ECRDate);
end;

procedure TFiscalPrinterDriver.SetLongSerial(Serial: Int64);
begin
  FLogger.Debug(Format('SetLongSerial(%d)', [Serial]));
  EnsureConnected;
  SetDriverPassword(0);
  Driver.SerialNumber := IntToStr(Serial);
  CheckDriver(Driver.SetLongSerialNumber);
end;

function TFiscalPrinterDriver.ReadOperatorNumber(Password: Integer): Integer;
begin
  Result := ReadShortStatus2(Password).OperatorNumber;
end;

function TFiscalPrinterDriver.ReadUsrOperatorNumber: Integer;
begin
  Result := ReadShortStatus2(GetUsrPassword).OperatorNumber;
end;

function TFiscalPrinterDriver.ReadSysOperatorNumber: Integer;
begin
  Result := ReadShortStatus2(GetSysPassword).OperatorNumber;
end;

function TFiscalPrinterDriver.ReadShortStatus2(Password: Integer): TShortPrinterStatus;
begin
  EnsureConnected;
  SetDriverPassword(Password);
  CheckDriver(Driver.GetShortECRStatus);
  MapShortStatusFromDriver(Result);
  FShortStatus := Result;
end;

function TFiscalPrinterDriver.ReadShortStatus: TShortPrinterStatus;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  CheckDriver(Driver.GetShortECRStatus);
  MapShortStatusFromDriver(Result);
  FShortStatus := Result;
  SetPrinterStatusFromDriver;
end;

function TFiscalPrinterDriver.ReadLongStatus: TLongPrinterStatus;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  CheckDriver(Driver.GetECRStatus);
  MapLongStatusFromDriver(Result);
  FLongStatus := Result;
  SetPrinterStatusFromDriver;
end;

function TFiscalPrinterDriver.GetFMFlags(Flags: Byte): TFMFlags;
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

function TFiscalPrinterDriver.PrintBoldString(Flags: Byte; const Text: WideString): Integer;
begin
  FLogger.Debug(Format('PrintBoldString(%d,''%s'')',
    [Flags, Text]));

  SetPrintFlags(Flags);
  Driver.StringForPrinting := Text;
  Result := Driver.PrintWideString;
end;

function TFiscalPrinterDriver.Beep: Integer;
begin
  Result := Driver.Beep;
end;

function TFiscalPrinterDriver.SetPortParams(Port: Byte;
  const PortParams: TPortParams): Integer;
var
  Stream: TBinStream;
begin
  FLogger.Debug(Format('SetPortParams(%d,%d,%d)',
    [Port, PortParams.BaudRate, PortParams.Timeout]));

  Driver.PortNumber := Port;
  Driver.Timeout := PortParams.Timeout;
  Driver.BaudRate := PortParams.BaudRate;
  Result := Driver.SetExchangeParam;
end;

function TFiscalPrinterDriver.GetPortParams(Port: Byte): TPortParams;
begin
  Driver.PortNumber := Port;
  Driver.Check(Driver.GetExchangeParam);
  Result.BaudRate := Driver.BaudRate;
  Result.Timeout := Driver.Timeout;
end;

procedure TFiscalPrinterDriver.ResetFiscalMemory;
begin
  Driver.Check(Driver.ResetSettings);
end;

function TFiscalPrinterDriver.GetPrintFlags(Flags: Integer): Integer;
begin
  Result := Flags;
  if FCapFooterFlag and FFooterFlag then
  begin
    Result := Result or PRINTER_FLAG_FOOTER;
  end;
end;

procedure TFiscalPrinterDriver.SetPrintFlags(Flags: Byte);
begin
  Driver.UseJournalRibbon := TestBit(Flags, 0);
  Driver.UseReceiptRibbon := TestBit(Flags, 1);
  Driver.UseSlipDocument := TestBit(Flags, 2);
  Driver.UseSlipCheck := TestBit(Flags, 3);
  Driver.CarryStrings := TestBit(Flags, 6);
  Driver.DelayedPrint := TestBit(Flags, 7);
end;

procedure TFiscalPrinterDriver.PrintString(Flags: Byte;
  const Line: WideString);
begin
  FLogger.Debug(Format('PrintString(%d,''%s'')', [Flags, Line]));

  SetPrintFlags(Flags);
  Driver.StringForPrinting := Line;
  Driver.Check(Driver.PrintString);
end;

function TFiscalPrinterDriver.OpenFiscalDay: Boolean;
begin
end;

procedure TFiscalPrinterDriver.OpenDay;
begin
  Driver.Check(Driver.OpenSession);
  FFilter.OpenDay;
end;


procedure TFiscalPrinterDriver.PrintDocHeader(const DocName: WideString; DocNumber: Word);
begin
  FLogger.Debug(Format('PrintDocHeader(''%s'', %d)',
    [DocName, DocNumber]));

  Driver.DocumentName := DocName;
  Driver.DocumentNumber := DocNumber;
  Driver.Check(Driver.PrintDocumentTitle);
end;

procedure TFiscalPrinterDriver.StartTest(Interval: Byte);
begin
  FLogger.Debug(Format('StartTest(%d)', [Interval]));

  Driver.RunningPeriod := Interval;
  Driver.Check(Driver.Test);
end;

function TFiscalPrinterDriver.ReadCashReg(ID: Integer; var R: TCashRegisterRec): Integer;
begin
  FLogger.Debug(Format('ReadCashRegister(%d)', [ID]));

  Driver.RegisterNumber := ID;
  if ID <= $FF then
  begin
    Result := Driver.GetCashReg;
  end else
  begin
    Result := Driver.GetCashRegEx;
  end;
  if Result = 0 then
  begin
    R.Operator := Driver.OperatorNumber;
    R.Value := Round(Driver.ContentsOfCashRegister*100);
  end;
end;

function TFiscalPrinterDriver.ReadCashReg2(RegID: Integer): Int64;

  function ReadDayTotals(RecType: Integer): Int64;
  var
    i: Integer;
  begin
    Result := 0;
    for i := 0 to 15 do
    begin
      Result := Result + ReadCashRegister(121 + RecType + i*4);
    end;
  end;

var
  T: TFMTotals;
begin
  case RegID of
    SMFPTR_CASHREG_GRAND_TOTAL:
    begin
      T := ReadFPTotals(0);
      Result := T.SaleTotal - T.BuyTotal - T.RetSale + T.RetBuy;
    end;

    SMFPTR_CASHREG_LASTFISC_TOTAL:
    begin
      T := ReadFPTotals(1);
      Result := T.SaleTotal - T.BuyTotal - T.RetSale + T.RetBuy;
    end;

    SMFPTR_CASHREG_DAY_TOTAL_SALE:
      Result := ReadDayTotals(0);

    SMFPTR_CASHREG_DAY_TOTAL_RETSALE:
      Result := ReadDayTotals(2);

    SMFPTR_CASHREG_DAY_TOTAL_BUY:
      Result := ReadDayTotals(1);

    SMFPTR_CASHREG_DAY_TOTAL_RETBUY:
      Result := ReadDayTotals(3);

    SMFPTR_CASHREG_GRAND_TOTAL_SALE:
    begin
      T := ReadFPTotals(0);
      Result := T.SaleTotal;
    end;

    SMFPTR_CASHREG_GRAND_TOTAL_RETSALE:
    begin
      T := ReadFPTotals(0);
      Result := T.RetSale;
    end;

    SMFPTR_CASHREG_GRAND_TOTAL_BUY:
    begin
      T := ReadFPTotals(0);
      Result := T.BuyTotal;
    end;

    SMFPTR_CASHREG_GRAND_TOTAL_RETBUY:
    begin
      T := ReadFPTotals(0);
      Result := T.RetBuy;
    end;

    SMFPTR_CASHREG_CORRECTION_TOTAL_SALE:
    begin
      Check(FSReadCorrectionTotals(T));
      Result := T.SaleTotal;
    end;

    SMFPTR_CASHREG_CORRECTION_TOTAL_RETSALE:
    begin
      Check(FSReadCorrectionTotals(T));
      Result := T.RetSale;
    end;

    SMFPTR_CASHREG_CORRECTION_TOTAL_BUY:
    begin
      Check(FSReadCorrectionTotals(T));
      Result := T.BuyTotal;
    end;

    SMFPTR_CASHREG_CORRECTION_TOTAL_RETBUY:
    begin
      Check(FSReadCorrectionTotals(T));
      Result := T.RetBuy;
    end;
  else
    Result := ReadCashRegister(RegID);
  end;
end;

function TFiscalPrinterDriver.ReadCashRegister(ID: Integer): Int64;
var
  R: TCashRegisterRec;
begin
  Check(ReadCashReg(ID, R));
  Result := R.Value;
end;

function TFiscalPrinterDriver.ReadOperatingReg(ID: Byte;
  var R: TOperRegisterRec): Integer;
var
  Data: AnsiString;
  Command: AnsiString;
begin
  FLogger.Debug(Format('ReadOperatingRegister(%d)', [ID]));

  Driver.RegisterNumber := ID;
  Result := Driver.GetOperationReg;
  if Result = 0 then
  begin
    R.Operator := Driver.OperatorNumber;
    R.Value := Driver.ContentsOfOperationRegister;
  end;
end;

function TFiscalPrinterDriver.ReadOperatingRegister(ID: Byte): Word;
var
  R: TOperRegisterRec;
begin
  Check(ReadOperatingReg(ID, R));
  Result := R.Value;
end;

procedure TFiscalPrinterDriver.WriteLicense(License: Int64);
begin
  FLogger.Debug(Format('WriteLicense(%d)', [License]));
  { !!! }
end;

function TFiscalPrinterDriver.ReadLicense: Int64;
begin
  { !!! }
end;

function TFiscalPrinterDriver.DoWriteTable(
  Table, Row, Field: Integer;
  const FieldValue: WideString): Integer;
begin
  FLogger.Debug(Format('DoWriteTable(%d,%d,%d,%s)',
    [Table, Row, Field, StrToHexText(FieldValue)]));


  Driver.TableNumber := Table;
  Driver.RowNumber := Row;
  Driver.FieldNumber := Field;
  Driver.Check(Driver.GetFieldStruct);
  if Driver.FieldType then
    Driver.ValueOfFieldString := FieldValue
  else
    Driver.ValueOfFieldInteger := StrToInt(FieldValue);
  Result := Driver.WriteTable;
end;

function TFiscalPrinterDriver.ReadTableBin(Table, Row,
  Field: Integer): WideString;
begin
  FLogger.Debug(Format('ReadTableBin(%d,%d,%d)',
    [Table, Row, Field]));


  Driver.TableNumber := Table;
  Driver.RowNumber := Row;
  Driver.FieldNumber := Field;
  Driver.Check(Driver.GetFieldStruct);
  Driver.Check(Driver.ReadTable);
  if Driver.FieldType then
    Result := Driver.ValueOfFieldString
  else
    Result := IntToStr(Driver.ValueOfFieldInteger);
end;

procedure TFiscalPrinterDriver.SetPointPosition(PointPosition: Byte);
begin
  FLogger.Debug(Format('SetPointPosition(%d)',
    [PointPosition]));
  { !!! }
end;

procedure TFiscalPrinterDriver.SetTime(const Time: TPrinterTime);
begin
  FLogger.Debug(Format('SetTime(%s)',
    [PrinterTimeToStr(Time)]));

  Driver.ECRTime := PrinterTimeToTime(Time);
  Driver.Check(Driver.SetTime);
end;

procedure TFiscalPrinterDriver.WriteDate(const Date: TPrinterDate);
begin
  FLogger.Debug(Format('WriteDate(%s)',
    [PrinterDateToStr(Date)]));

  Driver.ECRDate := PrinterDateToDate(Date);
  Driver.Check(Driver.SetDate);
end;

procedure TFiscalPrinterDriver.ConfirmDate(const Date: TPrinterDate);
begin
  FLogger.Debug(Format('ConfirmDate(%.2d.%.2d.%.4d)',
    [Date.Day, Date.Month, Date.Year + 2000]));

  Driver.ECRDate := PrinterDateToDate(Date);
  Driver.Check(Driver.ConfirmDate);
end;

procedure TFiscalPrinterDriver.InitializeTables;
begin
  Driver.Check(Driver.InitTable);
end;

procedure TFiscalPrinterDriver.CutPaper(CutType: Byte);
begin
  if not FParameters2.Flags.CapCutter then Exit;
  FLogger.Debug(Format('CutPaper(%d)', [CutType]));


  Driver.CutType := CutType = PRINTER_CUTTYPE_PARTIAL;
  Driver.Check(Driver.CutCheck);
end;

procedure TFiscalPrinterDriver.FullCut;
begin
  CutPaper(PRINTER_CUTTYPE_FULL);
end;

procedure TFiscalPrinterDriver.PartialCut;
begin
  CutPaper(PRINTER_CUTTYPE_PARTIAL);
end;

function TFiscalPrinterDriver.ReadFontInfo(FontNumber: Byte): TFontInfo;
begin
  FLogger.Debug(Format('ReadFontInfo(%d)', [FontNumber]));

  Driver.FontType := FontNumber;
  Driver.Check(Driver.GetFontMetrics);
  Result.PrintWidth := Driver.PrintWidth;
  Result.CharWidth := Driver.CharWidth;
  Result.CharHeight := Driver.CharHeight;
  Result.FontCount := Driver.FontCount;
end;

procedure TFiscalPrinterDriver.ResetTotalizers;
begin
  Driver.Check(Driver.ResetSummary);
end;

procedure TFiscalPrinterDriver.OpenDrawer(DrawerNumber: Byte);
begin
  FLogger.Debug(Format('OpenDrawer(%d)', [DrawerNumber]));

  Driver.DrawerNumber := DrawerNumber;
  Driver.Check(Driver.OpenDrawer);
end;

procedure TFiscalPrinterDriver.FeedPaper(Station: Byte; Lines: Byte);
begin
  FLogger.Debug(Format('FeedPaper(%d,%d)',
    [Station, Lines]));

  SetPrintFlags(Station);
  Driver.StringQuantity := Lines;
  Driver.Check(Driver.FeedDocument);
end;

procedure TFiscalPrinterDriver.EjectSlip(Direction: Byte);
begin
  FLogger.Debug(Format('EjectSlip(%d)',
    [Direction]));
end;

procedure TFiscalPrinterDriver.StopTest;
begin
  Driver.Check(Driver.InterruptTest);
end;

procedure TFiscalPrinterDriver.PrintActnTotalizers;
begin

end;

function TFiscalPrinterDriver.ReadTableInfo(Table: Byte;
  var R: TPrinterTableRec): Integer;
begin
  FLogger.Debug(Format('ReadTableInfo(%d)', [Table]));

  Driver.TableNumber := Table;
  Result := Driver.GetTableStruct;
  if Result = 0 then
  begin
    R.Number := Table;
    R.Name := Driver.TableName;
    R.RowCount := Driver.RowNumber;
    R.FieldCount := Driver.FieldNumber;
  end;
end;

function TFiscalPrinterDriver.ReadFieldInfo(Table, Field: Byte;
  var R: TPrinterFieldRec): Integer;
begin
  FLogger.Debug(Format('ReadFieldInfo(%d,%d)', [Table, Field]));

  Driver.TableNumber := Table;
  Driver.FieldNumber := Field;
  Result := Driver.GetFieldStruct;
  if Result = 0 then
  begin
    R.Table := Table;
    R.Field := Field;
    R.Name := Driver.FieldName;
    R.FieldType := PRINTER_FIELD_TYPE_INT;
    if Driver.FieldType then
      R.FieldType := PRINTER_FIELD_TYPE_STR;

    R.Size := Driver.FieldSize;
    R.MinValue := Driver.MINValueOfField;
    R.MaxValue := Driver.MAXValueOfField;
  end;
end;

procedure TFiscalPrinterDriver.PrintStringFont(Flags, Font: Byte;
  const Line: WideString);
var
  Text: AnsiString;
begin
  Text := Line;
  Flags := GetPrintFlags(Flags);

  if Text = '' then Text := ' ';
  FLogger.Debug(Format('PrintStringFont(%d,%d, ''%s'')',
    [Flags, Font, Text]));


  SetPrintFlags(Flags);
  Driver.FontType := Font;
  Driver.StringForPrinting := Line;
  Driver.Check(Driver.PrintStringWithFont);
end;

procedure TFiscalPrinterDriver.PrintXReport;
begin
  Driver.Check(Driver.PrintReportWithoutCleaning);
end;

procedure TFiscalPrinterDriver.PrintLines(const Line1, Line2: WideString);
begin
  PrintStringFont(PRINTER_STATION_REC, Parameters.FontNumber,
    FormatLines(Line1, Line2));
end;

procedure TFiscalPrinterDriver.PrintCommStatus;
var
  i: Integer;
  R: TFSCommStatus;
begin
  if not CapFiscalStorage then Exit;

  WaitForPrinting;
  for i := 1 to 10 do
  begin
    if FSReadCommStatus(R) = 0 then
    begin
      PrintText(PRINTER_STATION_REC, StringOfChar('-', GetPrintWidth));
      PrintLines('ÊÎËÈ×ÅÑÒÂÎ ÑÎÎÁÙÅÍÈÉ ÄËß ÎÔÄ:', IntToStr(R.DocumentCount));
      PrintLines('ÍÎÌÅÐ ÏÅÐÂÎÃÎ ÄÎÊÓÌÅÍÒÀ ÄËß ÎÔÄ:', IntToStr(R.DocumentNumber));
      PrintLines('ÄÀÒÀ ÏÅÐÂÎÃÎ ÄÎÊÓÌÅÍÒÀ:', PrinterDateTimeToStr2(R.DocumentDate));
      Break;
    end;
    Sleep(1000)
  end;
end;

function TFiscalPrinterDriver.BeginZReport: Integer;
begin
  Result := Driver.FNBeginCloseSession;
end;

procedure TFiscalPrinterDriver.PrintZReport;
var
  FSState: TFSState;
begin
  if CapFiscalStorage then
  begin
    if FTLVItems.Count > 0 then
    begin
      Check(BeginZReport);
      WriteTLVItems;
    end;
  end;

  Driver.Check(Driver.PrintReportWithCleaning);
  FFilter.PrintZReport;
  try
    // Update document number
    if CapFiscalStorage then
    begin
      Check(FSReadState(FSState));
      Check(FSReadDocMac(FLastDocMac));
      FLastDocNumber := FSState.DocNumber;
    end;
    PrintCommStatus;
  except
    on E: Exception do
    begin
      Logger.Debug('PrintZReport: ' + GetExceptionMessage(E));
    end;
  end;
end;

procedure TFiscalPrinterDriver.PrintDepartmentsReport;
begin
  Driver.Check(Driver.PrintDepartmentReport);
end;

procedure TFiscalPrinterDriver.PrintTaxReport;
begin
  Driver.Check(Driver.PrintTaxReport);
end;

procedure TFiscalPrinterDriver.PrintHeader;
begin
  Driver.Check(Driver.PrintCliche);
end;

procedure TFiscalPrinterDriver.PrintDocTrailer(Flags: Byte);
begin
  FLogger.Debug(Format('PrintDocTrailer(%d)', [Flags]));

  Driver.FinishDocumentMode := Flags;
  Driver.Check(Driver.FinishDocument);
end;

procedure TFiscalPrinterDriver.PrintTrailer;
begin
  Driver.Check(Driver.PrintTrailer);
end;

procedure TFiscalPrinterDriver.WriteSerial(Serial: DWORD);
begin
  FLogger.Debug(Format('WriteSerial(%d)', [Serial]));

end;

procedure TFiscalPrinterDriver.InitFiscalMemory;
begin
end;

function BinToInt2(const Data: AnsiString; Index, Size: Integer): Int64;
begin
  Result := 0;
  if Copy(Data, Index, Size) <> StringOfChar(#$FF, Size) then
    Result := BinToInt(Data, Index, Size);
end;

function TFiscalPrinterDriver.ReadFMTotals(Flags: Byte; var R: TFMTotals): Integer;
begin
  FLogger.Debug(Format('ReadFMTotals(%d)', [Flags]));
end;

function TFiscalPrinterDriver.ReadFMLastRecordDate: TFMRecordDate;
begin

end;

function TFiscalPrinterDriver.ReadDaysRange: TDayRange;
begin
end;

function TFiscalPrinterDriver.Fiscalization(Password, PrinterID,
  FiscalID: Int64): TFiscalizationResult;
begin
  FLogger.Debug(Format('Fiscalization(%d,%d,%d)',
    [Password, PrinterID, FiscalID]));

end;

function TFiscalPrinterDriver.ReportOnDateRange(ReportType: Byte;
  Range: TDayDateRange): TDayRange;
begin
  FLogger.Debug(Format('ReportOnDateRange(%d,%s,%s)',
    [ReportType, PrinterDateToStr(Range.Date1), PrinterDateToStr(Range.Date2)]));
end;

function TFiscalPrinterDriver.ReportOnNumberRange(ReportType: Byte;
  Range: TDayNumberRange): TDayRange;
begin
  FLogger.Debug(Format('ReportOnDateRange(%d,%d,%d)',
    [ReportType, Range.Number1, Range.Number2]));

end;

procedure TFiscalPrinterDriver.InterruptReport;
begin
end;

function TFiscalPrinterDriver.ReadFiscInfo(FiscNumber: Byte): TFiscInfo;
begin
  FLogger.Debug(Format('ReadFiscInfo((%d)',
    [FiscNumber]));

end;

function TFiscalPrinterDriver.OpenSlipDoc(Params: TSlipParams): TDocResult;
begin
end;

function TFiscalPrinterDriver.OpenStdSlip(Params: TStdSlipParams): TDocResult;
begin
end;

function TFiscalPrinterDriver.SlipOperation(Params: TSlipOperation;
  Operation: TPriceReg): Integer;
begin
end;

function TFiscalPrinterDriver.SlipStdOperation(LineNumber: Byte;
  Operation: TPriceReg): Integer;
begin
end;

function TFiscalPrinterDriver.SlipDiscount(Params: TSlipDiscountParams;
  Discount: TSlipDiscount): Integer;
begin
end;

function TFiscalPrinterDriver.SlipStdDiscount(Discount: TSlipDiscount): Integer;
begin
end;

function TFiscalPrinterDriver.SlipClose(Params: TCloseReceiptParams): TCloseReceiptResult;
begin
end;

procedure TFiscalPrinterDriver.UpdateDepartment(var P: TPriceReg);
var
  S: AnsiString;
  V, Code: Integer;
begin
  if Parameters.DepartmentInText then
  begin
    S := Copy(P.Text, 1, 2);
    Val(S, V, Code);
    if (Code = 0)and(V in [1..16]) then
    begin
      P.Department := V;
      P.Text := Copy(P.Text, 3, Length(P.Text));
    end;
  end;
end;

function TFiscalPrinterDriver.PrintItemText(const S: WideString): WideString;
var
  i: Integer;
  Line: AnsiString;
  Lines: TTntStrings;
begin
  Result := S;
  if Parameters.ItemTextMode <> ItemTextModePrint then exit;

  Lines := TTntStringList.Create;
  try
    SplitText(S, 1, Lines);
    if Lines.Count = 1 then Exit;

    for i := 0 to Lines.Count-2 do
    begin
      Line := Lines[i];
      PrintStringFont(PRINTER_STATION_REC, 1, Line)
    end;
    Result := Lines[Lines.Count-1];
  finally
    Lines.Free;
  end;
end;

function TFiscalPrinterDriver.Sale(Operation: TPriceReg): Integer;
begin
  UpdateDepartment(Operation);
  Driver.Quantity := Operation.Quantity/1000;
  Driver.Price := IntToAmount(Operation.Price);
  Driver.Department := Operation.Department;
  Driver.Tax1 := OPeration.Tax1;
  Driver.Tax2 := OPeration.Tax2;
  Driver.Tax3 := OPeration.Tax3;
  Driver.Tax4 := OPeration.Tax4;
  Driver.StringForPrinting := OPeration.Text;
  Result := Driver.Sale;
  if Result = 0 then
    FFilter.Sale(Operation);
end;

function TFiscalPrinterDriver.Buy(Operation: TPriceReg): Integer;
begin
  UpdateDepartment(Operation);
  Driver.Quantity := Operation.Quantity/1000;
  Driver.Price := IntToAmount(Operation.Price);
  Driver.Department := Operation.Department;
  Driver.Tax1 := OPeration.Tax1;
  Driver.Tax2 := OPeration.Tax2;
  Driver.Tax3 := OPeration.Tax3;
  Driver.Tax4 := OPeration.Tax4;
  Driver.StringForPrinting := OPeration.Text;
  Result := Driver.Buy;
  if Result = 0 then
    FFilter.Buy(Operation);
end;

function TFiscalPrinterDriver.RetSale(Operation: TPriceReg): Integer;
begin
  UpdateDepartment(Operation);
  Driver.Quantity := Operation.Quantity/1000;
  Driver.Price := IntToAmount(Operation.Price);
  Driver.Department := Operation.Department;
  Driver.Tax1 := OPeration.Tax1;
  Driver.Tax2 := OPeration.Tax2;
  Driver.Tax3 := OPeration.Tax3;
  Driver.Tax4 := OPeration.Tax4;
  Driver.StringForPrinting := OPeration.Text;
  Result := Driver.ReturnSale;
  if Result = 0 then
    FFilter.RetSale(Operation);
end;

function TFiscalPrinterDriver.RetBuy(Operation: TPriceReg): Integer;
begin
  UpdateDepartment(Operation);
  Driver.Quantity := Operation.Quantity/1000;
  Driver.Price := IntToAmount(Operation.Price);
  Driver.Department := Operation.Department;
  Driver.Tax1 := OPeration.Tax1;
  Driver.Tax2 := OPeration.Tax2;
  Driver.Tax3 := OPeration.Tax3;
  Driver.Tax4 := OPeration.Tax4;
  Driver.StringForPrinting := OPeration.Text;
  Result := Driver.ReturnBuy;
  if Result = 0 then
    FFilter.RetBuy(Operation);
end;

function TFiscalPrinterDriver.Storno(Operation: TPriceReg): Integer;
begin
  UpdateDepartment(Operation);
  Driver.Quantity := Operation.Quantity/1000;
  Driver.Price := IntToAmount(Operation.Price);
  Driver.Department := Operation.Department;
  Driver.Tax1 := OPeration.Tax1;
  Driver.Tax2 := OPeration.Tax2;
  Driver.Tax3 := OPeration.Tax3;
  Driver.Tax4 := OPeration.Tax4;
  Driver.StringForPrinting := OPeration.Text;
  Result := Driver.Storno;
  if Result = 0 then
    FFilter.Storno(Operation);
end;

function TFiscalPrinterDriver.ReceiptClose(const P: TCloseReceiptParams;
  var R: TCloseReceiptResult): Integer;
var
  Stream: TBinStream;
begin
  WriteTLVItems;
  FFilter.BeforeCloseReceipt;

  Driver.Summ1 := IntToAmount(P.CashAmount);
  Driver.Summ2 := IntToAmount(P.Amount2);
  Driver.Summ3 := IntToAmount(P.Amount3);
  Driver.Summ4 := IntToAmount(P.Amount4);
  Driver.DiscountOnCheck := IntToAmount(P.PercentDiscount);
  Driver.Tax1 := P.Tax1;
  Driver.Tax2 := P.Tax2;
  Driver.Tax3 := P.Tax3;
  Driver.Tax4 := P.Tax4;
  Driver.StringForPrinting := P.Text;
  Result := Driver.CloseCheck;
  if Result = 0 then
  begin
    R.OperatorNumber := Driver.OperatorNumber;
    R.Change := AmountToInt(Driver.Change);
    FFilter.CloseReceipt(P, R);
  end;
end;

function TFiscalPrinterDriver.ReceiptDiscount(
  Operation: TAmountOperation): Integer;
begin
  Driver.Price := IntToAmount(Operation.Amount);
  Driver.Department := GetDepartment(Operation.Department);
  Driver.Tax1 := OPeration.Tax1;
  Driver.Tax2 := OPeration.Tax2;
  Driver.Tax3 := OPeration.Tax3;
  Driver.Tax4 := OPeration.Tax4;
  Driver.StringForPrinting := OPeration.Text;
  Result := Driver.Discount;
  if Result = 0 then
    FFilter.ReceiptDiscount(Operation);
end;

function TFiscalPrinterDriver.ReceiptDiscount2(
  Operation: TReceiptDiscount2): Integer;
begin
end;

function TFiscalPrinterDriver.ReceiptCharge(
  Operation: TAmountOperation): Integer;
begin
  Driver.Price := IntToAmount(Operation.Amount);
  Driver.Department := GetDepartment(Operation.Department);
  Driver.Tax1 := OPeration.Tax1;
  Driver.Tax2 := OPeration.Tax2;
  Driver.Tax3 := OPeration.Tax3;
  Driver.Tax4 := OPeration.Tax4;
  Driver.StringForPrinting := OPeration.Text;
  Result := Driver.Charge;
  if Result = 0 then
    FFilter.ReceiptCharge(Operation);
end;

function TFiscalPrinterDriver.ReceiptCancel: Integer;
begin
  Result := Driver.CancelCheck;
end;

function TFiscalPrinterDriver.ReceiptCancelPassword(Password: Integer): Integer;
begin
  Driver.Password := Password;
  Result := Driver.CancelCheck;
end;

procedure TFiscalPrinterDriver.CancelReceipt;
var
  i: Integer;
  Password: Integer;
begin
  if IsRecOpened then
  begin
    if ReceiptCancelPassword(GetUsrPassword) = 0 then
    begin
      WaitForPrinting;
      Exit;
    end;
    if ReceiptCancelPassword(GetSysPassword) = 0 then
    begin
      WaitForPrinting;
      Exit;
    end;
    for i := 1 to 29 do
    begin
      Password := ReadTableInt(2, i, 1);
      if ReceiptCancelPassword(Password) = 0 then
      begin
        WaitForPrinting;
        Exit;
      end;
    end;
  end;
  if IsFSDocumentOpened then
  begin
    Check(FSCancelDocument);
  end;
end;


function TFiscalPrinterDriver.GetSubtotal: Int64;
begin
  Driver.Check(Driver.CheckSubTotal);
  
end;

function TFiscalPrinterDriver.ReceiptStornoDiscount(
  Operation: TAmountOperation): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.Summ1 := IntToAmount(Operation.Amount);
  Driver.Tax1 := Operation.Tax1;
  Driver.Tax2 := Operation.Tax2;
  Driver.Tax3 := Operation.Tax3;
  Driver.Tax4 := Operation.Tax4;
  Driver.StringForPrinting := Operation.Text;
  Result := Driver.StornoDiscount;
end;

(******************************************************************************

  Void Surcharge

  Command:	8BH. Length: 54 bytes.
  ?	Operator password (4 bytes)
  ?	Void Surcharge value (5 bytes) 0000000000?9999999999
  ?	Tax 1 (1 byte) '0' - no tax, '1'?'4' - tax ID
  ?	Tax 2 (1 byte) '0' - no tax, '1'?'4' - tax ID
  ?	Tax 3 (1 byte) '0' - no tax, '1'?'4' - tax ID
  ?	Tax 4 (1 byte) '0' - no tax, '1'?'4' - tax ID
  ?	Text (40 bytes)
  Answer:		8BH. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.ReceiptStornoCharge(
  Operation: TAmountOperation): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.Summ1 := IntToAmount(Operation.Amount);
  Driver.Tax1 := Operation.Tax1;
  Driver.Tax2 := Operation.Tax2;
  Driver.Tax3 := Operation.Tax3;
  Driver.Tax4 := Operation.Tax4;
  Driver.StringForPrinting := Operation.Text;
  Result := Driver.StornoCharge;
end;

(******************************************************************************

  Print Last Receipt Duplicate

  Command:	8CH. Length: 5 bytes.
  ?	Operator password (4 bytes)
  Answer:		8CH. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.PrintReceiptCopy: Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Result := Driver.RepeatDocument;
end;

(******************************************************************************

  Open Receipt

  Command:	8DH. Length: 6 bytes.
  ?	Operator password (4 bytes)
  ?	Receipt type (1 byte):		0 - Sale;
  1 - Buy;
  2 - Sale Refund;
  3 - Buy Refund.
  Answer:		8DH. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.OpenReceipt(ReceiptType: Byte): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.CheckType := ReceiptType;
  Result := Driver.OpenCheck;
  if Result = 0 then
    FFilter.OpenReceipt(ReceiptType);
end;

(******************************************************************************

  Continue Printing

  Command:	B0H. Length: 5 bytes.
  ?	Operator, Administrator or System Administrator password (4 bytes)
  Answer:		B0H. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.ContinuePrint: Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Result := Driver.ContinuePrint;
end;

(******************************************************************************

  Load Graphics In FP

  Command: 	C0H. Length: 46 bytes.
  ?	Operator password (4 bytes)
  ?	Graphics line number (1 byte) 0?199
  ?	Graphical data (40 bytes)
  Answer:		C0H. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.LoadGraphics1(Line: Byte; Data: AnsiString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.LineNumber := Line;
  Driver.LineDataHex := StrToHex(GetDataBlock(Data, 40, 40));
  Result := Driver.LoadLineData;
  if Result = ERROR_COMMAND_NOT_SUPPORTED then
  begin
    FCapGraphics1 := False;
    FModelData.CapGraphics := False;
  end;
end;

(******************************************************************************

  Print Graphics

  Command:	C1H. Length: 7 bytes.
  ?	Operator password (4 bytes)
  ?	Number of first line of preloaded graphics to be printed (1 byte) 1?200
  ?	Number of last line of preloaded graphics to be printed (1 byte) 1?200
  Answer:		C1H. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.PrintGraphics1(Line1, Line2: Byte): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.FirstLineNumber := Line1;
  Driver.LastLineNumber := Line2;
  Result := Driver.PrintGraphics512;
  if Result = ERROR_COMMAND_NOT_SUPPORTED then
    FModelData.CapGraphics := False;
end;

(******************************************************************************

  Print Bar Code

  Command:	C2H. Length: 10 bytes.
  ?	Operator password (4 bytes)
  ?	Bar code (5 bytes) 000000000000?999999999999
  Answer:		C2H. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.PrintBarcode(const Barcode: WideString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.BarCode := Barcode;
  Result := Driver.PrintBarCode;
end;

(******************************************************************************

  Extended Graphics Load In FP

  Command: 	C3H. Length: 47 bytes.
  ?	Operator password (4 bytes)
  ?	Graphics line number (2 bytes) 0?1199
  ?	Graphical data (40 bytes)
  Answer:		C3H. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.PrintGraphics2(Line1, Line2: Word): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.FirstLineNumber := Line1;
  Driver.LastLineNumber := Line2;
  Result := Driver.PrintGraphics512;
  if Result = ERROR_COMMAND_NOT_SUPPORTED then
    FModelData.CapGraphicsEx := False;
end;

(******************************************************************************

  Print Extended Graphics

  Command:	C4H. Length: 9 bytes.
  ?	Operator password (4 bytes)
  ?	Number of first line of preloaded graphics to be printed (1 byte) 1?1200
  ?	Number of last line of preloaded graphics to be printed (1 byte) 1?1200
  Answer:		C4H. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.LoadGraphics2(Line: Word; Data: AnsiString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.LineNumber := Line;
  Driver.LineDataHex := StrToHex(GetDataBlock(Data, 40, 40));
  Result := Driver.LoadLineDataEx;
  if Result = ERROR_COMMAND_NOT_SUPPORTED then
  begin
    FCapGraphics2 := False;
    FModelData.CapGraphicsEx := False;
  end;
end;

(******************************************************************************

  Print Graphical Line

  Command: 	C5H. Length: X + 7 bytes.
  ?	Operator password (4 bytes)
  ?	Number of repetitions (2 bytes)
  ?	Flags (1 byte)
  ?	Graphical data (X bytes)
  Answer:		C5H. Length: 3 bytes.
  ?	Result Code (1 byte)
  ?	Operator index number (1 byte) 1?30

******************************************************************************)

function TFiscalPrinterDriver.PrintGraphicsLine(Height: Word; Flags: Byte;
  Data: WideString): Integer;
begin
  Flags := GetPrintFlags(Flags);
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.LineNumber := Height;
  Driver.LineDataHex := StrToHex(AnsiString(Data));
  Result := Driver.WideLoadLineData;
  if Result = ERROR_COMMAND_NOT_SUPPORTED then
  begin
    FCapBarLine := False;
  end;
end;

(******************************************************************************

  Get Device Type

  Command:	FCH. Length: 1 byte.
  Answer:		FCH. Length: (8+X) bytes.
  ?	Result Code (1 byte)
  ?	Device type (1 byte) 0?255
  ?	Device subtype (1 byte) 0?255
  ?	Protocol version supported by device (1 byte) 0?255
  ?	Subprotocol version supported by device (1 byte) 0?255
  ?	Device model (1 byte) 0?255
  ?	Language (1 byte) 0?255, '0' - Russian, '1' - English
  ?	Device name (X bytes) AnsiString of WIN1251 code page characters;
    AnsiString length in bytes depends on device model

******************************************************************************)

function TFiscalPrinterDriver.ReadDeviceMetrics: TDeviceMetrics;
begin
  EnsureConnected;
  CheckDriver(Driver.GetDeviceMetrics);
  Result.DeviceType := Driver.UMajorType;
  Result.DeviceSubType := Driver.UMinorType;
  Result.ProtocolVersion := Driver.UMajorProtocolVersion;
  Result.ProtocolSubVersion := Driver.UMinorProtocolVersion;
  Result.Model := Driver.UModel;
  Result.Language := Driver.UCodePage;
  Result.DeviceName := Driver.UDescription;
end;

function TFiscalPrinterDriver.FieldToInt(FieldInfo: TPrinterFieldRec;
  const Value: WideString): Integer;
begin
  Result := 0;
  case FieldInfo.FieldType of
    PRINTER_FIELD_TYPE_INT: Result := BinToInt(Value, 1, FieldInfo.Size);
    PRINTER_FIELD_TYPE_STR: raiseException(_('Field type is not integer'));
  else
    raiseException(_('Invalid field type'));
  end;
end;

function TFiscalPrinterDriver.FieldToStr(FieldInfo: TPrinterFieldRec;
  const Value: WideString): WideString;
begin
  case FieldInfo.FieldType of
    PRINTER_FIELD_TYPE_INT: Result := IntToStr(BinToInt(Value, 1, FieldInfo.Size));
    PRINTER_FIELD_TYPE_STR: Result := PWideChar(Value);
  else
    raiseException(_('Invalid field type'));
  end;
end;

function TFiscalPrinterDriver.BinToFieldValue(
  FieldInfo: TPrinterFieldRec;
  const Value: WideString): WideString;
begin
  case FieldInfo.FieldType of
    PRINTER_FIELD_TYPE_INT: Result := IntToStr(BinToInt(Value, 1, FieldInfo.Size));
    PRINTER_FIELD_TYPE_STR: Result := Value;
  else
    raiseException(_('Invalid field type'));
  end;
end;

function TFiscalPrinterDriver.GetFieldValue(FieldInfo: TPrinterFieldRec;
  const Value: WideString): AnsiString;
begin
  case FieldInfo.FieldType of
    PRINTER_FIELD_TYPE_INT: Result := IntToBin(StrToInt(Value), FieldInfo.Size);
    PRINTER_FIELD_TYPE_STR: Result := GetDataBlock(Value, FieldInfo.Size, FieldInfo.Size);
  else
    raiseException(_('Invalid field type'));
  end;
end;

function TFiscalPrinterDriver.WriteTable(
  Table, Row, Field: Integer;
  const FieldValue: WideString): Integer;
var
  Data: AnsiString;
  FieldInfo: TPrinterFieldRec;
begin
  Result := 0;
  //if ReadTableStr(Table, Row, Field) = FieldValue then Exit; { !!! }

  FieldInfo := ReadFieldStructure(Table, Field);
  if ValidFieldValue(FieldInfo, FieldValue) then
  begin
    Data := GetFieldValue(FieldInfo, FieldValue);
    Result := DoWriteTable(Table, Row, Field, Data);
    if Result = 0 then
    begin
      if (Table = 17)and(Row = 1)and(Field=7) then
      begin
        FDocPrintMode := StrToInt(FieldValue);
      end;
    end;
  end else
  begin
    Logger.Error(Format('%s, "%s"', [_('Invalid field value'), FieldValue]));
  end;
end;

function TFiscalPrinterDriver.WriteTableInt(
  Table, Row, Field, Value: Integer): Integer;
begin
  Result := WriteTable(Table, Row, Field, IntToStr(Value));
end;

function TFiscalPrinterDriver.ReadTableInt(Table, Row, Field: Integer): Integer;
var
  Data: AnsiString;
  FieldInfo: TPrinterFieldRec;
begin
  FieldInfo := ReadFieldStructure(Table, Field);
  Data := ReadTableBin(Table, Row, Field);
  Result := FieldToInt(FieldInfo, Data);
end;

function TFiscalPrinterDriver.ReadTableStr(Table, Row, Field: Integer): WideString;
var
  Data: AnsiString;
  FieldInfo: TPrinterFieldRec;
begin
  FieldInfo := ReadFieldStructure(Table, Field);
  Data := ReadTableBin(Table, Row, Field);
  Result := FieldToStr(FieldInfo, Data);
end;

(*******************************************************************************

  Read discount totals in day

  185, Discounts accumulation on sales in day
  186, Discounts accumulation on buys in day
  187, Discounts accumulation on sale refunds in day
  188, Discounts accumulation on buy refunds in day

*******************************************************************************)

function TFiscalPrinterDriver.GetDayDiscountTotal: Int64;
begin
  Result :=
    ReadCashRegister(185) +
    ReadCashRegister(188) -
    ReadCashRegister(186) -
    ReadCashRegister(187);
end;

(*******************************************************************************

  Discounts accumulation in receipt

  64, Discounts accumulation from sales in receipt
  65, Discounts accumulation from buys in receipt
  66, Discounts accumulation from sale refunds in receipt
  67, Discounts accumulation from buy refunds in receipt

*******************************************************************************)

function TFiscalPrinterDriver.GetRecDiscountTotal: Int64;
begin
  Result :=
    ReadCashRegister(64) +
    ReadCashRegister(67) -
    ReadCashRegister(65) -
    ReadCashRegister(66);
end;

(*******************************************************************************

  Sales accumulation in day

    121, Sales accumulation in 1 department in day
    125, Sales accumulation in 2 department in day
    129, Sales accumulation in 3 department in day
    133, Sales accumulation in 4 department in day
    137, Sales accumulation in 5 department in day
    141, Sales accumulation in 6 department in day
    145, Sales accumulation in 7 department in day
    149, Sales accumulation in 8 department in day
    153, Sales accumulation in 9 department in day
    157, Sales accumulation in 10 department in day
    161, Sales accumulation in 11 department in day
    165, Sales accumulation in 12 department in day
    169, Sales accumulation in 13 department in day
    173, Sales accumulation in 14 department in day
    177, Sales accumulation in 15 department in day
    181, Sales accumulation in 16 department in day

*******************************************************************************)

function TFiscalPrinterDriver.GetDayItemTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + ReadCashRegister(121 + 4*i);
end;

(*******************************************************************************

  Sales accumulation in receipt

    0, Sales accumulation in 1 department in receipt
    4, Sales accumulation in 2 department in receipt
    8, Sales accumulation in 3 department in receipt
    12, Sales accumulation in 4 department in receipt
    16, Sales accumulation in 5 department in receipt
    20, Sales accumulation in 6 department in receipt
    24, Sales accumulation in 7 department in receipt
    28, Sales accumulation in 8 department in receipt
    32, Sales accumulation in 9 department in receipt
    36, Sales accumulation in 10 department in receipt
    40, Sales accumulation in 11 department in receipt
    44, Sales accumulation in 12 department in receipt
    48, Sales accumulation in 13 department in receipt
    52, Sales accumulation in 14 department in receipt
    56, Sales accumulation in 15 department in receipt
    60, Sales accumulation in 16 department in receipt

*******************************************************************************)

function TFiscalPrinterDriver.GetRecItemTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + ReadCashRegister(4*i);
end;

(*******************************************************************************

  Sales refund accumulation in day

    123, Sales refund accumulation in 1 department in day
    127, Sales refund accumulation in 2 department in day
    131, Sales refund accumulation in 3 department in day
    135, Sales refund accumulation in 4 department in day
    139, Sales refund accumulation in 5 department in day
    143, Sales refund accumulation in 6 department in day
    147, Sales refund accumulation in 7 department in day
    151, Sales refund accumulation in 8 department in day
    155, Sales refund accumulation in 9 department in day
    159, Sales refund accumulation in 10 department in day
    163, Sales refund accumulation in 11 department in day
    167, Sales refund accumulation in 12 department in day
    171, Sales refund accumulation in 13 department in day
    175, Sales refund accumulation in 14 department in day
    179, Sales refund accumulation in 15 department in day
    183, Sales refund accumulation in 16 department in day

*******************************************************************************)

function TFiscalPrinterDriver.GetDayItemVoidTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + ReadCashRegister(123 + 4*i);
end;

(*******************************************************************************

  Sales refund accumulation in receipt

    2, Sales refund accumulation in 1 department in receipt
    6, Sales refund accumulation in 2 department in receipt
    10, Sales refund accumulation in 3 department in receipt
    14, Sales refund accumulation in 4 department in receipt
    18, Sales refund accumulation in 5 department in receipt
    22, Sales refund accumulation in 6 department in receipt
    26, Sales refund accumulation in 7 department in receipt
    30, Sales refund accumulation in 8 department in receipt
    34, Sales refund accumulation in 9 department in receipt
    38, Sales refund accumulation in 10 department in receipt
    42, Sales refund accumulation in 11 department in receipt
    46, Sales refund accumulation in 12 department in receipt
    50, Sales refund accumulation in 13 department in receipt
    54, Sales refund accumulation in 14 department in receipt
    58, Sales refund accumulation in 15 department in receipt
    62, Sales refund accumulation in 16 department in receipt

*******************************************************************************)

function TFiscalPrinterDriver.GetRecItemVoidTotal: Int64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + ReadCashRegister(2 + 4*i);
end;

(*******************************************************************************

  Get Data Of EKLZ Daily Totals Report

  Command:	BAH. Length: 7 bytes.
  ?	System Administrator password (4 bytes) 30
  ?	Number of daily totals (2 bytes) 0000?2100
  Answer:		BAH. Length: 18 bytes.
  ?	Result Code (1 byte)
  ?	ECR model (16 bytes) AnsiString of WIN1251 code page characters

*******************************************************************************)

function TFiscalPrinterDriver.GetEJSesssionResult(Number: Word;
  var Text: WideString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.SessionNumber := Number;
  Result := Driver.GetEKLZSessionTotal;
  Text := Driver.EKLZData;
end;

function TFiscalPrinterDriver.ReadEJActivation(var Line: WideString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.EKLZActivizationResult;
  Line := TrimRight(Driver.EKLZData);
end;

(*******************************************************************************

  Get Data Of EKLZ Report

  Command:	B3H. Length: 5 bytes.
  ?	System Administrator password (4 bytes) 30
  Answer:		B3H. Length: (2+X) bytes.
  ?	Result Code (1 byte)
  ?	Report part or line (X bytes)

*******************************************************************************)

function TFiscalPrinterDriver.GetEJReportLine(var Line: WideString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.GetEKLZCode2Report;
  Line := TrimRight(Driver.EKLZData);
end;

(*******************************************************************************

  Cancel Active EKLZ Operation

  Command:	ACH. Length: 5 bytes.
  ?	System Administrator password (4 bytes) 30
  Answer:		ACH. Length: 2 bytes.
  ?	Result Code (1 byte)

*******************************************************************************)

function TFiscalPrinterDriver.EJReportStop: Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.EKLZInterrupt;
end;

function TFiscalPrinterDriver.DecodeEJFlags(Flags: Byte): TEJFlags;
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

  Get EKLZ Status 1

  Command:	ADH. Length: 5 bytes.
  ?	System Administrator password (4 bytes) 30
  Answer:		ADH. Length: 22 bytes.
  ?	Result Code (1 byte)
  ?	KPK value of last fiscal receipt (5 bytes) 0000000000?9999999999
  ?	Date of last KPK (3 bytes) DD-MM-YY
  ?	Time of last KPK (2 bytes) HH-MM
  ?	Number of last KPK (4 bytes) 00000000?99999999
  ?	EKLZ serial number (5 bytes) 0000000000?9999999999
  ?	EKLZ flags (1 byte)

*******************************************************************************)

function TFiscalPrinterDriver.GetEJStatus1(var Status: TEJStatus1): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.GetEKLZCode1Report;
  if Result = 0 then
  begin
    Status.DocAmount := AmountToInt(Driver.Summ1);
    Status.DocDate := DateTimeToPrinterDate(Driver.ECRDate);
    //Status.DocTime := DateTimeToPrinterTime(Driver.ECRTime);
    Status.DocNumber := Driver.DocumentNumber;
    Status.EJNumber := StrToInt64Def(Driver.EKLZNumber, 0);
    Status.Flags := DecodeEJFlags(Driver.EKLZFlags);
  end;
end;

function TFiscalPrinterDriver.FormatLines(const Line1, Line2: WideString): WideString;
begin
  Result := AlignLines(Line1, Line2, GetPrintWidth);
end;

function TFiscalPrinterDriver.FormatBoldLines(const Line1, Line2: WideString): WideString;
begin
  Result := AlignLines(Line1, Line2, GetPrintWidth div 2);
end;

(******************************************************************************

  Print Daily Totals Report In Dates Range From EKLZ

  Command:	A2H. Length: 12 bytes.
  ?	System Administrator password (4 bytes) 30
  ?	Report type (1 byte) '0' - short, '1' - full
  ?	Date of first daily totals in range (3 bytes) DD-MM-YY
  ?	Date of last daily totals in range (3 bytes) DD-MM-YY
  Answer:		A2H. Length: 2 bytes.
  ?	Result Code (1 byte)

******************************************************************************)

procedure TFiscalPrinterDriver.EJTotalsReportDate(
  const Parameters: TDateReport);
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.ReportType := Parameters.ReportType <> 0;
  Driver.FirstSessionDate := PrinterDateToDate(Parameters.Date1);
  Driver.LastSessionDate := PrinterDateToDate(Parameters.Date2);
  CheckDriver(Driver.EKLZSessionReportInDatesRange);
end;

(******************************************************************************

  Print Daily Totals Report In Daily Totals Numbers Range From EKLZ

  Command:	A3H. Length: 10 bytes.
  ?	System Administrator password (4 bytes) 30
  ?	Report type (1 byte) '0' - short, '1' - full
  ?	Number of first daily totals in range (2 bytes) 0000?2100
  ?	Number of last daily totals in range (2 bytes) 0000?2100
  Answer:		A3H. Length: 2 bytes.
  ?	Result Code (1 byte)

******************************************************************************)

procedure TFiscalPrinterDriver.EJTotalsReportNumber(
  const Parameters: TNumberReport);
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.ReportType := Parameters.ReportType <> 0;
  Driver.FirstSessionNumber := Parameters.Number1;
  Driver.LastSessionNumber := Parameters.Number2;
  CheckDriver(Driver.EKLZSessionReportInSessionsRange);
end;

function TFiscalPrinterDriver.GetModel: TPrinterModelRec;
begin
  Result := FModelData;
end;

function TFiscalPrinterDriver.GetPrinterModel: TPrinterModel;
begin
  if FModel = nil then
  begin
    FModel := SelectModel;
  end;
  Result := FModel;
end;

function TFiscalPrinterDriver.SelectModel: TPrinterModel;
var
  ModelID: Integer;
begin
  ModelID := Parameters.ModelID;
  Result := FModels.ItemByID(ModelID);
  if Result = nil then
  begin
    ModelID := GetDeviceMetrics.Model;
    Result := FModels.ItemByID(ModelID);
    if Result = nil then
    begin
      ModelID := DefaultModelID;
      Result := FModels.ItemByID(ModelID);
    end;
  end;

  if Result = nil then
    raiseExceptionFmt('%s, ID=%d', [_('Device model not found'), ModelID]);

  FModelData := Result.Data;
  FModelData.CapGraphics := True;
  FModelData.CapGraphicsEx := True;

  WriteLogModelParameters(FModelData);
end;

function TFiscalPrinterDriver.GetOnCommand: TCommandEvent;
begin
  Result := FOnCommand;
end;

procedure TFiscalPrinterDriver.SetOnCommand(Value: TCommandEvent);
begin
  FOnCommand := Value;
end;

function TFiscalPrinterDriver.GetBeforeCommand: TCommandEvent;
begin
  Result := FBeforeCommand;
end;

procedure TFiscalPrinterDriver.SetBeforeCommand(Value: TCommandEvent);
begin
  FBeforeCommand := Value;
end;

function TFiscalPrinterDriver.AlignLine(const Line: WideString;
  PrintWidth: Integer; Alignment: TTextAlignment = taLeft): WideString;
var
  L: Integer;
  L1: Integer;
  L2: Integer;
begin
  Result := Copy(Line, 1, PrintWidth);
  L := Length(Result);
  case Alignment of
    taCenter:
    begin
      L1 := (PrintWidth - L) div 2;
      L2 := PrintWidth - L -L1;
      Result := StringOfChar(' ', L1) + Result + StringOfChar(' ', L2);
    end;
    taRight:
    begin
      Result := StringOfChar(' ', PrintWidth-L) + Result;
    end;
  end;
end;

function TFiscalPrinterDriver.CenterLine(const Line: WideString): WideString;
var
  L: Integer;
  L1: Integer;
  L2: Integer;
begin
  Result := Trim(Line);
  Result := Copy(Result, 1, GetPrintWidth);
  L := Length(Result);
  L1 := (GetPrintWidth - L) div 2;
  L2 := GetPrintWidth - L -L1;
  Result := StringOfChar(' ', L1) + Result + StringOfChar(' ', L2);
end;

function TFiscalPrinterDriver.ProcessLine(const Line: WideString): Boolean;
var
  Barcode: TBarcodeRec;
begin
  Result := (Parameters.BarcodePrefix <> '')and(Pos(Parameters.BarcodePrefix, Line) = 1);
  if not Result then Exit;
  Barcode.Data := Copy(Line, Length(Parameters.BarcodePrefix) + 1, Length(Line));
  Barcode.Text := Barcode.Data;
  Barcode.Height := Parameters.BarcodeHeight;
  Barcode.BarcodeType := Parameters.BarcodeType;
  Barcode.ModuleWidth := Parameters.BarcodeModuleWidth;
  Barcode.Alignment := Parameters.BarcodeAlignment;
  Barcode.Parameter1 := Parameters.BarcodeParameter1;
  Barcode.Parameter2 := Parameters.BarcodeParameter2;
  Barcode.Parameter3 := Parameters.BarcodeParameter3;
  PrintBarcode2(Barcode);
end;

procedure TFiscalPrinterDriver.PrintLineFont(const Data: TTextRec);
var
  i: Integer;
  Line: AnsiString;
  Lines: TTntStrings;
  PrintWidth: Integer;
begin
  PrintWidth := GetPrintWidth(Data.Font);
  Lines := TTntStringList.Create;
  try
    if ProcessLine(Data.Text) then Exit;

    if Data.Wrap then
    begin
      SplitText(Data.Text, Data.Font, Lines);
    end else
    begin
      Lines.Add(Data.Text);
    end;

    for i := 0 to Lines.Count-1 do
    begin
      Line := Lines[i];
      Line := AlignLine(Line, PrintWidth, Data.Alignment);
      if CapPrintStringFont then
        PrintStringFont(Data.Station, Data.Font, Line)
      else
        PrintStringFont(Data.Station, Parameters.FontNumber, Line);
    end;
  finally
    Lines.Free;
  end;
end;

procedure TFiscalPrinterDriver.SplitText(const Text: WideString; Font: Integer;
  Lines: TTntStrings);
var
  Line: WideString;
  AText: WideString;
  PrintWidth: Integer;
begin
  Lines.Clear;
  PrintWidth := GetPrintWidth(Font);
  AText := Text;
  Line := Copy(AText, 1, PrintWidth);
  AText := Copy(AText, PrintWidth + 1, Length(AText));
  repeat
    Lines.Add(Line);
    Line := Copy(AText, 1, PrintWidth);
    AText := Copy(AText, PrintWidth + 1, Length(AText));
  until Line = '';
end;

procedure TFiscalPrinterDriver.PrintTextFont(Station: Integer;
  Font: Integer; const Text: WideString);
var
  Data: TTextRec;
begin
  Data.Text := Text;
  Data.Station := Station;
  Data.Font := Font;
  Data.Alignment := taLeft;
  Data.Wrap := Parameters.WrapText;
  PrintText(Data);
end;

procedure TFiscalPrinterDriver.PrintText(Station: Integer; const Text: WideString);
var
  Data: TTextRec;
begin
  Data.Text := Text;
  Data.Station := Station;
  Data.Font := Parameters.FontNumber;
  Data.Alignment := taLeft;
  Data.Wrap := Parameters.WrapText;
  PrintText(Data);
end;

procedure TFiscalPrinterDriver.PrintText(const Data: TTextRec);
var
  i: Integer;
  Text: AnsiString;
  Line: TTextRec;
  Lines: TTntStrings;
begin
  Line := Data;
  Text := Data.Text;
  if Text = '' then Text := ' ';

  Lines := TTntStringList.Create;
  try
    Lines.Text := Text;
    for i := 0 to Lines.Count-1 do
    begin
      Line.Text := Lines[i];
      PrintLineFont(Line);
    end;
  finally
    Lines.Free;
  end;
end;

function TFiscalPrinterDriver.GetTables: TDeviceTables;
begin
  Result := FDeviceTables;
end;

procedure TFiscalPrinterDriver.SetTables(const Value: TDeviceTables);
begin
  FDeviceTables := Value;
end;

procedure TFiscalPrinterDriver.OpenPort(
  PortNumber, BaudRate, ByteTimeout: Integer);
begin
  Logger.Debug(Format('OpenPort(COM%d, %d, %d)', [PortNumber, BaudRate, ByteTimeout]));
  ApplyDriverConnection;
  Driver.ComNumber := PortNumber;
  Driver.BaudRate := BaudRate;
  Driver.Timeout := ByteTimeout;
  if FDriverConnected then
  begin
    Driver.Disconnect;
    FDriverConnected := False;
  end;
  EnsureConnected;
end;

procedure TFiscalPrinterDriver.ClaimDevice(PortNumber, Timeout: Integer);
begin
  EnsureConnected;
  CheckDriver(Driver.LockPort);
end;

procedure TFiscalPrinterDriver.ReleaseDevice;
begin
  if FDriverConnected then
    CheckDriver(Driver.UnlockPort);
end;

procedure TFiscalPrinterDriver.Close;
begin
  Disconnect;
  FConnection := nil;
  FIsOnline := False;
end;

procedure TFiscalPrinterDriver.Open(AConnection: IPrinterConnection);
begin
  FConnection := AConnection;
  ApplyDriverConnection;
end;

procedure TFiscalPrinterDriver.ClosePort;
begin
  if FDriverConnected then
  begin
    Driver.Disconnect;
    FDriverConnected := False;
    if Assigned(FOnDisconnect) then
      FOnDisconnect(Self);
  end;
  FIsOnline := False;
end;

procedure TFiscalPrinterDriver.WriteLogModelParameters(const Model: TPrinterModelRec);
begin
  Logger.Debug(Logger.Separator);
  Logger.LogParam('Model.ID', Model.ID);
  Logger.LogParam('Model.Name', Model.Name);
  Logger.LogParam('Model.CapShortEcrStatus', Model.CapShortEcrStatus);
  Logger.LogParam('Model.CapCoverSensor', Model.CapCoverSensor);
  Logger.LogParam('Model.CapJrnPresent', Model.CapJrnPresent);
  Logger.LogParam('Model.CapJrnEmptySensor', Model.CapJrnEmptySensor);
  Logger.LogParam('Model.CapJrnNearEndSensor', Model.CapJrnNearEndSensor);
  Logger.LogParam('Model.CapRecPresent', Model.CapRecPresent);
  Logger.LogParam('Model.CapRecEmptySensor', Model.CapRecEmptySensor);
  Logger.LogParam('Model.CapRecNearEndSensor', Model.CapRecNearEndSensor);
  Logger.LogParam('Model.CapSlpFullSlip', Model.CapSlpFullSlip);
  Logger.LogParam('Model.CapSlpEmptySensor', Model.CapSlpEmptySensor);
  Logger.LogParam('Model.CapSlpFiscalDocument', Model.CapSlpFiscalDocument);
  Logger.LogParam('Model.CapSlpNearEndSensor', Model.CapSlpNearEndSensor);
  Logger.LogParam('Model.CapSlpPresent', Model.CapSlpPresent);
  Logger.LogParam('Model.CapSetHeader', Model.CapSetHeader);
  Logger.LogParam('Model.CapSetTrailer', Model.CapSetTrailer);
  Logger.LogParam('Model.CapRecLever', Model.CapRecLever);
  Logger.LogParam('Model.CapJrnLever', Model.CapJrnLever);
  Logger.LogParam('Model.CapFixedTrailer', Model.CapFixedTrailer);
  Logger.LogParam('Model.CapDisableTrailer', Model.CapDisableTrailer);
  Logger.LogParam('Model.NumHeaderLines', Model.NumHeaderLines);
  Logger.LogParam('Model.NumTrailerLines', Model.NumTrailerLines);
  Logger.LogParam('Model.StartHeaderLine', Model.StartHeaderLine);
  Logger.LogParam('Model.StartTrailerLine', Model.StartTrailerLine);
  Logger.LogParam('Model.BaudRates', Model.BaudRates);
  Logger.LogParam('Model.PrintWidth', Model.PrintWidth);
  Logger.LogParam('Model.MaxGraphicsWidth', Model.MaxGraphicsWidth);
  Logger.LogParam('Model.MaxGraphicsHeight', Model.MaxGraphicsHeight);
  Logger.LogParam('Model.CapFullCut', Model.CapFullCut);
  Logger.LogParam('Model.CapPartialCut', Model.CapPartialCut);
  Logger.Debug(Logger.Separator);
end;

procedure TFiscalPrinterDriver.Check(Code: Integer);
begin
  if Code = 0 then Exit;
  RaiseError(Code, GetErrorText(Code));
end;

function TFiscalPrinterDriver.GetDeviceMetrics: TDeviceMetrics;
begin
  if not FValidDeviceMetrics then
  begin
    FDeviceMetrics := ReadDeviceMetrics;
    FValidDeviceMetrics := True;
  end;
  Result := FDeviceMetrics;
end;

function TFiscalPrinterDriver.MinProtocolVersion(V1, V2: Integer): Boolean;
var
  DM: TDeviceMetrics;
begin
  DM := GetDeviceMetrics;
  Result := (DM.ProtocolVersion > V1)or
    ((DM.ProtocolVersion = V1) and (DM.ProtocolSubVersion >= V2));
end;

function TFiscalPrinterDriver.CapShortEcrStatus: Boolean;
begin
  Result := MinProtocolVersion(1, 1);
end;

function TFiscalPrinterDriver.CapPrintStringFont: Boolean;
begin
  Result := MinProtocolVersion(1, 1);
end;

function TFiscalPrinterDriver.CapGraphics: Boolean;
begin
  Result := MinProtocolVersion(1, 3);
end;

(******************************************************************************

  Print Daily Log Report For Daily Totals Number From EKLZ

  Command:	A6H. Length: 7 bytes.
  ?	System Administrator password (4 bytes) 30
  ?	Day number (2 bytes) 0000?2100

  Answer:		A6H. Length: 2 bytes.
  ?	Result Code (1 byte)

******************************************************************************)

procedure TFiscalPrinterDriver.PrintJournal(DayNumber: Integer);
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.SessionNumber := DayNumber;
  CheckDriver(Driver.EKLZJournalOnSessionNumber);
end;

function TFiscalPrinterDriver.ValidRow(Table, Row: Integer): Boolean;
var
  TableInfo: TPrinterTableRec;
begin
  Check(ReadTableStructure(Table, TableInfo));
  Result := (Row >= 1)and(Row <= TableInfo.RowCount);
end;

function TFiscalPrinterDriver.ValidField(Table, Field: Integer): Boolean;
var
  TableInfo: TPrinterTableRec;
begin
  Check(ReadTableStructure(Table, TableInfo));
  Result := (Field >= 1)and(Field <= TableInfo.FieldCount);
end;

function TFiscalPrinterDriver.CapParameter(ParamID: Integer): Boolean;
begin
  Result := PrinterModel.Parameters.ItemByID(ParamID) <> nil;
end;

function TFiscalPrinterDriver.ValidParameter(const Parameter: TTableParameter): Boolean;
begin
  Result := ValidRow(Parameter.Table, Parameter.Row) and
    ValidField(Parameter.Table, Parameter.Field);
end;

procedure TFiscalPrinterDriver.WriteParameter(ParamID, ValueID: Integer);
var
  Parameter: TTableParameter;
  ParameterValue: TParameterValue;
begin
  Parameter := PrinterModel.Parameters.ItemByID(ParamID);
  if Parameter <> nil then
  begin
    if ValidParameter(Parameter) then
    begin
      ParameterValue := Parameter.Values.ItemByID(ValueID);
      if ParameterValue <> nil then
      begin
        WriteTableInt(Parameter.Table, Parameter.Row, Parameter.Field,
        ParameterValue.Value);
      end;
    end;
  end;
end;

function TFiscalPrinterDriver.ReadParameter(ParamID: Integer): Integer;
var
  Parameter: TTableParameter;
begin
  Result := 0;
  Parameter := PrinterModel.Parameters.ItemByID(ParamID);
  if Parameter <> nil then
  begin
    if ValidParameter(Parameter) then
      Result := ReadTableInt(Parameter.Table, Parameter.Row, Parameter.Field);
  end;
end;

function TFiscalPrinterDriver.ReadEJDocument(MACNumber: Integer;
  var Line: WideString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.KPKNumber := MACNumber;
  Result := Driver.GetEKLZDocument;
  if Result = 0 then
    Line := Driver.EKLZData;
end;


function TFiscalPrinterDriver.ReadEJDocumentText(MACNumber: Integer): WideString;
var
  Line: WideString;
  Lines: TTntStrings;
begin
  Result := '';
  Lines := TTntStringList.Create;
  try
    if EJReportStop <> 0 then Exit;
    if ReadEJDocument(MACNumber, Line) <> 0 then Exit;
    Lines.Add(Line);

    while GetEJReportLine(Line) = 0 do
    begin
      Lines.Add(Line);
    end;
    EJReportStop;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

// 00000068 #049021
function TFiscalPrinterDriver.ParseEJDocument(const Text: WideString): TEJDocument;
var
  Line: WideString;
  Lines: TTntStrings;
begin
  Result.Text := Text;
  Result.MACValue := 0;
  Result.MACNumber := 0;

  Lines := TTntStringList.Create;
  try
    Lines.Text := Text;
    if Lines.Count > 0 then
    begin
      Line := Trim(Lines[Lines.Count-1]);
      Result.MACNumber := StrToInt64(Copy(Line, 1, 8));
      Result.MACValue := StrToInt64(Copy(Line, 11, 6));
    end;
  finally
    Lines.Free;
  end;
end;

function TFiscalPrinterDriver.ReadEJActivationText(MaxCount: Integer): WideString;
var
  i: Integer;
  Line: WideString;
  Lines: TTntStrings;
begin
  Lines := TTntStringList.Create;
  try
    if EJReportStop <> 0 then Exit;
    if ReadEJActivation(Line) <> 0 then Exit;
    Lines.Add(Line);

    for i := 1 to MaxCount do
    begin
      if GetEJReportLine(Line) <> 0 then Break;
      Lines.Add(Line);
    end;
    EJReportStop;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function TFiscalPrinterDriver.QueryEJActivation: TEJActivation;
begin
  Result := TEJReportParser.ParseActivation(ReadEJActivationText(6));
end;

function TFiscalPrinterDriver.GetIsOnline: Boolean;
begin
  Result := FIsOnline;
end;

function TFiscalPrinterDriver.GetOnConnect: TNotifyEvent;
begin
  Result := FOnConnect;
end;

function TFiscalPrinterDriver.GetOnDisconnect: TNotifyEvent;
begin
  Result := FOnDisconnect;
end;

procedure TFiscalPrinterDriver.SetOnConnect(const Value: TNotifyEvent);
begin
  FOnConnect := Value;
end;

procedure TFiscalPrinterDriver.SetOnDisconnect(const Value: TNotifyEvent);
begin
  FOnDisconnect := Value;
end;

function TFiscalPrinterDriver.LoadGraphics(Line: Word;
  Data: AnsiString): Integer;
begin
  Result := 0;
  if FCapGraphics2 then
  begin
    Result := LoadGraphics2(Line, Data);
    Exit;
  end;
  if FCapGraphics1 then
  begin
    Result := LoadGraphics1(Line, Data);
    Exit;
  end;
  raiseException(_('Graphics is not supported'));
end;

function TFiscalPrinterDriver.PrintGraphics(Line1, Line2: Word): Integer;
begin
  Result := 0;
  CheckGraphicsSize(Line1);
  CheckGraphicsSize(Line2);

(*
  if FModel.Data.ID in [0, 4] then
  begin
    Line1 := Line1 + 1;
    Line2 := Line2 + 2;
  end;
  if FModel.Data.ID = 250 then
  begin
    Line1 := Line1 + 1;
    Line2 := Line2 + 1;
  end;
  if FModel.Data.ID in [7, 14] then
  begin
    Line2 := Line2 + 1;
  end;
*)
  if FCapGraphics512 then
  begin
    Result := PrintGraphics3(Line1, Line2);
    Exit;
  end;
  if FCapGraphics2 then
  begin
    Result := PrintGraphics2(Line1, Line2);
    Exit;
  end;
  if FCapGraphics1 then
  begin
    Result := PrintGraphics1(Line1, Line2);
    Exit;
  end;
  raiseException(_('Graphics is not supported'));
end;

function TFiscalPrinterDriver.IsDayOpened(Mode: Integer): Boolean;
begin
  Result := (Mode and $0F) in [MODE_24NOTOVER, MODE_24OVER, MODE_REC, MODE_SLP];
end;


function TFiscalPrinterDriver.GetAmountDecimalPlaces: Integer;
begin
  Result := FAmountDecimalPlaces;
end;

procedure TFiscalPrinterDriver.SetAmountDecimalPlaces(
  const Value: Integer);
begin
  FAmountDecimalPlaces := Value;
end;

procedure TFiscalPrinterDriver.PrintBarcode2(const Barcode: TBarcodeRec);

  procedure PrintBarcodeEAN13Zint(ABarcode: TBarcodeRec);
  var
    Line: AnsiString;
  begin
    ABarcode.Height := 80;
    ABarcode.Data := Copy(ABarcode.Data, 1, 12);
    ABarcode.Text := ABarcode.Data;
    ABarcode.Alignment := BARCODE_ALIGNMENT_CENTER;
    ABarcode.BarcodeType := DIO_BARCODE_EAN13;
    PrintBarcodeZInt(ABarcode);
    WaitForPrinting;
    Line := AlignLine(ABarcode.Data, GetPrintWidth, taCenter);
    PrintStringFont(PRINTER_STATION_REC, Parameters.FontNumber, Line);
  end;

  procedure PrintBarcodeEAN13Int(ABarcode: TBarcodeRec);
  begin
    Check(PrintBarcode(Copy(ABarcode.Data, 1, 12)));
    WaitForPrinting;
  end;

  procedure PrintBarcodeEAN13(ABarcode: TBarcodeRec);
  begin
    if Length(ABarcode.Data) in [12, 13] then
    begin
      PrintBarcodeEAN13Int(ABarcode);
    end else
    begin
      PrintBarcodeEAN13ZInt(ABarcode);
    end;
  end;

  function PrintBarcode2D_2(Barcode: TBarcodeRec): Integer;
  var
    Barcode2D: TBarcode2D;
  begin
    Barcode.Data := Barcode.Data + #0;
    Result := LoadBarcodeData(0, Barcode.Data);
    if Result <> 0 then Exit;

    Barcode2D.BarcodeType := Barcode.BarcodeType;
    Barcode2D.DataLength := Length(Barcode.Data);
    Barcode2D.BlockNumber := 0;
    Barcode2D.Parameter1 := Barcode.Parameter1;
    Barcode2D.Parameter2 := Barcode.Parameter2;
    Barcode2D.Parameter3 := Barcode.Parameter3;
    Barcode2D.Parameter4 := Barcode.Parameter4;
    Barcode2D.Parameter5 := Barcode.Parameter5;
    Barcode2D.Alignment := IntToAlignment(Barcode.Alignment);
    Result := PrintBarcode2D(Barcode2D);
  end;

  function IntTo2DBarcodeType(BarcodeType: Integer): Integer;
  begin
    case BarcodeType of
      DIO_BARCODE_DEVICE_PDF417     : Result := 0;
      DIO_BARCODE_DEVICE_DATAMATRIX : Result := 1;
      DIO_BARCODE_DEVICE_AZTEC      : Result := 2;
      DIO_BARCODE_DEVICE_QR         : Result := 3;
      DIO_BARCODE_DEVICE_EGAIS      : Result := $83;
    else
      raise Exception.Create('Invalid barcode type');
    end;
  end;

var
  TickCount: Integer;
  ABarcode: TBarcodeRec;
begin
  ABarcode := Barcode;
  Logger.Debug('PrintBarcode2');
  TickCount := GetTickCount;

  if ABarcode.BarcodeType = DIO_BARCODE_EAN13_INT then
  begin
    PrintBarcodeEAN13(ABarcode);
  end else
  begin
    if not FCapBarcode2D then
    begin
      if ABarcode.BarcodeType = DIO_BARCODE_QRCODE3 then
      begin
        PrintQRCode3(ABarcode);
      end else
      begin
        PrintBarcodeZInt(ABarcode);
      end;
    end else
    begin
      case ABarcode.BarcodeType of
        DIO_BARCODE_EAN13_INT: PrintBarcodeEAN13(ABarcode);
        DIO_BARCODE_QRCODE:
          Check(PrintQRCode2D(ABarcode));

        DIO_BARCODE_QRCODE2,
        DIO_BARCODE_QRCODE4:
        begin
          ABarcode.Data := ABarcode.Data + ' ' + ABarcode.Text;
          ABarcode.Text := '';
          Check(PrintQRCode2D(ABarcode))
        end;
        DIO_BARCODE_DEVICE_PDF417,
        DIO_BARCODE_DEVICE_DATAMATRIX,
        DIO_BARCODE_DEVICE_AZTEC,
        DIO_BARCODE_DEVICE_QR,
        DIO_BARCODE_DEVICE_EGAIS:
        begin
          ABarcode.BarcodeType := IntTo2DBarcodeType(ABarcode.BarcodeType);
          Check(PrintBarcode2D_2(ABarcode));
        end;
      else
        PrintBarcodeZInt(ABarcode);
      end;
    end;
  end;
  Logger.Debug('PrintBarcode2.OK');
  Logger.Debug(Format('Barcode printed in %d ms', [Integer(GetTickCount) - TickCount]));
  WaitForPrinting;
end;

function TFiscalPrinterDriver.LoadBarcodeData(BlockType: Integer;
  const Barcode: WideString): Integer;
const
  DATA_BLOCK_SIZE = 64;
var
  i: Integer;
  Count: Integer;
  Block: TBarcode2DData;
begin
  Result := 0;
  Count := (Length(Barcode) + DATA_BLOCK_SIZE -1) div DATA_BLOCK_SIZE;
  for i := 0 to Count-1 do
  begin
    Block.BlockType := BlockType;
    Block.BlockNumber := i;
    Block.BlockData := Copy(Barcode, 1 + i * DATA_BLOCK_SIZE, DATA_BLOCK_SIZE);
    Result := LoadBarcode2D(Block);
    if Result <> 0 then Exit;
  end;
end;

function TFiscalPrinterDriver.PrintQRCode2D(Barcode: TBarcodeRec): Integer;
var
  Barcode2D: TBarcode2D;
begin
  Barcode.Data := Barcode.Data + #0;
  Result := LoadBarcodeData(0, Barcode.Data);
  if Result <> 0 then Exit;

  case Barcode.BarcodeType of
    DIO_BARCODE_QRCODE: Barcode2D.BarcodeType := 3;
    DIO_BARCODE_QRCODE2: Barcode2D.BarcodeType := $83;
    DIO_BARCODE_QRCODE3: Barcode2D.BarcodeType := $83;
    DIO_BARCODE_QRCODE4: Barcode2D.BarcodeType := $C3;
  else
    Barcode2D.BarcodeType := 3;
  end;
  Barcode2D.DataLength := Length(Barcode.Data);
  Barcode2D.BlockNumber := 0;
  Barcode2D.Parameter1 := Barcode.Parameter1;
  Barcode2D.Parameter2 := Barcode.Parameter2;
  Barcode2D.Parameter3 := Barcode.ModuleWidth;
  Barcode2D.Parameter4 := 0;
  Barcode2D.Parameter5 := Barcode.Parameter3;
  Barcode2D.Alignment := IntToAlignment(Barcode.Alignment);
  Result := PrintBarcode2D(Barcode2D);
end;

function TFiscalPrinterDriver.DrawScale(const P: TDrawScale): Integer;
var
  LastLine: Integer;
begin
  LastLine := P.LastLine;
  if GetPrinterModel.Data.ID in [7, 14] then
  begin
    LastLine := LastLine - 1;
  end;

  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.FirstLineNumber := P.FirstLine;
  Driver.LastLineNumber := LastLine;
  Driver.VertScale := P.VScale;
  Driver.HorizScale := P.HScale;
  Result := Driver.PrintGraphics512;
end;

function TFiscalPrinterDriver.GetStartLine: Integer;
begin
  Result := 1;
  if Parameters.IsLogoLoaded and (Parameters.LogoSize > 0) then
  begin
    Result := Parameters.LogoSize + 1;
  end;
end;

function TFiscalPrinterDriver.Is1DBarcode(Symbology: Integer): Boolean;
begin
  Result := not Is2DBarcode(Symbology);
end;

function TFiscalPrinterDriver.Is2DBarcode(Symbology: Integer): Boolean;
begin
  Result := Symbology in [
    DIO_BARCODE_QRCODE,
    DIO_BARCODE_QRCODE2,
    DIO_BARCODE_QRCODE3,
    DIO_BARCODE_QRCODE4,
    DIO_BARCODE_AZTEC,
    DIO_BARCODE_MICROQR,
    DIO_BARCODE_AZRUNE,
    DIO_BARCODE_PDF417,
    DIO_BARCODE_PDF417TRUNC,
    DIO_BARCODE_MICROPDF417,
    DIO_BARCODE_MAXICODE,
    DIO_BARCODE_DATAMATRIX
  ];
end;

function GetZIntBarcodeType(DIOBarcodeType: Integer): Integer;
begin
  Result := BARCODE_CODE11;
  case DIOBarcodeType of
    DIO_BARCODE_EAN13_INT           : Result := BARCODE_EANX;
    DIO_BARCODE_CODE128A            : Result := BARCODE_CODE128;
    DIO_BARCODE_CODE128B            : Result := BARCODE_CODE128B;
    DIO_BARCODE_CODE128C            : Result := BARCODE_CODE128;
    DIO_BARCODE_CODE39              : Result := BARCODE_CODE39;
    DIO_BARCODE_CODE25INTERLEAVED   : Result := BARCODE_C25INTER;
    DIO_BARCODE_CODE25INDUSTRIAL    : Result := BARCODE_C25IND;
    DIO_BARCODE_CODE25MATRIX        : Result := BARCODE_C25MATRIX;
    DIO_BARCODE_CODE39EXTENDED      : Result := BARCODE_EXCODE39;
    DIO_BARCODE_CODE93              : Result := BARCODE_CODE93;
    DIO_BARCODE_CODE93EXTENDED      : Result := BARCODE_CODE93;
    DIO_BARCODE_MSI                 : Result := BARCODE_MSI_PLESSEY;
    DIO_BARCODE_POSTNET             : Result := BARCODE_POSTNET;
    DIO_BARCODE_CODABAR             : Result := BARCODE_CODABAR;
    DIO_BARCODE_EAN8                : Result := BARCODE_EANX;
    DIO_BARCODE_EAN13               : Result := BARCODE_EANX;
    DIO_BARCODE_UPC_A               : Result := BARCODE_UPCA;
    DIO_BARCODE_UPC_E0              : Result := BARCODE_UPCE;
    DIO_BARCODE_UPC_E1              : Result := BARCODE_UPCE;
    DIO_BARCODE_UPC_S2              : Result := BARCODE_UPCE;
    DIO_BARCODE_UPC_S5              : Result := BARCODE_UPCE;
    DIO_BARCODE_EAN128A             : Result := BARCODE_EAN128;
    DIO_BARCODE_EAN128B             : Result := BARCODE_EAN128;
    DIO_BARCODE_EAN128C             : Result := BARCODE_EAN128;

    DIO_BARCODE_CODE11              : Result := BARCODE_CODE11;
    DIO_BARCODE_C25IATA             : Result := BARCODE_C25IATA;
    DIO_BARCODE_C25LOGIC            : Result := BARCODE_C25LOGIC;
    DIO_BARCODE_DPLEIT              : Result := BARCODE_DPLEIT;
    DIO_BARCODE_DPIDENT             : Result := BARCODE_DPIDENT;
    DIO_BARCODE_CODE16K             : Result := BARCODE_CODE16K;
    DIO_BARCODE_CODE49              : Result := BARCODE_CODE49;
    DIO_BARCODE_FLAT                : Result := BARCODE_FLAT;
    DIO_BARCODE_RSS14               : Result := BARCODE_RSS14;
    DIO_BARCODE_RSS_LTD             : Result := BARCODE_RSS_LTD;
    DIO_BARCODE_RSS_EXP             : Result := BARCODE_RSS_EXP;
    DIO_BARCODE_TELEPEN             : Result := BARCODE_TELEPEN;
    DIO_BARCODE_FIM                 : Result := BARCODE_FIM;
    DIO_BARCODE_LOGMARS             : Result := BARCODE_LOGMARS;
    DIO_BARCODE_PHARMA              : Result := BARCODE_PHARMA;
    DIO_BARCODE_PZN                 : Result := BARCODE_PZN;
    DIO_BARCODE_PHARMA_TWO          : Result := BARCODE_PHARMA_TWO;
    DIO_BARCODE_PDF417              : Result := BARCODE_PDF417;
    DIO_BARCODE_PDF417TRUNC         : Result := BARCODE_PDF417TRUNC;
    DIO_BARCODE_MAXICODE            : Result := BARCODE_MAXICODE;
    DIO_BARCODE_QRCODE              : Result := BARCODE_QRCODE;
    DIO_BARCODE_QRCODE2             : Result := BARCODE_QRCODE;
    DIO_BARCODE_QRCODE3             : Result := BARCODE_QRCODE;
    DIO_BARCODE_AUSPOST             : Result := BARCODE_AUSPOST;
    DIO_BARCODE_AUSREPLY            : Result := BARCODE_AUSREPLY;
    DIO_BARCODE_AUSROUTE            : Result := BARCODE_AUSROUTE;
    DIO_BARCODE_AUSREDIRECT         : Result := BARCODE_AUSREDIRECT;
    DIO_BARCODE_ISBNX               : Result := BARCODE_ISBNX;
    DIO_BARCODE_RM4SCC              : Result := BARCODE_RM4SCC;
    DIO_BARCODE_DATAMATRIX          : Result := BARCODE_DATAMATRIX;
    DIO_BARCODE_EAN14               : Result := BARCODE_EAN14;
    DIO_BARCODE_CODABLOCKF          : Result := BARCODE_CODABLOCKF;
    DIO_BARCODE_NVE18               : Result := BARCODE_NVE18;
    DIO_BARCODE_JAPANPOST           : Result := BARCODE_JAPANPOST;
    DIO_BARCODE_KOREAPOST           : Result := BARCODE_KOREAPOST;
    DIO_BARCODE_RSS14STACK          : Result := BARCODE_RSS14STACK;
    DIO_BARCODE_RSS14STACK_OMNI     : Result := BARCODE_RSS14STACK_OMNI;
    DIO_BARCODE_RSS_EXPSTACK        : Result := BARCODE_RSS_EXPSTACK;
    DIO_BARCODE_PLANET              : Result := BARCODE_PLANET;
    DIO_BARCODE_MICROPDF417         : Result := BARCODE_MICROPDF417;
    DIO_BARCODE_ONECODE             : Result := BARCODE_ONECODE;
    DIO_BARCODE_PLESSEY             : Result := BARCODE_PLESSEY;
    DIO_BARCODE_TELEPEN_NUM         : Result := BARCODE_TELEPEN_NUM;
    DIO_BARCODE_ITF14               : Result := BARCODE_ITF14;
    DIO_BARCODE_KIX                 : Result := BARCODE_KIX;
    DIO_BARCODE_AZTEC               : Result := BARCODE_AZTEC;
    DIO_BARCODE_DAFT                : Result := BARCODE_DAFT;
    DIO_BARCODE_MICROQR             : Result := BARCODE_MICROQR;
    DIO_BARCODE_HIBC_128            : Result := BARCODE_HIBC_128;
    DIO_BARCODE_HIBC_39             : Result := BARCODE_HIBC_39;
    DIO_BARCODE_HIBC_DM             : Result := BARCODE_HIBC_DM;
    DIO_BARCODE_HIBC_QR             : Result := BARCODE_HIBC_QR;
    DIO_BARCODE_HIBC_PDF            : Result := BARCODE_HIBC_PDF;
    DIO_BARCODE_HIBC_MICPDF         : Result := BARCODE_HIBC_MICPDF;
    DIO_BARCODE_HIBC_BLOCKF         : Result := BARCODE_HIBC_BLOCKF;
    DIO_BARCODE_HIBC_AZTEC          : Result := BARCODE_HIBC_AZTEC;
    DIO_BARCODE_AZRUNE              : Result := BARCODE_AZRUNE;
    DIO_BARCODE_CODE32              : Result := BARCODE_CODE32;
    DIO_BARCODE_EANX_CC             : Result := BARCODE_EANX_CC;
    DIO_BARCODE_EAN128_CC           : Result := BARCODE_EAN128_CC;
    DIO_BARCODE_RSS14_CC            : Result := BARCODE_RSS14_CC;
    DIO_BARCODE_RSS_LTD_CC          : Result := BARCODE_RSS_LTD_CC;
    DIO_BARCODE_RSS_EXP_CC          : Result := BARCODE_RSS_EXP_CC;
    DIO_BARCODE_UPCA_CC             : Result := BARCODE_UPCA_CC;
    DIO_BARCODE_UPCE_CC             : Result := BARCODE_UPCE_CC;
    DIO_BARCODE_RSS14STACK_CC       : Result := BARCODE_RSS14STACK_CC;
    DIO_BARCODE_RSS14_OMNI_CC       : Result := BARCODE_RSS14_OMNI_CC;
    DIO_BARCODE_RSS_EXPSTACK_CC     : Result := BARCODE_RSS_EXPSTACK_CC;
    DIO_BARCODE_CHANNEL             : Result := BARCODE_CHANNEL;
    DIO_BARCODE_CODEONE             : Result := BARCODE_CODEONE;
    DIO_BARCODE_GRIDMATRIX          : Result := BARCODE_GRIDMATRIX;
  else
    raiseExceptionFmt('%s, %d', [_('Invalid barcode type'), DIOBarcodeType]);
  end;
end;

function IsPDF417(BarcodeType: Integer): Boolean;
begin
  Result := BarcodeType in [DIO_BARCODE_PDF417,
    DIO_BARCODE_PDF417TRUNC, DIO_BARCODE_MICROPDF417];
end;

procedure RenderBarcode(Bitmap: TBitmap; Symbol: PZintSymbol; Is1D: Boolean);
var
  B: Byte;
  Mask: Byte;
  X, Y: Integer;
begin
  Bitmap.Monochrome := True;
  Bitmap.PixelFormat := pf1Bit;
  Bitmap.Width := Symbol.width;
  if Is1D then
    Bitmap.Height := Round(Symbol.Height)
  else
    Bitmap.Height := Round(Symbol.rows);

  for Y := 0 to Bitmap.Height-1 do
  for X := 0 to Bitmap.width-1 do
  begin
    Bitmap.Canvas.Pixels[X, Y] := clWhite;
    if Is1D then
      B := Symbol.encoded_data[0][X div 8]
    else
      B := Symbol.encoded_data[Y][X div 8];

    Mask := 1 shl (X mod 8);
    if (B and Mask) <> 0 then
      Bitmap.Canvas.Pixels[X, Y] := clBlack;
  end;
end;

(*
procedure RenderBarcode(Bitmap: TBitmap; Symbol: PZintSymbol; Is1D: Boolean);
var
  Count: Integer;
  Stream: TMemoryStream;
begin
  Bitmap.Monochrome := True;
  Bitmap.PixelFormat := pf1Bit;
  Bitmap.Width := Symbol.bitmap_width;
  Bitmap.Height := Symbol.bitmap_height;

  Stream := TMemoryStream.Create;
  try
    Count := Symbol.bitmap_height * Symbol.bitmap_width * 3;
    Stream.Write(Symbol.bitmap, Count);
    Stream.Position := 0;
    Stream.SaveToFile('test.bmp');
    Bitmap.LoadFromStream(Stream);
    //Bitmap image is not valid
  finally
    Stream.Free;
  end;
end;
*)

procedure ScaleBitmap(Bitmap: TBitmap; Xscale, YSCale: Integer);
var
  P: TPoint;
  DstBitmap: TBitmap;
begin
  DstBitmap := TBitmap.Create;
  try
    DstBitmap.Monochrome := True;
    DstBitmap.PixelFormat := pf1Bit;
    P.X := Bitmap.Width * XScale;
    P.Y := Bitmap.Height * YScale;
    DstBitmap.Width := P.X;
    DstBitmap.Height := P.Y;
    DstBitmap.Canvas.StretchDraw(Rect(0, 0, P.X, P.Y), Bitmap);
    Bitmap.Assign(DstBitmap);
  finally
    DstBitmap.Free;
  end;
end;

procedure TFiscalPrinterDriver.AlignBitmap(Bitmap: TBitmap;
  const Barcode: TBarcodeRec; HScale: Integer; PrintWidthInDots: Integer);
var
  Bmp: TBitmap;
  XOffset: Integer;
begin
  if Barcode.Alignment = BARCODE_ALIGNMENT_LEFT then Exit;
  if HScale = 0 then
    raiseException('HScale = 0');
  PrintWidthInDots := PrintWidthInDots div HScale;

  XOffset := 0;
  case Barcode.Alignment of
    BARCODE_ALIGNMENT_CENTER:
    begin
      XOffset := (PrintWidthInDots - Bitmap.Width) div 2;
    end;
    BARCODE_ALIGNMENT_RIGHT:
    begin
      XOffset := PrintWidthInDots - Bitmap.Width;
    end;
  end;
  Bmp := TBitmap.Create;
  try
    Bmp.Monochrome := True;
    Bmp.PixelFormat := pf1Bit;
    Bmp.Width := Bitmap.Width + XOffset;
    Bmp.Height := Bitmap.Height;
    Bmp.Canvas.Draw(XOffset, 0, Bitmap);
    Bitmap.Assign(Bmp);
  finally
    Bmp.Free;
  end;
end;

function TFiscalPrinterDriver.GetMaxGraphicsHeight: Integer;
begin
  Result := 0;
  if FCapGraphics1 then
    Result := 200;
  if FCapGraphics2 then
    Result := 1200;
  if FCapGraphics512 then
    Result := 600;
end;

function TFiscalPrinterDriver.GetMaxGraphicsWidth: Integer;
begin
  Result := 0;
  if FCapGraphics512 then
  begin
    Result := 512;
  end else
  begin
    if ValidFont(1) then
      Result := FFontInfo[0].PrintWidth;
  end;
end;

function TFiscalPrinterDriver.GetMaxGraphicsWidthInBytes: Integer;
begin
  Result := GetMaxGraphicsWidth div 8;
end;

procedure TFiscalPrinterDriver.PrintQRCode3(Barcode: TBarcodeRec);

  procedure DrawQRCodeText(URL, Sign: AnsiString; Bitmap: TBitmap;
    BitmapWidth: Integer);
  var
    Y: Integer;
    Bits: TBits;
    i, j, k: Integer;
    Line: AnsiString;
    Lines: TTntStrings;
    LineLength: Integer;
    CharLine: Integer;
  begin
    Bitmap.Canvas.Brush.Style := bsSolid;

    LineLength := 35;
    Bits := TBits.Create;
    Lines := TTntStringList.Create;
    try
      while Length(URL) > 0 do
      begin
        Lines.Add(Copy(URL, 1, LineLength));
        URL := Copy(URL, LineLength+1, Length(URL));
      end;
      while Length(Sign) > 0 do
      begin
        Lines.Add(Copy(Sign, 1, LineLength));
        Sign := Copy(Sign, LineLength+1, Length(Sign));
      end;
      for i := 0 to Lines.Count-1 do
      begin
        Line := Lines[i];
        for k := 0 to 13 do
        begin
          Y := k + 18*i;
          if Y > Bitmap.Height then Break;

          Bits.Clear;
          for j := 1 to Length(Line) do
          begin
            CharLine := cFont14x8[Ord(Line[j]) * FONT_5_HEIGHT + k];
            Bits.add(CharLine, 8);
            Bits.add(0, 2);
          end;
          Bits.UpdateBytes;
          for j := 0 to Bits.SizeInBytes-1 do
          begin
            PByteArray(Bitmap.ScanLine[Y])[j] := Bits.Bytes(j) xor $FF;
          end;
        end;
      end;
    finally
      Bits.Free;
      Lines.Free;
    end;
  end;

var
  P: Integer;
  URLText: AnsiString;
  SignText: AnsiString;
  Bitmap: TBitmap;
  StartLine: Integer;
  BitmapWidth: Integer;
  Render: TZintBarcode;
  MaxGraphicsWidth: Integer;
  MaxGraphicsHeight: Integer;
  Graphics3: TPrintGraphics3;
begin
  SignText := '';
  URLText := Barcode.Data;
  P := Pos(' ', Barcode.Data);
  if P <> 0 then
  begin
    URLText := Copy(Barcode.Data, 1, P-1);
    SignText := Copy(Barcode.Data, P+1, Length(Barcode.Data));
  end;
  Barcode.Data := URLText;
  Barcode.Alignment := BARCODE_ALIGNMENT_RIGHT;
  MaxGraphicsHeight := GetMaxGraphicsHeight;
  MaxGraphicsWidth := GetMaxGraphicsWidth;

  Bitmap := TBitmap.Create;
  Render := TZintBarcode.Create;
  try
    Render.BorderWidth := 0;
    Render.FGColor := clBlack;
    Render.BGColor := clWhite;
    Render.Scale := 1;
    Render.Height := Barcode.Height;
    Render.BarcodeType := GetZIntBarcodeType(Barcode.BarcodeType);
    Render.Data := Barcode.Data;
    Render.ShowHumanReadableText := False;
    Render.EncodeNow;
    RenderBarcode(Bitmap, Render.Symbol, Is1DBarcode(Barcode.BarcodeType));


    ScaleBitmap(Bitmap, Barcode.ModuleWidth, Barcode.ModuleWidth);


    if Bitmap.Width > MaxGraphicsWidth then
      raiseExceptionFmt('%s, %d > %d', [_('Bitmap width more than maximum'),
        Bitmap.Width, MaxGraphicsWidth]);

    if Bitmap.Height > MaxGraphicsHeight then
      raiseExceptionFmt('%s, %d > %d', [_('Bitmap height more than maximum'),
        Bitmap.Height, MaxGraphicsHeight]);

    BitmapWidth := Bitmap.Width;
    AlignBitmap(Bitmap, Barcode, 1, MaxGraphicsWidth);

    DrawQRCodeText(URLText, SignText, Bitmap, BitmapWidth);

    StartLine := GetStartLine;
    LoadBitmap(StartLine, Bitmap);
    if FCapGraphics512 then
    begin
      Graphics3.FirstLine := StartLine;
      Graphics3.LastLine := StartLine + Bitmap.Height -1;
      Graphics3.VScale := 1;
      Graphics3.HScale := 1;
      Graphics3.Flags := PRINTER_STATION_REC;
      Check(PrintGraphics3(Graphics3));
    end else
    begin
      Check(PrintGraphics(StartLine, Bitmap.Height + StartLine));
    end;
  finally
    Render.Free;
    Bitmap.Free;
  end;
end;

procedure TFiscalPrinterDriver.PrintBarcodeZInt(const Barcode: TBarcodeRec);
var
  P: TDrawScale;
  Bitmap: TBitmap;
  StartLine: Integer;
  ModuleWidth: Integer;
  Render: TZintBarcode;
  VScale, HScale: Integer;
  MaxGraphicsWidth: Integer;
  MaxGraphicsHeight: Integer;
  Graphics3: TPrintGraphics3;
begin
  MaxGraphicsHeight := GetMaxGraphicsHeight;
  MaxGraphicsWidth := GetMaxGraphicsWidth;
  if Is2DBarcode(Barcode.BarcodeType) or (not FCapBarLine) then
  begin
    if FCapGraphics512 then
    begin
      MaxGraphicsWidth := Min(512, MaxGraphicsWidth);
    end else
    begin
      if not FCapScaleGraphics then
      begin
        MaxGraphicsWidth := 320;
      end;
    end;
  end;

  ModuleWidth := Barcode.ModuleWidth;
  StartLine := GetStartLine;

  Bitmap := TBitmap.Create;
  Render := TZintBarcode.Create;
  try
    Render.BorderWidth := 0;
    Render.FGColor := clBlack;
    Render.BGColor := clWhite;
    Render.Scale := 1;
    Render.Height := Barcode.Height;
    Render.BarcodeType := GetZIntBarcodeType(Barcode.BarcodeType);
    Render.Data := Barcode.Data;
    Render.ShowHumanReadableText := False;
    Render.EncodeNow;
    RenderBarcode(Bitmap, Render.Symbol, Is1DBarcode(Barcode.BarcodeType));

    VScale := 1;
    HScale := ModuleWidth;
    if Is2DBarcode(Barcode.BarcodeType) then
    begin
      if Model.ID <> 19 then
      begin
        VScale := 1;
        HScale := 1;
        ScaleBitmap(Bitmap, ModuleWidth, ModuleWidth);
      end else
      begin
        if IsPDF417(Barcode.BarcodeType) then
          VScale := ModuleWidth*3
        else
          VScale := ModuleWidth;
      end;
    end;

    if Is1DBarcode(Barcode.BarcodeType)and FCapBarLine then
    begin
      ScaleBitmap(Bitmap, HScale, 1);
      HScale := 1;
    end else
    begin
      if not FCapGraphics512 then
      begin
        if FCapScaleGraphics then
        begin
          ScaleBitmap(Bitmap, HScale, 1);
        end else
        begin
          ScaleBitmap(Bitmap, HScale, VScale);
          VScale := 1;
        end;
        HScale := 1;
      end;
    end;

    if Bitmap.Width > MaxGraphicsWidth then
      raiseExceptionFmt('%s, %d > %d', [_('Bitmap width more than maximum'),
        Bitmap.Width, MaxGraphicsWidth]);

    if Bitmap.Height > MaxGraphicsHeight then
      raiseExceptionFmt('%s, %d > %d', [_('Bitmap height more than maximum'),
        Bitmap.Height, MaxGraphicsHeight]);


    AlignBitmap(Bitmap, Barcode, HScale, MaxGraphicsWidth);

    if Is1DBarcode(Barcode.BarcodeType) then
    begin
      if FCapBarLine then
      begin
        PrintBarLine(Barcode.Height, GetLineData(Bitmap, 0));
      end else
      begin
        LoadBitmap(StartLine, Bitmap);
        Check(PrintGraphics(StartLine, Bitmap.Height + StartLine));
      end;
    end else
    begin
      LoadBitmap(StartLine, Bitmap);
      if FCapGraphics512 then
      begin
        Graphics3.FirstLine := StartLine;
        Graphics3.LastLine := StartLine + Bitmap.Height -1;
        Graphics3.VScale := VScale;
        Graphics3.HScale := HScale;
        Graphics3.Flags := PRINTER_STATION_REC;
        Check(PrintGraphics3(Graphics3));
      end else
      begin
        if FCapScaleGraphics then
        begin
          P.FirstLine := StartLine;
          P.LastLine := StartLine + Bitmap.Height;
          P.VScale := VScale;
          P.HScale := 0;
          Check(DrawScale(P));
        end else
        begin
          Check(PrintGraphics(StartLine, Bitmap.Height + StartLine));
        end;
      end;
    end;
  finally
    Render.Free;
    Bitmap.Free;
  end;
end;

procedure TFiscalPrinterDriver.BarcodeToBitmap(
  const Barcode: TBarcodeRec; Bitmap: TBitmap);
var
  Render: TZintBarcode;
  VScale, HScale: Integer;
  MaxGraphicsWidth: Integer;
  MaxGraphicsHeight: Integer;
begin
  MaxGraphicsHeight := GetMaxGraphicsHeight;
  MaxGraphicsWidth := GetMaxGraphicsWidth;
  if Is2DBarcode(Barcode.BarcodeType) or (not FCapBarLine) then
  begin
    if FCapGraphics512 then
    begin
      MaxGraphicsWidth := Min(512, MaxGraphicsWidth);
    end else
    begin
      if not FCapScaleGraphics then
      begin
        MaxGraphicsWidth := 320;
      end;
    end;
  end;

  Render := TZintBarcode.Create;
  try
    Render.BorderWidth := 0;
    Render.FGColor := clBlack;
    Render.BGColor := clWhite;
    Render.Scale := 1;
    Render.Height := Barcode.Height;
    Render.BarcodeType := GetZIntBarcodeType(Barcode.BarcodeType);
    Render.Data := Barcode.Data;
    Render.ShowHumanReadableText := False;
    Render.EncodeNow;
    RenderBarcode(Bitmap, Render.Symbol, Is1DBarcode(Barcode.BarcodeType));

    VScale := 1;
    HScale := Barcode.ModuleWidth;
    if Is2DBarcode(Barcode.BarcodeType) then
    begin
      if Model.ID <> 19 then
      begin
        VScale := 1;
        HScale := 1;
        ScaleBitmap(Bitmap, Barcode.ModuleWidth, Barcode.ModuleWidth);
      end else
      begin
        if IsPDF417(Barcode.BarcodeType) then
          VScale := Barcode.ModuleWidth * 3
        else
          VScale := Barcode.ModuleWidth;
      end;
    end;

    if Is1DBarcode(Barcode.BarcodeType)and FCapBarLine then
    begin
      ScaleBitmap(Bitmap, HScale, 1);
    end else
    begin
      if not FCapGraphics512 then
      begin
        if FCapScaleGraphics then
        begin
          ScaleBitmap(Bitmap, HScale, 1);
        end else
        begin
          ScaleBitmap(Bitmap, HScale, VScale);
        end;
      end;
    end;

    if Bitmap.Width > MaxGraphicsWidth then
      raiseExceptionFmt('%s, %d > %d', [_('Bitmap width more than maximum'),
        Bitmap.Width, MaxGraphicsWidth]);

    if Bitmap.Height > MaxGraphicsHeight then
      raiseExceptionFmt('%s, %d > %d', [_('Bitmap height more than maximum'),
        Bitmap.Height, MaxGraphicsHeight]);

  finally
    Render.Free;
  end;
end;

procedure TFiscalPrinterDriver.PrintImage(const FileName: WideString;
  StartLine: Integer);
var
  ImageHeight: Integer;
begin
  ImageHeight := LoadImage(FileName, StartLine);
  Check(PrintGraphics(StartLine, StartLine + ImageHeight - 1));
end;

procedure TFiscalPrinterDriver.PrintImageScale(const FileName: WideString;
  StartLine, Scale: Integer);
var
  Bitmap: TBitmap;
  Picture: TPicture;
  P: TPrintGraphics3;
begin
  if not(Scale in [1..10]) then
    Scale := 1;

  Bitmap := TBitmap.Create;
  Picture := TPicture.Create;
  try
    Picture.LoadFromFile(FileName);

    Bitmap.PixelFormat := pf1Bit;
    Bitmap.Monochrome := True;
    Bitmap.Width := Picture.Width;
    Bitmap.Height := Picture.Height;
    Bitmap.Canvas.Draw(0, 0, Picture.Graphic);

    if FCapGraphics512 then
    begin
      LoadBitmap512(StartLine, Bitmap, Scale);
    end else
    begin
      LoadBitmap320(StartLine, Bitmap);
    end;

    if FCapGraphics512 then
    begin
      P.FirstLine := StartLine;
      P.LastLine := StartLine + Bitmap.Height-1;
      P.VScale := Scale;
      P.HScale := Scale;
      P.Flags := PRINTER_STATION_REC;
      Check(PrintGraphics3(P));
    end else
    begin
      Check(PrintGraphics(StartLine, StartLine + Bitmap.Height-1));
    end;
  finally
    Bitmap.Free;
    Picture.Free;
  end;
end;

procedure AlignBitmapWidth(Bitmap: TBitmap; const NewWidth: Integer);
var
  NewHeight: Integer;
begin
  if Bitmap.Width = 0 then
    raiseException('Bitmap.Width = 0');

  NewHeight := Trunc(Bitmap.Height*(NewWidth/Bitmap.Width));
  Bitmap.Canvas.StretchDraw(
    Rect(0, 0, NewWidth, NewHeight),
    Bitmap);
  Bitmap.Width := NewWidth;
  Bitmap.Height := NewHeight;
end;

function IsInversedPalette(Bitmap: TBitmap): Boolean;
var
  PaletteSize: Integer;
  PalEntry: TPaletteEntry;
begin
  Result := False;
  if Bitmap.Palette <> 0 then
  begin
    PaletteSize := 0;
    if GetObject(Bitmap.Palette, SizeOf(PaletteSize), @PaletteSize) = 0 then Exit;
    if PaletteSize = 0 then Exit;
    GetPaletteEntries(Bitmap.Palette, 0, 1, PalEntry);
    Result := (PalEntry.peRed = $FF)and(PalEntry.peGreen = $FF)and(PalEntry.peBlue = $FF);
  end;
end;

function Inverse(const S: AnsiString): AnsiString;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
    Result := Result + Chr(Ord(S[i]) xor $FF);
end;

function TFiscalPrinterDriver.GetLineData(Bitmap: TBitmap; Index: Integer): AnsiString;
var
  B: Byte;
  i: Integer;
  Len: Integer;
const
  Mask: array [0..7] of Byte = ($FF, $80, $C0, $E0, $F0, $F8, $FC, $FE);
begin
  Result := '';
  Len := (Bitmap.Width + 7 )div 8;
  for i := 0 to Len-1 do
  begin
    B := $FF - PByteArray(Bitmap.ScanLine[Index])[i];
    if i = (Len-1) then
      B := B and Mask[Bitmap.Width mod 8];
    Result := Result + Chr(SwapByte(B));
  end;

  // If palette is inverse
  if IsInversedPalette(Bitmap) then
    Result := Inverse(Result);
end;

procedure TFiscalPrinterDriver.ProgressEvent(Progress: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Progress);
end;

procedure TFiscalPrinterDriver.LoadBitmap(StartLine: Integer; Bitmap: TBitmap);
begin
  Bitmap.Monochrome := True;
  Bitmap.PixelFormat := pf1Bit;

  if Bitmap.Height = 0 then
    raiseException(_('Image height is zero, must be > 0'));

  if Bitmap.Width = 0 then
    raiseException(_('Image width is zero, must be > 0'));

  if Bitmap.Width > GetMaxGraphicsWidth then
    AlignBitmapWidth(Bitmap, GetMaxGraphicsWidth);

  Bitmap.Height := Min(Bitmap.Height, GetMaxGraphicsHeight);
  if FCapGraphics512 then
  begin
    LoadBitmap512(StartLine, Bitmap, 1);
  end else
  begin
    LoadBitmap320(StartLine, Bitmap);
  end;
end;

procedure TFiscalPrinterDriver.LoadBitmap320(StartLine: Integer; Bitmap: TBitmap);
var
  i: Integer;
  Data: AnsiString;
  Count: Integer;
  Progress: Integer;
  NewProgress: Integer;
  ProgressStep: Double;
begin
  Progress := 0;
  Count := Bitmap.Height;
  ProgressStep := Bitmap.Height/100;
  for i := 0 to Count-1 do
  begin
    Data := GetLineData(Bitmap, i);
    Data := GetDataBlock(Data, 40, 40);
    Check(LoadGraphics(i+ StartLine, Data));
    NewProgress := 0;
    if ProgressStep <> 0 then
      NewProgress := Round(i/ProgressStep);

    if (NewProgress <> Progress)and(NewProgress <= 100) then
    begin
      Progress := NewProgress;
      ProgressEvent(NewProgress);
    end;
  end;
  ProgressEvent(100);
end;

procedure TFiscalPrinterDriver.LoadBitmap512(StartLine: Integer;
  Bitmap: TBitmap; Scale: Integer);
var
  i, j: Integer;
  Line: AnsiString;
  Row: Integer;
  Progress: Integer;
  NewProgress: Integer;
  ProgressStep: Double;
  CommandCount: Integer;
  RowsPerCommand: Integer;
  LineLength: Integer;
  RowCount: Integer;
const
  BytesPerCommand = 240;
begin
  Progress := 0;
  LineLength := (Bitmap.Width + 7) div 8;
  RowsPerCommand := 0;
  if LineLength <> 0 then
    RowsPerCommand := BytesPerCommand div LineLength;
  if RowsPerCommand = 0 then
    raiseException('RowsPerCommand = 0');
  CommandCount := (Bitmap.Height + RowsPerCommand -1) div RowsPerCommand;
  ProgressStep := CommandCount/100;
  Row := 0;
  for i := 0 to CommandCount-1 do
  begin
    Line := '';
    RowCount := 0;
    for j := 0 to RowsPerCommand-1 do
    begin
      Line := Line + GetLineData(Bitmap, Row);
      Inc(Row);
      Inc(RowCount);
      if Row >= Bitmap.Height then Break;
    end;
    EnsureConnected;
    SetDriverPassword(GetUsrPassword);
    Driver.LineLength := LineLength;
    Driver.FirstLineNumber := StartLine;
    Driver.LineNumber := RowCount;
    Driver.GraphBufferType := 1;
    Driver.LineDataHex := StrToHex(Line);
    CheckDriver(Driver.LoadGraphics512);
    Inc(StartLine, RowsPerCommand);
    NewProgress := 0;
    if ProgressStep <> 0 then
      NewProgress := Round(i/ProgressStep);
    if (NewProgress <> Progress)and(NewProgress <= 100) then
    begin
      Progress := NewProgress;
      ProgressEvent(NewProgress);
    end;
  end;
  ProgressEvent(100);
end;

function TFiscalPrinterDriver.LoadImage(const FileName: WideString;
  StartLine: Integer): Integer;
var
  Picture: TPicture;
begin
  Picture := TPicture.Create;
  try
    Picture.LoadFromFile(FileName);
    Result := LoadPicture(Picture, StartLine);
  finally
    Picture.Free;
  end;
end;

function TFiscalPrinterDriver.LoadPicture(Picture: TPicture;
  StartLine: Integer): Integer;
var
  Bitmap: TBitmap;
  XOffset: Integer;
begin
  XOffset := 0;
  if Parameters.LogoCenter then
  begin
    XOffset := (GetMaxGraphicsWidth - Picture.Width) div 2;
  end;

  Bitmap := TBitmap.Create;
  try
    Bitmap.PixelFormat := pf1Bit;
    Bitmap.Monochrome := True;
    Bitmap.Width := Picture.Width + XOffset;
    Bitmap.Height := Picture.Height;
    Bitmap.Canvas.Draw(XOffset, 0, Picture.Graphic);


    LoadBitmap(StartLine, Bitmap);
    Result := Bitmap.Height;
  finally
    Bitmap.Free;
  end;
end;

function IntToFFDVersion(Value: Integer): TFFDVersion;
begin
  case Value of
    1: Result := ffd10;
    2: Result := ffd105;
    3: Result := ffd11;
    4: Result := ffd12;
  else
    Result := ffdUnknown;
  end;
end;

function TFiscalPrinterDriver.GetFFDVersion: TFFDVersion;
begin
  if FFFDVersion = TFFDVersion(-1) then
    FFFDVersion := IntToFFDVersion(ReadTableInt(17,1,17));
  Result := FFFDVersion;
end;

procedure TFiscalPrinterDriver.Connect;
begin
  GetDeviceMetrics;
end;

procedure TFiscalPrinterDriver.UpdateInfo;
begin
  GetPrinterModel;
  FCapCloseReceipt3 := False;
  FCapParameters2 := ReadParameters2(FParameters2) = 0;
  if FCapParameters2 then
  begin
    FCapGraphics512 := FParameters2.Flags.CapGraphics512;
    FCapScaleGraphics := FParameters2.Flags.CapScaleGraphics;

    FModelData.CapCoverSensor := FParameters2.Flags.CapCoverSensor;
    FModelData.CapJrnPresent := FParameters2.Flags.CapJrnPresent;
    FModelData.CapJrnEmptySensor := FParameters2.Flags.CapJrnEmptySensor;
    FModelData.CapJrnNearEndSensor := FParameters2.Flags.CapJrnNearEndSensor;
    FModelData.CapRecEmptySensor := FParameters2.Flags.CapRecEmptySensor;
    FModelData.CapRecNearEndSensor := FParameters2.Flags.CapRecNearEndSensor;
    FModelData.CapSlpEmptySensor := FParameters2.Flags.CapSlpEmptySensor;
    FModelData.CapSlpNearEndSensor := FParameters2.Flags.CapSlpNearEndSensor;
    FModelData.CapSlpPresent := FParameters2.Flags.CapSlpPresent;
    FModelData.CapRecLever := FParameters2.Flags.CapRecLeverSensor;
    FModelData.CapJrnLever := FParameters2.Flags.CapJrnLeverSensor;
  end else
  begin
    FCapGraphics512 := True;
    FCapScaleGraphics := True;
  end;
  FCapFooterFlag := FCapParameters2 and FParameters2.Flags.CapFlagsGraphicsEx;

  ReadLongStatus;
  FCapBarcode2D := True;

  FCapFiscalStorage := True;
  if Parameters.ModelId <> MODEL_ID_WEB_CASSA then
    FCapFiscalStorage := ReadCapFiscalStorage;

  FCapFontInfo := True;
  if FCapFontInfo then
  begin
    FFontInfo := ReadFontInfoList;
  end;
  FTaxInfo := ReadTaxInfoList;

  if FCapFiscalStorage then
  begin
    FDiscountMode := ReadDiscountMode;
    FDocPrintMode := ReadDocPrintMode;
  end;
  FCapEnablePrint := GetDeviceMetrics.Model <> 19;
  FIsFiscalized := FCapFiscalStorage or (FLongStatus.RegistrationNumber <> 0);
  FCapDiscount := not FCapFiscalStorage;
  FCapSubtotalRound := FCapFiscalStorage;
  FCondensedFont := ReadTableInt(1, 1, PARAMID_CONDENSED_FONT) = 1;
  FHeadToCutterDistanse := ReadTableInt(10, 1, 1);
  FCutterToCombDistanse := ReadTableInt(10, 1, 2);
  if FHeadToCutterDistanse <> 0 then
  begin
    FModelData.NumHeaderLines := FHeadToCutterDistanse div FFontInfo[1].CharHeight;
  end;
end;

function TFiscalPrinterDriver.GetTaxCount: Integer;
begin
  Result := Length(FTaxInfo);
end;

// Read font info
function TFiscalPrinterDriver.ReadFontInfoList: TFontInfoList;
var
  i: Integer;
  FontInfo: TFontInfo;
begin
  SetLength(Result, 0);
  FontInfo := ReadFontInfo(1);
  if FontInfo.FontCount > 0 then
  begin
    SetLength(Result, FontInfo.FontCount);
    Result[0] := FontInfo;
    for i := 2 to FontInfo.FontCount do
    begin
      Result[i-1] := ReadFontInfo(i);
    end;
  end;
end;

// Read tax Info
function TFiscalPrinterDriver.ReadTaxInfoList: TTaxInfoList;
var
  i: Integer;
  Table: TPrinterTableRec;
begin
  SetLength(Result, 0);
  Check(ReadTableStructure(PRINTER_TABLE_TAX, Table));
  if Table.RowCount > 0 then
  begin
    SetLength(Result, Table.RowCount);
    for i := 1 to Table.RowCount do
    begin
      Result[i-1].Rate := ReadTableInt(PRINTER_TABLE_TAX, i, 1);
      Result[i-1].Name := ReadTableStr(PRINTER_TABLE_TAX, i, 2);
    end;
  end;
end;

// Is fiscal printer firmware 2 (Semenov)
function TFiscalPrinterDriver.IsMobilePrinter: Boolean;
begin
  Result := GetDeviceMetrics.Model = 19;
end;

function TFiscalPrinterDriver.GetTaxInfo(Tax: Integer): TTaxInfo;
begin
  Result.Rate := 0;
  Result.Name := '';
  if (Tax >= 1)and(Tax <= Length(FTaxInfo)) then
    Result := FTaxInfo[Tax-1];
end;

function TFiscalPrinterDriver.ReadCapFiscalStorage: Boolean;
var
  R: TFSState;
begin
  try
    Result := FSReadState(R) = 0;
  except
    Result := False;
  end;
end;

function TFiscalPrinterDriver.WaitForPrinting: TPrinterStatus;
var
  Mode: Byte;
  TryCount: Integer;
  TickCount: Integer;
const
  MaxTryCount = 3;
begin
  Logger.Debug('TSharedPrinter.WaitForPrinting');
  TryCount := 0;
  TickCount := GetTickCount;
  repeat
    if Integer(GetTickCount) > (TickCount + Parameters.StatusTimeout*1000) then
      raiseException(SStatusWaitTimeout);

    Result := ReadPrinterStatus;
    Mode := Result.Mode and $0F;
    case Result.AdvancedMode of
      AMODE_IDLE:
      begin
        case Mode of
          MODE_FULLREPORT,
          MODE_EKLZREPORT,
          MODE_SLPPRINT:
            Sleep(Parameters.StatusInterval);
        else
          Exit;
        end;
      end;

      AMODE_PASSIVE,
      AMODE_ACTIVE:
      begin
        // No receipt paper
        if GetModel.CapRecPresent and Result.Flags.RecEmpty then
          raiseOposFptrRecEmpty;
        // No control paper
        if GetModel.CapJrnPresent and Result.Flags.JrnEmpty then
          raiseOposFptrJrnEmpty;
        // Cover is opened
        if GetModel.CapCoverSensor and Result.Flags.CoverOpened then
          raiseOposFptrCoverOpened;

        raiseOposFptrRecEmpty;
      end;

      AMODE_AFTER:
      begin
        if TryCount > MaxTryCount then
          raiseException(_('Failed to continue print'));
        ContinuePrint;
        Inc(TryCount);
      end;

      AMODE_REPORT,
      AMODE_PRINT:
        Sleep(Parameters.StatusInterval);
    else
      Sleep(Parameters.StatusInterval);
    end;
  until False;
end;

function TFiscalPrinterDriver.GetPrinterStatus: TPrinterStatus;
begin
  Result := FPrinterStatus;
end;

function TFiscalPrinterDriver.ReadPrinterStatus: TPrinterStatus;
begin
  Logger.Debug('TSharedPrinter.ReadPrinterStatus');
  case Parameters.StatusCommand of
    // Driver will select command to read printer status
    StatusCommandDriver:
    begin
      if CapShortEcrStatus then
      begin
        ReadShortStatus;
      end else
      begin
        ReadLongStatus;
      end;
    end;
    // Short status command
    StatusCommandShort: ReadShortStatus;
  else
    // Long status command
    ReadLongStatus;
  end;
  Result := FPrinterStatus;
end;

function TFiscalPrinterDriver.PrintBarLine(Height: Word; Data: AnsiString): Integer;
var
  IsSwapBytes: Boolean;
begin
  case Parameters.BarLineByteMode of
    BarLineByteModeAuto:
    begin
      if FCapParameters2 then
      begin
        IsSwapBytes := not FParameters2.Flags.SwapGraphicsLine;
      end else
      begin
        IsSwapBytes := Model.BarcodeSwapBytes;
      end;
    end;
    BarLineByteModeStraight: IsSwapBytes := False;
    BarLineByteModeReverse: IsSwapBytes := True;
  else
    IsSwapBytes := False;
  end;
  if IsSwapBytes then
  begin
    Data := SwapBytes(Data);
  end;

  Result := PrintGraphicsLine(Height, PRINTER_STATION_REC, Data);
  if Result = 0 then
  begin
    Sleep(Parameters.BarLinePrintDelay);
  end;
end;

function TFiscalPrinterDriver.LoadBarcode2D(const Data: TBarcode2DData): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.BlockType := Data.BlockType;
  Driver.BlockNumber := Data.BlockNumber;
  Driver.BlockDataHex := StrToHex(Data.BlockData);
  Result := Driver.LoadBlockData;
end;

function TFiscalPrinterDriver.PrintBarcode2D(const Barcode: TBarcode2D): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.BarcodeType := Barcode.BarcodeType;
  Driver.BarcodeDataLength := Barcode.DataLength;
  Driver.BarcodeStartBlockNumber := Barcode.BlockNumber;
  Driver.BarcodeParameter1 := Barcode.Parameter1;
  Driver.BarcodeParameter2 := Barcode.Parameter2;
  Driver.BarcodeParameter3 := Barcode.Parameter3;
  Driver.BarcodeParameter4 := Barcode.Parameter4;
  Driver.BarcodeParameter5 := Barcode.Parameter5;
  Result := Driver.Print2DBarcode;
end;

function TFiscalPrinterDriver.LoadGraphics3(Line: Word; Data: AnsiString): Integer;
begin
  if Length(Data) > 64 then
    raiseException(_('Image data length > 64 bytes'));

  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.LineLength := Length(Data);
  Driver.FirstLineNumber := Line;
  Driver.LineNumber := 1;
  Driver.GraphBufferType := 1;
  Driver.LineDataHex := StrToHex(Data);
  Result := Driver.LoadGraphics512;
end;

function TFiscalPrinterDriver.LoadGraphics3(const P: TLoadGraphics3): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.LineLength := Length(P.Data);
  Driver.FirstLineNumber := P.FirstLineNum;
  Driver.LineNumber := P.NextLinesNum;
  Driver.GraphBufferType := 1;
  Driver.LineDataHex := StrToHex(P.Data);
  Result := Driver.LoadGraphics512;
end;

function TFiscalPrinterDriver.PrintGraphics3(Line1, Line2: Word): Integer;
var
  P: TPrintGraphics3;
begin
  P.FirstLine := Line1;
  P.LastLine := Line2;
  P.VScale := 1;
  P.HScale := 1;
  P.Flags := PRINTER_STATION_REC;
  Result := PrintGraphics3(P);
end;

function TFiscalPrinterDriver.PrintGraphics3(const P: TPrintGraphics3): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.FirstLineNumber := P.FirstLine;
  Driver.LastLineNumber := P.LastLine;
  Driver.VertScale := P.VScale;
  Driver.HorizScale := P.HScale;
  Result := Driver.PrintGraphics512;
end;

procedure TFiscalPrinterDriver.CheckGraphicsSize(Line: Word);
begin

end;

function TFiscalPrinterDriver.FilterTLV(Data: AnsiString): AnsiString;
var
  Tag: TTLVTag;
  Item: TTLVItem;
  Tags: TTLVTags;
  IsValid: Boolean;
begin
  Result := '';
  Tags := TTLVTags.Create;
  try
    while TTLVReader.Read(Data, Item) do
    begin
      Tag := Tags.Find(Item.ID);
      IsValid := True;
      if Tag <> nil then
      begin
        IsValid := GetFFDVersion in Tag.Versions;
      end;

      if IsValid then
        Result := Result + TTLVWriter.Write(Item);
    end;
  finally
    Tags.Free;
  end;
end;

function TFiscalPrinterDriver.FSWriteTLV(const TLVData: AnsiString): Integer;
var
  Data: AnsiString;
begin
  Result := 0;
  Data := FilterTLV(TLVData);
  if Length(Data) = 0 then Exit;

  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.TLVDataHex := StrToHex(Copy(Data, 1, 250));
  Result := Driver.FNSendTLV;
end;

function TFiscalPrinterDriver.FSSale(P: TFSSale): Integer;
begin
  P.Text := PrintItemText(P.Text);
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.CheckType := Abs(P.RecType);
  Driver.Quantity := Abs(P.Quantity);
  Driver.Price := IntToAmount(Abs(P.Price));
  Driver.Summ1 := IntToAmount(Abs(P.Amount));
  Driver.Department := Abs(P.Department);
  Driver.Tax1 := Abs(P.Tax);
  Driver.BarCode := IntToStr(P.Barcode);
  Driver.StringForPrinting := Copy(P.Text, 1, 109);
  Result := Driver.FNOperation;
end;

function TFiscalPrinterDriver.FSSale2(P: TFSSale2): Integer;
begin
  P.Text := PrintItemText(P.Text);
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.CheckType := Abs(P.RecType);
  Driver.Quantity := Abs(P.Quantity);
  Driver.Price := IntToAmount(Abs(P.Price));
  Driver.Summ1 := IntToAmount(Abs(P.Total));
  Driver.Summ2 := IntToAmount(Abs(P.TaxAmount));
  Driver.Tax1 := Abs(P.Tax);
  Driver.Department := P.Department;
  Driver.PaymentTypeSign := P.PaymentType;
  Driver.PaymentItemSign := P.PaymentItem;
  Driver.StringForPrinting := Copy(P.Text, 1, 128);
  Result := Driver.FNOperation;
end;

function TFiscalPrinterDriver.FSReadRegTag(var R: TFSReadRegTagCommand): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.TagNumber := R.TagID;
  Result := Driver.FNReadFiscalDocumentTLV;
  if Succeeded(Result) then
  begin
    R.TLV := AnsiString(Driver.TagValueStr);
  end;
end;

function TFiscalPrinterDriver.FSReadState(var R: TFSState): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.FNGetStatus;
  if Result = 0 then
  begin
    R.State := Driver.FNLifeState;
    R.Document := Driver.FNCurrentDocument;
    R.DocReceived := Driver.FNDocumentData;
    R.DayOpened := Driver.FNSessionState;
    R.WarningFlags := Driver.FNWarningFlags;
    R.Date := DateTimeToPrinterDate(Driver.ECRDate);
    R.Time := DateTimeToPrinterTime(Driver.ECRTime);
    R.Time.Sec := 0;
    R.FSNumber := Copy(Driver.SerialNumber, 1, 16);
    R.DocNumber := Driver.DocumentNumber;
  end;
end;

function TFiscalPrinterDriver.FSCancelDocument: Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.FNCancelDocument;
end;

function TFiscalPrinterDriver.FSReadStatus(var R: TFSStatus): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.FNGetFreeMemoryResource;
  if Result = 0 then
  begin
    R.DataSize := Driver.DataLength;
    R.BlockSize := Driver.FreeMemorySize;
  end;
end;

function TFiscalPrinterDriver.FSFindDocument(DocNumber: Integer;
  var R: TFSDocument): Integer;

  procedure DecodeDocType1(const Data: AnsiString; var R: TFSDocument1);
  begin
    CheckMinLength(Data, 47);
    R.Date := BinToPrinterDateTime2(Data);
    R.DocNum := BinToInt(Data, 6, 4);
    R.DocMac := BinToInt(Data, 10, 4);
    R.TaxID := TrimRight(Copy(Data, 14, 12));
    R.EcrRegNum := TrimRight(Copy(Data, 26, 20));
    R.TaxType := Ord(Data[46]);
    R.WorkMode := Ord(Data[47]);
  end;

  procedure DecodeDocType2(const Data: AnsiString; var R: TFSDocument2);
  begin
    CheckMinLength(Data, 15);
    R.Date := BinToPrinterDateTime2(Data);
    R.DocNum := BinToInt(Data, 6, 4);
    R.DocMac := BinToInt(Data, 10, 4);
    R.DayNum := BinToInt(Data, 14, 2);
  end;

  procedure DecodeDocType3(const Data: AnsiString; var R: TFSDocument3);
  begin
    CheckMinLength(Data, 19);
    R.Date := BinToPrinterDateTime2(Data);
    R.DocNum := BinToInt(Data, 6, 4);
    R.DocMac := BinToInt(Data, 10, 4);
    R.OperationType := Ord(Data[14]);
    R.Amount := BinToInt(Data, 15, 5);
  end;

  procedure DecodeDocType6(const Data: AnsiString; var R: TFSDocument6);
  begin
    CheckMinLength(Data, 45);
    R.Date := BinToPrinterDateTime2(Data);
    R.DocNum := BinToInt(Data, 6, 4);
    R.DocMac := BinToInt(Data, 10, 4);
    R.TaxID := Copy(Data, 14, 12);
    R.EcrRegNum := Copy(Data, 26, 20);
  end;

  procedure DecodeDocType11(const Data: AnsiString; var R: TFSDocument11);
  begin
    CheckMinLength(Data, 48);
    R.Date := BinToPrinterDateTime2(Data);
    R.DocNum := BinToInt(Data, 6, 4);
    R.DocMac := BinToInt(Data, 10, 4);
    R.TaxID := Copy(Data, 14, 12);
    R.EcrRegNum := Copy(Data, 26, 20);
    R.TaxType := Ord(Data[46]);
    R.WorkMode := Ord(Data[47]);
    R.ReasonCode := Ord(Data[48]);
  end;

  procedure DecodeDocType21(const Data: AnsiString; var R: TFSDocument21);
  begin
    CheckMinLength(Data, 20);
    R.Date := BinToPrinterDateTime2(Data);
    R.DocNum := BinToInt(Data, 6, 4);
    R.DocMac := BinToInt(Data, 10, 4);
    R.DocCount := BinToInt(Data, 14, 2);
    R.DocDate := BinToPrinterDateTime2(Copy(Data, 16, 5));
  end;

begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.DocumentNumber := DocNumber;
  Result := Driver.FNFindDocument;
  if Result = 0 then
  begin
    R.DocType := Driver.DocumentType;
    R.TicketReceived := Driver.OFDTicketReceived;
    R.TlvData := AnsiString(Driver.TagValueStr);
    case R.DocType of
      1: DecodeDocType1(R.TlvData, R.DocType1);
      2: DecodeDocType2(R.TlvData, R.DocType2);
      3: DecodeDocType3(R.TlvData, R.DocType3);
      4: DecodeDocType3(R.TlvData, R.DocType3);
      5: DecodeDocType2(R.TlvData, R.DocType2);
      6: DecodeDocType6(R.TlvData, R.DocType6);
      11: DecodeDocType11(R.TlvData, R.DocType11);
      21: DecodeDocType21(R.TlvData, R.DocType21);
      31: DecodeDocType3(R.TlvData, R.DocType3);
    end;
  end;
end;

function TFiscalPrinterDriver.FSReadDocMac(var DocMac: Int64): Integer;
var
  FSState: TFSState;
  FSDocument: TFSDocument;
begin
  Result := FSReadState(FSState);
  if Result <> 0 then Exit;

  Result := FSFindDocument(FSState.DocNumber, FSDocument);
  DocMac := 0;
  case FSDocument.DocType of
    1: DocMac := FSDocument.DocType1.DocMac;
    2: DocMac := FSDocument.DocType2.DocMac;
    3: DocMac := FSDocument.DocType3.DocMac;
    4: DocMac := FSDocument.DocType3.DocMac;
    5: DocMac := FSDocument.DocType2.DocMac;
    6: DocMac := FSDocument.DocType6.DocMac;
    11: DocMac := FSDocument.DocType11.DocMac;
    21: DocMac := FSDocument.DocType21.DocMac;
    31: DocMac := FSDocument.DocType3.DocMac;
  end;
end;

function TFiscalPrinterDriver.FSReadBlock(const P: TFSBlockRequest;
  var Block: AnsiString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Block := '';
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.FSStartWrite(DataSize: Word;
  var BlockSize: Byte): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  BlockSize := 0;
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.FSWriteBlock(const Block: TFSBlock): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.GetBlockSize(BlockSize: Integer): Integer;
begin
  Result := BlockSize;
  if Result = 0 then
    Result := DefDocumentBlockSize;

  if (GetDeviceMetrics.Model = 19)and(BlockSize > GetParameters.DocumentBlockSize) then
    Result := GetParameters.DocumentBlockSize;
end;

function TFiscalPrinterDriver.FSReadBlockData: AnsiString;
var
  i: Integer;
  Count: Integer;
  Block: AnsiString;
  BlockData: AnsiString;
  Status: TFSStatus;
  DataSize: Integer;
  BlockSize: Integer;
  BlockRequest: TFSBlockRequest;
begin
  Lock;
  try
    BlockData := '';
    BlockRequest.Offset := 0;
    Check(FSReadStatus(Status));
    if Status.DataSize = 0 then Exit;
    if Status.BlockSize = 0 then Exit;
    Status.BlockSize := GetBlockSize(Status.BlockSize);

    Count := (Status.DataSize + Status.BlockSize-1) div Status.BlockSize;
    DataSize := Status.DataSize;
    for i := 0 to Count-1 do
    begin
      BlockSize := Min(Status.BlockSize, DataSize);
      BlockRequest.Offset := i*Status.BlockSize;
      BlockRequest.Size := BlockSize;
      Check(FSReadBlock(BlockRequest, Block));
      BlockData := BlockData + Block;
      DataSize := DataSize - BlockSize;
    end;
    BlockData := Copy(BlockData, 1, Status.DataSize);
    Result := BlockData;
  finally
    Unlock;
  end;
end;

procedure TFiscalPrinterDriver.FSWriteBlockData(const BlockData: AnsiString);
var
  i: Integer;
  Count: Integer;
  BlockSize: Byte;
  Block: TFSBlock;
begin
  Lock;
  try
    Check(FSStartWrite(Length(BlockData), BlockSize));
    if BlockSize = 0 then
      raiseException('BlockSize = 0');

    BlockSize := GetBlockSize(BlockSize);
    Count := (Length(BlockData)+ BlockSize-1) div BlockSize;
    for i := 0 to Count-1 do
    begin
      Block.Offset := BlockSize*i;
      Block.Size := BlockSize;
      Block.Data := Copy(BlockData, BlockSize*i + 1, BlockSize);
      Check(FSWriteBlock(Block));
    end;
  finally
    Unlock;
  end;
end;

function TFiscalPrinterDriver.FSPrintCalcReport(var R: TFSCalcReport): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.FNBuildCalculationStateReport;
  if Result = 0 then
  begin
    R.DocNumber := Driver.DocumentNumber;
    R.FiscalSign := Driver.FiscalSign;
    R.OutstandDocCount := 0;
    R.OutstandDocDate := DateTimeToPrinterDate(Driver.ECRDate);
  end;
end;

function TFiscalPrinterDriver.FSReadCommStatus(
  var R: TFSCommStatus): Integer;

  function DecodeFSWriteStatus(Value: Integer): TFSWriteStatus;
  begin
    Result.IsConnected := TestBit(Value, 0);
    Result.HasMessageToSend := TestBit(Value, 1);
    Result.IsWaitForTicket := TestBit(Value, 2);
    Result.IsServerCommand := TestBit(Value, 3);
    Result.ConnParamsChanged := TestBit(Value, 4);
    Result.IsWaitForAnswer := TestBit(Value, 5);
  end;

begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.FNGetInfoExchangeStatus;
  if Result = 0 then
  begin
    R.WriteStatus := Driver.InfoExchangeStatus;
    R.FSWriteStatus := DecodeFSWriteStatus(R.WriteStatus);
    R.ReadStatus := 0;
    R.DocumentCount := Driver.DocumentCount;
    R.DocumentNumber := Driver.DocumentNumber;
    R.DocumentDate := DateTimeToPrinterDateTime(Driver.ECRDate);
  end;
end;

function TFiscalPrinterDriver.FSReadExpiration(var R: TCommandFF03): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.FNGetExpirationTime;
  if Result = 0 then
  begin
    R.ExpDate := DateTimeToPrinterDate(Driver.ECRDate);
    R.RegLeft := Driver.FreeRegistration;
    R.RegNumber := Driver.RegistrationNumber;
  end;
end;

function TFiscalPrinterDriver.FSReadFiscalResult(var R: TFSFiscalResult): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := Driver.FNGetFiscalizationResult;
  if Result = 0 then
  begin
    R.Date := DateTimeToPrinterDateTime(Driver.ECRDate);
    R.TaxID := Driver.INN;
    R.EcrRegNum := Driver.RNM;
    R.TaxType := Driver.TaxType;
    R.WorkMode := Driver.WorkMode;
    R.DocNum := Driver.DocumentNumber;
    R.DocMac := Driver.FiscalSign;
  end;
end;

function TFiscalPrinterDriver.FSReadTicket(var R: TFSTicket): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.DocumentNumber := R.Number;
  Result := Driver.FNGetOFDTicketByDocNumber;
  if Result = 0 then
  begin
    R.Data := AnsiString(Driver.TagValueStr);
    if Length(R.Data) >= 27 then
    begin
      R.Date := BinToPrinterDateTime2(R.Data);
      R.DocumentMac := Copy(R.Data, 6, 18);
      R.DocumentNum := BinToInt(R.Data, 24, 4);
    end;
  end;
end;


function TFiscalPrinterDriver.GetCapFiscalStorage: Boolean;
begin
  Result := FCapFiscalStorage;
end;

function TFiscalPrinterDriver.WriteCustomerAddress(const Value: WideString): Integer;
begin
  Result := FSWriteTag(1008, Value);
end;

function TFiscalPrinterDriver.FSWriteTag(TagID: Integer; const Data: WideString): Integer;
begin
  Result := FSWriteTLV(TagToStr(TagID, Data));
end;

function TFiscalPrinterDriver.ReadFPParameter(ParamId: Integer): WideString;
begin
  case ParamId of
    DIO_FPTR_PARAMETER_QRCODE_ENABLED:
    begin
      Result := ReadTableStr(1, 1, 41);
    end;
    DIO_FPTR_PARAMETER_OFD_ADDRESS:
    begin
      if IsMobilePrinter then
        Result := ReadTableStr(15, 1, 1)
      else
        Result := ReadTableStr(19, 1, 1);
    end;

    DIO_FPTR_PARAMETER_OFD_PORT:
    begin
      if IsMobilePrinter then
        Result := ReadTableStr(15, 1, 2)
      else
        Result := ReadTableStr(19, 1, 2);
    end;

    DIO_FPTR_PARAMETER_OFD_TIMEOUT:
    begin
      if IsMobilePrinter then
        Result := ReadTableStr(15, 1, 3)
      else
        Result := ReadTableStr(19, 1, 3);
    end;

    DIO_FPTR_PARAMETER_RNM:
    begin
      if IsMobilePrinter then
        Result := ReadTableStr(14, 1, 3)
      else
        Result := ReadTableStr(18, 1, 3);
    end;

    DIO_FPTR_PARAMETER_INN:
    begin
      if IsMobilePrinter then
        Result := ReadTableStr(14, 1, 2)
      else
        Result := ReadTableStr(18, 1, 2);
    end;
    DIO_FPTR_PARAMETER_TAXSYSTEM:
    begin
      if IsMobilePrinter then
        Result := ReadTableStr(14, 1, 5)
      else
        Result := ReadTableStr(18, 1, 5);
    end;
    DIO_FPTR_PARAMETER_WORKMODE:
    begin
      if IsMobilePrinter then
        Result := ReadTableStr(14, 1, 6)
      else
        Result := ReadTableStr(18, 1, 6);
    end;

    DIO_FPTR_PARAMETER_ENABLE_PRINT:
    begin
      Result := '0';
      if FCapEnablePrint then
      begin
        Result := ReadTableStr(17, 1, 7);
      end;
    end;
  else
    raiseExceptionFmt('%s, %d', [_('Invalid parameter ID value'), ParamId]);
  end;
end;

procedure TFiscalPrinterDriver.WriteFPParameter(ParamId: Integer;
  const Value: WideString);
begin
  case ParamId of
    DIO_FPTR_PARAMETER_QRCODE_ENABLED:
    begin
      WriteTable(1, 1, 41, Value);
    end;
    DIO_FPTR_PARAMETER_OFD_ADDRESS:
    begin
      WriteTable(19, 1, 1, Value);
    end;

    DIO_FPTR_PARAMETER_OFD_PORT:
    begin
      WriteTable(19, 1, 2, Value);
    end;

    DIO_FPTR_PARAMETER_OFD_TIMEOUT:
    begin
      WriteTable(19, 1, 3, Value);
    end;

    DIO_FPTR_PARAMETER_ENABLE_PRINT:
    begin
      if FCapEnablePrint then
      begin
        WriteTable(17, 1, 7, Value);
      end;
    end;

  else
    raiseExceptionFmt('%s, %d', [_('Invalid parameter ID value'), ParamId]);
  end;
end;


function TFiscalPrinterDriver.ReadDiscountMode: Integer;
var
  R: TPrinterTableRec;
begin
  Result := 0;
  try
    if ReadTableStructure(17, R) = 0 then
    begin
      Result := ReadTableInt(17, 1, 3);
    end;
  except
    on E: Exception do
    begin
      Result := 0;
    end;
  end;
end;

function TFiscalPrinterDriver.ReadDocPrintMode: Integer;
var
  R: TPrinterTableRec;
begin
  Result := 0;
  try
    if ReadTableStructure(17, R) = 0 then
    begin
      Result := ReadTableInt(17, 1, 7);
    end;
  except
    on E: Exception do
    begin
      Result := 0;
    end;
  end;
end;

function TFiscalPrinterDriver.GetDiscountMode: Integer;
begin
  Result := FDiscountMode;
end;

function TFiscalPrinterDriver.GetIsFiscalized: Boolean;
begin
  Result := FIsFiscalized;
end;

function TFiscalPrinterDriver.FSReadTotals(var R: TFMTotals): Integer;
begin
  FLogger.Debug('FSReadTotals');
  FillChar(R, SizeOf(R), 0);
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.FSReadCorrectionTotals(var R: TFMTotals): Integer;
begin
  FLogger.Debug('FSReadCorrectionTotals');
  FillChar(R, SizeOf(R), 0);
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.FSReadTotalsByPayType(RecType: Byte;
  var R: TFSTotalsByPayType): Integer;
begin
  FLogger.Debug(Format('FSReadTotalsByPayType(%d)', [RecType]));
  CheckParam(RecType, 1, 4, 'RecType');
  FillChar(R, SizeOf(R), 0);
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.ReadDayTotalsByReceiptType(Index: Integer): Int64;
begin
  Result := ReadCashRegister(193 + Index) +
    ReadCashRegister(197 + Index) +
    ReadCashRegister(201 + Index) +
    ReadCashRegister(205 + Index);
end;

function TFiscalPrinterDriver.ReadTotalsByReceiptType(Index: Integer): Int64;
begin
  Result :=
    ReadCashRegister(72 + Index) +
    ReadCashRegister(76 + Index) +
    ReadCashRegister(80 + Index) +
    ReadCashRegister(84 + Index);
end;

function TFiscalPrinterDriver.ReadDayTotals: TFMTotals;
begin
  Result.SaleTotal := 0;
  Result.BuyTotal := 0;
  Result.RetSale := 0;
  Result.RetBuy := 0;
  if GetIsFiscalized then
  begin
    Result.SaleTotal := ReadDayTotalsByReceiptType(0);
    Result.BuyTotal := ReadDayTotalsByReceiptType(1);
    Result.RetSale := ReadDayTotalsByReceiptType(2);
    Result.RetBuy := ReadDayTotalsByReceiptType(3);
  end else
  begin
    Result.SaleTotal := ReadDayTotalsByReceiptType(0);
    Result.BuyTotal := 0;
    Result.RetSale := 0;
    Result.RetBuy := 0;
  end;
end;

function TFiscalPrinterDriver.ReadFPTotals(Flags: Integer): TFMTotals;
begin
  Result.SaleTotal := 0;
  Result.BuyTotal := 0;
  Result.RetSale := 0;
  Result.RetBuy := 0;
  if CapFiscalStorage then
  begin
    Check(FSReadTotals(Result));
  end else
  begin
    if GetIsFiscalized then
    begin
      Check(ReadFMTotals(Flags, Result));
    end else
    begin
      Result.SaleTotal := ReadCashRegister(244);
    end;
  end;
end;

function TFiscalPrinterDriver.ReadFPDayTotals(Flags: Integer): TFMTotals;
var
  FPTotals: TFMTotals;
  DayTotals: TFMTotals;
begin
  FPTotals := ReadFPTotals(Flags);
  DayTotals := ReadDayTotals;
  Result.SaleTotal := FPTotals.SaleTotal + DayTotals.SaleTotal;
  Result.BuyTotal := FPTotals.BuyTotal + DayTotals.BuyTotal;
  Result.RetSale := FPTotals.RetSale + DayTotals.RetSale;
  Result.RetBuy := FPTotals.RetBuy + DayTotals.RetBuy;
end;

function TFiscalPrinterDriver.FSPrintCorrectionReceipt(
  var Command: TFSCorrectionReceipt): Integer;
begin
  OpenFiscalDay;
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.Summ1 := IntToAmount(Command.Total);
  Driver.CorrectionType := Command.RecType;
  Result := Driver.FNBuildCorrectionReceipt;
  if Result = 0 then
  begin
    Command.ResultCode := Result;
    Command.ReceiptNumber := Driver.ReceiptNumber;
    Command.DocumentNumber := Driver.DocumentNumber;
    Command.DocumentMac := Driver.FiscalSign;
  end;
end;

function TFiscalPrinterDriver.FSPrintCorrectionReceipt2(
  var Data: TFSCorrectionReceipt2): Integer;
begin
  OpenFiscalDay;
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.CorrectionType := Data.CorrectionType;
  Driver.PaymentTypeSign := Data.CalculationSign;
  Driver.Summ1 := IntToAmount(Data.Amount1);
  Driver.Summ2 := IntToAmount(Data.Amount2);
  Driver.Summ3 := IntToAmount(Data.Amount3);
  Driver.Summ4 := IntToAmount(Data.Amount4);
  Driver.TaxType := Data.TaxType;
  Result := Driver.FNBuildCorrectionReceipt2;
  if Result = 0 then
  begin
    Data.ResultCode := Result;
    Data.ReceiptNumber := Driver.ReceiptNumber;
    Data.DocumentNumber := Driver.DocumentNumber;
    Data.DocumentMac := Driver.FiscalSign;
  end;
end;

procedure TFiscalPrinterDriver.LoadTables(const Path: WideString);
var
  i: Integer;
  j: Integer;
  Mask: AnsiString;
  F: TSearchRec;
  DeviceName: AnsiString;
  FileName: AnsiString;
  ResultCode: Integer;
  FileNames: TTntStrings;
  Tables: TPrinterTables;
  Reader: TCsvPrinterTableFormat;
begin
  Logger.Debug('LoadTables("' + Path + '")');

  DeviceName := GetDeviceMetrics.DeviceName;
  FileNames := TTntStringList.Create;
  Reader := TCsvPrinterTableFormat.Create(nil);
  Tables := TPrinterTables.Create;
  try
    Mask := WideIncludeTrailingPathDelimiter(Path) + '*.csv';
    ResultCode := FindFirst(Mask, faAnyFile, F);
    if ResultCode = 0 then
    begin
      while ResultCode = 0 do
      begin
        FileName := ExtractFilePath(Mask) + F.FindData.cFileName;
        FileNames.Add(FileName);
        ResultCode := FindNext(F);
      end;
      FindClose(F);
    end;

    for i := 0 to FileNames.Count-1 do
    begin
      Reader.LoadFromFile(FileNames[i], Tables);
      if Tables.DeviceName = DeviceName then
      begin
        Logger.Debug('Tables file name: ' + FileNames[i]);
        Logger.Debug('Tables count = ' + IntToStr(Tables.Count));
        for j := 0 to Tables.Count - 1 do
        begin
          WriteFields(Tables[j]);
        end;
        Break;
      end;
    end;
  except
    on E: Exception do
    begin
      Logger.Error('LoadTables: ' + GetExceptionMessage(E));
    end;
  end;
  Tables.Free;
  Reader.Free;
  FileNames.Free;
end;

procedure TFiscalPrinterDriver.WriteFields(Table: TPrinterTable);
var
  i: Integer;
  Data: AnsiString;
  Field: TPrinterField;
  FieldValue: WideString;
begin
  for i := 0 to Table.Fields.Count-1 do
  begin
    Field := Table.Fields[i];
    Data := ReadTableBin(Field.Table, Field.Row, Field.Field);
    FieldValue := FieldToStr(Field.Data, Data);
    if FieldValue <> Field.Value then
    begin
      WriteTable(Field.Table, Field.Row, Field.Field, Field.Value);
    end;
  end;
end;

function TFiscalPrinterDriver.GetContext: TDriverContext;
begin
  Result := FContext;
end;

function TFiscalPrinterDriver.IsFSDocumentOpened: Boolean;
var
  FSState: TFSState;
begin
  Result := False;
  if GetCapFiscalStorage then
  begin
    Check(FSReadState(FSState));
    Result := FSState.Document <> 0;
  end;
end;

function TFiscalPrinterDriver.IsRecOpened: Boolean;
begin
  Result := (ReadPrinterStatus.Mode and $0F) = MODE_REC;
end;

function TFiscalPrinterDriver.ReadLoaderVersion(var Version: WideString): Integer;
begin
  Version := '';
  EnsureConnected;
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.ReceiptClose2(
  const P: TFSCloseReceiptParams2;
  var R: TFSCloseReceiptResult2): Integer;
begin
  if FCapCloseReceipt3 then
    Result := ReceiptClose3(P, R)
  else
    Result := ReceiptClose22(P, R);
end;

function TFiscalPrinterDriver.ReceiptClose22(
  const P: TFSCloseReceiptParams2;
  var R: TFSCloseReceiptResult2): Integer;
var
  Command: AnsiString;
  Answer: AnsiString;
  Status: TLongPrinterStatus;
const
  SInvalidDiscountValue =  'Invalid discount value, %d. Valid discount value is [0..99].';
begin
  WriteTLVItems;

  if not ((P.Discount) in [0..99]) then
    RaiseIllegalError(Format(SInvalidDiscountValue, [P.Discount]));

  FLastDocTotal := GetSubtotal;
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.Summ1 := IntToAmount(P.Payments[0]);
  Driver.Summ2 := IntToAmount(P.Payments[1]);
  Driver.Summ3 := IntToAmount(P.Payments[2]);
  Driver.Summ4 := IntToAmount(P.Payments[3]);
  Driver.DiscountOnCheck := P.Discount;
  Driver.StringForPrinting := P.Text;
  Result := Driver.FNCloseCheckEx;
  if Result = 0 then
  begin
    R.Change := AmountToInt(Driver.Change);
    R.DocNumber := Driver.DocumentNumber;
    R.MacValue := Driver.FiscalSign;
    Status := ReadLongStatus;
    R.DocDate := Status.Date;
    R.DocTime := Status.Time;

    FLastDocNumber := R.DocNumber;
    FLastDocMac := R.MacValue;
    FLastDocDate := R.DocDate;
    FLastDocTime := R.DocTime;
  end;
end;

function TFiscalPrinterDriver.ReceiptClose3(
  const P: TFSCloseReceiptParams2;
  var R: TFSCloseReceiptResult2): Integer;
var
  Command: AnsiString;
  Answer: AnsiString;
  Status: TLongPrinterStatus;
const
  SInvalidDiscountValue =  'Invalid discount value, %d. Valid discount value is [0..99].';
begin
  WriteTLVItems;

  if not ((P.Discount) in [0..99]) then
    RaiseIllegalError(Format(SInvalidDiscountValue, [P.Discount]));

  FLastDocTotal := GetSubtotal;
  EnsureConnected;
  SetDriverPassword(GetUsrPassword);
  Driver.Summ1 := IntToAmount(P.Payments[0]);
  Driver.Summ2 := IntToAmount(P.Payments[1]);
  Driver.Summ3 := IntToAmount(P.Payments[2]);
  Driver.Summ4 := IntToAmount(P.Payments[3]);
  Driver.DiscountOnCheck := P.Discount;
  Driver.StringForPrinting := P.Text;
  Result := Driver.FNCloseCheckEx;
  if Result = 0 then
  begin
    R.Change := AmountToInt(Driver.Change);
    R.DocNumber := Driver.DocumentNumber;
    R.MacValue := Driver.FiscalSign;
    Status := ReadLongStatus;
    R.DocDate := Status.Date;
    R.DocTime := Status.Time;

    FLastDocNumber := R.DocNumber;
    FLastDocMac := R.MacValue;
    FLastDocDate := R.DocDate;
    FLastDocTime := R.DocTime;
  end;
end;

function TFiscalPrinterDriver.ReadParameters2(
  var R: TPrinterParameters2): Integer;
begin
  FillChar(R, Sizeof(R), 0);
  EnsureConnected;
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.FSFiscalization(const P: TFSFiscalization;
  var R: TFDDocument): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.INN := P.TaxID;
  Driver.RNM := P.RegID;
  Driver.TaxType := P.TaxCode;
  Driver.WorkMode := P.WorkMode;
  CheckDriver(Driver.FNBeginFiscalization);
  Result := Driver.FNFiscalization;
  if Result = 0 then
  begin
    R.DocNumber := Driver.DocumentNumber;
    R.DocMac := Driver.FiscalSign;
  end;
end;

function TFiscalPrinterDriver.FSReFiscalization(const P: TFSReFiscalization;
  var R: TFDDocument): Integer;
begin
  EnsureConnected;
  SetDriverPassword(GetSysPassword);
  Driver.INN := P.TaxID;
  Driver.RNM := P.RegID;
  Driver.TaxType := P.TaxCode;
  Driver.WorkMode := P.WorkMode;
  Driver.RegistrationReasonCode := P.ReasonCode;
  Result := Driver.FNFiscalization;
  if Result = 0 then
  begin
    R.DocNumber := Driver.DocumentNumber;
    R.DocMac := Driver.FiscalSign;
  end;
end;

function TFiscalPrinterDriver.IsCapFooterFlag: Boolean;
begin
  Result := FCapFooterFlag;
end;

procedure TFiscalPrinterDriver.SetFooterFlag(Value: Boolean);
begin
  FFooterFlag := Value;
end;

function TFiscalPrinterDriver.GetOnPrinterStatus: TNotifyEvent;
begin
  Result := FOnPrinterStatus;
end;

procedure TFiscalPrinterDriver.SetOnPrinterStatus(Value: TNotifyEvent);
begin
  FOnPrinterStatus := Value;
end;

procedure TFiscalPrinterDriver.SetPrinterStatus(Value: TPrinterStatus);
begin
  if not IsEqual(FPrinterStatus, Value) then
  begin
    FPrinterStatus := Value;

    Logger.Debug(Format('Mode: $%.2x, amode: $%.2x, Flags: $%.4x',
      [FPrinterStatus.Mode, FPrinterStatus.AdvancedMode, FPrinterStatus.Flags.Value]));

    if Assigned(FOnPrinterStatus) then
      FOnPrinterStatus(Self);
  end;
end;

function TFiscalPrinterDriver.IsCapBarcode2D: Boolean;
begin
  Result := FCapBarcode2D;
end;

function TFiscalPrinterDriver.IsCapEnablePrint: Boolean;
begin
  Result := FCapEnablePrint;
end;

function TFiscalPrinterDriver.ReadFSDocument(Number: Integer): WideString;
var
  P: TFSReadDocument;
begin
  Result := '';
  P.Number := Number;
  P.Password := FSysPassword;
  Check(FSReadDocument(P));
  Result := ReadDocData;
end;

function TFiscalPrinterDriver.ReadDocData: WideString;
var
  FSDocData: TFSReadDocData;
begin
  Result := '';
  FSDocData.Password := FSysPassword;
  while FSReadDocData(FSDocData) = 0 do
  begin
    Result := Result + FSDocData.TLVData;
  end;
  Result := TLVToText(Result);
end;

procedure TFiscalPrinterDriver.PrintFSDocument(Number: Integer);
begin
  PrintText(PRINTER_STATION_REC, ReadFSDocument(Number));
end;

function TFiscalPrinterDriver.FSReadDocument(var P: TFSReadDocument): Integer;
begin
  EnsureConnected;
  SetDriverPassword(P.Password);
  Driver.DocumentNumber := P.Number;
  Result := Driver.FNRequestFiscalDocumentTLV;
  if Result = 0 then
  begin
    P.DocType := Driver.DocumentType;
    P.DocLength := Driver.DataLength;
  end;
end;

function TFiscalPrinterDriver.FSReadDocData(var P: TFSReadDocData): Integer;
begin
  EnsureConnected;
  SetDriverPassword(P.Password);
  Result := Driver.FNReadFiscalDocumentTLV;
  if Result = 0 then
  begin
    P.TLVData := AnsiString(Driver.TagValueStr);
  end;
end;

function TFiscalPrinterDriver.FSStartOpenDay: Integer;
begin
  EnsureConnected;
  SetDriverPassword(FSysPassword);
  Result := Driver.FNBeginOpenSession;
end;

procedure TFiscalPrinterDriver.EkmCheckBarcode(const Barcode: TGS1Barcode);
var
  Client: TEkmClient;
  SaleEnabled: Boolean;
begin
  Client := TEkmClient.Create;
  try
    Client.Host := Parameters.EkmServerHost;
    Client.Port := Parameters.EkmServerPort;
    Client.Timeout := Parameters.EkmServerTimeout;
    SaleEnabled := Client.ReadSaleEnabled(Barcode.GTIN, Barcode.Serial);
    if not SaleEnabled then
      raiseError(E_SALE_NOT_ENABLED, _('Ïðîäàæà òîâàðà çàïðåùåíà'));
  finally
    Client.Free;
  end;
end;

function TFiscalPrinterDriver.CheckItemCode(const Barcode: WideString): Integer;
var
  CheckItemCode: TFSCheckItemCode;
  CheckItemResult: TFSCheckItemResult;
begin
  Result := 0;
  if Barcode = '' then Exit;
  if Parameters.CheckItemCodeEnabled then
  begin
    if Result = 0 then
    begin
      CheckItemCode.ItemStatus := Parameters.NewItemStatus;
      CheckItemCode.ProcessMode := 0;
      CheckItemCode.TLVData := '';
      CheckItemCode.CMData := Barcode;

      Result := FSCheckItemCode(CheckItemCode, CheckItemResult);
      if Result = 0 then
      begin
        CheckCorrectItemCode(CheckItemResult);
      end;
    end;
  end;
end;

procedure TFiscalPrinterDriver.CheckCorrectItemCode(const P: TFSCheckItemResult);
begin

  if P.LocalCheckResult = SMFP_LOCAL_CHECK_FAILED then
    raise Exception.Create(_('Barcode is not valid'));

(*
  if (P.ProcessingCode = 0) then
  begin
    if P.SellPermission <> SMFP_SELL_PERMISSION_OK then
      raise Exception.Create(_('Item is forbidden to sold'));

    if P.ServerResult <> SMFP_SERVER_RESULT_OK then
      raise Exception.Create(getServerResultCodeText(P.ServerResult));
  end;
*)
end;

function TFiscalPrinterDriver.IsCorrectItemCode(const P: TFSCheckItemResult): Boolean;
begin
  if P.LocalCheckResult = SMFP_LOCAL_CHECK_FAILED then
  begin
    Result := False;
    Exit;
  end;
(*
  if (P.ProcessingCode = 0) then
  begin
    if P.SellPermission <> SMFP_SELL_PERMISSION_OK then
    begin
      Result := False;
      Exit;
    end;
    if P.ServerResult <> SMFP_SERVER_RESULT_OK then
    begin
      Result := False;
      Exit;
    end;
  end;
*)
  Result := True;
end;


function TFiscalPrinterDriver.SendItemBarcode(const Barcode: WideString;
  MarkType: Integer): Integer;
var
  Data: AnsiString;
begin
  Data := BarcodeTo1162Value(Barcode);
  Data := TTLVTag.Int2ValueTLV(1162, 2) + TTLVTag.Int2ValueTLV(Length(Data), 2) + Data;
  Result := FSWriteTLVOperation(Data);
end;

function GetEANCrc(const data: string): Integer;
var
  i: Integer;
  len: Integer;
  sum: Integer;
begin
	sum := 0;
	len := Length(data);
	for i:=1 to Length(data) do
	begin
		if (len mod 2) = 0 then
			sum := sum + (StrToInt(data[i])*1)
		else
			sum := sum + (StrToInt(data[i])*3);
		dec(len);
	end;
  sum := sum mod 10;
	if sum <> 0 then
		sum := 10 - sum;
  Result := sum;
end;

function CheckEANCRC(const Barcode: AnsiString): Boolean;
var
  Crc: Integer;
begin
  Result := False;
  if Length(Barcode) > 1 then
  begin
    Crc := GetEANCrc(Copy(Barcode, 1, Length(Barcode)-1));
    Result := Crc = StrToInt(Barcode[Length(Barcode)]);
  end;
end;

function TFiscalPrinterDriver.BarcodeTo1162Value(
  const Barcode: AnsiString): AnsiString;
var
  gtin: AnsiString;
  serial: AnsiString;
  Data: AnsiString;
  Tokens: TGS1Tokens;
  BarcodeType: Integer;
begin
  Data := Barcode;
  BarcodeType := KTN_UNKNOWN;
  Tokens := TGS1Tokens.Create(TGS1Token);
  try
    Tokens.DecodeGS1(Barcode);
    if Tokens.HasItem('01') and Tokens.HasItem('21') then
    begin
      BarcodeType := KTN_DM;
      gtin := Tokens.ItemByID('01').Data;
      if Length(gtin) > 24 then
        gtin := Copy(gtin, 1, 24);

      Data := IntToBinBE(StrToInt64(gtin), 6);
      serial := Tokens.ItemByID('21').Data;
      Data := Data + Serial;

      if Tokens.HasItem('8005') then
      begin
        Data := Data + Tokens.ItemByID('8005').Data;
      end;
    end else
    begin
      case Length(Barcode) of
        8:
          if IsMatch(Barcode, '\d+') and CheckEANCRC(Barcode) then
          begin
            BarcodeType := KTN_EAN8;
            Data := IntToBinBE(StrToInt64(Barcode), 6);
          end;

        10:
          if IsMatch(Barcode, '\d+') then
          begin
            BarcodeType := KTN_FUEL;
            Data := IntToBinBE(StrToInt64(Barcode), 6);
          end;

        13:
          if IsMatch(Barcode, '\d+') and CheckEANCrc(Barcode) then
          begin
            BarcodeType := KTN_EAN13;
            Data := IntToBinBE(StrToInt64(Barcode), 6);
          end;

        14:
          if IsMatch(Barcode, '\d+') then
          begin
            BarcodeType := KTN_ITF14;
            Data := IntToBinBE(StrToInt64(Barcode), 6);
          end;

        21:
          if IsMatch(Barcode, '\w{2}-\d{6}-\w{11}') then
            BarcodeType := KTN_RF;

        29:
        begin
          BarcodeType := KTN_DM;
          gtin := Copy(Barcode, 1, 14);
          Data := IntToBinBE(StrToInt64(gtin), 6);
          Data := Data + Copy(Barcode, 15, 11) + '  ';
        end;

        68:
        begin
          BarcodeType := KTN_EGAIS2;
          Data := Copy(Barcode, 9, 23);
        end;

        150:
        begin
          BarcodeType := KTN_EGAIS3;
          Data := Copy(Barcode, 1, 14);
        end;
      end;
    end;
    if BarcodeType = KTN_UNKNOWN then
      Data := Copy(Barcode, 1, 30);

  finally
    Tokens.Free;
  end;
  Result := IntToBinBE(BarcodeType, 2) + Data;
end;

function TFiscalPrinterDriver.FSWriteTLVOperation(const AData: AnsiString): Integer;
var
  Data: AnsiString;
begin
  Result := 0;
  Data := FilterTLV(AData);
  if Length(Data) = 0 then Exit;

  if Length(Data) > 249 then
    raiseException(_('TLV data length too big'));

  EnsureConnected;
  SetDriverPassword(FSysPassword);
  Driver.TLVDataHex := StrToHex(Copy(Data, 1, 249));
  Result := Driver.FNSendTLVOperation;
end;

function TFiscalPrinterDriver.FSStartCorrectionReceipt: Integer;
begin
  EnsureConnected;
  SetDriverPassword(FSysPassword);
  Result := Driver.FNBeginCorrectionReceipt;
end;

function TFiscalPrinterDriver.GetLastDocNumber: Int64;
begin
  Result := FLastDocNumber;
end;

function TFiscalPrinterDriver.GetLastDocMac: Int64;
begin
  Result := FLastDocMac;
end;

function TFiscalPrinterDriver.GetLastDocTotal: Int64;
begin
  Result := FLastDocTotal;
end;

function TFiscalPrinterDriver.GetLastDocDate: TPrinterDate;
begin
  Result := FLastDocDate;
end;

function TFiscalPrinterDriver.GetLastDocTime: TPrinterTime;
begin
  Result := FLastDocTime;
end;

function TFiscalPrinterDriver.FSReadLastDocNum2: Int64;
var
  FSState: TFSState;
begin
  Result := 0;
  if CapFiscalStorage then
  begin
    Check(FSReadState(FSState));
    Result := FSState.DocNumber;
  end;
end;

function TFiscalPrinterDriver.FSReadLastDocNum: Int64;
begin
  if FLastDocNumber = 0 then
    FLastDocNumber := FSReadLastDocNum2;
  Result := FLastDocNumber;
end;

function TFiscalPrinterDriver.FSReadLastMacValue: Int64;
begin
  if FLastDocMac = 0 then
    FLastDocMac := FSReadLastMacValue2;
  Result := FLastDocMac;
end;

function TFiscalPrinterDriver.FSReadLastMacValue2: Int64;
var
  LastMacValue: Int64;
begin
  LastMacValue := 0;
  if CapFiscalStorage then
  begin
    Check(FSReadDocMac(LastMacValue));
  end;
  Result := LastMacValue;
end;

function TFiscalPrinterDriver.FSCheckItemCode(P: TFSCheckItemCode;
  var R: TFSCheckItemResult): Integer;
begin
  P.CMData := CorrectGS1(P.CMData);
  EnsureConnected;
  SetDriverPassword(FSysPassword);
  Driver.ItemStatus := P.ItemStatus;
  Driver.BarcodeHex := StrToHex(P.CMData);
  Driver.TLVDataHex := StrToHex(P.TLVData);
  Result := Driver.FNCheckItemBarcode;
  if Result = 0 then
  begin
    R.LocalCheckResult := 0;
    R.LocalCheckError := 0;
    R.SymbolicType := Driver.MarkingType;
    R.DataLength := 0;
    R.FSResultCode := 0;
    R.ServerCheckStatus := Driver.KMServerCheckingStatus;
    R.ServerTLVData := AnsiString(Driver.TagValueStr);
  end;
end;

function TFiscalPrinterDriver.FSSyncRegisters: Integer;
begin
  EnsureConnected;
  SetDriverPassword(FSysPassword);
  Result := Driver.FNCountersSync;
end;

function TFiscalPrinterDriver.FSReadMemory(var R: TFSReadMemoryResult): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FSysPassword);
  Result := Driver.FNGetFreeMemoryResource;
  if Result = 0 then
  begin
    R.FreeDocCount := Driver.FN5YearResource;
    R.FreeMemorySizeInKB := Driver.FreeMemorySize;
    R.UsedMCTicketStorageInPercents := Driver.FNMarkingFillPercentage;
  end;
end;

function TFiscalPrinterDriver.FSWriteTLVFromBuffer: Integer;
begin
  EnsureConnected;
  SetDriverPassword(FSysPassword);
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.FSRandomData(var Data: AnsiString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FSysPassword);
  Data := '';
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.FSAuthorize(const DataToAuthorize: AnsiString): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FSysPassword);
  Result := ERROR_COMMAND_NOT_SUPPORTED;
  FResultCode := Result;
  FResultText := GetErrorText(Result);
end;

function TFiscalPrinterDriver.FSBindItemCode(P: TFSBindItemCode;
  var R: TFSBindItemCodeResult): Integer;
begin
  P.Code := CorrectGS1(P.Code);
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  Driver.BarcodeHex := StrToHex(P.Code);
  Driver.MarkingOnly := P.IsAccounted;
  Result := Driver.FNBindMarkingItem;
  if Result = 0 then
  begin
    R.ItemCode := Driver.MarkingType;
    R.CodeType := Driver.MarkingTypeEx;
    R.CheckResult.LocalCheckResult := 0;
    R.CheckResult.LocalCheckError := 0;
    R.CheckResult.SymbolicType := Driver.MarkingType;
    R.CheckResult.DataLength := 0;
    R.CheckResult.FSResultCode := 0;
    R.CheckResult.ServerCheckStatus := Driver.KMServerCheckingStatus;
    R.CheckResult.ServerTLVData := AnsiString(Driver.TagValueStr);
  end;
end;

function TFiscalPrinterDriver.FSReadTicketStatus(var R: TFSTicketStatus): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  Result := Driver.FNGetKMServerExchangeStatus;
  if Result = 0 then
  begin
    R.TicketStatus := Driver.KMServerCheckingStatus;
    R.TicketCount := Driver.DocumentCount;
    R.TicketNumber := Driver.LastDocumentNumber;
    R.TicketDate := DateTimeToPrinterDateTime(Driver.ECRDate);
    R.TicketStorageUsageInPercents := Driver.FNMarkingFillPercentage;
  end;
end;

function TFiscalPrinterDriver.FSAcceptItemCode(Action: Integer): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  if Action = 2 then
    Result := Driver.FNMarkingClearBuffer
  else
    Result := Driver.FNAcceptMarkingCode;
end;

function TFiscalPrinterDriver.FSClearMCCheckResults: Integer;
begin
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  Result := Driver.FNMarkingClearBuffer;
end;

function TFiscalPrinterDriver.FSReadMarkStatus(var R: TFSMarkStatus): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  Result := Driver.FNGetMarkingCodeWorkStatus;
  if Result = 0 then
  begin
    R.MarkCheckStatus := Driver.KMServerCheckingStatus;
    R.TicketStatus := 0;
    R.CommandFlags := 0;
    R.MCSavedCount := Driver.MCCheckResultSavedCount;
    R.MCTicketCount := Driver.DocumentCount;
    R.TicketStorageStatus := Driver.FNMarkingFillPercentage;
    R.TicketCount := Driver.DocumentCount;
  end;
end;

function TFiscalPrinterDriver.FSStartReadTickets(var R: TFSTicketParams): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  Result := Driver.FNGetKMServerExchangeStatus;
  if Result = 0 then
  begin
    R.TicketCount := Driver.DocumentCount;
    R.FirstTicketNumber := Driver.LastDocumentNumber;
    R.FirstTicketSize := Driver.DataLength;
  end;
end;

function TFiscalPrinterDriver.FSReadNextTicket(var R: TFSTicketData): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  Result := Driver.FNReadNotificationBlock;
  if Result = 0 then
  begin
    R.Number := Driver.DocumentNumber;
    R.Size := Driver.DataLength;
    R.Offset := 0;
    R.Data := AnsiString(Driver.DataBlock);
  end;
end;

function TFiscalPrinterDriver.FSConfirmTicket(const P: TFSTicketNumber): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  Driver.DocumentNumber := P.Number;
  Driver.FiscalSign := P.Crc16;
  Result := Driver.FNConfirmNotificationRead;
end;

function TFiscalPrinterDriver.FSReadDeviceInfo(var R: string): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  Result := Driver.FNGetImplementation;
  if Result = 0 then
  begin
    R := Driver.FNImplementation;
  end;
end;

function TFiscalPrinterDriver.FSReadDocSize(var R: TFSDocSize): Integer;
begin
  EnsureConnected;
  SetDriverPassword(FUsrPassword);
  Result := Driver.FNGetFreeMemoryResource;
  if Result = 0 then
  begin
    R.DocSize := Driver.FreeMemorySize;
    R.TicketSize := Driver.DataLength;
  end;
end;

procedure TFiscalPrinterDriver.STLVBegin(TagID: Integer);
begin
  FSTLVTag.Items.Clear;
  FSTLVTag.Tag := TagId;
  FSTLVStarted := True;
end;

procedure TFiscalPrinterDriver.STLVAddTag(TagID: Integer;
  TagValue: string);
begin
  if not FSTLVStarted then
    raise Exception.Create('Call STLVBegin first');
  FSTLVTag.Items.Add(TagID).Data := TagToStr(TagID, TagValue);
end;

function TFiscalPrinterDriver.STLVGetHex: string;
begin
  Result := StrToHexText(FSTLVTag.RawData);
end;

procedure TFiscalPrinterDriver.STLVWrite;
begin
  Check(FSWriteTLV(FSTLVTag.RawData));
end;

procedure TFiscalPrinterDriver.STLVWriteOp;
begin
  Check(FSWriteTLVOperation(FSTLVTag.RawData));
end;

procedure TFiscalPrinterDriver.WriteTLVItems;
var
  i: Integer;
begin
  for i := 0 to FTLVItems.Count-1 do
  begin
    FSWriteTLV(FTLVItems[i]);
  end;
  FTLVItems.Clear;
end;

procedure TFiscalPrinterDriver.FSWriteTLV2(const TLVData: AnsiString);
begin
  FTLVItems.Add(TLVData);
end;

procedure TFiscalPrinterDriver.ResetPrinter;
begin
  FTLVItems.Clear;
  if FDocPrintMode = 1 then
    FDocPrintMode := 0;
end;

function TFiscalPrinterDriver.GetDocPrintMode: Integer;
begin
  Result := FDocPrintMode;
end;

procedure TFiscalPrinterDriver.CorrectDate;
var
  PDate: TPrinterDate;
  TimeDiffInSecs: Int64;
  PrinterDate: TDateTime;
  Status: TLongPrinterStatus;
begin
  Logger.Debug('CorrectDate');
  if Parameters.ValidTimeDiffInSecs > 0 then
  begin
    Status := ReadLongStatus;
    PrinterDate := PrinterDateToDate(Status.Date) + PrinterTimeToTime(Status.Time);
    TimeDiffInSecs := SecondsBetween(Now, PrinterDate);
    if TimeDiffInSecs > Parameters.ValidTimeDiffInSecs then
    begin
      PDate := GetCurrentPrinterDate;
      WriteDate(PDate);
      ConfirmDate(PDate);
      SetTime(GetCurrentPrinterTime);
    end;
  end;
end;

procedure TFiscalPrinterDriver.CheckPrinterStatus;

  function GetStateErrorMessage(const Mode: Integer): WideString;
  begin
    Result := Tnt_WideFormat('%s: %d, %s', [_('Íåâîçìîæíî èçìåíèòü ñîñòîÿíèå'), Mode, GetModeText(Mode)]);
  end;

const
  MaxStateCount = 3;
var
  Mode: Byte;
  TickCount: Integer;
  PrinterStatus: TPrinterStatus;
  PrinterDate: TPrinterDate;
  WaitDateCount: Integer;
  ModeTechCount: Integer;
  ModeTestCount: Integer;
  ModePointCount: Integer;
  ModeDumpCount: Integer;
  LockedCount: Integer;
begin
  WaitDateCount := 0;
  ModeTechCount := 0;
  ModeTestCount := 0;
  ModePointCount := 0;
  ModeDumpCount := 0;
  LockedCount := 0;
  TickCount := GetTickCount;
  repeat
    if Integer(GetTickCount) > (TickCount + Parameters.StatusTimeout*1000) then
      raiseException(SStatusWaitTimeout);

    PrinterStatus := ReadPrinterStatus;
    Mode := PrinterStatus.Mode and $0F;

    case Mode of
      // Dump mode
      MODE_DUMPMODE:
      begin
        ReadDocData;
        //Device.StopDump;

        Inc(ModeDumpCount);
        if ModeDumpCount >= MaxStateCount then
          raiseOposException(OPOS_E_FAILURE, GetStateErrorMessage(Mode));
      end;

      // Fiscal day opened, 24 hours is not over
      MODE_24NOTOVER: Exit;

      // Fiscal day opened, 24 hours is over
      MODE_24OVER: Exit;

      // Fiscal day closed
      MODE_CLOSED: Exit;

      // ECR blocked by incorrect tax offecer password
      MODE_LOCKED:
      begin
        if StartDump(1) = 0 then
          StopDump;
        Inc(LockedCount);
        if LockedCount >= MaxStateCount then
          raiseOposException(OPOS_E_FAILURE, GetStateErrorMessage(Mode));
      end;

      // Waiting for date confirm
      MODE_WAITDATE:
      begin
        ConfirmDate(ReadLongStatus.Date);
        Inc(WaitDateCount);
        if WaitDateCount >= MaxStateCount then
          raiseOposException(OPOS_E_FAILURE, GetStateErrorMessage(Mode));
      end;

      // Permission to cange decimal point position
      MODE_POINTPOS:
      begin
        SetPointPosition(PRINTER_POINT_POSITION_2);
        Inc(ModePointCount);
        if ModePointCount >= MaxStateCount then
          raiseOposException(OPOS_E_FAILURE, GetStateErrorMessage(Mode));
      end;

      // Opened document
      MODE_REC: Exit;

      // Tech reset permission
      MODE_TECH:
      begin
        ResetFiscalMemory;
        PrinterDate := GetCurrentPrinterDate;
        WriteDate(PrinterDate);
        ConfirmDate(PrinterDate);
        SetTime(GetCurrentPrinterTime);

        Inc(ModeTechCount);
        if ModeTechCount >= MaxStateCount then
          raiseOposException(OPOS_E_FAILURE, GetStateErrorMessage(Mode));
      end;
      // Test run
      MODE_TEST:
      begin
        StopTest;
        Inc(ModeTestCount);
        if ModeTestCount >= MaxStateCount then
          raiseOposException(OPOS_E_FAILURE, GetStateErrorMessage(Mode));
      end;
      // Full fiscal report printing
      MODE_FULLREPORT:
      begin
        Sleep(Parameters.StatusInterval);
      end;
      // EJ report printing
      MODE_EKLZREPORT:
      begin
        Sleep(Parameters.StatusInterval);
      end;
      // Opened fiscal slip
      MODE_SLP: Exit;
      // Slip printing
      MODE_SLPPRINT: Exit;
      // Fiscal slip is ready
      MODE_SLPREADY: Exit;
    else
      Break;
    end;
  until False;
end;


procedure TFiscalPrinterDriver.SetCapFiscalStorage(const Value: Boolean);
begin
  FCapFiscalStorage := Value;
end;

function TFiscalPrinterDriver.GetTrailerHeight: Integer;
var
  Font: TFontInfo;
begin
  Font := GetFont(Parameters.TrailerFont);
  Result := GetModel.NumTrailerLines * Font.CharHeight;
end;

function TFiscalPrinterDriver.GetFont(Font: Integer): TFontInfo;
begin
  if not ValidFont(Font) then
    Font := 1;
  Result := FFontInfo[Font];
end;

function TFiscalPrinterDriver.GetHeaderHeight: Integer;
var
  Font: TFontInfo;
begin
  if FHeadToCutterDistanse <> 0 then
  begin
    Result := FHeadToCutterDistanse;
  end else
  begin
    Font := GetFont(Parameters.HeaderFont);
    Result := GetModel.NumHeaderLines * Font.CharHeight;
  end;
end;

function TFiscalPrinterDriver.GetTaxInfoList: TTaxInfoList;
begin
  Result := FTaxInfo;
end;

procedure TFiscalPrinterDriver.WriteTaxRate(Tax, Rate: Integer);
begin
  if (Tax < 1)or(Tax > Length(FTaxInfo)) then
    raise Exception.CreateFmt('Invalid tax number, %d', [Tax]);

  WriteTableInt(PRINTER_TABLE_TAX, Tax, 1, Rate);
end;


end.
