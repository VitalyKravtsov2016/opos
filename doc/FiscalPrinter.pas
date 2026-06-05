{$R-}
unit FiscalPrinter;

interface

uses
  // VCL
  Windows, SysUtils, ComObj, ActiveX, Graphics, Classes, Registry, SyncObjs,
  ExtCtrls, Dialogs, Math, JSON, DateUtils, StrUtils,
  System.Generics.Collections,
  // ID
  idTCPClient, idGlobal,
  // This
  DrvFRLib_TLB, LogicDevice, untUtil, BinUtils, DriverError, VersionInfo,
  fmuAbout, PrinterDriver, LocalDriver, TCPDriver, PrinterCommand, StringUtils,
  Code128, DispItem, DriverTypes, PrinterTypes, DevicePorts, PacketDriver,
  PluginAPI, Mutex, fmuProgress, untLogger, PrinterModels, DrvFR_Messages,
  LogFile, PrinterDocument, XmlDriverParams, TextEncoding, Translation,
  FileUtils, TCPSocketDriver, PPPDriver, FptrTypes, ModelParam, DefaultModels,
  DebugUtils, XmlPrinterModel, ConnectionParams, PrinterProtocolInterface,
  DriverState, DriverPlugin, QREncode, NotifyThread, OFDClient, FormatTLV,
  PrinterTable, CsvPrinterTableFormat, TLVTag, TLVParser, NETCONLib_TLB,
  untRecDB, CommandExecutorInterface, PrinterDevice, TagNodes, LangUtils,
  GS1Barcode, DFU, DeviceSearch, FWUpdateDFU, FirmwareUpdateParams, AESUtils,
  untAuthKey, FWUpdater, FWUpdateXModem, ShtrihDeviceMonitor, FNReport,
  FNDocument, sbp.Client, sbp.Types, VMCScanner, VMCScanner.Types,
  VMCScanner.SearchDevice, IO.SerialPort, QrDisplay.IkodDisplay, QrDisplay,
  BarcodeHelper, zint, dkkt_json, TspiotServer;

type
  TFieldStruct = record
    TableNumber: Integer;
    FieldNumber: Integer;
    FieldName: string;
    FieldSize: Integer;
    MinValue: UInt64;
    MaxValue: UInt64;
    FieldType: Boolean;
  end;

  { TFiscalPrinter }

  TFiscalPrinter = class(TDriverState)
  public
    Serial: string; // !!!
  private
    FDisconnectTimer: TTimer;
    FDisconnectTimerLastCommandTime: Cardinal;
    FTagValueVLN: AnsiString;
    // FMarkChecker: TMarkChecker;
    FICSEnabled: Boolean;
    FICSPollPeriod: Integer;
    FSTLVTag: TTagNode;
    FSTLVStarted: Boolean;
    FRandomSequence: AnsiString;
    FReadTicket: Boolean;
    FCachedFieldStruct: TList<TFieldStruct>;
    procedure AddCachedFieldStruct(ATableNumber, AFieldNumber: Integer; AFieldName: string; AFieldSize: Integer; AMinValue: Int64; AMaxValue: Int64; AFieldType: Boolean);
    function FindCachedField(ATableNumber, AFieldNumber: Integer; var AFieldStruct: TFieldStruct): Boolean;
    // FDeviceMonitor: TShtrihDeviceMonitor;
    function ReadFiscalDocumentTLV: AnsiString;
    function FNInterruptFiscalDocumentReading: Integer;
    function ReadFNDocument(ADocumentNumber: Integer; ReadTicket: Boolean): TFNDocumentRec;
    function ReadFNTicket(ADocumentNumber: Integer): TFNTicketRec;
    function ReadFiscalizationParams: AnsiString;

    procedure OnDeviceArrived(Sender: TObject; DeviceType: Integer; const Description: AnsiString);
    procedure OnDeviceRemoved(Sender: TObject; DeviceType: Integer; const Description: AnsiString);
    function GetPlugins: TDriverPlugins;
    function GetICSEnabled: Boolean;
    function GetICSPollPeriod: Integer;
    procedure SetICSEnabled(const Value: Boolean);
    procedure SetICSPollPeriod(const Value: Integer);
    function GetFiscalSignAsString: WideString;
    function IsRepeatableCommand(ACode: Integer): Boolean;
    function GetPrintStringWidth: Integer;
    function ReadDefaultFont: Integer;
    function LoadBarcodeData(BlockType: Integer; const Data: AnsiString): Integer;
    // function CheckItemMarking: Integer;
    // function SendItemMarking: Integer;
    function GetUpdateFirmwareStatus: Integer;
    function GetUpdateFirmwareStatusMessage: WideString;
    function GetFWUpdateEnabled: Boolean;
    function GetFWUpdatePollInterval: Integer;
    procedure SetFWUpdateEnabled(const Value: Boolean);
    procedure SetFWUpdatePollInterval(const Value: Integer);
    function GetFWUpdateServerURL: WideString;
    procedure SetFWUpdateServerURL(const Value: WideString);
    procedure SetTagValueVLN(const Value: AnsiString);
    function StrToInteger64(const Value: AnsiString; const AName: string): Int64;
    function GetTagValueBinHex: AnsiString;
    procedure SetTagValueBinHex(const Value: AnsiString);

  private
    FFNReport: TFNReport;
    FDefaultFont: Integer;
    FWUpdateParams: TFirmwareUpdateParams;
    FPrintStringWidth: Integer;
    FCommandSender: ICommandExecutor;
    FPrinterDevice: TPrinterDevice;
    FLastOFDDocNumber: Integer;
    FTags: TTLVTags;
    FDB: TRecDB;
    FLogger: TLogger;
    FMutex: TMutex;
    FLock: TCriticalSection;
    FDrvFR49: IDrvFR49;
    FProps: TDispItems;
    FMethods: TDispItems;
    FDevices: TLogicDevices; // Логические устройства
    FDriver: IPrinterDriver; // Драйвер
    FPlugins: TDriverPlugins;
    // FJournal: TPrinterJournal;          // Фискальный регистратор
    FCommands: TPrinterCommands;
    FModels: TPrinterModels;
    // FPaymentDrv: IPaymentDrv;
    // FPaymDrv: TPaymentDrv;
    // FDocument: TPrinterDocument;
    FPrinterModel: TPrinterModel;
    FTranslation: TTranslation;
    FConnectionParams: TConnectionParams;
    FBarcodeRender: TBarcodeRender;
    FState: TDriverState;
    FECRInputOld: AnsiString;
    FECROutputOld: AnsiString;
    FOFDStopFlag: Boolean;
    FOFDStarted: Boolean;
    FOFDThread: TNotifyThread;
    FEODEnabled: Boolean;
    FECode: Integer;
    FFwupdater: TFWUpdater;
    FUpdaterDFU: TFWUpdateDFU;
    FUpdaterXModem: TFwupdateXModem;
    FSaveOFDExchangeSuspended: Boolean;
    FSbpAuthorize: TSbpAuthorize;
    FPaymanClient: TPaymanClient;
    procedure OnDFUUpdateFinished(Sender: TObject);
    procedure OFDDelay(Timeout: Integer);
    // procedure ICSDelay(Timeout: Integer);
    function GetTCPPort: Integer;
    procedure SetTCPPort(const Value: Integer);
    function GetIPAddress: AnsiString;
    procedure SetIPAddress(const Value: AnsiString);
    function GetUseIPAddress: Boolean;
    procedure SetUseIPAddress(const Value: Boolean);
    function GetBufferingType: Integer;
    procedure SetBufferingType(const Value: Integer);
    function GetTimeout: Integer;
    procedure SetTimeout(const Value: Integer);
    procedure SetProtocolType(const Value: Integer);
    procedure SetBaudRate(const Value: Integer);
    function Translate(const Text: WideString): WideString;
    function GetTCPConnectionTimeout: Integer;
    procedure SetTCPConnectionTimeout(const Value: Integer);
    function GetSyncTimeout: Integer;
    procedure SetSyncTimeout(const Value: Integer);
    property Plugins: TDriverPlugins read GetPlugins;

  private
    function GetBarcodeHex: AnsiString;
    function GetBarcodeInt: AnsiString;
    procedure SetBarcodeHex(const Value: AnsiString);
    procedure OFDThreadProc(Sender: TObject);
    function PrintText(const AText: WideString; AWrap: Boolean = True): Integer;
    procedure EnablePlugins(AEnabled: Boolean);
    function GetPlainTransferMode: Integer;
    procedure SetPlainTransferMode(const Value: Integer);
    function GetTLSMode: Integer;
    procedure SetTLSMode(const Value: Integer);
    function GetTaxValue7: AnsiString;
    function GetTaxValue8: AnsiString;
    function GetTaxValue9: AnsiString;
    function GetTaxValue10: AnsiString;
    function GetEncryptPassword(var Password: AnsiString): Integer;
  public
    function MCScannerGetLastMCStatus: Integer;
    function MCScannerKeyAgreement: Integer;
    function MCScannerReadDeviceStatus: Integer;
    function MCScannerReadKey: Integer;
    function MCScannerSendMCStatus: Integer;
    function MCScannerSearchDevice: Integer;
    function FNBeginReadNotifications: Integer;
    function FNReadNotificationBlock: Integer;
    function FNConfirmNotificationRead: Integer;
    function FNReadFiscalBarcode: Integer;
    function WriteRegistryParam: Integer;
    function ReadRegistryParam: Integer;
    function PayManCancel: Integer;
    function PayManCreateCashRegisterCode: Integer;
    function PayManCreatePayData: Integer;
    function PayManGetPayStatus: Integer;
    function PayManRefund: Integer;
    function PayManCreatePayDataByCode: Integer;
    function PayManSetParam: Integer;
    function PayManReadParam: Integer;
    procedure PayManAuthorize;
    function ReadUIN: string;
    function ReadFontHash: Integer;
    function ResetFont: Integer;
    function FNGetImplementation: Integer;
    function FNGetOSUSupportStatus: Integer;
    function FNGetDocumentSize: Integer;
    function PluginsUpdateSettings: Integer;
    function RebootKKT: Integer;
    function GetSysAdminPassword: AnsiString;
    procedure Lock;
    procedure Unlock;

    function GetTLVDataHex: AnsiString;
    procedure SetTLVDataHex(const Value: AnsiString);
    function GetTagAsTLV: Integer;
    function ReadOFDData: AnsiString;
    procedure WriteOFDData(const Data: AnsiString);
    procedure OFDStartPoll;
    procedure OFDStopPoll;
    procedure WriteLogStart;
    procedure SetPosControlReceiptSeparator(const Value: AnsiString);
    procedure Check(Code: Integer);
    function GetMutex: TMutex;
    // function GetPaymentDrv: IPaymentDrv;
    function Get2DBarcodeAlignment: Byte;
    function GetBarcodeRender: TBarcodeRender;
    function GetPosControlReceiptSeparator: AnsiString;
    function GetLineData(Image: TImage; Index: Integer): AnsiString;
    function GetLineData512(Image: TImage; Index: Integer; BufType: Integer = 0; CutLine: Boolean = False): AnsiString;

    function DoLoadImage(const FileName: AnsiString): Integer;
    function LoadGraphics(Image: TImage;
      { Progress: TfmProgress; } ALineNumber: Integer): Integer;
    function LoadBlockGraphics(Image: TImage;
      { Progress: TfmProgress; } ALineNumber: Integer): Integer;
    function LoadBlockGraphics512(Image: TImage;
      { Progress: TfmProgress; } ALineNumber: Integer): Integer;
    function GetBlockData512(Image: TImage; BufType: Integer; FirstLine, LinesCount: Integer; var IsEnd: Boolean; var RealLinesCount: Integer): AnsiString;

    function IntLoadBlockData(const Data: TBlockData): Integer;
    function IntPrint2DBarcode(const Data: T2DBarcode): Integer;
    function LoadBarcodeGraph: Integer;
    function GetZintBarcodetype(AGraphic: Boolean): TZintSymbology;
    function MaxImageWidth: Integer;
    function GetLogMaxFileCount: Integer;
    function GetLogMaxFileSize: Integer;
    procedure SetLogMaxFileCount(const Value: Integer);
    procedure SetLogMaxFileSize(const Value: Integer);
    function DecodeString(const Data: AnsiString): AnsiString;
    function EncodeString(const Data: AnsiString): AnsiString;
    function DeviceToStr(const Text: AnsiString): WideString;
    function StrToDevice(const Text: WideString): WideString;
    procedure WriteLogParameters;
    function GetModelNames: WideString;
    function GetModelsCount: Integer;
    procedure LoadModelParams;
    function IntToINN(Value: Int64): AnsiString;
    function GetUCodePageText: WideString;
    function GetModelParamCount: Integer;
    function BinToAmount(const Data: AnsiString; Index, Count: Integer): Currency;
    function AmountToBin(Value: Currency; Length: Integer): AnsiString;
    function Get_LDProtocolType: Integer;
    procedure Set_LDProtocolType(const Value: Integer);
    function GetAdjustRITimeout: Boolean;
    procedure SetAdjustRITimeout(const Value: Boolean);
    function GetDoNotSendENQ: Boolean;
    procedure SetDoNotSendENQ(const Value: Boolean);
    function GetReconnectPort: Boolean;
    procedure SetReconnectPort(const Value: Boolean);
    function Get_ComputerName: AnsiString;
    function Get_ComNumber: Integer;
    procedure Set_ComNumber(const Value: Integer);
  public
    function PrintBCText(APrintW, APrintGW, ACharW, ABarW: Integer): Integer;
    function GetPrinterModel: TPrinterModel;
    function GetLogger: TLogger;
    function GetDriver: IPrinterDriver;
    function DecodeOutput(const ATxData: AnsiString; const BinOutput: AnsiString): Integer;
    procedure WriteLogData(ResultCode: Integer; const ATxData, AOutput: AnsiString);
    function GetNakCount: Integer;
    procedure SetNakCount(const Value: Integer);
    function GetMaxAnsCount: Integer;
    function GetMaxCmdCount: Integer;
    function GetMaxENQCount: Integer;
    function GetCommandRetryCount: Integer;
    procedure SetCommandRetryCount(const Value: Integer);
    procedure SetMaxAnsCount(const Value: Integer);
    procedure SetMaxCmdCount(const Value: Integer);
    procedure SetMaxENQCount(const Value: Integer);
    function Get_LogOn: Boolean;
    function GetDocArg: AnsiString;
    function GetDocArgEx: AnsiString;
    function Get_LineData2: AnsiString;
    function Get_ComLogFile: AnsiString;
    function Get_LDIPAddress: AnsiString;
    function Get_LDTCPPort: Integer;
    function GetRegSlipDocEx: AnsiString;
    function GetCloseCheckEx: AnsiString;
    function GetServerVersion: AnsiString;
    function GetLastKPKTimeStr: AnsiString;
    function GetLastKPKDateStr: AnsiString;
    function Get_LastKPKDate: TDateTime;
    function Get_LDComputerName: AnsiString;
    function Get_LastKPKTime: TDateTime;
    function GetDiscountChargeEx: AnsiString;
    function GetComLogOnlyErrors: Boolean;
    function Get_ServerConnected: Boolean;
    function Get_LDUseIPAddress: Boolean;
    function Get_LDSysAdminPassword: Integer;
    function Get_ValueOfFieldInteger: Integer;
    function ValueOfFieldInteger64: Int64;
    function Get_IBMSessionDateTime: TDateTime;
    procedure Set_ValueOfFieldInteger(Value: Integer);
    function Get_LDName: WideString;
    function Get_LDCount: Integer;
    function Get_LDIndex: Integer;
    function Get_LDNumber: Integer;
    function Get_LDTimeout: Integer;
    function Get_LDBaudRate: Integer;
    function Get_LDComNumber: Integer;
    function Get_LDConnectionType: Integer;
    function Get_FirstSessionDate: TDateTime;
    procedure Set_LogOn(Value: Boolean);
    procedure Set_LDIndex(Value: Integer);
    procedure Set_LDNumber(Value: Integer);
    procedure Set_LDTCPPort(Value: Integer);
    procedure Set_LDTimeout(Value: Integer);
    procedure Set_LDBaudRate(Value: Integer);
    procedure Set_LDName(const Value: WideString);
    procedure Set_LDComNumber(Value: Integer);
    procedure Set_LineData2(const Value: AnsiString);
    procedure SetComLogOnlyErrors(Value: Boolean);
    procedure Set_ComLogFile(const Value: AnsiString);
    procedure Set_LDConnectionType(Value: Integer);
    procedure Set_ComputerName(const Value: AnsiString);
    procedure Set_LDComputerName(const Value: AnsiString);
    procedure Set_LDIPAddress(const Value: AnsiString);
    procedure Set_LDUseIPAddress(Value: Boolean);
    procedure Set_LDSysAdminPassword(Value: Integer);
    procedure Set_FirstSessionDate(Value: TDateTime);
    function Get_LDEscapeIP: AnsiString;
    function Get_LDEscapePort: Integer;
    function Get_LDEscapeTimeout: Integer;
    procedure Set_LDEscapeIP(const Value: AnsiString);
    procedure Set_LDEscapePort(Value: Integer);
    procedure Set_LDEscapeTimeout(Value: Integer);
    function Get_CharLineLength: Integer;

    procedure Set_LD1CUserPassword(Value: Integer);
    function Get_LD1CUserPassword: Integer;
    procedure Set_LD1CAdminPassword(Value: Integer);
    function Get_LD1CAdminPassword: Integer;
    function Get_LD1CIsFiscalCheck: Boolean;
    procedure Set_LD1CIsFiscalCheck(Value: Boolean);
    function Get_LD1CIsReturnCheck: Boolean;
    procedure Set_LD1CIsReturnCheck(Value: Boolean);
    function Get_LD1CIsOpenedCheck: Boolean;
    procedure Set_LD1CIsOpenedCheck(Value: Boolean);
    function Get_LD1CTax: T1CTax;
    procedure Set_LD1CTax(Value: T1CTax);
    function Get_LD1CCloseSession: Boolean;
    procedure Set_LD1CCloseSession(Value: Boolean);
    procedure Set_LD1CNonFiscalCheckNumber(Value: Integer);
    function Get_LD1CNonFiscalCheckNumber: Integer;
    procedure Set_LD1CSerialNumber(const Value: AnsiString);
    function Get_LD1CSerialNumber: AnsiString;
    procedure Set_LD1CLineLength(Value: Integer);
    function Get_LD1CLineLength: Integer;
    procedure Set_LD1CTaxProgrammed(Value: Boolean);
    function Get_LD1CTaxProgrammed: Boolean;
    procedure Set_LD1CPayNames(Value: T1CPayNames);
    function Get_LD1CPayNames: T1CPayNames;
    procedure Set_LD1CPayProgrammed(Value: Boolean);
    function Get_LD1CPayProgrammed: Boolean;
    procedure Set_LD1CCapOpenCheck(Value: Boolean);
    function Get_LD1CCapOpenCheck: Boolean;
    procedure Set_LD1CCapSetShortECRStatus(Value: Boolean);
    function Get_LD1CCapGetShortECRStatus: Boolean;
    procedure Set_LD1CPrintLogo(Value: Boolean);
    function Get_LD1CPrintLogo: Boolean;
    procedure Set_LD1CLogoSize(Value: Integer);
    function Get_LD1CLogoSize: Integer;

    procedure Set_LDTaxPassword(Value: Integer);
    function Get_LDTaxPassword: Integer;
    function GetDevices: TLogicDevices;
    property Devices: TLogicDevices read GetDevices;
    function GetEnteredTaxPassword: Integer;
    procedure SetEnteredTaxPassword(Value: Integer);

    function GetCharLineLength: Integer;
    function GetErrorCode: Integer;
    procedure UpdatePassword;
    procedure SetECRMode(Value: Byte);
    procedure SetFMFlags(Value: Byte);
    procedure SetFMFlagsEx(Value: Byte);
    procedure SetECRFlags(Value: Word);
    procedure Decode01(const Data: AnsiString);
    procedure Decode02(const Data: AnsiString);
    procedure Decode04(const Data: AnsiString);
    procedure Decode05(const Data: AnsiString);
    procedure Decode0D(const Data: AnsiString);
    procedure Decode0F(const Data: AnsiString);
    procedure Decode10(const Data: AnsiString);
    procedure Decode11(const Data: AnsiString);
    procedure Decode15(const Data: AnsiString);
    procedure Decode15_CashCore(const Data: AnsiString);
    procedure Decode18(const Data: AnsiString);
    procedure Decode1A(const Data: AnsiString);
    procedure Decode1B(const Data: AnsiString);
    procedure DecodeFF1A(const Data: AnsiString);
    procedure Decode1D(const Data: AnsiString);
    procedure Decode1F(const Data: AnsiString);
    procedure Decode1F_CashCore(const Data: AnsiString);
    procedure Decode28(const Data: AnsiString);
    procedure Decode2D(const Data: AnsiString);
    procedure Decode2E(const Data: AnsiString);
    procedure Decode50(const Data: AnsiString);
    procedure Decode4B(const Data: AnsiString);
    procedure Decode6A(const Data: AnsiString);
    procedure Decode6B(const Data: AnsiString);
    procedure DecodeFE(const Data: AnsiString);
    procedure DecodeFF01(const Data: AnsiString);
    procedure DecodeFF02(const Data: AnsiString);
    procedure DecodeFF03(const Data: AnsiString);
    procedure DecodeFF04(const Data: AnsiString);
    procedure DecodeFF06(const Data: AnsiString);
    procedure DecodeFF09(const Data: AnsiString);
    procedure DecodeFF09_11(const Data: AnsiString);
    procedure DecodeFF0A(const Data: AnsiString);
    procedure DecodeFF0B(const Data: AnsiString);
    procedure DecodeFF0E(const Data: AnsiString);
    procedure DecodeFF30(const Data: AnsiString);
    procedure DecodeFF31(const Data: AnsiString);
    procedure DecodeFF32(const Data: AnsiString);
    procedure DecodeFF34(const Data: AnsiString);
    procedure DecodeFF38(const Data: AnsiString);
    procedure DecodeFF3E(const Data: AnsiString);
    procedure DecodeFF36(const Data: AnsiString);
    procedure DecodeFF39(const Data: AnsiString);
    procedure DecodeFF3A(const Data: AnsiString);
    procedure DecodeFF3B(const Data: AnsiString);
    procedure DecodeFF3C(const Data: AnsiString);
    procedure DecodeFF3F(const Data: AnsiString);
    procedure DecodeFF40(const Data: AnsiString);
    procedure DecodeFF43(const Data: AnsiString);
    procedure DecodeFF45(const Data: AnsiString);
    procedure DecodeFF4A(const Data: AnsiString);
    procedure DecodeFF4C(const Data: AnsiString);
    procedure DecodeFF51(const Data: AnsiString);
    procedure DecodeFF52(const Data: AnsiString);
    procedure DecodeFF53(const Data: AnsiString);
    procedure DecodeFF61(const Data: AnsiString);
    procedure DecodeFF63(const Data: AnsiString);
    procedure DecodeFF65(const Data: AnsiString);
    procedure DecodeFF67(const Data: AnsiString);
    procedure DecodeFF68(const Data: AnsiString);
    procedure DecodeFF69(const Data: AnsiString);
    procedure DecodeFF70(const Data: AnsiString);
    procedure DecodeFF71(const Data: AnsiString);
    procedure DecodeFF72(const Data: AnsiString);
    procedure DecodeFF74(const Data: AnsiString);
    procedure DecodeFF75(const Data: AnsiString);
    procedure DecodeFF76(const Data: AnsiString);
    procedure DecodeFFF0(const Data: AnsiString);
    procedure DecodeFFF1(const Data: AnsiString);

    procedure DecodeDocType1(const Data: AnsiString);
    procedure DecodeDocType2(const Data: AnsiString);
    procedure DecodeDocType3(const Data: AnsiString);
    procedure DecodeDocType6(const Data: AnsiString);
    procedure DecodeDocType11(const Data: AnsiString);
    procedure DecodeDocType11_11(const Data: AnsiString);
    procedure DecodeDocType21(const Data: AnsiString);
    procedure DecodeDataTime(const Data: AnsiString);
    function GetTransferByte: AnsiString;
    procedure SetTransferByte(const Value: AnsiString);
    function GetLogCommands: Boolean;
    procedure SetLogCommands(const Value: Boolean);
    function GetLogMethods: Boolean;
    procedure SetLogMethods(const Value: Boolean);
    function GetLogFileMaxSize: DWORD;
    procedure SetLogFileMaxSize(const Value: DWORD);
    function GetLineDataHex: AnsiString;
    procedure SetLineDataHex(const Value: AnsiString);
    procedure Decode4F(const Data: AnsiString);
    procedure Decode26(const Data: AnsiString);
    procedure Decode62(const Data: AnsiString);
    procedure Decode63(const Data: AnsiString);
    procedure Decode64(const Data: AnsiString);
    procedure Decode65(const Data: AnsiString);
    procedure Decode66(const Data: AnsiString);
    procedure Decode69(const Data: AnsiString);
    procedure Decode70(const Data: AnsiString);
    procedure Decode85(const Data: AnsiString);
    procedure Decode89(const Data: AnsiString);
    procedure DecodeAB(const Data: AnsiString);
    procedure DecodeAD(const Data: AnsiString);
    procedure DecodeAD_SKNO(const Data: AnsiString);
    procedure DecodeAE_SKNO(const Data: AnsiString);
    procedure DecodeAE(const Data: AnsiString);
    procedure DecodeB1(const Data: AnsiString);
    procedure DecodeB3(const Data: AnsiString);
    procedure DecodeB4(const Data: AnsiString);
    procedure DecodeBD(const Data: AnsiString);
    procedure DecodeBD_SKNO(const Data: AnsiString);
    procedure DecodeCC(const Data: AnsiString);
    procedure DecodeCD(const Data: AnsiString);
    procedure DecodeD0(const Data: AnsiString);
    procedure DecodeD1(const Data: AnsiString);
    procedure DecodeD2(const Data: AnsiString);
    procedure DecodeE5(const Data: AnsiString);
    procedure DecodeE6(const Data: AnsiString);
    procedure DecodeEA(const Data: AnsiString);
    procedure DecodeEB(const Data: AnsiString);
    procedure DecodeED(const Data: AnsiString);
    procedure DecodeEC(const Data: AnsiString);
    procedure DecodeEF(const Data: AnsiString);
    procedure DecodeF0(const Data: AnsiString);
    procedure DecodeF7(const Data: AnsiString);
    procedure DecodeF7_1(const Data: AnsiString);
    procedure DecodeF7_16(const Data: AnsiString);
    procedure DecodeF9(const Data: AnsiString);
    procedure DecodeFC(const Data: AnsiString);
    procedure DecodeFD(const Data: AnsiString);
    procedure Decode00(const Data: AnsiString);
    procedure DecodeD4(const Data: AnsiString);
    procedure DecodeD5(const Data: AnsiString);
    procedure DecodeD6(const Data: AnsiString);
    procedure DecodeD7(const Data: AnsiString);
    procedure DecodeD8(const Data: AnsiString);
    procedure DecodeD9(const Data: AnsiString);
    procedure DecodeDA(const Data: AnsiString);

    function GetPollDescription: AnsiString;
    function GetSlipStringIntervals: AnsiString;
    procedure SetSlipStringIntervals(const Value: AnsiString);
    function GetSerialNumber: Int64;
    function GetRunningPeriod: Byte;
    function ReadFieldStruct: Integer;
    procedure SetModel(Value: TDeviceModel);
    function GetPortLocked: Boolean;
    // function GetJournal: TPrinterJournal;
    function GetJournalText: AnsiString;
    function GetJournalRowCount: Integer;
    procedure DecodeC8(const Data: AnsiString);
    procedure DecodeC9(const Data: AnsiString);
    procedure DecodeDB(const Data: AnsiString);
    function CheckIntervalValue: Integer;
    function CheckIntervalNumber: Integer;
    function WaitForAdvancedMode: Integer;
    function GetCapGetShortECRStatus: Boolean;
    function GetCapOpenCheck: Boolean;
    function PayMobile(Intf: IUnknown): Integer;
    function Get_CashControlHost: AnsiString;
    function Get_CashControlPort: AnsiString;
    function Get_CashControlUseTCP: Boolean;
    function Get_CashControlEnabled: Boolean;
    procedure Set_CashControlUseTCP(Value: Boolean);
    procedure Set_CashControlEnabled(Value: Boolean);
    procedure Set_CashControlHost(const Value: AnsiString);
    procedure Set_CashControlPort(const Value: AnsiString);
    function GetProtocol: TCashControlProtocol;
    procedure SetProtocol(const Value: TCashControlProtocol);
    function GetccHeaderLineCount: Integer;
    function GetccUseTextAsWareName: Boolean;
    function GetccWareNameLineNumber: Integer;
    procedure SetccHeaderLineCount(const Value: Integer);
    procedure SetccUseTextAsWareName(const Value: Boolean);
    procedure SetccWareNameLineNumber(const Value: Integer);
    function GetBarcodeTypes: AnsiString;
    function GetBarcodeAlignments: AnsiString;
    function GetBarcodeAlignment: TBarcodeAlignment;
    function GetBarcodeType: Integer;
    function GetBarWidth: Integer;
    procedure SetBarcodeAlignment(const Value: TBarcodeAlignment);
    procedure SetBarcodeType(const Value: Integer);
    procedure SetBarWidth(const Value: Integer);
    function LoadCommandParams: Integer;
    function GetModelParamNumber: Integer;

    property TagValueVLN: AnsiString read FTagValueVLN write SetTagValueVLN;
    // property Journal: TPrinterJournal read GetJournal;
    // property PaymentDrv: IPaymentDrv read GetPaymentDrv;
    procedure SendPluginMessage(PluginMessage: Integer; PluginParams: AnsiString);
    function SendCommand(const Data: AnsiString): Integer;
    function SimpleSendCommand(const Data: AnsiString): Integer;
    procedure GlobalLock;
    procedure GlobalUnlock;
    function GetINNAsStr: AnsiString;
    function GetINNAsInteger: Integer;
    function GetINNAsInt64: Int64;
    function GetRNMAsInt64: Int64;
    function GetSerialNumberAsInt64: Int64;
    function GetSerialNumberBCD: AnsiString;
    function GetSerialNumberAsInteger: Integer;
    function GetHasCashControlLicense: Boolean;
    function GetCommands: TPrinterCommands;
    function GetModels: TPrinterModels;
    procedure SetConnected(const Value: Boolean);
    function GetConnected: Boolean;
    function GetBanknoteType: Integer;
    function ReadPrintUserRequisite(var AValue: Integer): Integer;
    procedure LogIBMStatusBytes(AShort: Boolean);
  protected
    FCashControlINN: AnsiString;
    function GetCashControlEnabledLicense: Boolean;
    procedure OpenPort;
    function HasDriver: Boolean;
    procedure BeforeCommand(Code: Integer);
    procedure AfterCommand(Code: Integer);
    function CreateDriver: IPrinterDriver;

    procedure DecodeAnswer(CmdCode: Word; const Data: AnsiString);
    function GetINN: AnsiString;
    function GetKKTRegistrationNumber: AnsiString;
    function GetKKTRegistrationNumberAsStr: AnsiString;
    function GetLicense: AnsiString;
    function GetBaudRate: Integer;
    function GetRowNumber: Integer;
    function GetFieldValue: AnsiString;
    function GetDeviceCode: Integer;
    function GetProtocolType: Integer;
    procedure SetDefParams;
    procedure DriverConnect;
    function GetTableNumber: Integer;
    function GetFieldNumber: Integer;
    function GetFlagsFR: Word; virtual;
    function GetRegisterNumber: Integer;
    function GetRegisterNumberEx: Integer;
    function GetWareCode: Integer;
    function GetWareCodeStr: AnsiString;
    function GetCheckingType: Integer;
    function GetCARegisterNumber: Integer;
    procedure LoadRegParams(Reg: TRegistry);
    procedure SaveRegParams(Reg: TRegistry);
    function InvalidParam(const ParamName: WideString): Integer;
    function GetStr(const S: WideString; MinLen, DataLen: Integer): WideString;
    function FormatStrZero(const S: WideString; MinLen: Integer): WideString;
    function GetStringForPrinting(DataLen: Integer): WideString;
    function GetPrintString: WideString;
    function GetPrintBarcodeText: Integer;
    function GetExciseCode: Integer;
    function SendCmd(var Command: TCommandRec): Integer; virtual;
    function OFDNeedCancel: Boolean;
    function GetOPSystem: Integer;
    function GetOPTransactionType: Integer;
    function GetOPBarcodeType: Integer;
    function GetOPTransactionStatus: Integer;
    function GetOPRequisiteNumber: Integer;
    function DoPrintString: Integer;
    procedure SetFWUpdater(AMethod: Integer);
    procedure OnDisconnectTimer(Sender: TObject);
  public
    ModelIndex: Integer;
    ParameterNumber: Integer;
    ParameterValue: WideString;

    constructor Create(ADrvFR49: IDrvFR49); virtual;
    destructor Destroy; override;
    procedure SendCmd2(var Command: TCommandRec);
    procedure ChangeConnected(AConnected: Boolean);
    function GetCmdTimeout(Code: Word): Integer;
    function ReadErrorDescription: Integer;
    function ReadModelParam: Integer;
    function ReadModelParamDescription: Integer;
    function GetStatus: Integer;
    function CashControlOpen: Integer;
    function CashControlClose: Integer;
    function CashControlLoadParams: Integer;
    function ResetECR: Integer;
    function ReadFFDVersion: Integer;
    function NeedToChangeToFFD12: Boolean;
    procedure ChangeToFFD12;
    procedure CheckForSendedDocuments;
    function ReadTableInt(ATable, ARow, AField: Integer): Integer;
    function ReadTableStr(ANumber: Integer; ARow: Integer; AField: Integer): string;
    procedure WriteTableInt(ATableNumber: Integer; ARow: Integer; AField: Integer; AValue: Integer);
    procedure WriteTableStr(ATableNumber: Integer; ARow: Integer; AField: Integer; const AValue: string);
    function CorrectTableNumber(ANumber: Integer): Integer;
    procedure Feed(ALineCount: Integer);
    function OpenSession: Integer;
    function GetInterval: Integer;
    function SetInterval: Integer;
    function ShowPayParams: Integer;
    function ShowAdditionalParams: Integer;
    function WaitForPrinting: Integer;
    function WaitForCheckClose: Integer;
    function ReprintSlipDocument: Integer;
    function Sale2(Intf: IUnknown): Integer;
    function Sale2ByWare_CashCore: Integer;
    property CapGetShortECRStatus: Boolean read GetCapGetShortECRStatus;
    property CapOpenCheck: Boolean read GetCapOpenCheck;
    function PrintCliche: Integer;
    function CardPayProperties: Integer;
    function PrintZReportInBuffer: Integer;
    function PrintZReportFromBuffer: Integer;
    function OutputReceipt: Integer;
    function FindDevice: Integer;
    function JournalInit: Integer;
    function JournalClear: Integer;
    function JournalGetRow: Integer;
    function ClearPrintBuffer: Integer;
    function ReadPrintBufferLine: Integer;
    function ReadPrintBufferLineNumber: Integer;
    function ReadReportBufferLine: Integer;
    function ClearReportBuffer: Integer;
    function FinishDocument: Integer;
    function PrintTrailer: Integer;
    function PrintBarcodeLine: Integer;
    function PrintBarcodeGraph: Integer;
    function MethodSupported: WordBool;
    function PropertySupported: WordBool;
    procedure UpdateAddinLists(Dispatch: IDispatch);
    function GetTapeType: Byte;
    function IsBug0001: Boolean;
    function LoadParams(ALoadDevices: Boolean = True): Integer;
    function ReadParams: Integer;
    function SaveState: Integer;
    function RestoreState: Integer;
    function DeviceCodeDescription: AnsiString;
    function GetEKLZCode1Status: Integer;
    function GetEKLZCode2Status: Integer;
    function ReadWriteFM: Integer;
    function PrintHeader: Integer;
    function CloseCheckWithResult: Integer;
    function AboutBox: Integer;
    function PresenterKeep: Integer;
    function PresenterPush: Integer;
    function OpenScreen: Integer;
    function CloseScreen: Integer;
    function SetSCPassword: Integer;
    function LockPortTimeout: Integer;
    function GetIBMStatus: Integer;
    function GetShortIBMStatus: Integer;
    procedure ClosePort;
    function LockPort: Integer;
    function UnlockPort: Integer;
    function AdminUnlockPort: Integer;
    function AdminUnlockPorts: Integer;
    procedure DeviceToParams(Device: TLogicDevice);
    function SaveParams(ASaveDevices: Boolean = True): Integer;
    procedure SaveDevices;
    function DoLockPortTimeout: Integer;
    function NotSupported: Integer;
    function GetPrice: AnsiString;
    function GetTax1: Integer;
    function GetTax2: Integer;
    function GetTax3: Integer;
    function GetTax4: Integer;
    function GetDiscountValue: AnsiString;
    function GetChargeValue: AnsiString;
    function GetTaxValue: AnsiString;
    function GetTaxValue1: AnsiString;
    function GetTaxValue2: AnsiString;
    function GetTaxValue3: AnsiString;
    function GetTaxValue4: AnsiString;
    function GetTaxValue5: AnsiString;
    function GetTaxValue6: AnsiString;

    function GetTaxValue_: AnsiString;
    function GetTaxValue1_: AnsiString;
    function GetTaxValue2_: AnsiString;
    function GetTaxValue3_: AnsiString;
    function GetTaxValue4_: AnsiString;
    function GetTaxValue5_: AnsiString;
    function GetTaxValue6_: AnsiString;
    function GetSumm1_: AnsiString;

    function GetSumm1: AnsiString;
    function GetSumm2: AnsiString;
    function GetSumm3: AnsiString;
    function GetSumm4: AnsiString;
    function GetSumm5: AnsiString;
    function GetSumm6: AnsiString;
    function GetSumm7: AnsiString;
    function GetSumm8: AnsiString;
    function GetSumm9: AnsiString;
    function GetSumm10: AnsiString;
    function GetSumm11: AnsiString;
    function GetSumm12: AnsiString;
    function GetSumm13: AnsiString;
    function GetSumm14: AnsiString;
    function GetSumm15: AnsiString;
    function GetSumm16: AnsiString;
    function GetSumm1RB: AnsiString;
    function GetSumm2RB: AnsiString;
    function GetSumm3RB: AnsiString;
    function GetSumm4RB: AnsiString;
    function GetCustomerCode: Byte;
    function GetPermitActivizatonCode: Integer;
    function GetFontType: Integer;
    function GetSlipWidth: Integer;
    function GetSlipLength: Integer;
    function GetStringNumber: Integer;
    function GetPrintingAlignment: Integer;
    function GetDepartment: Integer;
    function GetReportType: Integer;
    function GetLineNumber: Integer;
    function CommandCount: Integer;
    function GetCheckType: Integer;
    function GetDrawerNumber: Integer;
    function GetDiscountOnCheck: AnsiString;
    function GetLastSessionNumber: Integer;
    function GetFirstSessionNumber: Integer;
    function GetOperationBlockFirstString: Integer;
    function ValidKPKNumber: Boolean;
    function StoreParams: Integer;
    procedure RestoreParams;
    function GetQuantity: AnsiString;
    function GetQuantity6: AnsiString;
    procedure InitializeProps;
    function CheckStatus: Integer;
    function SaveCommandParams: Integer;
    function GetCommandParams: Integer;
    function SetCommandParams: Integer;
    function SetAllCommandsParams: Integer;
    function SetDefCommandsParams: Integer;
    procedure LoadDevices;
    procedure LoadDrvParams;
    procedure SaveDrvParams;
    function SessionGetEcrStatus: Integer;
    function ClearResult: Integer;
    function ServerDisconnect: Integer; virtual;
    function Send(const Data: AnsiString): Integer;
    function DoSend(const Data: AnsiString): Integer;
    function HandleException(E: Exception): Integer;
    function AddLD: Integer;
    function Buy: Integer;
    function BuyByWare_CashCore: Integer;
    function BuyEx: Integer;
    function CancelCheck: Integer;
    function CashIncome: Integer;
    function CashOutcome: Integer;
    function Charge: Integer;
    function CheckSubTotal: Integer;
    function CloseCheck: Integer;
    function CloseCheckWithKPK: Integer;
    function Connect: Integer;
    function WaitConnection: Integer;
    function ContinuePrint: Integer;
    function Correction: Integer;
    function DeleteLD: Integer;
    function Discount: Integer;
    function DozeOilCheck: Integer;
    function Draw: Integer;
    function DrawScale: Integer;
    function LoadGraphics512: Integer;
    function PrintGraphics512: Integer;
    function EKLZDepartmentReportInDatesRange: Integer;
    function EKLZDepartmentReportInSessionsRange: Integer;
    function EKLZJournalOnSessionNumber: Integer;
    function EKLZSessionReportInDatesRange: Integer;
    function EKLZSessionReportInSessionsRange: Integer;
    function ExchangeBytes: Integer;
    function FeedDocument: Integer;
    function Fiscalization: Integer;
    function FiscalReportForDatesRange: Integer;
    function FiscalReportForSessionRange: Integer;
    function GetActiveLD: Integer;
    function EnumLD: Integer;
    function GetCountLD: Integer;
    function GetFiscalizationParameters: Integer;
    function GetFMRecordsSum: Integer;
    function GetLastFMRecordDate: Integer;
    function GetLiterSumCounter: Integer;
    function GetParamLD: Integer;
    function GetRangeDatesAndSessions: Integer;
    function GetRKStatus: Integer;
    function GetTableStruct: Integer;
    function InitFM: Integer;
    function InterruptFullReport: Integer;
    function InterruptTest: Integer;
    function LaunchRK: Integer;
    function LoadLineData: Integer;
    function OilSale: Integer;
    function OpenCheck: Integer;
    function OpenDrawer: Integer;
    function PrintBarCode: Integer;
    function PrintBarcodeUsingPrinter: Integer;
    function PrintDepartmentReport: Integer;
    function PrintOperationReg: Integer;
    function PrintReportWithCleaning: Integer;
    function PrintReportWithoutCleaning: Integer;
    function PrintCashierReport: Integer;
    function PrintHourlyReport: Integer;
    function PrintWareReport: Integer;
    function UpdateWare: Integer;
    function ReadWare: Integer;
    function RemoveWare: Integer;
    function CheckFM: Integer;
    function ReadEKLZDocumentOnKPK: Integer;
    function ReadEKLZSessionTotal: Integer;
    function RepeatDocument: Integer;
    function ResetAllTRK: Integer;
    function ResetRK: Integer;
    function ResetSummary: Integer;
    function ReturnBuy: Integer;
    function ReturnBuyByWare_CashCore: Integer;
    function ReturnBuyEx: Integer;
    function ReturnSale: Integer;
    function ReturnSaleByWare_CashCore: Integer;
    function ReturnSaleEx: Integer;
    function SaleEx(Intf: IUnknown): Integer;
    function ExcisableOperation: Integer;
    function SetActiveLD: Integer;
    function Sale(Intf: IUnknown): Integer;
    function SetDozeInMilliliters: Integer;
    function SetDozeInMoney: Integer;
    function SetParamLD: Integer;
    function SetRKParameters: Integer;
    function SetSerialNumber: Integer;
    function ResetSerialNumber: Integer;
    function StopEKLZDocumentPrinting: Integer;
    function StopRK: Integer;
    function Storno: Integer;
    function StornoByWare_CashCore: Integer;
    function StornoEx: Integer;
    function StornoCharge: Integer;
    function StornoDiscount: Integer;
    function SummOilCheck: Integer;
    function SysAdminCancelCheck: Integer;
    function ECRAdvancedModeDescription: WideString;
    function ECRModeDescription: WideString;
    function Get_LastSessionDate: TDateTime;
    procedure Set_LastSessionDate(Value: TDateTime);
    function Get_NameCashReg: WideString;
    function Get_NameCashRegEx: WideString;
    function Get_NameOperationReg: WideString;
    function Get_TimeStr: AnsiString;
    procedure Set_TimeStr(const Value: AnsiString);
    function Get_TypeOfLastEntryFM: Boolean;
    function PrintStringWithFont: Integer;
    function PrintStringWithFont_CashCore: Integer;
    function EKLZActivizationResult: Integer;
    function EKLZActivization: Integer;
    function CloseEKLZArchive: Integer;
    function GetEKLZSerialNumber: Integer;
    function EKLZInterrupt: Integer;
    function GetEKLZCode1Report: Integer;
    function GetEKLZCode2Report: Integer;
    function GetEKLZCode3Report: Integer;
    function TestEKLZArchiveIntegrity: Integer;
    function GetEKLZVersion: Integer;
    function InitEKLZArchive: Integer;
    function GetEKLZData: Integer;
    function GetEKLZJournal: Integer;
    function GetEKLZDocument: Integer;
    function GetEKLZDepartmentReportInDatesRange: Integer;
    function GetEKLZDepartmentReportInSessionsRange: Integer;
    function GetEKLZSessionReportInDatesRange: Integer;
    function GetEKLZSessionReportInSessionsRange: Integer;
    function GetEKLZSessionTotal: Integer;
    function GetEKLZActivizationResult: Integer;
    function SetEKLZResultCode: Integer;
    function OpenFiscalSlipDocument: Integer;
    function OpenStandardFiscalSlipDocument: Integer;
    function RegistrationOnSlipDocument: Integer;
    function StandardRegistrationOnSlipDocument: Integer;
    function ChargeOnSlipDocument: Integer;
    function StandardChargeOnSlipDocument: Integer;
    function CloseCheckOnSlipDocument: Integer;
    function StandardCloseCheckOnSlipDocument: Integer;
    function ConfigureSlipDocument: Integer;
    function ConfigureStandardSlipDocument: Integer;
    function FillSlipDocumentWithUnfiscalInfo: Integer;
    function ClearSlipDocumentBufferString: Integer;
    function ClearSlipDocumentBuffer: Integer;
    function PrintSlipDocument: Integer;
    function DiscountOnSlipDocument: Integer;
    function StandardDiscountOnSlipDocument: Integer;
    function EjectSlipDocument: Integer;
    function LoadLineDataEx: Integer;
    function DrawEx: Integer;
    function ConfigureGeneralSlipDocument: Integer;
    function WideLoadLineData: Integer;
    function PrintTaxReport: Integer;
    function PrintOperationalTaxReport: Integer;
    function Connect2: Integer;
    function GetECRPrinterStatus: Integer;
    function DoConnect: Integer; virtual;
    function CheckConnection: Integer;
    function ServerConnect: Integer;
    function ServerCheckKey: Integer;
    function GetFontMetrics: Integer;
    function GetFreeLDNumber: Integer;
    function ReadTable2: Integer;
    function GetTimeoutsUsing: Integer;
    procedure SetTimeoutsUsing(Value: Integer);
    procedure DrvOpenCheck; virtual;
    procedure DrvCloseCheck; virtual;
    function GetUModelValue: Integer; virtual;
    procedure GetExDeviceMetrics;
    function GetQuantityFactor: Integer; virtual;
    function Beep: Integer;
    function ConfirmDate: Integer;
    function CutCheck: Integer;
    function DampRequest: Integer;
    function Disconnect: Integer; virtual;
    function FiscalizationWithLongRNM: Integer;
    function GetCashReg: Integer;
    function GetCashRegEx: Integer;
    function GetWareBaseCashRegs: Integer;
    function GetData: Integer;
    function GetDeviceMetrics: Integer;
    function GetECRStatus: Integer;
    function GetExchangeParam: Integer;
    function GetFieldStruct: Integer;
    function GetLongSerialNumberAndLongRNM: Integer;
    function GetModel: TDeviceModel; virtual;
    function GetOperationReg: Integer;
    function GetRNM: Int64;
    function GetRNMBin: AnsiString;
    function GetINNBCD: AnsiString;
    function GetRNMBCD: AnsiString;
    function GetShortECRStatus: Integer;
    function GetSummFactor: Integer; virtual;
    function InitTable: Integer;
    function InterruptDataStream: Integer;
    function PrintDocumentTitle: Integer;
    function PrintString: Integer;
    function PrintString_CashCore: Integer;
    function PrintStringWithWrap: Integer;
    function PrintWideString: Integer;
    function PrintWideString_CashCore: Integer;
    function ReadLicense: Integer;
    function ReadTable: Integer;
    function ResetSettings: Integer;
    function SetDate: Integer;
    function SetExchangeParam: Integer;
    function SetLongSerialNumber: Integer;
    function WriteRNMTj: Integer;
    function ReadRNMTj: Integer;
    function SetPointPosition: Integer;
    function SetTime: Integer;
    function Test: Integer;
    function WriteLicense: Integer;
    function WriteTable: Integer;
    function WriteTable2: Integer;
    function PrintLine: Integer;
    function GetPortNames: AnsiString;
    function LoadImage: Integer;
    function OpenNonfiscalDocument: Integer;
    function CloseNonfiscalDocument: Integer;
    function PrintAttribute: Integer;
    function ReadModelParamValue: Integer;
    function LoadCashControlParams: Integer;
    function GetCashAcceptorStatus: Integer;
    function GetCashAcceptorRegisters: Integer;
    function CashAcceptorReport: Integer;
    function ReadBanknoteCount: Integer;
    function ReadEKLZActivizationParams: Integer;
    function GetShortReportInDatesRange: Integer;
    function GetShortReportInSessionRange: Integer;
    function ReadLastReceipt: Integer;
    function ReadLastReceiptLine: Integer;
    function ReadLastReceiptMac: Integer;
    function MasterPayClearBuffer: Integer;
    function MasterPayAddTextBlock: Integer;
    function MasterPayCreateMac: Integer;
    function BeginDocument: Integer;
    function EndDocument: Integer;
    procedure CreatePaymentDrv;
    function LoadBlockData: Integer;
    function Print2DBarcode: Integer;
    function LoadAndPrint2DBarcode: Integer;
    function GetSaveSettingsType: Integer;
    procedure SetSaveSettingsType(Value: Integer);
    function ReadModemParameter: Integer;
    function WriteModemParameter: Integer;
    function InitEEPROM: Integer;
    function ChangeProtocol: Integer;
    function GetECRParams: Integer;
    function JournalOperation: Integer;
    function GetMFPCode3Status: Integer;
    function MFPActivization: Integer;
    function MFPCloseArchive: Integer;
    function MFPGetPermitActivizationCode: Integer;
    function MFPGetCustomerCode: Integer;
    function MFPPrepareActivization: Integer;
    function MFPSetCustomerCode: Integer;
    function MFPSetPermitActivizationCode: Integer;
    function MFPGetPrepareActivizationResult: Integer;
    function CloseCheckEx: Integer;
    function GetCloudCashDeskParams: Integer;
    // Команды работы с ФН
    function FNGetStatus: Integer;
    function FNGetSerial: Integer;
    function FNGetExpirationTime: Integer;
    function FNGetVersion: Integer;
    function FNBeginFiscalization: Integer;
    function FNFiscalization: Integer;
    function FNResetState: Integer;
    function FNCancelDocument: Integer;
    function FNGetFiscalizationResult: Integer;
    function FNGetFiscalizationResult2: Integer;
    function FNFindDocument: Integer;
    function FNOpenSession: Integer;
    function FNSendTLV: Integer;
    function FNDiscountOperation: Integer;
    function FNDiscountTaxOperation: Integer;
    function FNStorno: Integer;
    function FNGetBufferData: Integer;
    function FNReadBufferDataBlock: Integer;
    function FNStartWriteBufferData: Integer;
    function FNWriteBufferDataBlock: Integer;
    function FNBeginReadArchive: Integer;
    function FNReadArchiveItem: Integer;
    function FNSaveArchive: Integer;
    function OFDExchange: Integer;
    function ICSReset: Integer;
    procedure DoICSReset;
    function OFDSendData(const Data: AnsiString; const AServer: AnsiString; APort: Integer): AnsiString;
    function FNBeginCalculationStateReport: Integer;
    function FNBeginCloseFiscalMode: Integer;
    function FNBeginCloseSession: Integer;
    function FNBeginCorrectionReceipt: Integer;
    function FNBeginOpenSession: Integer;
    function FNBeginRegistrationReport: Integer;
    function FNBuildCalculationStateReport: Integer;
    function FNBuildCorrectionReceipt: Integer;
    function FNBuildCorrectionReceipt2: Integer;
    function FNBuildRegistrationReport: Integer;
    function FNCloseFiscalMode: Integer;
    function FNCloseSession: Integer;
    function FNGetCurrentSessionParams: Integer;
    function FNGetInfoExchangeStatus: Integer;
    function FNGetOFDTicketByDocNumber: Integer;
    function FNGetUnconfirmedDocCount: Integer;
    function FNReadFiscalDocumentTLV: Integer;
    function FNRequestFiscalDocumentTLV: Integer;
    function FNBuildReregistrationReport: Integer;
    function FNCloseCheckEx: Integer;
    function FNSendCustomerEmail: Integer;
    function FNSendSenderEmail: Integer;
    function Ping: Integer;
    function FNOpenCheckCorrection: Integer;
    function FNCountersSync: Integer;
    function FNGetFreeMemoryResource: Integer;
    function SetDFUMode: Integer;
    function UpdateFirmware: Integer;
    function CancelFirmwareUpdate: Integer;
    function ReadRandomSequence: Integer;
    function Authorization(const AuthData: AnsiString): Integer;
    function SendAuth(const Data: AnsiString): Integer;
    function ResetAuthKey: Integer;
    function RewriteAuthKey: Integer;
    function WriteAuthKey: Integer;
    function GetAuthKey: AnsiString;
    function SaveAuthKey: Integer;
    function DeleteAuthKey: Integer;
    // РБ
    function Annulment: Integer;
    function AnnulmentRB: Integer;
    function SafeOpenSession: Integer;
    // Роснефть
    function FNDiscountChargeRN: Integer;
    function FNSendAutomatNumber(const ANumber: WideString): Integer;
    function FNPrintOperatorConfirm: Integer;
    function FNGetFiscalizationResultByNumber: Integer;
    //
    function ImportTables: Integer;
    function ExportTables: Integer;
    function DoExportTables: Integer;
    function DoImportTables: Integer;
    function WriteFields(Table: TPrinterTable): Integer;
    function FNSendTag: Integer;
    function FNSendTagOperation: Integer;
    function FNCustomSendTag(AOperation: Boolean): Integer;
    function FNSendItemCodeData: Integer;
    function FNSendItemBarcode: Integer;
    function FNCheckItemBarcodeCrpt: Integer;
    function FNCheckItemBarcode: Integer;
    function FNCheckItemBarcode2: Integer;
    function FNOperationMdlp: Integer;
    function FNCloseCheckMdlp: Integer;
    function ReadSerialNumber: Integer;
    function FNGetTagDescription: Integer;
    function FNPrintDocument: Integer;
    function FNGetDocumentAsString: Integer;
    function FNOperation: Integer;
    function FNOperationSendAdditionalTags: Integer;
    function FNSendTLVOperation: Integer;
    function FNGetNonClearableSumm: Integer;
    function FNGetNonClearableSummEx: Integer;
    function DBFindDocument: Integer;
    function DBPrintDocument: Integer;
    function GetKKTLicenseByNumber: Integer;
    function ReadKKTLicenses: Integer;
    function WriteKKTLicense: Integer;
    function CloseCheckBel: Integer;
    function GetSumm1AsString: WideString;
    function GetSumm2AsString: WideString;
    function GetSumm3AsString: WideString;
    function GetSumm4AsString: WideString;
    function DBGetNextDocument: Integer;
    function DBPrintNextDocument: Integer;
    function DBQueryDocumentsInSession: Integer;
    function GetDBFileName(var FName: WideString): Integer;
    procedure DBRecToDriver(ARec: TReceiptDBRec);
    function OnlinePay: Integer;
    function OPGetLastRequisite: Integer;
    function OPGetLastStatus: Integer;
    function GenerateMonoToken: Integer;
    //
    function FNAddTag: Integer;
    function FNBeginSTLVTag: Integer;
    function FNSendSTLVTag: Integer;
    function FNSendSTLVTagOperation: Integer;
    function FNSendSTLVTagCustom(AOperation: Boolean): Integer;
    //
    function LoadFontSymbol: Integer;
    function LoadFont: Integer;
    function LoadBlockOnSDCard: Integer;
    function LoadFileOnSDCard: Integer;
    function FNRequestRegistrationTLV: Integer;
    function ReadLoaderVersion: Integer;

    function FNAcceptMakringCode: Integer;
    function FNDeclineMarkingCode: Integer;
    function FNMarkingClearBuffer: Integer;
    function FNBindMarkingItem: Integer;
    function FNGetKMServerExchangeStatus: Integer;
    procedure UpdateStringForPrinting;
    function ReadFeatureLicenses: Integer;
    function WriteFeatureLicenses: Integer;
    function FNSendUserAttribute: Integer;
    function FNGetMarkingCodeWorkStatus: Integer;
    function PlainTransferEnable: Integer;
    function PlainTransferDisable: Integer;
    function RenderDeclarativeDocument: Integer;

    function FNCloseCheckEx3: Integer;
    function FNBuildCorrectionReceipt3: Integer;

    function FNEncryptData: Integer;
    function FNEncryptReadData: Integer;
    function FNEncryptWriteData: Integer;

    function FNDecryptData: Integer;
    function FNDecryptReadData: Integer;
    function FNDecryptWriteData: Integer;

    function FNDecryptData2: Integer;
    function FNEncryptData2: Integer;
  public
    property UpdateFirmwareStatus: Integer read GetUpdateFirmwareStatus;
    property UpdateFirmwareStatusMessage: WideString read GetUpdateFirmwareStatusMessage;
    property BarcodeHex: AnsiString read GetBarcodeHex write SetBarcodeHex;
    property TagValueBinHex: AnsiString read GetTagValueBinHex write SetTagValueBinHex;
    property Connected: Boolean read GetConnected write SetConnected;
    property PrinterModel: TPrinterModel read GetPrinterModel;
    property Driver: IPrinterDriver read GetDriver;
    property NakCount: Integer read GetNakCount write SetNakCount;
    property CommandRetryCount: Integer read GetCommandRetryCount write SetCommandRetryCount;
    property MaxCmdCount: Integer read GetMaxCmdCount write SetMaxCmdCount;
    property MaxAnsCount: Integer read GetMaxAnsCount write SetMaxAnsCount;
    property MaxENQCount: Integer read GetMaxENQCount write SetMaxENQCount;
    property PortLocked: Boolean read GetPortLocked;
    property TimeStr: AnsiString read Get_TimeStr write Set_TimeStr;
    property NameOperationReg: WideString read Get_NameOperationReg;

    property LDIndex: Integer read Get_LDIndex write Set_LDIndex;
    property LDNumber: Integer read Get_LDNumber write Set_LDNumber;
    property IBMSessionDateTime: TDateTime read Get_IBMSessionDateTime;
    property LineData2: AnsiString read Get_LineData2 write Set_LineData2;
    property LDTCPPort: Integer read Get_LDTCPPort write Set_LDTCPPort;
    property LDTimeout: Integer read Get_LDTimeout write Set_LDTimeout;
    property ComLogFile: AnsiString read Get_ComLogFile write Set_ComLogFile;
    property LDBaudRate: Integer read Get_LDBaudRate write Set_LDBaudRate;
    property ComputerName: AnsiString read Get_ComputerName write Set_ComputerName;
    property LDIPAddress: AnsiString read Get_LDIPAddress write Set_LDIPAddress;
    property LDComNumber: Integer read Get_LDComNumber write Set_LDComNumber;
    property LDComputerName: AnsiString read Get_LDComputerName write Set_LDComputerName;
    property LDUseIPAddress: Boolean read Get_LDUseIPAddress write Set_LDUseIPAddress;
    property LDSysAdminPassword: Integer read Get_LDSysAdminPassword write Set_LDSysAdminPassword;
    property LastSessionDate: TDateTime read Get_LastSessionDate write Set_LastSessionDate;
    property LDConnectionType: Integer read Get_LDConnectionType write Set_LDConnectionType;
    property LDProtocolType: Integer read Get_LDProtocolType write Set_LDProtocolType;
    property FirstSessionDate: TDateTime read Get_FirstSessionDate write Set_FirstSessionDate;
    property SlipStringIntervals: AnsiString read GetSlipStringIntervals write SetSlipStringIntervals;
    property ValueOfFieldInteger: Integer read Get_ValueOfFieldInteger write Set_ValueOfFieldInteger;
    property JournalText: AnsiString read GetJournalText;
    property BarcodeTypes: AnsiString read GetBarcodeTypes;
    property JournalRowCount: Integer read GetJournalRowCount;
    property BarcodeAlignments: AnsiString read GetBarcodeAlignments;
    property BarWidth: Integer read GetBarWidth write SetBarWidth;
    property BarcodeType: Integer read GetBarcodeType write SetBarcodeType;
    property ccProtocol: TCashControlProtocol read GetProtocol write SetProtocol;
    property CashControlPort: AnsiString read Get_CashControlPort write Set_CashControlPort;
    property CashControlHost: AnsiString read Get_CashControlHost write Set_CashControlHost;
    property CashControlUseTCP: Boolean read Get_CashControlUseTCP write Set_CashControlUseTCP;
    property CashControlEnabled: Boolean read Get_CashControlEnabled write Set_CashControlEnabled;
    property ccHeaderLineCount: Integer read GetccHeaderLineCount write SetccHeaderLineCount;
    property ccUseTextAsWareName: Boolean read GetccUseTextAsWareName write SetccUseTextAsWareName;
    property ccWareNameLineNumber: Integer read GetccWareNameLineNumber write SetccWareNameLineNumber;
    property BarcodeAlignment: TBarcodeAlignment read GetBarcodeAlignment write SetBarcodeAlignment;
    property Props: TDispItems read FProps;
    property Methods: TDispItems read FMethods;
    property LogMethods: Boolean read GetLogMethods write SetLogMethods;
    property LineDataHex: AnsiString read GetLineDataHex write SetLineDataHex;
    property LogCommands: Boolean read GetLogCommands write SetLogCommands;
    property TransferByte: AnsiString read GetTransferByte write SetTransferByte;
    property LogFileMaxSize: DWORD read GetLogFileMaxSize write SetLogFileMaxSize;
    property INNAsInteger: Integer read GetINNAsInteger;
    property SerialNumberAsInteger: Integer read GetSerialNumberAsInteger;
    property HasCashControlLicense: Boolean read GetHasCashControlLicense;
    property CharLineLength: Integer read Get_CharLineLength;
    property LD1CUserPassword: Integer read Get_LD1CUserPassword write Set_LD1CUserPassword;
    property LD1CAdminPassword: Integer read Get_LD1CAdminPassword write Set_LD1CAdminPassword;
    property LD1CIsFiscalCheck: Boolean read Get_LD1CIsFiscalCheck write Set_LD1CIsFiscalCheck;
    property LD1CIsReturnCheck: Boolean read Get_LD1CIsReturnCheck write Set_LD1CIsReturnCheck;
    property LD1CIsOpenedCheck: Boolean read Get_LD1CIsOpenedCheck write Set_LD1CIsOpenedCheck;
    property LD1CCloseSession: Boolean read Get_LD1CCloseSession write Set_LD1CCloseSession;
    property LD1CTax: T1CTax read Get_LD1CTax write Set_LD1CTax;
    property LD1CNonFiscalCheckNumber: Integer read Get_LD1CNonFiscalCheckNumber write Set_LD1CNonFiscalCheckNumber;
    property LD1CSerialNumber: AnsiString read Get_LD1CSerialNumber write Set_LD1CSerialNumber;
    property LD1CLineLength: Integer read Get_LD1CLineLength write Set_LD1CLineLength;
    property LD1CTaxProgrammed: Boolean read Get_LD1CTaxProgrammed write Set_LD1CTaxProgrammed;
    property LD1CPaynames: T1CPayNames read Get_LD1CPayNames write Set_LD1CPayNames;
    property LD1CPayProgrammed: Boolean read Get_LD1CPayProgrammed write Set_LD1CPayProgrammed;
    property LD1CCapOpenCheck: Boolean read Get_LD1CCapOpenCheck write Set_LD1CCapOpenCheck;
    property LD1CCapGetShortECRStatus: Boolean read Get_LD1CCapGetShortECRStatus write Set_LD1CCapSetShortECRStatus;
    property LD1CPrintLogo: Boolean read Get_LD1CPrintLogo write Set_LD1CPrintLogo;
    property LD1CLogoSize: Integer read Get_LD1CLogoSize write Set_LD1CLogoSize;
    property LDTaxPassword: Integer read Get_LDTaxPassword write Set_LDTaxPassword;
    property EnteredTaxPassword: Integer read GetEnteredTaxPassword;
    property PollDescription: AnsiString read GetPollDescription;
    property PosControlReceiptSeparator: AnsiString read GetPosControlReceiptSeparator write SetPosControlReceiptSeparator;
    property LogMaxFileSize: Integer read GetLogMaxFileSize write SetLogMaxFileSize;
    property LogMaxFileCount: Integer read GetLogMaxFileCount write SetLogMaxFileCount;
    property SaveSettingsType: Integer read GetSaveSettingsType write SetSaveSettingsType;
    property AdjustRITimeout: Boolean read GetAdjustRITimeout write SetAdjustRITimeout;
    property ReconnectPort: Boolean read GetReconnectPort write SetReconnectPort;
    property DoNotSendENQ: Boolean read GetDoNotSendENQ write SetDoNotSendENQ;
    property ModelsCount: Integer read GetModelsCount;
    property ModelNames: WideString read GetModelNames;
    property UCodePageText: WideString read GetUCodePageText;
    property ModelParamCount: Integer read GetModelParamCount;
    property ComNumber: Integer read Get_ComNumber write Set_ComNumber;
    property Commands: TPrinterCommands read GetCommands;
    property Models: TPrinterModels read GetModels;
    property BarcodeRender: TBarcodeRender read GetBarcodeRender;
    property Logger: TLogger read GetLogger;
    property TCPPort: Integer read GetTCPPort write SetTCPPort;
    property IPAddress: AnsiString read GetIPAddress write SetIPAddress;
    property UseIPAddress: Boolean read GetUseIPAddress write SetUseIPAddress;
    property BufferingType: Integer read GetBufferingType write SetBufferingType;
    property Timeout: Integer read GetTimeout write SetTimeout;
    property PlainTransferMode: Integer read GetPlainTransferMode write SetPlainTransferMode;
    property TLSMode: Integer read GetTLSMode write SetTLSMode;
    property TCPConnectionTimeout: Integer read GetTCPConnectionTimeout write SetTCPConnectionTimeout;
    property SyncTimeout: Integer read GetSyncTimeout write SetSyncTimeout;
    property ProtocolType: Integer read GetProtocolType write SetProtocolType;
    property BaudRate: Integer read GetBaudRate write SetBaudRate;
    property ServerVersion: AnsiString read GetServerVersion;
    property LastKPKDateStr: AnsiString read GetLastKPKDateStr;
    property LastKPKTimeStr: AnsiString read GetLastKPKTimeStr;
    property LDEscapeIP: AnsiString read Get_LDEscapeIP write Set_LDEscapeIP;
    property LDEscapePort: Integer read Get_LDEscapePort write Set_LDEscapePort;
    property LDEscapeTimeout: Integer read Get_LDEscapeTimeout write Set_LDEscapeTimeout;
    property ComLogOnlyErrors: Boolean read GetComLogOnlyErrors write SetComLogOnlyErrors;
    property TimeoutsUsing: Integer read GetTimeoutsUsing write SetTimeoutsUsing;
    property LDCount: Integer read Get_LDCount;
    property NameCashReg: WideString read Get_NameCashReg;
    property NameCashRegEx: WideString read Get_NameCashRegEx;
    property LastKPKDate: TDateTime read Get_LastKPKDate;
    property LastKPKTime: TDateTime read Get_LastKPKTime;
    property LogOn: Boolean read Get_LogOn write Set_LogOn;
    property LDName: WideString read Get_LDName write Set_LDName;
    property ServerConnected: Boolean read Get_ServerConnected;
    property State: TDriverState read FState;
    property ICSEnabled: Boolean read GetICSEnabled write SetICSEnabled;
    property ICSPollPeriod: Integer read GetICSPollPeriod write SetICSPollPeriod;
    property FiscalSignAsString: WideString read GetFiscalSignAsString;
    property FWUpdateEnabled: Boolean read GetFWUpdateEnabled write SetFWUpdateEnabled;
    property FWUpdatePollInterval: Integer read GetFWUpdatePollInterval write SetFWUpdatePollInterval;
    property FWUpdateServerURL: WideString read GetFWUpdateServerURL write SetFWUpdateServerURL;
  end;

  TFiscalPrinters = TObjectList<TFiscalPrinter>;

implementation

uses
  fmuParams, CommandSender, FirmwareUpdatePlugin, FeatureLicenseUpdatePlugin,
  PinpadYarusPlugin, OFDYaSlipPlugin, DeclarativeCheck, TspiotPlugin;

procedure CheckMinLength(const Data: AnsiString; MinLength: Integer);
begin
  if Length(Data) < MinLength then
    RaiseError(E_ANSWERLENGTH, GetRes(@SDriverAnswerLength));
end;

function GetCRC(const Data: AnsiString): Byte;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(Data) do
    Result := Result xor Ord(Data[i]);
end;

procedure CheckIntProp(Value, MinValue, MaxValue: Int64; const PropName: AnsiString);
begin
  if (Value < MinValue) or (Value > MaxValue) then
    InvalidProp(PropName);
end;

function Int64ToECRS(Value: Int64; Count: Integer): AnsiString;
const
  MaxValues: array[2..8] of Int64 = ($10000, $1000000, $100000000, $10000000000, $1000000000000, $100000000000000, 0);
begin
  if Value < 0 then
    Value := MaxValues[Count] - abs(Value);
  SetLength(Result, Count);
  Move(Value, Result[1], Count);
end;

function Int64ToCurrency(Value: Int64; Divider: Integer): Currency;
begin
  Result := 0;
  if (Value >= MinCurrency * Divider) and (Value <= MaxCurrency * Divider) then
  begin
    try
      Result := Value / Divider;
    except
      Result := 0;
    end;
  end;
end;

function AnswerToHex(const S: AnsiString): AnsiString;
var
  i: Integer;
  L: Integer;
  k: Integer;
begin
  Result := '';
  L := Length(S);
  k := 4;
  if Length(S) > 2 then
    if Ord(S[3]) = $FF then
      k := 5;
  for i := 1 to L do
  begin
    Result := Result + IntToHex(Ord(S[i]), 2);
    if i <> L then
    begin
      if (i in [1..k]) or (i = L - 1) then
        Result := Result + ' | '
      else
        Result := Result + ' ';
    end;
  end;
end;

function IsValidValue(Value: Int64; Len: Integer): Boolean;
begin
  Result := IntToBin(Value, Len) <> StringOfChar(#$FF, Len);
end;

function MakeFiscalQR(Dat: TDateTime; Sum: Currency; const FnSerial: string; const DocNumber: string; const FiscalSign: string; DocType: Integer): string;
var
  dt1: string;
  dt2: string;
  saveSeparator: Char;
begin
  saveSeparator := FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator := '.';
  try
    DateTimeToString(dt1, 'YYYYMMDD', Dat);
    DateTimeToString(dt2, 'hhnn', Dat);
    Result := Format('t=%sT%s&s=%.2f&fn=%s&i=%s&fp=%s&n=%d', [dt1, dt2, Sum, FnSerial, DocNumber, FiscalSign, DocType]);
  finally
    FormatSettings.DecimalSeparator := saveSeparator;
  end;
end;

function TaxToFiscalPrinterTax(TaxValue: Byte): Byte;
begin
  case TaxValue of
    1:
      Result := $01;
    2:
      Result := $02;
    3:
      Result := $04;
    4:
      Result := $08;
    5:
      Result := $10;
    6:
      Result := $20;
    7:
      Result := $81;
    8:
      Result := $82;
    9:
      Result := $84;
    10:
      Result := $88;
  end;
end;

{ TFiscalPrinter }

constructor TFiscalPrinter.Create(ADrvFR49: IDrvFR49);
begin
  inherited Create;

  FLock := TCriticalSection.Create;
  FState := TDriverState.Create;
  FConnectionParams := TConnectionParams.Create;
  FTranslation := TTranslation.Create;
  FPrinterModel := TPrinterModel.Create(nil);
  EnablePlugins(True);
  FDrvFR49 := ADrvFR49;
  if FDrvFR49 <> nil then
    FDrvFR49._Release;

  FProps := TDispItems.Create;
  FMethods := TDispItems.Create;

  FTags := TTLVTags.Create;
  FTags.CreateTags;

  if DateOf(Now) >= EncodeDate(2019, 1, 1) then
    FTags.TaxValue := '20'
  else
    FTags.TaxValue := '18';

  FDB := TRecDB.Create;
  FWUpdateParams := TFirmwareUpdateParams.Create;
  FSTLVTag := TTagNode.Create(nil);
  FSTLVStarted := False;
  InitializeProps;
  LoadCommandParams;
  TestMode := False;
  ModelsLoaded := False;
  SetDefParams;
  FCommandSender := TCommandSender.Create(Self);
  FPrinterDevice := TPrinterDevice.Create(FCommandSender);
  FUpdaterDFU := TFWUpdateDFU.Create;
  FUpdaterXModem := TFwupdateXModem.Create;
  FUpdaterDFU.OnFinish := OnDFUUpdateFinished;
  FUpdaterXModem.OnFinish := OnDFUUpdateFinished;
  FFwupdater := FUpdaterDFU;
  FOFDStarted := False;
  FFNReport := TFNReport.Create;
  FPaymanClient := TPaymanClient.Create;
  FCachedFieldStruct := TList<TFieldStruct>.Create;
  // FDeviceMonitor := TShtrihDeviceMonitor.Create;
  // FDeviceMonitor.OnArrived := OnDeviceArrived;
  // FDeviceMonitor.OnRemoved := OnDeviceRemoved;

  AuthKey := ''; // '00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F';
  FDisconnectTimer := TTimer.Create(nil);
  FDisconnectTimer.Enabled := True;
  FDisconnectTimer.Interval := 1000;
  FDisconnectTimer.OnTimer := OnDisconnectTimer;
  Logger.Debug('Create');
end;

destructor TFiscalPrinter.Destroy;
begin
  FDisconnectTimer.Enabled := False;
  FDisconnectTimer.Free;
  // OFDStopPoll;
  Disconnect;
  FDriver := nil;
  // FDeviceMonitor.Free;
  FDevices.Free;
  FCommands.Free;
  // FJournal.Free;
  FBarcodeRender.Free;
  // FPaymDrv.Free;
  FProps.Free;
  FMethods.Free;
  FSTLVTag.Free;
  FDB.Free;
  FTags.Free;
  FMutex.Free;
  FModels.Free;
  FLogger.Free;
  // FDocument.Free;
  FPrinterModel.Free;
  FTranslation.Free;
  FConnectionParams.Free;
  FState.Free;
  FPlugins.Free;
  FPrinterDevice.Free;
  FWUpdateParams.Free;
  FFNReport.Free;
  FPaymanClient.Free;
  FUpdaterDFU.Free;
  FUpdaterXModem.Free;
  FCachedFieldStruct.Free;
  // FPPPService.Free;
  FLock.Free;
  inherited Destroy;
end;

function TFiscalPrinter.GetPlainTransferMode: Integer;
begin
  Result := FConnectionParams.PlainTransferMode;
end;

procedure TFiscalPrinter.SetPlainTransferMode(const Value: Integer);
begin
  FConnectionParams.PlainTransferMode := Value;
end;

function TFiscalPrinter.GetPlugins: TDriverPlugins;
begin
  if FPlugins = nil then
  begin
    FPlugins := TDriverPlugins.Create;
    if not TestMode then
    begin
      FPlugins.Add(TFeatureLicensePlugin.Create(Self));
      FPlugins.Add(TFirmwareUpdatePlugin.Create(Self));
      // FPlugins.Add(TReceiptFilePlugin.Create(Self));
      // FPlugins.Add(TReceiptServerPlugin.Create(Self));
      // FPlugins.Add(TEReportPlugin.Create(Self));
      // FPlugins.Add(TXMLReceiptFilePlugin.Create(Self));
      // FPlugins.Add(TTxtReceiptFilePlugin.Create(Self));
      // FPlugins.Add(TReceiptGnivcPlugin.Create(Self));
      FPlugins.Add(TPinpadYarusPlugin.Create(Self));
      FPlugins.Add(TOFDYaSlipPlugin.Create(Self));
      FPlugins.Add(TTspiotPlugin.Create(Self, TTspiotServer.Instance));
    end;
  end;
  Result := FPlugins;
end;

function TFiscalPrinter.AmountToBin(Value: Currency; Length: Integer): AnsiString;
begin
  Result := IntToBin(Round2(Value * GetSummFactor), Length);
end;

function TFiscalPrinter.BinToAmount(const Data: AnsiString; Index, Count: Integer): Currency;
var
  V: Int64;
begin
  Result := 0;
  try
    if (Copy(Data, Index, Count) <> StringOfChar(#$FF, Count)) then
    begin
      V := BinToInt(Data, Index, Count);
      Result := DoubleToCurrency(V / GetSummFactor);
    end;
  except
    on E: Exception do
    begin
      Logger.Error('BinToAmount, ' + E.Message);
    end;
  end;
end;

function TFiscalPrinter.GetSummFactor: Integer;
begin
  if FSummFactor = 0 then
  begin
    GetFlagsFR;
    FSummFactor := 1;
    if PointPosition then
      FSummFactor := 100;
  end;
  Result := FSummFactor;
end;

function TFiscalPrinter.GetMutex: TMutex;
begin
  if FMutex = nil then
    FMutex := TMutex.Create('FiscalPrinterRegistryLock');
  Result := FMutex;
end;

function TFiscalPrinter.GetBarcodeRender: TBarcodeRender;
begin
  if FBarcodeRender = nil then
    FBarcodeRender := TBarcodeRender.Create;
  Result := FBarcodeRender;
end;

function TFiscalPrinter.GetCommands: TPrinterCommands;
begin
  if FCommands = nil then
    FCommands := CreateCommands;
  Result := FCommands;
end;

{ Прочитать параметры моделей из файла }

procedure TFiscalPrinter.LoadModelParams;
begin
  if not ModelsLoaded then
  begin
    if not TestMode then
    begin
      LoadModelsXml(FModels, GetModulePath + 'Models.xml');
    end;
    ModelsLoaded := True;
  end;
end;

function TFiscalPrinter.GetModels: TPrinterModels;
begin
  if FModels = nil then
  begin
    FModels := TPrinterModels.Create;
    LoadModelParams;
  end;
  Result := FModels;
end;

procedure TFiscalPrinter.CreatePaymentDrv;
begin
  // try
  // GetPaymentDrv;
  // except
  // { !!! }
  // end;
end;

function TFiscalPrinter.InvalidParam(const ParamName: WideString): Integer;
begin
  Result := E_INVALIDPARAM;
  ResultCode := E_INVALIDPARAM;
  ResultCodeDescription := Format('%s %s.', [GetRes(@SInvalidPropValue), ParamName]);
end;

// Запрос состояния

function TFiscalPrinter.SessionGetEcrStatus: Integer;
begin
  Result := ClearResult;
  if not FGetECRStatus then
    Result := GetECRStatus;
end;

function TFiscalPrinter.GetTapeType: Byte;
begin
  Result := 0;
  if UseJournalRibbon then
    SetBit(Result, 0);
  if UseReceiptRibbon then
    SetBit(Result, 1);
  if UseSlipDocument then
    SetBit(Result, 2);

  if UseSlipCheck then
    SetBit(Result, 3);
  if CarryStrings then
    SetBit(Result, 6);
  if DelayedPrint then
    SetBit(Result, 7);
end;

function TFiscalPrinter.GetFieldValue: AnsiString;

  procedure CheckIntFieldValue;
  var
    S: AnsiString;
    Value: Int64;
    MinValue: Int64;
    MaxValue: Int64;
  begin
    MinValue := Cardinal(MinValueOfField);
    MaxValue := Cardinal(MaxValueOfField);
    Value := Cardinal(ValueOfFieldInteger64);
    if (Value < MinValue) or (Value > MaxValue) then
    begin
      S := Format('%s (%d).'#13#10'%s %s..%s.', [GetRes(@SInvalidFieldValue), Value, GetRes(@SValidValues), IntToStr(Cardinal(MinValue)), IntToStr(Cardinal(MaxValue))]);
      RaiseError(E_INVALIDPARAM, S);
    end;
  end;

var
  Value: Int64;
begin
  if FieldType then
  begin
    Result := GetStr2(StrToDevice(ValueOfFieldString), FieldSize);
  end else
  begin
    CheckIntFieldValue;
    Value := Int64(ValueOfFieldInteger);
    Result := IntToBin(Value, FieldSize);
  end;
end;

{ Проверка заводского номера }

function TFiscalPrinter.GetSerialNumber: Int64;
var
  Code: Integer;
begin
  Val(SerialNumber, Result, Code);
  if Code <> 0 then
    InvalidProp('SerialNumber');
end;

function TFiscalPrinter.GetRunningPeriod: Byte;
begin
  if (RunningPeriod < 0) or (RunningPeriod > $FF) then
    InvalidProp('RunningPeriod');
  Result := RunningPeriod;
end;

function TFiscalPrinter.GetRowNumber: Integer;
begin
  if (RowNumber < 0) or (RowNumber > $FFFF) then
    InvalidProp('RowNumber');
  Result := RowNumber;
end;

function TFiscalPrinter.GetTableNumber: Integer;
begin
  if (TableNumber < 0) or (TableNumber > $FF) then
    InvalidProp('TableNumber');
  Result := TableNumber;
end;

function TFiscalPrinter.GetFieldNumber: Integer;
begin
  if (FieldNumber < 0) or (FieldNumber > $FF) then
    InvalidProp('FieldNumber');
  Result := FieldNumber;
end;

function TFiscalPrinter.GetBanknoteType: Integer;
begin
  CheckIntProp(BanknoteType, 0, 23, 'BanknoteType');
  Result := BanknoteType;
end;

function TFiscalPrinter.GetStr(const S: WideString; MinLen, DataLen: Integer): WideString;
var
  StrLen: Integer;
begin
  StrLen := Length(S);
  if StrLen < MinLen then
  begin
    Result := S + StringOfChar(#0, MinLen - StrLen);
  end else
  begin
    if GetModel <> dmShtrihFRF3 then
      Result := Copy(S, 1, 253 - DataLen)
    else
      Result := Copy(S, 1, MinLen);
  end;
end;

function TFiscalPrinter.GetStringForPrinting(DataLen: Integer): WideString;
begin
  Result := GetStr(GetPrintString, 40, DataLen);
end;

// Если не подавался запрос параметров устройства

function TFiscalPrinter.GetModel: TDeviceModel;
begin
  Logger.Debug('GetModel');
  if not FGetDeviceMetrics then
  begin
    if GetDeviceMetrics <> 0 then
      RaiseError(ResultCode, ResultCodeDescription);
  end;
  Result := FModel;
end;

function TFiscalPrinter.GetRegisterNumber: Integer;
begin
  if (RegisterNumber < 0) or (RegisterNumber > $FF) then
    InvalidProp('RegisterNumber');
  Result := RegisterNumber;
end;

function TFiscalPrinter.GetRegisterNumberEx: Integer;
begin
  if (RegisterNumber < 0) or (RegisterNumber > $FFFF) then
    InvalidProp('RegisterNumber');
  Result := RegisterNumber;
end;

function TFiscalPrinter.GetWareCodeStr: AnsiString;
begin
  Result := GetStr(Format('%.4d', [GetWareCode]), 40, 40);
end;

function TFiscalPrinter.GetZintBarcodetype(AGraphic: Boolean): TZintSymbology;
begin
  case BarcodeType of
    { DriverTypes.BARCODE_CODE128A :
      DriverTypes.BARCODE_CODE128B = 1;
      DriverTypes.BARCODE_CODE128C = 2; }

    DriverTypes.BARCODE_QRCODE:
      begin
        if not AGraphic then
          InvalidProp('BarcodeType')
        else
          Result := zsQRCODE;
      end;
    DriverTypes.BARCODE_CODE128AUTO:
      Result := zsCODE128;
    DriverTypes.BARCODE_CODE39:
      Result := zsCODE39;
    DriverTypes.BARCODE_CODE93:
      Result := zsCODE93;
    DriverTypes.BARCODE_ITF14:
      Result := zsITF14;
    DriverTypes.BARCODE_UPCA:
      Result := zsUPCA;
    DriverTypes.BARCODE_UPCE:
      Result := zsUPCE;
    DriverTypes.BARCODE_PDF417:
      begin
        if not AGraphic then
          InvalidProp('BarcodeType')
        else
          Result := zsPDF417;
      end;
    DriverTypes.BARCODE_AZTEC:
      begin
        if not AGraphic then
          InvalidProp('BarcodeType')
        else
          Result := zsAZTEC;
      end;
    DriverTypes.BARCODE_2OF5_INTERLEAVED:
      Result := zsC25INTER;
  else
    InvalidProp('BarcodeType');
  end;
end;

function TFiscalPrinter.GetWareCode: Integer;
begin
  if (WareCode < 1) or (WareCode > 9999) then
    InvalidProp('WareCode');
  Result := WareCode;
end;

function TFiscalPrinter.GetCheckingType: Integer;
begin
  if CheckingType > 4 then
    InvalidProp('CheckingType');
  Result := CheckingType;
end;

function TFiscalPrinter.GetCARegisterNumber: Integer;
begin
  if (RegisterNumber < 0) or (RegisterNumber > 2) then
    InvalidProp('RegisterNumber');
  Result := RegisterNumber;
end;

function TFiscalPrinter.GetLicense: AnsiString;
var
  Value: Int64;
  Code: Integer;
begin
  Val(License, Value, Code);
  if (Code <> 0) or (Value <= 0) then
    InvalidProp('License');
  if Value > $FFFFFFFFFF then
    InvalidProp('License');
  Result := IntToBin(Value, 5);
end;

function TFiscalPrinter.Disconnect: Integer;
var
  NeedToDelay: Boolean;
begin
  Logger.Debug('Disconnect');
  try
    if (not FGetExDeviceMetrics) or (not FGetDeviceMetrics) then
      NeedToDelay := False
    else
      NeedToDelay := IsModelType2(PrinterModel.ModelID);
    FConnected := False;
    ServerDisconnect;

    ECRInput := '';
    ECROutput := '';
    FSummFactor := 0;
    QuantityFactor := 0;
    FECRFlagsValid := False;
    FGetDeviceMetrics := False;
    FGetExDeviceMetrics := False;
    FGetPrinterModel := False;
    FPrintStringWidth := 0;
    FDefaultFont := 0;
    FCashControlINN := '';
    FCachedFieldStruct.Clear;
    if NeedToDelay then
      Sleep(DelayOnDisconnect);
    Result := ClearResult;

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetDeviceCode: Integer;
begin
  if (DeviceCode < 0) or (DeviceCode > $FF) then
    InvalidProp('DeviceCode');
  Result := DeviceCode;
end;

function TFiscalPrinter.GetRNM: Int64;
var
  Code: Integer;
begin
  Val(RNM, Result, Code);
  if Code <> 0 then
    InvalidProp('RNM');
end;

function TFiscalPrinter.GetINN: AnsiString;
var
  Code: Integer;
  Value: Int64;
begin
  Val(INN, Value, Code);
  if Code <> 0 then
    InvalidProp('INN');
  CheckIntProp(Value, 0, 99999999999999, 'INN');
  Result := IntToBin(Value, 6);
end;

function TFiscalPrinter.GetKKTRegistrationNumber: AnsiString;
var
  Code: Integer;
  Value: Int64;
begin
  Val(INN, Value, Code);
  if Code <> 0 then
    InvalidProp('KKTRegistrationNumber');
  CheckIntProp(Value, 0, 99999999999999, 'INN');
  Result := IntToBin(Value, 6);
end;

function TFiscalPrinter.GetINNAsStr: AnsiString;
var
  Code: Integer;
  Value: Int64;
begin
  Val(INN, Value, Code);
  if Code <> 0 then
    InvalidProp('INN');
  CheckIntProp(Value, 0, 99999999999999, 'INN');
  Result := Copy(INN, 1, 12);
  Result := StringOfChar('0', 12 - Length(INN)) + Result;
end;

function TFiscalPrinter.GetKKTRegistrationNumberAsStr: AnsiString;
begin
  Result := Copy(KKTRegistrationNumber, 1, 20);
  Result := StringOfChar('0', 20 - Length(KKTRegistrationNumber)) + Result;
end;

function TFiscalPrinter.GetFlagsFR: Word;
begin
  if not FECRFlagsValid then
  begin
    if GetECRStatus <> 0 then
      RaiseError(ResultCode, ResultCodeDescription);
  end;
  Result := ECRFlags;
end;

// Распаковка ответов

procedure TFiscalPrinter.Decode00(const Data: AnsiString);
begin
  if Length(Data) > 0 then
    OperatorNumber := Ord(Data[1]);
end;

procedure TFiscalPrinter.DecodeEB(const Data: AnsiString);
begin
  CheckMinLength(Data, 46);
  ECRDate := Str2DateBCD(Data, 1);
  ECRTime := Str2TimeBCD(Data, 4);
  SerialNumber := Trim(Copy(Data, 7, 12));
  ECRINN := BCDStrToInt2(Copy(Data, 19, 6));
  INN := IntToINN(ECRINN);
  SessionNumber := BinToInt(Data, 31, 2);
  MFPNumber := Int64ToStr(BCDStrToInt2(Copy(Data, 33, 5)));
  KPKNumber := BCDStrToInt2(Copy(Data, 38, 4));
  KPKValue := BCDStrToInt2(Copy(Data, 42, 3));
  ActivizationControlByte := Ord(Data[45]);
  PrepareActivizationRemainCount := Ord(Data[46]);
end;

procedure TFiscalPrinter.DecodeEC(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  AnswerCode := Ord(Data[1]);
end;

procedure TFiscalPrinter.DecodeED(const Data: AnsiString);
begin
  CheckMinLength(Data, 40);
  KPKStr := Copy(Data, 1, 40);
end;

procedure TFiscalPrinter.DecodeEF(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  CustomerCode := Ord(Data[1]);
end;

procedure TFiscalPrinter.DecodeD4(const Data: AnsiString);
begin
  CheckMinLength(Data, 2);
  MFPStatus := Ord(Data[1]);
  ActivizationStatus := Ord(Data[2]);
end;

procedure TFiscalPrinter.DecodeD5(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  OperatorNumber := Ord(Data[1]);
end;

procedure TFiscalPrinter.Decode4F(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  OperatorNumber := Ord(Data[1]);
end;

procedure TFiscalPrinter.DecodeD6(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  OperatorNumber := Ord(Data[1]);
  LineData := Copy(Data, 2, Length(Data));
end;

procedure TFiscalPrinter.DecodeD7(const Data: AnsiString);
begin
  CheckMinLength(Data, 5);
  OperatorNumber := Ord(Data[1]);
  KPKNumber := BinToInt(Data, 2, 4);
end;

procedure TFiscalPrinter.DecodeD8(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  OperatorNumber := Ord(Data[1]);
end;

procedure TFiscalPrinter.DecodeD9(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  OperatorNumber := Ord(Data[1]);
end;

procedure TFiscalPrinter.DecodeDA(const Data: AnsiString);
begin
  CheckMinLength(Data, 5);
  OperatorNumber := Ord(Data[1]);
  KPKNumber := BinToInt(Data, 2, 4);
end;

procedure TFiscalPrinter.Decode01(const Data: AnsiString);
begin
  CheckMinLength(Data, 2);
  DataBlockNumber := BinToInt(Data, 1, 2);
end;

procedure TFiscalPrinter.Decode02(const Data: AnsiString);
var
  BlockSize: Integer;
begin
  CheckMinLength(Data, 4);
  DeviceCode := BinToInt(Data, 1, 1);
  DataBlockNumber := BinToInt(Data, 2, 2);
  if DeviceCode = $86 then
    BlockSize := 248
  else
    BlockSize := 32;
  DataBlock := Copy(Data, 4, BlockSize);
  BlockDataHex := StrToHex(DataBlock);
end;

procedure TFiscalPrinter.Decode0D(const Data: AnsiString);
begin
  CheckMinLength(Data, 7);
  RegistrationNumber := Ord(Data[1]);
  FreeRegistration := Ord(Data[2]);
  SessionNumber := BinToInt(Data, 3, 2);
  ECRDate := Str2Date(Data, 5);
end;

procedure TFiscalPrinter.Decode0F(const Data: AnsiString);
// var
// I: Int64;
begin
  RNM := Trim(Data);

  { CheckMinLength(Data, 15);
    OperatorNumber := Ord(Data[1]);
    // SerialNumber
    SerialNumber := '';
    I := BinToInt(Data, 2, 7);
    if IsValidValue(I, 7) then
    SerialNumber := Format('%.*d', [PrinterModel.LongSerialDigitCount, I]);
    // RNM
    RNM := '';
    I := BinToInt(Data, 9, 7);
    if IsValidValue(I, 7) then
    begin
    if PrinterModel.CapRnmLeadingZeros then
    RNM := Format('%.*d', [PrinterModel.LongRnmDigitCount, I])
    else
    RNM := IntToStr(I);
    end; }
end;

{
  Код команды:	10h. Длина сообщения: 5 байт.
  Пароль оператора (4 байта)
  Ответ: 		10h. Длина сообщения: 16 или 171 байт.
  Код ошибки (1 байт)
  Порядковый номер оператора (1 байт) 1…30    1
  Флаги ККТ (2 байта) 2
  Режим ККТ (1 байт) 4
  Подрежим ККТ (1 байт)  5
  Количество операций в чеке (1 байт) младший байт двухбайтного числа (см. ниже)  6
  Напряжение резервной батареи (1 байт) 7
  Напряжение источника питания (1 байт)  8
  Зарезервировано (1 байт)      9
  Код ошибки при обновлении ключей (1 байт) 10
  Количество операций в чеке (1 байт) старший байт двухбайтного числа (см. выше) 11
  Температура ТПГ (1 байт)   12
  Предыдущий режим ККТ (1 байт) 13
  Статус обновления ключей (1 байта): Бит 0 – требуется обновление; бит 1 – требуется срочное обновление; биты 2-7 – количество обновленных ключей (0-63) 14
  Результат последней печати1 (1 байт) 15
  // Прошивка 14.10.21 и новее
}

procedure TFiscalPrinter.Decode10(const Data: AnsiString);
var
  BatteryState: Byte;
begin
  if PrinterModel.CapLastPrintResult then
    CheckMinLength(Data, 15)
  else
    CheckMinLength(Data, 14);
  OperatorNumber := Ord(Data[1]);
  SetECRFlags(BinToInt(Data, 2, 2));
  SetECRMode(Ord(Data[4]));
  ECRAdvancedMode := Ord(Data[5]);
  QuantityOfOperations := (Ord(Data[11]) shl 8) + Ord(Data[6]);
  BatteryState := Ord(Data[7]);
  FXState := Ord(Data[8]);
  FMResultCode := Ord(Data[9]);
  EKLZResultCode := Ord(Data[10]);
  UpdateKeysResultCode := Ord(Data[10]);
  PrinterHeadTemperature := Ord(Data[12]);
  PreviousECRMode := Ord(Data[13]);
  UpdateKeysStatus := Ord(Data[14]);
  FBatteryVoltage := Round2(BatteryState / 255 * 100 * 5) / 100;
  FPowerSourceVoltage := Round2(XState * 24 / $D8 * 100) / 100;

  LastPrintResult := 0;
  if PrinterModel.CapLastPrintResult then
  begin
    LastPrintResult := Ord(Data[15]);
  end;
end;

function TFiscalPrinter.IntToINN(Value: Int64): AnsiString;
begin
  Result := '';
  if IsValidValue(Value, 6) then
  begin
    if PrinterModel.CapInnLeadingZeros then
      Result := Format('%.*d', [PrinterModel.InnDigitCount, Value])
    else
      Result := Int64ToStr(Value);
  end;
end;

procedure TFiscalPrinter.Decode11(const Data: AnsiString);
var
  HiSerial: Word;
  MinLen: Integer;
  i: Integer;
begin
  MinLen := 46;
  if PrinterModel.CapCashCore then
    Inc(MinLen, 2);
  if PrinterModel.CapSKNO then
    Inc(MinLen, 2);
  if (PrinterModel.LongSerialDigitCount > 0) and ((UMajorProtocolVersion > 1) or ((UMinorProtocolVersion >= 13) and (UMajorProtocolVersion = 1))) then
    Inc(MinLen, 2);
  CheckMinLength(Data, MinLen);

  OperatorNumber := Ord(Data[1]);
  FECRSoftVersion := Data[2] + '.' + Data[3];
  ECRBuild := BinToInt(Data, 4, 2);
  FECRSoftDate := Str2Date(Data, 6);
  ECRSoftDateInt := Str2EcrDate(Data, 6);
  FLogicalNumber := Ord(Data[9]);
  DocumentNumber := BinToInt(Data, 10, 2);
  SetECRFlags(BinToInt(Data, 12, 2));
  SetECRMode(Ord(Data[14]));
  ECRAdvancedMode := Ord(Data[15]);
  PortNumber := Ord(Data[16]);
  FFMSoftVersion := Data[17] + '.' + Data[18];
  FFMBuild := BinToInt(Data, 19, 2);
  FFMSoftDate := Str2Date(Data, 21);
  ECRDate := Str2Date(Data, 24);
  ECRTime := Str2Time(Data, 27);

  SetFMFlags(Ord(Data[30]));
  // Serial
  ECRSerial := BinToInt(Data, 31, 4);
  SerialNumber := '';
  if IsValidValue(ECRSerial, 4) then
    SerialNumber := Format('%.8d', [ECRSerial]);
  if PrinterModel.CapFN then
  begin
    SerialNumber := Copy(SerialNumber, Length(SerialNumber) - 5, Length(SerialNumber));
  end;
  // SessionNumber
  SessionNumber := BinToInt(Data, 35, 2);
  FFreeRecordInFM := BinToInt(Data, 37, 2);
  RegistrationNumber := Ord(Data[39]);
  FreeRegistration := Ord(Data[40]);
  // INN
  ECRINN := BinToInt(Data, 41, 6);
  INN := IntToINN(ECRINN);
  FFMMode := 0;
  FFMFlagsEx := 0;
  i := 47;
  // Протокол Кассового Ядра
  if PrinterModel.CapCashCore then
  begin
    SetFMFlagsEx(Ord(Data[i]));
    FFMMode := Ord(Data[i + 1]);
    Inc(i, 2);
  end;

  // По протоколу ККТ 2.0
  if (PrinterModel.LongSerialDigitCount > 0) and ((UMajorProtocolVersion > 1) or ((UMinorProtocolVersion >= 13) and (UMajorProtocolVersion = 1))) then
  begin
    // Старшее слово 6-и байтного числа
    HiSerial := BinToInt(Data, i, 2);
    Inc(i, 2);
    if (HiSerial = $FFFF) and (ECRSerial = $FFFFFFFF) then
      SerialNumber := ''
    else
      SerialNumber := Format('%.*d', [PrinterModel.LongSerialDigitCount, StrToIntDef(IntToStr(HiSerial) + IntToStr(ECRSerial), 0)]);
  end;

  if PrinterModel.CapSKNO then
  begin
    SKNOStatus := BinToInt(Data, i, 2);
  end;

  FGetECRStatus := True;
end;

procedure TFiscalPrinter.Decode15_CashCore(const Data: AnsiString);
begin
  CheckMinLength(Data, 2);
  TCPPort := DecodeTCPPort(Ord(Data[1]));
  Timeout := ByteToTimeout(Ord(Data[2]));
end;

procedure TFiscalPrinter.Decode15(const Data: AnsiString);
begin
  if PrinterModel.CapCashCore then
  begin
    Decode15_CashCore(Data);
    Exit;
  end;
  CheckMinLength(Data, 2);
  BaudRate := Ord(Data[1]);
  Timeout := ByteToTimeout(Ord(Data[2]));
end;

procedure TFiscalPrinter.Decode18(const Data: AnsiString);
begin
  CheckMinLength(Data, 3);
  OperatorNumber := BinToInt(Data, 1, 1);
  DocumentNumber := BinToInt(Data, 2, 2);
end;

procedure TFiscalPrinter.Decode1A(const Data: AnsiString);
const
  NumericRegs: TArray<Integer> = [4228, 4229, 4230, 4243, 4256, 4269, 4282, 4283, 4285, 4287, 4289, 4291, 4292, 4293, 4306, 4319, 4332, 4345, 4346, 4348, 4350, 4352, 4354, 4355, 4357, 4359, 4361];
var
  ind: Integer;
begin
  CheckMinLength(Data, 7);
  OperatorNumber := Ord(Data[1]);
  ContentsOfCashRegister := BinToAmount(Data, 2, 6);
  if TArray.BinarySearch<Integer>(NumericRegs, RegisterNumber, ind) then
    ContentsOfCashRegister := ContentsOfCashRegister * 100;
end;

procedure TFiscalPrinter.Decode1B(const Data: AnsiString);
begin
  CheckMinLength(Data, 3);
  OperatorNumber := Ord(Data[1]);
  FContentsOfOperationRegister := BinToInt(Data, 2, 2);
end;

procedure TFiscalPrinter.DecodeFF1A(const Data: AnsiString);
begin
  CheckMinLength(Data, 49);
  OperatorNumber := Ord(Data[1]);
  RegSaleRec := BinToAmount(Data, 2, 6);
  RegBuyRec := BinToAmount(Data, 8, 6);
  RegSaleReturnRec := BinToAmount(Data, 14, 6);
  RegBuyReturnRec := BinToAmount(Data, 20, 6);
  RegSaleSession := BinToAmount(Data, 26, 6);
  RegBuySession := BinToAmount(Data, 32, 6);
  RegSaleReturnSession := BinToAmount(Data, 38, 6);
  RegBuyReturnSession := BinToAmount(Data, 44, 6);
end;

procedure TFiscalPrinter.Decode1D(const Data: AnsiString);
var
  i: Int64;
begin
  CheckMinLength(Data, 5);
  i := BinToInt(Data, 1, 5);
  License := '';
  if IsValidValue(i, 5) then
    License := IntToStr(i);
end;

procedure TFiscalPrinter.Decode1F_CashCore(const Data: AnsiString);
begin
  if FieldType then
  begin
    ValueOfFieldString := DeviceToStr(PAnsiChar(Copy(Data, 1, 246)));
  end else
  begin
    CheckMinLength(Data, FieldSize);
    ValueOfFieldString := IntToStr(Cardinal(BinToInt(Data, 1, FieldSize)));
  end;
end;

procedure TFiscalPrinter.Decode1F(const Data: AnsiString);
begin
  if PrinterModel.CapCashCore then
  begin
    Decode1F_CashCore(Data);
    Exit;
  end;

  if FieldType then
  begin
    ValueOfFieldString := DeviceToStr(PAnsiChar(Copy(Data, 1, FieldSize)));
    Logger.Debug('ValueOfFieldString.s = (' + ValueOfFieldString + ') ' + StrToHex(ValueOfFieldString));
  end else
  begin
    CheckMinLength(Data, FieldSize);
    ValueOfFieldString := IntToStr(Cardinal(BinToInt(Data, 1, FieldSize)));
    Logger.Debug('ValueOfFieldString.i = ' + ValueOfFieldString);
  end;
end;

procedure TFiscalPrinter.Decode28(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  OperatorNumber := Ord(Data[1]);
end;

procedure TFiscalPrinter.Decode2D(const Data: AnsiString);
begin
  CheckMinLength(Data, 43);
  TableName := Translate(DeviceToStr(TrimRight(Copy(Data, 1, 40))));

  RowNumber := 0;
  RowNumber := BinToInt(Data, 41, 2);
  FieldNumber := Ord(Data[43]);
end;

procedure TFiscalPrinter.Decode4B(const Data: AnsiString);
begin
  CheckMinLength(Data, 65);
  OperatorNumber := Ord(Data[1]);
  Price := BinToAmount(Data, 2, 5);
  Department := Ord(Data[7]);
  Tax1 := Ord(Data[8]);
  Tax2 := Ord(Data[9]);
  Tax3 := Ord(Data[10]);
  Tax4 := Ord(Data[11]);
  StringForPrinting := DeviceToStr(PAnsiChar(Copy(Data, 12, 54)));
end;

procedure TFiscalPrinter.Decode6A(const Data: AnsiString);
begin
  CheckMinLength(Data, 3);
  OperatorNumber := Ord(Data[1]);
  RecordCount := BinToInt(Data, 2, 2);
end;

procedure TFiscalPrinter.Decode6B(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  ResultCodeDescription := '';
  if Length(Data) > 1 then
  begin
    if FReadErrorDescription then
      ErrorDescription := DeviceToStr(PAnsiChar(Copy(Data, 1, Length(Data))))
    else
      ResultCodeDescription := DeviceToStr(PAnsiChar(Copy(Data, 1, Length(Data))));
  end;
end;

procedure TFiscalPrinter.Decode50(const Data: AnsiString);
begin
  CheckMinLength(Data, 3);
  OperatorNumber := Ord(Data[1]);
  DocumentNumber := BinToInt(Data, 2, 2);
end;

procedure TFiscalPrinter.Decode2E(const Data: AnsiString);
begin
  CheckMinLength(Data, 42);
  FieldName := Translate(DeviceToStr(TrimRight(Copy(Data, 1, 40))));

  FieldType := Data[41] <> #0;
  FieldSize := Ord(Data[42]);
  if not FieldType then
  begin
    MinValueOfField := 0;
    MaxValueOfField := 0;
    MinValueOfField := BinToInt(Data, 43, FieldSize);
    MaxValueOfField := BinToInt(Data, 43 + FieldSize, FieldSize);
  end;
  AddCachedFieldStruct(TableNumber, FieldNumber, FieldName, FieldSize, MinValueOfField, MaxValueOfField, FieldType);
end;

procedure TFiscalPrinter.Decode62(const Data: AnsiString);
begin
  CheckMinLength(Data, 27);
  OperatorNumber := Ord(Data[1]);
  Summ1 := BinToAmount(Data, 2, 8);
  Summ2 := BinToAmount(Data, 10, 6);
  Summ3 := BinToAmount(Data, 16, 6);
  Summ4 := BinToAmount(Data, 22, 6);
end;

procedure TFiscalPrinter.Decode63(const Data: AnsiString);
begin
  CheckMinLength(Data, 5);
  OperatorNumber := Ord(Data[1]);
  FTypeOfLastEntryFM := Ord(Data[2]) <> 0;
  FTypeOfLastEntryFMEx := Ord(Data[2]);
  ECRDate := Str2Date(Data, 3);
end;

procedure TFiscalPrinter.Decode64(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  FFirstSessionDay := Ord(Data[1]);
  FFirstSessionMonth := Ord(Data[2]);
  FFirstSessionYear := Ord(Data[3]);
  FLastSessionDay := Ord(Data[4]);
  FLastSessionMonth := Ord(Data[5]);
  FLastSessionYear := Ord(Data[6]);
  FirstSessionNumber := BinToInt(Data, 7, 2);
  LastSessionNumber := BinToInt(Data, 9, 2);
end;

procedure TFiscalPrinter.Decode65(const Data: AnsiString);
begin
  CheckMinLength(Data, 7);
  RegistrationNumber := Ord(Data[1]);
  FreeRegistration := Ord(Data[2]);
  SessionNumber := BinToInt(Data, 3, 2);
  ECRDate := Str2Date(Data, 5);
end;

procedure TFiscalPrinter.Decode66(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  FFirstSessionDay := Ord(Data[1]);
  FFirstSessionMonth := Ord(Data[2]);
  FFirstSessionYear := Ord(Data[3]);
  FLastSessionDay := Ord(Data[4]);
  FLastSessionMonth := Ord(Data[5]);
  FLastSessionYear := Ord(Data[6]);
  FirstSessionNumber := BinToInt(Data, 7, 2);
  LastSessionNumber := BinToInt(Data, 9, 2);
end;

procedure TFiscalPrinter.Decode69(const Data: AnsiString);
var
  i: Int64;
begin
  CheckMinLength(Data, 20);
  if PrinterModel.CapSKNO then
    NewPasswordTI := BinToInt(Data, 1, 4)
  else
    FPassword := BinToInt(Data, 1, 4);
  // RNM
  RNM := '';
  i := BinToInt(Data, 5, 5);
  if IsValidValue(i, 5) then
  begin
    if PrinterModel.CapRnmLeadingZeros then
      RNM := Format('%.*d', [PrinterModel.RnmDigitCount, i])
    else
      RNM := IntToStr(i);
  end;
  // INN
  i := BinToInt(Data, 10, 6);
  INN := IntToINN(i);
  SessionNumber := BinToInt(Data, 16, 2);
  ECRDate := Str2Date(Data, 18);
  if PrinterModel.CapSKNO then
    KSAInfo := Trim(Copy(Data, 21, 20));
end;

procedure TFiscalPrinter.Decode89(const Data: AnsiString);
begin
  CheckMinLength(Data, 6);
  OperatorNumber := Ord(Data[1]);
  Summ1 := BinToAmount(Data, 2, 5);
end;

procedure TFiscalPrinter.Decode85(const Data: AnsiString);
begin
  CheckMinLength(Data, 6);
  OperatorNumber := Ord(Data[1]);
  Change := BinToAmount(Data, 2, 5);
end;

// Закрытие чека с возвратом КПК

procedure TFiscalPrinter.DecodeCC(const Data: AnsiString);
begin
  CheckMinLength(Data, 7);
  OperatorNumber := Ord(Data[1]);
  Change := BinToAmount(Data, 2, 5);
  KPKStr := PChar(Copy(Data, 7, 16));
end;

// Чтение параметров активизации ЭКЛЗ

procedure TFiscalPrinter.DecodeCD(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  ECRDate := Str2Date(Data, 1);
  FEKLZNumber := IntToStr(BinToInt(Data, 4, 5));
  SessionNumber := BinToInt(Data, 9, 2);
end;

procedure TFiscalPrinter.SetModel(Value: TDeviceModel);
begin
  QuantityFactor := 1000;
  FModel := Value;
end;

// обновляем модель

procedure TFiscalPrinter.DecodeFC(const Data: AnsiString);
begin
  CheckMinLength(Data, 6);
  UMajorType := Ord(Data[1]);
  UMinorType := Ord(Data[2]);
  UMajorProtocolVersion := Ord(Data[3]);
  UMinorProtocolVersion := Ord(Data[4]);
  FUModel := Ord(Data[5]);
  UCodePage := Ord(Data[6]);
  UDescription := Translate(DeviceToStr(PAnsiChar(Copy(Data, 7, 255))));
  SetModel(MetricsToModel(UModel, UMajorType, UMinorType, UMajorProtocolVersion, UMinorProtocolVersion));
end;

procedure TFiscalPrinter.Decode70(const Data: AnsiString);
begin
  CheckMinLength(Data, 3);
  OperatorNumber := Ord(Data[1]);
  DocumentNumber := BinToInt(Data, 2, 2);
end;

procedure TFiscalPrinter.DecodeAB(const Data: AnsiString);
begin
  CheckMinLength(Data, 5);
  FEKLZNumber := IntToStr(BinToInt(Data, 1, 5));
end;

procedure TFiscalPrinter.DecodeAD_SKNO(const Data: AnsiString);
begin
  CheckMinLength(Data, 3);
  SKNOStatus := BinToInt(Data, 1, 2);
  SKNOError := Ord(Data[3]);
end;

procedure TFiscalPrinter.DecodeAD(const Data: AnsiString);
begin
  if PrinterModel.CapSKNO then
  begin
    DecodeAD_SKNO(Data);
    Exit;
  end;

  CheckMinLength(Data, 20);
  if FCheckEJConnStatus then
    Exit;
  FLastKPKDocumentResult := BinToAmount(Data, 1, 5);
  FLastKPKYear := Ord(Data[6]);
  FLastKPKMonth := Ord(Data[7]);
  FLastKPKDay := Ord(Data[8]);
  FLastKPKhour := Ord(Data[9]);
  FLastKPKMin := Ord(Data[10]);
  FLastKPKNumber := BinToInt(Data, 11, 4);
  FEKLZNumber := IntToStr(BinToInt(Data, 15, 5));
  FEKLZFlags := Ord(Data[20]);
end;

procedure TFiscalPrinter.DecodeAE_SKNO(const Data: AnsiString);
var
  d, m, y, hour, min, sec: Integer;
begin
  CheckMinLength(Data, 8);
  SKNOStatus := BinToInt(Data, 1, 2);
  y := Ord(Data[3]);
  m := Ord(Data[4]);
  d := Ord(Data[5]);
  hour := Ord(Data[6]);
  min := Ord(Data[7]);
  sec := Ord(Data[8]);
  ECRDate := EncodeDate(y + 2000, m, d);
  ECRTime := EncodeTime(hour, min, sec, 0);
end;

procedure TFiscalPrinter.DecodeAE(const Data: AnsiString);
begin
  if PrinterModel.CapSKNO then
  begin
    DecodeAE_SKNO(Data);
    Exit;
  end;

  CheckMinLength(Data, 26);
  SessionNumber := BinToInt(Data, 1, 2);
  Summ1 := BinToAmount(Data, 3, 6);
  Summ2 := BinToAmount(Data, 9, 6);
  Summ3 := BinToAmount(Data, 15, 6);
  Summ4 := BinToAmount(Data, 21, 6);
end;

procedure TFiscalPrinter.DecodeBD_SKNO(const Data: AnsiString);
begin
  CheckMinLength(Data, 14);
  SKNOStatus := BinToInt(Data, 1, 2);
  SKNOIdentifier := Copy(Data, 3, Length(Data));
end;

procedure TFiscalPrinter.DecodeBD(const Data: AnsiString);
begin
  if PrinterModel.CapSKNO then
  begin
    DecodeBD_SKNO(Data);
    Exit;
  end;

  CheckMinLength(Data, 11);
  TransmitStatus := Ord(Data[1]);
  TransmitQueueSize := BinToInt(Data, 2, 4);
  TransmitSessionNumber := BinToInt(Data, 6, 2);
  TransmitDocumentNumber := BinToInt(Data, 8, 4);
end;

procedure TFiscalPrinter.DecodeB1(const Data: AnsiString);
begin
  CheckMinLength(Data, 18);
  FEKLZVersion := PChar(Data);
end;

procedure TFiscalPrinter.DecodeB3(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  EKLZData := DeviceToStr(Data);
end;

procedure TFiscalPrinter.DecodeB4(const Data: AnsiString);
begin
  CheckMinLength(Data, 16);
  UDescription := PChar(Data);
end;

procedure TFiscalPrinter.DecodeF9(const Data: AnsiString);
begin
  CheckMinLength(Data, 2);
  OperatorNumber := Ord(Data[1]);
  FPrinterStatus := Ord(Data[2]);
end;

procedure TFiscalPrinter.DecodeFD(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  ReadByte := Ord(Data[1]);
end;

procedure TFiscalPrinter.Decode26(const Data: AnsiString);
begin
  CheckMinLength(Data, 5);
  // LineWidth
  FPrintWidth := BinToInt(Data, 1, 2);
  FCharWidth := Ord(Data[3]); // Ширина символа в точках
  FCharHeight := Ord(Data[4]); // Высота символа в точках
  FFontCount := Ord(Data[5]); // Количество шрифтов
end;

procedure TFiscalPrinter.DecodeF0(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  OperatorNumber := Ord(Data[1]);
end;

(*
  Параметры модели (8 байт) - битовые поля:
  0 - Весовой датчик контрольной ленты
  1 - Весовой датчик чековой ленты
  2 - Оптический датчик контрольной ленты
  3 - Оптический датчик чековой ленты
  4 - Датчик крышки
  5 - Рычаг термоголовки контрольной ленты
  6 - Рычаг термоголовки чековой ленты
  7 - Верхний датчик подкладного документа
  8 - Нижний датчик подкладного документа
  9 - Презентер поддерживается
  10 - Поддержка команд работы с презентером
  11 - Флаг заполнения ЭКЛЗ
  12 - ЭКЛЗ поддерживается
  13 - Отрезчик поддерживается
  14 - Состояние ДЯ как датчик бумаги в презентере
  15 - Датчик денежного ящика
  16 - Датчик бумаги на входе в презентер
  17 - Датчик бумаги на выходе из презентера
  18 - Купюроприемник поддерживается
  19 - Клавиатура НИ поддерживается
  20 - Контрольная лента поддерживается
  21 - Подкладной документ поддерживается
  22 - Поддержка команд нефискального документа
  23 - Поддержка протокола Кассового Ядра (cashcore)
  24 - Ведущие нули в ИНН
  25 - Ведущие нули в РНМ
  26 - Переворачивать байты при печати линии
  27 - Блокировка ФР по неверному паролю налогового инспектора
  28 - Поддержка альтернативного нижнего уровня протокола ККТ
  29 - Поддержка переноса строк символом '\n' (код 10) в командах печати строк 12H,17H,2FH
  30 - Поддержка переноса строк номером шрифта (коды 1…9) в команде печати строк 2FH
  31 - Поддержка переноса строк символом '\n' (код 10) в фискальных командах 80H…87H,8AH,8BH
  32 - Поддержка переноса строк номером шрифта (коды 1…9) в фискальных командах 80H…87H,8AH,8BH
  33 - Права "СТАРШИЙ КАССИР" (28) на снятие отчетов: X, операционных регистров, по отделам, по налогам, по кассирам, почасового, по товарам
  34 - Поддержка "Бит 3 - слип чек" в командах печати строк 12H,17H,2FH, расширенной графики C3H, графической линии C5H; Поддержка поля "результат последней печати" в кратком запросе ФР
  35 - Поддержка блочной загрузки графики в команде C4H
  36 - Поддержка команды 6BH возврата описания ошибок ФР
  37 - Поддержка флагов печати для команд печати расширенной графики C3H и печати линии C5H
  38 - Поддержка СКНО
  39 - Поддержка МФП
  40 - Поддержка ЭКЛЗ5
  41 - Печать графики с масштабированием
  42 - Загрузка и печать графики 512 с масштабированием
  43 - Поддержка ФН
  44 - Поддержка EoD
  45 - Поддержка автопечати тегов
  46 - Поддержка двумерных штрихкодов в футере
  47 - Поддержка ФН 1.1
  48 - Поддержка чеков коррекции как обычных чеков.
  49 - Зарезервировано
  50 - Зарезервировано
  51 - Зарезервировано
  52 - Зарезервировано
  53 - Зарезервировано
  54 - Зарезервировано
  55 - Зарезервировано
  56 - Зарезервировано
  57 - Зарезервировано
  58 - Зарезервировано
  59 - Зарезервировано
  60 - Зарезервировано
  61 - Зарезервировано
  62 - Зарезервировано
  63 - Зарезервировано
  Ширина печати шрифтом 1 (1 байт) 0 - запросить командой параметры шрифта, 1…255
  Ширина печати шрифтом 2 (1 байт) 0 - запросить командой параметры шрифта, 1…255
  Номер первой печатаемой линии в графике (1 байт) 0, 1, 2
  Количество цифр в ИНН (1 байт) 12, 13, 14
  Количество цифр в РНМ (1 байт) 8, 10
  Количество цифр в длинном РНМ (1 байт) 0 - не поддерживается, 8, 14
  Количество цифр в длинном заводском номере (1 байт) 0 - не поддерживается, 8, 10, 12, 14
  Пароль НИ по умолчанию (4 байта) 0…99999999
  Пароль сист.админа по умолчанию (4 байта) 0…99999999
  Номер таблицы настроек Bluetooth (1 байт) 0 - не поддерживается, 1…255
  Номер поля "Начисление налогов" (1 байт) 0 - не поддерживается, 1…255
  Максимальная длина команды (N/LEN16) (2 байта) 0 - не поддерживается, >1…65535
  Ширина произвольной графической линии в байтах для печати штрих-кода (1 байт) 40 – для узких принтеров; 64, 72 – для широких принтеров
  Ширина графической линии в буфере графики-512 (1 байт) 0 – поле не поддерживается; 64
  Количество линий в буфере графики-512 (2 байта) 0 – поле не поддерживается; 600, 960
  Номер таблицы Фискального Накопителя (1 байт) 0 - не поддерживается, 1…255
  Номер таблицы параметров ОФД (1 байт) 0 - не поддерживается, 1…255
  Номер таблицы встраиваемой и интернет техники (1 байт) 0 - не поддерживается, 1…255
  Номер таблицы версии ФФД (1 байт) 0 - не поддерживается, 1…255
  Номер поля в таблице версии ФФД (1 байт) 0 - не поддерживается, 1…255
*)

procedure TFiscalPrinter.DecodeF7_1(const Data: AnsiString);
begin
  CheckMinLength(Data, 28);
  FPrinterModel.SetParamValue(mpCapJrnSensor, TestBit(Ord(Data[1]), 0)); // 0
  FPrinterModel.SetParamValue(mpCapRecSensor, TestBit(Ord(Data[1]), 1)); // 1
  FPrinterModel.SetParamValue(mpCapJrnOpticalSensor, TestBit(Ord(Data[1]), 2));
  // 2
  FPrinterModel.SetParamValue(mpCapRecOpticalSensor, TestBit(Ord(Data[1]), 3));
  // 3
  FPrinterModel.SetParamValue(mpCapCoverSensor, TestBit(Ord(Data[1]), 4)); // 4
  FPrinterModel.SetParamValue(mpCapJrnLeverSensor, TestBit(Ord(Data[1]), 5));
  // 5
  FPrinterModel.SetParamValue(mpCapRecLeverSensor, TestBit(Ord(Data[1]), 6));
  // 6
  FPrinterModel.SetParamValue(mpCapSlpDocumentHiSensor, TestBit(Ord(Data[1]), 7)); // 7
  FPrinterModel.SetParamValue(mpCapSlpDocumentLoSensor, TestBit(Ord(Data[2]), 0)); // 8
  FPrinterModel.SetParamValue(mpCapPresenter, TestBit(Ord(Data[2]), 1)); // 9
  FPrinterModel.SetParamValue(mpCapPresenterCommands, TestBit(Ord(Data[2]), 2));
  // 10
  FPrinterModel.SetParamValue(mpCapEKLZOverflowSensor, TestBit(Ord(Data[2]), 3)); // 11
  FPrinterModel.SetParamValue(mpCapEJournal, TestBit(Ord(Data[2]), 4)); // 12
  FPrinterModel.SetParamValue(mpCapCutterPresent, TestBit(Ord(Data[2]), 5));
  // 13
  FPrinterModel.SetParamValue(mpCapCashDrawerAsPresenter, TestBit(Ord(Data[2]), 6)); // 14
  FPrinterModel.SetParamValue(mpCapCashDrawerSensor, TestBit(Ord(Data[2]), 7));
  // 15
  FPrinterModel.SetParamValue(mpCapPrsPaperInSensor, TestBit(Ord(Data[3]), 0));
  // 16
  FPrinterModel.SetParamValue(mpCapPrsPaperOutSensor, TestBit(Ord(Data[3]), 1));
  // 17
  FPrinterModel.SetParamValue(mpCapBillAcceptor, TestBit(Ord(Data[3]), 2));
  // 18
  FPrinterModel.SetParamValue(mpCapTaxKeyboard, TestBit(Ord(Data[3]), 3)); // 19
  FPrinterModel.SetParamValue(mpCapJournal, TestBit(Ord(Data[3]), 4)); // 20
  FPrinterModel.SetParamValue(mpCapSlip, TestBit(Ord(Data[3]), 5)); // 21
  FPrinterModel.SetParamValue(mpCapNonfiscalDocument, TestBit(Ord(Data[3]), 6));
  // 22
  FPrinterModel.SetParamValue(mpCapCashCore, TestBit(Ord(Data[3]), 7)); // 23
  FPrinterModel.SetParamValue(mpCapInnLeadingZeros, TestBit(Ord(Data[4]), 0));
  // 24
  FPrinterModel.SetParamValue(mpCapRnmLeadingZeros, TestBit(Ord(Data[4]), 1));
  // 25
  FPrinterModel.SetParamValue(mpSwapLineBytes, TestBit(Ord(Data[4]), 2)); // 26
  FPrinterModel.SetParamValue(mpCapTaxPasswordLock, TestBit(Ord(Data[4]), 3));
  // 27
  FPrinterModel.SetParamValue(mpCapAltProtocol, TestBit(Ord(Data[4]), 4)); // 28
  FPrinterModel.SetParamValue(mpCapWrapNonFiscalString, TestBit(Ord(Data[4]), 5)); // 29
  FPrinterModel.SetParamValue(mpCapWrapWithFontNonFiscapString, TestBit(Ord(Data[4]), 6)); // 30
  FPrinterModel.SetParamValue(mpCapWrapFiscalString, TestBit(Ord(Data[4]), 7));
  // 31
  FPrinterModel.SetParamValue(mpCapWrapWithFontFiscalString, TestBit(Ord(Data[5]), 0)); // 32
  FPrinterModel.SetParamValue(mpCapChiefCashier, TestBit(Ord(Data[5]), 1));
  // 33
  FPrinterModel.SetParamValue(mpCapLastPrintResult, TestBit(Ord(Data[5]), 2));
  // 34
  FPrinterModel.SetParamValue(mpCapLoadBlockGraphics, TestBit(Ord(Data[5]), 3));
  // 35
  FPrinterModel.SetParamValue(mpCapErrorDescription, TestBit(Ord(Data[5]), 4));
  // 36
  FPrinterModel.SetParamValue(mpCapPrintFlagsGraphics, TestBit(Ord(Data[5]), 5)); // 37
  FPrinterModel.SetParamValue(mpCapSKNO, TestBit(Ord(Data[5]), 6)); // 38
  FPrinterModel.SetParamValue(mpCapMFP, TestBit(Ord(Data[5]), 7)); // 39
  FPrinterModel.SetParamValue(mpCapEJ5, TestBit(Ord(Data[6]), 0)); // 40
  FPrinterModel.SetParamValue(mpCapDrawScale, TestBit(Ord(Data[6]), 1)); // 41
  FPrinterModel.SetParamValue(mpCapGraphics512, TestBit(Ord(Data[6]), 2)); // 42
  FPrinterModel.SetParamValue(mpCapFN, TestBit(Ord(Data[6]), 3)); // 43
  FPrinterModel.SetParamValue(mpCapEoD, TestBit(Ord(Data[6]), 4)); // 44
  FEODEnabled := TestBit(Ord(Data[6]), 4);
  FPrinterModel.SetParamValue(mpCapTagAutoPrint, TestBit(Ord(Data[6]), 5));
  // 45
  FPrinterModel.SetParamValue(mpCap2DBarcodeFooter, TestBit(Ord(Data[6]), 6));
  // 46
  FPrinterModel.SetParamValue(mpCapFN11, TestBit(Ord(Data[6]), 7)); // 47
  FPrinterModel.SetParamValue(mpCapCorrectionAsRec, TestBit(Ord(Data[7]), 0));
  // 48
  FPrinterModel.SetParamValue(mpCapExtendedErrorCode, TestBit(Ord(Data[7]), 1));
  // 49
  FPrinterModel.SetParamValue(mpCapFDExtendedAnswer, TestBit(Ord(Data[7]), 2));
  // 50
  FPrinterModel.SetParamValue(mpCapAuthorization, TestBit(Ord(Data[7]), 3));
  // 51
  ///
  FPrinterModel.SetParamValue(mpFont1Width, Ord(Data[9]));
  FPrinterModel.SetParamValue(mpFont2Width, Ord(Data[10]));
  FPrinterModel.SetParamValue(mpFirstDrawLine, Ord(Data[11]));
  FPrinterModel.SetParamValue(mpInnDigitCount, Ord(Data[12]));
  FPrinterModel.SetParamValue(mpRnmDigitCount, Ord(Data[13]));
  FPrinterModel.SetParamValue(mpLongRnmDigitCount, Ord(Data[14]));
  FPrinterModel.SetParamValue(mpLongSerialDigitCount, Ord(Data[15]));
  FPrinterModel.SetParamValue(mpDefaultTaxPassword, BinToInt(Data, 16, 4));
  FPrinterModel.SetParamValue(mpDefaultSysPassword, BinToInt(Data, 20, 4));
  FPrinterModel.SetParamValue(mpBluetoothTableNumber, Ord(Data[24]));
  FPrinterModel.SetParamValue(mpTaxCalcField, Ord(Data[25]));
  FPrinterModel.SetParamValue(mpMaxCmdLength, BinToInt(Data, 26, 2));
  FPrinterModel.SetParamValue(mpMaxLineWidth, BinToInt(Data, 28, 1));
  FPrinterModel.SetParamValue(mpMaxLineWidth512, BinToInt(Data, 29, 1));
  FPrinterModel.SetParamValue(mpMaxLineCount512, BinToInt(Data, 30, 2));
  if Length(Data) > 31 then
    FPrinterModel.SetParamValue(mpFSTableNumber, Ord(Data[32]));
  if Length(Data) > 32 then
    FPrinterModel.SetParamValue(mpOFDTableNumber, Ord(Data[33]));
  if Length(Data) > 33 then
    FPrinterModel.SetParamValue(mpEmbeddedTableNumber, Ord(Data[34]));
  if Length(Data) > 34 then
    FPrinterModel.SetParamValue(mpFFDVersionTableNumber, Ord(Data[35]));
  if Length(Data) > 35 then
    FPrinterModel.SetParamValue(mpFFDVersionFieldNumber, Ord(Data[36]));
end;

procedure TFiscalPrinter.DecodeF7_16(const Data: AnsiString);
begin
  case RequestType of
    0:
      begin
        CheckMinLength(Data, 1);
        LineNumber := Ord(Data[1]);
      end;
    1:
      ;
    2:
      LineData := Data;
    3:
      LineData := Data;
  end;
end;

procedure TFiscalPrinter.DecodeF7(const Data: AnsiString);
begin
  case OperationType of
    1:
      DecodeF7_1(Data);
    16:
      DecodeF7_16(Data);
  end;
end;

procedure TFiscalPrinter.DecodeD0(const Data: AnsiString);
begin
  CheckMinLength(Data, 42);
  // Порядковый номер оператора (1 байт )
  OperatorNumber := Ord(Data[1]);
  // Текущая дата (3 байта ) ДД ММ ГГ
  ECRDate := Str2Date(Data, 2);
  // Текущее время (3 байта ) ЧЧ ММ СС
  ECRTime := Str2Time(Data, 5);
  // Номер последней закрытой смены (2 байта )
  SessionNumber := BinToInt(Data, 8, 2);
  // Сквозной номер последнего закрытого документа (4 байта)
  FIBMDocumentNumber := BinToInt(Data, 10, 4);
  // Номер последнего чека продаж в текущей смене (2 байта)
  FIBMLastSaleReceiptNumber := BinToInt(Data, 14, 2);
  // Номер последнего чека покупок в текущей смене (2 байта)
  FIBMLastBuyReceiptNumber := BinToInt(Data, 16, 2);
  // Номер последнего чека возврата продаж в текущей смене (2 байта)
  FIBMLastReturnSaleReceiptNumber := BinToInt(Data, 18, 2);
  // Номер последнего чека возврата покупок в текущей смене (2 байта)
  FIBMLastReturnBuyReceiptNumber := BinToInt(Data, 20, 2);
  // Дата начала открытой смены(3 байта ) ДД ММ ГГ
  // Время начала открытой смены(3 байта ) ЧЧ ММ СС
  Move(Data[22], FIBMSessionDate, 6);
  // Наличные в кассе за смену (6 байт)
  Summ1 := BinToAmount(Data, 28, 6);
  // Состояние принтера (8 байт)
  FIBMStatusByte1 := Ord(Data[34]);
  FIBMStatusByte2 := Ord(Data[35]);
  FIBMStatusByte3 := Ord(Data[36]);
  FIBMStatusByte4 := Ord(Data[37]);
  FIBMStatusByte5 := Ord(Data[38]);
  FIBMStatusByte6 := Ord(Data[39]);
  FIBMStatusByte7 := Ord(Data[40]);
  FIBMStatusByte8 := Ord(Data[41]);
  // Флаги (1 байт)
  FIBMFlags := Ord(Data[42]);

  LogIBMStatusBytes(False);

end;

procedure TFiscalPrinter.DecodeD1(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  // Порядковый номер оператора (1 байт )
  OperatorNumber := Ord(Data[1]);
  // Состояние принтера (8 байт)
  FIBMStatusByte1 := Ord(Data[2]);
  FIBMStatusByte2 := Ord(Data[3]);
  FIBMStatusByte3 := Ord(Data[4]);
  FIBMStatusByte4 := Ord(Data[5]);
  FIBMStatusByte5 := Ord(Data[6]);
  FIBMStatusByte6 := Ord(Data[7]);
  FIBMStatusByte7 := Ord(Data[8]);
  FIBMStatusByte8 := Ord(Data[9]);
  // Флаги (1 байт)
  FIBMFlags := Ord(Data[10]);

  LogIBMStatusBytes(True);
end;

// Запрос короткого отчета по диапазону смен

procedure TFiscalPrinter.DecodeD2(const Data: AnsiString);
begin
  CheckMinLength(Data, 36);
  FirstSessionNumber := BinToInt(Data, 1, 2);
  LastSessionNumber := BinToInt(Data, 3, 2);
  FirstSessionDate := Str2Date(Data, 5);
  LastSessionDate := Str2Date(Data, 8);
  Summ1 := BinToAmount(Data, 11, 8);
  Summ2 := BinToAmount(Data, 19, 6);
  Summ3 := BinToAmount(Data, 25, 6);
  Summ4 := BinToAmount(Data, 31, 6);
end;

procedure TFiscalPrinter.DecodeE5(const Data: AnsiString);
begin
  CheckMinLength(Data, 4);
  // Порядковый номер оператора (1 байт )
  OperatorNumber := Ord(Data[1]);
  // Режим опроса купюроприемника (1 байт)
  CashAcceptorPollingMode := Ord(Data[2]);
  // Poll1
  Poll1 := Ord(Data[3]);
  // Poll2
  Poll2 := Ord(Data[4]);
end;

procedure TFiscalPrinter.DecodeE6(const Data: AnsiString);
begin
  CheckMinLength(Data, 98);
  // Порядковый номер оператора (1 байт )
  OperatorNumber := Ord(Data[1]);
  // Номер набора регистров
  RegisterNumber := Ord(Data[2]);
  // Количество купюр типа 0..23 (4*24=96 байт) 24 4-х байтных целых числа
  Move(Data[3], Banknotes[0], 96);
end;

procedure TFiscalPrinter.DecodeEA(const Data: AnsiString);
begin
  CheckMinLength(Data, 3);
  PermitActivizationCode := BCDStrToInt2(Copy(Data, 1, 3));
end;

procedure TFiscalPrinter.DecodeFF01(const Data: AnsiString);
begin
  CheckMinLength(Data, 30);
  FNLifeState := Ord(Data[1]);
  FNCurrentDocument := Ord(Data[2]);
  FNDocumentData := Ord(Data[3]);
  FNSessionState := Ord(Data[4]);
  FNWarningFlags := Ord(Data[5]);
  try
    ECRDate := EncodeDate(Ord(Data[6]) + 2000, Ord(Data[7]), Ord(Data[8]));
  except
    ECRDate := EncodeDate(1970, 1, 1);
  end;
  try
    ECRTime := EncodeTime(Ord(Data[9]), Ord(Data[10]), 0, 0);
  except
    ECRTime := EncodeTime(3, 0, 0, 0);
  end;
  // ECRDate := (BinToInt(Data, 6, 5) / 86400) + EncodeDateTime(1970, 1, 1, 3, 0, 0, 0);
  // ECRTime :=  TimeOf(ECRDate);
  // ECRDate := DateOf(ECRDate);
  SerialNumber := Copy(Data, 11, 16);
  DocumentNumber := BinToInt(Data, 27, 4);
end;

procedure TFiscalPrinter.DecodeFF04(const Data: AnsiString);
begin
  CheckMinLength(Data, 17);
  FNSoftVersion := Trim(Copy(Data, 1, 16));
  FNSoftType := Ord(Data[17]);
end;

procedure TFiscalPrinter.DecodeFF06(const Data: AnsiString);
begin
  CheckMinLength(Data, 8);
  DocumentNumber := BinToInt(Data, 1, 4);
  FiscalSign := BinToInt(Data, 5, 4);
end;

{
  Ответ для ФФД 1.1:    FF4Сh Длина сообщения: 65 байт.
  Код ошибки : 1 байт
  Дата и время:  5 байт DATE_TIME
  ИНН : 12 байт ASCII
  Регистрационный номер ККT: 20 байт ASCII
  Код налогообложения: 1 байт
  Режим работы: 1 байт
  Расширенные признаки работы ККТ: 1 байт
  ИНН ОФД: 12 байт ASCII
  Код причины изменения сведений о ККТ:4 байта
  Номер ФД: 4 байта
  Фискальный признак: 4 байта

}
procedure TFiscalPrinter.DecodeFF09_11(const Data: AnsiString);
var
  y, m, d, h, min: Integer;
begin
  CheckMinLength(Data, 64);
  y := Ord(Data[1]);
  m := Ord(Data[2]);
  d := Ord(Data[3]);
  h := Ord(Data[4]);
  min := Ord(Data[5]);
  try
    ECRDate := EncodeDate(y + 2000, m, d);
  except
    ECRDate := EncodeDate(1970, 1, 1);
  end;
  try
    ECRTime := EncodeTime(h, min, 0, 0);
  except
    ECRTime := EncodeTime(0, 0, 0, 0);
  end;
  INN := Trim(Copy(Data, 6, 12));
  KKTRegistrationNumber := Copy(Data, 18, 20);
  TaxType := Ord(Data[38]);
  WorkMode := Ord(Data[39]);
  WorkModeEx := Ord(Data[40]);
  INNOFD := Trim(Copy(Data, 41, 12));
  RegistrationReasonCode := 0;
  RegistrationReasonCodeEx := BinToInt(Data, 53, 4);
  DocumentNumber := BinToInt(Data, 57, 4);
  FiscalSign := BinToInt(Data, 61, 4);
end;

procedure TFiscalPrinter.DecodeFF09(const Data: AnsiString);
var
  y, m, d, h, min: Integer;
begin
  if Length(Data) > 48 then
  begin
    DecodeFF09_11(Data);
    Exit;
  end;

  CheckMinLength(Data, 48);
  y := Ord(Data[1]);
  m := Ord(Data[2]);
  d := Ord(Data[3]);
  h := Ord(Data[4]);
  min := Ord(Data[5]);
  try
    ECRDate := EncodeDate(y + 2000, m, d);
  except
    ECRDate := EncodeDate(1970, 1, 1);
  end;
  try
    ECRTime := EncodeTime(h, min, 0, 0);
  except
    ECRTime := EncodeTime(0, 0, 0, 0);
  end;
  INN := Trim(Copy(Data, 6, 12));
  KKTRegistrationNumber := Copy(Data, 18, 20);
  // SerialNumber := Copy(Data, 38, 16);
  TaxType := Ord(Data[38]);
  WorkMode := Ord(Data[39]);
  WorkModeEx := 0;
  RegistrationReasonCodeEx := 0;
  INNOFD := '';
  RegistrationReasonCode := Ord(Data[40]);
  DocumentNumber := BinToInt(Data, 41, 4);
  FiscalSign := BinToInt(Data, 45, 4);
end;

procedure TFiscalPrinter.DecodeFF4C(const Data: AnsiString);
var
  y, m, d, h, min: Integer;
begin
  if Length(Data) > 48 then
  begin
    DecodeFF09_11(Data);
    Exit;
  end;

  CheckMinLength(Data, 47);
  y := Ord(Data[1]);
  m := Ord(Data[2]);
  d := Ord(Data[3]);
  h := Ord(Data[4]);
  min := Ord(Data[5]);
  try
    ECRDate := EncodeDate(y + 2000, m, d);
  except
    ECRDate := EncodeDate(1970, 1, 1);
  end;
  try
    ECRTime := EncodeTime(h, min, 0, 0);
  except
    ECRTime := EncodeTime(0, 0, 0, 0);
  end;
  INN := Copy(Data, 6, 12);
  KKTRegistrationNumber := Copy(Data, 18, 20);
  TaxType := Ord(Data[38]);
  WorkMode := Ord(Data[39]);
  WorkModeEx := 0;
  RegistrationReasonCodeEx := 0;
  INNOFD := '';
  if Length(Data) = 48 then
  begin
    RegistrationReasonCode := Ord(Data[40]);
    DocumentNumber := BinToInt(Data, 41, 4);
    FiscalSign := BinToInt(Data, 45, 4);
  end else
  begin
    DocumentNumber := BinToInt(Data, 40, 4);
    FiscalSign := BinToInt(Data, 44, 4);
  end;
end;

procedure TFiscalPrinter.DecodeFF0A(const Data: AnsiString);
begin
  CheckMinLength(Data, 2);
  DocumentType := Ord(Data[1]);
  OFDTicketReceived := Ord(Data[2]) <> 0;
  DocumentData := Copy(Data, 3, Length(Data));
  case DocumentType of
    1:
      DecodeDocType1(DocumentData);
    2:
      DecodeDocType2(DocumentData);
    3:
      DecodeDocType3(DocumentData);
    4:
      DecodeDocType3(DocumentData);
    5:
      DecodeDocType2(DocumentData);
    6:
      DecodeDocType6(DocumentData);
    11:
      DecodeDocType11(DocumentData);
    21:
      DecodeDocType21(DocumentData);
    31:
      DecodeDocType3(DocumentData);
  end;
end;

// SDocType1 = 'Отчёт о регистрации';
{
  Дата и время	DATE_TIME	5
  Номер ФД	Uint32, LE	4
  Фискальный признак	Uint32, LE	4
  ИНН	ASCII	12
  Регистрационный номер ККТ	ASCII	20
  Код налогообложения	Byte	1
  Режим работы	Byte	1 }
procedure TFiscalPrinter.DecodeDocType1(const Data: AnsiString);
begin
  CheckMinLength(Data, 47);
  DecodeDataTime(Data);
  DocumentNumber := BinToInt(Data, 6, 4);
  FiscalSign := BinToInt(Data, 10, 4);
  INN := Copy(Data, 14, 12);
  KKTRegistrationNumber := Copy(Data, 26, 20);
  TaxType := Ord(Data[46]);
  WorkMode := Ord(Data[47]);
  if Length(Data) > 47 then
  begin
    CheckMinLength(Data, 60);
    WorkModeEx := Ord(Data[48]);
    INNOFD := Copy(Data, 49, 12)
  end else
  begin
    WorkModeEx := 0;
    INNOFD := '';
  end;
end;

{ Дата и время	DATE_TIME	5
  Номер ФД	Uint32, LE	4
  Фискальный признак	Uint32, LE	4
  Номер смены	Uint16, LE	2 }

// SDocType2 = 'Отчёт об открытии смены';
procedure TFiscalPrinter.DecodeDocType2(const Data: AnsiString);
begin
  CheckMinLength(Data, 15);
  DecodeDataTime(Data);
  DocumentNumber := BinToInt(Data, 6, 4);
  FiscalSign := BinToInt(Data, 10, 4);
  SessionNumber := BinToInt(Data, 14, 2);
end;

// SDocType3 = 'Кассовый чек';

{ Дата и время	DATE_TIME	5
  Номер ФД	Uint32, LE	4
  Фискальный признак	Uint32, LE	4
  Тип операции	Byte	1
  Сумма операции	Uint40, LE	5 }

procedure TFiscalPrinter.DecodeDocType3(const Data: AnsiString);
begin
  CheckMinLength(Data, 19);
  DecodeDataTime(Data);
  DocumentNumber := BinToInt(Data, 6, 4);
  FiscalSign := BinToInt(Data, 10, 4);
  OperationType := Ord(Data[14]);
  Summ1 := BinToAmount(Data, 15, 5);
end;

// 6 Отчёт о закрытии фискального накопителя
{ Дата и время	DATE_TIME	5
  Номер ФД	Uint32, LE	4
  Фискальный признак	Uint32, LE	4
  ИНН	ASCII	12
  Регистрационный номер ККТ	ASCII	20 }

procedure TFiscalPrinter.DecodeDocType6(const Data: AnsiString);
begin
  CheckMinLength(Data, 45);
  DecodeDataTime(Data);
  DocumentNumber := BinToInt(Data, 6, 4);
  FiscalSign := BinToInt(Data, 10, 4);
  INN := Copy(Data, 14, 12);
  KKTRegistrationNumber := Copy(Data, 26, 20);
end;

{
  11 Отчёт об изменении параметров регистрации
  Для ФН 1.1
  Поле	Тип	Длина
  Дата и время	DATE_TIME	5
  Номер ФД	Uint32, LE	4
  ФПД	Uint32, LE	4
  ИНН	ASCII	12
  Регистрационный номер ККТ	ASCII	20
  Код налогообложения	Byte	1
  Режим работы	Byte	1
  Расширенные признаки работы ККТ	Byte	1
  ИНН ОФД	ASCII	12
  Код причины изменения сведений о ККТ (Соответствует кодировке поля TLV 1205)	Uint32, LE	4
}
procedure TFiscalPrinter.DecodeDocType11_11(const Data: AnsiString);
begin
  CheckMinLength(Data, 64);
  DecodeDataTime(Data);
  DocumentNumber := BinToInt(Data, 6, 4);
  FiscalSign := BinToInt(Data, 10, 4);
  INN := Copy(Data, 14, 12);
  KKTRegistrationNumber := Copy(Data, 26, 20);
  TaxType := Ord(Data[46]);
  WorkMode := Ord(Data[47]);
  WorkModeEx := Ord(Data[48]);
  INNOFD := Trim(Copy(Data, 49, 12));
  RegistrationReasonCodeEx := BinToInt(Data, 61, 4);
  RegistrationReasonCode := 0;
end;


// 11 Отчёт об изменении параметров регистрации
{ Дата и время	DATE_TIME	5
  Номер ФД	Uint32, LE	4
  Фискальный признак	Uint32, LE	4
  ИНН	ASCII	12
  Регистрационный номер ККТ	ASCII	20
  Код налогообложения	Byte	1
  Режим работы	Byte	1
  Код причины перерегистрации	Byte	1 }

procedure TFiscalPrinter.DecodeDocType11(const Data: AnsiString);
begin

  if Length(Data) > 48 then
  begin
    DecodeDocType11_11(Data);
    Exit;
  end;

  CheckMinLength(Data, 48);
  DecodeDataTime(Data);
  DocumentNumber := BinToInt(Data, 6, 4);
  FiscalSign := BinToInt(Data, 10, 4);
  INN := Copy(Data, 14, 12);
  KKTRegistrationNumber := Copy(Data, 26, 20);
  TaxType := Ord(Data[46]);
  WorkMode := Ord(Data[47]);
  RegistrationReasonCode := Ord(Data[48]);
  RegistrationReasonCodeEx := 0;
  WorkModeEx := 0;
  INNOFD := '';
end;

// 21 Отчет о состоянии расчетов
{ Дата и время	DATE_TIME	5
  Номер ФД	Uint32, LE	4
  Фискальный признак	Uint32, LE	4
  Кол-во неподтвержденных документов	Uint32, LE	4
  Дата первого неподтвержденного документа	DATE_TIME	5 }
procedure TFiscalPrinter.DecodeDocType21(const Data: AnsiString);
var
  y, m, d: Integer;
begin
  CheckMinLength(Data, 20);
  DecodeDataTime(Data);
  DocumentNumber := BinToInt(Data, 6, 4);
  FiscalSign := BinToInt(Data, 10, 4);
  DocumentCount := BinToInt(Data, 14, 4);
  y := Ord(Data[18]);
  m := Ord(Data[19]);
  d := Ord(Data[20]);
  try
    Date2 := EncodeDate(y + 2000, m, d);
  except
    ECRDate := EncodeDate(1970, 1, 1);
  end;
  Time2 := EncodeTime(0, 0, 0, 0);
end;

procedure TFiscalPrinter.DecodeFF0B(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  SessionNumber := BinToInt(Data, 1, 2);
  DocumentNumber := BinToInt(Data, 3, 4);
  FiscalSign := BinToInt(Data, 7, 4);
end;

procedure TFiscalPrinter.DecodeAnswer(CmdCode: Word; const Data: AnsiString);
begin
  case CmdCode of
    $01:
      Decode01(Data);
    $02:
      Decode02(Data);
    $03:
      ;
    $04:
      Decode04(Data);
    $05:
      Decode05(Data);
    $0D:
      Decode0D(Data);
    $0E:
      ;
    $0F:
      Decode0F(Data);
    $10:
      Decode10(Data);
    $11:
      Decode11(Data);
    $12:
      Decode00(Data);
    $13:
      Decode00(Data);
    $14:
      ;
    $15:
      Decode15(Data);
    $16:
      ;
    $17:
      Decode00(Data);
    $18:
      Decode18(Data);
    $19:
      Decode00(Data);
    $1A:
      Decode1A(Data);
    $1B:
      Decode1B(Data);
    $1C:
      ;
    $1D:
      Decode1D(Data);
    $1E:
      ;
    $1F:
      Decode1F(Data);
    $20:
      ;
    $21:
      ;
    $22:
      ;
    $23:
      ;
    $24:
      ;
    $25:
      Decode00(Data);
    $26:
      Decode26(Data);
    $27:
      ;
    $28:
      Decode28(Data);
    $29:
      Decode00(Data);
    $2A:
      Decode00(Data);
    $2B:
      Decode00(Data);
    $2C:
      Decode00(Data);
    $2D:
      Decode2D(Data);
    $2E:
      Decode2E(Data);
    $2F:
      Decode00(Data);
    $40:
      Decode00(Data);
    $41:
      Decode00(Data);
    $42:
      Decode00(Data);
    $43:
      Decode00(Data);
    $44:
      Decode00(Data);
    $45:
      Decode00(Data);
    $46:
      Decode00(Data);
    $4A:
      Decode00(Data);
    $4B:
      Decode4B(Data);
    $4C:
      Decode00(Data);
    $4D:
      Decode00(Data);
    $4E:
      Decode00(Data);
    $4F:
      Decode4F(Data);
    $50:
      Decode50(Data);
    $51:
      Decode50(Data);
    $55:
      Decode00(Data);
    $56:
      Decode00(Data);
    $57:
      Decode85(Data);
    $60:
      ;
    $61:
      ;
    $62:
      Decode62(Data);
    $63:
      Decode63(Data);
    $64:
      Decode64(Data);
    $65:
      Decode65(Data);
    $66..$67:
      Decode66(Data);
    $68:
      ;
    $69:
      Decode69(Data);
    $6A:
      Decode6A(Data);
    $6B:
      Decode6B(Data);
    $70..$71:
      Decode70(Data);
    $72..$75:
      Decode00(Data);
    $76..$77:
      Decode85(Data);
    $78..$7E:
      Decode00(Data);
    $80..$84:
      Decode00(Data);
    $85, $8E:
      Decode85(Data);
    $86..$88:
      Decode00(Data);
    $89:
      Decode89(Data);
    $8A..$8D:
      Decode00(Data);
    $8F:
      Decode00(Data);
    $A0..$AA:
      ;
    $AB:
      DecodeAB(Data);
    $AC:
      ;
    $AD:
      DecodeAD(Data);
    $AE:
      DecodeAE(Data);
    $AF:
      ;
    $B0:
      Decode00(Data);
    $B1:
      DecodeB1(Data);
    $B2:
      ;
    $B3:
      DecodeB3(Data);
    $B4..$BB:
      DecodeB4(Data);
    $BC:
      ;
    $BD:
      DecodeBD(Data);
    $C0:
      Decode00(Data);
    $C1:
      Decode00(Data);
    $C2:
      Decode00(Data);
    $C3:
      Decode00(Data);
    $C4:
      Decode00(Data);
    $C5:
      Decode00(Data);
    $CB:
      Decode00(Data);
    $CC:
      DecodeCC(Data);
    $CD:
      DecodeCD(Data);
    $D0:
      DecodeD0(Data);
    $D1:
      DecodeD1(Data);
    $D2, $D3:
      DecodeD2(Data);
    $D4:
      DecodeD4(Data);
    $F0:
      DecodeF0(Data);
    $F1:
      DecodeF0(Data);
    $F9:
      DecodeF9(Data);
    $FB:
      ;
    $FC:
      DecodeFC(Data);
    $F7:
      DecodeF7(Data);
    $FD:
      DecodeFD(Data);
    $FE:
      DecodeFE(Data);
    $C8:
      DecodeC8(Data);
    $C9:
      DecodeC9(Data);
    $E0:
      Decode00(Data);
    $E1:
      Decode00(Data);
    $E2:
      Decode00(Data);
    $E3:
      Decode00(Data);
    $E4:
      Decode00(Data);
    $E5:
      DecodeE5(Data);
    $E6:
      DecodeE6(Data);
    $E7:
      Decode00(Data);
    $E9:
      ;
    $EA:
      DecodeEA(Data);
    $EB, $EE:
      DecodeEB(Data);
    $EC:
      DecodeEC(Data);
    $ED:
      DecodeED(Data);
    $EF:
      DecodeEF(Data);
    $D5:
      DecodeD5(Data);
    $D6:
      DecodeD6(Data);
    $D7:
      DecodeD7(Data);
    $D8:
      DecodeD8(Data);
    $D9:
      DecodeD9(Data);
    $DA:
      DecodeDA(Data);
    $DB:
      DecodeDB(Data);
    $DC:
      Decode00(Data);
    $DD:
      Decode00(Data);
    $DE:
      Decode00(Data);
    $DF:
      Decode00(Data);
    $F2:
      ;
    $FF01:
      DecodeFF01(Data);
    $FF02:
      DecodeFF02(Data);
    $FF03:
      DecodeFF03(Data);
    $FF04:
      DecodeFF04(Data);
    $FF05:
      ;
    $FF06:
      DecodeFF06(Data);
    $FF07:
      ;
    $FF08:
      ;
    $FF09:
      DecodeFF09(Data);
    $FF0A:
      DecodeFF0A(Data);
    $FF0B:
      DecodeFF0B(Data);
    $FF0C:
      ;
    $FF0D:
      ;
    $FF0E:
      DecodeFF0E(Data);

    $FF1A:
      DecodeFF1A(Data);

    $FF30:
      DecodeFF30(Data);
    $FF31:
      DecodeFF31(Data);
    $FF32:
      DecodeFF32(Data);
    $FF33:
      ;
    $FF34:
      DecodeFF34(Data);
    $FF35:
      ;
    $FF36:
      DecodeFF36(Data);
    $FF37:
      ;
    $FF38:
      DecodeFF38(Data);
    $FF39:
      DecodeFF39(Data);
    $FF3A:
      DecodeFF3A(Data);
    $FF3B:
      DecodeFF3B(Data);
    $FF3C:
      DecodeFF3C(Data);
    $FF3E:
      DecodeFF3E(Data);
    $FF3F:
      DecodeFF3F(Data);
    $FF40:
      DecodeFF40(Data);
    $FF41:
      ;
    $FF42:
      ;
    $FF43:
      DecodeFF43(Data);
    $FF45:
      DecodeFF45(Data);
    $FF4A:
      DecodeFF4A(Data);
    $FF4B:
      ;
    $FF4C:
      DecodeFF4C(Data);
    $FF50:
      ;
    $FF51:
      DecodeFF51(Data);
    $FF52:
      DecodeFF52(Data);
    $FF53:
      DecodeFF53(Data);
    $FF61:
      DecodeFF61(Data);
    $FF62:
      ;
    $FF63:
      DecodeFF63(Data);
    $FF65:
      DecodeFF65(Data);
    $FF67:
      DecodeFF67(Data);
    $FF68:
      DecodeFF68(Data);
    $FF69:
      DecodeFF69(Data);
    $FF70:
      DecodeFF70(Data);
    $FF71:
      DecodeFF71(Data);
    $FF72:
      DecodeFF72(Data);
    $FF74:
      DecodeFF74(Data);
    $FF75:
      DecodeFF75(Data);
    $FF76:
      DecodeFF76(Data);
    $FFF0:
      DecodeFFF0(Data);
    $FFF1:
      DecodeFFF1(Data);
  end;
end;

// 01h, Запрос дампа

function TFiscalPrinter.DampRequest: Integer;
begin
  try
    Result := Send(#$01 + FPassw + AnsiChar(GetDeviceCode));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 02h, Запрос данных

function TFiscalPrinter.GetData: Integer;
begin
  Result := Send(#$02 + FPassw);
end;

// 03h, Прерывание выдачи данных

function TFiscalPrinter.InterruptDataStream: Integer;
begin
  Result := Send(#$03 + FPassw);
end;

// 0Dh, Фискализация (перерегистрация) с длинным РНМ

function TFiscalPrinter.FiscalizationWithLongRNM: Integer;
var
  Data: AnsiString;
begin
  try
    CheckIntProp(GetRNM, 0, 99999999999999, 'RNM');

    Data := #$0D + FPassw + IntToBin(NewPasswordTI, 4) + IntToBin(GetRNM, 7) + GetINN;

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 0Eh, Ввод длинного заводского номера

function TFiscalPrinter.SetLongSerialNumber: Integer;
var
  S: AnsiString;
begin
  try
    S := IntToBin(GetSerialNumber, 7);
    Result := Send(#$0E + FPassw + S);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 0Fh, Запрос длинного заводского номера и длинного РНМ

function TFiscalPrinter.GetLongSerialNumberAndLongRNM: Integer;
begin
  Result := Send(#$0F + FPassw);
end;

// 10h, Короткий запрос состояния

function TFiscalPrinter.GetShortECRStatus: Integer;
begin
  try
    // Прочитать параметры моделей из файла
    Result := Send(#$10 + FPassw);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 11h, Полный запрос состояния

function TFiscalPrinter.GetECRStatus: Integer;
begin
  try
    Result := Send(#$11 + FPassw);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 12h, Печать жирной строки (КЯ)

function TFiscalPrinter.PrintWideString_CashCore: Integer;
var
  Data: AnsiString;
begin
  Data := #$12 + FPassw + AnsiChar(GetTapeType) + Copy(GetPrintString, 1, 249);
  Result := Send(Data);
end;

// 12h, Печать жирной строки

function TFiscalPrinter.PrintWideString: Integer;
var
  Data: AnsiString;
begin
  try
    if PrinterModel.CapCashCore then
    begin
      Result := PrintWideString_CashCore;
      Exit;
    end;

    Data := #$12 + FPassw + AnsiChar(GetTapeType) + GetStr(GetPrintString, 20, 6);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 13h, Гудок

function TFiscalPrinter.Beep: Integer;
begin
  Result := Send(#$13 + FPassw);
end;

// 14h, Установка параметров обмена

function TFiscalPrinter.SetExchangeParam: Integer;
var
  Data: AnsiString;
  TimeoutByte: Byte;
  B2, B3: Byte;
  sOFDSuspended: Boolean;
begin
  sOFDSuspended := OFDExchangeSuspended;
  try
    try
      OFDExchangeSuspended := True;
      if Timeout < 1000 then
        InvalidProp('Timeout');
      TimeoutByte := TimeoutToByte(Timeout);
      Timeout := ByteToTimeout(TimeoutByte);

      if PortNumber = 128 then
      begin
        B2 := EncodeTCPPort(TCPPort);
        B3 := 0
      end else
      begin
        B2 := GetBaudRate;
        B3 := TimeoutByte;
      end;

      Data := #$14 + FPassw + AnsiChar(PortNumber) + AnsiChar(B2) + AnsiChar(B3);

      Result := Send(Data);
    finally
      OFDExchangeSuspended := sOFDSuspended;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 15h, Чтение параметров обмена

function TFiscalPrinter.GetExchangeParam: Integer;
begin
  try
    Result := Send(#$15 + FPassw + AnsiChar(PortNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 16h, Технологическое обнуление

function TFiscalPrinter.ResetSettings: Integer;
begin
  Result := Send(#$16);
  (*
    if PrinterModel.ModelID = 8 then
    Result := Send(#$16#$01)
    else
    Result := Send(#$16);
  *)
end;

// 17h, Печать строки (КЯ)

function TFiscalPrinter.PrintString_CashCore: Integer;
var
  Data: AnsiString;
begin
  Data := #$17 + FPassw + AnsiChar(GetTapeType) + Copy(GetPrintString, 1, 249);
  Result := Send(Data);
end;

function TFiscalPrinter.GetPrintStringWidth: Integer;
var
  SavePassword: Integer;
begin
  if FPrintStringWidth <> 0 then
  begin
    Result := FPrintStringWidth;
    Exit;
  end;
  SavePassword := Password;
  try
    Logger.Debug('GetPrintStringWidth');
    Result := 40;
    FontType := ReadDefaultFont;
    Password := SysAdminPassword;
    try
      Check(GetFontMetrics);
    finally
      Password := SavePassword;
    end;
    if CharWidth <> 0 then
      Result := Trunc(PrintWidth / CharWidth);
    FPrintStringWidth := Result;
  finally
    Password := SavePassword;
  end;
end;

function TFiscalPrinter.DoPrintString: Integer;
var
  Data: AnsiString;
begin
  try
    if PrinterModel.CapCashCore then
    begin
      Result := PrintString_CashCore;
      Exit;
    end;

    Data := #$17 + FPassw + AnsiChar(GetTapeType) + GetStringForPrinting(6);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 17h, Печать строки

function TFiscalPrinter.PrintString: Integer;
begin
  if WrapStrings then
    Result := PrintStringWithWrap
  else
    Result := DoPrintString;
end;


// Печать строки с переносом

function TFiscalPrinter.PrintStringWithWrap: Integer;
var
  S: WideString;
  L: Integer;
  StrBackup: WideString;
  RepCount: Integer;
begin
  StrBackup := StringForPrinting;
  try
    try
      Logger.Debug('PrintStringWithWrap');
      L := GetPrintStringWidth;
      Logger.Debug('Print width: ' + IntToStr(L));
      S := StringForPrinting;
      repeat
        RepCount := 0;
        StringForPrinting := Copy(S, 1, L);
        repeat
          FontType := ReadDefaultFont;
          Result := PrintStringWithFont;
          Inc(RepCount);
          if (Result = $50) or (Result = $4B) then
            Sleep(50);
        until ((Result <> $50) and (Result <> $4B)) or (RepCount >= 5);
        if Result <> 0 then
          Exit;
        Delete(S, 1, L);
      until Length(S) = 0;
    except
      on E: Exception do
        Result := HandleException(E);
    end;
  finally
    StringForPrinting := StrBackup;
  end;
end;

// 18h, Печать заголовка документа
function TFiscalPrinter.PrintDocumentTitle: Integer;
var
  Data: AnsiString;
begin
  Data := #$18 + FPassw + GetStr2(StrToDevice(DocumentName), 30) + WordToStr(DocumentNumber);

  Result := Send(Data);
end;

// 19h, Тестовый прогон
function TFiscalPrinter.Test: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$19 + FPassw + AnsiChar(GetRunningPeriod);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 1Ah, Запрос денежного регистра

function TFiscalPrinter.GetCashRegEx: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$1A + FPassw + WordToStr(GetRegisterNumberEx);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 1Ah, Запрос денежного регистра

function TFiscalPrinter.GetCashReg: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$1A + FPassw + AnsiChar(GetRegisterNumber);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// FF1AH - Запрос денежных регистров базы товаров

function TFiscalPrinter.GetWareBaseCashRegs: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$FF#$1A + FPassw + WordToStr(GetWareCode);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 1Bh, Запрос операционного регистра

function TFiscalPrinter.GetOperationReg: Integer;
begin
  try
    Result := Send(#$1B + FPassw + AnsiChar(GetRegisterNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 1Ch, Запись лицензии

function TFiscalPrinter.WriteLicense: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$1C + FPassw + GetLicense;
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 1Dh, Чтение лицензии

function TFiscalPrinter.ReadLicense: Integer;
begin
  Result := Send(#$1D + FPassw);
end;

// 1Eh, Запись таблицы

procedure TFiscalPrinter.UpdatePassword;
begin
  // Пароль оператора
  if (TableNumber = 2) and (RowNumber = 30) and (FieldNumber = 1) then
  begin
    Set_Password(ValueOfFieldInteger);
  end;
end;

function TFiscalPrinter.WriteTable: Integer;
var
  Data: AnsiString;
begin
  try
    Result := ReadFieldStruct;
    if DRV_SUCCESS(Result) then
    begin
      Data := #$1E + FPassw + AnsiChar(GetTableNumber) + WordToStr(GetRowNumber) + AnsiChar(GetFieldNumber) + GetFieldValue;

      Result := Send(Data);
      if Result = 0 then
        UpdatePassword;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.WriteTable2: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$1E + FPassw + AnsiChar(GetTableNumber) + WordToStr(GetRowNumber) + AnsiChar(GetFieldNumber) + GetFieldValue;

    Result := Send(Data);
    if Result = 0 then
      UpdatePassword;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 1Fh, Чтение таблицы

function TFiscalPrinter.ReadTable: Integer;
begin
  Result := ReadFieldStruct;
  if not DRV_SUCCESS(Result) then
    Exit;
  Logger.Debug('ReadTable T=' + GetTableNumber.ToString + ', R=' + GetRowNumber.ToString + ', F=' + GetFieldNumber.ToString);
  try
    Result := Send(#$1F + FPassw + AnsiChar(GetTableNumber) + WordToStr(GetRowNumber) + AnsiChar(GetFieldNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// 20h, Запись положения десятичной точки

function TFiscalPrinter.SetPointPosition: Integer;
begin
  Result := Send(#$20 + FPassw + AnsiChar(BoolToInt[PointPosition]));
  if Result = 0 then
  begin
    FECRFlagsValid := False;
    FSummFactor := 0;
  end;
end;

// 21h, Программирование времени

function TFiscalPrinter.SetTime: Integer;
var
  Data: AnsiString;
  hour, min, sec, MSec: Word;
begin
  DecodeTime(ECRTime, hour, min, sec, MSec);
  Data := #$21 + FPassw + AnsiChar(hour) + AnsiChar(min) + AnsiChar(sec);

  Result := Send(Data);
end;

// 22h, Программирование даты

function TFiscalPrinter.SetDate: Integer;
var
  Data: AnsiString;
  Year, Month, Day: Word;
begin
  DecodeDate(ECRDate, Year, Month, Day);
  Data := #$22 + FPassw + AnsiChar(Day) + AnsiChar(Month) + AnsiChar(Year mod 100);

  Result := Send(Data);
end;

// 23h, Подтверждение программирования даты

function TFiscalPrinter.ConfirmDate: Integer;
var
  Data: AnsiString;
  Year, Month, Day: Word;
begin
  DecodeDate(ECRDate, Year, Month, Day);
  Data := #$23 + FPassw + AnsiChar(Day) + AnsiChar(Month) + AnsiChar(Year mod 100);

  Result := Send(Data);
end;

// 24h, Инициализация таблиц начальными значениями

function TFiscalPrinter.InitTable: Integer;
begin
  Result := Send(#$24 + FPassw);
end;

// Bug0001 - ошибка перепутанных битов для команд печати
// Проверяем сборку и дату ПО: сборка 4766 от 30.01.06 14:25

function TFiscalPrinter.IsBug0001: Boolean;
begin
  Result := (ECRBuild = 4766) and (ECRSoftDateInt.Day = 30) and (ECRSoftDateInt.Month = 01) and (ECRSoftDateInt.Year = 06);
end;

// 25h, Отрезка чека

function TFiscalPrinter.CutCheck: Integer;
var
  ACutType: Boolean;
begin
  if FeedAfterCut and not (FeedLineCount in [0..255]) then
  begin
    Result := InvalidParam('FeedLineCount');
    Exit;
  end;

  // Запрос состояния
  Result := SessionGetEcrStatus;
  if Result <> 0 then
    Exit;
  // Ошибка заключалась в
  ACutType := CutType;
  if IsBug0001 then
    ACutType := not ACutType;
  Result := Send(#$25 + FPassw + AnsiChar(BoolToInt[ACutType]));
  if Result <> 0 then
    Exit;

  // Промотка после отрезки
  if FeedAfterCut then
    Result := Send(#$29 + FPassw + AnsiChar(2) + AnsiChar(FeedLineCount));
end;

// 2Eh, Запрос структуры поля с кэшированием

function TFiscalPrinter.ReadFieldStruct: Integer;
var
  mFieldStruct: TFieldStruct;
begin
  Result := ClearResult;
  if FindCachedField(TableNumber, FieldNumber, mFieldStruct) then
  begin
    Logger.Debug('ReadFieldStruct. Cached struct found ' + 'T=' + mFieldStruct.TableNumber.ToString + ', F=' + mFieldStruct.FieldNumber.ToString + ', N=' + mFieldStruct.FieldName + ', S=' + mFieldStruct.FieldSize.ToString + ', Min=' + mFieldStruct.MinValue.ToString + ', Max=' + mFieldStruct.MaxValue.ToString + ', T=' + SysUtils.BoolToStr(mFieldStruct.FieldType, True));

    FieldName := mFieldStruct.FieldName;
    FieldSize := mFieldStruct.FieldSize;
    MinValueOfField := mFieldStruct.MinValue;
    MaxValueOfField := mFieldStruct.MaxValue;
    FieldType := mFieldStruct.FieldType;
  end else
    Result := GetFieldStruct;
end;

// 2Eh, Запрос структуры поля

function TFiscalPrinter.GetFieldStruct: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$2E + FPassw + AnsiChar(GetTableNumber) + AnsiChar(GetFieldNumber);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// FCh, Получить тип устройства

function TFiscalPrinter.GetDeviceMetrics: Integer;
begin
  Result := Send(#$FC);
end;

{ Флаги ФП }

procedure TFiscalPrinter.SetFMFlags(Value: Byte);
begin
  FFMFlags := Value;
  // 0 - ФП 1 (0 -нет, 1 - есть)
  FFM1IsPresent := TestBit(Value, 0);
  // 1 - ФП 2 (0 -нет, 1 - есть)
  FFM2IsPresent := TestBit(Value, 1);
  // 2 - Лицензия (0 - не введена, 1 - введена)
  FLicenseIsPresent := TestBit(Value, 2);
  // 3 - Переполнение ФП (0 - нет, 1 - есть)
  FFMOverflow := TestBit(Value, 3);
  // 4 - Батарея ФП (0 - >80%, 1 - <80%)
  FIsBatteryLow := TestBit(Value, 4);
  FBatteryCondition := TestBit(Value, 4);
  // 5 - Последняя запись ФП (0 - испорчена, 1 - корректна)
  FIsLastFMRecordCorrupted := TestBit(Value, 5);
  // 6 - Смена в ФП (0 - закрыта, 1 - открыта)
  FIsFMSessionOpen := TestBit(Value, 6);
  // 7 - 24 часа в ФП (0 - не кончились, 1 - кончились)
  FIsFM24HoursOver := TestBit(Value, 7);
end;

// Дополнительные флаги (Протокол Кассового Ядра)

(* Битовое поле (назначение бит):
  9 (1)- АСПД (0 - нет, есть записи активизации ЭКЛЗ в ФП, 1 - да)
  10 (2)- Блокировка ККТ по неверному паролю НИ (0 - нет, 1 - есть)
  11 (3)- Зарезервировано
  12 (4)- Три или более поврежденных записей сменных итогов в ФП (0 - нет, 1 - да)
  13 (5)- Запись фискализации или активизации ЭКЛЗ или заводского номера в накопителе повреждена (0 - нет, 1 - да)
  14 (6)- Зарезервировано
  15 (7)- Последняя запись в накопителе ФП (0 - фискализации/активизации ЭКЛЗ, 1 - сменного итога)
*)

procedure TFiscalPrinter.SetFMFlagsEx(Value: Byte);
begin
  FFMFlagsEx := Value;
  // АСПД режим (0 - нет, 1 - есть)
  FIsASPDMode := TestBit(Value, 1);

  // Блокировка ККТ по неверному паролю НИ (0 - нет, 1 - есть)
  FIsBlockedByWrongTaxPassword := TestBit(Value, 2);

  // Имеется 3 или более поврежденных записей сменных итогов (0 - нет, 1 - есть)
  FIsCorruptedFMRecords := TestBit(Value, 4);
  // Повреждена запись фискализации, активизации ЭКЛЗ или заводского номера (0 - нет, 1 - есть)
  FIsCorruptedFiscalizationInfo := TestBit(Value, 5);

  // Последняя запись в накопителе ФП (0 - фискализации/активизации ЭКЛЗ, 1 - сменного итога)
  if TestBit(Value, 7) then
    FLastFMRecordType := 1
  else
    FLastFMRecordType := 0;
end;

// Флаги принтера

procedure TFiscalPrinter.SetECRFlags(Value: Word);
begin
  FECRFlags := Value;
  FECRFlagsValid := True;

  // Value := (Value and FlagsMask) + (DefaultFlags and (not FlagsMask)); { !!! }

  // 0 - Рулон операционного журнала (0 - нет, 1 - есть)
  FJournalRibbonIsPresent := TestBit(Value, 0);
  // 1 - Рулон чековой ленты (0 - нет, 1 - есть)
  FReceiptRibbonIsPresent := TestBit(Value, 1);
  // 2 - Верхний датчик подкладного документа (0 - нет, 1 - да)
  FSlipDocumentIsMoving := TestBit(Value, 2);
  // 3 - Нижний датчик подкладного документа (0 - нет, 1 - да)
  FSlipDocumentIsPresent := TestBit(Value, 3);
  // 4 - Положение десятичной точки (0 - 0 знаков, 1 - 2 знака)
  PointPosition := TestBit(Value, 4);
  // 5 - ЭКЛЗ (0 - нет, 1 - есть)
  FEKLZIsPresent := TestBit(Value, 5);
  // 6 - Оптический датчик операционного журнала (0 - бумаги нет, 1 - бумага есть)
  FJournalRibbonOpticalSensor := TestBit(Value, 6);
  // 7 - Оптический датчик чековой ленты (0 - бумаги нет, 1 - бумага есть)
  FReceiptRibbonOpticalSensor := TestBit(Value, 7);
  // 8 - Рычаг термоголовки контрольной ленты (0 - поднят, 1 - опущен)
  FJournalRibbonLever := TestBit(Value, 8);
  // 9 - Рычаг термоголовки чековой ленты (0 - поднят, 1 - опущен)
  FReceiptRibbonLever := TestBit(Value, 9);
  // 10 - Крышка корпуса (0 - опущена, 1 - поднята)
  FLidPositionSensor := TestBit(Value, 10);
  // 11 - Денежный ящик (0 - закрыт, 1 - окрыт)
  FIsDrawerOpen := TestBit(Value, 11);
  // 12а - Отказ правого датчика принтера (0 - нет, 1 - да)
  FIsPrinterRightSensorFailure := TestBit(Value, 12);
  // 12б - Бумага на входе в презентер (0 - нет, 1 - да)
  PresenterIn := TestBit(Value, 12);
  // 13а - Отказ левого датчика принтера (0 - нет, 1 - да)
  FIsPrinterLeftSensorFailure := TestBit(Value, 13);
  // 13б - Бумага на выходе из презентера (0 - нет, 1 - да)
  PresenterOut := TestBit(Value, 13);
  // 14 - ЭКЛЗ почти заполнена (0 - нет, 1 - да)
  FIsEKLZOverflow := TestBit(Value, 14);
  // 15а - Увеличенная точность количества
  // (0 - нормальная точность, 1 - увеличенная точность)
  FQuantityPointPosition := TestBit(Value, 15);

  if AutoSensorValues then
  begin
    if not PrinterModel.CapJrnSensor then
      FJournalRibbonIsPresent := True;

    if not PrinterModel.CapRecSensor then
      FReceiptRibbonIsPresent := True;

    if not PrinterModel.CapSlpDocumentHiSensor then
      FSlipDocumentIsMoving := True;

    if not PrinterModel.CapSlpDocumentLoSensor then
      FSlipDocumentIsPresent := True;

    if not PrinterModel.CapJrnOpticalSensor then
      FJournalRibbonOpticalSensor := True;

    if not PrinterModel.CapRecOpticalSensor then
      FReceiptRibbonOpticalSensor := True;

    if not PrinterModel.CapJrnLeverSensor then
      FJournalRibbonLever := True;

    if not PrinterModel.CapRecLeverSensor then
      FReceiptRibbonLever := True;

    if not PrinterModel.CapCoverSensor then
      FLidPositionSensor := False;

    if not PrinterModel.CapEKLZOverflowSensor then
      FIsEKLZOverflow := False;
  end;

  // Для моделей "ЯРУС"
  if PrinterModel.CapCashDrawerAsPresenter then
  begin
    PresenterIn := not FIsDrawerOpen;
    FIsDrawerOpen := False;
  end;
end;

procedure TFiscalPrinter.SetECRMode(Value: Byte);
begin
  FullECRMode := Value;
  FECRMode := Value and $0F;
  FECRModeStatus := Value shr 4;
  FECRMode8Status := Value shr 4;
end;

function TFiscalPrinter.Get_LineData2: AnsiString;
begin
  Result := StrToDec(LineData);
end;

procedure TFiscalPrinter.Set_LineData2(const Value: AnsiString);
begin
  LineData := DecToStr(Value);
end;

{ TDriver }

function TFiscalPrinter.GetEKLZCode1Status: Integer;
begin
  Result := GetEKLZCode1Report;
end;

function TFiscalPrinter.GetEKLZCode2Status: Integer;
begin
  Result := GetEKLZCode2Report;
end;

function TFiscalPrinter.ReadWriteFM: Integer;
begin
  Result := NotSupported;
end;

function TFiscalPrinter.PrintHeader: Integer;
var
  i: Integer;
  SaveRowNumber: Integer;
  SaveFieldNumber: Integer;
  SaveTableNumber: Integer;
  S: array[1..3] of WideString;
  SaveStringForPrinting: WideString;
begin
  { Сохраняем свойства }
  SaveRowNumber := RowNumber;
  SaveFieldNumber := FieldNumber;
  SaveTableNumber := TableNumber;
  SaveStringForPrinting := StringForPrinting;
  try
    { Читаем клише }
    TableNumber := 4;
    FieldNumber := 1;
    for i := 1 to 3 do
    begin
      RowNumber := 3 + i;
      Result := ReadTable;
      if Result <> 0 then
        Exit;
      S[i] := ValueOfFieldString;
    end;
    { Печатаем клише }
    for i := 1 to 3 do
    begin
      StringForPrinting := S[i];
      Result := PrintString;
      if Result <> 0 then
        Exit;
    end;
  finally
    { Восстанавливаем свойства }
    RowNumber := SaveRowNumber;
    FieldNumber := SaveFieldNumber;
    TableNumber := SaveTableNumber;
    StringForPrinting := SaveStringForPrinting;
  end;
end;

function TFiscalPrinter.CloseCheckWithResult: Integer;
begin
  Result := NotSupported;
end;

function TFiscalPrinter.AboutBox: Integer;
var
  DriverVersion: AnsiString;
  ServerVersion: AnsiString;
begin
  try
    { Версия драйвера }
    DriverVersion := Format(SDriverVersion, [GetFileVersionInfoStr]);
    ServerVersion := Format(SServerVersion, [Driver.ServerVersion]);
    ShowAboutBox(GetActiveWindow, SDriverName, [DriverVersion, ServerVersion]);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.PresenterKeep: Integer;
begin
  Result := Send(#$F1 + FPassw + #1);
end;

function TFiscalPrinter.PresenterPush: Integer;
begin
  Result := Send(#$F1 + FPassw + #0);
end;

function TFiscalPrinter.OpenScreen: Integer;
begin
  Result := Send(#$F0 + FPassw + #1);
end;

function TFiscalPrinter.CloseScreen: Integer;
begin
  Result := Send(#$F0 + FPassw + #0);
end;

function TFiscalPrinter.GetComLogOnlyErrors: Boolean;
begin
  Result := False;
end;

procedure TFiscalPrinter.SetComLogOnlyErrors(Value: Boolean);
begin
  { !!! }
end;

// IDrvFR14

function TFiscalPrinter.SetSCPassword: Integer;
var
  Data: AnsiString;
begin
  if SCPassword > 99999999 then
  begin
    Result := InvalidParam('SCPassword');
    Exit;
  end;

  if NewSCPassword > 99999999 then
  begin
    Result := InvalidParam('NewSCPassword');
    Exit;
  end;

  Data := #$F3 + IntToBin(SCPassword, 4) + IntToBin(NewSCPassword, 4);
  Result := Send(Data);
end;

function TFiscalPrinter.GetLastKPKDateStr: AnsiString;
begin
  // Дата в формате dd.mm.yyyy
  Result := Format('%.2d.%.2d.%.4d', [FLastKPKDay, FLastKPKMonth, 2000 + FLastKPKYear]);
end;

function TFiscalPrinter.GetLastKPKTimeStr: AnsiString;
begin
  // Время в формате hh:mm:ss
  Result := Format('%.2d:%.2d:00', [FLastKPKhour, FLastKPKMin]);
end;

function TFiscalPrinter.LockPortTimeout: Integer;
begin
  Result := DoLockPortTimeout;
end;

procedure TFiscalPrinter.SetDefParams;
begin
  AdjustRITimeout := False;
  ReconnectPort := False;
  DoNotSendENQ := False;
  TranslationEnabled := False;
  Devices.LDIndex := 0;
  Timeout := DefTimeout;
  ConnectionTimeout := DefConnectionTimeout;
  TCPConnectionTimeout := DefTCPConnectionTimeout;
  SyncTimeout := 0;
  BaudRate := DefBaudRate;
  ComNumber := DefComNumber;
  TCPPort := DefTCPPort;
  ConnectionType := CT_LOCAL;
  GlobalLogger.FileName := GetDefaultLogFileName;
  GlobalLogger.Enabled := False;
  LogCommands := False;
  LogMethods := False;
  CardPayType := 2;
  CardPayEnabled := False;
  PayDepartment := 15;
  ParamsPageIndex := 0;
  PayDepartment := 15;
  RealPayDepartment := 1;
  MobilePayEnabled := False;
  WaitForPrintingDelay := 300;
  RequestErrorDescription := True;
  CommandRetryCount := DefCommandRetryCount;
  FeedAfterCut := False;
  FeedLineCount := 3;
  StatusCommand := STATUS_COMMAND_DRIVER_SELECTION;
  LogMaxFileCount := DefLogMaxFileCount;
  LogMaxFileSize := DefLogMaxFileSize;
  CodePage := CODE_PAGE_RUSSIAN;
  PrintJournalBeforeZReport := False;
  SwapBytesMode := DefSwapBytesMode;
  CheckFMConnection := True;
  CheckEJConnection := False;
  AutoSensorValues := True;
  AutoStartSearch := False;
  SearchTimeout := 200;
  OFDEnabled := False;
  ICSEnabled := False;
  OFDPollPeriod := 30;
  ICSPollPeriod := 60;
  OFDServer := '109.73.43.4';
  OFDPort := 19082;
  AutoOpenSession := True;
  OFDReadTimeout := 10000;
  UpdateFirmwareSuspended := False;

  FConnectionParams.ComputerName := GetCompName;
  AuthKeyStorageType := 0;
  ItemNameLength := 0;
  FWUpdateSearchTimeout := 30000;
  FWUpdDelayAfterReboot := 10000;
  FWUpdDelayBeforeSearch := 30000;
  FWUpdDelayBeforeWrite := 3000;
  FWUpdWriteTimeout := 20000;
  // PPPComNumber := 1;
  // PPPServiceEnabled := False;
  FWUpdateFFDParams := 2;
  FWUpdateFFDWaitInterval := 3;
  IPAddress := DefIPAddress;
  UseIPAddress := True;
  FWUpdPrintStatus := True;
  MCOSUSign := False;
  PlainTransferMode := 0;
  TLSMode := 0;
  CorrectDateTimeOnOpenSession := False;
  DisconnectOnIdle := False;
  DisconnectOnIdleTimeout := 2000;
end;

function TFiscalPrinter.Get_ComLogFile: AnsiString;
begin
  Result := GlobalLogger.FileName;
end;

procedure TFiscalPrinter.Set_ComLogFile(const Value: AnsiString);
begin
  GlobalLogger.FileName := Value;
end;

function TFiscalPrinter.CreateDriver: IPrinterDriver;
begin
  Logger.Debug('CreateDriver: ' + IntToStr(ConnectionType));
  FConnectionParams.UseTCP := False;
  case ConnectionType of
    CT_LOCAL:
      Result := TLocalDriver.Create(FConnectionParams);
    CT_TCP:
      Result := TTCPDriver.Create(FConnectionParams);
    CT_DCOM:
      Result := TDCOMDriver.Create(FConnectionParams);
    // CT_EMULATOR: Result := TPrinterEmulatorDriver.Create;
    CT_TCPSOCKET:
      begin
        FConnectionParams.UseTCP := True;
        Result := TTCPSocketDriver.Create(FConnectionParams);
      end;
    CT_PPP:
      begin
        FConnectionParams.UseTCP := True;
        Result := TPPPDriver.Create(FConnectionParams);
      end;

    CT_EMULATOR, CT_ESCAPE, CT_PACKETDRV:
      raise Exception.Create('Не  поддерживается');
  else
    Result := TLocalDriver.Create(FConnectionParams);
  end;
  FCurrentProtocolType := GetProtocolType;
end;

// Поддержка TCP

function TFiscalPrinter.Get_LDConnectionType: Integer;
begin
  Result := Devices.LDConnectionType;
end;

function TFiscalPrinter.Get_LDIPAddress: AnsiString;
begin
  Result := Devices.LDIPAddress;
end;

function TFiscalPrinter.Get_LDTCPPort: Integer;
begin
  Result := Devices.LDTCPPort;
end;

function TFiscalPrinter.Get_LDUseIPAddress: Boolean;
begin
  Result := Devices.LDUseIPAddress;
end;

procedure TFiscalPrinter.Set_LDConnectionType(Value: Integer);
begin
  Devices.LDConnectionType := Value;
end;

procedure TFiscalPrinter.Set_LDIPAddress(const Value: AnsiString);
begin
  Devices.LDIPAddress := Value;
end;

procedure TFiscalPrinter.Set_LDTCPPort(Value: Integer);
begin
  Devices.LDTCPPort := Value;
end;

procedure TFiscalPrinter.Set_LDUseIPAddress(Value: Boolean);
begin
  Devices.LDUseIPAddress := Value;
end;

function TFiscalPrinter.Get_LDSysAdminPassword: Integer;
begin
  Result := Devices.LDSysAdminPassword;
end;

procedure TFiscalPrinter.Set_LDSysAdminPassword(Value: Integer);
begin
  Devices.LDSysAdminPassword := Value;
end;

procedure TFiscalPrinter.GlobalLock;
begin
  GetMutex.Lock(INFINITE);
end;

procedure TFiscalPrinter.GlobalUnlock;
begin
  GetMutex.Unlock;
end;

procedure TFiscalPrinter.WriteLogStart;
const
  Separator = '------------------------------------------------------------';
resourcestring
  SDriverText = 'М3Про. PRO-RETAIL. Версия файла: ';
begin
  Logger.Debug(Separator);
  Logger.Debug('LOG START');
  Logger.Debug(SDriverText + GetFileVersionInfoStr);
  Logger.Debug(Separator);
  WriteLogParameters;
end;

procedure TFiscalPrinter.WriteLogParameters;
begin
  // Log parameters
  GlobalLogger.Debug('CommandRetryCount', CommandRetryCount);
  GlobalLogger.Debug('ComLogFile', GlobalLogger.FileName);
  GlobalLogger.Debug('LogOn', GlobalLogger.Enabled);
  GlobalLogger.Debug('BaudRate', BaudRate);
  GlobalLogger.Debug('ComNumber', ComNumber);
  GlobalLogger.Debug('Timeout', Timeout);
  GlobalLogger.Debug('PlainTransferMode', PlainTransferMode);
  GlobalLogger.Debug('TLSMode', TLSMode);
  GlobalLogger.Debug('ConnectionTimeout', ConnectionTimeout);
  GlobalLogger.Debug('TCPConnectionTimeout', TCPConnectionTimeout);
  GlobalLogger.Debug('SyncTimeout', SyncTimeout);
  GlobalLogger.Debug('ComputerName', ComputerName);
  GlobalLogger.Debug('LDIndex', Devices.LDIndex);
  GlobalLogger.Debug('LockTimeout', LockTimeout);
  GlobalLogger.Debug('TCPPort', TCPPort);
  GlobalLogger.Debug('IPAddress', IPAddress);
  GlobalLogger.Debug('UseIPAddress', UseIPAddress);
  GlobalLogger.Debug('ConnectionType', ConnectionType);
  GlobalLogger.Debug('EscapeIP', EscapeIP);
  GlobalLogger.Debug('EscapePort', EscapePort);
  GlobalLogger.Debug('EscapeTimeout', EscapeTimeout);
  GlobalLogger.Debug('SysAdminPassword', SysAdminPassword);
  GlobalLogger.Debug('CardPayType', CardPayType);
  GlobalLogger.Debug('CardPayEnabled', CardPayEnabled);
  GlobalLogger.Debug('LogCommands', LogCommands);
  GlobalLogger.Debug('LogMethods', LogMethods);
  GlobalLogger.Debug('SaleError', SaleError);
  GlobalLogger.Debug('MobilePayEnabled', MobilePayEnabled);
  GlobalLogger.Debug('PayDepartment', PayDepartment);
  GlobalLogger.Debug('ParamsPageIndex', ParamsPageIndex);
  GlobalLogger.Debug('RealPayDepartment', RealPayDepartment);
  GlobalLogger.Debug('WaitForPrintingDelay', WaitForPrintingDelay);
  GlobalLogger.Debug('BufferingType', BufferingType);
  GlobalLogger.Debug('FeedAfterCut', FeedAfterCut);
  GlobalLogger.Debug('FeedLineCount', FeedLineCount);
  GlobalLogger.Debug('StatusCommand', StatusCommand);
  GlobalLogger.Debug('MaxAnsCount', MaxAnsCount);
  GlobalLogger.Debug('LogMaxFileSize', LogMaxFileSize);
  GlobalLogger.Debug('LogMaxFileCount', LogMaxFileCount);
  GlobalLogger.Debug('CodePage', CodePage);
  GlobalLogger.Debug('PrintJournalBeforeZReport', PrintJournalBeforeZReport);
  GlobalLogger.Debug('TranslationEnabled', TranslationEnabled);
  GlobalLogger.Debug('AdjustRITimeout', AdjustRITimeout);
  GlobalLogger.Debug('ReconnectPort', ReconnectPort);
  GlobalLogger.Debug('DoNotSendENQ', DoNotSendENQ);
end;

// Блокировки нужны для того, чтобы запись параметров в реестр
// была синхронизирована для разных экземпляров драйвера
function TFiscalPrinter.LoadParams(ALoadDevices: Boolean = True): Integer;
begin
  if TestMode then
  begin
    Result := ClearResult;
    Exit;
  end;

  try
    GlobalLock;
    try
      LoadDrvParams;
      if ALoadDevices then
        LoadDevices;

      WriteLogStart;
      FTranslation.Load;
    finally
      GlobalUnlock;
    end;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;

end;

{ Выполняет то же самое, что и LoadParams, но не читает значеие
  SaveSettingsType из DrvFRIni.xml }

function TFiscalPrinter.ReadParams: Integer;
begin
  try
    GlobalLock;
    try
      LoadDrvParams;
      LoadDevices;
    finally
      GlobalUnlock;
    end;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Блокировки нужны для того, чтобы запись параметров в реестр
// была синхронизирована для разных экземпляров драйвера

function TFiscalPrinter.SaveParams(ASaveDevices: Boolean = True): Integer;
begin
  if TestMode then
  begin
    Result := ClearResult;
    Exit;
  end;

  try
    GlobalLock;
    try
      SaveDrvParams; // Сохранение параметров
      if ASaveDevices then
        SaveDevices; // сохранение устройств
      WriteLogParameters;
      Plugins.SaveParams;
    finally
      GlobalUnlock;
    end;
    FTranslation.Save;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.ClosePort;
begin
  Logger.Debug('ClosePort');
  Lock;
  try
    Driver.ClosePort;
  finally
    Unlock;
  end;
end;

procedure TFiscalPrinter.DrvOpenCheck;
begin
  Logger.Debug('DrvOpenCheck');
  if DRV_SUCCESS(ResultCode) then
  begin
    Lock;
    try
      Driver.OpenCheck(ComNumber, FPassword);
    finally
      Unlock;
    end;
  end;
end;

procedure TFiscalPrinter.DrvCloseCheck;
begin
  Logger.Debug('DrvCloseCheck');
  if DRV_SUCCESS(ResultCode) then
  begin
    Lock;
    try
      Driver.CloseCheck(ComNumber);
    finally
      Unlock;
    end;
  end;
end;

function TFiscalPrinter.GetServerVersion: AnsiString;
begin
  Logger.Debug('GetServerVersion');
  Lock;
  try
    Result := Driver.ServerVersion;
  finally
    Unlock;
  end;
end;

function TFiscalPrinter.LockPort: Integer;
begin
  Logger.Debug('LockPort');
  try
    Lock;
    try
      Driver.LockPort;
    finally
      Unlock;
    end;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.UnlockPort: Integer;
begin
  Logger.Debug('UnlockPort');
  try
    Lock;
    try
      Driver.UnlockPort;
    finally
      Unlock;
    end;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.AdminUnlockPort: Integer;
begin
  try
    Lock;
    try
      Driver.AdminUnlockPort(ComNumber);
    finally
      Unlock;
    end;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.AdminUnlockPorts: Integer;
begin
  try
    Lock;
    try
      Driver.AdminUnlockPorts;
    finally
      Unlock;
    end;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{ ***************************************************************************** }
{
  {       Ожидание блокировки порта.
  {
  {       Процедура сделана для того, чтобы можно было
  {       ожидать завершение блокировки в методе Connect.
  {       Это нужно для одновременной работы с нескольких ККМ
  {
  {***************************************************************************** }

function TFiscalPrinter.DoLockPortTimeout: Integer;
var
  TickCount: DWORD;
  IsTimeout: Boolean;
begin
  IsTimeout := False;
  TickCount := GetTickCount;
  Result := LockPort;
  while (Result = E_PORTLOCKED) and (not IsTimeout) do
  begin
    Sleep(20);
    IsTimeout := GetTickCount > TickCount + LockTimeout;
    Result := LockPort;
  end;
end;

procedure TFiscalPrinter.LoadDevices;
resourcestring
  SDevicesReadError = 'Ошибка чтения устройств из реестра: ';
begin
  try
    Devices.Load(GetStorageType);
  except
    on E: Exception do
      // Пишем в лог
      Logger.Error(SDevicesReadError, E);
  end;
end;

procedure TFiscalPrinter.SaveDevices;
resourcestring
  SDevicesWriteError = 'Ошибка записи устройств в реестр: ';
begin
  try
    Devices.Save(GetStorageType);
  except
    on E: Exception do
      Logger.Error(SDevicesWriteError, E);
  end;
end;

procedure TFiscalPrinter.LoadDrvParams;
var
  Reg: TRegistry;
begin
  SetDefParams;
  Reg := TRegistry.Create;
  try
    Reg.Access := KEY_READ;
    Reg.RootKey := GetRegRootKey(GetStorageType);
    if Reg.OpenKey(REGSTR_KEY_PARAMS, False) then
    begin
      LoadRegParams(Reg);
    end;
  except
    on E: Exception do
      Logger.Error(SParamsReadError, E);
  end;
  Reg.Free;
end;

procedure TFiscalPrinter.LoadRegParams(Reg: TRegistry);
begin
  // ComLogFile
  if Reg.ValueExists('ComLogFile') then
    GlobalLogger.FileName := Reg.ReadString('ComLogFile');

  // LogOn
  if Reg.ValueExists('LogOn') then
    GlobalLogger.Enabled := Reg.ReadBool('LogOn');

  // BaudRate
  if Reg.ValueExists(REGSTR_VAL_BAUDRATE) then
    BaudRate := Reg.ReadInteger(REGSTR_VAL_BAUDRATE);

  // ComNumber
  if Reg.ValueExists(REGSTR_VAL_COMNUMBER) then
    ComNumber := Reg.ReadInteger(REGSTR_VAL_COMNUMBER);

  // ProtocolType
  if Reg.ValueExists(REGSTR_VAL_PROTOCOLTYPE) then
    ProtocolType := Reg.ReadInteger(REGSTR_VAL_PROTOCOLTYPE);

  // Timeout
  if Reg.ValueExists(REGSTR_VAL_TIMEOUT) then
    Timeout := Reg.ReadInteger(REGSTR_VAL_TIMEOUT);

  // PlainTransferMode
  if Reg.ValueExists(REGSTR_VAL_PLAINTRANSFERMODE) then
    PlainTransferMode := Reg.ReadInteger(REGSTR_VAL_PLAINTRANSFERMODE);

  // TLSMode
  if Reg.ValueExists(REGSTR_VAL_TLSMODE) then
    TLSMode := Reg.ReadInteger(REGSTR_VAL_TLSMODE);

  // ConnectionTimeout
  if Reg.ValueExists(REGSTR_VAL_CONNECTIONTIMEOUT) then
    ConnectionTimeout := Reg.ReadInteger(REGSTR_VAL_CONNECTIONTIMEOUT);

  // ConnectionTimeout
  if Reg.ValueExists(REGSTR_VAL_TCPCONNECTIONTIMEOUT) then
    TCPConnectionTimeout := Reg.ReadInteger(REGSTR_VAL_TCPCONNECTIONTIMEOUT);

  // SyncTimeout
  if Reg.ValueExists(REGSTR_VAL_SYNCTIMEOUT) then
    SyncTimeout := Reg.ReadInteger(REGSTR_VAL_SYNCTIMEOUT);

  // ComputerName
  if Reg.ValueExists(REGSTR_VAL_COMPUTERNAME) then
    ComputerName := Reg.ReadString(REGSTR_VAL_COMPUTERNAME);
  // CurrentDevice
  if Reg.ValueExists(REGSTR_VAL_CURRENTDEVICE) then
    Devices.LDIndex := Reg.ReadInteger(REGSTR_VAL_CURRENTDEVICE);
  //
  if Reg.ValueExists(REGSTR_VAL_LOCKTIMEOUT) then
    LockTimeout := Reg.ReadInteger(REGSTR_VAL_LOCKTIMEOUT);
  // TCPPort
  if Reg.ValueExists(REGSTR_VAL_TCPPORT) then
    TCPPort := Reg.ReadInteger(REGSTR_VAL_TCPPORT);
  // IPAddress
  if Reg.ValueExists(REGSTR_VAL_IPADDRESS) then
    IPAddress := Reg.ReadString(REGSTR_VAL_IPADDRESS);
  // UseIPAddress
  if Reg.ValueExists(REGSTR_VAL_USEIPADDRESS) then
    UseIPAddress := Reg.ReadBool(REGSTR_VAL_USEIPADDRESS);
  // Connection Type
  if Reg.ValueExists(REGSTR_VAL_CONNECTIONTYPE) then
    ConnectionType := Reg.ReadInteger(REGSTR_VAL_CONNECTIONTYPE);
  // EscapeIP
  if Reg.ValueExists(REGSTR_VAL_ESCAPEIP) then
    EscapeIP := Reg.ReadString(REGSTR_VAL_ESCAPEIP);
  // EscapePort
  if Reg.ValueExists(REGSTR_VAL_ESCAPEPORT) then
    EscapePort := Reg.ReadInteger(REGSTR_VAL_ESCAPEPORT);
  // EscapeTimeout
  if Reg.ValueExists(REGSTR_VAL_ESCAPETIMEOUT) then
    EscapeTimeout := Reg.ReadInteger(REGSTR_VAL_ESCAPETIMEOUT);
  // SysAdminPassword
  if Reg.ValueExists(REGSTR_VAL_SYSADMINPASSWORD) then
    SysAdminPassword := Reg.ReadInteger(REGSTR_VAL_SYSADMINPASSWORD);
  if Reg.ValueExists('CardPayType') then
    CardPayType := Reg.ReadInteger('CardPayType');
  if Reg.ValueExists('CardPayEnabled') then
    CardPayEnabled := Reg.ReadBool('CardPayEnabled');
  if Reg.ValueExists('LogCommands') then
    LogCommands := Reg.ReadBool('LogCommands');
  if Reg.ValueExists('LogMethods') then
    LogMethods := Reg.ReadBool('LogMethods');
  if Reg.ValueExists('SaleError') then
    SaleError := Reg.ReadBool('SaleError');
  if Reg.ValueExists('MobilePayEnabled') then
    MobilePayEnabled := Reg.ReadBool('MobilePayEnabled');
  if Reg.ValueExists('PayDepartment') then
    PayDepartment := Reg.ReadInteger('PayDepartment');
  if Reg.ValueExists('ParamsPageIndex') then
    ParamsPageIndex := Reg.ReadInteger('ParamsPageIndex');
  if Reg.ValueExists('RealPayDepartment') then
    RealPayDepartment := Reg.ReadInteger('RealPayDepartment');
  if Reg.ValueExists('WaitForPrintingDelay') then
    WaitForPrintingDelay := Reg.ReadInteger('WaitForPrintingDelay');
  if Reg.ValueExists('BufferingType') then
    BufferingType := Reg.ReadInteger('BufferingType');
  if Reg.ValueExists('CommandRetryCount') then
    CommandRetryCount := Reg.ReadInteger('CommandRetryCount');
  if Reg.ValueExists('FeedAfterCut') then
    FeedAfterCut := Reg.ReadBool('FeedAfterCut');
  if Reg.ValueExists('FeedLineCount') then
    FeedLineCount := Reg.ReadInteger('FeedLineCount');

  if Reg.ValueExists('StatusCommand') then
    StatusCommand := Reg.ReadInteger('StatusCommand');
  if Reg.ValueExists('MaxAnsCount') then
    MaxAnsCount := Reg.ReadInteger('MaxAnsCount');

  if Reg.ValueExists('LogMaxFileSize') then
    LogMaxFileSize := Reg.ReadInteger('LogMaxFileSize');

  if Reg.ValueExists('LogMaxFileCount') then
    LogMaxFileCount := Reg.ReadInteger('LogMaxFileCount');

  if Reg.ValueExists('CodePage') then
    CodePage := Reg.ReadInteger('CodePage');

  if Reg.ValueExists('PrintJournalBeforeZReport') then
    PrintJournalBeforeZReport := Reg.ReadBool('PrintJournalBeforeZReport');

  if Reg.ValueExists('TranslationEnabled') then
    TranslationEnabled := Reg.ReadBool('TranslationEnabled');

  if Reg.ValueExists('ModelIndex') then
    ModelIndex := Reg.ReadInteger('ModelIndex');

  if Reg.ValueExists('AdjustRITimeout') then
    AdjustRITimeout := Reg.ReadBool('AdjustRITimeout');

  if Reg.ValueExists('ReconnectPort') then
    ReconnectPort := Reg.ReadBool('ReconnectPort');

  if Reg.ValueExists('DoNotSendENQ') then
    DoNotSendENQ := Reg.ReadBool('DoNotSendENQ');

  if Reg.ValueExists('SwapBytesMode') then
    SwapBytesMode := Reg.ReadInteger('SwapBytesMode');

  if Reg.ValueExists('AutoSensorValues') then
    AutoSensorValues := Reg.ReadBool('AutoSensorValues');

  if Reg.ValueExists('AutoStartSearch') then
    AutoStartSearch := Reg.ReadBool('AutoStartSearch');

  if Reg.ValueExists('SearchTimeout') then
    SearchTimeout := Reg.ReadInteger('SearchTimeout');

  if Reg.ValueExists('MaxCmdCount') then
    MaxCmdCount := Reg.ReadInteger('MaxCmdCount');

  if Reg.ValueExists('RequestErrorDescription') then
    RequestErrorDescription := Reg.ReadBool('RequestErrorDescription');

  if Reg.ValueExists('OFDEnabled') then
    OFDEnabled := Reg.ReadBool('OFDEnabled');

  if Reg.ValueExists('AutoOFDExchange') then
    AutoOFDExchange := Reg.ReadBool('AutoOFDExchange');

  if Reg.ValueExists('OFDPollPeriod') then
    OFDPollPeriod := Reg.ReadInteger('OFDPollPeriod');

  if Reg.ValueExists('OFDPort') then
    OFDPort := Reg.ReadInteger('OFDPort');

  if Reg.ValueExists('OFDServer') then
    OFDServer := Reg.ReadString('OFDServer');

  if Reg.ValueExists('AutoOpenSession') then
    AutoOpenSession := Reg.ReadBool('AutoOpenSession');

  if Reg.ValueExists('ICSEnabled') then
    ICSEnabled := Reg.ReadBool('ICSEnabled');

  if Reg.ValueExists('ICSPollPeriod') then
    ICSPollPeriod := Reg.ReadInteger('ICSPollPeriod');

  if Reg.ValueExists('OFDReadTimeout') then
    OFDReadTimeout := Reg.ReadInteger('OFDReadTimeout');

  if Reg.ValueExists('DelayOnDisconnect') then
    DelayOnDisconnect := Reg.ReadInteger('DelayOnDisconnect');

  if Reg.ValueExists('WrapStrings') then
    ICSEnabled := Reg.ReadBool('WrapStrings');

  if Reg.ValueExists('AuthKeyStorageType') then
    AuthKeyStorageType := Reg.ReadInteger('AuthKeyStorageType');

  if Reg.ValueExists('ItemNameLength') then
    ItemNameLength := Reg.ReadInteger('ItemNameLength');

  if Reg.ValueExists('FWUpdateFFDParams') then
    FWUpdateFFDParams := Reg.ReadInteger('FWUpdateFFDParams');

  if Reg.ValueExists('FWUpdateFFDWaitInterval') then
    FWUpdateFFDWaitInterval := Reg.ReadInteger('FWUpdateFFDWaitInterval');

  if Reg.ValueExists('FWUpdateSearchTimeout') then
    FWUpdateSearchTimeout := Reg.ReadInteger('FWUpdateSearchTimeout');

  if Reg.ValueExists('FWUpdDelayAfterReboot') then
    FWUpdDelayAfterReboot := Reg.ReadInteger('FWUpdDelayAfterReboot');

  if Reg.ValueExists('FWUpdDelayBeforeSearch') then
    FWUpdDelayBeforeSearch := Reg.ReadInteger('FWUpdDelayBeforeSearch');

  if Reg.ValueExists('FWUpdDelayBeforeWrite') then
    FWUpdDelayBeforeWrite := Reg.ReadInteger('FWUpdDelayBeforeWrite');

  if Reg.ValueExists('FWUpdWriteTimeout') then
    FWUpdWriteTimeout := Reg.ReadInteger('FWUpdWriteTimeout');

  if Reg.ValueExists('FWUpdPrintStatus') then
    FWUpdPrintStatus := Reg.ReadBool('FWUpdPrintStatus');

  if Reg.ValueExists('MCScannerAutoSendMCStatus') then
    MCScannerAutoSendMCStatus := Reg.ReadBool('MCScannerAutoSendMCStatus');

  if Reg.ValueExists('MCScannerComNumber') then
    MCScannerComNumber := Reg.ReadInteger('MCScannerComNumber');

  if Reg.ValueExists('PayManServerURL') then
    PayManServerURL := Reg.ReadString('PayManServerURL');

  if Reg.ValueExists('PayManUseQRDisplay') then
    PayManUseQRDisplay := Reg.ReadBool('PayManUseQRDisplay');

  if Reg.ValueExists('QRDisplayPortNumber') then
    QRDisplayPortNumber := Reg.ReadInteger('QRDisplayPortNumber');

  if Reg.ValueExists('PayManCashRegisterCode') then
    PayManCashRegisterCode := Reg.ReadString('PayManCashRegisterCode');

  if Reg.ValueExists('Payman_Sbp_Login') then
    FSbpAuthorize.Login := Reg.ReadString('Payman_Sbp_Login');

  if Reg.ValueExists('Payman_Sbp_Password') then
    FSbpAuthorize.Password := DecryptPass(Reg.ReadString('Payman_Sbp_Password'));

  if Reg.ValueExists('Payman_Sbp_INN') then
    FSbpAuthorize.INN := Reg.ReadString('Payman_Sbp_INN');

  if Reg.ValueExists('CorrectDateTimeOnOpenSession') then
    CorrectDateTimeOnOpenSession := Reg.ReadBool('CorrectDateTimeOnOpenSession');

  if Reg.ValueExists('FWUpdateSaveCashCounter') then
    FWUpdateSaveCashCounter := Reg.ReadBool('FWUpdateSaveCashCounter');

  if Reg.ValueExists('DisconnectOnIdle') then
    DisconnectOnIdle := Reg.ReadBool('DisconnectOnIdle');

  if Reg.ValueExists('DisconnectOnIdleTimeout') then
    DisconnectOnIdleTimeout := Reg.ReadInteger('DisconnectOnIdleTimeout');

  // if Reg.ValueExists('PPPComNumber') then
  // PPPComNumber := Reg.ReadInteger('PPPComNumber');

  // if Reg.ValueExists('PPPServiceEnabled') then
  // PPPServiceEnabled := Reg.ReadBool('PPPServiceEnabled');
end;

procedure TFiscalPrinter.SaveDrvParams;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := GetRegRootKey(GetStorageType);
    if Reg.OpenKey(REGSTR_KEY_PARAMS, True) then
    begin
      SaveRegParams(Reg);
    end;
  except
    on E: Exception do
      Logger.Error(SParamsWriteError, E);
  end;
  Reg.Free;
end;

procedure TFiscalPrinter.SaveRegParams(Reg: TRegistry);
begin
  // Лог
  Reg.WriteBool('LogOn', GlobalLogger.Enabled);
  Reg.WriteString('ComLogFile', GlobalLogger.FileName);
  Reg.WriteInteger(REGSTR_VAL_TIMEOUT, Timeout);
  Reg.WriteInteger(REGSTR_VAL_PLAINTRANSFERMODE, PlainTransferMode);
  Reg.WriteInteger(REGSTR_VAL_TLSMODE, TLSMode);
  Reg.WriteInteger(REGSTR_VAL_CONNECTIONTIMEOUT, ConnectionTimeout);
  Reg.WriteInteger(REGSTR_VAL_TCPCONNECTIONTIMEOUT, TCPConnectionTimeout);
  Reg.WriteInteger(REGSTR_VAL_SYNCTIMEOUT, SyncTimeout);
  Reg.WriteInteger(REGSTR_VAL_BAUDRATE, BaudRate);
  Reg.WriteInteger(REGSTR_VAL_COMNUMBER, ComNumber);
  Reg.WriteInteger(REGSTR_VAL_PROTOCOLTYPE, ProtocolType);
  Reg.WriteString(REGSTR_VAL_COMPUTERNAME, ComputerName);
  Reg.WriteInteger(REGSTR_VAL_CURRENTDEVICE, Devices.LDIndex);
  Reg.WriteInteger(REGSTR_VAL_LOCKTIMEOUT, LockTimeout);
  //
  Reg.WriteInteger(REGSTR_VAL_TCPPORT, TCPPort);
  Reg.WriteString(REGSTR_VAL_IPADDRESS, IPAddress);
  Reg.WriteBool(REGSTR_VAL_USEIPADDRESS, UseIPAddress);
  Reg.WriteInteger(REGSTR_VAL_CONNECTIONTYPE, ConnectionType);
  Reg.WriteString(REGSTR_VAL_ESCAPEIP, EscapeIP);
  Reg.WriteInteger(REGSTR_VAL_ESCAPEPORT, EscapePort);
  Reg.WriteInteger(REGSTR_VAL_ESCAPETIMEOUT, EscapeTimeout);
  Reg.WriteInteger(REGSTR_VAL_SYSADMINPASSWORD, SysAdminPassword);
  Reg.WriteInteger('CardPayType', CardPayType);
  Reg.WriteBool('CardPayEnabled', CardPayEnabled);
  Reg.WriteBool('LogCommands', LogCommands);
  Reg.WriteBool('LogMethods', LogMethods);
  Reg.WriteBool('SaleError', SaleError);
  Reg.WriteBool('MobilePayEnabled', MobilePayEnabled);
  Reg.WriteInteger('PayDepartment', PayDepartment);
  Reg.WriteInteger('ParamsPageIndex', ParamsPageIndex);
  Reg.WriteInteger('RealPayDepartment', RealPayDepartment);
  Reg.WriteInteger('WaitForPrintingDelay', WaitForPrintingDelay);
  Reg.WriteInteger('BufferingType', BufferingType);
  Reg.WriteInteger('CommandRetryCount', CommandRetryCount);
  Reg.WriteBool('FeedAfterCut', FeedAfterCut);
  Reg.WriteInteger('FeedLineCount', FeedLineCount);
  Reg.WriteInteger('StatusCommand', Ord(StatusCommand));
  Reg.WriteInteger('MaxAnsCount', MaxAnsCount);
  Reg.WriteInteger('LogMaxFileCount', LogMaxFileCount);
  Reg.WriteInteger('LogMaxFileSize', LogMaxFileSize);
  Reg.WriteInteger('CodePage', CodePage);
  Reg.WriteBool('PrintJournalBeforeZReport', PrintJournalBeforeZReport);
  Reg.WriteBool('TranslationEnabled', TranslationEnabled);
  Reg.WriteInteger('ModelIndex', ModelIndex);
  Reg.WriteBool('AdjustRITimeout', AdjustRITimeout);
  Reg.WriteBool('ReconnectPort', ReconnectPort);
  Reg.WriteBool('DoNotSendENQ', DoNotSendENQ);
  Reg.WriteInteger('SwapBytesMode', SwapBytesMode);
  Reg.WriteBool('AutoSensorValues', AutoSensorValues);
  Reg.WriteBool('AutoStartSearch', AutoStartSearch);
  Reg.WriteInteger('SearchTimeout', SearchTimeout);
  Reg.WriteInteger('MaxCmdCount', MaxCmdCount);
  Reg.WriteBool('RequestErrorDescription', RequestErrorDescription);
  Reg.WriteBool('OFDEnabled', OFDEnabled);
  Reg.WriteBool('AutoOFDExchange', AutoOFDExchange);
  Reg.WriteInteger('OFDPollPeriod', OFDPollPeriod);
  Reg.WriteInteger('OFDPort', OFDPort);
  Reg.WriteString('OFDServer', OFDServer);
  Reg.WriteBool('AutoOpenSession', AutoOpenSession);
  Reg.WriteBool('ICSEnabled', ICSEnabled);
  Reg.WriteInteger('ICSPollPeriod', ICSPollPeriod);
  Reg.WriteInteger('OFDReadTimeout', OFDReadTimeout);
  Reg.WriteInteger('DelayOnDisconnect', DelayOnDisconnect);
  Reg.WriteBool('WrapStrings', WrapStrings);
  Reg.WriteInteger('AuthKeyStorageType', AuthKeyStorageType);
  Reg.WriteInteger('ItemNameLength', ItemNameLength);
  Reg.WriteInteger('FWUpdateSearchTimeout', FWUpdateSearchTimeout);
  Reg.WriteInteger('FWUpdDelayAfterReboot', FWUpdDelayAfterReboot);
  Reg.WriteInteger('FWUpdDelayBeforeSearch', FWUpdDelayBeforeSearch);
  Reg.WriteInteger('FWUpdDelayBeforeWrite', FWUpdDelayBeforeWrite);
  Reg.WriteInteger('FWUpdWriteTimeout', FWUpdWriteTimeout);
  Reg.WriteInteger('FWUpdateFFDParams', FWUpdateFFDParams);
  Reg.WriteInteger('FWUpdateFFDWaitInterval', FWUpdateFFDWaitInterval);
  Reg.WriteBool('FWUpdPrintStatus', FWUpdPrintStatus);
  Reg.WriteBool('MCScannerAutoSendMCStatus', MCScannerAutoSendMCStatus);
  Reg.WriteInteger('MCScannerComNumber', MCScannerComNumber);

  Reg.WriteString('PayManServerURL', PayManServerURL);
  Reg.WriteBool('PayManUseQRDisplay', PayManUseQRDisplay);
  Reg.WriteInteger('QRDisplayPortNumber', QRDisplayPortNumber);
  Reg.WriteString('PayManCashRegisterCode', PayManCashRegisterCode);

  Reg.WriteString('Payman_Sbp_Login', FSbpAuthorize.Login);
  Reg.WriteString('Payman_Sbp_Password', EncryptPass(FSbpAuthorize.Password));
  Reg.WriteString('Payman_Sbp_INN', FSbpAuthorize.INN);
  Reg.WriteBool('CorrectDateTimeOnOpenSession', CorrectDateTimeOnOpenSession);
  Reg.WriteBool('FWUpdateSaveCashCounter', FWUpdateSaveCashCounter);

  Reg.WriteBool('DisconnectOnIdle', DisconnectOnIdle);
  Reg.WriteInteger('DisconnectOnIdleTimeout', DisconnectOnIdleTimeout);

  // Reg.WriteInteger('PPPComNumber', PPPComNumber);
  // Reg.WriteBool('PPPServiceEnabled', PPPServiceEnabled);
end;

function TFiscalPrinter.GetUModelValue: Integer;
begin
  if not FGetDeviceMetrics then
  begin
    if DoSend(#$FC) <> 0 then
      RaiseError(ResultCode, ResultCodeDescription);
    FGetDeviceMetrics := True;
  end;
  Result := UModel;
end;

function TFiscalPrinter.GetFontType: Integer;
begin
  if not (FontType in [0..255]) then
    InvalidProp('FontType');
  Result := FontType;
end;

function TFiscalPrinter.GetQuantityFactor: Integer;
begin
  if QuantityFactor = 0 then
    GetModel;
  Result := QuantityFactor;
end;

function TFiscalPrinter.GetPrintingAlignment: Integer;
begin
  if (PrintingAlignment < 0) or (PrintingAlignment > $FF) then
    InvalidProp('PrintingAlignment');
  Result := PrintingAlignment;
end;

function TFiscalPrinter.GetSlipWidth: Integer;
begin
  if (SlipDocumentWidth < 0) or (SlipDocumentWidth > $FFFF) then
    InvalidProp('SlipWidth');
  Result := SlipDocumentWidth;
end;

function TFiscalPrinter.GetSlipLength: Integer;
begin
  if (SlipDocumentLength < 0) or (SlipDocumentLength > $FFFF) then
    InvalidProp('SlipLength');
  Result := SlipDocumentLength;
end;

function TFiscalPrinter.GetStringNumber: Integer;
begin
  if (StringNumber < 0) or (StringNumber > $FF) then
    InvalidProp('StringNumber');
  Result := StringNumber;
end;

function TFiscalPrinter.GetOperationBlockFirstString: Integer;
begin
  if not (OperationBlockFirstString in [0..255]) then
    InvalidProp('OperationBlockFirstString');
  Result := OperationBlockFirstString;
end;

function TFiscalPrinter.GetExciseCode: Integer;
begin
  if (ExciseCode < 0) or (ExciseCode > 255) then
    InvalidProp('ExciseCode');
  Result := ExciseCode;
end;

function TFiscalPrinter.GetTax1: Integer;
begin
  if (Tax1 < 0) or (Tax1 > $FF) then
    InvalidProp('Tax1');
  Result := Tax1;
end;

function TFiscalPrinter.GetTax2: Integer;
begin
  if (Tax2 < 0) or (Tax2 > $FF) then
    InvalidProp('Tax2');
  Result := Tax2;
end;

function TFiscalPrinter.GetTax3: Integer;
begin
  if (Tax3 < 0) or (Tax3 > $FF) then
    InvalidProp('Tax3');
  Result := Tax3;
end;

function TFiscalPrinter.GetTax4: Integer;
begin
  if (Tax4 < 0) or (Tax4 > $FF) then
    InvalidProp('Tax4');
  Result := Tax4;
end;

function TFiscalPrinter.GetDiscountValue: AnsiString;
begin
  if (DiscountValue < 0) then
    InvalidProp('DiscountValue');
  Result := AmountToBin(DiscountValue, 5);
end;

function TFiscalPrinter.GetChargeValue: AnsiString;
begin
  if (ChargeValue < 0) then
    InvalidProp('ChargeValue');
  Result := AmountToBin(ChargeValue, 5);
end;

function TFiscalPrinter.GetTaxValue: AnsiString;
begin
  if (TaxValue < 0) then
    InvalidProp('TaxValue');
  Result := AmountToBin(TaxValue, 5);
end;

function TFiscalPrinter.GetTaxValue1: AnsiString;
begin
  if (TaxValue1 < 0) then
    InvalidProp('TaxValue1');
  Result := AmountToBin(TaxValue1, 5);
end;

function TFiscalPrinter.GetTaxValue2: AnsiString;
begin
  if (TaxValue2 < 0) then
    InvalidProp('TaxValue2');
  Result := AmountToBin(TaxValue2, 5);
end;

function TFiscalPrinter.GetTaxValue3: AnsiString;
begin
  if (TaxValue3 < 0) then
    InvalidProp('TaxValue3');
  Result := AmountToBin(TaxValue3, 5);
end;

function TFiscalPrinter.GetTaxValue4: AnsiString;
begin
  if (TaxValue4 < 0) then
    InvalidProp('TaxValue4');
  Result := AmountToBin(TaxValue4, 5);
end;

function TFiscalPrinter.GetTaxValue5: AnsiString;
begin
  if (TaxValue5 < 0) then
    InvalidProp('TaxValue5');
  Result := AmountToBin(TaxValue5, 5);
end;

function TFiscalPrinter.GetTaxValue6: AnsiString;
begin
  if (TaxValue6 < 0) then
    InvalidProp('TaxValue6');
  Result := AmountToBin(TaxValue6, 5);
end;

function TFiscalPrinter.GetTaxValue7: AnsiString;
begin
  if (TaxValue7 < 0) then
    InvalidProp('TaxValue7');
  Result := AmountToBin(TaxValue7, 5);
end;

function TFiscalPrinter.GetTaxValue8: AnsiString;
begin
  if (TaxValue8 < 0) then
    InvalidProp('TaxValue8');
  Result := AmountToBin(TaxValue8, 5);
end;

function TFiscalPrinter.GetTaxValue9: AnsiString;
begin
  if (TaxValue9 < 0) then
    InvalidProp('TaxValue9');
  Result := AmountToBin(TaxValue9, 5);
end;

function TFiscalPrinter.GetTaxValue10: AnsiString;
begin
  if (TaxValue10 < 0) then
    InvalidProp('TaxValue10');
  Result := AmountToBin(TaxValue10, 5);
end;

function TFiscalPrinter.GetSumm1: AnsiString;
begin
  if (Summ1 < 0) then
    InvalidProp('Summ1');
  Result := AmountToBin(Summ1, 5);
end;

function TFiscalPrinter.GetTaxValue_: AnsiString;
begin
  if not TaxValueEnabled then
    Result := #$FF#$FF#$FF#$FF#$FF
  else
    Result := GetTaxValue;

end;

function TFiscalPrinter.GetTaxValue1_: AnsiString;
begin
  if not TaxValue1Enabled then
    Result := #$FF#$FF#$FF#$FF#$FF
  else
    Result := GetTaxValue1;
end;

function TFiscalPrinter.GetTaxValue2_: AnsiString;
begin
  if not TaxValue2Enabled then
    Result := #$FF#$FF#$FF#$FF#$FF
  else
    Result := GetTaxValue2;
end;

function TFiscalPrinter.GetTaxValue3_: AnsiString;
begin
  if not TaxValue3Enabled then
    Result := #$FF#$FF#$FF#$FF#$FF
  else
    Result := GetTaxValue3;
end;

function TFiscalPrinter.GetTaxValue4_: AnsiString;
begin
  if not TaxValue4Enabled then
    Result := #$FF#$FF#$FF#$FF#$FF
  else
    Result := GetTaxValue4;
end;

function TFiscalPrinter.GetTaxValue5_: AnsiString;
begin
  if not TaxValue5Enabled then
    Result := #$FF#$FF#$FF#$FF#$FF
  else
    Result := GetTaxValue5;
end;

function TFiscalPrinter.GetTaxValue6_: AnsiString;
begin
  if not TaxValue6Enabled then
    Result := #$FF#$FF#$FF#$FF#$FF
  else
    Result := GetTaxValue6;
end;

function TFiscalPrinter.GetSumm1_: AnsiString;
begin
  if not Summ1Enabled then
    Result := #$FF#$FF#$FF#$FF#$FF
  else
    Result := GetSumm1;
end;

function TFiscalPrinter.GetSumm2: AnsiString;
begin
  if (Summ2 < 0) then
    InvalidProp('Summ2');
  Result := AmountToBin(Summ2, 5);
end;

function TFiscalPrinter.GetSumm3: AnsiString;
begin
  if (Summ3 < 0) then
    InvalidProp('Summ3');
  Result := AmountToBin(Summ3, 5);
end;

function TFiscalPrinter.GetSumm4: AnsiString;
begin
  if (Summ4 < 0) then
    InvalidProp('Summ4');
  Result := AmountToBin(Summ4, 5);
end;

function TFiscalPrinter.GetSumm5: AnsiString;
begin
  if (Summ5 < 0) then
    InvalidProp('Summ5');
  Result := AmountToBin(Summ5, 5);
end;

function TFiscalPrinter.GetSumm6: AnsiString;
begin
  if (Summ6 < 0) then
    InvalidProp('Summ6');
  Result := AmountToBin(Summ6, 5);
end;

function TFiscalPrinter.GetSumm7: AnsiString;
begin
  if (Summ7 < 0) then
    InvalidProp('Summ7');
  Result := AmountToBin(Summ7, 5);
end;

function TFiscalPrinter.GetSumm8: AnsiString;
begin
  if (Summ8 < 0) then
    InvalidProp('Summ8');
  Result := AmountToBin(Summ8, 5);
end;

function TFiscalPrinter.GetSumm9: AnsiString;
begin
  if (Summ9 < 0) then
    InvalidProp('Summ9');
  Result := AmountToBin(Summ9, 5);
end;

function TFiscalPrinter.GetSumm10: AnsiString;
begin
  if (Summ10 < 0) then
    InvalidProp('Summ10');
  Result := AmountToBin(Summ10, 5);
end;

function TFiscalPrinter.GetSumm11: AnsiString;
begin
  if (Summ11 < 0) then
    InvalidProp('Summ11');
  Result := AmountToBin(Summ11, 5);
end;

function TFiscalPrinter.GetSumm12: AnsiString;
begin
  if (Summ12 < 0) then
    InvalidProp('Summ12');
  Result := AmountToBin(Summ12, 5);
end;

function TFiscalPrinter.GetSumm13: AnsiString;
begin
  if (Summ13 < 0) then
    InvalidProp('Summ13');
  Result := AmountToBin(Summ13, 5);
end;

function TFiscalPrinter.GetSumm14: AnsiString;
begin
  if (Summ14 < 0) then
    InvalidProp('Summ14');
  Result := AmountToBin(Summ14, 5);
end;

function TFiscalPrinter.GetSumm15: AnsiString;
begin
  if (Summ15 < 0) then
    InvalidProp('Summ15');
  Result := AmountToBin(Summ15, 5);
end;

function TFiscalPrinter.GetSumm16: AnsiString;
begin
  if (Summ16 < 0) then
    InvalidProp('Summ16');
  Result := AmountToBin(Summ16, 5);
end;

function TFiscalPrinter.GetCustomerCode: Byte;
begin
  if (CustomerCode < 0) or (CustomerCode > 255) then
    InvalidProp('CustomerCode');
  Result := CustomerCode;
end;

function TFiscalPrinter.GetPermitActivizatonCode: Integer;
begin
  if (PermitActivizationCode < 0) or (PermitActivizationCode >= 999999) then
    InvalidProp('PermitActivizationCode');
  Result := PermitActivizationCode;
end;

function TFiscalPrinter.GetLineNumber: Integer;
begin
  if (LineNumber < 0) or (LineNumber > $FFFF) then
    InvalidProp('LineNumber');
  Result := LineNumber;
end;

function TFiscalPrinter.ValidKPKNumber: Boolean;
begin
  Result := (KPKNumber >= 0) and (KPKNumber <= 99999999);
end;

function TFiscalPrinter.GetCheckType: Integer;
begin
  if (CheckType < 0) or (CheckType > $FF) then
    InvalidProp('CheckType');
  Result := CheckType;
end;

function TFiscalPrinter.GetDepartment: Integer;
begin
  if (Department < 0) or (Department > $FF) then
    InvalidProp('Department');
  Result := Department;
end;

function TFiscalPrinter.GetReportType: Integer;
begin
  Result := BoolToInt[ReportType];
end;

function TFiscalPrinter.GetDiscountOnCheck: AnsiString;
begin
  if abs(DiscountOnCheck) > 100 then
    InvalidProp('DiscountOnCheck');
  Result := Int64ToECRS(Round2(DiscountOnCheck * 100), 2);
end;

function TFiscalPrinter.GetDrawerNumber: Integer;
begin
  if (DrawerNumber < 0) or (DrawerNumber > $FF) then
    InvalidProp('DrawerNumber');
  Result := DrawerNumber;
end;

function TFiscalPrinter.GetFirstSessionNumber: Integer;
begin
  if (FirstSessionNumber < 0) or (FirstSessionNumber > $FFFF) then
    InvalidProp('FirstSessionNumber');
  Result := FirstSessionNumber;
end;

function TFiscalPrinter.GetLastSessionNumber: Integer;
begin
  if (LastSessionNumber < 0) or (LastSessionNumber > $FFFF) then
    InvalidProp('LastSessionNumber');
  Result := LastSessionNumber;
end;

function TFiscalPrinter.GetPrice: AnsiString;
begin
  Result := AmountToBin(Price, 5);
end;

function TFiscalPrinter.GetQuantity: AnsiString;
begin
  if (Quantity < 0) then
    InvalidProp('Quantity');
  if Quantity > 200000000 then
    InvalidProp('Quantity');
  Result := IntToBin(Round2(Quantity * GetQuantityFactor), 5);
end;

function TFiscalPrinter.GetQuantity6: AnsiString;
begin
  if (Quantity < 0) then
    InvalidProp('Quantity');
  if Quantity > 200000000 then
    InvalidProp('Quantity');

  if DivisionalQuantity then
  begin
    Logger.Debug('DivisionalQuantity = True, set Quantity to "1"');
    Result := IntToBin(Round2(1000000), 6)
  end else
    Result := IntToBin(Round2(Quantity * 1000000), 6);
end;

function TFiscalPrinter.NotSupported: Integer;
begin
  Result := E_NOTSUPPORTED;
  ResultCode := E_NOTSUPPORTED;
  ResultCodeDescription := GetRes(@SDriverNotSupported);
end;

{ Получаем таймаут для команды }

function TFiscalPrinter.GetCmdTimeout(Code: Word): Integer;
var
  Command: TPrinterCommand;
begin
  if UseCommandTimeout then
  begin
    Result := CommandTimeout;
  end else
  begin
    if (FModel = dmUnknown) or (TimeoutsUsing = 1) then
    begin
      Command := Commands.ItemByCode(Code);
      if Command <> nil then
        Result := Command.Timeout
      else
        Result := GetCommandTimeout(Code);
    end else
    begin
      Result := GetCommandTimeout(Code);
    end;
  end;
end;

function TFiscalPrinter.CheckStatus: Integer;
begin
  Result := ClearResult;
end;

// КЯ: Продажа по коду товара
function TFiscalPrinter.BuyByWare_CashCore: Integer;
var
  Data: AnsiString;
begin
  try
    Result := CheckStatus;
    if DRV_SUCCESS(Result) then
    begin
      Data := #$81 + FPassw + GetQuantity + GetPrice + AnsiChar($FF) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetWareCodeStr;
      Result := Send(Data);
      DrvOpenCheck;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.Buy: Integer;
var
  Data: AnsiString;
begin
  try
    Result := SafeOpenSession;
    if Result <> 0 then
      Exit;

    // КЯ: Продажа по коду товара
    if PrinterModel.CapCashCore and UseWareCode then
    begin
      Result := BuyByWare_CashCore;
      Exit;
    end;

    Result := CheckStatus;
    if DRV_SUCCESS(Result) then
    begin
      UpdateStringForPrinting;
      Data := #$81 + FPassw + GetQuantity + GetPrice + AnsiChar(GetDepartment) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(24);
      Result := Send(Data);
      DrvOpenCheck;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.StoreParams: Integer;
var
  S: AnsiString;
  StrLen: Integer;
  PriceStr: AnsiString;
  DataSize: Integer;
  QuantityStr: AnsiString;
begin
  Result := 0;
  DataSize := ModelToDataSize(GetModel);
  if not TestMode then
  begin
    Result := GetCharLineLength;
    if not DRV_SUCCESS(Result) then
      Exit;
    DataSize := CharLineLength;
  end;
  Str(Quantity: 15: 6, QuantityStr);
  if GetSummFactor = 100 then
    Str(Price: 11: 2, PriceStr)
  else
    Str(Price: 11: 0, PriceStr);

  S := Trim(QuantityStr) + ' X ' + Trim(PriceStr);
  StrLen := Length(S);
  S := Format('%-*s %*s', [DataSize - StrLen - 1, Copy(GetPrintString, 1, DataSize - StrLen - 1), StrLen, S]);
  // сохранем StringForPrinting Quantity Price
  OldPrice := Price;
  OldString := StringForPrinting;
  OldQuantity := Quantity;
  // изменяем
  StringForPrinting := S;
  Quantity := 1;
  // округляем до шести знаков  количество
  Price := Round2(((Round2(OldQuantity * 1000000) / 1000000) * (Round2(OldPrice * GetSummFactor)))) / GetSummFactor;
end;

procedure TFiscalPrinter.RestoreParams;
begin
  Price := OldPrice;
  StringForPrinting := OldString;
  Quantity := OldQuantity;
end;

function TFiscalPrinter.BuyEx: Integer;
begin
  Result := StoreParams;
  if not DRV_SUCCESS(Result) then
    Exit;
  Result := Buy;
  RestoreParams;
  DrvOpenCheck;
end;

// Аннулирование чека

function TFiscalPrinter.CancelCheck: Integer;
begin
  Result := Send(#$88 + FPassw);
end;

// Внесение

function TFiscalPrinter.CashIncome: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$50 + FPassw + GetSumm1;
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Выплата

function TFiscalPrinter.CashOutcome: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$51 + FPassw + GetSumm1;
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// надбавка

function TFiscalPrinter.Charge: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$87 + FPassw + GetSumm1 + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(14);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// запрос подытога чека

function TFiscalPrinter.CheckSubTotal: Integer;
begin
  try
    Result := Send(#$89 + FPassw);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.SendPluginMessage(PluginMessage: Longint; PluginParams: AnsiString);
begin
  { !!! }
end;

function TFiscalPrinter.CloseCheck: Integer;
var
  Data: AnsiString;
begin
  { ///!!!
    if not TestMode then
    begin
    Result := GetECRStatus;
    if Result <> 0 then Exit;
    end; }

  try
    Data := #$85 + FPassw + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetDiscountOnCheck + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(31);

    Result := SendAuth(Data);
    DrvCloseCheck;

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Закрытие чека с возвратом КПК

function TFiscalPrinter.CloseCheckWithKPK: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$CC + FPassw + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetDiscountOnCheck + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(31);

    Result := Send(Data);
    DrvCloseCheck;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{ ***************************************************************************** }
{
  {  Выполнение подключения. Вынесено в отдельный виртуальный метод для
  {  того, чтобы можно было сделать тест.
  {
  {***************************************************************************** }

function TFiscalPrinter.DoConnect: Integer;
begin
  Result := GetDeviceMetrics;
  if Result = 0 then
    Result := GetECRStatus;
  if Result < 0 then
    ClosePort;
  FConnected := Result = 0;
  if FConnected then
  begin
    Logger.Debug('Connected');
    if PluginsEnabled then
      Plugins.Connect;
  end;
end;

{ ***************************************************************************** }
{
  {  Подключение. Если было подключение, выполняется отключение.
  {
  {***************************************************************************** }

function TFiscalPrinter.Connect: Integer;
begin
  Result := ClearResult;
  try
    if not FConnected then
    begin
      Disconnect;
      Result := DoConnect;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Ожидание подключения

function TFiscalPrinter.WaitConnection: Integer;
var
  T: Cardinal;
begin
  T := GetTickCount;
  while True do
  begin
    Disconnect;
    Result := Connect;
    if (GetTickCount - T) >= ConnectionTimeout then
      Exit;
    if Result = E_NOHARDWARE then
      Continue
    else
      Exit;
  end;
end;

// Продолжение печати

function TFiscalPrinter.ContinuePrint: Integer;
begin
  Result := Send(#$B0 + FPassw);
end;

// Скидка

function TFiscalPrinter.Discount: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$86 + FPassw + GetSumm1 + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(14);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Команда печати чека коррекции при неполном отпуске нефтепродуктов

function TFiscalPrinter.Correction: Integer;
begin
  Result := NotSupported;
end;

// Команда печати чека с закрытием отпуска нефтепродуктов
// в режиме предоплаты заданной дозы

function TFiscalPrinter.DozeOilCheck: Integer;
begin
  Result := NotSupported;
end;

// Печать графики с масштабированием

function TFiscalPrinter.DrawScale: Integer;
var
  Data: AnsiString;
begin
  // Проверка FirstLineNumber

  if (FirstLineNumber < 0) or ((FirstLineNumber > 1520) and ((FirstLineNumber < 65000) or (FirstLineNumber > 65512))) then
  begin
    Result := InvalidParam('FirstLineNumber');
    Exit;
  end;
  // Проверка LastLineNumber

  if (LastLineNumber < 0) or ((LastLineNumber > 1520) and ((LastLineNumber < 65000) or (LastLineNumber > 65512))) then
  begin
    Result := InvalidParam('LastLineNumber');
    Exit;
  end;

  // Проверка VertScale
  if (VertScale < 0) or (VertScale > 255) then
  begin
    Result := InvalidParam('VertScale');
    Exit;
  end;

  // Проверка HorizScale
  if (HorizScale < 0) or (HorizScale > 255) then
  begin
    Result := InvalidParam('HorizScale');
    Exit;
  end;

  Data := #$4F + FPassw + AnsiChar(FirstLineNumber) + AnsiChar(LastLineNumber) + AnsiChar(VertScale) + AnsiChar(HorizScale);

  Result := Send(Data);
end;

// Печать графики

function TFiscalPrinter.Draw: Integer;
var
  Data: AnsiString;
begin
  // Проверка FirstLineNumber
  if (FirstLineNumber < 0) or ((FirstLineNumber > 1520) and ((FirstLineNumber < 65000) or (FirstLineNumber > 65512))) then
  begin
    Result := InvalidParam('FirstLineNumber');
    Exit;
  end;
  // Проверка LastLineNumber
  if (LastLineNumber < 0) or ((LastLineNumber > 1520) and ((LastLineNumber < 65000) or (FirstLineNumber > 65512))) then
  begin
    Result := InvalidParam('LastLineNumber');
    Exit;
  end;

  Data := #$C1 + FPassw + AnsiChar(FirstLineNumber) + AnsiChar(LastLineNumber);

  Result := Send(Data);
end;

// Загрузка графики 512
function TFiscalPrinter.LoadGraphics512: Integer;
var
  Data: AnsiString;
  Len: Integer;
  MaxLineNumber: Integer;
  MaxLineLength: Integer;
begin
  if (GraphBufferType < 0) or (GraphBufferType > 1) then
  begin
    Result := InvalidParam('GraphBufferType');
    Exit;
  end;

  if GraphBufferType = 1 then
  begin
    MaxLineNumber := 1200;
    MaxLineLength := 64;
  end else
  begin
    MaxLineNumber := 600;
    MaxLineLength := 64;
  end;

  if (LineLength <= 0) or (LineLength > MaxLineLength) then
  begin
    Result := InvalidParam('LineLength');
    Exit;
  end;

  if (FirstLineNumber < 0) or ((FirstLineNumber > 1520) and ((FirstLineNumber < 65000) or (FirstLineNumber > 65512))) then
  begin
    Result := InvalidParam('FirstLineNumber');
    Exit;
  end;

  Len := LineNumber * LineLength;
  Data := #$4E + FPassw + AnsiChar(LineLength) + WordToStr(FirstLineNumber) + WordToStr(LineNumber) + AnsiChar(GraphBufferType) + GetStr2(LineData, Len);

  Result := Send(Data);
end;

// Печать графики 512
function TFiscalPrinter.PrintGraphics512: Integer;
var
  Data: AnsiString;
begin
  if (FirstLineNumber < 0) or ((FirstLineNumber > 1520) and ((FirstLineNumber < 65000) or (FirstLineNumber > 65512))) then
  begin
    Result := InvalidParam('FirstLineNumber');
    Exit;
  end;

  if (LastLineNumber < 0) or ((LastLineNumber > 1520) and ((LastLineNumber < 65000) or (LastLineNumber > 65512))) then
  begin
    Result := InvalidParam('LastLineNumber');
    Exit;
  end;

  if (VertScale <= 0) or (VertScale > 255) then
  begin
    Result := InvalidParam('VertScale');
    Exit;
  end;

  if (HorizScale <= 0) or (HorizScale > 6) then
  begin
    Result := InvalidParam('HorizScale');
    Exit;
  end;

  Data := #$4D + FPassw + WordToStr(FirstLineNumber) + WordToStr(LastLineNumber) + AnsiChar(VertScale) + AnsiChar(HorizScale) + AnsiChar(GetTapeType);

  Result := Send(Data);
end;


// Отчет ЭКЛЗ по отделам в заданном диапазоне дат

function TFiscalPrinter.EKLZDepartmentReportInDatesRange: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$A0 + FPassw + AnsiChar(GetReportType) + AnsiChar(GetDepartment) + AnsiChar(FFirstSessionDay) + AnsiChar(FFirstSessionMonth) + AnsiChar(FFirstSessionYear) + AnsiChar(FLastSessionDay) + AnsiChar(FLastSessionMonth) + AnsiChar(FLastSessionYear);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Отчет ЭКЛЗ по отделам в заданном диапазоне номеров смен

function TFiscalPrinter.EKLZDepartmentReportInSessionsRange: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$A1 + FPassw + AnsiChar(GetReportType) + AnsiChar(GetDepartment) + WordToStr(GetFirstSessionNumber) + WordToStr(GetLastSessionNumber);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Отчет ЭКЛЗ по закрытиям смен в заданном диапазоне дат

function TFiscalPrinter.EKLZSessionReportInDatesRange: Integer;
var
  Data: AnsiString;
begin
  Data := #$A2 + FPassw + AnsiChar(GetReportType) + AnsiChar(FFirstSessionDay) + AnsiChar(FFirstSessionMonth) + AnsiChar(FFirstSessionYear) + AnsiChar(FLastSessionDay) + AnsiChar(FLastSessionMonth) + AnsiChar(FLastSessionYear);

  Result := Send(Data);
end;

// Отчет ЭКЛЗ по закрытиям смен в заданном диапазоне номеров смен

function TFiscalPrinter.EKLZSessionReportInSessionsRange: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$A3 + FPassw + AnsiChar(GetReportType) + WordToStr(GetFirstSessionNumber) + WordToStr(GetLastSessionNumber);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Контрольная лента из ЭКЛЗ по номеру смены

function TFiscalPrinter.EKLZJournalOnSessionNumber: Integer;
var
  Data: AnsiString;
begin
  Data := #$A6 + FPassw + WordToStr(SessionNumber);

  Result := Send(Data);
end;

function TFiscalPrinter.DecodeString(const Data: AnsiString): AnsiString;
begin
  case BinaryConversion of
    BINARY_CONVERSION_NONE:
      Result := Data;
    BINARY_CONVERSION_HEX:
      Result := HexToStr(Data);
  else
    Result := Data;
  end;
end;

function TFiscalPrinter.EncodeString(const Data: AnsiString): AnsiString;
begin
  case BinaryConversion of
    BINARY_CONVERSION_NONE:
      Result := Data;
    BINARY_CONVERSION_HEX:
      Result := StrToHex(Data);
  else
    Result := Data;
  end;
end;

// Послать байты

function TFiscalPrinter.ExchangeBytes: Integer;
begin
  FECode := 0;
  if TransferBytes = '' then
  begin
    Result := E_NOERROR;
    try
      Driver.Sync;
    except
      on E: Exception do
        Result := HandleException(E);
    end;
    TransferBytes := '';
    Exit;
  end;
  Result := Send(DecodeString(TransferBytes));
  if Result = E_NOERROR then
  begin
    TransferBytes := EncodeString(FRxData);
  end;
end;

// Протяжка

function TFiscalPrinter.FeedDocument: Integer;
var
  Data: AnsiString;
begin
  if (StringQuantity in [0..255]) then
  begin
    Data := #$29 + FPassw + AnsiChar(GetTapeType) + AnsiChar(StringQuantity);
    Result := Send(Data);
  end else
    Result := InvalidParam('StringQuantity');
end;

// Фискализация (перерегистрация)

function TFiscalPrinter.Fiscalization: Integer;

  function GetINN: AnsiString;
  var
    Code: Integer;
    Value: Int64;
    MaxValue: Int64;
  begin
    Val(INN, Value, Code);
    if Code <> 0 then
      InvalidProp('INN');
    MaxValue := StrToInt64(StringOfChar('9', 12 { PrinterModel.InnDigitCount } ));
    CheckIntProp(Value, 0, MaxValue, 'INN');
    Result := IntToBin(Value, 6);
  end;

var
  Data: AnsiString;
begin
  try
    CheckIntProp(GetRNM, 0, 999999999999, 'RNM');
    CheckIntProp(NewPasswordTI, 0, 999999999, 'NewPasswordTI');
    Data := #$65 + FPassw + IntToBin(NewPasswordTI, 4) + IntToBin(GetRNM, 5) + GetINN;

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Фискальный отчет по диапазону дат

function TFiscalPrinter.FiscalReportForDatesRange: Integer;
var
  Data: AnsiString;
begin
  Data := #$66 + FPassw + AnsiChar(GetReportType) + AnsiChar(FFirstSessionDay) + AnsiChar(FFirstSessionMonth) + AnsiChar(FFirstSessionYear) + AnsiChar(FLastSessionDay) + AnsiChar(FLastSessionMonth) + AnsiChar(FLastSessionYear);

  Result := Send(Data);
end;

// Фискальный отчет по диапазону смен

function TFiscalPrinter.FiscalReportForSessionRange: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$67 + FPassw + AnsiChar(GetReportType) + WordToStr(GetFirstSessionNumber) + WordToStr(GetLastSessionNumber);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Чтение параметров фискализации (перерегистрации)

function TFiscalPrinter.GetFiscalizationParameters: Integer;
var
  Data: AnsiString;
begin
  if (RegistrationNumber in [0..$FF]) then
  begin
    Data := #$69 + FPassw + AnsiChar(RegistrationNumber);
    Result := Send(Data);
  end else
    Result := InvalidParam('RegistrationNumber');
end;

// Запрос суммы записей в ФП

function TFiscalPrinter.GetFMRecordsSum: Integer;
var
  Data: AnsiString;
begin
  Data := #$62 + FPassw + AnsiChar(BoolToInt[TypeOfSumOfEntriesFM]);
  Result := Send(Data);
end;

// Запрос даты последней записи в ФП

function TFiscalPrinter.GetLastFMRecordDate: Integer;
begin
  Result := Send(#$63 + FPassw);
end;

// Команда позволяет прочитать содержимое литрового суммарного счетчика

function TFiscalPrinter.GetLiterSumCounter: Integer;
begin
  Result := NotSupported;
end;

// Запрос диапазона дат и смен

function TFiscalPrinter.GetRangeDatesAndSessions: Integer;
begin
  Result := Send(#$64 + FPassw);
end;

// Команда запроса состояния РК

function TFiscalPrinter.GetRKStatus: Integer;
begin
  Result := NotSupported;
end;

// Запрос структуры таблицы

function TFiscalPrinter.GetTableStruct: Integer;
begin
  try
    Result := Send(#$2D + FPassw + AnsiChar(GetTableNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Инициализация ФП

function TFiscalPrinter.InitFM: Integer;
begin
  Result := Send(#$61);
end;

// Прерывание полного отчета

function TFiscalPrinter.InterruptFullReport: Integer;
begin
  Result := Send(#$68 + FPassw);
end;

// Прерывание тестового прогона

function TFiscalPrinter.InterruptTest: Integer;
begin
  Result := Send(#$2B + FPassw);
end;

// Пуск РК

function TFiscalPrinter.LaunchRK: Integer;
begin
  Result := NotSupported;
end;

// Загрузка графики

function TFiscalPrinter.LoadLineData: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$C0 + FPassw + AnsiChar(GetLineNumber) + GetStr2(LineData, 40);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Команда оформления на чеке отпуска нефтепродуктов
// в режиме оплаты после отпуска нефтепродуктов (без закрытия чека).

function TFiscalPrinter.OilSale: Integer;
begin
  Result := NotSupported;
end;

// Открыть чек

function TFiscalPrinter.OpenCheck: Integer;
begin
  try
    Result := SafeOpenSession;
    if Result <> 0 then
      Exit;
    Result := Send(#$8D + FPassw + AnsiChar(GetCheckType));
    DrvOpenCheck;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Открыть денежный ящик

function TFiscalPrinter.OpenDrawer: Integer;
begin
  try
    Result := Send(#$28 + FPassw + AnsiChar(GetDrawerNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Печать штрих-кода

function TFiscalPrinter.PrintBarCode: Integer;
var
  V: Int64;
  E: Integer;
begin
  // Копируем первые 12 символов, остальные игнорируем
  Val(Copy(Barcode, 1, 12), V, E);
  if (E <> 0) or (V < 0) then
    Result := InvalidParam('Barcode')
  else
    Result := Send(#$c2 + FPassw + IntToBin(V, 5));
end;

{ Печать штрих-кода средствами принтера

  Команда: CBH. Длина сообщения: 57 байт или менее
  - Пароль оператора (4 байта)
  - Высота штрих-кода (1 байт)
  - Ширина штриха (1 байт)
  - Позиция HRI (1 байт)
  - Шрифт HRI (1 байт)
  - Тип штрих-кода (1 байт)
  - Данные штрих-кода (1-48 байт)
  Ответ: E5H. Длина сообщения: 3 байт.
  - Код ошибки (1 байт)
  - Порядковый номер оператора (1 байт) 1..30 }

function TFiscalPrinter.PrintBarcodeUsingPrinter: Integer;
var
  BC: AnsiString;
begin
  try
    if (LineNumber > $FF) or (LineNumber < 0) then
      InvalidProp('LineNumber');
    if (BarWidth > $FF) or (BarWidth < 0) then
      InvalidProp('BarWidth');
    if (HRIPosition > $FF) or (HRIPosition < 0) then
      InvalidProp('HRIPosition');
    if (FontType > $FF) or (FontType < 0) then
      InvalidProp('FontType');
    if (BarcodeType > $FF) or (BarcodeType < 0) then
      InvalidProp('BarcodeType');
    if Length(Barcode) < 1 then
      InvalidProp('Barcode');
    BC := Copy(Barcode, 1, 48);
    Result := Send(#$CB + FPassw + AnsiChar(LineNumber) + AnsiChar(BarWidth) + AnsiChar(HRIPosition) + AnsiChar(FontType) + AnsiChar(BarcodeType) + Barcode);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Отчёт по секциям

function TFiscalPrinter.PrintDepartmentReport: Integer;
begin
  Result := Send(#$42 + FPassw);
end;

// Метод печатает содержимое операционных регистров

function TFiscalPrinter.PrintOperationReg: Integer;
begin
  Result := Send(#$2C + FPassw);
end;

// Суточный отчет с гашением

function TFiscalPrinter.PrintReportWithCleaning: Integer;
begin
  Result := SendAuth(#$41 + FPassw);

  { Для казахских фр-ов

    Если на команду снятия Z отчёта возвращается ошибка 208, то
    a.	Сделать запрос состояния и получить  номер последней закрытой смены N.
    b.	Запустить печать контрольный ленты  из ЭКЛЗ по смене N+1. Фр перейдёт в 12 режим - печать отчёта ЭКЛЗ.
    c.	Далее нужно дождаться прекращения  12го  режима.
    d.	Подать команду снятия Z отчёта.
    Если в 12 режиме закончится  бумага, то появится  3 подрежим. Нужно подать команду продолжить печать и дождаться прекращения 12 режима
  }
  if (Result = 208) and (PrintJournalBeforeZReport) then
  begin
    Result := GetECRStatus;
    if Result <> 0 then
      Exit;
    SessionNumber := SessionNumber + 1;
    Result := EKLZJournalOnSessionNumber;
    if Result <> 0 then
      Exit;
    Result := WaitForPrinting;
    if Result <> 0 then
      Exit;
    Result := Send(#$41 + FPassw);
  end
end;

// Суточный отчет без гашения

function TFiscalPrinter.PrintReportWithoutCleaning: Integer;
begin
  Result := Send(#$40 + FPassw);
end;

// Отчет по кассирам

function TFiscalPrinter.PrintCashierReport: Integer;
begin
  Result := Send(#$44 + FPassw);
end;

// Отчет почасовой

function TFiscalPrinter.PrintHourlyReport: Integer;
begin
  Result := Send(#$45 + FPassw);
end;

// Отчет по товарам

function TFiscalPrinter.PrintWareReport: Integer;
begin
  Result := Send(#$46 + FPassw);
end;

// Добавить или обновить товар в базе товаров

function TFiscalPrinter.UpdateWare: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$4A + FPassw + WordToStr(GetWareCode) + GetPrice + AnsiChar(GetDepartment) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetPrintString;
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Считать товар из базы товаров

function TFiscalPrinter.ReadWare: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$4B + FPassw + WordToStr(GetWareCode);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Удалить товар в базе товаров

function TFiscalPrinter.RemoveWare: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$4C + FPassw + WordToStr(GetWareCode);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.RenderDeclarativeDocument: Integer;
var
  Check: TDeclarativeCheck;
  Err: string;
begin
  Result := ClearResult;
  Check := TDeclarativeCheck.Create(Self);
  try
    Check.IsCorrection := False;
    Result := Check.Render(DeclarativeInput, DeclarativeOutput, Err);
    if Result <> 0 then
    begin
      ResultCodeDescription := Err;
      ResultCode := Result;
    end;
  finally
    Check.Free;
  end;

end;

// Проверка накопителя ФП на сбойные записи

function TFiscalPrinter.CheckFM: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$6A + FPassw + AnsiChar(GetCheckingType);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Платежный документ из ЭКЛЗ по номеру КПК

function TFiscalPrinter.ReadEKLZDocumentOnKPK: Integer;
var
  Data: AnsiString;
begin
  if not ValidKPKNumber then
  begin
    Result := InvalidParam('KPKNumber');
    Exit;
  end;

  Data := #$A5 + FPassw + IntToBin(KPKNumber, 4);

  Result := Send(Data);
end;

// Итоги смены по номеру смены ЭКЛЗ

function TFiscalPrinter.ReadEKLZSessionTotal: Integer;
var
  Data: AnsiString;
begin
  Data := #$A4 + FPassw + WordToStr(SessionNumber);

  Result := Send(Data);
end;

// Повтор документа

function TFiscalPrinter.RepeatDocument: Integer;
begin
  Result := Send(#$8C + FPassw);
end;

// Сброс всех ТРК

function TFiscalPrinter.ResetAllTRK: Integer;
begin
  Result := NotSupported;
end;

// Сброс РК

function TFiscalPrinter.ResetRK: Integer;
begin
  Result := NotSupported;
end;

// Общее гашение

function TFiscalPrinter.ResetSummary: Integer;
begin
  Result := Send(#$27 + FPassw);
end;

// КЯ: Возврат покупки по коду товара

function TFiscalPrinter.ReturnBuyByWare_CashCore: Integer;
var
  Data: AnsiString;
begin
  try
    Result := CheckStatus;
    if DRV_SUCCESS(Result) then
    begin
      Data := #$83 + FPassw + GetQuantity + GetPrice + AnsiChar($FF) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetWareCodeStr;
      Result := Send(Data);
      DrvOpenCheck;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Возврат покупки

function TFiscalPrinter.ReturnBuy: Integer;
var
  Data: AnsiString;
begin
  try
    Result := SafeOpenSession;
    if Result <> 0 then
      Exit;

    if PrinterModel.CapCashCore and UseWareCode then
    begin
      Result := ReturnBuyByWare_CashCore;
      Exit;
    end;

    Result := CheckStatus;
    if DRV_SUCCESS(Result) then
    begin
      UpdateStringForPrinting;
      Data := #$83 + FPassw + GetQuantity + GetPrice + AnsiChar(GetDepartment) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(20);
      Result := Send(Data);
      DrvOpenCheck;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// КЯ: Возврат продажи по коду товара

function TFiscalPrinter.ReturnSaleByWare_CashCore: Integer;
var
  Data: AnsiString;
begin
  try
    Result := CheckStatus;
    if DRV_SUCCESS(Result) then
    begin
      Data := #$82 + FPassw + GetQuantity + GetPrice + AnsiChar($FF) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetWareCodeStr;

      Result := Send(Data);
      DrvOpenCheck;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Возврат продажи

function TFiscalPrinter.ReturnSale: Integer;
var
  Data: AnsiString;
begin
  try
    Result := SafeOpenSession;
    if Result <> 0 then
      Exit;

    if PrinterModel.CapCashCore and UseWareCode then
    begin
      Result := ReturnSaleByWare_CashCore;
      Exit
    end;

    Result := CheckStatus;

    if DRV_SUCCESS(Result) then
    begin
      UpdateStringForPrinting;
      Data := #$82 + FPassw + GetQuantity + GetPrice + AnsiChar(GetDepartment) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(20);

      Result := Send(Data);
      DrvOpenCheck;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ReturnBuyEx: Integer;
begin
  Result := StoreParams;
  if not DRV_SUCCESS(Result) then
    Exit;
  Result := ReturnBuy;
  RestoreParams;
  DrvOpenCheck;
end;

function TFiscalPrinter.ReturnSaleEx: Integer;
begin
  Result := StoreParams;
  if not DRV_SUCCESS(Result) then
    Exit;
  Result := ReturnSale;
  RestoreParams;
  DrvOpenCheck;
end;

function TFiscalPrinter.Sale2ByWare_CashCore: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$80 + FPassw + GetQuantity + GetPrice +
    // Если Цена 0  - то берется из базы
      AnsiChar($FF) + // Отдел 255
      AnsiChar(GetTax1) + // Налоги не учитываются - берутся из базы
      AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetWareCodeStr; // Код товара из 4-х символов

    Result := Send(Data);
    DrvOpenCheck;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.Sale2(Intf: IUnknown): Integer;
var
  Data: AnsiString;
begin
  try
    // КЯ: продажа по коду товара
    if PrinterModel.CapCashCore and UseWareCode then
    begin
      Result := Sale2ByWare_CashCore;
      Exit;
    end;

    { Result := CheckItemMarking;
      if Result <> 0 then Exit; }
    UpdateStringForPrinting;
    Data := #$80 + FPassw + GetQuantity + GetPrice + AnsiChar(GetDepartment) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(20);

    Result := Send(Data);
    DrvOpenCheck;

    { if Result = 0 then
      begin
      Result := SendItemMarking;
      end; }
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Продажа

function TFiscalPrinter.Sale(Intf: IUnknown): Integer;
begin
  if MobilePayEnabled and (Department = PayDepartment) then
  begin
    Result := PayMobile(Intf);
  end else
  begin
    try
      Result := SafeOpenSession;
      if Result <> 0 then
        Exit;

      Result := CheckStatus;
      if DRV_SUCCESS(Result) then
      begin
        Result := Sale2(Intf);
      end;
    except
      on E: Exception do
        Result := HandleException(E);
    end;
  end;
end;

function TFiscalPrinter.SaleEx(Intf: IUnknown): Integer;
begin
  Result := StoreParams;
  if not DRV_SUCCESS(Result) then
    Exit;
  Result := Sale(Intf);
  RestoreParams;
  DrvOpenCheck;
end;

{ Подакцизная операция }

function TFiscalPrinter.ExcisableOperation: Integer;
var
  Data: AnsiString;
  BarcodeData: AnsiString;
begin
  try
    case OperationType of
      $00, $01, $02, $03, $10, $11, $12, $13:
        ;
    else
      InvalidProp('OperationType');
    end;
    BarcodeData := Copy(Barcode, 1, 73);
    UpdateStringForPrinting;
    Data := #$8F + FPassw + AnsiChar(OperationType) + AnsiChar(GetExciseCode) + AnsiChar(GetDepartment) + GetPrice + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(40) + BarcodeData;

    Result := Send(Data);
    DrvOpenCheck;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Задание дозы РК в миллилитрах
// (для режима оплаты дозы после отпуска нефтепродуктов).

function TFiscalPrinter.SetDozeInMilliliters: Integer;
begin
  Result := NotSupported;
end;

// Задание дозы РК в денежных единицах
// (для режима оплаты дозы после отпуска нефтепродуктов).

function TFiscalPrinter.SetDozeInMoney: Integer;
begin
  Result := NotSupported;
end;

// Установка параметров РК

function TFiscalPrinter.SetRKParameters: Integer;
begin
  Result := NotSupported;
end;

// Ввод заводского номера

function TFiscalPrinter.SetSerialNumber: Integer;
var
  Value: Integer;
  Code: Integer;
begin
  if PrinterModel.CapFN then
  begin
    // fe f5 30 31 32 33 34 35 36 37 38 39 31 32 33 34 35 36
    FECode := $F5;
    Result := Send(#$FE#$F5 + AddLeadingZeros(SerialNumber, 16));
    Exit;
  end;

  Val(SerialNumber, Value, Code);
  if not ((Code = 0) and (Value <= 99999999) and (Value >= 0)) then
  begin
    Result := InvalidParam('SerialNumber');
    Exit;
  end;
  Result := Send(#$60 + FPassw + IntToBin(Value, 4));
end;


// Повторный ввод заводского номера

function TFiscalPrinter.ResetSerialNumber: Integer;
begin
  FECode := $F1;
  Result := Send(#$FE#$F1 + AddLeadingZeros(SerialNumber, 16) + AddLeadingZeros(License, 8));
end;


// Прерывание полного отчета ЭКЛЗ или контрольной ленты ЭКЛЗ
// или печати платежного документа ЭКЛЗ

function TFiscalPrinter.StopEKLZDocumentPrinting: Integer;
begin
  Result := Send(#$A7 + FPassw);
end;

// procedure TFiscalPrinter.StopPPPService;
// begin
// FPPPService.Stop;
// end;

// Остановка РК

function TFiscalPrinter.StopRK: Integer;
begin
  Result := NotSupported;
end;

// КЯ: Сторно по коду товара

function TFiscalPrinter.StornoByWare_CashCore: Integer;
var
  Data: AnsiString;
begin
  try
    Result := CheckStatus;
    if DRV_SUCCESS(Result) then
    begin
      Data := #$84 + FPassw + GetQuantity + GetPrice + AnsiChar($FF) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetWareCodeStr;

      Result := Send(Data);
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.Storno: Integer;
var
  Data: AnsiString;
begin
  try
    if PrinterModel.CapCashCore and UseWareCode then
    begin
      Result := StornoByWare_CashCore;
      Exit;
    end;

    Result := CheckStatus;
    if DRV_SUCCESS(Result) then
    begin
      UpdateStringForPrinting;
      Data := #$84 + FPassw + GetQuantity + GetPrice + AnsiChar(GetDepartment) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(20);

      Result := Send(Data);
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.StornoEx: Integer;
begin
  Result := StoreParams;
  if not DRV_SUCCESS(Result) then
    Exit;
  Result := Storno;
  RestoreParams;
end;

function TFiscalPrinter.StornoCharge: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$8B + FPassw + GetSumm1 + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(14);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Сторно скидки

function TFiscalPrinter.StornoDiscount: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$8A + FPassw + GetSumm1 + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(14);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Команда печати чека с закрытием отпуска нефтепродуктов
// в режиме предоплаты заданной суммы.

function TFiscalPrinter.SummOilCheck: Integer;
begin
  Result := NotSupported;
end;

function TFiscalPrinter.SysAdminCancelCheck: Integer;
var
  i: Integer;
  StartPassword: Integer;
begin
  // Пытаемся отменить чек с текущим паролем.
  // Ошибка 0x59 - Документ открыт другим оператором
  Result := CancelCheck;
  if Result <> $59 then
    Exit;

  // Пытаемся отменить с паролем кассиров
  TableNumber := 2;
  FieldNumber := 1;
  StartPassword := Password;
  // читаем пароли
  for i := 1 to 29 do
  begin
    RowNumber := i;
    Set_Password(StartPassword);
    Result := ReadTable;
    if not DRV_SUCCESS(Result) then
      Break;

    Set_Password(ValueOfFieldInteger);
    Result := CancelCheck;
    if Result <> $59 then
      Break;
  end;
  Password := StartPassword;
end;

function TFiscalPrinter.DeviceCodeDescription: AnsiString;
begin
  Result := GetDeviceCodeDescription(DeviceCode);
end;

function TFiscalPrinter.ECRAdvancedModeDescription: WideString;
begin
  Result := GetAdvancedModeDescription(ECRAdvancedMode);
end;

function TFiscalPrinter.ECRModeDescription: WideString;
begin
  Result := GetECRModeDescription(FullECRMode);
end;

function TFiscalPrinter.Get_FirstSessionDate: TDateTime;
begin
  if not DoEncodeDate(2000 + FFirstSessionYear, FFirstSessionMonth, FFirstSessionDay, Result) then
    Result := 0;
end;

procedure TFiscalPrinter.Set_FirstSessionDate(Value: TDateTime);
var
  Year, Month, Day: Word;
begin
  DecodeDate(Value, Year, Month, Day);
  FFirstSessionYear := Year - 2000;
  FFirstSessionMonth := Month;
  FFirstSessionDay := Day;
end;

function TFiscalPrinter.Get_LastSessionDate: TDateTime;
begin
  try
    Result := EncodeDate(2000 + FLastSessionYear, FLastSessionMonth, FLastSessionDay);
  except
    on EConvertError do
      Result := 0;
  end;
end;

procedure TFiscalPrinter.Set_LastSessionDate(Value: TDateTime);
var
  Year, Month, Day: Word;
begin
  DecodeDate(Value, Year, Month, Day);
  FLastSessionYear := Year - 2000;
  FLastSessionMonth := Month;
  FLastSessionDay := Day;
end;

function TFiscalPrinter.Get_NameCashReg: WideString;
begin
  try
    Result := PrinterModel.GetCashRegName(RegisterNumber);
  except
    Result := '?';
  end;
end;

function TFiscalPrinter.Get_NameCashRegEx: WideString;
begin
  try
    Result := PrinterModel.GetCashRegNameEx(RegisterNumber);
  except
    Result := '?';
  end;
end;

function TFiscalPrinter.Get_NameOperationReg: WideString;
begin
  try
    Result := PrinterModel.GetOperRegName(RegisterNumber);
  except
    Result := '?';
  end;
end;

function TFiscalPrinter.Get_TimeStr: AnsiString;
begin
  Result := TimeToStr1C(ECRTime);
end;

procedure TFiscalPrinter.Set_TimeStr(const Value: AnsiString);
begin
  ECRTime := StrToTime(Value);
end;

function TFiscalPrinter.Get_TypeOfLastEntryFM: Boolean;
begin
  Result := Boolean(FTypeOfLastEntryFM);
end;

// Печать строки данным шрифтом (КЯ)

function TFiscalPrinter.PrintStringWithFont_CashCore: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$2F + FPassw + AnsiChar(GetTapeType) + AnsiChar(GetFontType) + Copy(GetPrintString, 1, 248);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Печать строки данным шрифтом

function TFiscalPrinter.PrintStringWithFont: Integer;
var
  Data: AnsiString;
begin
  try
    if PrinterModel.CapCashCore then
    begin
      Result := PrintStringWithFont_CashCore;
      Exit;
    end;

    Data := #$2F + FPassw + AnsiChar(GetTapeType) + AnsiChar(GetFontType) + GetStringForPrinting(7);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Итог активизации ЭКЛЗ

function TFiscalPrinter.EKLZActivizationResult: Integer;
begin
  Result := Send(#$A8 + FPassw);
end;

// Активизация ЭКЛЗ

function TFiscalPrinter.EKLZActivization: Integer;
begin
  Result := Send(#$A9 + FPassw);
end;

// Закрытие архива ЭКЛЗ

function TFiscalPrinter.CloseEKLZArchive: Integer;
begin
  Result := Send(#$AA + FPassw);
end;

// Прекращение ЭКЛЗ

function TFiscalPrinter.EKLZInterrupt: Integer;
begin
  Result := Send(#$AC + FPassw);
end;

// Запрос регистрационного номера ЭКЛЗ

function TFiscalPrinter.GetEKLZSerialNumber: Integer;
begin
  Result := Send(#$AB + FPassw);
end;

function TFiscalPrinter.Get_LastKPKDate: TDateTime;
begin
  try
    Result := EncodeDate(2000 + FLastKPKYear, FLastKPKMonth, FLastKPKDay);
  except
    on EConvertError do
      Result := 0;
  end;
end;

function TFiscalPrinter.Get_LastKPKTime: TDateTime;
begin
  try
    Result := EncodeTime(FLastKPKhour, FLastKPKMin, 0, 0);
  except
    on EConvertError do
      Result := 0;
  end;
end;

// Запрос состояния по коду 1 ЭКЛЗ

function TFiscalPrinter.GetEKLZCode1Report: Integer;
begin
  FGetEKLZCode1Report := True;
  try
    Result := Send(#$AD + FPassw);
  finally
    FGetEKLZCode1Report := False;
  end;
end;

// Запрос состояния по коду 2 ЭКЛЗ

function TFiscalPrinter.GetEKLZCode2Report: Integer;
begin
  Result := Send(#$AE + FPassw);
end;

// Запрос состояния по коду 3 ЭКЛЗ

function TFiscalPrinter.GetEKLZCode3Report: Integer;
begin
  Result := Send(#$BD + FPassw);
end;

// Тест целостности архива ЭКЛЗ

function TFiscalPrinter.TestEKLZArchiveIntegrity: Integer;
begin
  Result := Send(#$AF + FPassw);
end;

// Запрос версии ЭКЛЗ

function TFiscalPrinter.GetEKLZVersion: Integer;
begin
  Result := Send(#$B1 + FPassw);
end;

// Инициализация архива ЭКЛЗ

function TFiscalPrinter.InitEKLZArchive: Integer;
begin
  Result := Send(#$B2 + FPassw);
end;

// Запрос данных отчёта ЭКЛЗ

function TFiscalPrinter.GetEKLZData: Integer;
begin
  Result := Send(#$B3 + FPassw);
end;

// Запрос отчёта ЭКЛЗ по отделам в заданном диапазоне дат

function TFiscalPrinter.GetEKLZDepartmentReportInDatesRange: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$B6 + FPassw + AnsiChar(GetReportType) + AnsiChar(GetDepartment) + AnsiChar(FFirstSessionDay) + AnsiChar(FFirstSessionMonth) + AnsiChar(FFirstSessionYear) + AnsiChar(FLastSessionDay) + AnsiChar(FLastSessionMonth) + AnsiChar(FLastSessionYear);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Запрос отчёта ЭКЛЗ по отделам в заданном диапазоне номеров смен

function TFiscalPrinter.GetEKLZDepartmentReportInSessionsRange: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$B7 + FPassw + AnsiChar(GetReportType) + AnsiChar(GetDepartment) + WordToStr(GetFirstSessionNumber) + WordToStr(GetLastSessionNumber);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Запрос документа ЭКЛЗ

function TFiscalPrinter.GetEKLZDocument: Integer;
var
  Data: AnsiString;
begin
  if not ValidKPKNumber then
  begin
    Result := InvalidParam('KPKNumber');
    Exit;
  end;

  Data := #$B5 + FPassw + IntToBin(KPKNumber, 4);
  Result := Send(Data);
end;

// Запрос контрольной ленты ЭКЛЗ

function TFiscalPrinter.GetEKLZJournal: Integer;
var
  Data: AnsiString;
begin
  Data := #$B4 + FPassw + WordToStr(SessionNumber);
  Result := Send(Data);
end;

// Запрос отчёта ЭКЛЗ по закрытиям смен в заданном диапазоне дат

function TFiscalPrinter.GetEKLZSessionReportInDatesRange: Integer;
var
  Data: AnsiString;
begin
  Data := #$B8 + FPassw + AnsiChar(GetReportType) + AnsiChar(FFirstSessionDay) + AnsiChar(FFirstSessionMonth) + AnsiChar(FFirstSessionYear) + AnsiChar(FLastSessionDay) + AnsiChar(FLastSessionMonth) + AnsiChar(FLastSessionYear);

  Result := Send(Data);
end;

// Запрос отчёта ЭКЛЗ по закрытиям смен в заданном диапазоне номеров смен

function TFiscalPrinter.GetEKLZSessionReportInSessionsRange: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$B9 + FPassw + AnsiChar(GetReportType) + WordToStr(GetFirstSessionNumber) + WordToStr(GetLastSessionNumber);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Запрос итога активизации ЭКЛЗ

function TFiscalPrinter.GetEKLZActivizationResult: Integer;
begin
  Result := Send(#$BB + FPassw);
end;

// Запрос в ЭКЛЗ итогов смены по номеру смены

function TFiscalPrinter.GetEKLZSessionTotal: Integer;
var
  Data: AnsiString;
begin
  Data := #$BA + FPassw + WordToStr(SessionNumber);
  Result := Send(Data);
end;

// Вернуть ошибку ЭКЛЗ

function TFiscalPrinter.SetEKLZResultCode: Integer;
begin
  if (EKLZResultCode in [0..255]) then
    Result := Send(#$BC + FPassw + AnsiChar(EKLZResultCode))
  else
    Result := InvalidParam('EKLZResultCode');
end;

function TFiscalPrinter.GetDocArg: AnsiString;
begin
  SetLength(Result, 7);
  Result[1] := AnsiChar(CopyType);
  Result[2] := AnsiChar(NumberOfCopies);
  Result[3] := AnsiChar(CopyOffset1);
  Result[4] := AnsiChar(CopyOffset2);
  Result[5] := AnsiChar(CopyOffset3);
  Result[6] := AnsiChar(CopyOffset4);
  Result[7] := AnsiChar(CopyOffset5);
end;

function TFiscalPrinter.GetDocArgEx: AnsiString;
begin
  SetLength(Result, 13);
  Result[1] := AnsiChar(ClicheFont);
  Result[2] := AnsiChar(HeaderFont);
  Result[3] := AnsiChar(EKLZFont);
  Result[4] := AnsiChar(KPKFont);
  Result[5] := AnsiChar(ClicheStringNumber);
  Result[6] := AnsiChar(HeaderStringNumber);
  Result[7] := AnsiChar(EKLZStringNumber);
  Result[8] := AnsiChar(FMStringNumber);
  Result[9] := AnsiChar(ClicheOffset);
  Result[10] := AnsiChar(HeaderOffset);
  Result[11] := AnsiChar(EKLZOffset);
  Result[12] := AnsiChar(KPKOffset);
  Result[13] := AnsiChar(FMOffset);
end;

// Открыть фискальный подкладной документ

function TFiscalPrinter.OpenFiscalSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$70 + FPassw + AnsiChar(GetCheckType) + GetDocArg + GetDocArgEx;

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Открыть стандартный фискальный подкладной документ

function TFiscalPrinter.OpenStandardFiscalSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$71 + FPassw + AnsiChar(GetCheckType) + GetDocArg;

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetRegSlipDocEx: AnsiString;
begin
  Result := AnsiChar(QuantityFormat) + AnsiChar(StringQuantityInOperation) + AnsiChar(TextStringNumber) + AnsiChar(QuantityStringNumber) + AnsiChar(SummStringNumber) + AnsiChar(DepartmentStringNumber) + AnsiChar(TextFont) + AnsiChar(QuantityFont) + AnsiChar(MultiplicationFont) + AnsiChar(PriceFont) + AnsiChar(SummFont) + AnsiChar(DepartmentFont) + AnsiChar(TextSymbolNumber) + AnsiChar(QuantitySymbolNumber) + AnsiChar(PriceSymbolNumber) + AnsiChar(SummSymbolNumber) + AnsiChar(DepartmentSymbolNumber) + AnsiChar(TextOffset) + AnsiChar(QuantityOffset) + AnsiChar(SummOffset) + AnsiChar(DepartmentOffset);
end;

// Формирование операции на подкладном документе

function TFiscalPrinter.RegistrationOnSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$72 + FPassw + GetRegSlipDocEx + AnsiChar(GetOperationBlockFirstString) + GetQuantity + GetPrice + AnsiChar(GetDepartment) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(42);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Формирование стандартной операции на подкладном документе

function TFiscalPrinter.StandardRegistrationOnSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$73 + FPassw + AnsiChar(GetOperationBlockFirstString) + GetQuantity + GetPrice + AnsiChar(GetDepartment) + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(21);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// procedure TFiscalPrinter.StartPPPService(AComNumber: Integer);
// begin
// FPPPService.Start(AComNumber);
// end;

function TFiscalPrinter.GetDiscountChargeEx: AnsiString;
begin
  SetLength(Result, 12);
  Result[1] := AnsiChar(StringQuantityInOperation);
  Result[2] := AnsiChar(TextStringNumber);
  Result[3] := AnsiChar(operationNameStringNumber);
  Result[4] := AnsiChar(SummStringNumber);
  Result[5] := AnsiChar(TextFont);
  Result[6] := AnsiChar(operationNameFont);
  Result[7] := AnsiChar(SummFont);
  Result[8] := AnsiChar(TextSymbolNumber);
  Result[9] := AnsiChar(SummSymbolNumber);
  Result[10] := AnsiChar(TextOffset);
  Result[11] := AnsiChar(OperationNameOffset);
  Result[12] := AnsiChar(SummOffset);
end;

// Формирование скидки/надбавки на подкладном документе

function TFiscalPrinter.ChargeOnSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$74 + FPassw + GetDiscountChargeEx + #$01 + AnsiChar(GetOperationBlockFirstString) + GetSumm1 + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(28);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Формирование стандартной скидки/надбавки на подкладном документе

function TFiscalPrinter.StandardChargeOnSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$75 + FPassw + #$01 + AnsiChar(GetOperationBlockFirstString) + GetSumm1 + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(16);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetCloseCheckEx: AnsiString;
begin
  Result := AnsiChar(StringQuantityInOperation) + AnsiChar(TotalStringNumber) + AnsiChar(TextStringNumber) + AnsiChar(Summ1StringNumber) + AnsiChar(Summ2StringNumber) + AnsiChar(Summ3StringNumber) + AnsiChar(Summ4StringNumber) + AnsiChar(ChangeStringNumber) + AnsiChar(Tax1TurnOverStringNumber) + AnsiChar(Tax2TurnOverStringNumber) + AnsiChar(Tax3TurnOverStringNumber) + AnsiChar(Tax4TurnOverStringNumber) + AnsiChar(Tax1SumStringNumber) + AnsiChar(Tax2SumStringNumber) + AnsiChar(Tax3SumStringNumber) + AnsiChar
    (Tax4SumStringNumber) + AnsiChar(SubTotalStringNumber) + AnsiChar(DiscountOnCheckStringNumber) + AnsiChar(TextFont) + AnsiChar(TotalFont) + AnsiChar(TotalSumFont) + AnsiChar(Summ1NameFont) + AnsiChar(Summ1Font) + AnsiChar(Summ2NameFont) + AnsiChar(Summ2Font) + AnsiChar(Summ3NameFont) + AnsiChar(Summ3Font) + AnsiChar(Summ4NameFont) + AnsiChar(Summ4Font) + AnsiChar(ChangeFont) + AnsiChar(ChangeSumFont) + AnsiChar(Tax1NameFont) + AnsiChar(tax1TurnOverFont) + AnsiChar(Tax1rateFont) + AnsiChar(Tax1SumFont) +
    AnsiChar(Tax2NameFont) + AnsiChar(tax2TurnOverFont) + AnsiChar(Tax2rateFont) + AnsiChar(Tax2SumFont) + AnsiChar(Tax3NameFont) + AnsiChar(tax3TurnOverFont) + AnsiChar(Tax3rateFont) + AnsiChar(Tax3SumFont) + AnsiChar(Tax4NameFont) + AnsiChar(tax4TurnOverFont) + AnsiChar(Tax4rateFont) + AnsiChar(Tax4SumFont) + AnsiChar(SubTotalFont) + AnsiChar(SubTotalSumFont) + AnsiChar(DiscountOnCheckFont) + AnsiChar(DiscountOnCheckSumFont) + AnsiChar(TextSymbolNumber) + AnsiChar(TotalSymbolNumber) + AnsiChar(Summ1SymbolNumber)
    + AnsiChar(Summ2SymbolNumber) + AnsiChar(Summ3SymbolNumber) + AnsiChar(Summ4SymbolNumber) + AnsiChar(ChangeSymbolNumber) + AnsiChar(Tax1NameSymbolNumber) + AnsiChar(tax1TurnOverSymbolNumber) + AnsiChar(Tax1rateSymbolNumber) + AnsiChar(Tax1SumSymbolNumber) + AnsiChar(Tax2NameSymbolNumber) + AnsiChar(tax2TurnOverSymbolNumber) + AnsiChar(Tax2rateSymbolNumber) + AnsiChar(Tax2SumSymbolNumber) + AnsiChar(Tax3NameSymbolNumber) + AnsiChar(tax3TurnOverSymbolNumber) + AnsiChar(Tax3rateSymbolNumber) + AnsiChar(Tax3SumSymbolNumber)
    + AnsiChar(Tax4NameSymbolNumber) + AnsiChar(tax4TurnOverSymbolNumber) + AnsiChar(Tax4rateSymbolNumber) + AnsiChar(Tax4SumSymbolNumber) + AnsiChar(SubTotalSymbolNumber) + AnsiChar(DiscountOnCheckSymbolNumber) + AnsiChar(DiscountOnCheckSumSymbolNumber) + AnsiChar(TextOffset) + AnsiChar(TotalOffset) + AnsiChar(TotalSumOffset) + AnsiChar(Summ1NameOffset) + AnsiChar(Summ1Offset) + AnsiChar(Summ2NameOffset) + AnsiChar(Summ2Offset) + AnsiChar(Summ3NameOffset) + AnsiChar(Summ3Offset) + AnsiChar(Summ4NameOffset)
    + AnsiChar(Summ4Offset) + AnsiChar(ChangeOffset) + AnsiChar(ChangeSumOffset) + AnsiChar(Tax1NameOffset) + AnsiChar(tax1TurnOverOffset) + AnsiChar(Tax1rateOffset) + AnsiChar(Tax1SumOffset) + AnsiChar(Tax2NameOffset) + AnsiChar(tax2TurnOverOffset) + AnsiChar(Tax2rateOffset) + AnsiChar(Tax2SumOffset) + AnsiChar(Tax3NameOffset) + AnsiChar(tax3TurnOverOffset) + AnsiChar(Tax3rateOffset) + AnsiChar(Tax3SumOffset) + AnsiChar(Tax4NameOffset) + AnsiChar(tax4TurnOverOffset) + AnsiChar(Tax4rateOffset) + AnsiChar(Tax4SumOffset) + AnsiChar(SubTotalOffset) + AnsiChar(SubTotalSumOffset) + AnsiChar(DiscountOnCheckOffset) + AnsiChar(DiscountOnCheckSumOffset);
end;

// Формирование закрытия чека на подкладном документе

function TFiscalPrinter.CloseCheckOnSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$76 + FPassw + GetCloseCheckEx + AnsiChar(GetOperationBlockFirstString) + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetDiscountOnCheck + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(141);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Формирование стандартного закрытия чека на подкладном документе

function TFiscalPrinter.StandardCloseCheckOnSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$77 + FPassw + AnsiChar(GetOperationBlockFirstString) + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetDiscountOnCheck + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(32);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Конфигурация подкладного документа

function TFiscalPrinter.ConfigureSlipDocument: Integer;

  function GetSlipStringIntervals: AnsiString;
  var
    i: Integer;
    Count: Integer;
  begin
    SetLength(Result, 199);
    FillChar(Result[1], 199, #0);
    Count := min(199, Length(SlipStringIntervals));
    for i := 1 to Count do
      Result[i] := SlipStringIntervals[i];
  end;

var
  Data: AnsiString;
begin
  try
    Data := #$78 + FPassw + WordToStr(GetSlipWidth) + WordToStr(GetSlipLength) + AnsiChar(GetPrintingAlignment) + GetSlipStringIntervals;
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Установка стандартной конфигурации подкладного документа

function TFiscalPrinter.ConfigureStandardSlipDocument: Integer;
begin
  Result := Send(#$79 + FPassw);
end;

// Очистка всего буфера подкладного документа
// от нефискальной информации

function TFiscalPrinter.ClearSlipDocumentBuffer: Integer;
begin
  Result := Send(#$7C + FPassw);
end;

// Очистка строки буфера подкладного документа
// от нефискальной информации

function TFiscalPrinter.ClearSlipDocumentBufferString: Integer;
begin
  try
    Result := Send(#$7B + FPassw + AnsiChar(GetStringNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Заполнение буфера подкладного документа нефискальной информацией

function TFiscalPrinter.FillSlipDocumentWithUnfiscalInfo: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$7A + FPassw + AnsiChar(GetStringNumber) + Copy(StrToDevice(GetPrintString), 1, 247);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Печать подкладного документа

function TFiscalPrinter.PrintSlipDocument: Integer;
var
  Data: AnsiString;
begin
  if (InfoType in [0..255]) then
  begin
    Data := #$7D + FPassw + AnsiChar(BoolToInt[not IsClearUnfiscalInfo]) + AnsiChar(InfoType);
    Result := Send(Data);
  end else
    Result := InvalidParam('InfoType');
end;

// Формирование скидки/надбавки на подкладном документе

function TFiscalPrinter.DiscountOnSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$74 + FPassw + GetDiscountChargeEx + #$00 + AnsiChar(GetOperationBlockFirstString) + GetSumm1 + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(28);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Формирование стандартной скидки/надбавки на подкладном документе

function TFiscalPrinter.StandardDiscountOnSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$75 + FPassw + #$00 + AnsiChar(GetOperationBlockFirstString) + GetSumm1 + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(16);
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Выброс подкладного документа

function TFiscalPrinter.EjectSlipDocument: Integer;
begin
  if (EjectDirection in [0..255]) then
    Result := Send(#$2A + FPassw + AnsiChar(EjectDirection))
  else
    Result := InvalidParam('EjectDirection');
end;

function TFiscalPrinter.DrawEx: Integer;
var
  Data: AnsiString;
  Flags: AnsiString;
begin
  if (FirstLineNumber < 0) or ((FirstLineNumber > 1520) and ((FirstLineNumber < 65000) or (FirstLineNumber > 65512))) then
  begin
    Result := InvalidParam('FirstLineNumber');
    Exit;
  end;

  if (LastLineNumber < 0) or ((LastLineNumber > 1520) and ((LastLineNumber < 65000) or (LastLineNumber > 65512))) then
  begin
    Result := InvalidParam('LastLineNumber');
    Exit;
  end;

  try
    if PrinterModel.CapPrintFlagsGraphics then
      Flags := AnsiChar(GetTapeType)
    else
      Flags := '';

    Data := #$C3 + FPassw + WordToStr(FirstLineNumber) + WordToStr(LastLineNumber) + Flags;

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.LoadLineDataEx: Integer;
var
  Data: AnsiString;
  LData: AnsiString;
  Len: Integer;
begin
  try
    if PrinterModel.CapLoadBlockGraphics then
    begin
      if Length(LineData) < 40 then
        Len := 40
      else
        Len := Length(LineData);
      LData := GetStr2(LineData, Len);
    end else
      LData := GetStr2(LineData, 40);

    Data := #$C4 + FPassw + WordToStr(GetLineNumber) + LData;
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.Connect2: Integer;
begin
  try
    OpenPort;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Общая конфигурация подкладного документа

function TFiscalPrinter.ConfigureGeneralSlipDocument: Integer;
var
  Data: AnsiString;
begin
  try
    if (SlipEqualStringIntervals in [0..255]) then
    begin
      Data := #$7E + FPassw + WordToStr(GetSlipWidth) + WordToStr(GetSlipLength) + AnsiChar(GetPrintingAlignment) + AnsiChar(SlipEqualStringIntervals);
      Result := Send(Data);
    end else
      Result := InvalidParam('SlipEqualStringIntervals');
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.WideLoadLineData: Integer;
var
  i: Integer;
  Count: Integer;
  SaveLineNumber: Word;
  SaveLineData: AnsiString;
  BlockLen: Integer;
  k: Integer;
begin
  Result := ClearResult;
  SaveLineData := LineData;
  SaveLineNumber := LineNumber;
  try
    if PrinterModel.CapLoadBlockGraphics then
    begin
      BlockLen := PrinterModel.MaxCmdLength - 10;
      BlockLen := BlockLen - (BlockLen mod 40);
    end else
      BlockLen := 40;
    Count := (Length(SaveLineData) div BlockLen) + 1;
    k := 0;
    for i := 0 to Count - 1 do
    begin
      LineNumber := k + SaveLineNumber;
      LineData := Copy(SaveLineData, i * BlockLen + 1, BlockLen);
      Result := LoadLineDataEx;
      if not DRV_SUCCESS(Result) then
        Break;
      Inc(k, BlockLen div 40);
    end;
    LineData := SaveLineData;
    LineNumber := SaveLineNumber;
  except
    Result := 0;
  end;
end;

// Отчёт по налогам

function TFiscalPrinter.PrintTaxReport: Integer;
begin
  Result := Send(#$43 + FPassw);
end;

{ Оперативный отчет НИ
  Команда: 	E8H. Длина сообщения: 5 байт.
  "	Пароль НИ (4 байта)
  Ответ:		E8H. Длина сообщения: 2 байта
  "	Код ошибки (1 байт) }

function TFiscalPrinter.PrintOperationalTaxReport: Integer;
begin
  Result := Send(#$E8 + FPassw);
end;

function TFiscalPrinter.GetECRPrinterStatus: Integer;
begin
  Result := Send(#$F9 + FPassw);
end;

function TFiscalPrinter.GetDevices: TLogicDevices;
begin
  if FDevices = nil then
    FDevices := TLogicDevices.Create;
  Result := FDevices;
end;

procedure TFiscalPrinter.AddCachedFieldStruct(ATableNumber, AFieldNumber: Integer; AFieldName: string; AFieldSize: Integer; AMinValue: Int64; AMaxValue: Int64; AFieldType: Boolean);
var
  mFieldStruct: TFieldStruct;
begin
  if FindCachedField(ATableNumber, AFieldNumber, mFieldStruct) then
    Exit;

  Logger.Debug('Struct Cached: ' + ATableNumber.ToString + ', ' + AFieldNumber.ToString + ' ' + AFieldName + ', min= ' + AMinValue.ToString + ', max=' + AMaxValue.ToString + ', size=' + AFieldSize.ToString + ', type=' + SysUtils.BoolToStr(AFieldType, True));
  mFieldStruct.TableNumber := ATableNumber;
  mFieldStruct.FieldNumber := AFieldNumber;
  mFieldStruct.FieldSize := AFieldSize;
  mFieldStruct.FieldType := AFieldType;
  mFieldStruct.FieldName := AFieldName;
  mFieldStruct.MinValue := AMinValue;
  mFieldStruct.MaxValue := AMaxValue;

  FCachedFieldStruct.Add(mFieldStruct);
end;

function TFiscalPrinter.AddLD: Integer;
begin
  try
    Devices.AddLD;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.DeviceToParams(Device: TLogicDevice);
begin
  Logger.Debug('Apply LD params');
  Logger.Debug('Set COM ' + IntToStr(Device.LDComNumber));
  Logger.Debug('Set Baudrate ' + IntToStr(Device.LDBaudRate));
  Logger.Debug('Set ConnectionType ' + IntToStr(Device.LDConnectionType));
  Logger.Debug('Set ProtocolType ' + IntToStr(Device.LDProtocolType));
  Logger.Debug('Set SysAdminPassword ' + IntToStr(Device.LDSysAdminPassword));
  Logger.Debug('Set IPAddress ' + Device.LDIPAddress);
  Logger.Debug('Set ComputerName' + Device.LDComputerName);
  Logger.Debug('Set UseIPAddress' + BoolToStr[Device.LDUseIPAddress]);
  Logger.Debug('Set Timeout' + IntToStr(Device.LDTimeout));

  Timeout := Device.LDTimeout;
  BaudRate := Device.LDBaudRate;
  ComNumber := Device.LDComNumber;
  ComputerName := Device.LDComputerName;
  TCPPort := Device.LDTCPPort;
  IPAddress := Device.LDIPAddress;
  UseIPAddress := Device.LDUseIPAddress;
  ConnectionType := Device.LDConnectionType;
  EscapeIP := Device.LDEscapeIP;
  EscapePort := Device.LDEscapePort;
  EscapeTimeout := Device.LDEscapeTimeout;
  SysAdminPassword := Device.LDSysAdminPassword;
  ProtocolType := Device.LDProtocolType;
end;

function TFiscalPrinter.SetActiveLD: Integer;
var
  Device: TLogicDevice;
begin
  Logger.Debug('SetActive LD ' + IntToStr(Devices.LDNumber));
  Logger.Debug('Current LD ' + IntToStr(Devices.ActiveLDNumber));
  Device := Devices.ItemByNumber(Devices.LDNumber);
  if Device <> nil then
  begin
    if Devices.ActiveLDNumber <> Devices.LDNumber then
      Disconnect;
    Devices.ActiveLDNumber := Devices.LDNumber;
    DeviceToParams(Device);
    Result := ClearResult;
  end else
  begin
    Result := InvalidParam('LDNumber');
  end;
end;

function TFiscalPrinter.DeleteLD: Integer;
begin
  try
    Devices.DeleteLD;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.EnumLD: Integer;
begin
  try
    Devices.EnumLD;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetActiveLD: Integer;
begin
  try
    Devices.GetActiveLD;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetCountLD: Integer;
begin
  Result := ClearResult;
end;

function TFiscalPrinter.GetParamLD: Integer;
begin
  try
    Devices.GetParamLD;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.SetParamLD: Integer;
begin
  try
    Devices.SetParamLD;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.Get_LDBaudRate: Integer;
begin
  Result := Devices.LDBaudRate;
end;

procedure TFiscalPrinter.Set_LDBaudRate(Value: Integer);
begin
  Devices.LDBaudRate := Value;
end;

function TFiscalPrinter.Get_LDComNumber: Integer;
begin
  Result := Devices.LDComNumber;
end;

function TFiscalPrinter.Get_LDCount: Integer;
begin
  Result := Devices.Count;
end;

function TFiscalPrinter.Get_LDIndex: Integer;
begin
  Result := Devices.LDIndex;
end;

function TFiscalPrinter.Get_LDName: WideString;
begin
  Result := Devices.LDName;
end;

function TFiscalPrinter.Get_LDNumber: Integer;
begin
  Result := Devices.LDNumber;
end;

procedure TFiscalPrinter.Set_LDComNumber(Value: Integer);
begin
  Devices.LDComNumber := Value;
end;

procedure TFiscalPrinter.Set_LDIndex(Value: Integer);
begin
  Devices.LDIndex := Value;
end;

procedure TFiscalPrinter.Set_LDName(const Value: WideString);
begin
  Devices.LDName := Value;
end;

procedure TFiscalPrinter.Set_LDNumber(Value: Integer);
begin
  Devices.LDNumber := Value;
end;

function TFiscalPrinter.Get_LDComputerName: AnsiString;
begin
  Result := Devices.LDComputerName;
end;

procedure TFiscalPrinter.Set_LDComputerName(const Value: AnsiString);
begin
  Devices.LDComputerName := Value;
end;

function TFiscalPrinter.Get_LDTimeout: Integer;
begin
  Result := Devices.LDTimeout;
end;

procedure TFiscalPrinter.Set_LDTimeout(Value: Integer);
begin
  Devices.LDTimeout := Value;
end;

procedure TFiscalPrinter.Set_ComputerName(const Value: AnsiString);
begin
  if Value <> ComputerName then
  begin
    FConnectionParams.ComputerName := Value;
    FComputerNameChanged := True;
  end;
end;

function TFiscalPrinter.Get_LD1CAdminPassword: Integer;
begin
  Result := Devices.LD1CAdminPassword;
end;

function TFiscalPrinter.Get_LD1CUserPassword: Integer;
begin
  Result := Devices.LD1CUserPassword;
end;

procedure TFiscalPrinter.Set_LD1CAdminPassword(Value: Integer);
begin
  Devices.LD1CAdminPassword := Value;
end;

procedure TFiscalPrinter.Set_LD1CUserPassword(Value: Integer);
begin
  Devices.LD1CUserPassword := Value;
end;

function TFiscalPrinter.Get_LD1CIsFiscalCheck: Boolean;
begin
  Result := Devices.LD1CIsFiscalCheck;
end;

function TFiscalPrinter.Get_LD1CIsOpenedCheck: Boolean;
begin
  Result := Devices.LD1CIsOpenedCheck;
end;

function TFiscalPrinter.Get_LD1CIsReturnCheck: Boolean;
begin
  Result := Devices.LD1CIsReturnCheck;
end;

function TFiscalPrinter.Get_LD1CTax: T1CTax;
begin
  Result := Devices.LD1CTax;
end;

procedure TFiscalPrinter.Set_LD1CTax(Value: T1CTax);
begin
  Devices.LD1CTax := Value;
end;

procedure TFiscalPrinter.Set_LD1CIsFiscalCheck(Value: Boolean);
begin
  Devices.LD1CIsFiscalCheck := Value;
end;

procedure TFiscalPrinter.Set_LD1CIsOpenedCheck(Value: Boolean);
begin
  Devices.LD1CIsOpenedCheck := Value;
end;

procedure TFiscalPrinter.Set_LD1CIsReturnCheck(Value: Boolean);
begin
  Devices.LD1CIsReturnCheck := Value;
end;

function TFiscalPrinter.Get_LD1CCloseSession: Boolean;
begin
  Result := Devices.LD1CCloseSession;
end;

procedure TFiscalPrinter.Set_LD1CCloseSession(Value: Boolean);
begin
  Devices.LD1CCloseSession := Value;
end;

function TFiscalPrinter.Get_LD1CNonFiscalCheckNumber: Integer;
begin
  Result := Devices.LD1CNonFiscalCheckNumber;
end;

procedure TFiscalPrinter.Set_LD1CNonFiscalCheckNumber(Value: Integer);
begin
  Devices.LD1CNonFiscalCheckNumber := Value;
end;

function TFiscalPrinter.Get_LD1CSerialNumber: AnsiString;
begin
  Result := Devices.LD1CSerialNumber;
end;

procedure TFiscalPrinter.Set_LD1CSerialNumber(const Value: AnsiString);
begin
  Devices.LD1CSerialNumber := Value;
end;

function TFiscalPrinter.Get_LD1CLineLength: Integer;
begin
  Result := Devices.LD1CLineLength;
end;

procedure TFiscalPrinter.Set_LD1CLineLength(Value: Integer);
begin
  Devices.LD1CLineLength := Value;
end;

function TFiscalPrinter.Get_LD1CTaxProgrammed: Boolean;
begin
  Result := Devices.LD1CTaxProgrammed;
end;

procedure TFiscalPrinter.Set_LD1CTaxProgrammed(Value: Boolean);
begin
  Devices.LD1CTaxProgrammed := Value;
end;

function TFiscalPrinter.Get_LD1CPayNames: T1CPayNames;
begin
  Result := Devices.LD1CPaynames;
end;

procedure TFiscalPrinter.Set_LD1CPayNames(Value: T1CPayNames);
begin
  Devices.LD1CPaynames := Value;
end;

function TFiscalPrinter.Get_LD1CPayProgrammed: Boolean;
begin
  Result := Devices.LD1CPayProgrammed;
end;

procedure TFiscalPrinter.Set_LD1CPayProgrammed(Value: Boolean);
begin
  Devices.LD1CPayProgrammed := Value;
end;

function TFiscalPrinter.Get_LD1CCapGetShortECRStatus: Boolean;
begin
  Result := Devices.LD1CCapGetShortECRStatus;
end;

function TFiscalPrinter.Get_LD1CCapOpenCheck: Boolean;
begin
  Result := Devices.LD1CCapOpenCheck;
end;

procedure TFiscalPrinter.Set_LD1CCapOpenCheck(Value: Boolean);
begin
  Devices.LD1CCapOpenCheck := Value;
end;

procedure TFiscalPrinter.Set_LD1CCapSetShortECRStatus(Value: Boolean);
begin
  Devices.LD1CCapGetShortECRStatus := Value;
end;

function TFiscalPrinter.Get_LD1CLogoSize: Integer;
begin
  Result := Devices.LD1CLogoSize;
end;

function TFiscalPrinter.Get_LD1CPrintLogo: Boolean;
begin
  Result := Devices.LD1CPrintLogo;
end;

procedure TFiscalPrinter.Set_LD1CLogoSize(Value: Integer);
begin
  Devices.LD1CLogoSize := Value;
end;

procedure TFiscalPrinter.Set_LD1CPrintLogo(Value: Boolean);
begin
  Devices.LD1CPrintLogo := Value;
end;

function TFiscalPrinter.Get_LDTaxPassword: Integer;
begin
  Result := Devices.LDTaxPassword;
end;

procedure TFiscalPrinter.Set_LDTaxPassword(Value: Integer);
begin
  Devices.LDTaxPassword := Value;
end;

procedure TFiscalPrinter.DriverConnect;
begin
  Logger.Debug('DriverConnect');
  Lock;
  try
    Driver.Connect;
  finally
    Unlock;
  end;
end;

function TFiscalPrinter.ServerConnect: Integer;
begin
  try
    // Отключаемся только если изменили имя компьютера
    if FComputerNameChanged then
      Driver.Disconnect;

    DriverConnect;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.Get_ServerConnected: Boolean;
begin
  Result := HasDriver;
end;

function TFiscalPrinter.ServerCheckKey: Integer;
begin
  { Ничего не делает }
  Result := ClearResult;
end;

function TFiscalPrinter.GetFontMetrics: Integer;

  function GetFonts(const Fonts: array of TFontRec): Integer;
  var
    FontRec: TFontRec;
  begin
    Result := ClearResult;
    FFontCount := High(Fonts) - Low(Fonts) + 1;
    if (FontType > 0) and (FontType <= FFontCount) then
    begin
      FontRec := Fonts[FontType - 1];
      FPrintWidth := FontRec.LineWidth;
      FCharWidth := FontRec.CharWidth;
      FCharHeight := FontRec.CharHeight;
    end else
    begin
      Result := InvalidParam('FontType');
    end;
  end;

  function ReadByte(TableNumber, RowNumber, FieldNumber: Integer): Integer;
  var
    Data: AnsiString;
  begin
    FieldSize := 1;
    FieldType := False;
    Data := #$1F + FPassw + AnsiChar(TableNumber) + WordToStr(RowNumber) + AnsiChar(FieldNumber);
    Result := Send(Data);
  end;

  function GetFRF4Font: Integer;
  var
    FontCompression: Boolean; // сжатие шрифтов
  begin
    FontCompression := False;
    if UseJournalRibbon then
    begin
      Result := ReadByte(1, 1, 31);
      FontCompression := ValueOfFieldInteger <> 0;
    end else
    begin
      if UseReceiptRibbon then
      begin
        Result := ReadByte(1, 1, 32);
        FontCompression := ValueOfFieldInteger <> 0;
      end else
      begin
        Result := InvalidParam('TapeType');
      end;
    end;
    if Result <> 0 then
      Exit;
    if FontCompression then
      Result := GetFonts(FRF4FontsCompressed)
    else
      Result := GetFonts(FRF4Fonts);
  end;

  function GetShtrih500Font: Integer;
  var
    FontCompression: Boolean; // сжатие шрифтов
  begin
    Result := ReadByte(1, 1, 9);
    FontCompression := ValueOfFieldInteger <> 0;
    if not DRV_SUCCESS(Result) then
      Exit;
    if FontCompression then
      Result := GetFonts(Shtrih500FontsCompressed)
    else
      Result := GetFonts(Shtrih500Fonts);
  end;

  function Get950Fonts: Integer;
  var
    LineSpacing: Integer;
  begin
    Result := ReadByte(1, 1, 36);
    if DRV_SUCCESS(Result) then
    begin
      Result := GetFonts(Shtrih950Fonts);
      // Добавляем межстрочный интервал
      if DRV_SUCCESS(Result) then
      begin
        LineSpacing := Round2(ValueOfFieldInteger / 2);
        FCharHeight := FCharHeight + LineSpacing;
      end;
    end;
  end;

  function GetComboFonts: Integer;
  var
    LineSpacing: Byte; // Межстрочный интервал
    FontCompression: Boolean; // Сжатие шрифтов
  begin
    Result := ReadByte(1, 1, 33);
    if not DRV_SUCCESS(Result) then
      Exit;
    FontCompression := ValueOfFieldInteger <> 0;
    // Межстрочный интервал
    Result := ReadByte(1, 1, 31);
    if not DRV_SUCCESS(Result) then
      Exit;
    LineSpacing := ValueOfFieldInteger;
    if FontCompression then
      LineSpacing := Round2(LineSpacing / 2);
    // Шрифты
    if FontCompression then
      Result := GetFonts(ShtrihMiniFontsCompressed)
    else
      Result := GetFonts(ShtrihMiniFonts);
    if not DRV_SUCCESS(Result) then
      Exit;
    // Изменяем высоту шрифта
    FCharHeight := FCharHeight - 5 + LineSpacing;
  end;

  function GetShtrihMiniFRKFonts: Integer;
  var
    Compression: Boolean; // Сжатие шрифтов
  begin
    // Сжатие шрифтов на чековой ленте
    Result := ReadByte(1, 1, 25);
    if not DRV_SUCCESS(Result) then
      Exit;
    Compression := ValueOfFieldInteger <> 0;
    // Шрифты
    if Compression then
      Result := GetFonts(ShtrihMiniFontsCompressed)
    else
      Result := GetFonts(ShtrihMiniFonts);
  end;

  function GetShtrihMiniFRK2Fonts: Integer;
  var
    Compression: Boolean;
  begin
    // Сжатие шрифтов на чековой ленте
    Result := ReadByte(1, 1, 25);
    if not DRV_SUCCESS(Result) then
      Exit;
    Compression := ValueOfFieldInteger <> 0;
    // Шрифты
    if Compression then
      Result := GetFonts(ShtrihMini2FontsCompressed)
    else
      Result := GetFonts(ShtrihMini2Fonts);
  end;

  function GetElvesFRKFonts: Integer;
  var
    Compression: Boolean;
  begin
    // Сжатие шрифтов на чековой ленте
    Result := ReadByte(1, 1, 25);
    if not DRV_SUCCESS(Result) then
      Exit;
    Compression := ValueOfFieldInteger <> 0;
    // Шрифты
    if Compression then
      Result := GetFonts(ElvesFRKFontsCompressed)
    else
      Result := GetFonts(ElvesFRKFonts);
  end;

  function GetFontParams: Integer;
  begin
    case GetModel of
      dmShtrihFRF3:
        Result := GetFonts(FRF3Fonts);
      dmShtrihFRF4:
        Result := GetFRF4Font;
      dmShtrihFRFKaz:
        Result := GetFRF4Font;
      dmElvesMiniFRF:
        Result := GetFRF4Font;
      dmShtrihFRK:
        Result := GetFRF4Font;
      dmShtrih950K:
        Result := Get950Fonts;
      dmShtrih950KV2:
        Result := Get950Fonts;
      dmElvesFRK:
        Result := GetElvesFRKFonts;
      dmShtrihMiniFRK:
        Result := GetShtrihMiniFRKFonts;
      dmShtrihMiniFRK2:
        Result := GetShtrihMiniFRK2Fonts;
      dmShtrihFRFBel:
        Result := GetFRF4Font;
      dmShtrihComboFRKv1:
        Result := GetComboFonts;
      dmShtrihComboFRKv2:
        Result := GetComboFonts;
      dmShtrihPOSF:
        Result := GetFRF4Font;
      dmShtrih500:
        Result := GetShtrih500Font;
    else
      Result := 55;
      ResultCode := Result;
      ResultCodeDescription := TPrinterError.GetDescription(55);
    end;
  end;

begin
  try
    ECRInput := '';
    ECROutput := '';
    // Запрос параметров устройства
    if (not FGetDeviceMetrics) and (not TestMode) and (not FGetExDeviceMetrics) then
    begin
      Result := GetDeviceMetrics;
      if Result <> 0 then
        Exit;
    end;
    // Проверка версий протокола
    if ((UMajorProtocolVersion = 1) and (UMinorProtocolVersion >= 5)) or (UMajorProtocolVersion > 1) then
    begin
      Result := Send(#$26 + FPassw + AnsiChar(GetFontType))
    end else
    begin
      Result := GetFontParams;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetFreeLDNumber: Integer;
begin
  Result := Devices.GetFreeNumber;
end;

function TFiscalPrinter.Get_LogOn: Boolean;
begin
  Result := GlobalLogger.Enabled;
end;

procedure TFiscalPrinter.Set_LogOn(Value: Boolean);
begin
  GlobalLogger.Enabled := Value;
end;

function TFiscalPrinter.ReadTable2: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$1F + FPassw + AnsiChar(GetTableNumber) + WordToStr(GetRowNumber) + AnsiChar(FieldNumber);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.LogIBMStatusBytes(AShort: Boolean);

  procedure LogIBMStatus(AByte, ABit: Integer; const AText: AnsiString);
  begin
    if TestBit(AByte, ABit) then
      Logger.Debug(' [+] ' + AText)
    else
      Logger.Debug(' [ ] ' + AText);
  end;

begin
  if not AShort then
  begin
    Logger.Debug('IBM Date: ' + DateToStr(ECRDate));
    Logger.Debug('IBM Time: ' + DateToStr(ECRTime));
    Logger.Debug('IBM Session Number: ' + IntToStr(SessionNumber));
    Logger.Debug('IBM Doc Number: ' + IntToStr(IBMDocNumber));
    Logger.Debug('IBM Sale rec number: ' + IntToStr(IBMLastSaleReceiptNumber));
    Logger.Debug('IBM Buy rec number: ' + IntToStr(IBMLastBuyReceiptNumber));
    Logger.Debug('IBM Return sale rec number: ' + IntToStr(IBMLastReturnSaleReceiptNumber));
    Logger.Debug('IBM Return buy rec number: ' + IntToStr(IBMLastReturnBuyReceiptNumber));
    Logger.Debug('IBM Open session Date: ' + Format('%.2d.%.2d.%.2d', [IBMSessionDay, IBMSessionMonth, IBMSessionYear]));
    Logger.Debug('IBM Open session Time: ' + Format('%.2d:%.2d:%.2d', [IBMSessionHour, IBMSessionMin, IBMSessionSec]));
    Logger.Debug('IBM cash total' + Format('%.2f', [Summ1]));
  end;

  Logger.Debug(Format('IBM Status byte 1 = %.2x', [IBMStatusByte1]));
  LogIBMStatus(IBMStatusByte1, 0, 'Command complete');
  LogIBMStatus(IBMStatusByte1, 1, 'Cash receipt right home position');
  LogIBMStatus(IBMStatusByte1, 2, 'Left home position');
  LogIBMStatus(IBMStatusByte1, 3, 'Document right home position');
  LogIBMStatus(IBMStatusByte1, 4, 'Reserved. Always 0');
  LogIBMStatus(IBMStatusByte1, 5, 'Ribbon cover open');
  LogIBMStatus(IBMStatusByte1, 6, 'Cash receipt print error');
  LogIBMStatus(IBMStatusByte1, 7, 'Command reject');

  Logger.Debug(Format('IBM Status byte 2 = %.2x', [IBMStatusByte2]));
  LogIBMStatus(IBMStatusByte2, 0, 'Document ready');
  LogIBMStatus(IBMStatusByte2, 1, 'Document present under the front sensor');
  LogIBMStatus(IBMStatusByte2, 2, 'Document present under the top sensor');
  LogIBMStatus(IBMStatusByte2, 3, 'Reserved. Always equals 1');
  LogIBMStatus(IBMStatusByte2, 4, 'Print buffer held');
  LogIBMStatus(IBMStatusByte2, 5, 'Open throat position');
  LogIBMStatus(IBMStatusByte2, 6, 'Buffer empty');
  LogIBMStatus(IBMStatusByte2, 7, 'Buffer Full');

  Logger.Debug(Format('IBM Status byte 3 = %.2x', [IBMStatusByte3]));
  LogIBMStatus(IBMStatusByte3, 0, 'Memory sector is full');
  LogIBMStatus(IBMStatusByte3, 1, 'Home error');
  LogIBMStatus(IBMStatusByte3, 2, 'Document error');
  LogIBMStatus(IBMStatusByte3, 3, 'Flash EPROM load error or MCT load error');
  LogIBMStatus(IBMStatusByte3, 4, 'Reserved. Always equals 0');
  LogIBMStatus(IBMStatusByte3, 5, 'User flash storage sector is full');
  LogIBMStatus(IBMStatusByte3, 6, 'Firmware error');
  LogIBMStatus(IBMStatusByte3, 7, 'Command complete');

  Logger.Debug(Format('IBM Status byte 4 = %.2x', [IBMStatusByte4]));

  Logger.Debug(Format('IBM Status byte 5 = %.2x', [IBMStatusByte5]));
  LogIBMStatus(IBMStatusByte5, 0, 'Printer ID Request Address command');
  LogIBMStatus(IBMStatusByte5, 1, 'EC Level');
  LogIBMStatus(IBMStatusByte5, 2, 'MICR Read');
  LogIBMStatus(IBMStatusByte5, 3, 'MCT Read');
  LogIBMStatus(IBMStatusByte5, 4, 'User flash read');
  LogIBMStatus(IBMStatusByte5, 5, 'Reserved. Defaults to 1');
  LogIBMStatus(IBMStatusByte5, 6, 'Reserved');
  LogIBMStatus(IBMStatusByte5, 7, 'Reserved');

  Logger.Debug(Format('IBM Status byte 6 = %.2x', [IBMStatusByte6]));

  Logger.Debug(Format('IBM Status byte 7 = %.2x', [IBMStatusByte7]));
  LogIBMStatus(IBMStatusByte7, 0, 'Station selection low order bit');
  LogIBMStatus(IBMStatusByte7, 1, 'Reserved');
  LogIBMStatus(IBMStatusByte7, 2, 'Reserved');
  LogIBMStatus(IBMStatusByte7, 3, 'Cash drawer status');
  LogIBMStatus(IBMStatusByte7, 4, 'Print key pressed');
  LogIBMStatus(IBMStatusByte7, 5, 'Reserved. Defaults to 1');
  LogIBMStatus(IBMStatusByte7, 6, 'Station Selection high order bit');
  LogIBMStatus(IBMStatusByte7, 7, 'Document feed error');

  Logger.Debug(Format('IBM Status byte 8 = %.2x', [IBMStatusByte8]));
  LogIBMStatus(IBMStatusByte8, 0, 'Fiscal offline mode');
  LogIBMStatus(IBMStatusByte8, 1, 'Fiscal offline mode');
  LogIBMStatus(IBMStatusByte8, 2, 'Fiscal offline mode');
  LogIBMStatus(IBMStatusByte8, 3, 'Reserved');
  LogIBMStatus(IBMStatusByte8, 4, 'Reserved');
  LogIBMStatus(IBMStatusByte8, 5, 'Reserved');
  LogIBMStatus(IBMStatusByte8, 6, 'Reserved');
  LogIBMStatus(IBMStatusByte8, 7, 'Reserved');

  Logger.Debug(Format('IBM Flags = %.2x', [IBMFlags]));
  if AShort then
    LogIBMStatus(IBMFlags, 0, 'Print buffer empty')
  else
  begin
    LogIBMStatus(IBMFlags, 0, 'Serialized');
    LogIBMStatus(IBMFlags, 1, 'Fiscalized');
    LogIBMStatus(IBMFlags, 2, 'Activated');
    LogIBMStatus(IBMFlags, 3, 'Session opened');
    LogIBMStatus(IBMFlags, 4, '24 hours finished');
  end;
end;

function TFiscalPrinter.GetIBMStatus: Integer;
begin
  Result := Send(#$D0 + FPassw);

end;

function TFiscalPrinter.GetShortIBMStatus: Integer;
begin
  Result := Send(#$D1 + FPassw);

end;

function TFiscalPrinter.Get_LDEscapeIP: AnsiString;
begin
  Result := Devices.LDEscapeIP;
end;

function TFiscalPrinter.Get_LDEscapePort: Integer;
begin
  Result := Devices.LDEscapePort;
end;

procedure TFiscalPrinter.Set_LDEscapeIP(const Value: AnsiString);
begin
  Devices.LDEscapeIP := Value;
end;

procedure TFiscalPrinter.Set_LDEscapePort(Value: Integer);
begin
  Devices.LDEscapePort := Value;
end;

function TFiscalPrinter.Get_LDEscapeTimeout: Integer;
begin
  Result := Devices.LDEscapeTimeout;
end;

procedure TFiscalPrinter.Set_LDEscapeTimeout(Value: Integer);
begin
  Devices.LDEscapeTimeout := Value;
end;

function TFiscalPrinter.CommandCount: Integer;
begin
  Result := Commands.Count;
end;

function TFiscalPrinter.GetCommandParams: Integer;
var
  Command: TPrinterCommand;
begin
  if (CommandIndex >= 0) and (CommandIndex < Commands.Count) then
  begin
    Command := Commands[CommandIndex];
    FCommandCode := Command.Code;
    FCommandName := Command.Name;
    FCommandTimeout := Command.Timeout;
    FCommandDefTimeout := Command.DefTimeout;

    Result := ClearResult;
  end else
  begin
    Result := InvalidParam('CommandIndex');
  end;
end;

function TFiscalPrinter.GetCommandRetryCount: Integer;
begin
  Result := FCommandRetryCount;
end;

procedure TFiscalPrinter.SetCommandRetryCount(const Value: Integer);
begin
  FCommandRetryCount := Value;
  FConnectionParams.CommandRetryCount := Value;
end;

function TFiscalPrinter.LoadCommandParams: Integer;
begin
  try
    CommandsFileName := IncludeTrailingBackSlash(ExtractFilePath(GetDllFileName)) + 'Timeouts.cfg';
    Commands.LoadFromFile(CommandsFileName);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.SaveCommandParams: Integer;
begin
  try
    Commands.SaveToFile(CommandsFileName);
  except
    on E: Exception do
    begin
      Logger.Debug('SaveCommandParams ' + E.Message);
    end;
  end;
  Result := ClearResult;
end;

function TFiscalPrinter.SetCommandParams: Integer;
var
  Command: TPrinterCommand;
begin
  if (CommandIndex >= 0) and (CommandIndex < Commands.Count) then
  begin
    Command := Commands[CommandIndex];
    Command.Timeout := FCommandTimeout;
    Result := ClearResult;
  end else
  begin
    Result := InvalidParam('CommandIndex');
  end;
end;

function TFiscalPrinter.SetAllCommandsParams: Integer;
begin
  Commands.SetTimeout(CommandTimeout);
  Result := ClearResult;
end;

function TFiscalPrinter.SetDefCommandsParams: Integer;
begin
  Commands.SetDefTimeout;
  Result := ClearResult;
end;

function TFiscalPrinter.GetTimeoutsUsing: Integer;
begin
  Result := Commands.TimeoutsUsing;
end;

procedure TFiscalPrinter.SetTimeoutsUsing(Value: Integer);
begin
  Commands.TimeoutsUsing := Value;
end;

function TFiscalPrinter.Get_IBMSessionDateTime: TDateTime;
begin
  Result := ECRDateTimeToDateTime(FIBMSessionDate);
end;

function TFiscalPrinter.GetSlipStringIntervals: AnsiString;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to 199 do
    Result := Result + AnsiChar(Intervals[i]);
end;

procedure TFiscalPrinter.SetSlipStringIntervals(const Value: AnsiString);
var
  i: Integer;
  Count: Integer;
begin
  Count := min(Length(Value), 199);
  for i := 1 to Count do
    Intervals[i] := Ord(Value[i]);
end;

function TFiscalPrinter.Get_ValueOfFieldInteger: Integer;
var
  Code: Integer;
  Value: Int64;
begin
  try
    Val(ValueOfFieldString, Value, Code);
  except
    on E: Exception do
      Logger.Error('Get_ValueOfFieldInteger ' + ValueOfFieldString + ' ' + E.Message);
  end;
  Result := Value;
  Logger.Debug('ValueOfFieldInteger = ' + Result.ToString);
end;

procedure TFiscalPrinter.Set_ValueOfFieldInteger(Value: Integer);
begin
  ValueOfFieldString := Int64ToStr(Int64(Value));
end;

function TFiscalPrinter.SaveState: Integer;
begin
  State.Assign(Self);
  Result := 0;
end;

function TFiscalPrinter.RestoreState: Integer;
begin
  Assign(State);
  Result := 0;
end;

function TFiscalPrinter.GetPortLocked: Boolean;
begin
  Lock;
  try
    Result := Driver.PortLocked;
  finally
    Unlock;
  end;
end;

(*

  Печать линии
  Команда: 	C5H. Длина сообщения: X + 7 байт.
  ·	Пароль оператора (4 байта)
  ·	Количество повторов (2 байта)
  ·	Графическая информация (X байт)
  Ответ:		C5H. Длина сообщения: 3 байта.
  ·	Код ошибки (1 байт)
  ·	Порядковый номер оператора (1 байт) 1…30

*)

(*

  Печать графической линии
  Команда: C5H. Длина сообщения: 7+X+Y байт.
  Пароль оператора (4 байта)
  Количество повторов линий (2 байта) 1…1200
  Флаги* (X=1 байт) Бит 0 - контрольная лента,
  Бит 1 - чековая лента,
  Бит 2 - подкладной документ,
  Бит 3** - слип чек;
  Бит 7 - отложенная печать линии
  Графическая информация (Y*** байт)
  Ответ: C5H. Длина сообщения: 3 байта.
  Код ошибки (1 байт)
  Порядковый номер оператора (1 байт) 1…30

  * - поддерживается если в ответе на команду F7H расширенного запроса в
  параметрах модели ФР установлен бит 37 (поддержка флагов печати);
  если в длине сообщения X=0, то ККТ игнорирует поле Флаги;

  ** - поддерживается если в ответе на команду F7H расширенного запроса в
  параметрах модели ФР установлен бит 34 (поддержка "Бит 3 - слип чек");

  *** - ширина печатаемой графической линии зависит от модели ККТ и определяется
  числовым полем в ответе на команду F7H расширенного запроса в параметрах
  модели ФР;

*)

function TFiscalPrinter.PrintLine: Integer;

  function IsSwapBytes: Boolean;
  begin
    case SwapBytesMode of
      SwapBytesModeSwap:
        Result := True;
      SwapBytesModeNoSwap:
        Result := False;
      SwapBytesModeProp:
        Result := LineSwapBytes;
      SwapBytesModeModel:
        Result := PrinterModel.SwapLineBytes;
    else
      Result := PrinterModel.SwapLineBytes;
    end;
  end;

var
  S: AnsiString;
  Flags: AnsiString;
  MaxWidth: Integer;
begin
  try
    S := LineData;
    if IsSwapBytes then
      S := SwapBytes(LineData);
    if PrinterModel.CapPrintFlagsGraphics then
      Flags := AnsiChar(GetTapeType)
    else
      Flags := '';
    MaxWidth := PrinterModel.MaxLineWidth;
    if (PrinterModel.ModelID = 19) and (Length(S) > MaxWidth) then
      MaxWidth := 72;

    if (UMajorProtocolVersion > 1) or ((UMinorProtocolVersion >= 13) and (UMajorProtocolVersion = 1)) then
    begin
      S := GetStr2(S, MaxWidth);
    end;

    Result := Send(#$C5 + FPassw + WordToStr(GetLineNumber) + Flags + S);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetPrintString: WideString;
begin
  Result := StrToDevice(ConvertCharCodeString(StringForPrinting));
end;

function FilterStringText(Data: AnsiString): AnsiString;
var
  P: Integer;
  i: Integer;
resourcestring
  SFiscalMemory = 'ФП';
  SGraphics = 'Графика';
  SBarcode = 'Штрихкод';
begin
  Result := '';
  // Знак ФП
  P := Pos(#$0D#$0E#$0F, Data);
  if P <> 0 then
  begin
    Delete(Data, P, 3);
    Insert(SFiscalMemory, Data, P);
  end;
  // Остальные символы
  for i := 1 to Length(Data) do
  begin
    if Data[i] >= #$20 then
      Result := Result + Data[i]
    else
    begin
      case Data[i] of
        #$08:
          Result := Result + SGraphics + ': ';
        #$09:
          Result := Result + SBarcode + ': ';
        #$10:
          Result := Result + '=';
        #$0C:
          Result := Result + '-';
      end;
    end;
  end;
  Result := TrimRight(Result);
end;

function FilterStringChar(Data: AnsiString): AnsiString;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(Data) do
  begin
    if Data[i] >= #$20 then
      Result := Result + Data[i]
    else
      Result := Result + Format('#%.2x ', [Ord(Data[i])]);
  end;
  Result := TrimRight(Result);
end;

function FilterString(const Data: AnsiString; PrintBufferFormat: Integer): AnsiString;
begin
  case PrintBufferFormat of
    0:
      Result := Data;
    1:
      Result := FilterStringText(Data);
    2:
      Result := FilterStringChar(Data);
  else
    Result := Data;
  end;
end;

function TrimReportString(const Data: AnsiString): AnsiString;
begin
  Result := TrimRight(Copy(Data, 7, Length(Data)));
  // Первые 6 байт - ESC коды принтера
  Result := StringReplace(Result, #$FE, '=', [rfReplaceAll]);
  // фискальный признак Ярус-01
  Result := StringReplace(Result, #$FD, '=', [rfReplaceAll]);
  // фискальный признак Ярус-02
  Result := Str866To1251(Result);
end;

function FilterReportString(const Data: AnsiString; PrintBufferFormat: Integer): AnsiString;
begin
  case PrintBufferFormat of
    0:
      Result := Data;
    1:
      Result := StrToHex(Data);
    2:
      Result := TrimReportString(Data)  else
    Result := Data;
  end;
end;

// function TFiscalPrinter.GetJournal: TPrinterJournal;
// begin
// if FJournal = nil then
// FJournal := GetPrinterJournalClass(GetUModelValue).Create(FDrvFR48);
// Result := FJournal;
// end;

procedure TFiscalPrinter.BeforeCommand(Code: Integer);
var
  State: TDriverState;
begin
  if not PluginsEnabled then
    Exit;
  State := TDriverState.Create;
  State.Assign(Self);
  try
    { if Code <> $FC then
      begin
      if JournalEnabled then
      Journal.BeforeCommand(Code);
      end; }

    Plugins.BeforeCommand(Code);
  finally
    Assign(State);
    State.Free;
  end;
end;

procedure TFiscalPrinter.AfterCommand(Code: Integer);
var
  State: TDriverState;
begin
  if not PluginsEnabled then
    Exit;

  State := TDriverState.Create;
  State.Assign(Self);
  try
    Plugins.AfterCommand(Code);
  finally
    Assign(State);
    State.Free;
  end;
end;

function TFiscalPrinter.GetJournalRowCount: Integer;
begin
  Result := 0;
  // Result := Journal.Journal.Count;
end;

function TFiscalPrinter.GetJournalText: AnsiString;
begin
  Result := '';
  // Result := Journal.Journal.Text;
end;

function TFiscalPrinter.JournalClear: Integer;
begin
  // Journal.Journal.Clear;
  Result := ClearResult;
end;

function TFiscalPrinter.JournalGetRow: Integer;
begin
  Result := 0;
  { if (JournalRowNumber >= 1)and(JournalRowNumber <= Journal.Journal.Count) then
    begin
    JournalRow := Journal.Journal[JournalRowNumber-1];
    Result := ClearResult;
    end else
    begin
    Result := E_INVALIDPARAM;
    end; }
end;

function TFiscalPrinter.JournalInit: Integer;
begin
  Result := ClearResult;
  { try
    Journal.JournalInit;
    Result := ClearResult;
    except
    on E: Exception do
    Result := HandleException(E);
    end; }
end;

procedure TFiscalPrinter.DecodeC8(const Data: AnsiString);
begin
  CheckMinLength(Data, 4);
  // Количество строк в буфере печати
  FPrintBufferLineNumber := BinToInt(Data, 1, 2);
  // Количество напечатанных строк
  LineNumber := BinToInt(Data, 3, 2);
end;

procedure TFiscalPrinter.DecodeC9(const Data: AnsiString);
begin
  StringForPrinting := FilterString(Data, PrintBufferFormat);
end;

procedure TFiscalPrinter.DecodeDB(const Data: AnsiString);
begin
  if Length(Data) > 0 then
    OperatorNumber := Ord(Data[1]);
  StringForPrinting := FilterReportString(Copy(Data, 2, Length(Data)), PrintBufferFormat);
end;

function TFiscalPrinter.ClearPrintBuffer: Integer;
begin
  Result := Send(#$CA + FPassw);
end;

function TFiscalPrinter.ReadPrintBufferLine: Integer;
begin
  Result := Send(#$C9 + FPassw + IntToBin(GetLineNumber, 2));
end;

function TFiscalPrinter.ReadPrintBufferLineNumber: Integer;
begin
  Result := Send(#$C8 + FPassw);
end;

{ Получить строку из буфера отчета }

function TFiscalPrinter.ReadReportBufferLine: Integer;
begin
  try
    if (DocumentNumber < $00) or (DocumentNumber > $FF) then
      InvalidProp('DocumentNumber');
    if (LineNumber < $00) or (LineNumber > $FF) then
      InvalidProp('LineNumber');
    Result := Send(#$DB + FPassw + AnsiChar(DocumentNumber) + AnsiChar(LineNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{ Очистка буфера отчетов }

function TFiscalPrinter.ClearReportBuffer: Integer;
begin
  Result := Send(#$DC + FPassw);
end;

// Поиск устройства

function TFiscalPrinter.FindCachedField(ATableNumber, AFieldNumber: Integer; var AFieldStruct: TFieldStruct): Boolean;
var
  mFieldStruct: TFieldStruct;
begin
  Result := False;
  for mFieldStruct in FCachedFieldStruct do
  begin
    if (ATableNumber = mFieldStruct.TableNumber) and (AFieldNumber = mFieldStruct.FieldNumber) then
    begin
      AFieldStruct := mFieldStruct;
      Result := True;
      Break;
    end;
  end;
end;

function TFiscalPrinter.FindDevice: Integer;
var
  i: Integer;
  j: Integer;
  Ports: TStringList;
  SaveTimeout: Integer;
  SaveBaudRate: Integer;
  SavePortNumber: Integer;
  SaveResultCode: Integer;
  SaveResultCodeDescription: WideString;
begin
  SaveTimeout := Timeout;
  SaveBaudRate := BaudRate;
  SavePortNumber := PortNumber;

  ClosePort;
  Disconnect;
  Result := ClearResult;
  Ports := TStringList.Create;
  try
    // Timeout := 100;
    TDevicePorts.GetPorts(Ports);
    for i := 0 to Ports.Count - 1 do
    begin
      ComNumber := Integer(Ports.Objects[i]);
      for j := Low(BAUD_RATE_CODE_SEARCH_ORDER) to High(BAUD_RATE_CODE_SEARCH_ORDER) do
      begin
        Timeout := 200;
        BaudRate := BAUD_RATE_CODE_SEARCH_ORDER[j];
        Result := GetDeviceMetrics;
        SaveResultCode := ResultCode;
        SaveResultCodeDescription := ResultCodeDescription;
        Disconnect;

        ResultCode := SaveResultCode;
        ResultCodeDescription := SaveResultCodeDescription;

        if Result = 0 then
        begin
          Timeout := SaveTimeout;
          // Если устройство найдено - сохраняем параметры
          SaveParams;
          Exit;
        end;
      end;
    end;
  finally
    Ports.Free;
    Timeout := SaveTimeout;
  end;
  BaudRate := SaveBaudRate;
  PortNumber := SavePortNumber;
end;

// Завершение документа и печать клише следующего чека

function TFiscalPrinter.FinishDocument: Integer;
begin
  try
    CheckIntProp(FinishDocumentMode, 0, $FF, 'FinishDocumentMode');
    Result := Send(#$53 + FPassw + AnsiChar(FinishDocumentMode));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Печать рекламного текста

function TFiscalPrinter.PrintTrailer: Integer;
begin
  try
    Result := Send(#$54 + FPassw);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Параметры оплаты по картам

function TFiscalPrinter.CardPayProperties: Integer;
begin
  Result := ClearResult;
end;

{ Печать клише }

function TFiscalPrinter.PrintCliche: Integer;
begin
  Result := Send(#$52 + FPassw);
end;

function TFiscalPrinter.PrintZReportInBuffer: Integer;
begin
  Result := Send(#$C6 + FPassw);
end;

function TFiscalPrinter.PrintZReportFromBuffer: Integer;
begin
  Result := Send(#$C7 + FPassw);
end;

function TFiscalPrinter.OutputReceipt: Integer;
begin
  Result := Send(#$F1 + FPassw + AnsiChar(ReceiptOutputType));
end;

function TFiscalPrinter.GetStatus: Integer;
begin
  case StatusCommand of
    STATUS_COMMAND_SHORT:
      Result := GetShortECRStatus;
    STATUS_COMMAND_LONG:
      Result := GetECRStatus;
  else
    if CapGetShortECRStatus then
    begin
      Result := GetShortECRStatus;
    end else
    begin
      Result := GetECRStatus;
    end;
  end;
end;

function TFiscalPrinter.ReadFFDVersion: Integer;
var
  ModelID: Integer;
begin
  ModelParamNumber := mpModelID;
  Check(ReadModelParamValue);
  ModelID := ModelParamValue;

  if ModelID = 152 then
    Result := ReadTableInt(17, 1, 17)
  else
  begin
    if ModelID = 19 then
      Result := ReadTableInt(10, 1, 4)
    else if IsModelType2(ModelID) then
      Result := ReadTableInt(10, 1, 29)
    else
      Result := ReadTableInt(17, 1, 17);
  end;
end;

function TFiscalPrinter.ReadTableInt(ATable, ARow, AField: Integer): Integer;
begin
  TableNumber := CorrectTableNumber(ATable);
  RowNumber := ARow;
  FieldNumber := AField;
  Check(ReadTable);
  Result := ValueOfFieldInteger;
end;

function TFiscalPrinter.ReadTableStr(ANumber: Integer; ARow: Integer; AField: Integer): string;
begin
  TableNumber := CorrectTableNumber(ANumber);
  RowNumber := ARow;
  FieldNumber := AField;
  Check(ReadTable);
  Result := ValueOfFieldString;
end;

procedure TFiscalPrinter.WriteTableInt(ATableNumber: Integer; ARow: Integer; AField: Integer; AValue: Integer);
begin
  TableNumber := CorrectTableNumber(ATableNumber);
  RowNumber := ARow;
  FieldNumber := AField;
  Check(GetFieldStruct);
  if FieldType then
    ValueOfFieldString := IntToStr(AValue)
  else
    ValueOfFieldInteger := AValue;
  Check(WriteTable);
end;

procedure TFiscalPrinter.WriteTableStr(ATableNumber: Integer; ARow: Integer; AField: Integer; const AValue: string);
begin
  TableNumber := CorrectTableNumber(ATableNumber);
  RowNumber := ARow;
  FieldNumber := AField;
  ValueOfFieldString := AValue;
  Check(WriteTable);
end;

function TFiscalPrinter.CorrectTableNumber(ANumber: Integer): Integer;
begin
  Result := ANumber;
(*
  if ANumber = 18 then
  begin
    ModelParamNumber := mpFSTableNumber;
    if ReadModelParamValue = 0 then
      Result := ModelParamValue;
  end else if ANumber = 19 then
  begin
    ModelParamNumber := mpOFDTableNumber;
    if ReadModelParamValue = 0 then
      Result := ModelParamValue;
  end else
    Result := ANumber;
*)
end;

procedure TFiscalPrinter.Feed(ALineCount: Integer);
var
  Res: Integer;
  RepCount: Integer;
begin
  UseReceiptRibbon := True;
  StringQuantity := ALineCount;
  RepCount := 0;
  repeat
    Res := FeedDocument;
    Inc(RepCount);
    if (Res = $50) or (Res = $4B) then
      Sleep(50);
  until ((Res <> $50) and (Res <> $4B)) or (RepCount >= 5);
end;

function TFiscalPrinter.NeedToChangeToFFD12: Boolean;
var
  FFDVersion: Integer;
  MaxFDValue: Integer;
begin
  Result := False;
  if not TestBit(FWUpdateFFDParams, 0) then
  begin
    Logger.Debug('FWUpdateFFDParams is off');
    Exit;
  end;
  Logger.Debug('FWUpdateFFDParams is on');
  ModelParamNumber := mpModelID;
  Check(ReadModelParamValue);
  if IsModelType2(ModelParamValue) then
    Exit;
  if ModelParamValue = 152 then
    Exit; // НАНО

  Logger.Debug('Проверка версии ФФД');
  FFDVersion := ReadFFDVersion;
  Logger.Debug('Current FFD Version: ' + FFDVersion.ToString);
  TableNumber := 17;
  FieldNumber := 17;
  RowNumber := 1;
  Check(GetFieldStruct);
  MaxFDValue := MaxValueOfField;
  Logger.Debug('Current Firmware FFD version: ' + MaxFDValue.ToString);
  if (MaxFDValue = 4) and (FFDVersion <> 4) then
  begin
    Result := True;
    Logger.Debug('Необходимо обновление версии ФФД');
  end;
end;

procedure TFiscalPrinter.CheckForSendedDocuments;
var
  T: Cardinal;
begin
  // Ожидание отправки всех документов в ОФД
  Logger.Debug('Ожидание отправки сообщений');
  T := GetTickCount;
  while True do
  begin
    Check(FNGetInfoExchangeStatus);
    if MessageCount = 0 then
    begin
      Logger.Debug('Все документы отправлены');
      Break;
    end;
    Sleep(500);
    if abs(GetTickCount - T) > (1000 * 60 * FWUpdateFFDWaitInterval) then
    begin
      Feed(2);
      PrintText('ВНИМАНИЕ!');
      PrintText('НЕВОЗМОЖНО ПРОИЗВЕСТИ ПЕРЕРЕГИСТРАЦИЮ НА ФФД 1.2');
      PrintText('ИЗ-ЗА ОТСУТСТВИЯ СВЯЗИ С ОФД');
      PrintText('');
      PrintText('ВОССТАНОВИТЕ СВЯЗЬ');
      PrintText('СЛЕДУЮЩАЯ ПОПЫТКА ПЕРЕРЕГИСТРАЦИИ');
      PrintText('БУДЕТ ПРОИЗВЕДЕНА ПРИ ОТКРЫТИИ СМЕНЫ');
      Feed(12);
      Sleep(50);
      FinishDocument;
      WaitForPrinting;
      raise Exception.Create('Перерегистрация на ФФД 1.2 не может быть произведена. Есть неотправленные в ОФД документы');
    end;
  end;
end;

procedure TFiscalPrinter.ChangeToFFD12;
var
  WMEx: Byte;
  T: Cardinal;
  INNOFD: string;
  ServerKM: string;
  PortKM: Integer;
begin
  Logger.Debug('Перерегистрация ККТ на ФФД 1.2');

  Feed(2);
  PrintText('ПРОИЗВОДИТСЯ ПЕРЕРЕГИСТРАЦИЯ ККТ НА ФФД 1.2');
  PrintText('НЕ ОТКЛЮЧАЙТЕ ПИТАНИЕ КАССЫ И КОМПЬЮТЕРА');
  PrintText('ДОЖДИТЕСЬ ПЕЧАТИ СООБЩЕНИЯ');
  PrintText('О ЗАВЕРШЕНИИ ПЕРЕРЕГИСТРАЦИИ');
  Feed(14);

  WMEx := ReadTableInt(18, 1, 21);

  begin
    if TestBit(FWUpdateFFDParams, 1) then
      SetBit(WMEx, 4);

    if TestBit(FWUpdateFFDParams, 2) then
      SetBit(WMEx, 5);

    if TestBit(FWUpdateFFDParams, 3) then
      SetBit(WMEx, 6);
  end;
  CheckForSendedDocuments;
  Check(FNBuildCalculationStateReport);
  WaitForPrinting;
  CheckForSendedDocuments;
  WriteTableInt(17, 1, 17, 4);
  WriteTableInt(18, 1, 21, WMEx);
  WriteTableInt(18, 1, 22, 2097216);
  // причина - Смена ФФД + изменение версии модели
  RegistrationReasonCode := 4; // Изменение настроек ККТ
  INN := Trim(ReadTableStr(18, 1, 2));
  KKTRegistrationNumber := Trim(ReadTableStr(18, 1, 3));
  TaxType := ReadTableInt(18, 1, 5);
  WorkMode := ReadTableInt(18, 1, 6);
  Logger.Debug('FNBuildReregistrationReport');
  Check(FNBuildReregistrationReport);
  WaitForPrinting;

  INNOFD := ReadTableStr(18, 1, 12);
  Logger.Debug('INN OFD: ' + INNOFD);
  GetServerKMParams(INNOFD, ServerKM, PortKM);
  if ServerKM <> '' then
  begin
    Logger.Debug('Запись настроек сервера КМ');
    WriteTableStr(19, 1, 5, ServerKM);
    WriteTableInt(19, 1, 6, PortKM);
  end;

  Feed(2);
  PrintText('ПРОИЗВЕДЕНА АВТОМАТИЧЕСКАЯ ПЕРЕРЕГИСТРАЦИЯ');
  PrintText('НА ФФД 1.2');
  Feed(12);
  Sleep(50);
  FinishDocument;
  WaitForPrinting;
end;

{ Передача команды E0 }

function TFiscalPrinter.OpenSession: Integer;
var
  UTC: TSystemTime;
  Dat: TDateTime;
  sec: UInt64;
begin
  try
    if NeedToChangeToFFD12 then
      ChangeToFFD12;

    if not IsModelType2(ModelID) then
    begin
      TableNumber := 25;
      RowNumber := 1;
      FieldNumber := 1;
      GetSystemTime(UTC);
      ValueOfFieldString := Format('drvfr %s %s', [GetFileVersionInfoStr, FormatDateTime('yyyy-mm-dd"T"hh:mm:ss', SystemTimeToDateTime(UTC))]);
      WriteTable;
    end;

    if CorrectDateTimeOnOpenSession then
    begin
      Logger.Debug('Correct Date and time on OpenSession');
      Result := GetECRStatus;
      if Result <> 0 then
        Exit;

      Logger.Debug('Current PC time: ' + DateTimeToStr(Now));
      Logger.Debug('Current ECR time: ' + DateTimeToStr(ECRDate + ECRTime));
      if SecondsBetween(Now, ECRDate + ECRTime) < 86400 then
      begin
        Logger.Debug('Correcting Date and time on OpenSession');
        Dat := Date;
        ECRDate := Dat;
        Check(SetDate);
        ECRDate := Dat;
        Check(ConfirmDate);
        ECRTime := Time;
        Check(SetTime);
      end else
        RaiseError(E_DATE_TIME_DIFFER_MORE_THAN_24H, S_DATE_TIME_DIFFER_MORE_THAN_24H)
    end;

    Result := SendAuth(#$E0 + FPassw)
  except
    on E: Exception do
      Result := HandleException(E)
  end;
end;

{ Проверка номера интервала }

function TFiscalPrinter.CheckIntervalNumber: Integer;
begin
  if IntervalNumber in [1..199] then
  begin
    Result := ClearResult;
  end else
  begin
    Result := InvalidParam('IntervalNumber');
  end;
end;

{ Проверка значения интервала }

function TFiscalPrinter.CheckIntervalValue: Integer;
begin
  if IntervalValue in [0..255] then
  begin
    Result := ClearResult;
  end else
  begin
    Result := InvalidParam('IntervalValue');
  end;
end;

{ Получение интервала }

function TFiscalPrinter.GetInterval: Integer;
begin
  // Номер интервала
  Result := CheckIntervalNumber;
  if Result <> 0 then
    Exit;

  IntervalValue := Intervals[IntervalNumber];
end;

{ Установка интервала }

function TFiscalPrinter.SetInterval: Integer;
begin
  // Номер интервала
  Result := CheckIntervalNumber;
  if Result <> 0 then
    Exit;
  // Значение интервала
  Result := CheckIntervalValue;
  if Result <> 0 then
    Exit;

  Intervals[IntervalNumber] := IntervalValue;
end;

function TFiscalPrinter.ShowPayParams: Integer;
begin
  try
    RaiseError(E_NOTSUPPORTED, SDriverNotSupported);
    { Disconnect;
      PaymentDrv.ParentWnd := ParentWnd;
      PaymentDrv.ShowProperties;
      Result := ClearResult; }
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{ Методы менеджера оплат }
{
  Устанавливает параметры работы с процессингом. Для НСПК СБП возможны следующие имена параметров:
  Используемые свойства
  PayManParamName ПМИмяПараметра – string RW
  Имя параметра для работы с процессингом. Возможны следующие значения:
  "sbp.MemberId"
  "sbp.MerchantId"
  "sbp.Account"
  PayManParamValue ПМЗначениеПатаметра – string RW
  Значение параметра для работы с процессингом
}
function TFiscalPrinter.PayManSetParam: Integer;
begin
  Result := ClearResult;
  Logger.Debug('sbp set param: ' + PayManParamName + ': ' + PayManParamValue);
  try
    if PayManParamName = 'sbp.Login' then
      FSbpAuthorize.Login := PayManParamValue
    else if PayManParamName = 'sbp.Password' then
      FSbpAuthorize.Password := PayManParamValue
    else if PayManParamName = 'sbp.INN' then
      FSbpAuthorize.INN := PayManParamValue
    else
      InvalidProp('PayManParamName');
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{
  PayManCreatePayData
  ПМСоздатьПлатеж
  Создать платеж на сервере оплат. Перед выполнением метода необходимо задать параметры процессинга с помощью метода PayManSetParam.
  Используемые свойства
  PayManProcessingID ПМИДПроцессинга – integer RW
  Идентификатор используемого процессинга. В данное время может принимать только значение
  1 – соответствует «НСПК СБП»
  PayManServerURL ПМАдрСервера – string RW
  URL сервера оплат
  PayManKDevice ПМКУстройств – string RW
  Значение KDevice в виде HEX строки
  PayManUseQRDisplay ПМИспДисплей – string RW
  Использовать внешний Дисплей QR кода
  QRDisplayPortNumber ПМНомерПортаДисплея – string RW
  Номер порта подключенного внешнего дисплея QR кода
  QRDisplayText ПМТекстДисплея – string RW
  Рекламный текст для вывода на внешний дисплей QR кода
  Summ1 - Currency
  Сумма платежа
  Модифицируемые свойства
  Barcode – string RW
  Данные QR кода для отображения, которые должен считать покупатель в своем приложении.
  PayManClientPaymentID ПМИДПлатежаКлиента – string RW
  ИД платежа на стороне клиента
  PayManProcessingPaymentID ПМИДПлатежаПроцессинга – string RW
  ИД платежа на стороне процессинга
  PaymanServerPaymentID ПМИДПлатежаСервера – string RW
  ИД платежа на стороне сервера оплат
  PayManErrorCode ПМКодОшибки – Integer R
  Код ошибки сервера оплат. Значение, отличное от 0 считается ошибкой.
  Возможные коды ошибок:
  100 - ККМ с переданным UIN не найдена на сервере СКОК
  101 - у ККМ с переданным UIN не задан KDevice на сервере СКОК
  102 - переданный хеш вычислен неверно
  110 - передан просроченный или несуществующий токен
  120 - передано некорректное имя процессинга
  200 - передан повторяющийся ИД платежа на клиенте при другом ИД запроса
  300 - статус платежа на сервере не допускает запрашиваемую операцию
  301 - платеж с переданным ИД не найден на сервере
  1001 и 1002 - ошибки на стороне процессинга
  PayManErrorMessage ПМОписаниеОшибки – string R
  Описание кода ошибки
  PayManProcessingResponse ПМОтветПроцессинга – string R
  Ответ от процессинга в формате JSON

}
function TFiscalPrinter.PayManCreatePayData: Integer;
var
  PayDataResp: TSbpCreatePayDataResp;
  Display: IQRDisplay;
begin
  Result := ClearResult;
  Logger.Debug('PayManCreatePayData');
  try
    PayManAuthorize;
    PayManClientPaymentID := FPaymanClient.CreateUniqueID;
    PayDataResp := FPaymanClient.CreatePayData(FPaymanClient.CreateGUID, PayManClientPaymentID, Round(Summ1 * 100));
    if PayDataResp.payData.HasValue then
    begin
      Barcode := PayDataResp.payData.Value;
      // DrawQr(PayDataResp.payData.Value, pbQr, edtSum.Text);
      Logger.Debug('PayData: ' + PayDataResp.payData.Value);
    end;
    if PayDataResp.processingPaymentId.HasValue then
    begin
      PayManProcessingPaymentID := PayDataResp.processingPaymentId.Value;
      Logger.Debug('PayManProcessingPaymentID: ' + PayManProcessingPaymentID);
    end;
    if PayDataResp.serverPaymentId.HasValue then
    begin
      PaymanServerPaymentID := PayDataResp.serverPaymentId.Value;
      Logger.Debug('PaymanServerPaymentID: ' + PaymanServerPaymentID);
    end;
    if PayDataResp.processingResponse.HasValue then
    begin
      PayManProcessingResponse := PayDataResp.processingResponse.Value;
      Logger.Debug('PayManProcessingResponse: ' + PayManProcessingResponse);
    end;

    if PayManUseQRDisplay then
    begin
      Display := TIkodDisplay.Create(QRDisplayPortNumber);
      Display.ShowQr(Barcode);
      Display.SetText1(QRDisplayText);
      Display.SetText2(CurrToStr(Summ1) + ' руб')
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{
  Запрос статуса оплаты на сервере платежей. После создания оплаты с помощью PayManCreatePayData необходимо с определенной периодичностью проверять состояние оплаты, выполняя этот метод. Статус следует запрашивать, пока  PayManIsStatusFinal не примет значение True, либо отметить оплату с помощью метода PayManCancel. Перед выполнением метода должны быть задать параметры процессинга с помощью метода PayManSetParam.
  Используемые свойства
  PayManProcessingID – integer RW
  Идентификатор используемого процессинга. В данное время может принимать только значение
  1 – соответствует «НСПК СБП»
  ClientPaymentID – string RW
  ИД платежа на стороне клиента, полученный в методе PayManCreatePayData
  Модифицируемые свойства
  PayManErrorCode – Integer R
  Код ошибки сервера оплат. Значение, отличное от 0 считается ошибкой.
  PayManErrorMessage – string R
  Описание кода ошибки
  PayManProcessingResponse – string R
  Ответ от процессинга в формате JSON
  PayManProcessingPaymentID – string RW
  ИД платежа на стороне процессинга
  PaymanServerPaymentID – string RW
  ИД платежа на стороне сервера оплат
  PayManPayStatus ПМСтатус – inteter R
  Статус платежа на сервере оплат
  Возможные значения:
  1 - новый,
  2 - создан в процессинге,
  3 - в процессе выполнения в процессинге,
  4 - Успешно выполнен,
  5 - Ошибка,
  6 - Отменен,
  7 - Частично возвращен,
  8 - Возвращен полностью,
  9 - В процессе возврата
  PayManIsStatusFinal ПМФинальныйСтатус – Boolean R
  Признак финальности статуса
  Summ1 – Currency
  Сумма платежа

}

{
  PayManPayStatus

  PayManProcessingPaymentID

  PayManServerPaymentID

  PayManErrorCode

  PayManErrorMessage

  PayManProcessingResponse

  PayManIsStatusFinal


  errorCode: TOptional<Integer>;
  errorMessage: TOptional<string>;
  processingPaymentId: TOptional<string>;
  serverPaymentId: TOptional<string>;
  status: TOptional<Integer>;
  isStatusFinal: TOptional<Boolean>;
  processingResponse: TOptional<string>;
  payerId: TOptional<string>;
  paymentType: TOptional<Integer>;
  amount: TOptional<string>;
  additionalProcessingInfo: TOptional<TPairArray>;
  rawData: string;


}

function TFiscalPrinter.PayManGetPayStatus: Integer;
var
  PayStatus: TSbpGetPayStatusResp;
begin
  Result := ClearResult;
  Logger.Debug('PayManGetPayStatus');
  try
    PayManAuthorize;
    PayStatus := FPaymanClient.GetPayStatus(FPaymanClient.CreateGUID, PayManClientPaymentID);

    if PayStatus.Status.HasValue then
    begin
      PayManPayStatus := PayStatus.Status.Value;
      Logger.Debug('PayManPayStatus: ' + PayManPayStatus.ToString);
    end;
    if PayStatus.IsStatusFinal.HasValue then
    begin
      PayManIsStatusFinal := PayStatus.IsStatusFinal.Value;
      Logger.Debug('PayManIsStatusFinal: ' + SysUtils.BoolToStr(PayManIsStatusFinal, True));
    end;
    if PayStatus.processingPaymentId.HasValue then
    begin
      PayManProcessingPaymentID := PayStatus.processingPaymentId.Value;
      Logger.Debug('PayManProcessingPaymentID: ' + PayManProcessingPaymentID);
    end;
    if PayStatus.serverPaymentId.HasValue then
    begin
      PaymanServerPaymentID := PayStatus.serverPaymentId.Value;
      Logger.Debug('PaymanServerPaymentID: ' + PaymanServerPaymentID);
    end;
    if PayStatus.processingResponse.HasValue then
    begin
      PayManProcessingResponse := PayStatus.processingResponse.Value;
      Logger.Debug('PayManProcessingResponse: ' + PayManProcessingResponse);
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;

end;

{
  Отмена оплаты, созданной ранее методом PayManCreatePayData. Перед выполнением метода должны быть задать параметры процессинга с помощью метода PayManSetParam.
  Используемые свойства
  PayManProcessingID – integer RW
  Идентификатор используемого процессинга.
  ClientPaymentID – string RW
  ИД платежа на стороне клиента, полученный в методе PayManCreatePayData
  Модифицируемые свойства
  PayManErrorCode – Integer R
  Код ошибки сервера оплат. Значение, отличное от 0 считается ошибкой.
  PayManErrorMessage – string R
  Описание кода ошибки
  PayManPayStatus – inteter R
  Статус платежа на сервере оплат

  PayManProcessingCancelPaymentID – string RW
  ИД отмены платежа на стороне процессинга
  PayManProcessingResponse – string R
  Ответ от процессинга в формате JSON

}
{
  PayManErrorCode

  PayManErrorMessage

  PayManPayStatus

  PayManProcessingCancelPaymentID

  PayManProcessingResponse


}
function TFiscalPrinter.PayManCancel: Integer;
var
  Resp: TSbpCancelResp;
begin
  Result := ClearResult;
  Logger.Debug('PayManCancel');
  try
    PayManAuthorize;
    Resp := FPaymanClient.Cancel(FPaymanClient.CreateGUID, PayManClientPaymentID, FPaymanClient.CreateGUID);

    if Resp.errorcode.HasValue then
    begin
      PayManErrorCode := Resp.errorcode.Value;
    end;
    if Resp.errorMessage.HasValue then
    begin
      PayManErrorMessage := Resp.errorMessage.Value;
    end;
    if Resp.processingResponse.HasValue then
    begin
      PayManProcessingResponse := Resp.processingResponse.Value;
    end;
    if Resp.Status.HasValue then
    begin
      PayManPayStatus := Resp.Status.Value;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ReadUIN: string;
begin
  Result := ReadTableStr(23, 1, 11);
end;

procedure TFiscalPrinter.PayManAuthorize;
begin
  FPaymanClient.BaseUrl := PayManServerURL;
  FPaymanClient.AuthorizeSbp(FSbpAuthorize);
end;

{
  ПМВозвратПлатежа
  Выполнить частичный или полный возврат ранее произведенной оплаты. Возврат выполняется синхронно, предполагаемое время возврата при процессинге работающем, через СБП до 4 минут. Перед выполнением метода должны быть задать параметры процессинга с помощью метода PayManSetParam.
  Используемые свойства
  PayManProcessingID – integer RW
  Идентификатор используемого процессинга.
  PaymanServerPaymentID – string RW
  ИД платежа на стороне сервера оплат
  Summ1 – Currency RW
  Сумма возврата
  Модифицируемые свойства
  PayManErrorCode – Integer R
  Код ошибки сервера оплат. Значение, отличное от 0 считается ошибкой.
  PayManErrorMessage – string R
  Описание кода ошибки
  PayManProcessingResponse – string R
  Ответ от процессинга в формате JSON
  PayManPayStatus – inteter R
  Статус отмены платежа на сервере оплат




  PayManErrorCode

  PayManErrorMessage

  PayManProcessingResponse

  PayManPayStatus



}
function TFiscalPrinter.PayManReadParam: Integer;
begin
  Result := ClearResult;
  Logger.Debug('sbp read param: ' + PayManParamName);
  try
    if PayManParamName = 'sbp.Login' then
      PayManParamValue := FSbpAuthorize.Login
    else if PayManParamName = 'sbp.Password' then
      PayManParamValue := FSbpAuthorize.Password
    else if PayManParamName = 'sbp.INN' then
      PayManParamValue := FSbpAuthorize.INN
    else
      InvalidProp('PayManParamName');
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.PayManRefund: Integer;
var
  Resp: TSbpRefundResp;
begin
  Logger.Debug('PayManRefund');
  Result := ClearResult;
  try
    Resp := FPaymanClient.Refund(FPaymanClient.CreateGUID, PaymanServerPaymentID, FPaymanClient.CreateGUID, Round(Summ1 * 100));

    if Resp.errorcode.HasValue then
    begin
      PayManErrorCode := Resp.errorcode.Value;
    end;
    if Resp.errorMessage.HasValue then
    begin
      PayManErrorMessage := Resp.errorMessage.Value;
    end;
    if Resp.processingResponse.HasValue then
    begin
      PayManProcessingResponse := Resp.processingResponse.Value;
    end;
    if Resp.Status.HasValue then
    begin
      PayManPayStatus := Resp.Status.Value;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{
  Создать код статической кассовой ссылки, для оплаты по кассовой ссылке методом PayManCreatePayDataByCode. Перед выполнением метода должны быть задать параметры процессинга с помощью метода PayManSetParam.
  Используемые свойства
  PayManProcessingID – integer RW
  Идентификатор используемого процессинга.
  Модифицируемые свойства
  Barcode – string RW
  Значение QR кода постоянной кассовой ссылки, демонстрируемого покупателю.
  PayManCashRegisterCode ПМКодКассовойСсылки – string RW
  Код кассовой ссылки, используется в методе CreatePayDataByCode
}

function TFiscalPrinter.PayManCreateCashRegisterCode: Integer;
var
  Resp: TSbpCreateCashRegisterCodeResp;
begin
  Logger.Debug('PayManCreateCashRegisterCode');
  Result := ClearResult;
  try
    PayManAuthorize;
    Resp := FPaymanClient.CreateCashRegisterCode(FPaymanClient.CreateGUID);

    if Resp.errorcode.HasValue then
    begin
      PayManErrorCode := Resp.errorcode.Value;
    end;
    if Resp.errorMessage.HasValue then
    begin
      PayManErrorMessage := Resp.errorMessage.Value;
    end;
    if Resp.processingResponse.HasValue then
    begin
      PayManProcessingResponse := Resp.processingResponse.Value;
    end;
    if Resp.payData.HasValue then
    begin
      PayManCashRegisterCode := Resp.payData.Value;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{
  Создать платеж на сервере оплат, используя статическую кассовую ссылку. Кассовую ссылку можно сгенерировать методом PayManCreateCashRegisterCode. Перед выполнением метода должны быть задать параметры процессинга с помощью метода PayManSetParam.
  Используемые свойства
  PayManProcessingID – integer RW
  Идентификатор используемого процессинга. В данное время может принимать только значение
  1 – соответствует «НСПК СБП»
  PayManServerURL – string RW
  URL сервера оплат
  PayManKDevice – string RW
  Значение KDevice в виде HEX строки
  PayManUseQRDisplay – string RW
  Использовать внешний Дисплей QR кода
  QRDisplayPortNumber – string RW
  Номер порта подключенного внешнего дисплея QR кода
  QRDisplayText – string RW
  Рекламный текст для вывода на внешний дисплей QR кода
  Summ1 - Currency
  Сумма платежа
  Barcode – string RW
  QR Код кассовой ссылки для отображения на дисплее
  PayManCashRegisterCode
  Код кассовой ссылки
  Модифицируемые свойства
  PayManClientPaymentID – string RW
  ИД платежа на стороне клиента
  PayManProcessingPaymentID – string RW
  ИД платежа на стороне процессинга
  PaymanServerPaymentID – string RW
  ИД платежа на стороне сервера оплат
  PayManErrorCode – Integer R
  Код ошибки сервера оплат. Значение, отличное от 0 считается ошибкой.
  Возможные коды ошибок:
  100 - ККМ с переданным UIN не найдена на сервере СКОК
  101 - у ККМ с переданным UIN не задан KDevice на сервере СКОК
  102 - переданный хеш вычислен неверно
  110 - передан просроченный или несуществующий токен
  120 - передано некорректное имя процессинга
  200 - передан повторяющийся ИД платежа на клиенте при другом ИД запроса
  300 - статус платежа на сервере не допускает запрашиваемую операцию
  301 - платеж с переданным ИД не найден на сервере
  1001 и 1002 - ошибки на стороне процессинга
  PayManErrorMessage – string R
  Описание кода ошибки
  PayManProcessingResponse – string R
  Ответ от процессинга в формате JSON
}
function TFiscalPrinter.PayManCreatePayDataByCode: Integer;
var
  PayDataResp: TSbpCreatePayDataResp;
  Display: IQRDisplay;
begin
  Result := ClearResult;
  Logger.Debug('PayManCreatePayDataByCode');
  try
    PayManAuthorize;
    PayManClientPaymentID := FPaymanClient.CreateUniqueID;
    PayDataResp := FPaymanClient.CreatePayData(FPaymanClient.CreateGUID, PayManClientPaymentID, Round(Summ1 * 100), PayManCashRegisterCode);
    { if PayDataResp.payData.HasValue then
      begin
      Barcode := PayDataResp.payData.Value;
      Logger.Debug('PayData: ' + PayDataResp.payData.Value);
      end; }
    if PayDataResp.processingPaymentId.HasValue then
    begin
      PayManProcessingPaymentID := PayDataResp.processingPaymentId.Value;
      Logger.Debug('PayManProcessingPaymentID: ' + PayManProcessingPaymentID);
    end;
    if PayDataResp.serverPaymentId.HasValue then
    begin
      PaymanServerPaymentID := PayDataResp.serverPaymentId.Value;
      Logger.Debug('PaymanServerPaymentID: ' + PaymanServerPaymentID);
    end;
    if PayDataResp.processingResponse.HasValue then
    begin
      PayManProcessingResponse := PayDataResp.processingResponse.Value;
      Logger.Debug('PayManProcessingResponse: ' + PayManProcessingResponse);
    end;

    if PayManUseQRDisplay then
    begin
      Display := TIkodDisplay.Create(QRDisplayPortNumber);
      Display.ShowQr(PayManCashRegisterCode);
      Display.SetText1(QRDisplayText);
      Display.SetText2(CurrToStr(Summ1) + ' руб')
    end;

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.PayMobile(Intf: IUnknown): Integer;
begin

  try
    RaiseError(E_NOTSUPPORTED, SDriverNotSupported);
  except
    on E: Exception do
      Result := HandleException(E);
  end;

  { try
    Disconnect;
    PaymentDrv.Password := Password;            // Пароль
    PaymentDrv.Department := RealPayDepartment; // Секция
    Result := PaymentDrv.ShowPayDialog(Intf);
    if Result = 0 then
    begin
    if SaleError then
    begin
    Result := E_MP_SALEERROR;
    ResultCode := E_MP_SALEERROR;
    ResultCodeDescription := GetRes(@SDriverMPSaleError);
    end else
    begin
    Result := ClearResult;
    end;
    end else
    begin
    Result := E_MP_PAYERROR;
    ResultCode := E_MP_PAYERROR;
    ResultCodeDescription := PaymentDrv.ResultDescription;
    end;
    except
    on E: Exception do
    Result := HandleException(E);
    end; }
end;

function TFiscalPrinter.ReprintSlipDocument: Integer;
begin
  Result := Send(#$E1 + FPassw);
end;

const
  AMODE_HASPAPER = 0; // 0.	Бумага есть
  AMODE_NOPAPER_PASSIVE = 1; // 1.	Пассивное отсутствие бумаги
  AMODE_NOPAPER_ACTIVE = 2; // 2.	Активное отсутствие бумаги
  AMODE_NOPAPER_AFTER = 3; // 3.	После активного отсутствия бумаги
  AMODE_PRINTING_REPORT = 4; // 4.	Фаза печати отчетов
  AMODE_PRINTING = 5; // 5.	Фаза печати операции

function TFiscalPrinter.WaitForAdvancedMode: Integer;
begin
  repeat
    Result := GetShortECRStatus;
    if Result <> 0 then
      Exit;
    case ECRAdvancedMode of
      0:
        Break;
      1, 2:
        begin
          Result := E_NOPAPER;
          ResultCode := E_NOPAPER;
          ResultCodeDescription := ECRAdvancedModeDescription;
          Exit;
        end;
      3:
        begin
          Result := ContinuePrint;
          if Result <> 0 then
            Exit;
        end;
      4, 5:
        Sleep(WaitForPrintingDelay);
    else
      Break;
    end;
  until Result <> 0;
end;

// Ожидание завершения печати.

function TFiscalPrinter.WaitForPrinting: Integer;
var
  T: Cardinal;
begin
  T := GetTickCount;
  repeat
    Result := WaitForAdvancedMode;

    case Result of
      E_NOHARDWARE:
        if (GetTickCount - T) >= ConnectionTimeout then
          Exit;

      E_NOERROR:
        if ECRMode in [11, 12, 14] then
          Sleep(WaitForPrintingDelay)
        else
          Exit;
    else
      Exit;
    end;
  until False;
end;

// Ожидание закрытия чека

function TFiscalPrinter.WaitForCheckClose: Integer;
var
  T: Cardinal;
begin
  T := GetTickCount;
  repeat
    Result := WaitForAdvancedMode;

    case Result of
      E_NOHARDWARE:
        if (GetTickCount - T) >= ConnectionTimeout then
          Exit;

      E_NOERROR:
        if ECRMode in [8, 11, 12, 14] then
          Sleep(WaitForPrintingDelay)
        else
          Exit;
    else
      Exit;
    end;
  until False;
end;

function TFiscalPrinter.GetCapGetShortECRStatus: Boolean;
begin
  Result := (UMajorProtocolVersion > 1) or ((UMajorProtocolVersion = 1) and (UMinorProtocolVersion >= 2));
end;

function TFiscalPrinter.GetCapOpenCheck: Boolean;
begin
  Result := (UMajorProtocolVersion > 1) or ((UMajorProtocolVersion = 1) and (UMinorProtocolVersion >= 2));
end;

function TFiscalPrinter.ResetECR: Integer;
const
  RepCount = 10;
var
  i: Integer;
begin
  for i := 0 to RepCount - 1 do
  begin
    Result := WaitForPrinting;
    if Result <> 0 then
      Exit;

    case ECRMode of
      1:
        Result := FNInterruptFiscalDocumentReading; // InterruptDataStream;
      6:
        Result := ConfirmDate;
      8:
        Result := CancelCheck;
      10:
        Result := InterruptTest;
      11, 12, 14:
        ;
    else
      Exit;
    end;
    if Result <> 0 then
      Exit;
  end;
  if FNGetStatus = 0 then
  begin
    if FNCurrentDocument <> 0 then
      FNCancelDocument;
  end;
  Result := E_RESET;
  ResultCode := E_RESET;
  ResultCodeDescription := GetRes(@SDriverReset);
end;

function TFiscalPrinter.ResetFont: Integer;
begin
  FECode := $0A;
  Result := Send(#$FE#$0A#$00#$00#$00#$00);
end;

function TFiscalPrinter.Get_CashControlEnabled: Boolean;
begin
  Result := False;
end;

function TFiscalPrinter.Get_CashControlPort: AnsiString;
begin
  Result := '';
end;

procedure TFiscalPrinter.Set_CashControlEnabled(Value: Boolean);
begin
end;

procedure TFiscalPrinter.Set_CashControlPort(const Value: AnsiString);
begin
end;

function TFiscalPrinter.Get_CashControlHost: AnsiString;
begin
  Result := '';
end;

procedure TFiscalPrinter.Set_CashControlHost(const Value: AnsiString);
begin
end;

function TFiscalPrinter.Get_CashControlUseTCP: Boolean;
begin
  Result := True;
end;

procedure TFiscalPrinter.Set_CashControlUseTCP(Value: Boolean);
begin
end;

{ ***************************************************************************** }
{
  {       Явное подключение к CashControl
  {       Выведено на всякий случай, но видимо не будет использовавться
  {       К тому же оно асинхронное. Не сообщит об ошибке подключения.
  {       Если понадобится, то нужно будет сделать метод синхронного
  {       подключения с таймаутом (только для TCP).
  {
  {***************************************************************************** }

function TFiscalPrinter.CashControlOpen: Integer;
begin
  try
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{ ***************************************************************************** }
{
  {       Явное отключение от CashControl
  {       Выведено на всякий случай, но видимо не будет использовавться
  {
  {***************************************************************************** }

function TFiscalPrinter.CashControlClose: Integer;
begin
  try
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetProtocol: TCashControlProtocol;
begin
  Result := cpCashControl_2_11;
end;

procedure TFiscalPrinter.SetProtocol(const Value: TCashControlProtocol);
begin
end;

function TFiscalPrinter.CashControlLoadParams: Integer;
begin
  try
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetccHeaderLineCount: Integer;
begin
  Result := 0;
end;

function TFiscalPrinter.GetccUseTextAsWareName: Boolean;
begin
  Result := False;
end;

function TFiscalPrinter.GetccWareNameLineNumber: Integer;
begin
  Result := 0;
end;

procedure TFiscalPrinter.SetccHeaderLineCount(const Value: Integer);
begin
end;

procedure TFiscalPrinter.SetccUseTextAsWareName(const Value: Boolean);
begin
end;

procedure TFiscalPrinter.SetccWareNameLineNumber(const Value: Integer);
begin
end;

// Получение списка поддерживаемых штрих-кодов

function TFiscalPrinter.GetBarcodeTypes: AnsiString;
begin
  Result := BarcodeRender.GetBarcodeTypes;
end;

// Печать текста штрихкода

function TFiscalPrinter.PrintBCText(APrintW, APrintGW, ACharW, ABarW: Integer): Integer;
var
  n: Integer;
begin
  if FontType < 1 then
    FontType := 1;

  n := 0;
  if ACharW = 0 then
    ACharW := 12;
  case BarcodeAlignment of
    baCenter:
      n := ((APrintW div ACharW) - Length(Barcode)) div 2;
    baLeft:
      n := (APrintW - APrintGW) div (2 * ACharW) + ((ABarW div ACharW) - Length(Barcode)) div 2;
    baRight:
      n := ((APrintW - APrintGW) div 2 + APrintGW - ABarW) div ACharW + ((ABarW div ACharW) - Length(Barcode)) div 2;
  end;
  StringForPrinting := StringOfChar(' ', n) + Barcode;
  UseJournalRibbon := False;
  UseReceiptRibbon := True;
  UseSlipDocument := False;
  Result := PrintString;
end;

// Печать штрихкода линией

function TFiscalPrinter.PrintBarcodeLine: Integer;
var
  SavePassword: Integer;
  PrintLineWidth: Integer;
begin
  try
    // Получение ширины печати
    // Значение записывается в свойство PrintWidth
    FontType := 1;
    // Команда GetFontMetrics выполняется под пароленм системного администратора
    SavePassword := Password;
    Password := SysAdminPassword;
    try
      Result := GetFontMetrics;
      if Result <> 0 then
        Exit;
    finally
      Password := SavePassword;
    end;
    PrintLineWidth := PrinterModel.MaxLineWidth * 8;
    // Печать
    BarcodeRender.Data := Barcode;
    BarcodeRender.BarWidth := BarWidth;
    BarcodeRender.PrintWidth := PrintLineWidth; // PrintWidth;
    BarcodeRender.BarcodeAlignment := BarcodeAlignment;
    BarcodeRender.BarcodeType := TBarcodeType(BarcodeType);
    BarcodeRender.CreateBarcode;

    // Печать текста сверху
    if PrintBarcodeText in [PrintBarcodeTextAbove, PrintBarcodeTextBoth] then
    begin
      Result := PrintBCText(PrintWidth, PrintWidth, CharWidth, BarcodeRender.BarcodeWidth);
      if Result <> 0 then
        Exit;
    end;

    // Печать
    LineData := BarcodeRender.BarcodeLine;
    Result := PrintLine;
    if Result <> 0 then
      Exit;
    Sleep(700); // некоторые принтеры глючат
    // Печать текста снизу
    if PrintBarcodeText in [PrintBarcodeTextBelow, PrintBarcodeTextBoth] then
    begin
      Result := PrintBCText(PrintWidth, PrintWidth, CharWidth, BarcodeRender.BarcodeWidth);
      if Result <> 0 then
        Exit;
    end;

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Печать штрихкода графикой

function TFiscalPrinter.PrintBarcodeGraph: Integer;
var
  i: Integer;
  Count: Integer;
  PrintW: Integer;
  CharW: Integer;
  SavePassword: Integer;
begin
  try
    Logger.Debug('PrintBarcodeGraph');

    Logger.Debug('QR Loaded');
    SavePassword := Password;
    Password := SysAdminPassword;
    try
      if FontType < 1 then
        FontType := 1;
      Result := GetFontMetrics;
      if Result <> 0 then
        Exit;
      PrintW := PrintWidth;
      CharW := CharWidth;
    finally
      Password := SavePassword;
    end;
    GraphBufferType := 1;
    Result := LoadBarcodeGraph;
    if Result <> 0 then
      Exit;

    if PrintBarcodeText in [PrintBarcodeTextAbove, PrintBarcodeTextBoth] then
    begin
      Result := PrintBCText(PrintW, 320, CharW, BarcodeRender.BarcodeWidth);
      if Result <> 0 then
        Exit;
      WaitForPrinting;
    end;
    FirstLineNumber := FirstLineNumber + PrinterModel.FirstDrawLine - 1;
    LastLineNumber := LastLineNumber + PrinterModel.FirstDrawLine - 1;
    VertScale := 1;
    HorizScale := 1;
    if PrinterModel.CapGraphics512 then
      Result := PrintGraphics512
    else
      Result := DrawEx;
    if Result <> 0 then
      Exit;
    // Печать текста снизу
    if PrintBarcodeText in [PrintBarcodeTextBelow, PrintBarcodeTextBoth] then
    begin
      Result := PrintBCText(PrintW, 320, CharW, BarcodeRender.BarcodeWidth);
      if Result <> 0 then
        Exit;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetBarcodeAlignments: AnsiString;
resourcestring
  SBarcodeAlignments = 'По центру'#13#10'Влево'#13#10'Вправо';
begin
  Result := SBarcodeAlignments;
end;

function TFiscalPrinter.GetBarcodeAlignment: TBarcodeAlignment;
begin
  Result := BarcodeRender.BarcodeAlignment;
end;

function TFiscalPrinter.GetBarcodeType: Integer;
begin
  Result := Ord(BarcodeRender.BarcodeType);
end;

function TFiscalPrinter.GetBarWidth: Integer;
begin
  Result := BarcodeRender.BarWidth;
end;

procedure TFiscalPrinter.SetBarcodeAlignment(const Value: TBarcodeAlignment);
begin
  BarcodeRender.BarcodeAlignment := Value;
end;

procedure TFiscalPrinter.SetBarcodeType(const Value: Integer);
begin
  BarcodeRender.BarcodeType := TBarcodeType(Value);
end;

procedure TFiscalPrinter.SetBarWidth(const Value: Integer);
begin
  BarcodeRender.BarWidth := Value;
end;

function TFiscalPrinter.DecodeOutput(const ATxData: AnsiString; const BinOutput: AnsiString): Integer;
var
  Data: AnsiString;
  CmdCode: Word;
begin
  FRxData := BinOutput;
  if (Ord(ATxData[1]) = $FE) and (Ord(ATxData[2]) = $FB) then
  begin
    Result := ClearResult;
    Exit;
  end;
  CheckMinLength(FRxData, 2);
  CmdCode := Ord(FRxData[1]);

  if CmdCode = $FF then
  begin
    if Length(FRxData) = 2 then
    begin
      CmdCode := Ord(FRxData[1]);
      Result := Ord(FRxData[2]);
    end else
    begin
      CmdCode := MakeWord(Ord(FRxData[2]), CmdCode);
      Result := Ord(FRxData[3]);
    end;
  end else
  begin
    Result := Ord(FRxData[2]);
  end;

  if Result = 0 then
  begin
    if CmdCode > $FF then
    begin
      Data := Copy(FRxData, 4, Length(FRxData));
    end else
      Data := Copy(FRxData, 3, Length(FRxData));
    DecodeAnswer(CmdCode, Data);
    if (CmdCode = $6B) and not (FReadErrorDescription) then
    begin
      Result := Ord(ATxData[2]);
      // ResultCode := Result;
    end else
      Result := ClearResult;
  end else
  begin
    FCommandError := True;
    ResultCode := Result;
    if not FGetPrinterModel then
      ResultCodeDescription := TPrinterError.GetDescription(Result)
    else
    begin
      ResultCodeDescription := TPrinterError.GetDescription(Result, PrinterModel.CapFN)
    end;
  end;
end;

function TFiscalPrinter.ServerDisconnect: Integer;
begin
  Logger.Debug('ServerDisconnect');
  OFDStopPoll;
  FDriver := nil;
  Result := ClearResult;
end;

function TFiscalPrinter.ClearResult: Integer;
begin
  Result := E_NOERROR;
  ResultCode := E_NOERROR;
  ResultCodeDescription := GetRes(@SDriverNoErrors);
end;

function TFiscalPrinter.HandleException(E: Exception): Integer;
var
  DriverError: EDriverError;
  OleSysError: EOleSysError;
begin
  Logger.Error('Handle Exception ' + E.Message);
  if E is EDriverError then
  begin
    DriverError := E as EDriverError;
    ResultCode := DriverError.errorcode;
    ResultCodeDescription := EDriverError(E).WideMessage;
    Logger.Error(Format('%d %s', [DriverError.errorcode, E.Message]));
  end else
  begin
    if E is EOleSysError then
    begin
      Logger.Error('EOleSysError');
      FDriver := nil;
      // ServerDisconnect;
      ResultCode := E_NOTLOADED;
      OleSysError := E as EOleSysError;
      ResultCodeDescription := Format('%s %s (%x)', [GetRes(@SDriverServerError), E.Message, OleSysError.errorcode]);
      Logger.Error(Format('0x%8x %s', [OleSysError.errorcode, E.Message]));
    end else if E is ECommError then
    begin
      ResultCode := E_NOHARDWARE;
      ResultCodeDescription := GetRes(@SDriverNoHardware);
      Logger.Error(ResultCodeDescription);
    end else if E is EVMCScannerError then
    begin
      ResultCode := E_VMCSCANNER_ERROR;
      ResultCodeDescription := E.Message;
    end else
    begin
      ResultCode := E_UNKNOWN;
      ResultCodeDescription := E.Message;
      Logger.Error(ResultCodeDescription);
    end;
  end;
  Result := ResultCode;
end;

function TFiscalPrinter.SendCmd(var Command: TCommandRec): Integer;
begin
  try
    OpenPort;
    Driver.Send(Command);
    Result := ClearResult;
  except
    on E: Exception do
    begin
      Result := HandleException(E);
      Logger.Error('Exception:' + E.Message);

      if ConnectionType = 6 then
      begin
        Logger.Debug('Close socket due exception');
        ClosePort;
      end;
    end;
  end;
end;

procedure TFiscalPrinter.SendCmd2(var Command: TCommandRec);
begin
  try
    OpenPort;
    Driver.Send(Command);
  except
    on E: Exception do
    begin
      if ConnectionType = 6 then
      begin
        Logger.Debug('Close socket due exception');
        ClosePort;
      end;
      raise;
    end;
  end;
end;

procedure TFiscalPrinter.OpenPort;
begin
  Logger.Debug('OpenPort');
  Lock;
  try
    Driver.OpenPort;
  finally
    Unlock;
  end;
end;

function TFiscalPrinter.SendCommand(const Data: AnsiString): Integer;
var
  PluginData: AnsiString;
  PluginMessage: TCommandPluginMessage;
  Command: TCommandRec;
resourcestring
  SCommand = 'Команда';
begin
  // Оповещение
  Command.Code := 0;
  if Length(Data) > 0 then
  begin
    Command.Code := Ord(Data[1]);
    // Получаем расширенный код команды
    if (Command.Code = $FF) and (Length(Data) > 1) then
      Command.Code := MakeWord(Ord(Data[2]), Command.Code);
  end;

  try
    // Запрашиваем первым делом параметры модели
    if (Command.Code <> $FC) and (Command.Code <> $16) and (Command.Code <> $F7) and (Command.Code <> $D1) then
      GetPrinterModel;

    Command.Command := Data;
    // Название команды
    Command.Name := GetCommandName(Command.Code);
    Command.Name := Format('%s: %.2xh, %s', [SCommand, Command.Code, Command.Name]);
    Command.Timeout := GetCmdTimeout(Command.Code);
    Logger.WriteSeparator;
    Logger.Debug(Command.Name);
    Logger.WriteSeparator;
    BeforeCommand(Command.Code);
    Result := SendCmd(Command);
    if Result = 0 then
    begin
      if Driver.IsCommandBuffered then
      begin
        Result := ClearResult;
      end else
      begin
        Result := DecodeOutput(Command.Command, Command.Answer);
      end;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;

  // Сохраняем введенный пароль налогового инспектора
  if Command.Code in [$64, $65, $66, $67, $68, $69, $CD, $D2, $D3] then
  begin
    if (FPassword <> Integer(LDTaxPassword)) or (not FDevices.LDIsEnteredTaxPassword) then
    begin
      SetEnteredTaxPassword(FPassword);
      FDevices.LDIsEnteredTaxPassword := True;
    end;
  end;
  // send plugin message
  PluginMessage.Code := Command.Code;
  PluginMessage.Driver := Pointer(FDrvFR49);
  SetLength(PluginData, Sizeof(PluginMessage));
  Move(PluginMessage, PluginData[1], Sizeof(PluginMessage));
  SendPluginMessage(0, PluginData);

  ECRInput := '';
  ECROutput := '';
  if (Result > 0) and (Command.Code <> $FC) and (Command.Code <> $16) and (Command.Code <> $F7) and (Command.Code <> $D1) then
  begin
    if not (PrinterModel.CapErrorDescription and (Command.Code = $6B) and not FReadErrorDescription) then
    begin
      ECRInput := StrToHex(Command.TxData) + ' ';
      ECROutput := AnswerToHex(Command.RxData);
    end else
    begin
      ECRInput := FECRInputOld;
      ECROutput := FECROutputOld;
    end;
  end else
  begin
    ECRInput := StrToHex(Command.TxData) + ' ';
    ECROutput := AnswerToHex(Command.RxData);
  end;
  if (Command.Code = $FE) and (Copy(Command.TxData, 4, 1) = #$E9) then
    ECRInput := StrToHex(Copy(Command.TxData, 1, 4));

  FConnected := True;
  // Запись в лог
  WriteLogData(Result, Command.TxData, Command.RxData);
  try
    AfterCommand(Command.Code);
  except
    on E: Exception do
      HandleException(E);
  end;
end;

function TFiscalPrinter.SimpleSendCommand(const Data: AnsiString): Integer;
var
  Command: TCommandRec;
resourcestring
  SCommand = 'Команда';
begin
  // Оповещение
  Command.Code := 0;
  if Length(Data) > 0 then
  begin
    Command.Code := Ord(Data[1]);
    // Получаем расширенный код команды
    if (Command.Code = $FF) and (Length(Data) > 1) then
      Command.Code := MakeWord(Ord(Data[2]), Command.Code);
  end;

  try
    Command.Command := Data;
    // Название команды
    Command.Name := GetCommandName(Command.Code);
    Command.Name := Format('%s: %.2xh, %s', [SCommand, Command.Code, Command.Name]);
    Command.Timeout := GetCmdTimeout(Command.Code);
    Logger.WriteSeparator;
    Logger.Debug(Command.Name);
    Logger.WriteSeparator;
    Result := SendCmd(Command);
    if Result = 0 then
    begin
      if Driver.IsCommandBuffered then
        Result := ClearResult
      else
        Result := DecodeOutput(Command.Command, Command.Answer);
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;

  ECRInput := StrToHex(Command.TxData) + ' ';
  ECROutput := AnswerToHex(Command.RxData);

  FConnected := True;
  // Запись в лог
  WriteLogData(Result, Command.TxData, Command.RxData);
end;

resourcestring
  SErrorGetDescription = 'Ошибка запроса описания ошибки';

function TFiscalPrinter.Send(const Data: AnsiString): Integer;
begin
  // Предотвращаем посылку команд во время обновления прошивки
  if FFwupdater.Started then
  begin
    ResultCode := E_FW_UPDATE_STARTED;
    Result := ResultCode;
    ResultCodeDescription := GetRes(@SFwUpdateStarted);
    Exit;
  end;

  Lock;
  try
    Result := DoSend(Data);
  finally
    Unlock;
  end;
  // Чтобы не было взаимоблокировки потоков, останавливаем поток
  // передачи данных в ОФД вне блокировки
  if Result = E_NOHARDWARE then
  begin
    FConnected := False;
    OFDStopPoll;
  end;
  if Result = 0 then
  begin
    FConnected := True;
    OFDStartPoll;
  end;
  FDisconnectTimerLastCommandTime := GetTickCount;
  if not FDisconnectTimer.Enabled then
    FDisconnectTimer.Enabled := True;
end;

function TFiscalPrinter.DoSend(const Data: AnsiString): Integer;
var
  i: Integer;
  CommandCode: Word;
begin
  Result := ClearResult;
  { if FDocument.Started then
    begin
    FDocument.Send(Data);
    Exit;
    end; }

  CommandCode := Ord(Data[1]);
  if CommandCode = $FF then
    CommandCode := MakeWord(Ord(Data[1]), Ord(Data[2]));
  Logger.Debug(Format('CommandCode=%.4x', [CommandCode]));
  if IsRepeatableCommand(CommandCode) then
  begin
    for i := 1 to CommandRetryCount do
    begin
      Result := SendCommand(Data);
      { if Result = 200 then
        begin
        Sleep(500);
        SendCommand(#$D1 + FPassw);
        end; }
      if Result <= 0 then
        Break;
      Logger.Debug(Format('Повтор команды %d/%d', [i, CommandRetryCount]));
    end;
  end else
  begin
    Result := SendCommand(Data);
    // Обработка для Ярус-ТК
    { if Result = 200 then
      begin
      for i := 1 to 3 do
      begin
      Sleep(500);
      SendCommand(#$D1 + FPassw);
      Result := SendCommand(Data);
      if Result = 0 then Break;
      end;
      end; }
  end;

  FECRInputOld := ECRInput;
  FECROutputOld := ECROutput;

  // Протокол КЯ - запрос сообщения об ошибке
  if (Result > 0) and (Result <> $50) and (Result <> $75) and (CommandCode <> $FC) and (CommandCode <> $16) and (CommandCode <> $F7) and (not FReadErrorDescription) then
  begin
    if PrinterModel.CapErrorDescription and RequestErrorDescription then
    begin
      if SendCommand(#$6B { + AnsiChar(Result) } ) < 0 then
        ResultCodeDescription := GetRes(@SErrorGetDescription);
      ResultCode := Result;
    end;
  end;
end;

function TFiscalPrinter.GetDriver: IPrinterDriver;
begin
  if FDriver = nil then
    FDriver := CreateDriver;
  Result := FDriver;
end;

function TFiscalPrinter.HasDriver: Boolean;
begin
  Result := FDriver <> nil;
end;

procedure TFiscalPrinter.WriteLogData(ResultCode: Integer; const ATxData, AOutput: AnsiString);
var
  S: AnsiString;
  OutputData: AnsiString;
begin
  if ResultCode <> 0 then
  begin
    if ResultCode > 0 then
      S := Format(', %.2xh', [ResultCode])
    else
      S := '';
    OutputData := Format('(%d%s) %s', [ResultCode, S, ResultCodeDescription]);
    Logger.Error(OutputData);
  end;
end;

function TFiscalPrinter.GetTransferByte: AnsiString;
begin
  Result := TransferBytes;
end;

procedure TFiscalPrinter.SetTransferByte(const Value: AnsiString);
begin
  TransferBytes := Value;
end;

{ ***************************************************************************** }
{
  {  Обновление информации о свойствах и методах
  {
  {***************************************************************************** }

procedure TFiscalPrinter.UpdateAddinLists(Dispatch: IDispatch);
var
  i, j: Integer;
  Item: TDispItem;
  TypeAttr: PTypeAttr;
  TypeInfo: ITypeInfo;
  FuncDesc: PFuncDesc;
  EngName: WideString;
  RusName: WideString;
  pEngName: TBStr;
  pRusName: TBStr;
begin
  Props.Clear;
  Methods.Clear;
  Dispatch.GetTypeInfo(0, 0, TypeInfo);
  if TypeInfo = nil then
    Exit;
  TypeInfo.GetTypeAttr(TypeAttr);
  try
    for i := 0 to TypeAttr.cFuncs - 1 do
    begin
      TypeInfo.GetFuncDesc(i, FuncDesc);
      try
        pEngName := '';
        pRusName := '';
        if not Succeeded(TypeInfo.GetDocumentation(FuncDesc.memid, @pEngName, @pRusName, nil, nil)) then
          Continue;
        try
          EngName := OleStrToString(pEngName);
          RusName := OleStrToString(pRusName);
        finally
          SysFreeString(pEngName);
          SysFreeString(pRusName);
        end;
        case FuncDesc.invkind of

          INVOKE_PROPERTYGET:
            begin
              Item := TDispItem.Create(Props);
              Item.memid := FuncDesc.memid;
              Item.EngName := EngName;
              Item.RusName := RusName;
              Item.IsReadable := True;
              Item.vt := FuncDesc.elemdescFunc.tdesc.vt;
            end;

          INVOKE_FUNC:
            begin
              Item := TDispItem.Create(Methods);
              Item.memid := FuncDesc.memid;
              Item.EngName := EngName;
              Item.RusName := RusName;
            end;

        else
          begin
            for j := Props.Count - 1 downto 0 do
            begin
              if Props[j].memid = FuncDesc.memid then
              begin
                Props[j].IsWritable := True;
                Break;
              end;
            end;
          end;
        end;
      finally
        TypeInfo.ReleaseFuncDesc(FuncDesc);
      end;
    end;
  finally
    TypeInfo.ReleaseTypeAttr(TypeAttr);
  end;
end;

function TFiscalPrinter.MethodSupported: WordBool;
begin
  Result := Methods.ItemByName(MethodName) <> nil;
end;

function TFiscalPrinter.PropertySupported: WordBool;
begin
  Result := Props.ItemByName(PropertyName) <> nil;
end;

function TFiscalPrinter.GetLogCommands: Boolean;
begin
  Result := False;
end;

procedure TFiscalPrinter.SetLogCommands(const Value: Boolean);
begin
  //
end;

function TFiscalPrinter.GetLogMethods: Boolean;
begin
  Result := False;
end;

procedure TFiscalPrinter.SetLogMethods(const Value: Boolean);
begin
  //
end;

function TFiscalPrinter.GetLogFileMaxSize: DWORD;
begin
  Result := 0;
end;

procedure TFiscalPrinter.SetLogFileMaxSize(const Value: DWORD);
begin
  //
end;

function TFiscalPrinter.GetLineDataHex: AnsiString;
begin
  Result := StrToHex(LineData);
end;

procedure TFiscalPrinter.SetLineDataHex(const Value: AnsiString);
begin
  try
    LineData := HexToStr(Value);
  except
    on E: Exception do
      Logger.Error(E.Message);
  end;
end;

function TFiscalPrinter.GetPortNames: AnsiString;
begin
  try
    Result := Driver.GetPortNames;
    ClearResult;
  except
    on E: Exception do
    begin
      HandleException(E);
      Result := '';
    end;
  end;
end;

function TFiscalPrinter.GetINNAsInteger: Integer;
begin
  Result := StrToIntDef(INN, 0);
end;

function TFiscalPrinter.GetSerialNumberAsInteger: Integer;
begin
  Result := StrToIntDef(SerialNumber, 0);
end;

function TFiscalPrinter.GetHasCashControlLicense: Boolean;
begin
  Result := Driver.HasCashControlLicense;
end;

function TFiscalPrinter.GetLineData(Image: TImage; Index: Integer): AnsiString;
const
  Bits: array[0..7] of Byte = (1, 2, 4, 8, $10, $20, $40, $80);
var
  Data: Byte;
  i, j: Integer;
  ImageWidth: Integer;
begin
  Result := '';
  ImageWidth := Image.Picture.Width;

  for i := 0 to 39 do
  begin
    Data := 0;
    for j := 0 to 7 do
    begin
      if (8 * i + j) <= ImageWidth then
      begin
        if (Image.Picture.Bitmap.Canvas.Pixels[8 * i + j, Index] = clBlack) or (Image.Picture.Bitmap.Canvas.Pixels[8 * i + j, Index] = 0) then
          Data := Data + Bits[j];
      end;
    end;
    Result := Result + AnsiChar(Data);
  end;
  if CenterImage then
  begin
    Result := Copy(StringOfChar(#$0, (320 - ImageWidth) div 16) + Result, 1, 40);
  end;
end;

function TFiscalPrinter.LoadBlockGraphics512(Image: TImage;
  { Progress: TfmProgress; } ALineNumber: Integer): Integer;
var
  LinesInBlock: Integer;
  LineLen: Integer;
  LN: Integer;
  IsEnd: Boolean;
  RealLinesCount: Integer;
  FirstLN: Integer;
  SaveFirstLN: Integer;
begin
  Result := ClearResult;
  FirstLN := FirstLineNumber;
  LineLen := Length(GetLineData512(Image, 0, GraphBufferType, True));
  LinesInBlock := (PrinterModel.MaxCmdLength - 12) div LineLen;
  LN := 1;
  SaveFirstLN := FirstLineNumber;
  try
    while True do
    begin
      FirstLineNumber := LN + FirstLN - 1;
      LineLength := LineLen;
      LineData := GetBlockData512(Image, GraphBufferType, LN, LinesInBlock, IsEnd, RealLinesCount);
      if LineData = '' then
        Break;
      LineNumber := RealLinesCount;
      Result := LoadGraphics512;
      if Result = 0 then
      begin
        Inc(LN, RealLinesCount);
      end else
      begin
        Exit;
      end;
      if IsEnd then
        Break;
    end;
  finally
    FirstLineNumber := SaveFirstLN;
  end;
end;

resourcestring
  SImageLoading = 'Загрузка картинки';
  SStopExecution = 'Прервать выполнение ?';
  SInvalidImageWidth = 'Ширина картинки превышает допустимую';
  SInvalidImageHeight = 'Высота картинки превышает допустимую';

function TFiscalPrinter.LoadBlockGraphics(Image: TImage;
  { Progress: TfmProgress; } ALineNumber: Integer): Integer;
var
  LNumber: Integer;
  Count: Integer;
  j: Integer;
  LinesPerBlock: Integer;
begin
  try
    Result := ClearResult;
    LinesPerBlock := ((PrinterModel.MaxCmdLength - 10) div 40);
    Count := Image.Picture.Height;
    { if ShowProgress and (Progress <> nil) then
      Progress.StartProgress(SImageLoading, Count); }

    LNumber := 0;
    while LNumber < Count do
    begin
      { if ShowProgress and (Progress <> nil) then
        begin
        Progress.Position := LNumber;
        if Progress.StopFlag then
        begin
        if MessageBox(Progress.Handle, PChar(SStopExecution),
        PChar(SDriverName), MB_YESNO or MB_ICONEXCLAMATION) = ID_YES then
        RaiseError(E_USERBREAK, SDriverAbortedByUser);
        Progress.StopFlag := False;
        end;
        end; }
      LineNumber := LNumber + ALineNumber;
      LineData := '';
      for j := 1 to LinesPerBlock do
      begin
        LineData := LineData + GetLineData(Image, LNumber);
        Inc(LNumber);
        if LNumber >= Count then
          Break;
      end;
      Result := LoadLineDataEx;
      if Result <> 0 then
        Exit;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.LoadGraphics(Image: TImage;
  { Progress: TfmProgress; } ALineNumber: Integer): Integer;
var
  i: Integer;
  Count: Integer;
begin
  Result := ClearResult;
  Count := Image.Picture.Height;
  { if ShowProgress and (Progress <> nil) then
    Progress.StartProgress(SImageLoading, Count); }
  i := 0;
  while i < Count do
  begin
    { if ShowProgress and (Progress <> nil) then
      begin
      Progress.Position := i;
      if Progress.StopFlag then
      begin
      if MessageBox(Progress.Handle, PChar(SStopExecution),
      PChar(SDriverName), MB_YESNO or MB_ICONEXCLAMATION) = ID_YES then
      RaiseError(E_USERBREAK, SDriverAbortedByUser);
      Progress.StopFlag := False;
      end;
      end; }
    LineNumber := i + ALineNumber;
    LineData := GetLineData(Image, i);
    Result := LoadLineDataEx;
    if Result = 0 then
      Inc(i)
    else
      Break;
  end;
end;

function TFiscalPrinter.DoLoadImage(const FileName: AnsiString): Integer;
var
  Image: TImage;
  // Progress: TfmProgress;
  SaveLineNumber: Integer;
begin
  Result := ClearResult;
  Image := TImage.Create(nil);
  SaveLineNumber := LineNumber;
  if SaveLineNumber = 0 then
    Inc(SaveLineNumber);
  FirstLineNumber := SaveLineNumber;
  try
    // Progress := TfmProgress.Create(nil);
    try
      Image.Picture.LoadFromFile(FileName);
      if Image.Picture.Graphic = nil then
        Exit;
      if Image.Picture.Bitmap.Width > 320 then
        RaiseError(E_INVALIDPARAM, GetRes(@SInvalidImageWidth));

      if Image.Picture.Bitmap.Height > 1200 then
        RaiseError(E_INVALIDPARAM, GetRes(@SInvalidImageHeight));

      if PrinterModel.CapLoadBlockGraphics then
        Result := LoadBlockGraphics(Image, { Progress, } SaveLineNumber)
      else
        Result := LoadGraphics(Image, { Progress, } SaveLineNumber);
      LastLineNumber := Image.Picture.Bitmap.Height + FirstLineNumber - 1;
    finally
      LineNumber := SaveLineNumber;
      Image.Free;
      // Progress.Free;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.LoadImage: Integer;
begin
  try
    Result := DoLoadImage(FileName);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.OpenNonfiscalDocument: Integer;
begin
  Result := Send(#$E2 + FPassw);
end;

function TFiscalPrinter.CloseNonfiscalDocument: Integer;
begin
  Result := Send(#$E3 + FPassw);
end;

function TFiscalPrinter.PrintAttribute: Integer;
begin
  try
    CheckIntProp(AttributeNumber, 0, $FF, 'AttributeNumber');
    CheckIntProp(Length(AttributeValue), 1, 200, 'AttributeValue');

    Result := Send(#$E4 + FPassw + AnsiChar(AttributeNumber) + AttributeValue);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ReadModelParamValue: Integer;
begin
  try
    Result := ClearResult;
    ModelParamValue := PrinterModel.GetParamValue(GetModelParamNumber);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetLogger: TLogger;
begin
  if FLogger = nil then
    FLogger := TLogger.Create(Self.ClassName);
  Result := FLogger;
end;

// Свойство CharLineLength
function TFiscalPrinter.Get_CharLineLength: Integer;
begin
  Result := Devices.LDCharLineLength;
end;

// Получить ширину печати в символах
function TFiscalPrinter.GetCharLineLength: Integer;
var
  SavePassword: Integer;
begin
  Result := E_NOERROR;

  // Если уже установлено, выходим.
  if Devices.LDCharLineLength <> 0 then
    Exit;

  SavePassword := Password;
  try
    Password := SysAdminPassword;
    FontType := 1;
    Result := GetFontMetrics;
    if DRV_SUCCESS(Result) then
    begin
      Devices.LDCharLineLength := 40;
      if CharWidth <> 0 then
        Devices.LDCharLineLength := Trunc(PrintWidth / CharWidth);
      Result := SetParamLD;
    end;
  finally
    Password := SavePassword;
  end;
end;

{ Получить параметры текущей модели }

function TFiscalPrinter.GetPrinterModel: TPrinterModel;
var
  ModelID: Integer;
  Model: TPrinterModel;
begin
  Result := FPrinterModel;
  if FGetPrinterModel then
    Exit;
  if not TestMode then
    ModelID := GetUModelValue
  else
    ModelID := 0;

  if ModelIndex = 0 then
  begin
    Model := Models.ItemByModelID(ModelID);
    if Model = nil then
    begin
      Model := Models.DefaultModel;
      Model.ModelID := ModelID;
      Model.Name := UDescription;
    end;
    FPrinterModel.Assign(Model);
    if (UMajorProtocolVersion > 1) or ((UMinorProtocolVersion >= 13) and (UMajorProtocolVersion = 1)) then
    begin
      if not TestMode then
        GetExDeviceMetrics;
    end;
  end else
  begin
    if Models.ValidIndex(ModelIndex - 1) then
    begin
      Model := Models[ModelIndex - 1];
    end else
    begin
      Model := Models.DefaultModel;
      Model.ModelID := ModelID;
      Model.Name := UDescription;
    end;
    FPrinterModel.Assign(Model);
  end;
  Logger.Debug('------------------------------------------------------------');
  Logger.Debug('PRO-RETAIL: М3Про v' + GetFileVersionInfoStr);
  Logger.Debug(Format('Модель : %d, %s ', [ModelID, UDescription]));
  Logger.Debug('------------------------------------------------------------');
  FGetPrinterModel := True;
end;

{ Загрузить параметры CashControl }

function TFiscalPrinter.LoadCashControlParams: Integer;
begin
  Result := E_NOERROR;
end;

{ Подключено устройство ? }

function TFiscalPrinter.GetConnected: Boolean;
begin
  Result := Driver.PortOpened;
end;

{ Подключить/отключить устройство }

procedure TFiscalPrinter.SetConnected(const Value: Boolean);
begin
  if Value then
    Connect
  else
    Disconnect;
end;

(* ******************************************************************************
  PrintBarcodeText
  Возможные значения:
  0: не печатать
  1: под штрихкодом
  2: над штрихкодом
  3: под и над штрихкодом
  ****************************************************************************** *)

function TFiscalPrinter.GetPrintBarcodeText: Integer;
begin
  if (PrintBarcodeText < 0) or (PrintBarcodeText > 3) then
    InvalidProp('PrintBarcodeText');
  Result := PrintBarcodeText;
end;

// Введенный пароль налогового инспектора

function TFiscalPrinter.GetEnteredTaxPassword: Integer;
begin
  Result := LDTaxPassword;
end;

procedure TFiscalPrinter.SetEnteredTaxPassword(Value: Integer);
begin
  LDTaxPassword := Value;
end;

(* ******************************************************************************

  Запрос состояния купюроприемника
  Команда: E5H. Длина сообщения: 5 байт.
  - Пароль оператора (4 байта)
  Ответ: E5H. Длина сообщения: 6 байт.
  - Код ошибки (1 байт)
  - Порядковый номер оператора (1 байт)1...30
  - Режим опроса купюроприемника (1 байт) 0 - не ведется, 1 - ведется
  - Poll 1 (1 байт)
  - Poll 2 (1 байт) - Байты, которые вернул купюроприемник на последнюю
  команду Poll (подробности в описании протокола CCNet)

  ****************************************************************************** *)

function TFiscalPrinter.GetCashAcceptorStatus: Integer;
begin
  Result := Send(#$E5 + FPassw);
end;

(* ******************************************************************************

  Запрос регистров купюроприемника
  Команда: E6H. Длина сообщения: 6 байт.
  - Пароль оператора (4 байта)
  - Номер набора регистров (1 байт) 0 - количество купюр в текущем чеке.
  1 - количество купюр в текущей смене, 2 - Общее количество принятых купюр.
  Ответ: E6H. Длина сообщения: 100 байт.
  - Код ошибки (1 байт)
  - Порядковый номер оператора (1 байт)1...30
  - Номер набора регистров (1 байт)
  - Количество купюр типа 0..23(4*24=96 байт) 24 4-х байтных целых числа.

  ****************************************************************************** *)

function TFiscalPrinter.GetCashAcceptorRegisters: Integer;
begin
  try
    Result := Send(#$E6 + FPassw + AnsiChar(GetCARegisterNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

(* ******************************************************************************

  Отчет по купюроприемнику
  Команда: E7H. Длина сообщения: 5 байт.
  - Пароль администратора или системного администратора (4 байта)
  Ответ: E7H. Длина сообщения: 3 байта.
  - Код ошибки (1 байт)
  - Порядковый номер оператора (1 байт)29, 30

  ****************************************************************************** *)

function TFiscalPrinter.CashAcceptorReport: Integer;
begin
  Result := Send(#$E7 + FPassw);
end;

function TFiscalPrinter.ReadBanknoteCount: Integer;
begin
  Result := 0;
  try
    BanknoteCount := Banknotes[GetBanknoteType];
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetPollDescription: AnsiString;
begin
  Result := PollToDescription(Poll1, Poll2);
end;

function TFiscalPrinter.ReadModelParam: Integer;
var
  ModelParam: TModelParam;
begin
  try
    Result := ClearResult;
    ModelParam := PrinterModel.Params[ModelParamIndex];
    ModelParamNumber := ModelParam.ID;
    ModelParamValue := ModelParam.Value;
    ModelParamDescription := ModelParam.Text;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ReadModelParamDescription: Integer;
var
  ModelParam: TModelParam;
begin
  Result := 0;
  try
    ModelParam := PrinterModel.Params.ItemByID(GetModelParamNumber);
    if ModelParam = nil then
      InvalidProp('ModelParamNumber, ' + IntToStr(GetModelParamNumber));
    ModelParamDescription := ModelParam.Text;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetModelParamNumber: Integer;
begin
  Result := ModelParamNumber;
end;

(* *****************************************************************************
  Чтение параметров активизации ЭКЛЗ
  Команда: СDH. Длина сообщения: 6 байт.
  "	Пароль оператора (4 байта)
  "	Номер активизации 1…255 (1 байт)
  Ответ:		CDH. Длина сообщения: 12 байт.
  "	Код ошибки (1 байт)
  "	Дата активизации ГГ-ММ-ДД (3 байта)
  "	Регистрационный номер ЭКЛЗ (5 байт)
  "	Номер смены перед активизацией 0000…9999 (2 байта)
  ****************************************************************************** *)

function TFiscalPrinter.ReadEKLZActivizationParams: Integer;
begin
  try
    if (RegistrationNumber < 1) or (RegistrationNumber > 255) then
      InvalidProp('RegistrationNumber');

    Result := Send(#$CD + FPassw + AnsiChar(RegistrationNumber));

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

(* ******************************************************************************

  Запрос короткого отчета по диапазону смен
  Команда:	D2H. Длина сообщения: 9 байт.
  "	Пароль оператора (4 байта)
  "	Номер первой смены 0000…9999 (2 байта)
  "	Номер последней смены 0000…9999 (2 байта)
  Ответ:		D2H. Длина сообщения:38 байта.
  "	Код ошибки (1 байт)
  "	Номер первой смены 0000…9999 (2 байта)
  "	Номер последней смены 0000…9999 (2 байта)
  "	Дата первой смены ГГ-ММ-ДД (3 байта)
  "	Дата последней смены ГГ-ММ-ДД (3 байта)
  "		Сумма сменных итогов продаж (8 байт)
  "	Сумма сменных итог покупок (6 байт) При отсутствии ФП 2 FFh FFh FFh FFh FFh FFh
  "	Сумма сменных возвратов продаж (6 байт) При отсутствии ФП 2 FFh FFh FFh FFh FFh FFh
  "	Сумма сменных возвратов покупок (6 байт) При отсутствии ФП 2 FFh FFh FFh FFh FFh FFh

  ****************************************************************************** *)

function TFiscalPrinter.GetShortReportInSessionRange: Integer;
var
  Data: AnsiString;
begin
  try
    if (FirstSessionNumber < 0) or (FirstSessionNumber > 9999) then
      InvalidProp('FirstSessionNumber');
    if (LastSessionNumber < 0) or (LastSessionNumber > 9999) then
      InvalidProp('LastSessionNumber');

    Data := #$D2 + FPassw + WordToStr(FirstSessionNumber) + WordToStr(LastSessionNumber);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

(* ******************************************************************************

  Запрос короткого отчета по диапазону дат
  Команда:	D3H. Длина сообщения:11 байт.
  "	Пароль оператора (4 байта)
  "	Дата первой смены ГГ-ММ-ДД (3 байта)
  "	Дата последней смены ГГ-ММ-ДД (3 байта)
  Ответ:		D3H. Длина сообщения: 38 байта.
  "	Код ошибки (1 байт)
  "	Номер первой смены 0000…9999 (2 байта)
  "	Номер последней смены 0000…9999 (2 байта)
  "	Дата первой смены ГГ-ММ-ДД (3 байта)
  "	Дата последней смены ГГ-ММ-ДД (3 байта)
  "		Сумма сменных итогов продаж (8 байт)
  "	Сумма сменных итог покупок (6 байт) При отсутствии ФП 2 FFh FFh FFh FFh FFh FFh FFh
  "	Сумма сменных возвратов продаж (6 байт) При отсутствии ФП 2 FFh FFh FFh FFh FFh FFh FFh
  "	Сумма сменных возвратов покупок (7 байт) При отсутствии ФП 2 FFh FFh FFh FFh FFh FFh FFh

  ****************************************************************************** *)

function TFiscalPrinter.GetShortReportInDatesRange: Integer;
var
  Data: AnsiString;
  y1, m1, d1: Word;
  y2, m2, d2: Word;
begin
  try
    DecodeDate(FirstSessionDate, y1, m1, d1);
    if y1 < 2000 then
      InvalidProp('FirstSessionDate');
    DecodeDate(LastSessionDate, y2, m2, d2);
    if y2 < 2000 then
      InvalidProp('LastSessionDate');

    Data := #$D3 + FPassw + AnsiChar(d1) + AnsiChar(m1) + AnsiChar(y1 - 2000) + AnsiChar(d2) + AnsiChar(m2) + AnsiChar(y2 - 2000);

    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

/// ////////////////////////////////////////////////////////////////////////////
// Command for MasterPay-K. Read last receipt

function TFiscalPrinter.ReadLastReceipt: Integer;
begin
  try
    Result := Send(#$D5 + FPassw);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ReadLastReceiptLine: Integer;
begin
  try
    Result := Send(#$D6 + FPassw);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ReadLastReceiptMac: Integer;
begin
  try
    Result := Send(#$D7 + FPassw);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MasterPayClearBuffer: Integer;
begin
  try
    Result := Send(#$D8 + FPassw);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MasterPayAddTextBlock: Integer;
var
  Msg: WideString;
begin
  try
    if (TextBlockNumber < 0) or (TextBlockNumber > $FF) then
    begin
      Msg := Format('%s TextBlockNumber (%d).', [GetRes(@SInvalidPropValue), TextBlockNumber]);
      RaiseError(E_INVALIDPARAM, Msg);
    end;
    if Length(TextBlock) > $FF then
    begin
      RaiseError(E_INVALIDPARAM, Format('%s %s', [GetRes(@SInvalidPropValue), 'TextBlock.']));
    end;
    Result := Send(#$D9 + FPassw + AnsiChar(TextBlockNumber) + TextBlock);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MasterPayCreateMac: Integer;
begin
  try
    Result := Send(#$DA + FPassw + AnsiChar(TextBlockNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.BeginDocument: Integer;
begin
  Result := ClearResult;
end;

function TFiscalPrinter.EndDocument: Integer;
begin
  Result := ClearResult;
end;

function TFiscalPrinter.GetPosControlReceiptSeparator: AnsiString;
begin
  Result := '';
end;

procedure TFiscalPrinter.SetPosControlReceiptSeparator(const Value: AnsiString);
begin
end;

// procedure TFiscalPrinter.SetPPPServiceEnabled(const Value: Boolean);
// begin
// if Value then
// FPPPService.Start(PPPComNumber)
// else
// FPPPService.Stop;
// end;

(* *****************************************************************************

  Загрузка данных

  Команда: DDH. Длина сообщения: 71 байт.
  "	Пароль (4 байта)
  "	Тип данных  (1 байт) 0 - данные для двумерного штрих-кода
  "	Порядковый номер блока данных (1 байт)
  "	Данные (64 байта)
  Ответ: DDH. Длина сообщения: 3 байта.
  "	Код ошибки (1 байт)
  "	Порядковый номер оператора (1 байт) 1…30

  ***************************************************************************** *)

function TFiscalPrinter.LoadBlockData: Integer;
var
  Data: TBlockData;
begin
  try
    Data.Password := Password;
    Data.BlockType := BlockType;
    Data.BlockNumber := BlockNumber;
    Data.BlockData := HexToStr(BlockDataHex);

    CheckIntProp(BlockType, 0, $FF, 'BlockType');
    CheckIntProp(BlockNumber, 0, $FF, 'BlockNumber');
    CheckIntProp(Length(Data.BlockData), 0, 64, 'BlockDataHex');

    Result := IntLoadBlockData(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.IntLoadBlockData(const Data: TBlockData): Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$DD + IntToBin(Data.Password, 4) + AnsiChar(Data.BlockType) + AnsiChar(Data.BlockNumber) + Data.BlockData;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

(* *****************************************************************************

  Печать многомерного штрих-кода
  Команда: DEH. Длина сообщения: 14 байт.
  "	Пароль (4 байта)
  "	Тип штрих-кода (1 байт)
  "	Длина данных штрих-кода (2 байта)
  "	Номер начального блока данных (1байт)
  "	Параметр 1 (1 байт)
  "	Параметр 2 (1 байт)
  "	Параметр 3 (1 байт)
  "	Параметр 4 (1 байт)
  "	Параметр 5 (1 байт)

  Ответ:		DEH. Длина сообщения: 3 байт.
  "	Код ошибки (1 байт)
  "	Порядковый номер оператора (1 байт) 1…30

  ***************************************************************************** *)

function TFiscalPrinter.Print2DBarcode: Integer;
var
  Data: T2DBarcode;
begin
  try
    CheckIntProp(BarcodeType, 0, $FF, 'BarcodeType');
    CheckIntProp(BarcodeDataLength, 0, $FFFF, 'BarcodeDataLength');
    CheckIntProp(BarcodeStartBlockNumber, 0, $FF, 'BarcodeStartBlockNumber');
    CheckIntProp(BarcodeParameter1, 0, $FF, 'BarcodeParameter1');
    CheckIntProp(BarcodeParameter2, 0, $FF, 'BarcodeParameter2');
    CheckIntProp(BarcodeParameter3, 0, $FF, 'BarcodeParameter3');
    CheckIntProp(BarcodeParameter4, 0, $FF, 'BarcodeParameter4');
    CheckIntProp(BarcodeParameter5, 0, $FF, 'BarcodeParameter5');

    Data.Password := Password;
    Data.BarcodeType := BarcodeType;
    Data.DataLength := BarcodeDataLength;
    Data.BlockNumber := BarcodeStartBlockNumber;
    Data.Parameter1 := BarcodeParameter1;
    Data.Parameter2 := BarcodeParameter2;
    Data.Parameter3 := BarcodeParameter3;
    Data.Parameter4 := BarcodeParameter4;
    Data.Parameter5 := BarcodeParameter5;
    Data.Alignment := Get2DBarcodeAlignment;
    { if BarcodeType = 3 then
      begin
      BarcodeType := bcQRCode;
      try

      Result := PrintBarcodeGraph;
      Exit;
      finally
      BarcodeType := 3;
      end;
      end; }

    Result := IntPrint2DBarcode(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.IntPrint2DBarcode(const Data: T2DBarcode): Integer;
var
  Command: AnsiString;
  BarcodeType: Byte;
begin
  try
    BarcodeType := Data.BarcodeType;
    if DelayedPrint then
      SetBit(BarcodeType, 6);
    Command := #$DE + IntToBin(Data.Password, 4) + AnsiChar(BarcodeType) + WordToStr(Data.DataLength) + AnsiChar(Data.BlockNumber) + AnsiChar(Data.Parameter1) + AnsiChar(Data.Parameter2) + AnsiChar(Data.Parameter3) + AnsiChar(Data.Parameter4) + AnsiChar(Data.Parameter5) + AnsiChar(Data.Alignment);

    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.LoadBarcodeData(BlockType: Integer; const Data: AnsiString): Integer;
var
  i: Integer;
  Count: Integer;
  Block: TBlockData;
const
  DATA_BLOCK_SIZE = 64;
begin
  Logger.Debug(Format('Load data to buffer (BlockType = %d) : ', [BlockType, StrToHex(Data)]));
  Result := 0;
  Count := (Length(Data) + DATA_BLOCK_SIZE - 1) div DATA_BLOCK_SIZE;
  for i := 0 to Count - 1 do
  begin
    Block.Password := Password;
    Block.BlockType := BlockType;
    Block.BlockNumber := i;
    Block.BlockData := Copy(Data, 1 + i * DATA_BLOCK_SIZE, DATA_BLOCK_SIZE);
    Result := IntLoadBlockData(Block);
    if Result <> 0 then
      Exit;
  end;
end;

// Load and print 2D barcode
function TFiscalPrinter.LoadAndPrint2DBarcode: Integer;
var
  BarcodeRec: T2DBarcode;
begin
  Logger.Debug('LoadAndPrint2DBarcode');
  try

    if (not PrinterModel.Cap2DBarcode) and (not PrinterModel.CapFN) then
    begin
      Logger.Debug('2d barcode is not supported');
      BarcodeType := Ord(bcQRCode);
      FirstLineNumber := BarcodeFirstLine;
      if FirstLineNumber = 0 then
        FirstLineNumber := 1;
      Result := PrintBarcodeGraph;
      Exit;
    end;
    // Загрузка блоков данных
    Result := LoadBarcodeData(0, Barcode);

    if Result <> 0 then
      Exit;
    // Print
    BarcodeRec.Password := Password;
    BarcodeRec.BarcodeType := BarcodeType;
    BarcodeRec.DataLength := Length(Barcode);
    BarcodeRec.BlockNumber := 0;
    BarcodeRec.Parameter1 := BarcodeParameter1;
    BarcodeRec.Parameter2 := BarcodeParameter2;
    BarcodeRec.Parameter3 := BarcodeParameter3;
    BarcodeRec.Parameter4 := BarcodeParameter4;
    BarcodeRec.Parameter5 := BarcodeParameter5;
    BarcodeRec.Alignment := Get2DBarcodeAlignment;

    repeat
      Result := IntPrint2DBarcode(BarcodeRec);
    until (Result <> $50) and (Result <> $4B);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.Get2DBarcodeAlignment: Byte;
begin
  case BarcodeAlignment of
    baLeft:
      Result := BARCODE_2D_ALIGNMENT_LEFT;
    baRight:
      Result := BARCODE_2D_ALIGNMENT_RIGHT;
  else
    Result := BARCODE_2D_ALIGNMENT_CENTER;
  end;
end;

function TFiscalPrinter.GetLogMaxFileCount: Integer;
begin
  Result := GlobalLogger.MaxFileCount;
end;

function TFiscalPrinter.GetLogMaxFileSize: Integer;
begin
  Result := GlobalLogger.MaxFileSize;
end;

procedure TFiscalPrinter.SetLogMaxFileCount(const Value: Integer);
begin
  GlobalLogger.MaxFileCount := Value;
end;

procedure TFiscalPrinter.SetLogMaxFileSize(const Value: Integer);
begin
  GlobalLogger.MaxFileSize := Value;
end;

function TFiscalPrinter.GetSaveSettingsType: Integer;
begin
  Result := GetStorageType;
end;

procedure TFiscalPrinter.SetSaveSettingsType(Value: Integer);
begin
  SetStorageType(Value);
end;

function TFiscalPrinter.Translate(const Text: WideString): WideString;
begin
  Logger.Debug('Translate ' + Text);
  Result := Text;
  if TestMode then
    Exit;

  if TranslationEnabled then
  begin
    Result := FTranslation.Translate(Result);
    Logger.Debug('Translated ' + Result);
  end;
end;

function TFiscalPrinter.DeviceToStr(const Text: AnsiString): WideString;
begin
  case CodePage of
    CODE_PAGE_DEFAULT:
      Result := Text;
    CODE_PAGE_RUSSIAN:
      Result := AnsiToUnicode(Text, 1251);
    CODE_PAGE_ARMENIAN_UNICODE:
      Result := ArmenianToUnicode(Text);
    CODE_PAGE_ARMENIAN_ANSI:
      Result := ArmenianToAscii(Text);
    CODE_PAGE_KAZAKH_UNICODE:
      Result := KazakhToUnicode(Text);
    CODE_PAGE_TURKMEN_UNICODE:
      Result := TurkmenToUnicode(Text);
  else
    Result := Text;
  end;
end;

function TFiscalPrinter.StrToDevice(const Text: WideString): WideString;
begin
  case CodePage of
    CODE_PAGE_DEFAULT:
      Result := Text;
    CODE_PAGE_RUSSIAN:
      Result := UnicodeToAnsi(Text, 1251);
    CODE_PAGE_ARMENIAN_UNICODE:
      Result := UnicodeToArmenian(Text);
    CODE_PAGE_ARMENIAN_ANSI:
      Result := AsciiToArmenian(Text);
    CODE_PAGE_KAZAKH_UNICODE:
      Result := UnicodeToKazakh(Text);
    CODE_PAGE_TURKMEN_UNICODE:
      Result := UnicodeToTurkmen(Text);
  else
    Result := Text;
  end;
end;

(*

  Запрос параметра модема

  Команда 04Н. Длина сообщения: 6 байт.
  "	Пароль оператора (4 байта)
  "	Номер параметра
  o	0x01 - версия модема
  o	0x08 - состояние модема

  Ответ:  04H. Длина сообщения: 3-131 байта.
  "	Код ошибки (1 байт)
  "	Порядковый номер оператора (1 байт) 1…30
  "	Текстовая строка (0-128 байт)

*)

procedure TFiscalPrinter.Decode04(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  OperatorNumber := Ord(Data[1]);
  ParameterValue := Copy(Data, 2, Length(Data));
end;

function TFiscalPrinter.ReadModemParameter: Integer;
var
  Command: AnsiString;
begin
  try
    CheckIntProp(ParameterNumber, 0, 255, 'ParameterNumber');
    Command := #$04 + FPassw + AnsiChar(ParameterNumber);
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

(*

  Запись параметра модема

  Команда 05Н. Длина сообщения: 6-134 байт.
  "	Пароль оператора (4 байта)
  "	Номер параметра
  "	Текстовая строка (0-128 байт)

  Ответ:  04H. Длина сообщения: 3 байта.
  "	Код ошибки (1 байт)
  "	Порядковый номер оператора (1 байт) 1…30

*)

procedure TFiscalPrinter.Decode05(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  OperatorNumber := Ord(Data[1]);
end;

procedure CheckStrProp(const PropValue: AnsiString; MinLength, MaxLength: Integer; const PropName: AnsiString);
var
  S: WideString;
resourcestring
  SInvalidPropValue = 'Неверное значение свойства %s. Допустимая длина: %d..%d';
begin
  if (Length(PropValue) < MinLength) or (Length(PropValue) > MaxLength) then
  begin
    S := Format(GetRes(@SInvalidPropValue), [PropName, MinLength, MaxLength]);
    RaiseError(E_INVALIDPARAM, S);
  end;
end;

function TFiscalPrinter.WriteModemParameter: Integer;
var
  Command: AnsiString;
begin
  try
    CheckIntProp(ParameterNumber, 0, 255, 'ParameterNumber');
    CheckStrProp(ParameterValue, 0, 128, 'ParameterValue');
    Command := #$05 + FPassw + AnsiChar(ParameterNumber) + ParameterValue;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetModelNames: WideString;
resourcestring
  SModelAuto = 'Автоопределение';
begin
  Result := GetRes(@SModelAuto) + CRLF + Models.Names;
end;

function TFiscalPrinter.GetModelsCount: Integer;
begin
  Result := Models.Count;
end;

function TFiscalPrinter.ReadErrorDescription: Integer;
begin
  try
    FReadErrorDescription := True;
    try
      Result := Send(#$6B + AnsiChar(GetErrorCode));
    finally
      FReadErrorDescription := False;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetErrorCode: Integer;
begin
  if (errorcode < 0) or (errorcode > 255) then
    InvalidProp('ErrorCode');
  Result := errorcode;
end;

function TFiscalPrinter.GetUCodePageText: WideString;
begin
  Result := GetLanguageName(UCodePage);
end;

function TFiscalPrinter.GetModelParamCount: Integer;
begin
  Result := PrinterModel.Params.Count;
end;

function TFiscalPrinter.InitEEPROM: Integer;
begin
  Result := Send(#$FF#$16);
end;

function TFiscalPrinter.CheckConnection: Integer;
begin
  Result := 0;
  if (not CheckFMConnection) and (not CheckEJConnection) then
    Result := GetDeviceMetrics;
  if CheckFMConnection then
    Result := GetShortECRStatus;
  if (Result = 0) and (CheckEJConnection) then
  begin
    FCheckEJConnStatus := True;
    try
      Result := GetEKLZCode1Status;
    finally
      FCheckEJConnStatus := False;
    end;
  end;
end;

function TFiscalPrinter.ChangeProtocol: Integer;
var
  SaveProtocolType: Integer;
  SaveTimeout: Integer;
  SaveTCPPort: Integer;
begin
  SaveProtocolType := GetProtocolType;
  ProtocolType := FCurrentProtocolType;
  SaveTimeout := Timeout;
  SaveTCPPort := TCPPort;
  Result := GetECRStatus; // Получаем PortNumber
  if Result <> 0 then
    Exit;
  try
    Result := GetExchangeParam;
    if Result <> 0 then
      Exit;
    Result := SetExchangeParam;
    if Result <> 0 then
      Exit;
    ProtocolType := SaveProtocolType;
    Result := Disconnect;
    if Result <> 0 then
      Exit;
  finally
    Timeout := SaveTimeout;
    TCPPort := SaveTCPPort;
  end;
  Result := GetDeviceMetrics;
  if Result <> 0 then
    Exit;
end;

function TFiscalPrinter.Get_LDProtocolType: Integer;
begin
  Result := Devices.LDProtocolType;
end;

procedure TFiscalPrinter.Set_LDProtocolType(const Value: Integer);
begin
  Devices.LDProtocolType := Value;
end;

// Расширенный запрос
function TFiscalPrinter.GetECRParams: Integer;
var
  Data: AnsiString;
begin
  try
    Logger.Debug('GetECRParams');
    if not ((OperationType = 1) or (OperationType = 16)) then
      InvalidProp('OperationType');
    Data := #$F7 + AnsiChar(OperationType);
    if OperationType = 16 then
    begin
      Data := Data + AnsiChar(RequestType);
      case RequestType of
        // Отправить данные и принять N строк с таймаутом
        0:
          Data := Data + AnsiChar(GetLineNumber) + AnsiChar(ReadTimeout) + LineData;
        // Отправить данные без ожидания приема
        1:
          Data := Data + LineData;
        // Получить строки из буфера в диапазоне номеров
        2:
          Data := Data + AnsiChar(FirstLineNumber) + AnsiChar(LastLineNumber);
        // Прочитать N байт
        3:
          Data := Data + AnsiChar(GetLineNumber) + AnsiChar(ReadTimeout);
      end;
    end;
    Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.GetExDeviceMetrics;
begin
  if not FGetExDeviceMetrics then
  begin
    OperationType := 1;
    if DoSend(#$F7#$01) <> 0 then
      RaiseError(ResultCode, ResultCodeDescription);
    FGetExDeviceMetrics := True;
  end;
end;

function TFiscalPrinter.JournalOperation: Integer;
var
  Command: AnsiString;
begin
  try
    CheckIntProp(OperationType, 0, 1, 'OperationType');
    Command := #$DF + FPassw + AnsiChar(OperationType);
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetAdjustRITimeout: Boolean;
begin
  Result := FConnectionParams.AdjustRITimeout;
end;

procedure TFiscalPrinter.SetAdjustRITimeout(const Value: Boolean);
begin
  FConnectionParams.AdjustRITimeout := Value;
end;

function TFiscalPrinter.GetDoNotSendENQ: Boolean;
begin
  Result := FConnectionParams.DoNotSendENQ;
end;

procedure TFiscalPrinter.SetDoNotSendENQ(const Value: Boolean);
begin
  FConnectionParams.DoNotSendENQ := Value;
end;

function TFiscalPrinter.GetMaxCmdCount: Integer;
begin
  Result := FConnectionParams.MaxCmdCount;
end;

procedure TFiscalPrinter.SetMaxCmdCount(const Value: Integer);
begin
  if Value > 0 then
  begin
    FConnectionParams.MaxCmdCount := Value;
  end;
end;

function TFiscalPrinter.GetMaxAnsCount: Integer;
begin
  Result := FConnectionParams.MaxAnsCount;
end;

procedure TFiscalPrinter.SetMaxAnsCount(const Value: Integer);
begin
  if Value > 0 then
    FConnectionParams.MaxAnsCount := Value
  else
    FConnectionParams.MaxAnsCount := 1;
end;

function TFiscalPrinter.GetMaxENQCount: Integer;
begin
  Result := FConnectionParams.MaxENQCount;
end;

procedure TFiscalPrinter.SetMaxENQCount(const Value: Integer);
begin
  FConnectionParams.MaxENQCount := Value;
end;

function TFiscalPrinter.GetNakCount: Integer;
begin
  Result := FConnectionParams.NakCount;
end;

procedure TFiscalPrinter.SetNakCount(const Value: Integer);
begin
  FConnectionParams.NakCount := Value;
end;

function TFiscalPrinter.GetReconnectPort: Boolean;
begin
  Result := FConnectionParams.ReconnectPort;
end;

procedure TFiscalPrinter.SetReconnectPort(const Value: Boolean);
begin
  FConnectionParams.ReconnectPort := Value;
end;

function TFiscalPrinter.Get_ComputerName: AnsiString;
begin
  Result := FConnectionParams.ComputerName;
end;

function TFiscalPrinter.Get_ComNumber: Integer;
begin
  Result := FConnectionParams.ComNumber;
end;

procedure TFiscalPrinter.Set_ComNumber(const Value: Integer);
begin
  FConnectionParams.ComNumber := Value;
end;

procedure TFiscalPrinter.InitializeProps;
var
  VInfo: TVersionInfo;
begin
  VInfo := GetFileVersionInfo;
  FFileVersionMS := VInfo.MajorVersion;
  FFileVersionLS := VInfo.MinorVersion;
  FDriverMajorVersion := VInfo.MajorVersion;
  FDriverMinorVersion := VInfo.MinorVersion;
  FDriverRelease := VInfo.ProductRelease;
  FDriverBuild := VInfo.ProductBuild;
  FDriverVersion := GetFileVersionInfoStr;

  ProtocolType := 0;
  FCurrentProtocolType := 0;
  StringQuantity := 12;
  FTypeOfLastEntryFM := True;
  FTypeOfLastEntryFMEx := 1;
  FFirstSessionDay := 1;
  FFirstSessionMonth := 10;
  FFirstSessionYear := 1;
  FLastSessionDay := 1;
  FLastSessionMonth := 10;
  FLastSessionYear := 10;
  FirstSessionNumber := 1;
  LastSessionNumber := 1;
  ReportType := True;
  TypeOfSumOfEntriesFM := True;
  DeviceCode := 6;
  FirstLineNumber := 1;
  LastLineNumber := 1;
  FEKLZNumber := '';
  FLastKPKDay := 1;
  FLastKPKMonth := 10;
  FLastKPKYear := 1;
  LockTimeout := 10000;
  ECRDate := Date;
  ECRTime := Time;
  DocumentNumber := 0;
  SessionNumber := 0;
  EscapeIP := DefEscapeIP;
  EscapePort := DefEscapePort;
  EscapeTimeout := DefEscapeTimeout;
  SysAdminPassword := DefSysAdminPassword;
  Password := 30;
  SlipStringInterval := 24;
  INN := '0';
  FFMSoftVersion := '0.0';
  SerialNumber := '';
  UseReceiptRibbon := True;
  UseJournalRibbon := True;
  UseSlipCheck := False;
  IntervalValue := 24;
  IntervalNumber := 1;

  RunningPeriod := 1;
  TableNumber := 1;
  RowNumber := 1;
  FieldNumber := 1;
  Barcode := '0';
  FLogicalNumber := 1;
  FECRSoftVersion := '0.0';
  SetFMFlags(1);
  FECRFlagsValid := False;
  SetECRMode(0);
  CenterImage := True;
  PortNumber := 0;
  OFDExchangeSuspended := False;
  AutoOFDExchange := True;
  DelayOnDisconnect := 300;
  FPrintStringWidth := 0;
  FDefaultFont := 0;
  WrapStrings := True;
  RequestDocumentType := 0;
  FCashControlINN := '';
  UpdateFirmwareMethod := FWUPDATE_METHOD_DFU;
  MeasureUnit := 0;
  DivisionalQuantity := False;
  FWUpdateSaveTables := True;
  FWUpdateSaveCashCounter := False;
  FWUpdateFFDParams := 2;
  FWUpdateFFDWaitInterval := 3;
  MCScannerAutoSendMCStatus := False;
  MCScannerComNumber := 1;
  PayManServerURL := 'https://sbp.shtrih-m.ru:7000/';
  PayManUseQRDisplay := False;
  QRDisplayPortNumber := 1;
  PayManProcessingID := 1;
  CorrectDateTimeOnOpenSession := False;
  ClearResult;
end;

function TFiscalPrinter.GetBarcodeHex: AnsiString;
begin
  Result := StrToHex(Barcode);
end;

procedure TFiscalPrinter.SetBarcodeHex(const Value: AnsiString);
begin
  try
    Barcode := HexToStr(Value);
  except
    on E: Exception do
      Logger.Error(E.Message);
  end;
end;

function TFiscalPrinter.GetTCPPort: Integer;
begin
  Result := FConnectionParams.TCPPort;
end;

procedure TFiscalPrinter.SetTCPPort(const Value: Integer);
begin
  FConnectionParams.TCPPort := Value;
end;

function TFiscalPrinter.GetIPAddress: AnsiString;
begin
  Result := FConnectionParams.IPAddress;
end;

procedure TFiscalPrinter.SetIPAddress(const Value: AnsiString);
begin
  FConnectionParams.IPAddress := Value;
end;

function TFiscalPrinter.GetUseIPAddress: Boolean;
begin
  Result := FConnectionParams.UseIPAddress;
end;

procedure TFiscalPrinter.SetUseIPAddress(const Value: Boolean);
begin
  FConnectionParams.UseIPAddress := Value;
end;

function TFiscalPrinter.GetBufferingType: Integer;
begin
  Result := FConnectionParams.BufferingType;
end;

procedure TFiscalPrinter.SetBufferingType(const Value: Integer);
begin
  FConnectionParams.BufferingType := Value;
end;

function TFiscalPrinter.GetTimeout: Integer;
begin
  Result := FConnectionParams.Timeout;
end;

procedure TFiscalPrinter.SetTimeout(const Value: Integer);
begin
  FConnectionParams.Timeout := Value;
end;

function TFiscalPrinter.GetProtocolType: Integer;
begin
  Result := FConnectionParams.ProtocolType;
end;

procedure TFiscalPrinter.SetProtocolType(const Value: Integer);
begin
  if Value <> ProtocolType then
  begin
    if (Value > 1) or (Value < 0) then
      InvalidProp('ProtocolType');
    FConnectionParams.ProtocolType := Value;
  end;
end;

function TFiscalPrinter.GetBaudRate: Integer;
begin
  Result := FConnectionParams.BaudRate;
  if (Result < 0) or (Result > 9) then
    InvalidProp('BaudRate');
end;

procedure TFiscalPrinter.SetBaudRate(const Value: Integer);
begin
  FConnectionParams.BaudRate := Value;
end;

procedure TFiscalPrinter.Check(Code: Integer);
begin
  if Code <> 0 then
    RaiseError(Code, ResultCodeDescription);
end;

function TFiscalPrinter.GetTCPConnectionTimeout: Integer;
begin
  Result := FConnectionParams.TCPConnectionTimeout;
end;

procedure TFiscalPrinter.SetTCPConnectionTimeout(const Value: Integer);
begin
  FConnectionParams.TCPConnectionTimeout := Value;
end;

function TFiscalPrinter.GetSyncTimeout: Integer;
begin
  Result := FConnectionParams.SyncTimeout;
end;

procedure TFiscalPrinter.SetSyncTimeout(const Value: Integer);
begin
  FConnectionParams.SyncTimeout := Value;
end;

// ****************** Команды МФП ******************

function TFiscalPrinter.MFPActivization: Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$ED + FPassw + GetINN + GetRNMBin;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MFPCloseArchive: Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$F2 + FPassw;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MFPGetPermitActivizationCode: Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$EA + FPassw;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MFPGetCustomerCode: Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$EF + FPassw;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MFPGetPrepareActivizationResult: Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$EE + FPassw;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MFPPrepareActivization: Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$EB + FPassw + GetINN;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MFPSetCustomerCode: Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$E9 + FPassw + AnsiChar(GetCustomerCode);
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MFPSetPermitActivizationCode: Integer;
var
  Command: AnsiString;
  S: AnsiString;
begin
  try
    S := Copy(Int64ToBCDStr2(GetPermitActivizatonCode), 1, 3);
    S := StringOfChar(#$00, 3 - Length(S)) + S;
    Command := #$EC + FPassw + S;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.CloseCheckEx: Integer;
var
  Command: AnsiString;
begin
  { ///!!!
    if not TestMode then
    begin
    Result := GetECRStatus;
    if Result <> 0 then Exit;
    end; }

  try
    Command := #$8E + FPassw + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetSumm5 + GetSumm6 + GetSumm7 + GetSumm8 + GetSumm9 + GetSumm10 + GetSumm11 + GetSumm12 + GetSumm13 + GetSumm14 + GetSumm15 + GetSumm16 + GetDiscountOnCheck + AnsiChar(GetTax1) + AnsiChar(GetTax2) + AnsiChar(GetTax3) + AnsiChar(GetTax4) + GetStringForPrinting(31);
    Result := SendAuth(Command);
    DrvCloseCheck;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetMFPCode3Status: Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$D4 + FPassw;
    Result := Send(Command);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetINNBCD: AnsiString;
var
  k: Int64;
begin
  Result := '';
  k := GetINNAsInt64;
  Result := Int64ToBCDStr2(k);
  Result := StringOfChar(#$00, 6 - Length(Result)) + Result;
end;

function TFiscalPrinter.GetINNAsInt64: Int64;
var
  Code: Integer;
begin
  Val(INN, Result, Code);
  if Code <> 0 then
    InvalidProp('INN');
  CheckIntProp(Result, 0, 99999999999999, 'INN');
end;

function TFiscalPrinter.GetSerialNumberAsInt64: Int64;
var
  Code: Integer;
begin
  Val(INN, Result, Code);
  if Code <> 0 then
    InvalidProp('SerialNumber');
  CheckIntProp(Result, 0, 99999999999999, 'INN');
end;

function TFiscalPrinter.GetSerialNumberBCD: AnsiString;
var
  k: Int64;
begin
  Result := '';
  k := GetSerialNumberAsInt64;
  Result := Int64ToBCDStr2(k);
  Result := StringOfChar(#$00, 6 - Length(Result)) + Result;
end;

function TFiscalPrinter.GetRNMBCD: AnsiString;
var
  k: Int64;
begin
  Result := '';
  k := GetRNMAsInt64;
  Result := Int64ToBCDStr2(k);
  Result := StringOfChar(#$00, 6 - Length(Result)) + Result;
end;

function TFiscalPrinter.GetRNMAsInt64: Int64;
var
  Code: Integer;
begin
  Val(RNM, Result, Code);
  if Code <> 0 then
    InvalidProp('RNM');
  CheckIntProp(Result, 0, 999999999999, 'RNM');
end;

function TFiscalPrinter.GetRNMBin: AnsiString;
var
  Code: Integer;
  Value: Int64;
begin
  Val(RNM, Value, Code);
  if Code <> 0 then
    InvalidProp('RNM');
  CheckIntProp(Value, 0, 99999999999999, 'RNM');
  Result := IntToBin(Value, 6);
end;

function TFiscalPrinter.ShowAdditionalParams: Integer;
var
  ParamsDlg: TfmParams;
begin
  Result := 0;
  try
    ParamsDlg := TfmParams.CreatePage(nil, FDrvFR49);
    SetWindowLong(ParamsDlg.Handle, GWL_HWNDPARENT, ParentWnd);
    try
      ParamsDlg.UpdatePage;
      ParamsDlg.ShowModal;
    finally
      ParamsDlg.Free;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetCloudCashDeskParams: Integer;
// var
// Params: TReceiptServerParams;
begin
  Result := 0;
  { try
    Params := TReceiptServerParams.Create;
    try
    Params.Load;
    ECRID := Params.ECRID;
    CloudCashDeskEnabled := Params.Enabled;
    finally
    Params.Free;
    end;
    except
    on E: Exception do
    Result := HandleException(E);
    end; }
end;

function TFiscalPrinter.LoadBarcodeGraph: Integer;
var
  Row, Column: Integer;
  Image, BarcodeImage: TImage;
  SaveLineNumber: Integer;
  Scale: Double;
  Padding: Integer;
  SaveCenterImage: Boolean;
  // GraphicWidth: Integer;
begin
  try
    Logger.Debug('LoadBarcodeGraph');
    Result := ClearResult;
    try
      if PrinterModel.CapGraphics512 then
        FPrintWidth := PrinterModel.MaxLineWidth512 * 8;

      Logger.Debug('GraphicWidth = ' + IntToStr(PrintWidth));

      Image := TImage.Create(nil);
      try
        SaveCenterImage := CenterImage;
        CenterImage := False;
        BarcodeHelper.Draw2DBarcode(Barcode, GetZintBarcodetype(True), Image, BarWidth, PrintWidth, BarcodeAlignment, LineNumber);

        if PrinterModel.CapGraphics512 then
          Result := LoadBlockGraphics512(Image, FirstLineNumber)
        else if PrinterModel.CapLoadBlockGraphics then
          Result := LoadBlockGraphics(Image, FirstLineNumber)
        else
          Result := LoadGraphics(Image, FirstLineNumber);
        LastLineNumber := Image.Picture.Bitmap.Height + FirstLineNumber - 1;
        // + PrinterModel.FirstDrawLine - 1;
      finally
        LineNumber := SaveLineNumber;
        CenterImage := SaveCenterImage;
      end;
    finally
      Image.Free;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetBlockData512(Image: TImage; BufType, FirstLine, LinesCount: Integer; var IsEnd: Boolean; var RealLinesCount: Integer): AnsiString;
var
  i: Integer;
  LastLine: Integer;
begin
  Result := '';
  IsEnd := False;
  if (FirstLine + LinesCount - 1) >= Image.Picture.Bitmap.Height then
  begin
    IsEnd := True;
    LastLine := Image.Picture.Bitmap.Height;
  end else
    LastLine := FirstLine + LinesCount - 1;
  RealLinesCount := LastLine - FirstLine + 1;
  for i := FirstLine to LastLine do
  begin
    Result := Result + GetLineData512(Image, i - 1, BufType, True);
  end;
end;

function TFiscalPrinter.GetLineData512(Image: TImage; Index, BufType: Integer; CutLine: Boolean): AnsiString;
const
  Bits: array[0..7] of Byte = (1, 2, 4, 8, $10, $20, $40, $80);
var
  Data: Byte;
  i, j: Integer;
  ImageWidth: Integer;
  LineLength: Integer;
  ImageWidthBytes: Integer;
begin
  if BufType = 0 then
    LineLength := 39
  else
    LineLength := 63;
  if CutLine then
  begin
    ImageWidthBytes := Ceil(Image.Picture.Width / 8) - 1;
    if ImageWidthBytes < LineLength then
      LineLength := ImageWidthBytes;
  end;
  Result := '';
  ImageWidth := Image.Picture.Width;
  for i := 0 to LineLength do
  begin
    Data := 0;
    for j := 0 to 7 do
    begin
      if (8 * i + j) <= ImageWidth then
      begin
        if (Image.Canvas.Pixels[8 * i + j, Index] = clBlack) or (Image.Canvas.Pixels[8 * i + j, Index] = 0) then
          Data := Data + Bits[j];
      end;
    end;
    Result := Result + AnsiChar(Data);
  end;
end;

function TFiscalPrinter.MaxImageWidth: Integer;
begin
  if PrinterModel.CapGraphics512 then
    Result := PrinterModel.MaxLineWidth512 * 8
  else
    Result := PrinterModel.MaxLineWidth * 8;
  // if Result = 0 then Result := 320;
end;

{
  Согласование ключа.
  Сервисная команда:
  #define SERVICE_CMD_1_DIR_SCANNER_KEY_AGREEMENT  0x0C
  FE 0C <16 байт ключ сканера>.
  Возвращает 1 байт – длину данных QR-кода согласования ключа. Сами данные не возвращаются, а помещаются в Фре в буфер данных штрихкодов начиная с блока 0. Далее необходимо подать командой печать QR-кода начиная с блока 0 и длиной сколько вернула команда.
  Успешное выполнение команды означает что ФР сгенерировал новый ключ вычисления имитоставки и сохранил его в энергонезависимом хранилище.
}
function TFiscalPrinter.MCScannerKeyAgreement: Integer;
begin
  Logger.Debug('MCScannerKeyAgreement');
  FECode := $0C;
  Result := Send(#$FE#$0C + HexToStr(MCScannerKeyHex));
end;

function TFiscalPrinter.MCScannerReadDeviceStatus: Integer;
var
  Scanner: TVMCScanner;
  Info: TVMCDeviceInfoRec;
begin
  Logger.Debug('MCScannerReadDeviceStatus');
  Result := ClearResult;
  try
    Scanner := TVMCScanner.Create(MCScannerComNumber);
    try
      Info := Scanner.GetDeviceInfo;
      MCScannerFirmwareVersion := Info.FirmwareVer;
      MCScannerHardwareVersion := Info.HardwareVer;
      MCScannerDeviceType := Info.DeviceType;
    finally
      Scanner.Free;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MCScannerReadKey: Integer;
var
  Scanner: TVMCScanner;
begin
  Logger.Debug('MCScannerReadKey');
  Result := ClearResult;
  try
    Scanner := TVMCScanner.Create(MCScannerComNumber);
    try
      MCScannerKeyHex := BytesToHex(Scanner.ReadKey);
    finally
      Scanner.Free;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MCScannerSearchDevice: Integer;
var
  Search: TSearchScanner;
begin
  Logger.Debug('MCScannerSearchDevice');
  Result := ClearResult;
  try
    Search := TSearchScanner.Create;
    try
      if not Search.Search then
        RaiseError(E_NOHARDWARE, GetRes(@SDriverNoHardware))
      else
      begin
        MCScannerComNumber := Search.ComNumber;
        MCScannerDeviceType := Search.DeviceInfo.DeviceType;
        MCScannerFirmwareVersion := Search.DeviceInfo.FirmwareVer;
        MCScannerHardwareVersion := Search.DeviceInfo.HardwareVer;
        MCScannerDeviceName := Search.DeviceInfo.DeviceName;
      end;
    finally
      Search.Free;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.MCScannerSendMCStatus: Integer;
var
  Scanner: TVMCScanner;
begin
  Logger.Debug('MCScannerSendMCStatus ' + MCScannerStatusHex);
  Result := ClearResult;
  try
    Scanner := TVMCScanner.Create(MCScannerComNumber);
    try
      Scanner.SendMCStatus(HexToBytes(MCScannerStatusHex));
    finally
      Scanner.Free;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{
  Запрос статуса проверки (для сканера) последнего КМ:
  Сервисная команда:
  #define SERVICE_CMD_1_DIR_GET_LAST_KM_STATUS     0x0B
  FE 0B 00 00 00 00
  Возвращает блок данных длиной 1+32+16 (результат проверки + хэш КМ + имитовставка), который надо передать в сканер. Команда работает только если ключ вычисления имитовставки был ранее согласован со сканером.
}
function TFiscalPrinter.MCScannerGetLastMCStatus: Integer;
begin
  Logger.Debug('MCScannerGetLastMCStatus');
  FECode := $0B;
  Result := Send(#$FE#$0B#$00#$00#$00#$00);
end;

function TFiscalPrinter.FNGetExpirationTime: Integer;
begin
  Result := Send(#$FF#$03 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF03(const Data: AnsiString);
var
  y, m, d: Integer;
begin
  CheckMinLength(Data, 5);
  y := Ord(Data[1]);
  m := Ord(Data[2]);
  d := Ord(Data[3]);
  try
    ECRDate := EncodeDate(y + 2000, m, d);
  except
    Date := EncodeDate(1970, 1, 1);
  end;
  FreeRegistration := Ord(Data[4]);
  RegistrationNumber := Ord(Data[5]);
end;

function TFiscalPrinter.FNGetSerial: Integer;
begin
  Result := Send(#$FF#$02 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF02(const Data: AnsiString);
begin
  CheckMinLength(Data, 16);
  SerialNumber := Copy(Data, 1, 16);
end;

function TFiscalPrinter.FNGetStatus: Integer;
begin
  Result := Send(#$FF#$01 + FPassw);
end;

function TFiscalPrinter.FNGetVersion: Integer;
begin
  Result := Send(#$FF#$04 + FPassw);
end;

function TFiscalPrinter.FNBeginFiscalization: Integer;
begin
  Result := 0; // !!!
end;

function TFiscalPrinter.FNFiscalization: Integer;
begin
  Result := 0; // !!!
end;

function TFiscalPrinter.FNCancelDocument: Integer;
begin
  Result := Send(#$FF#$08 + FPassw);
end;

function TFiscalPrinter.FNResetState: Integer;
begin
  Result := Send(#$FF#$07 + FPassw + AnsiChar(RequestType));
end;

function TFiscalPrinter.FNGetFiscalizationResult: Integer;
begin
  Result := Send(#$FF#$09 + FPassw);
end;

function TFiscalPrinter.FNGetFiscalizationResult2: Integer;
begin
  Logger.Debug('FNGetFiscalizationResult2');
  Result := SimpleSendCommand(#$FF#$09 + FPassw);
end;

function TFiscalPrinter.FNFindDocument: Integer;
var
  sDocNumber: Integer;
begin
  sDocNumber := DocumentNumber;
  GetSummFactor;
  DocumentNumber := sDocNumber;
  Result := Send(#$FF#$0A + FPassw + IntToBin(Cardinal(DocumentNumber), 4));
end;

function TFiscalPrinter.FNOpenSession: Integer;
begin
  Result := OpenSession; // Send(#$FF#$0B + FPassw);
end;

function TFiscalPrinter.FNSendTLV: Integer;
begin
  try
    if (Length(TLVData) > 249) and (ProtocolType = 0) then
    begin
      Check(LoadBarcodeData(1, TLVData));
      Result := Send(#$FF#$64 + FPassw);
    end else
      Result := Send(#$FF#$0C + FPassw + TLVData);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.Lock;
begin
  Logger.Debug('Lock');
  FLock.Enter;
end;

procedure TFiscalPrinter.Unlock;
begin
  Logger.Debug('Unlock');
  FLock.Leave;
end;

function TFiscalPrinter.FNDiscountOperation: Integer;
var
  TaxByte: Byte;
begin
  Result := SafeOpenSession;
  if Result <> 0 then
    Exit;

  TaxByte := TaxToFiscalPrinterTax(GetTax1);

  try
    UpdateStringForPrinting;
    Result := Send(#$FF#$0D + FPassw + AnsiChar(GetCheckType) + GetQuantity +
      // Количество
      GetPrice + // Цена
      GetDiscountValue + // Скидка
      GetChargeValue + // Надбавка
      AnsiChar(GetDepartment) + AnsiChar(TaxByte) + GetBarcodeInt + GetPrintString + #$0 + DiscountName + #$0);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNDiscountTaxOperation: Integer;
var
  TaxByte: Byte;
begin
  Result := SafeOpenSession;
  if Result <> 0 then
    Exit;

  TaxByte := TaxToFiscalPrinterTax(GetTax1);

  try
    Result := Send(#$FF#$44 + FPassw + AnsiChar(GetCheckType) + GetQuantity +
      // Количество
      GetPrice + // Цена
      GetDiscountValue + // Скидка
      GetChargeValue + // Надбавка
      GetTaxValue + // Налог
      AnsiChar(GetDepartment) + AnsiChar(TaxByte) + GetBarcodeInt + GetStr(GetPrintString, 215, 215));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FormatStrZero(const S: WideString; MinLen: Integer): WideString;
var
  StrLen: Integer;
begin
  StrLen := Length(S);
  if StrLen < MinLen then
    Result := S + StringOfChar(#0, MinLen - StrLen)
  else
    Result := Copy(S, 1, MinLen);
end;

function TFiscalPrinter.FNStorno: Integer;
{ var
  TaxByte: Byte; }
begin
  Result := NotSupported;
  { TaxByte := 0;
    SetTaxBit(TaxByte, Byte(GetTax1));

    Result := Send(#$FF#$0E +
    FPassw +
    AnsiChar(GetCheckType) +
    GetQuantity +  // Количество
    GetPrice +  // Цена
    GetSumm1 + // Скидка
    GetSumm2 + // Надбавка
    AnsiChar(GetDepartment) +
    AnsiChar(TaxByte) +
    FormatStrZero(Barcode, 16) +
    GetStr(GetPrintString, 64, 64)); }
end;

function TFiscalPrinter.FNGetBufferData: Integer;
begin
  Result := Send(#$FF#$30 + FPassw);

end;

function TFiscalPrinter.FNReadBufferDataBlock: Integer;
begin
  Result := Send(#$FF#$31 + FPassw + IntToBin(DataBlockNumber, 2) + IntToBin(DataLength, 1));
end;

function TFiscalPrinter.FNStartWriteBufferData: Integer;
begin
  Result := Send(#$FF#$32 + FPassw + IntToBin(DataLength, 2));
end;

function TFiscalPrinter.FNWriteBufferDataBlock: Integer;
begin
  Result := Send(#$FF#$33 + FPassw + IntToBin(DataBlockNumber, 2) + IntToBin(DataLength, 1) + DataBlock);
end;

procedure TFiscalPrinter.DecodeFF30(const Data: AnsiString);
begin
  CheckMinLength(Data, 3);
  DataLength := BinToInt(Data, 1, 2);
  DataBlockSize := BinToInt(Data, 3, 1);
end;

procedure TFiscalPrinter.DecodeFF31(const Data: AnsiString);
begin
  DataBlock := Data;
end;

procedure TFiscalPrinter.DecodeFF32(const Data: AnsiString);
begin
  CheckMinLength(Data, 1);
  DataBlockSize := BinToInt(Data, 1, 1);
end;

function TFiscalPrinter.OFDExchange: Integer;
var
  Data: AnsiString;
  Server: string;
  Port: Integer;
begin
  Result := 0;
  if ConnectionType = 1 then
  begin
    // Logger.Debug('TCP Server Connection... Exit');
    Exit;
  end;

  Logger.Debug('OFDExchange.begin');
  if OFDNeedCancel then
    Exit;
  try
    Result := ClearResult;
    try
      Logger.Debug('OFDexchange Lock');
      Lock;
      try
        if ConnectionType in [1, 2] then
        begin
          FDriver := nil; // DCOM, must be created in thread;
          // Logger.Debug('FDriver = nil');
        end;
        FPrinterDevice.SysAdminPassword := SysAdminPassword;
        FPrinterDevice.ReadOFDParams(Server, Port);
        if FPrinterDevice.ReadOFDData(Data) <> 0 then
          Exit;
      finally
        Logger.Debug('OFDexchange UnLock');
        try
          if ConnectionType in [1, 2] then
          begin
            FDriver := nil; // Disconnect;
            // Logger.Debug('FDriver = nil');
          end;
        finally
          Unlock;
        end;
      end;
      if OFDNeedCancel then
        Exit;
      if Length(Data) = 0 then
        Exit;
      Data := OFDSendData(Data, Server, Port);
      if OFDNeedCancel then
        Exit;
      if Length(Data) > 0 then
      begin
        Logger.Debug('OFDexchange Lock');
        Lock;
        try
          if ConnectionType in [1, 2] then
          begin
            FDriver := nil; // Disconnect;
            // Logger.Debug('FDriver = nil');
          end;
          FPrinterDevice.SysAdminPassword := SysAdminPassword;
          FPrinterDevice.WriteOFDData(Data);
        finally
          Logger.Debug('OFDexchange UnLock');
          if ConnectionType in [1, 2] then
          begin
            FDriver := nil; // Disconnect;
            // Logger.Debug('FDriver = nil');
          end;
          Unlock;
        end;
      end else
        Logger.Error('OFD Data length = 0');
    except
      on E: Exception do
        Logger.Error('OFDExchange: ' + E.Message);
    end;
  finally

    Logger.Debug('OFDExchange.end');
  end;
end;

function TFiscalPrinter.ICSReset: Integer;
var
  NeedReset: Boolean;
begin
  Result := 0;
  NeedReset := False;
  if not ICSEnabled then
    Exit;
  Logger.Debug('ICSReset.begin');

  try
    Lock;
    Result := ClearResult;
    try
      if FNGetInfoExchangeStatus = 0 then
      begin
        Logger.Debug('ICS LastDocNumber: ' + IntToStr(DocumentNumber));
        Logger.Debug('ICS Prev LastDocNumber: ' + IntToStr(FLastOFDDocNumber));
        if FLastOFDDocNumber < 0 then
        begin
          FLastOFDDocNumber := DocumentNumber;
          Exit;
        end;
        NeedReset := (FLastOFDDocNumber = DocumentNumber) and (DocumentNumber <> 0);
      end;
    finally
      Unlock;
    end;
    if NeedReset then
      DoICSReset;
  except
    on E: Exception do
      Logger.Error('ICSError: ' + E.Message);
  end;
end;

function TFiscalPrinter.ReadOFDData: AnsiString;
var
  TotalLength: Integer;
  BlockSize: Integer;
  BlockCount: Integer;
  i: Integer;
begin
  Result := '';
  Check(FNGetBufferData);
  if DataLength = 0 then
    Exit;
  if DataBlockSize = 0 then
    Exit;
  TotalLength := DataLength;
  BlockSize := DataBlockSize;
  BlockCount := Ceil(TotalLength / BlockSize);
  Logger.Debug('Length: ' + IntToStr(TotalLength));
  Logger.Debug('BlockSize: ' + IntToStr(BlockSize));
  Logger.Debug('BlockCount: ' + IntToStr(BlockCount));
  for i := 0 to BlockCount - 1 do
  begin
    DataBlockNumber := i * BlockSize;
    Logger.Debug('ReadOffset: ' + IntToStr(DataBlockNumber));
    if (TotalLength - DataBlockNumber) > BlockSize then
      DataLength := BlockSize
    else
      DataLength := (TotalLength - DataBlockNumber);

    Check(FNReadBufferDataBlock);
    Result := Result + DataBlock;
  end;
  Logger.Debug('FN Read: ' + StrToHex(Result));
end;

procedure TFiscalPrinter.WriteOFDData(const Data: AnsiString);
var
  TotalLength: Integer;
  BlockSize: Integer;
  BlockCount: Integer;
  i: Integer;
begin
  Logger.Debug('FN Write: ' + StrToHex(Data));
  DataLength := Length(Data);
  Check(FNStartWriteBufferData);
  BlockSize := DataBlockSize;
  if BlockSize = 0 then
    Exit;
  TotalLength := DataLength;
  BlockCount := Ceil(TotalLength / BlockSize);
  Logger.Debug('Length: ' + IntToStr(TotalLength));
  Logger.Debug('BlockSize: ' + IntToStr(BlockSize));
  Logger.Debug('BlockCount: ' + IntToStr(BlockCount));
  for i := 0 to BlockCount - 1 do
  begin
    DataBlockNumber := i * BlockSize;
    Logger.Debug('WriteOffset: ' + IntToStr(DataBlockNumber));
    DataBlock := Copy(Data, DataBlockNumber + 1, DataBlockSize);
    DataLength := Length(DataBlock);
    Check(FNWriteBufferDataBlock);
  end;
end;

function TFiscalPrinter.OFDSendData(const Data: AnsiString; const AServer: AnsiString; APort: Integer): AnsiString;
var
  Client: TOFDClient;
begin
  Client := TOFDClient.Create;
  try
    Client.Server := AServer;
    Client.Port := APort;
    Client.Timeout := OFDReadTimeout;
    Client.CheckCancelProc := OFDNeedCancel;
    Result := Client.SendData(Data);
  finally
    Client.Free;
  end;
end;

procedure TFiscalPrinter.OFDThreadProc(Sender: TObject);
begin
  // if TestMode then Exit;
  try
    try
      CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
      try
        while not OFDNeedCancel do
        begin
          OFDExchange;
          OFDDelay(OFDPollPeriod * 1000);
        end;
      finally
        CoUninitialize;
      end;
    except
      on E: Exception do
        Logger.Error('OFD Thread error: ' + E.Message);
    end;
  finally
    FOFDStarted := False;
    FOFDStopFlag := False;
  end;
end;

{ procedure TFiscalPrinter.ICSThreadProc(Sender: TObject);
  var
  sPass: Integer;
  begin
  if TestMode then Exit;
  CoInitialize(nil);
  while not FICSStopFlag do
  begin
  sPass := Password;
  Password := SysAdminPassword;
  try
  ICSReset;
  finally
  Password := sPass;
  end;
  ICSDelay(ICSPollPeriod * 1000 * 60);
  end;

  end; }

procedure TFiscalPrinter.OFDDelay(Timeout: Integer);
var
  TickCount: Integer;
begin
  TickCount := GetTickCount;
  while True do
  begin
    if OFDNeedCancel then
      Break;
    if Integer(GetTickCount) > (TickCount + Timeout) then
      Break;
    Sleep(50);
  end;
end;

{ procedure TFiscalPrinter.ICSDelay(Timeout: Integer);
  var
  TickCount: Integer;
  begin
  TickCount := GetTickCount;
  while True do
  begin
  if FICSStopFlag then
  Break;
  if Integer(GetTickCount) > (TickCount + Timeout) then
  Break;
  Sleep(50);
  end;
  end; }

procedure TFiscalPrinter.OFDStartPoll;
begin
  if OFDNeedCancel then
    Exit;
  if FOFDStarted then
    Exit;
  Logger.Debug('OFDStartPoll');
  FOFDStarted := True;
  FOFDStopFlag := False;
  FOFDThread := TNotifyThread.Create(True);
  FOFDThread.OnExecute := OFDThreadProc;
  FOFDThread.Resume;
end;

procedure TFiscalPrinter.OFDStopPoll;
begin
  if not FOFDStarted then
    Exit;
  Logger.Debug('OFDStopPoll');
  FOFDStopFlag := True;
  FOFDThread.WaitFor;
  FOFDThread.Free;
  FOFDThread := nil;
  FOFDStarted := False;
end;

{ procedure TFiscalPrinter.ICSStartPoll;
  begin
  FLastOFDDocNumber := -1;
  FICSStopFlag := False;
  FICSThread := TNotifyThread.Create(True);
  FICSThread.OnExecute := ICSThreadProc;
  FICSThread.Resume;
  end;

  procedure TFiscalPrinter.ICSStopPoll;
  begin
  FICSStopFlag := True;
  FICSThread.Free;
  FICSThread := nil;
  end; }

{ Начать формирование отчёта о состоянии расчётов FF37H
  Код команды FF37h . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF37h Длина сообщения: 1 байт.
  "	Код ошибки: 1 байт }
function TFiscalPrinter.FNBeginCalculationStateReport: Integer;
begin
  Result := Send(#$FF#$37 + FPassw);
end;

{
  Закрыть фискальный режим FF3EH
  Код команды FF3Eh . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF3Eh Длина сообщения: 9 байт.
  "	Код ошибки: 1 байт
  "	Номер ФД : 4 байта
  "	Фискальный признак: 4 байта
}
function TFiscalPrinter.FNCloseFiscalMode: Integer;
begin
  Result := SendAuth(#$FF#$3E + FPassw);
end;

procedure TFiscalPrinter.DecodeFF3E(const Data: AnsiString);
begin
  CheckMinLength(Data, 8);
  DocumentNumber := BinToInt(Data, 1, 4);
  FiscalSign := BinToInt(Data, 5, 4);
end;

{
  Начать закрытие смены FF42H
  Код команды FF42h . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF42h Длина сообщения: 1 байт.
  "	Код ошибки: 1 байт
}
function TFiscalPrinter.FNBeginCloseSession: Integer;
begin
  Result := Send(#$FF#$42 + FPassw);
end;

{ Начать формирование чека коррекции FF35H
  Код команды FF35h . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF35h Длина сообщения: 1 байт.
  "	Код ошибки: 1 байт }
function TFiscalPrinter.FNBeginCorrectionReceipt: Integer;
begin
  Result := SafeOpenSession;
  if Result <> 0 then
    Exit;
  Result := Send(#$FF#$35 + FPassw);
end;

{ Начать открытие смены FF41H
  Код команды FF41h . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF41h Длина сообщения: 1 байт.
  "	Код ошибки: 1 байт }
function TFiscalPrinter.FNBeginOpenSession: Integer;
begin
  Result := Send(#$FF#$41 + FPassw);
end;

{ Начать отчет о регистрации ККТ FF05H
  Код команды FF05h. Длина сообщения: 7 байт.
  "	Пароль системного администратора: 4 байта
  "	Тип отчета: 1 байт
  00 - Отчет о регистрации КТТ
  01 - Отчет  об  изменении параметров регистрации ККТ, в связи с заменой ФН
  02 - Отчет  об  изменении параметров регистрации ККТ без замены ФН

  Ответ:	    FF05h Длина сообщения: 1 байт.
  "	Код ошибки: 1 байт }
function TFiscalPrinter.FNBeginRegistrationReport: Integer;
begin
  Result := Send(#$FF#$05 + FPassw + AnsiChar(ReportTypeInt));
end;

{
  Сформировать отчёт о состоянии расчётов FF38H
  Код команды FF38h . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF38h Длина сообщения: 16 байт.
  "	Код ошибки: 1 байт
  "	Номер ФД: 4 байта
  "	Фискальный признак: 4 байта
  "	Количество неподтверждённых документов: 4 байта
  "	Дата первого неподтверждённого документа: 3 байта ГГ,ММ,ДД
}
function TFiscalPrinter.FNBuildCalculationStateReport: Integer;
begin
  Result := Send(#$FF#$38 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF38(const Data: AnsiString);
var
  y, m, d: Integer;
begin
  CheckMinLength(Data, 15);
  DocumentNumber := BinToInt(Data, 1, 4);
  FiscalSign := BinToInt(Data, 5, 4);
  DocumentCount := BinToInt(Data, 9, 4);
  y := Ord(Data[13]);
  m := Ord(Data[14]);
  d := Ord(Data[15]);
  try
    ECRDate := EncodeDate(y + 2000, m, d);
  except
    ECRDate := EncodeDate(1970, 1, 1);
  end;
end;

{ Сформировать чек коррекции FF36H
  Код команды FF36h . Длина сообщения: 11 байт.
  "	Пароль системного администратора: 4 байта
  "	Итог чека:  5 байт 0000000000…9999999999
  Ответ:	    FF36h Длина сообщения: 11 байт.
  "	Код ошибки: 1 байт
  "	Номер чека: 2 байта
  "	Номер ФД: 4 байта
  "	Фискальный признак: 4 байт }
function TFiscalPrinter.FNBuildCorrectionReceipt: Integer;
begin
  try
    Result := SafeOpenSession;
    if Result <> 0 then
      Exit;
    Result := SendAuth(#$FF#$36 + FPassw + GetSumm1 + AnsiChar(GetCheckType));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.DecodeFF36(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  ReceiptNumber := BinToInt(Data, 1, 2);
  DocumentNumber := BinToInt(Data, 3, 4);
  FiscalSign := BinToInt(Data, 7, 4)
end;

{ Сформировать чек коррекции V2 FF4AH
  Код команды FF4Ah . Длина сообщения: 210 байт.
  Пароль системного администратора: 4 байта
  Тип коррекции :1 байт  «0» - самостоятельно, «1» - по предписанию
  Признак расчета:1байт («1» (коррекция прихода, операция, при которой пользователь вносит денежные
  средства коррекции) и «3» (коррекция расхода, операция, при которой пользователь изымает денежные
  средства).
  Сумма расчёта :5 байт  Summ1
  Сумма по чеку наличными:5 байт Summ2
  Сумма по чеку электронными:5 байт  Summ3
  Сумма по чеку предоплатой:5 байт Summ4
  Сумма по чеку постоплатой:5 байт Summ5
  Сумма по чеку встречным представлением:5 байт Summ6
  Сумма НДС 18%:5 байт Summ7
  Сумма НДС 10%:5 байт Summ8
  Сумма расчёта по ставке 0%:5 байт Summ9
  Сумма расчёта по чеку без НДС:5 байт Summ10
  Сумма расчёта по расч. ставке 18/118:5 байт Summ11
  Сумма расчёта по расч. ставке 10/110:5 байт Summ12

  Ответ:	    FF36h Длина сообщения: 11 байт.
  Код ошибки: 1 байт
  Номер чека: 2 байта
  Номер ФД: 4 байта
  Фискальный признак: 4 байт
}

function TFiscalPrinter.FNBuildCorrectionReceipt2: Integer;
begin
  try
    Result := SafeOpenSession;
    if Result <> 0 then
      Exit;
    Result := SendAuth(#$FF#$4A + FPassw + AnsiChar(CorrectionType) + AnsiChar(CalculationSign) + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetSumm5 + GetSumm6 + GetSumm7 + GetSumm8 + GetSumm9 + GetSumm10 + GetSumm11 + GetSumm12 + AnsiChar(TaxType));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.DecodeFF4A(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  ReceiptNumber := BinToInt(Data, 1, 2);
  DocumentNumber := BinToInt(Data, 3, 4);
  FiscalSign := BinToInt(Data, 7, 4);
end;

{ Сформировать отчёт о регистрации ККТ FF06H
  Код команды FF06h . Длина сообщения: 40 байт.
  "	Пароль системного администратора: 4 байта
  "	ИНН : 12 байт ASCII
  "	Регистрационный номер ККТ: 20 байт ASCII
  "	Код налогообложения: 1 байт
  "	Режим работы: 1 байт
  Ответ:	    FF06h Длина сообщения: 9 байт.
  "	Код ошибки: 1 байт
  "	Номер ФД: 4 байта
  "	Фискальный признак: 4 байта }
function TFiscalPrinter.FNBuildRegistrationReport: Integer;
begin
  try
    GetINNAsStr;
    Result := SendAuth(#$FF#$06 + FPassw + AddFinalSpaces(INN, 12) + AddFinalSpaces(KKTRegistrationNumber, 20) + AnsiChar(TaxType) + AnsiChar(WorkMode));

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{ Сформировать отчёт о перерегистрации ККТ FF34H
  Код команды FF34h . Длина сообщения: 7 байт.
  "	Пароль системного администратора: 4 байта
  "	ИНН : 12 байт ASCII
  "	Регистрационный номер ККТ: 20 байт ASCII
  "	Код налогообложения: 1 байт
  "	Режим работы: 1 байт
  "	Код причины перерегистрации: 1 байт
}
function TFiscalPrinter.FNBuildReregistrationReport: Integer;
begin
  try
    GetINNAsStr;
    Result := SendAuth(#$FF#$34 + FPassw + AddFinalSpaces(INN, 12) + AddFinalSpaces(KKTRegistrationNumber, 20) +
      // GetKKTRegistrationNumberAsStr +
      AnsiChar(TaxType) + AnsiChar(WorkMode) + AnsiChar(RegistrationReasonCode));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.DecodeFF34(const Data: AnsiString);
begin
  CheckMinLength(Data, 8);
  DocumentNumber := BinToInt(Data, 1, 4);
  FiscalSign := BinToInt(Data, 5, 4)
end;

{ Начать закрытие фискального режима FF3DH
  Код команды FF3Dh . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF3Dh Длина сообщения: 1 байт.
  "	Код ошибки: 1 байт }
function TFiscalPrinter.FNBeginCloseFiscalMode: Integer;
begin
  Result := Send(#$FF#$3D + FPassw);
end;

{ Закрыть смену в ФН FF43H
  Код команды FF43h . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байт
  Ответ:    FF43h Длина сообщения: 11 байт.
  "	Код ошибки: 1 байт
  "	Номер только что закрытой смены: 2 байта
  "	Номер ФД :4 байта
  "	Фискальный признак: 4 байта }
function TFiscalPrinter.FNCloseSession: Integer;
begin
  Result := PrintReportWithCleaning; // Send(#$FF#$43 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF43(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  SessionNumber := BinToInt(Data, 1, 2);
  DocumentNumber := BinToInt(Data, 3, 4);
  FiscalSign := BinToInt(Data, 7, 4)
end;

{ Запрос параметров текущей смены FF40H
  Код команды FF40h . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF40h Длина сообщения: 6 байт.
  "	Код ошибки: 1 байт
  "	Состояние смены: 1 байт
  "	Номер смены : 2 байта
  "	Номер чека: 2 байта }
function TFiscalPrinter.FNGetCurrentSessionParams: Integer;
begin
  Result := Send(#$FF#$40 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF40(const Data: AnsiString);
begin
  CheckMinLength(Data, 5);
  FNSessionState := Ord(Data[1]);
  SessionNumber := BinToInt(Data, 2, 2);
  ReceiptNumber := BinToInt(Data, 4, 2);
end;

{ Получить статус информационного  обмена FF39H
  Код команды FF39h . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF39h Длина сообщения: 14 байт.
  "	Код ошибки: 1 байт
  "	Статус информационного обмена: 1 байт
  (0 - нет, 1 - да)
  Бит 0 - транспортное соединение установлено
  Бит 1 - есть сообщение для передачи в ОФД
  Бит 2 - ожидание ответного сообщения (квитанции) от ОФД
  Бит 3 - есть команда от ОФД
  Бит 4 - изменились настройки соединения с ОФД
  Бит 5 - ожидание ответа на команду от ОФД
  "	Состояние чтения сообщения: 1 байт 1 - да, 0 -нет
  "	Количество сообщений для ОФД: 2 байта
  "	Номер документа для ОФД первого в очереди: 4 байта
  "	Дата и время документа для ОФД первого в очереди: 5 байт }

function TFiscalPrinter.FNGetInfoExchangeStatus: Integer;
begin
  Result := Send(#$FF#$39 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF39(const Data: AnsiString);
var
  y, m, d, h, min: Integer;
begin
  CheckMinLength(Data, 13);
  InfoExchangeStatus := Ord(Data[1]);
  MessageState := Ord(Data[2]);
  MessageCount := BinToInt(Data, 3, 2);
  DocumentNumber := BinToInt(Data, 5, 4);
  y := Ord(Data[9]);
  m := Ord(Data[10]);
  d := Ord(Data[11]);
  h := Ord(Data[12]);
  min := Ord(Data[13]);
  try
    ECRDate := EncodeDate(y + 2000, m, d);
  except
    ECRDate := EncodeDate(1970, 1, 1);
  end;
  try
    ECRTime := EncodeTime(h, min, 0, 0);
  except
    ECRTime := EncodeTime(0, 0, 0, 0);
  end;
end;

{ Запрос квитанции о получении данных в ОФД по номеру  документа FF3CH
  Код команды FF3Сh . Длина сообщения: 11 байт.
  "	Пароль системного администратора: 4 байта
  "	Номер фискального документа: 4 байта
  Ответ:	    FF3Сh Длина сообщения: 1+N байт.
  "	Код ошибки: 1 байт
  "	Квитанция: N байт }
function TFiscalPrinter.FNGetOFDTicketByDocNumber: Integer;
begin
  Result := Send(#$FF#$3C + FPassw + IntToBin(DocumentNumber, 4));
end;

procedure TFiscalPrinter.DecodeFF3C(const Data: AnsiString);
begin
  DocumentData := Data;
  CheckMinLength(Data, 27);
  DecodeDataTime(Data);
  FiscalSignOFD := Copy(Data, 6, 18);
  DocumentNumber := BinToInt(Data, 24, 4);
end;

{ Запрос количества ФД на которые нет квитанции FF3FH
  Код команды FF3Fh . Длина сообщения: 6 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF3Fh Длина сообщения: 3 байт.
  "	Код ошибки: 1 байт
  "	Количество неподтверждённых ФД : 2 байта }
function TFiscalPrinter.FNGetUnconfirmedDocCount: Integer;
begin
  Result := Send(#$FF#$3F + FPassw);
end;

procedure TFiscalPrinter.DecodeFF3F(const Data: AnsiString);
begin
  CheckMinLength(Data, 2);
  DocumentCount := BinToInt(Data, 1, 2);
end;

{ Чтение TLV фискального документа FF3BH
  Код команды FF3Bh . Длина сообщения: 11 байт.
  "	Пароль системного администратора: 4 байта
  Ответ:	    FF3Bh Длина сообщения: 1+N байт.
  "	Код ошибки:1 байт
  "	TLV структура: N байт }
function TFiscalPrinter.FNReadFiscalDocumentTLV: Integer;
begin
  Result := Send(#$FF#$3B + FPassw);
end;

procedure TFiscalPrinter.DecodeFF3B(const Data: AnsiString);
begin
  TLVData := Data;
end;

{ Запросить фискальный документ в TLV формате FF3AH
  Код команды FF3Аh . Длина сообщения: 10 байт.
  "	Пароль системного администратора: 4 байта
  "	Номер фискального документа: 4 байта
  Ответ:	    FF3Аh Длина сообщения: 5 байт.
  "	Код ошибки: 1 байт
  "	Тип фискального документа: 2 байта STLV
  "	Длина фискального документа: 2 байта }
function TFiscalPrinter.FNRequestFiscalDocumentTLV: Integer;
begin
  Result := Send(#$FF#$3A + FPassw + IntToBin(DocumentNumber, 4));
end;

procedure TFiscalPrinter.DecodeFF3A(const Data: AnsiString);
begin
  CheckMinLength(Data, 4);
  DocumentType := BinToInt(Data, 1, 2);
  DataLength := BinToInt(Data, 3, 2);
end;

function TFiscalPrinter.GetBarcodeInt: AnsiString;
begin
  try
    Result := IntToBin(StrToInt64(Barcode), 5);
  except
    InvalidProp('Barcode');
  end;
end;

function TFiscalPrinter.FNCloseCheckEx: Integer;
var
  Command: AnsiString;
begin
  { ///!!!
    if not TestMode then
    begin
    Result := GetECRStatus;
    if Result <> 0 then Exit;
    end; }

  try
    Command := #$FF#$45 + FPassw + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetSumm5 + GetSumm6 + GetSumm7 + GetSumm8 + GetSumm9 + GetSumm10 + GetSumm11 + GetSumm12 + GetSumm13 + GetSumm14 + GetSumm15 + GetSumm16 + AnsiChar(RoundingSumm) + GetTaxValue1 + GetTaxValue2 + GetTaxValue3 + GetTaxValue4 + GetTaxValue5 + GetTaxValue6 + AnsiChar(TaxType) + Copy(GetPrintString, 1, 64);
    Result := SendAuth(Command);
    DrvCloseCheck;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.DecodeFF45(const Data: AnsiString);
begin
  CheckMinLength(Data, 13);
  Change := BinToAmount(Data, 1, 5);
  DocumentNumber := BinToInt(Data, 6, 4);
  FiscalSign := BinToInt(Data, 10, 4);
end;

function TFiscalPrinter.FNSendCustomerEmail: Integer;
var
  StrData: AnsiString;
  Req: Integer;
begin
  StrData := Copy(CustomerEmail, 1, 64);
  TLVData := TFormatTLV.Int2ValueTLV(1008, 2) + TFormatTLV.Int2ValueTLV(Length(StrData), 2) + TFormatTLV.ASCII2ValueTLV(StrData);
  Result := FNSendTLV;
  { if Result <> 0 then
    Exit;
    Result := ReadPrintUserRequisite(Req);
    if Result <> 0 then Exit;
    // Если не включена печать реквизита
    if not TestBit(Req, 4) then
    begin
    if Pos('@', StrData) > 0 then
    PrintText('ЭЛ.АДР.ПОКУПАТЕЛЯ:' + ' ' + StrData)
    else
    PrintText('ТЕЛ.ПОКУПАТЕЛЯ:' + ' ' + StrData)
    end; }
end;

function TFiscalPrinter.FNSendSenderEmail: Integer;
var
  StrData: AnsiString;
  Req: Integer;
begin
  StrData := Copy(EmailAddress, 1, 64);
  TLVData := TFormatTLV.Int2ValueTLV(1117, 2) + TFormatTLV.Int2ValueTLV(Length(StrData), 2) + TFormatTLV.ASCII2ValueTLV(StrData);
  Result := FNSendTLV;
  { if Result <> 0 then
    Exit;
    Result := ReadPrintUserRequisite(Req);
    if Result <> 0 then Exit;
    // Если не включена печать реквизита
    if not TestBit(Req, 3) then
    begin
    StringForPrinting := 'ЭЛ.АДР.ОТПРАВИТЕЛЯ:' + ' ' + StrData;
    Result := PrintStringWithWrap;
    end; }
end;

function TFiscalPrinter.Annulment: Integer;
begin
  Result := Send(#$55 + FPassw + IntToBin(DocumentNumber, 4) + GetSumm1RB);
end;

function TFiscalPrinter.AnnulmentRB: Integer;
begin
  Result := Send(#$56 + FPassw + IntToBin(DocumentNumber, 4) + GetSumm1RB + GetSumm2RB + GetSumm3RB + GetSumm4RB);
end;

function TFiscalPrinter.GetSumm1RB: AnsiString;
begin
  if (Summ1 < 0) then
    InvalidProp('Summ1');
  Result := AmountToBin(Summ1, 6);
end;

function TFiscalPrinter.GetSumm2RB: AnsiString;
begin
  if (Summ2 < 0) then
    InvalidProp('Summ2');
  Result := AmountToBin(Summ2, 6);
end;

function TFiscalPrinter.GetSumm3RB: AnsiString;
begin
  if (Summ3 < 0) then
    InvalidProp('Summ3');
  Result := AmountToBin(Summ3, 6);
end;

function TFiscalPrinter.GetSumm4RB: AnsiString;
begin
  if (Summ4 < 0) then
    InvalidProp('Summ4');
  Result := AmountToBin(Summ4, 6);
end;

procedure TFiscalPrinter.DecodeDataTime(const Data: AnsiString);
var
  y, m, d, h, min: Integer;
begin
  CheckMinLength(Data, 5);
  y := Ord(Data[1]);
  m := Ord(Data[2]);
  d := Ord(Data[3]);
  h := Ord(Data[4]);
  min := Ord(Data[5]);
  try
    ECRDate := EncodeDate(y + 2000, m, d);
  except
    ECRDate := EncodeDate(1970, 1, 1);
  end;
  try
    ECRTime := EncodeTime(h, min, 0, 0);
  except
    ECRTime := EncodeTime(0, 0, 0, 0);
  end;
end;

function TFiscalPrinter.SafeOpenSession: Integer;
begin
  Result := 0;
  if TestMode then
    Exit;
  if not AutoOpenSession then
    Exit;
  Result := GetShortECRStatus;
  if Result <> 0 then
    Exit;
  if ECRMode <> 4 then
    Exit;
  Logger.Debug('Автоматическое открытие смены по настройке');
  Result := OpenSession;
  if Result = $37 then // Игнорируем если не поддерживается
    Result := 0
  else if Result = 0 then
    WaitForPrinting;
end;
{
  Скидка, надбавка  на чек для Роснефти FF4BH
  Код команды FF4Bh . Длина сообщения:  145 байт.
  •	Пароль системного администратора: 4 байта
  •	Скидка:         5 байт
  •	Надбавка:    5 байт
  •	Налог:  1 байт
  •	Описание скидки или надбавки: 128 байт ASCII
  Ответ:    FF4Bh Длина сообщения: 1 байт.
  •	Код ошибки: 1 байт }

function TFiscalPrinter.FNDiscountChargeRN: Integer;
var
  TaxByte: Byte;
begin
  TaxByte := TaxToFiscalPrinterTax(GetTax1);
  try
    Result := Send(#$FF#$4B + FPassw + GetDiscountValue + // Скидка
      GetChargeValue + // Надбавка
      AnsiChar(TaxByte) + Copy(GetPrintString, 1, 128));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ExportTables: Integer;
begin
  try
    Result := DoExportTables;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ImportTables: Integer;
begin
  try
    Result := DoImportTables;
  except
    on E: Exception do
      Result := HandleException(E);
  end;

end;

function TFiscalPrinter.DoExportTables: Integer;
var
  Tables: TPrinterTables;
  TableRec: TPrinterTableRec;
  Res: Integer;
  Field: TField;
  Fields: TFields;
  FieldRec: TFieldRec;
  RowN: Integer;
  FieldN: Integer;
  Writer: TCsvPrinterTableFormat;
  Table: TPrinterTable;
  i: Integer;
begin
  Result := ClearResult;
  Tables := TPrinterTables.Create;

  // Чтение структуры таблиц
  try
    Tables.Clear;
    TableRec.Number := 1;
    repeat
      TableNumber := TableRec.Number;
      Res := GetTableStruct;
      case ResultCode of
        0:
          begin
            TableRec.Name := GetTableName(TableName);
            TableRec.RowCount := RowNumber;
            TableRec.Fieldcount := FieldNumber;

            TPrinterTable.Create(Tables, TableRec);
            Inc(TableRec.Number);
          end;
        93:
          Break;
      else
        begin
          Result := Res;
          Exit;
        end;
      end;
    until False;

    for i := 0 to Tables.Count - 1 do
    begin
      Table := Tables[i];

      // Чтение полей
      RowN := 1;
      FieldN := 1;
      Fields := Table.Fields;
      Fields.Clear;
      repeat
        RowNumber := RowN;
        FieldNumber := FieldN;
        TableNumber := Table.Number;
        Logger.Debug(Format('ReadTable %d %d %d', [TableNumber, RowNumber, FieldNumber]));
        Res := ReadTable;
        if Res = 0 then
        begin
          // Создание поля
          FieldRec.Row := RowN;
          FieldRec.Number := FieldN;
          FieldRec.Table := Table.Number;
          FieldRec.Name := GetTableName(FieldName);
          FieldRec.Size := FieldSize;
          FieldRec.FieldType := BoolFieldTypeToInt[FieldType];
          FieldRec.MinValue := MinValueOfField;
          FieldRec.MaxValue := MaxValueOfField;

          Field := TField.Create(Fields, FieldRec);
          Field.Value := ValueOfFieldString;

          Inc(RowN);
          if RowN > Table.RowCount then
          begin
            RowN := 1;
            Inc(FieldN);
          end;
        end else
        begin
          Result := Res;
          Exit;
        end;
      until FieldN > Table.Fieldcount;
    end;
    // Запись таблиц
    Writer := TCsvPrinterTableFormat.Create(nil);
    try
      Writer.SaveToFile(FileName, Tables);
    finally
      Writer.Free;
    end;
  finally
    Tables.Free;
  end;
end;

function TFiscalPrinter.WriteFields(Table: TPrinterTable): Integer;
var
  Field: TField;
  Index: Integer;
  Fields: TFields;
  Res: Integer;
  ResultDescr: WideString;
  OldValue: WideString;
resourcestring
  SReadError = 'Ошибка чтения';
begin
  Result := 0;
  Fields := Table.Fields;
  if Fields.Count = 0 then
    Exit;
  Index := 0;
  repeat
    Field := Fields[Index];
    TableNumber := Field.Table;
    RowNumber := Field.Row;
    FieldNumber := Field.Number;
    // Читаем
    ResultCode := ReadTable;
    if ResultCode = 0 then
      OldValue := ValueOfFieldString;
    if ResultCode > 0 then
      OldValue := Format('%s %d %s', [SReadError, ResultCode, ResultCodeDescription]);
    if ResultCode < 0 then
    begin
      Result := ResultCode;
      Exit;
    end;

    // Сравниваем - если отличаются, то записываем
    if OldValue = Field.Value then
    begin
      Inc(Index);
      Continue;
    end;
    ValueOfFieldString := Field.Value;
    Logger.Debug(Format('WriteTable %d, %d, %d, %d, %s', [TableNumber, RowNumber, FieldNumber, ValueOfFieldInteger, ValueOfFieldString]));
    Res := WriteTable;
    // Ошибки > 0 при записи игнорируются
    if Res <> -1 then
    begin
      Logger.Error('Error writing table ' + IntToStr(Res) + ', ' + ResultCodeDescription);
      ResultDescr := ResultCodeDescription;
      Inc(Index);
    end else
    begin
      Exit;
    end;
  until Index = Fields.Count;
end;

function TFiscalPrinter.DoImportTables: Integer;
var
  Reader: TCsvPrinterTableFormat;
  Tables: TPrinterTables;
  TableRec: TPrinterTableRec;
  Res: Integer;
  i: Integer;
begin
  Result := ClearResult;
  Reader := TCsvPrinterTableFormat.Create(nil);
  Tables := TPrinterTables.Create;
  // Чтение структуры таблиц
  try
    Tables.Clear;
    TableRec.Number := 1;
    repeat
      TableNumber := TableRec.Number;
      Res := GetTableStruct;
      case ResultCode of
        0:
          begin
            TableRec.Name := GetTableName(TableName);
            TableRec.RowCount := RowNumber;
            TableRec.Fieldcount := FieldNumber;

            TPrinterTable.Create(Tables, TableRec);
            Inc(TableRec.Number);
          end;
        93:
          Break;
      else
        begin
          Result := Res;
          Exit;
        end;
      end;
    until False;
    Logger.Debug('Import tables from ' + FileName);
    Reader.LoadFromFile(FileName, Tables);
    Logger.Debug('Tables count = ' + IntToStr(Tables.Count));
    for i := 0 to Tables.Count - 1 do
    begin
      if Tables[i].Selected then
        WriteFields(Tables[i]);
    end;
  finally
    Tables.Free;
    Reader.Free;
  end;
end;

function TFiscalPrinter.FNSendAutomatNumber(const ANumber: WideString): Integer;
var
  StrData: AnsiString;
begin
  Logger.Debug('Send TAG AutomatNumber ' + ANumber);
  StrData := Copy(ANumber, 1, 20);
  TLVData := TFormatTLV.Int2ValueTLV(1036, 2) + TFormatTLV.Int2ValueTLV(Length(StrData), 2) + TFormatTLV.ASCII2ValueTLV(StrData);
  Result := FNSendTLV;
end;

function AgentToStr(AAgent: Integer): AnsiString;
var
  S: TStringList;
  i: Integer;
begin
  S := TStringList.Create;
  try
    if TestBit(AAgent, 0) then
      S.Add('БАНК. ПЛ. АГЕНТ');
    if TestBit(AAgent, 1) then
      S.Add('БАНК. ПЛ. СУБАГЕНТ');
    if TestBit(AAgent, 2) then
      S.Add('ПЛ. АГЕНТ');
    if TestBit(AAgent, 3) then
      S.Add('ПЛ. СУБАГЕНТ');
    if TestBit(AAgent, 4) then
      S.Add('ПОВЕРЕННЫЙ');
    if TestBit(AAgent, 5) then
      S.Add('КОМИССИОНЕР');
    if TestBit(AAgent, 6) then
      S.Add('АГЕНТ');

    Result := '';
    for i := 0 to S.Count - 1 do
    begin
      if i < S.Count - 1 then
        Result := Result + S[i] + ','
      else
        Result := Result + S[i];
    end;
  finally
    S.Free;
  end;
end;

function TFiscalPrinter.FNSendTag: Integer;
// var
// Tag: TTLVTag;
begin
  Result := FNCustomSendTag(False);
  // Костыль для Почты России... Тег 1119 может быть включен только 1 раз,
  // но они хотят его передавать
  if (TagNumber = 1119) and (Result = 51) then
    Result := ClearResult;
  if Result <> 0 then
    Exit;
  { // Временное решение для Моделей семенова с агентскими тегами
    Tag := FTags.FindTag(TagNumber);
    if Tag = nil then Exit;
    if IsModelType2(PrinterModel.ModelID) then
    begin
    case TagNumber of
    1057: Result := PrintText(Tag.ShortDescription + ': ' +
    AgentToStr(TagValueInt));
    1075, 1044, 1073, 1074, 1026, 1005, 1016, 1171:
    Result := PrintText(Tag.ShortDescription + ': ' + TagValueStr);
    end;
    end; }
end;

function TFiscalPrinter.FNSendTagOperation: Integer;
begin
  Result := FNCustomSendTag(True);
end;

function TFiscalPrinter.FNCustomSendTag(AOperation: Boolean): Integer;
begin
  Result := GetTagAsTLV;
  if Result <> 0 then
    Exit;
  if AOperation then
    Result := FNSendTLVOperation
  else
    Result := FNSendTLV;
end;

function TFiscalPrinter.GetTagAsTLV: Integer;

  function IsTagFixedLength(var Len: Integer): Boolean;
  var
    Tag: TTLVTag;
  begin
    Tag := FTags.FindTag(TagNumber);
    if Tag = nil then
    begin
      Len := 0;
      Result := False;
      Exit;
    end;
    Result := Tag.FixedLength;
    Len := Tag.Info.TagLen;
  end;

var
  Len: Integer;
  sTagType: Integer;
  sTagValueLen: Integer;
begin
  try
    if (TagType = ttString) and (TagValueStr = '') then
    begin
      Result := ClearResult;
      Logger.Error('Tag value string is empty');
      InvalidProp('TagValueStr');
    end;

    sTagType := TagType;
    sTagValueLen := TagValueLength;
    FNGetTagDescription;
    TagType := sTagType;
    Result := ClearResult;

    case TagType of
      ttByte:
        TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(1, 2) + TFormatTLV.Int2ValueTLV(TagValueInt, 1);
      ttUint16:
        TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(2, 2) + TFormatTLV.Int2ValueTLV(TagValueInt, 2);
      ttUInt32:
        TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(4, 2) + TFormatTLV.Int2ValueTLV(TagValueInt, 4);
      ttVLN:
        TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(TagValueLength, 2) + TFormatTLV.VLN2ValueTLVLen(BinToInt(TagValueBin, 1, Length(TagValueBin)), TagValueLength);
      ttFVLN:
        TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(TagValueLength, 2) + TFormatTLV.FVLN2ValueTLVLen(TagValueFVLN, TagValueLength);
      ttFVLND:
        TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(TagValueLength, 2) + TFormatTLV.FVLND2ValueTLVLen(TagValueFVLND, TagValueLength);
      ttBitMask:
        TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(TagValueLength, 2) + TFormatTLV.Int2ValueTLV(BinToInt(TagValueBin, 1, TagValueLength), TagValueLength);
      ttUnixTime:
        TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(4, 2) + TFormatTLV.UnixTime2ValueTLV(TagValueDateTime);
      ttString:
        begin
          if IsTagFixedLength(Len) then
            TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(Len, 2) + TFormatTLV.ASCII2ValueTLV(AddFinalSpaces(TagValueStr, Len))
          else
            TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(Length(TagValueStr), 2) + TFormatTLV.ASCII2ValueTLV(TagValueStr);
        end;
      ttByteArray:
        begin
          TLVData := TFormatTLV.Int2ValueTLV(TagNumber, 2) + TFormatTLV.Int2ValueTLV(Length(TagValueBin), 2) + TagValueBin;
        end;
      ttSTLV:
        begin
          TLVData := FSTLVTag.GetTLV;
          FSTLVStarted := False;
        end;
    else
      InvalidProp('TagType');
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ReadSerialNumber: Integer;
begin
  try
    if PrinterModel.CapFN then
    begin
      TableNumber := PrinterModel.FSTableNumber;
      RowNumber := 1;
      FieldNumber := 1;
      Result := ReadTable;
      if Result = 0 then
        SerialNumber := ValueOfFieldString;
    end else
    begin
      Result := GetECRStatus;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNGetFiscalizationResultByNumber: Integer;
begin
  Result := Send(#$FF#$4C + FPassw + AnsiChar(Byte(RegistrationNumber)));
end;

{ - наименование документа "Подтверждение оператора"
  - ИНН ОФД
  - фискальный признак оператора (первые 8 байт массива шестнадцатиричных чисел)
  - номер ФН
  - номер ФД
  - дата, время }

function TFiscalPrinter.FNPrintOperatorConfirm: Integer;
var
  aINN: AnsiString;
  aFSSerial: AnsiString;
  aFSignOFD: AnsiString;
begin
  TableNumber := PrinterModel.FSTableNumber;
  RowNumber := 1;
  FieldNumber := 12;
  Result := ReadTable;
  if Result <> 0 then
    Exit;
  aINN := ValueOfFieldString;
  FieldNumber := 4;
  Result := ReadTable;
  if Result <> 0 then
    Exit;
  aFSSerial := ValueOfFieldString;

  Result := FNGetOFDTicketByDocNumber;
  if Result <> 0 then
    Exit;
  aFSignOFD := StrToHex(FiscalSignOFD);

  StringForPrinting := 'ПОДТВЕРЖДЕНИЕ';
  Result := PrintStringWithWrap;
  if Result <> 0 then
    Exit;

  StringForPrinting := 'ИНН ОФД: ' + aINN;
  Result := PrintStringWithWrap;
  if Result <> 0 then
    Exit;

  StringForPrinting := 'ФПО: ' + aFSignOFD;
  Result := PrintStringWithWrap;
  if Result <> 0 then
    Exit;

  StringForPrinting := 'ФН: ' + aFSSerial;
  Result := PrintStringWithWrap;
  if Result <> 0 then
    Exit;

  StringForPrinting := 'ФД: ' + IntToStr(DocumentNumber);
  Result := PrintStringWithWrap;
  if Result <> 0 then
    Exit;

  StringForPrinting := 'ДАТА: ' + DateTimeToStr(Date + Time);
  Result := PrintStringWithWrap;
  if Result <> 0 then
    Exit;
  FinishDocumentMode := 0;
  Result := FinishDocument;
end;

function TFiscalPrinter.FNGetTagDescription: Integer;
var
  Tag: TTLVTag;
begin
  Result := ClearResult;
  try
    Tag := FTags.FindTag(TagNumber);
    if Tag = nil then
      RaiseError(E_UNKNOWNTAG, GetRes(@SUnknownTag));
    TagType := Tag.TagType;
    TagDescription := Tag.Description;
    TagValueLength := Tag.Info.TagLen;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNPrintDocument: Integer;
var
  S: TStringList;
  i: Integer;
  sDelayedPrint: Boolean;
begin
  Result := FNGetDocumentAsString;
  if Result <> 0 then
    Exit;
  S := TStringList.Create;
  sDelayedPrint := DelayedPrint;
  try
    S.Text := StringForPrinting;
    for i := 0 to S.Count - 1 do
    begin
      DelayedPrint := False;
      StringForPrinting := S[i];
      Result := PrintStringWithWrap;
      if Result <> 0 then
        Exit;
    end;
    if Result <> 0 then
      Exit;
    DelayedPrint := True;
    FinishDocumentMode := fdmTrailerDisabled;
    Result := FinishDocument;
  finally
    DelayedPrint := sDelayedPrint;
    StringForPrinting := S.Text;
    S.Free;
  end;
end;

function TFiscalPrinter.FNGetDocumentAsString: Integer;
var
  Parser: TTLVParser;
  Data: AnsiString;
  TaxValue: AnsiString;
begin
  // Result := ClearResult;
  StringForPrinting := '';
  Data := '';
  try
    Result := FNFindDocument;
    if Result <> 0 then
      Exit;
    if ECRDate >= EncodeDate(2019, 1, 1) then
      TaxValue := '20'
    else
      TaxValue := '18';
    FLogger.Debug('TAX value = ' + TaxValue);

    Parser := TTLVParser.Create;
    try
      Parser.TaxValue := TaxValue;
      Parser.ShowTagNumbers := ShowTagNumber;
      if RequestDocumentType = rdtDocument then
        Result := FNRequestFiscalDocumentTLV
      else
      begin
        TagNumber := $FFFF;
        Result := FNRequestRegistrationTLV;
      end;
      if Result <> 0 then
        Exit;
      if RequestDocumentType = rdtDocument then
        StringForPrinting := TLVDocTypeToStr(DocumentType) + #13#10;

      while True do
      begin
        Result := FNReadFiscalDocumentTLV;
        if (Result = 8) then
        begin
          Result := ClearResult;
          Break;
        end else if Result <> 0 then
          Exit;
        if Length(TLVData) = 0 then
          Break;
        Data := Data + GetTLVDataHex;
      end;
      StringForPrinting := StringForPrinting + Parser.ParseTLVAsHex(Data);
    finally
      Parser.Free;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.Ping: Integer;
begin
  FECode := $F2;
  Result := Send(#$FE + #$F2 + URL);
end;

procedure TFiscalPrinter.DecodeFE(const Data: AnsiString);
var
  i: Integer;
begin
  case FECode of
    $0B:
      begin
        CheckMinLength(Data, 49);
        MCScannerStatusHex := StrToHex(Data);
        Logger.Debug('MCScannerStatus: ' + StrToHex(Data));
      end;
    $0C:
      begin
        CheckMinLength(Data, 1);
        BarcodeStartBlockNumber := 0;
        BarcodeDataLength := Ord(Data[1]);
        if BarcodeDataLength < 0 then
          BarcodeDataLength := 0;
      end;
    $09:
      begin
        CheckMinLength(Data, 32);
        FontHashHex := StrToHex(Data);
      end;
    $0F:
      begin
        CheckMinLength(Data, 1);
        FNOSUSupportStatus := Ord(Data[1]);
      end;
    $F2:
      begin
        CheckMinLength(Data, 5);
        PingResult := Ord(Data[1]);
        PingTime := BinToInt(Data, 2, 4);
      end;
    $F3:
      ;
    $F4:
      begin
        CheckMinLength(Data, 32);
        Summ1 := BinToAmount(Data, 1, 8); // Приход
        Summ2 := BinToAmount(Data, 9, 8); // Возврат прихода
        Summ3 := BinToAmount(Data, 17, 8); // Расход
        Summ4 := BinToAmount(Data, 25, 8); // Возврат расхода
      end;
    $F4FF:
      begin
        if CheckType = 5 then
        begin
          CheckMinLength(Data, 8 * 4);
          Summ1 := BinToAmount(Data, 1, 8);
          Summ2 := BinToAmount(Data, 9, 8);
          Summ3 := BinToAmount(Data, 17, 8);
          Summ4 := BinToAmount(Data, 25, 8);
        end else
        begin
          CheckMinLength(Data, 128);
          Summ1 := BinToAmount(Data, 1, 8);
          Summ2 := BinToAmount(Data, 9, 8);
          Summ3 := BinToAmount(Data, 17, 8);
          Summ4 := BinToAmount(Data, 25, 8);
          Summ5 := BinToAmount(Data, 33, 8);
          Summ6 := BinToAmount(Data, 41, 8);
          Summ7 := BinToAmount(Data, 49, 8);
          Summ8 := BinToAmount(Data, 57, 8);
          Summ9 := BinToAmount(Data, 65, 8);
          Summ10 := BinToAmount(Data, 73, 8);
          Summ11 := BinToAmount(Data, 81, 8);
          Summ12 := BinToAmount(Data, 89, 8);
          Summ13 := BinToAmount(Data, 97, 8);
          Summ14 := BinToAmount(Data, 105, 8);
          Summ15 := BinToAmount(Data, 113, 8);
          Summ16 := BinToAmount(Data, 121, 8);
        end;
      end;
    $EC:
      begin
        CheckMinLength(Data, 4);
        LoaderVersion := IntToStr(BinToInt(Data, 1, 4));
      end;
    $EF:
      begin
        CheckMinLength(Data, 60);
        for i := 1 to 15 do
        begin
          KKTLicenses[i] := BinToInt(Data, ((i - 1) * 4 + 1), 4);
        end;
      end;
    $E7:
      begin
        CheckMinLength(Data, 64);
        License := StrToHex2(Data);
      end;

  end;
end;

procedure TFiscalPrinter.DoICSReset;
var
  pEnum: IEnumVariant;
  vNetCon: OleVARIANT;
  dwRetrieved: Cardinal;
  pUser: NETCONLib_TLB.PUserType1;
  NetCon: INetConnection;
  NetSharingConf: INetSharingConfiguration;
  ConnectionSharing: INetConnection;
  ConnectionHome: INetConnection;
  HomeFound: Boolean;
  SharedFound: Boolean;
  NetSharingManager: TNetSharingManager;
begin
  Logger.Debug('DoICSReset');
  NetSharingManager := TNetSharingManager.Create(nil);
  try
    HomeFound := False;
    SharedFound := False;
    pEnum := (NetSharingManager.EnumEveryConnection._NewEnum as IEnumVariant);
    while (pEnum.Next(1, vNetCon, dwRetrieved) = S_OK) do
    begin
      (IUnknown(vNetCon) as INetConnection).GetProperties(pUser);
      NetCon := (IUnknown(vNetCon) as INetConnection);

      NetSharingConf := NetSharingManager.INetSharingConfigurationForINetConnection[NetCon];
      if NetSharingConf.SharingEnabled then
      begin
        if (NetSharingConf.SharingConnectionType = ICSSHARINGTYPE_PUBLIC) and (not SharedFound) then
        begin
          ConnectionSharing := NetCon;
          Logger.Debug('ICS ' + string(pUser.pszwName) + ', ' + pUser.pszwDeviceName + ', Puclic shared');

          SharedFound := True;
        end else if (NetSharingConf.SharingConnectionType = ICSSHARINGTYPE_PRIVATE) and (not HomeFound) then
        begin
          ConnectionHome := NetCon;
          Logger.Debug('ICS ' + string(pUser.pszwName) + ', ' + pUser.pszwDeviceName + ', Private shared');

          HomeFound := True;
        end;
      end
    end;
    if HomeFound then
    begin

      if SharedFound then
      begin
        NetSharingConf := NetSharingManager.INetSharingConfigurationForINetConnection[ConnectionSharing];
        if NetSharingConf <> nil then
        begin
          Logger.Debug('ICS ResetPublic');
          NetSharingConf.DisableSharing;
          NetSharingConf.EnableSharing(ICSSHARINGTYPE_PUBLIC);
        end;
      end;
      // Непонятно, нужно ли приватную сеть переподключать
      { NetSharingConf := NetSharingmanager.INetSharingConfigurationForINetConnection[ConnectionHome];
        if NetSharingConf <> nil then
        begin
        Logger.Debug('ResetPrivate');
        NetSharingConf.DisableSharing;
        NetSharingConf.EnableSharing(ICSSHARINGTYPE_PRIVATE);
        end; }

    end;
  finally
    NetSharingManager.Free;
  end;
end;

function TFiscalPrinter.GetICSEnabled: Boolean;
begin
  Result := FICSEnabled;
end;

function TFiscalPrinter.GetICSPollPeriod: Integer;
begin
  Result := FICSPollPeriod;
end;

procedure TFiscalPrinter.SetICSEnabled(const Value: Boolean);
begin
  FICSEnabled := Value;
  // ICSStopPoll;
  // ICSStartPoll;
end;

procedure TFiscalPrinter.SetICSPollPeriod(const Value: Integer);
begin
  FICSPollPeriod := Value;
  // ICSStopPoll;
  // ICSStartPoll;
end;

function TFiscalPrinter.FNOperationSendAdditionalTags: Integer;
begin
  Result := 0;
  if MeasureUnit <> 0 then
  begin
    Logger.Debug('FNOperation Additional Tag: 2108');
    TagNumber := 2108; // Мера количества предмета расчета
    TagType := ttByte;
    TagValueInt := MeasureUnit;
    Result := FNSendTagOperation;
  end;
  if Result <> 0 then
    Exit;

  if DivisionalQuantity then
  begin
    Logger.Debug('FNOperation Additional Tag: 1293, 1294');
    TagNumber := 1293; // Числитель
    TagType := ttVLN;
    TagValueVLN := Numerator;
    Result := FNSendTagOperation;
    if Result = 0 then
    begin
      TagNumber := 1294; // Знаменатель
      TagType := ttVLN;
      TagValueVLN := Denominator;
      Result := FNSendTagOperation;
    end;
  end;
end;

function TFiscalPrinter.FNOperation: Integer;
var
  TaxByte: Byte;
begin
  Result := SafeOpenSession;
  if Result <> 0 then
    Exit;

  TaxByte := TaxToFiscalPrinterTax(GetTax1);
  try
    if PrinterModel.CapCashCore then
    begin
      Result := FNOperationSendAdditionalTags;
      if Result <> 0 then
        Exit;
    end;

    UpdateStringForPrinting;
    Result := Send(#$FF#$46 + FPassw + AnsiChar(GetCheckType) + GetQuantity6 +
      // Количество
      GetPrice + // Цена
      GetSumm1_ + // Сумма операции
      GetTaxValue_ + // Налог
      AnsiChar(TaxByte) + AnsiChar(GetDepartment) + AnsiChar(PaymentTypeSign) + AnsiChar(PaymentItemSign) + Copy(GetPrintString, 1, 128));
    if Result <> 0 then
      Exit;

    if not PrinterModel.CapCashCore then
      Result := FNOperationSendAdditionalTags;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNSendTLVOperation: Integer;
begin
  try
    if (Length(TLVData) > 249) and (ProtocolType = 0) then
      RaiseError(E_INCORRECTTLVLENGTH, GetRes(@SIncorrectTLVLength));
    Result := Send(#$FF#$4D + FPassw + TLVData);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNGetNonClearableSumm: Integer;
begin
  FECode := $F4;
  Result := Send(#$FE#$F4 + #$00 + #$00 + #$00 + #$00);
end;

function TFiscalPrinter.GetFiscalSignAsString: WideString;
begin
  Result := IntToStr(Cardinal(FiscalSign));
end;

function TFiscalPrinter.DBFindDocument: Integer;
begin
  Result := ClearResult;
end;

function TFiscalPrinter.DBPrintDocument: Integer;
begin
  Result := ClearResult;
end;

function TFiscalPrinter.GetKKTLicenseByNumber: Integer;
begin
  Result := ClearResult;
  KKTLicense := KKTLicenses[LicenseNumber];
end;

{


  Команда чтения FE EF 00 00 00 00 возвращает 15 лицензий по 4 байта.
  Команда записи FE EE 04 01 02 03 04 F9 CC D8 30
  ^^
  Номер ^^ ^^ ^^ ^^
  Лицензия   ^^ ^^ ^^ ^^
  PUK-код
  Лицензий 15 штук 1-15. За подробностями какая что значит и как работает, а так же за PUK к Денису Петрушову.
}

function TFiscalPrinter.ReadKKTLicenses: Integer;
var
  i: Integer;
begin
  for i := 1 to 15 do
  begin
    KKTLicenses[i] := 0;
  end;
  FECode := $EF;
  Result := Send(#$FE#$EF#$00#$00#$00#$00);
end;

function TFiscalPrinter.WriteKKTLicense: Integer;
begin
  try
    if (LicenseNumber < 1) or (LicenseNumber > 15) then
      InvalidProp('LicenseNumber');
    FECode := $EE;
    Result := Send(#$FE#$EE + IntToBin(LicenseNumber, 1) + IntToBin(KKTLicense, 4) + IntToBin(Cardinal(PUKCode), 4));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

(*
  Закрытие чека со скидками/надбавками (Белоруссия)
  Команда: 57H. Длина сообщения: 37 байт.
  Пароль оператора (4 байта)
  Сумма наличных (5 байт) 0000000000…9999999999
  Сумма типа оплаты 2 (5 байт) 0000000000…9999999999
  Сумма типа оплаты 3 (5 байт) 0000000000…9999999999
  Сумма типа оплаты 4 (5 байт) 0000000000…9999999999
  Абсолютная скидка на чек (5 байт) 0000000000…9999999999
  Абсолютная надбавка на чек (5 байт) 0000000000…9999999999
  Процентная скидка/надбавка(в случае отрицательного значения) на чек от 0 до 99,99 % (2 байта со знаком) -9999…9999
  Ответ: 57H. Длина сообщения: 8 байт.
  Код ошибки (1 байт)
  Порядковый номер оператора (1 байт) 1…30
  Сдача (5 байт) 0000000000…9999999999

*)

function TFiscalPrinter.CloseCheckBel: Integer;
var
  Data: AnsiString;
begin
  try
    Data := #$57 + FPassw + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetDiscountValue + GetChargeValue + GetDiscountOnCheck;

    if UseTaxDiscountBel then
      Data := Data + AmountToBin(Discount1, 5) + AmountToBin(Discount2, 5) + AmountToBin(Discount3, 5) + AmountToBin(Discount4, 5);

    Result := Send(Data);
    DrvCloseCheck;

  except
    on E: Exception do
      Result := HandleException(E);
  end;

end;

function TFiscalPrinter.GetSumm1AsString: WideString;
begin
  Result := DecimalToString(Summ1);
end;

function TFiscalPrinter.GetSumm2AsString: WideString;
begin
  Result := DecimalToString(Summ2);
end;

function TFiscalPrinter.GetSumm3AsString: WideString;
begin
  Result := DecimalToString(Summ3);
end;

function TFiscalPrinter.GetSumm4AsString: WideString;
begin
  Result := DecimalToString(Summ4);
end;

function TFiscalPrinter.DBGetNextDocument: Integer;
var
  Rec: TReceiptDBRec;
begin
  try
    Result := ClearResult;
    Rec := FDB.GetNextDocument;
    if not Rec.IsFound then
    begin
      ResultCode := E_DOCUMENTNOTFOUND;
      ResultCodeDescription := GetRes(@SDocumentNotFound);
      Result := ResultCode;
      Exit;
    end;
    DBRecToDriver(Rec);
  except
    on E: Exception do
      Result := HandleException(E)
  end;
end;

function TFiscalPrinter.DBPrintNextDocument: Integer;
var
  S: TStringList;
  i: Integer;
begin
  Result := DBGetNextDocument;
  if Result <> 0 then
    Exit;
  S := TStringList.Create;
  try
    S.Text := StringForPrinting;
    for i := 0 to S.Count - 1 do
    begin
      StringForPrinting := S[i];
      Result := PrintStringWithWrap;
      if Result <> 0 then
        Exit;
    end;
    StringForPrinting := S.Text;
  finally
    S.Free;
  end;
  if Result <> 0 then
    Exit;
  // Result := FinishDocument;
end;

function TFiscalPrinter.DBQueryDocumentsInSession: Integer;
var
  DBFileName: WideString;
begin
  try
    Result := GetDBFileName(DBFileName);
    if Result <> 0 then
      Exit;
    if not FileExists(DBFileName) then
    begin
      ResultCode := E_FILENOTFOUND;
      ResultCodeDescription := Format('%s %s', [@SFileNotFound, DBFileName]);
      Result := ResultCode;
      Exit;
    end;
    FDB.FileName := DBFileName;
    FDB.StartSessionRequest(SessionNumber);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetDBFileName(var FName: WideString): Integer;
begin
  Result := ClearResult;
end;

procedure TFiscalPrinter.DBRecToDriver(ARec: TReceiptDBRec);
begin
  StringForPrinting := ARec.RecText;
  FiscalSign := ARec.FiscalSign;
  ECRDate := DateOf(ARec.RecDateTime);
  ECRTime := TimeOf(ARec.RecDateTime);
  SessionNumber := ARec.SessionNumber;
  DBDocType := ARec.RecType;
  DocumentNumber := ARec.FDNumber;
  Summ1 := ARec.Summ;
end;

function TFiscalPrinter.GetSysAdminPassword: AnsiString;
begin
  Result := IntToBin(SysAdminPassword, 4);
end;

procedure TFiscalPrinter.ChangeConnected(AConnected: Boolean);
begin
  FConnected := AConnected;
end;

function TFiscalPrinter.OFDNeedCancel: Boolean;
begin
  Result := (not (FEODEnabled and AutoOFDExchange)) and (not OFDEnabled) or (OFDExchangeSuspended) or (FOFDStopFlag) or (not FConnected);
end;

{
  # 1. Онлайн платеж 0xFF50
  #### вход:
  1. Система оплаты (сейчас только МОБИ) **1 байт**
  * **Моби** - `0x01`
  2. Тип транзакции **1 байт**
  * **Оплата (продажа)** `0x01`  ```// обрабатывается в любой момент, если предыдущие транзакции завершены```
  * **Возврат оплаты** `0x02` ```// обрабатывается в любой момент, если предыдущие транзакции завершены```
  * **Отмена оплаты** `0x03`
  * может быть передана сразу после оплаты(продажи) в любом состоянии этой продажи
  * сумма и id платежа должны быть такие же как и в последней команде оплаты.
  * При отмена оплаты выставляется флаг что последнюю оплату необходимо будет отменить и дальнейшие платежи/возвраты не принимаются пока:
  * не пришел ответ на оплату
  * не пришел ответ на отмену оплаты
  3. Тип ввода Штрих-Кода **1 байт**
  * **ручной ввод** - `0x00`
  * **1D** - `0x01`
  * **2D** - `0x02`
  4. Сумма **5 байт** диапазон `0000000000...9999999999`
  5. Идентификатор платежа **Null-terminated строка до 225+1 байт**
  * ```// для оплаты - это штрих код```
  * ```// для возврата и отмены - это ID транзакции на стороне платежного агента <service_payment_id>```
  ### выход:
  1. Код ошибки **1 байт** ```//код 0 - в данном случае означает принято в обработку```
}
function TFiscalPrinter.OnlinePay: Integer;
begin
  try
    Result := Send(#$FF#$50 + AnsiChar(GetOPSystem) + AnsiChar(GetOPTransactionType) + AnsiChar(GetOPBarcodeType) + GetSumm1 + Copy(OPIdPayment, 1, 255) + #0);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{
  # 2. Статус последнего онлайн платежа 0xFF51
  ```
  *всегда возвращается статус последнего платежа, новый платеж невозможен если еще не получен ответ сервера о последнем платеже)
  ```
  #### вход:
  ...
  #### выход:
  1. Код ошибки **1 байт**
  2. Система оплаты (сейчас только МОБИ) **1 байт**
  * **Моби** - `0x01`
  3. Тип транзакции **1 байт**
  4. Сумма **5 байт** диапазон `0000000000...9999999999`
  5. Статус транзакции **1 байт**
  * **Неизвестно** - `0x00` ```//(еще не было онлайн платежей) Отмена платежа невозможна пока не получен его статус.```
  * **Принят к проведению** - `0x01` ```//(транзакция еще не отправлен на сервер)```
  * **Ожидание получения статуса предыдущей команды** - `0x02` ```//(отправлен на сервер, но статус с сервера еще не получен или сервер возвращает "в обработке" )```
  * **Транзакция завершена успешно (одобрена)** - `0x03`
  * **Транзакция завершена неудачей (не одобрена)** - `0x04`
  6. Идентификатор платежа **Null-terminated строка до 225+1 байт**
}
function TFiscalPrinter.OPGetLastStatus: Integer;
begin
  try
    Result := Send(#$FF#$51);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.DecodeFF51(const Data: AnsiString);
begin
  OPSystem := Ord(Data[1]);
  OPTransactionType := Ord(Data[2]);
  Summ1 := BinToAmount(Data, 3, 5);
  OPTransactionStatus := Ord(Data[8]);
  OPIdPayment := TrimRight(Copy(Data, 9, 255));
end;

(*
  # 3. Получить реквизит последнего онлайн платежа 0xFF52
  ```
  Таким образом мы отдаем печать слипа верхнему софту. Пусть сами получают необходимые/желаемые реквизиты и вставляют их в текущий чек или печатают строками отдельный слип.
  Список возможных номеров реквизитов необходимо согласовать дополнительно, будет зависеть от "Система оплаты"
  *доступно при статусе последнего платежа:
  * Транзакция завершена успешно (одобрена)
  * Транзакция завершена неудачей (не одобрена)
  ```
  #### вход:
  1. Номер реквизита **1 байт**
  **Реквизиты доступны для всех систем оплаты**
  * **0xFE**: Текстовое описание последней ошибки

  **Список возможных рекизитов для Моби**
  * **0x01**: Id-транзакции по версии Алипей ```{параметр <wallet_payment_id>}```
  * **0x02**: Способ оплаты: Алипей ```{параметр <wallet_type>}```
  * **0x03**: User login ID ``` {параметр < wallet_user_login > }```
  * **0x04**: Время транзакции ```{ параметр  <payment_completion_datetime>}```
  * **0x05**: Сумма (в валюте кошелька, CNY)
  * **0x06**: Курс конвертации ```<wallet_exchange_rate>```
  * **0x07**: ID транзакции на стороне магазина ```{параметр <shop_payment_id>}```
  * **0x08**: ID транзакции на стороне платежного агента ```{параметр <service_payment_id>}```
  #### выход:
  1. код ошибки  **1 байт**
  2. Строка реквизита **Null-terminated строка до 225+1 байт**
*)
function TFiscalPrinter.OPGetLastRequisite: Integer;
begin
  try
    Result := Send(#$FF#$52 + AnsiChar(GetOPRequisiteNumber));
  except
    on E: Exception do
      Result := HandleException(E);
  end;

end;

procedure TFiscalPrinter.DecodeFF52(const Data: AnsiString);
begin
  OPRequisiteValue := TrimRight(Data);
end;

function TFiscalPrinter.GetOPBarcodeType: Integer;
begin
  if (OPBarcodeInputType < 0) or (OPBarcodeInputType > $FF) then
    InvalidProp('OPBarcodeInputType');
  Result := OPBarcodeInputType;
end;

function TFiscalPrinter.GetOPRequisiteNumber: Integer;
begin
  if (OPRequisiteNumber < 0) or (OPRequisiteNumber > $FF) then
    InvalidProp('OPRequisiteNumber');
  Result := OPRequisiteNumber;
end;

function TFiscalPrinter.GetOPSystem: Integer;
begin
  if (OPSystem < 0) or (OPSystem > $FF) then
    InvalidProp('OPSystem');
  Result := OPSystem;
end;

function TFiscalPrinter.GetOPTransactionStatus: Integer;
begin
  if (OPTransactionStatus < 0) or (OPTransactionStatus > $FF) then
    InvalidProp('OPTransactionStatus');
  Result := OPTransactionStatus;
end;

function TFiscalPrinter.GetOPTransactionType: Integer;
begin
  if (OPTransactionType < 0) or (OPTransactionType > $FF) then
    InvalidProp('OPTransactionType');
  Result := OPTransactionType;
end;

function TFiscalPrinter.GenerateMonoToken: Integer;
begin
  Result := Send(#$FF#$53);
end;

procedure TFiscalPrinter.DecodeFF53(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  Token := Copy(Data, 1, 10);
end;

function TFiscalPrinter.IsRepeatableCommand(ACode: Integer): Boolean;
begin
  case ACode of
    $10, $11, $FC, $26, $FF01, $2E, $1F, $1E, $FF04, $FF0A, $F7:
      Result := True   else
    Result := False;
  end;
end;

function TFiscalPrinter.RebootKKT: Integer;
begin
  FECode := $F3;
  Result := Send(#$FE#$F3#$00#$00#$00#$00);
end;

function TFiscalPrinter.FNBeginSTLVTag: Integer;
var
  Node: TTagNode;
  NewTag: TTagNode;
begin
  Result := 0;
  try
    if not FSTLVStarted then
    begin
      FSTLVTag.Nodes.Clear;
      FSTLVTag.Tag := TagNumber;
      FSTLVTag.TagType := ttSTLV;
      TagID := 0;
    end else
    begin
      Node := FSTLVTag.NodeByTagID(TagID);
      if Node = nil then
        InvalidProp('TagID');
      NewTag := Node.AddTag(TagNumber, ttSTLV);
      TagID := NewTag.TagID;
    end;
    FSTLVStarted := True;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNAddTag: Integer;

  function IsTagFixedLength(var Len: Integer): Boolean;
  var
    Tag: TTLVTag;
  begin
    Tag := FTags.FindTag(TagNumber);
    if Tag = nil then
    begin
      Len := 0;
      Result := False;
      Exit;
    end;
    Result := Tag.FixedLength;
    Len := Tag.Info.TagLen;
  end;

var
  Node: TTagNode;
  NewTag: TTagNode;
  Len: Integer;
begin
  Result := 0;
  try
    if not FSTLVStarted then
      raise Exception.Create('Call FNBeginSTLVTag first');
    Node := FSTLVTag.NodeByTagID(TagID);
    if Node = nil then
      InvalidProp('TagID');
    if TagType = ttSTLV then
      raise Exception.Create('Use FNBeginSTLVTag to add STLV');
    NewTag := Node.AddTag(TagNumber, TagType);
    case TagType of
      ttByte:
        NewTag.IntValue := TagValueInt;

      ttString:
        begin
          if IsTagFixedLength(Len) then
            NewTag.StrValue := AddFinalSpaces(TagValueStr, Len)
          else
            NewTag.StrValue := TagValueStr;
        end;

      ttUint16:
        NewTag.IntValue := TagValueInt;
      ttUInt32:
        NewTag.IntValue := TagValueInt;
      ttVLN:
        begin
          NewTag.BinValue := TagValueBin;
          NewTag.ValueLength := TagValueLength;
        end;
      ttFVLN:
        begin
          NewTag.FVLNValue := TagValueFVLN;
          NewTag.ValueLength := TagValueLength;
        end;
      ttFVLND:
        begin
          NewTag.FVLNDValue := TagValueFVLND;
          NewTag.ValueLength := TagValueLength;
        end;
      ttBitMask:
        begin
          NewTag.BinValue := TagValueBin;
          NewTag.ValueLength := TagValueLength;
        end;
      ttUnixTime:
        NewTag.DateTimeValue := TagValueDateTime;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNSendSTLVTag: Integer;
begin
  Result := FNSendSTLVTagCustom(False);
end;

function TFiscalPrinter.FNSendSTLVTagOperation: Integer;
begin
  Result := FNSendSTLVTagCustom(True);
end;

function TFiscalPrinter.FNSendSTLVTagCustom(AOperation: Boolean): Integer;
begin
  try
    FSTLVStarted := False;
    TLVData := FSTLVTag.GetTLV;
    if AOperation then
      Result := FNSendTLVOperation
    else
      Result := FNSendTLV;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ValueOfFieldInteger64: Int64;
var
  Code: Integer;
begin
  Val(ValueOfFieldString, Result, Code);
end;

// Чтение поля "Печать реквизитов пользователя"
function TFiscalPrinter.ReadPrintUserRequisite(var AValue: Integer): Integer;
var
  savePass: Integer;
begin
  Result := 0;
  AValue := 0;
  if IsModelType2(PrinterModel.ModelID) then
    Exit;
  TableNumber := 17;
  RowNumber := 1;
  FieldNumber := 12;
  savePass := Password;
  Password := SysAdminPassword;
  try
    Result := ReadTable;
    if Result <> 0 then
      Exit;
    AValue := ValueOfFieldInteger;
  finally
    Password := savePass;
  end;
end;

function TFiscalPrinter.LoadFontSymbol: Integer;
var
  SymbolSize: Integer;
begin
  FECode := $03;
  SymbolSize := Ceil(SymbolWidth / 8) * SymbolHeight;
  Result := Send(#$FE#$03 + AnsiChar(SymbolCode) + IntToBin(SymbolWidth, 2) + IntToBin(SymbolHeight, 2) + Copy(BlockData, 1, SymbolSize));
end;

function TFiscalPrinter.LoadFont: Integer;
var
  F: AnsiString;
  i: Integer;
  Count: Integer;
  Position: Integer;
  SymbolSize: Integer;
begin
  try
    Result := 0;
    F := ReadFileData(FileName);
    if (Length(F) < 9) or (Copy(F, 1, 3) <> 'SPF') then
      raise Exception.Create('Invalid SPF file format');
    Count := BinToInt(F, 5, 1);
    if Count = 0 then
      raise Exception.Create('Invalid SPF file format (symbol count = 0)');
    SymbolWidth := BinToInt(F, 6, 2);
    SymbolHeight := BinToInt(F, 8, 2);
    SymbolSize := Ceil(SymbolWidth / 8) * SymbolHeight;
    Position := 10;
    for i := 1 to Count do
    begin
      SymbolCode := BinToInt(F, Position, 1);
      Inc(Position);
      BlockData := Copy(F, Position, SymbolSize);
      Inc(Position, SymbolSize);
      Result := LoadFontSymbol;
      if Result <> 0 then
        Exit;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{
  Запись блока данных прошивки  ФР на SD карту FF4EH
  Код команды FF4Eh . Длина сообщения: 137 байт.
  Пароль системного администратора: 4 байта
  Файл прошивки: 1 байт ( 0- загрузчик, 1 - прошивка)
  Номер блока: 2 байта
  Блок данных: 128 байт.

  Ответ:	 FF4E  Длина сообщения: 1 байт.
  Код ошибки: 1 байт
}

function TFiscalPrinter.LoadBlockOnSDCard: Integer;
begin
  Result := Send(#$FF#$4E + FPassw + AnsiChar(Byte(FileType)) + IntToBin(BlockNumber, 2) + Copy(BlockData, 1, 128));
end;

const
  LoaderFileSize = 28672;
  FirmwareFileSize = 491520;

  {
    Запись файла на СД-карту
  }

function TFiscalPrinter.LoadFileOnSDCard: Integer;
var
  F: AnsiString;
  Position: Integer;
begin
  try
    F := ReadFileData(FileName);
    if ((FileType = ftLoader) and (Length(F) < LoaderFileSize)) or ((FileType = ftFirmware) and (Length(F) < FirmwareFileSize)) then
      raise Exception.Create('Invalid file size');

    Position := 1;
    BlockNumber := 0;
    repeat
      BlockData := Copy(F, Position, 128);
      Result := LoadBlockOnSDCard;
      if Result <> 0 then
        Exit;
      Inc(BlockNumber);
      Inc(Position, 128);
    until Position >= Length(F);
    if ((FileType = ftLoader) and (Length(F) > LoaderFileSize)) or ((FileType = ftFirmware) and (Length(F) > FirmwareFileSize)) then
    begin
      BlockData := '';
      Result := LoadBlockOnSDCard;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

/// ////////////////////////////////////////////////////////////////////////////
//
// Отправить код товарной номенклатуры
//
/// ////////////////////////////////////////////////////////////////////////////
//
// Вход:
// MarkingType: 2 - Меха; 3 - Лекарственные препараты; 5 - Табачные изделия
// SerialNumber - для Меха - КиЗ 20 символов; для лекарственных
// препаратов - Серийный номер 13 символов; для табачных изделий -
// код идентификации экземпляра, 24 симв.
// GTIN - число, преобразуется в 6 байт Big endian
//
/// ////////////////////////////////////////////////////////////////////////////

function TFiscalPrinter.FNSendItemCodeData: Integer;
var
  GTINBin: Int64;
  GTINStr: AnsiString;
  Data: AnsiString;
  Code: AnsiString;
  sString: WideString;
  bcode: AnsiString;
begin
  Result := ClearResult;
  try
    if (MarkingType = $444D) or (MarkingType = 3) or (MarkingType = 5) or (MarkingType = $1520) then
    begin

      if GTIN = '' then
        InvalidProp('GTIN');
      if SerialNumber = '' then
        InvalidProp('SerialNumber');

      GTINBin := 0;
      try
        GTINBin := StrToInt64(GTIN);
      except
        InvalidProp('GTIN');
      end;
      if GTINBin > $FFFFFFFFFFFF then
        InvalidProp('GTIN');

      GTINStr := ReverseString(IntToBin(GTINBin, 6));

      // Code := ReverseString(IntToBin(MarkingType, 2));

      Code := #$44#$4D;

      case MarkingType of
        3:
          begin // Лекарственные препараты
            SerialNumber := Copy(SerialNumber, 1, 13);
            SerialNumber := SerialNumber + StringOfChar(' ', 13 - Length(SerialNumber));
          end;

        5:
          begin // Табачная продукция
            SerialNumber := Copy(SerialNumber, 1, 24);
          end;

      end;
      Data := Code + GTINStr + TFormatTLV.ASCII2ValueTLV(SerialNumber);

      TLVData := TFormatTLV.Int2ValueTLV(1162, 2) + TFormatTLV.Int2ValueTLV(Length(Data), 2) + Data;
      Result := FNSendTLVOperation;
      { if IsModelType2(PrinterModel.ModelID) then
        begin
        sString := StringForPrinting;
        try
        StringForPrinting := 'КТ:' + GTIN;
        Result := PrintStringWithWrap;
        if Result <> 0 then Exit;
        StringForPrinting := SerialNumber;
        Result := PrintStringWithWrap;
        if Result <> 0 then Exit;
        finally
        StringForPrinting := sString;
        end;
        end; }
    end else if MarkingType = 2 then
    begin
      if SerialNumber = '' then
        InvalidProp('SerialNumber');
      SerialNumber := Copy(SerialNumber, 1, 20);
      SerialNumber := SerialNumber + StringOfChar(' ', 20 - Length(SerialNumber));
      Code := #$52#$46;
      Data := Code + TFormatTLV.ASCII2ValueTLV(SerialNumber);
      TLVData := TFormatTLV.Int2ValueTLV(1162, 2) + TFormatTLV.Int2ValueTLV(Length(Data), 2) + Data;
      Result := FNSendTLVOperation;
    end else // Другие типы маркировки
    begin
      Code := ReverseString(IntToBin(MarkingType, 2));
      case MarkingType of
        0:
          Data := Code + TFormatTLV.ASCII2ValueTLV(Copy(Barcode, 1, 30));
        $4508, $450D, $490E:
          Data := Code + ReverseString(TFormatTLV.Int2ValueTLV(StrToInt64(Barcode), 6));
      else
        Data := Code + TFormatTLV.ASCII2ValueTLV(Barcode);
      end;
      TLVData := TFormatTLV.Int2ValueTLV(1162, 2) + TFormatTLV.Int2ValueTLV(Length(Data), 2) + Data;
      Result := FNSendTLVOperation;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

// Передать ШК товара в формате GS1
(*
  Привязка  маркированного товара к позиции FF67H
  Код команды FF67h. Длина сообщения: 5+N байт.
  Пароль оператора: 4 байта
  Длина кода маркировки: 1 байт
  Данные маркировки N байт
  Данная команда должна вызываться после привязки всех тегов к предмету расчета.
  Ответ: FF67h	    Длина сообщения: 8 байт.
  Код ошибки: 1 байт
*)

function TFiscalPrinter.FNSendItemBarcode: Integer;
var
  LBarcode: AnsiString;
  OSU: AnsiString;
begin
  try
    if Length(Barcode) > 248 then
      InvalidProp('Barcode');

    if Length(Barcode) = 12 then
      LBarcode := '0' + Barcode
    else
      LBarcode := Barcode;

    OSU := '';
    if MCOSUSign then
      OSU := #$FF;

    Result := Send(#$FF#$67 + FPassw + AnsiChar(Byte(Length(LBarcode))) + LBarcode + OSU);

    // Управление индикацией ЗНАК ID
    if MCScannerAutoSendMCStatus then
    begin
      Result := MCScannerGetLastMCStatus;
      if Result <> 0 then
        Exit;
      Result := MCScannerSendMCStatus;
    end;

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.DecodeFF67(const Data: AnsiString);
var
  AddLength: Integer;
begin
  CheckMinLength(Data, 3);
  // MarkingType - Распознанный тип кода (2 байта)**
  // Тип кода	        Значение
  // EAN8	            0x45 0x08
  // EAN13	            0x45 0x0D
  // ITF14	            0x49 0x0E
  // GS-1 Data Matrix	0x44 0x4D
  // RF метка меховых изделий	0x52 0x46
  // ЕГАИС-3	          0xC5 0x14
  // ЕГАИС-3	          0xC5 0x1E
  // ОСУ EAN8	        0x4F 0x08
  // ОСУ EAN13	        0x4F 0x0D
  // ОСУ GTIN ITF14	  0x4F 0x0E
  // Нераспознанный код	0x00 0x00

  MarkingType := BinToInt(ReverseString(Copy(Data, 1, 2)), 1, 2);
  Logger.Debug('MarkingType = ' + IntToStr(MarkingType));

  // MarkingTypeEx - Тип Data Matrix (1 байт)***
  // 0 – КМ 88
  // 1 – КМ симметричный
  // 2 – КМ Табачный
  // 3 – КМ 44.
  // 0xFF – GS-1 без маркировки

  MarkingTypeEx := BinToInt(Data, 3, 1);

  CheckItemLocalResult := -1;
  if Length(Data) > 3 then
  begin
    CheckMinLength(Data, 7);
    // CheckItemLocalResult - Статус локальной проверки Тег 2004
    CheckItemLocalResult := BinToInt(Data, 1 + 3, 1);
    // Статус  локальной проверки
    // CheckItemLocalError - Причина, по которой не была проведена локальная проверка
    // Причина того, что КМ не проверен в ФН:
    // 0 – КМ проверен в ФН
    // 1 – КМ данного типа не подлежит проверки в ФН
    // 2 – ФН не содержит ключ проверки кода проверки этого КМ
    // 3 – Проверка невозможна, так как отсутствуют идентификаторы применения GS1 91 и /
    // или 92 или их формат неверный.
    // 4 – Проверка КМ в ФН невозможна по иной причине
    CheckItemLocalError := BinToInt(Data, 2 + 3, 1);
    // ричина, по которой не была проведена локальная проверка	В соответствии с таблицей 123
    // MarkingType2 - Распознанный тип КМ Тег 2100
    MarkingType2 := BinToInt(Data, 3 + 3, 1); // Распознанный тип КМ	Тег 2100
    // Длина дополнительных параметров
    AddLength := BinToInt(Data, 4 + 3, 1);
    KMServerErrorCode := -1;
    KMServerCheckingStatus := -1;
    TLVData := '';
    CheckMinLength(Data, 7 + AddLength);
    if AddLength > 0 then
    begin
      // KMServerErrorCode - Код ответа ФН на команду онлайн-проверки
      // Если 0x20, то вследующем байте возвращается причина в соответствии с Примечанием 3
      // Значение 0xFF если сервер не ответил в течение таймаута.
      KMServerErrorCode := BinToInt(Data, 5 + 3, 1);
      // KMServerCheckingStatus - Результат проверки КМ Тег 2106 Только если сервер ответил без ошибок
      // Если KMServerErrorCode = 0x20, то сделующие значения:
      // Причина проблемы при обработке ответа:
      // 1 – Неверный фискальный признак ответа;
      // 2 – Неверный формат реквизиов ответа;
      // 3 – Неверный номер запроса в ответе;
      // 4 – Неверный номер ФН;
      // 5 – Неверный CRC блока данных;
      // 7 – Неверная длина ответа.
      if (AddLength > 1) and ((KMServerErrorCode = 0) or (KMServerErrorCode = $20)) then
        KMServerCheckingStatus := BinToInt(Data, 6 + 3, 1);
      // Результат проверки КМ 	Тег 2106	Только если сервер ответил без ошибок
      // Список реквизитов ответа сервера TLV List Только если сервер ответил без ошибок
      if (AddLength > 2) and (KMServerErrorCode = 0) then
        TLVData := Copy(Data, 7 + 3, AddLength - 2);
      // Список реквизитов ответа сервера	TLV List	Только если сервер ответил без ошибок
    end;
  end;
end;

(* *****************************************************************************
  Проверка маркированного товара

  На входе:
  смещение	параметр	значение
  0	Планируемый статус |	Тег 2003 ФФД
  1	Режим обработки |	Тег 2102 ФФД, сейчас всегда 0
  2	Длина КМ в байтах (N)	| Полная длина КМ
  3	Длина списка TLV в байтах	| Полная длина списка TLV
  4	КМ	| Сам КМ, как он был прочитан сканером
  4+N	Список TLV	Если планируется частичное выбытие (согласно с тегом 2003), то необходимо сформировать буфер из тегов 2108 (мера) и 1023(количество) и передать его здесь

  Значения реквизита "планируемый статус товара" (тег 2003)
  1 Штучный товар, подлежащий обязательной маркировке средством идентификации, реализован
  2	Мерный товар, подлежащий обязательной маркировке средством идентификации, в стадии реализации
  3	Штучный товар, подлежащий обязательной маркировке средством идентификации, возвращен
  4	Часть товара, подлежащего обязательной маркировке средством идентификации, возвращена
  255	Статус товара, подлежащего обязательной маркировке средством идентификации, не изменился

  На выходе:
  Смещение	Параметр	Значение	Примечание
  0	Статус  локальной проверки	Тег 2004
  1	Причина, по которой не была проведена локальная проверка	В соответствии с таблицей 123
  2	Распознанный тип КМ	Тег 2100
  3	Длина дополнительных параметров	Длина данных, идущих далее	0 если автономный режим.
  4	Код ответа ФН на команду онлайн-проверки	В соответствии и вводом ошибки ФН.	Если 0x20, то в следующем байте возвращается причина в соответствии с таблицей 130 протокола ККТ-ФНМ.
  0xFF Если сервер не ответил в течении таймаута.
  5	Результат проверки КМ 	Тег 2106	Только если сервер ответил без ошибок
  6	Список реквизитов ответа сервера	TLV List	Только если сервер ответил без ошибок

  Тег 2004  [1b] Результат проверки КМ
  Номер бита
  0	"0" - код маркировки не может быть проверен фискальным накопителем с использованием ключа проверки КП
  "1" - код маркировки проверен фискальным накопителем с использованием ключа проверки КП
  1	"0" - результат проверки КП КМ фискальным накопителем с использованием ключа проверки КП отрицательный (в случае, если значение нулевого бита равно "1") или код маркировки не может быть проверен фискальным накопителем с использованием ключа проверки КП (в случае, если значение нулевого бита равно "0")
  "1" - результат проверки КП КМ фискальным накопителем с использованием ключа проверки КП положительный
  2-7	Заполняются нулями

  Тег 2100 [1b] Тип КМ
  0	Тип кода маркировки не идентифицирован (код маркировки отсутствует, не может быть прочитан или может быть прочитан, но не может быть распознан)
  1	Короткий код маркировки
  2	Код маркировки со значением кода проверки длиной 88 символов, подлежащим проверке в ФН
  3	Код маркировки со значением кода проверки длиной 44 символа, не подлежащим проверке в ФН
  4	Код маркировки со значением кода проверки длиной 44 символа, подлежащим проверке в ФН
  5	Код маркировки со значением кода проверки длиной 4 символа, не подлежащим проверке в ФН

  Тег 2106 [1b] Результат проверки сведений о товаре
  Состояния битов в значении реквизита "результат проверки сведений о товаре" (тег 2106)
  Номер бита	Состояние бита в зависимости от результата проверки КМ и статуса товара
  0	"0" - код маркировки не был проверен ФН и (или) ОИСМ
  "1" - код маркировки проверен
  1	"0" - результат проверки КП КМ отрицательный или код маркировки не был проверен
  "1" - результат проверки КП КМ положительный
  2	"0" - сведения о статусе товара от ОИСМ не получены
  "1" - проверка статуса ОИСМ выполнена
  3	"0" - от ОИСМ получены сведения, что планируемый статус товара некорректен или сведения о статусе товара от ОИСМ не получены
  "1" - от ОИСМ получены сведения, что планируемый статус товара корректен
  4	"0" - результат проверки КП КМ и статуса товара сформирован ККТ, работающей в режиме передачи данных
  "1" - результат проверки КП КМ сформирован ККТ, работающей в автономном режиме
  5-7	Заполняются нулями

  Тег 2108 [1b] мера количества предмета расчета
  Порядковый номер пункта	ПФ	Значение реквизита "мера количества предмета расчета" (тег 2108) в ЭФ	Примечание
  1	  шт. или  ед.	0	Применяется для предметов расчета, которые могут быть реализованы поштучно или единицами
  2	  г           	10	Грамм
  3	  кг	          11	Килограмм
  4	  т	            12	Тонна
  5	  см	          20	Сантиметр
  6	  дм	          21	Дециметр
  7	  м	            22	Метр
  8	  кв. см	      30	Квадратный сантиметр
  9	  кв. дм	      31	Квадратный дециметр
  10	кв. м	        32	Квадратный метр
  11	мл	          40	Миллилитр
  12	л	            41	Литр
  13	куб. м	      42	Кубический метр
  14	кВт?ч	        50	Киловатт час
  15	Гкал	        51	Гигакалория
  16	сутки	        70	Сутки (день)
  17	час	          71	Час
  18	мин	          72	Минута
  19	с	            73	Секунда
  20	Кбайт	        80	Килобайт
  21	Мбайт	        81	Мегабайт
  22	Гбайт	        82	Гигабайт
  23	Тбайт	        83	Терабайт
  -	-	              255	Применяется при использовании иных единиц измерения, не поименованных в п.п. 1-23

  Тег 1023 [FVLN 8] - кол-во предмета расчета

  Таблица 123
  Наименование	Тип	Длина	Комментарий
  Результат проверки КМ в ФН	Byte	1	Значение соответствует значению тега 2004.
  0 - КМ не был проверен в ФН
  1 - КМ проверен в ФН и результат проверки отрицательный
  3 - КМ проверен в ФН и результат проверки положительный
  Причина того, что КМ не проверен в ФН	Byte	1	Информирует ККТ о причине того, что КМ не был проверен в ФН
  0 - КМ проверен в ФН
  1 - КМ данного типа не подлежит проверки в ФН
  2 - ФН не содержит ключ проверки кода проверки этого КМ
  3 - Проверка невозможна, так как отсутствуют теги 91 и / или 92 или их формат неверный
  4 -Внутренняя ошибка в ФН при проверке этого КМ

  Таблица 130
  Наименование	Тип	Длина	Комментарий
  Причина ошибки при обработке ответа	Byte 1
  1 - Неверный фискальный признак
  2 - Неверный формат ответа
  3 - Неверный номер запроса в ответе
  4 - Неверный номер ФН
  5 - Неверный CRC блока данных
  7 - Неверная длина ответа

  ***************************************************************************** *)

function TFiscalPrinter.FNCheckItemBarcode: Integer;
var
  LBarcode: AnsiString;
  bCheckItemMode: Byte;
begin
  try
    if Length(Barcode) > $FF then
      InvalidProp('BarCode');

    if ((ItemStatus < 1) or (ItemStatus > 4)) and (ItemStatus <> 255) then
      InvalidProp('ItemStatus');

    if CheckItemMode <> 0 then
      InvalidProp('CheckItemMode');

    bCheckItemMode := CheckItemMode;
    if MCCheckWithOSU then
      SetBit(bCheckItemMode, 7);

    if Length(Barcode) = 12 then
      LBarcode := '0' + Barcode
    else
      LBarcode := Barcode;

    Result := Send(#$FF#$61 + FPassw + AnsiChar(ItemStatus) + AnsiChar(bCheckItemMode) + AnsiChar(Length(LBarcode)) + AnsiChar(Length(TLVData)) + LBarcode + TLVData);

    if Result <> 0 then
      Exit;

    // Управление индикацией ЗНАК ID
    if MCScannerAutoSendMCStatus then
    begin
      Result := MCScannerGetLastMCStatus;
      if Result <> 0 then
        Exit;
      Result := MCScannerSendMCStatus;
    end;

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNCheckItemBarcode2: Integer;
var
  TagData: AnsiString;
  Node: TTagNode;
  n: TTagNode;
  Num: AnsiString;
  Den: AnsiString;
  LBarcode: AnsiString;
  bCheckItemMode: Byte;
begin
  try
    if Length(Barcode) > $FF then
      InvalidProp('BarCode');

    if ((ItemStatus < 1) or (ItemStatus > 4)) and (ItemStatus <> 255) then
      InvalidProp('ItemStatus');

    if CheckItemMode <> 0 then
      InvalidProp('CheckItemMode');

    bCheckItemMode := CheckItemMode;
    if MCCheckWithOSU then
      SetBit(bCheckItemMode, 7);

    if DivisionalQuantity then
    begin
      Num := IntToBin(StrToInteger64(Numerator, 'Numerator'), 8);
      Den := IntToBin(StrToInteger64(Denominator, 'Denominator'), 8);
    end;

    TagData := '';

    if (ItemStatus = 4) or (ItemStatus = 2) then
    begin
      Node := TTagNode.Create(nil);
      Node.Tag := 2108;
      Node.TagType := ttByte;
      Node.IntValue := MeasureUnit;
      TagData := Node.GetTLV;
      Node.Free;

      Node := TTagNode.Create(nil);
      Node.Tag := 1023;
      Node.TagType := ttFVLND;
      Node.ValueLength := 8;
      if DivisionalQuantity then
        Node.FVLNDValue := 1
      else
        Node.FVLNDValue := Quantity;
      TagData := TagData + Node.GetTLV;
      Node.Free;

      if DivisionalQuantity then
      begin
        Node := TTagNode.Create(nil);
        Node.Tag := 1291;
        Node.TagType := ttSTLV;
        n := Node.AddTag(1293, ttVLN);
        n.BinValue := Num;
        n.ValueLength := 8;
        n := Node.AddTag(1294, ttVLN);
        n.BinValue := Den;
        n.ValueLength := 8;
        TagData := TagData + Node.GetTLV;
        Node.Free;
      end;
    end;

    if Length(Barcode) = 12 then
      LBarcode := '0' + Barcode
    else
      LBarcode := Barcode;

    Result := Send(#$FF#$61 + FPassw + AnsiChar(ItemStatus) + Char(bCheckItemMode) + AnsiChar(Length(LBarcode)) + AnsiChar(Length(TagData)) + LBarcode + TagData);
    if Result <> 0 then
      Exit;

    // Управление индикацией ЗНАК ID
    if MCScannerAutoSendMCStatus then
    begin
      Result := MCScannerGetLastMCStatus;
      if Result <> 0 then
        Exit;
      Result := MCScannerSendMCStatus;
    end;

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNCheckItemBarcodeCrpt: Integer;
begin
  //
end;

procedure TFiscalPrinter.DecodeFF61(const Data: AnsiString);
var
  AddLength: Integer;
begin
  CheckMinLength(Data, 4);

  CheckItemLocalResult := BinToInt(Data, 1, 1); // Статус  локальной проверки
  CheckItemLocalError := BinToInt(Data, 2, 1);
  // ричина, по которой не была проведена локальная проверка	В соответствии с таблицей 123
  MarkingType2 := BinToInt(Data, 3, 1); // Распознанный тип КМ	Тег 2100
  AddLength := BinToInt(Data, 4, 1);
  KMServerErrorCode := -1;
  KMServerCheckingStatus := -1;
  TLVData := '';
  if AddLength > 0 then
  begin
    KMServerErrorCode := BinToInt(Data, 5, 1);
    // Код ответа ФН на команду онлайн-проверки	В соответствии и вводом ошибки ФН.
    // Если 0x20, то в следующем байте возвращается причина в соответствии с таблицей 130 протокола ККТ-ФНМ.
    // 0xFF Если сервер не ответил в течении таймаута.

    if (AddLength > 1) and ((KMServerErrorCode = 0) or (KMServerErrorCode = $20)) then
      KMServerCheckingStatus := BinToInt(Data, 6, 1);
    // Результат проверки КМ 	Тег 2106	Только если сервер ответил без ошибок

    if (AddLength > 2) and (KMServerErrorCode = 0) then
      TLVData := Copy(Data, 7, AddLength - 2);
    // Список реквизитов ответа сервера	TLV List	Только если сервер ответил без ошибок
  end;
end;

//

{ function TFiscalPrinter.CheckItemMarking: Integer;
  begin
  Result := ClearResult;
  if (MarkingType in [2, 3])and(Barcode <> '') then
  begin
  Result := FNCheckItemBarcode;
  end;
  end; }

{ function TFiscalPrinter.SendItemMarking: Integer;
  begin
  Result := ClearResult;
  if (Barcode <> '')and(FMarkChecker.EkmServerEnabled or FMarkChecker.FSMarkCheckEnabled) then
  begin
  Result := FNSendItemCodeData;
  end;
  end; }

{
  Запрос параметра открытия ФН
  Код команды FF0Eh . Длина сообщения: 9 байт.
  Пароль системного администратора: 4 байта
  Порядковый номер отчета о регистрации/перерегистрации: 1 байт
  Номер тега (Тип Т, TLV параметра): 2 байта (если T=FFFFh (2), то читать TLV структуру командой FF3Bh)
  Ответ:    FF0Eh Длина сообщения: 2+1+X(1) байт.
  Код ошибки : 1 байт
  TLV структура: X(1) байт
  Примечание:
  (1) - длина ответного сообщения зависит от TLV структуры, возвращаемой ФН на заданный номер тега (кроме FFFFh);
  (2) - при запросе всех тегов TLV структура не возвращается (X=0).
}

function TFiscalPrinter.FNRequestRegistrationTLV: Integer;
begin
  try
    CheckIntProp(RegistrationNumber, 0, $FF, 'RegistrationNumber');
    CheckIntProp(TagNumber, 0, $FFFF, 'TagNumber');
    Result := Send(#$FF#$0E + FPassw + IntToBin(RegistrationNumber, 1) + IntToBin(TagNumber, 2));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TFiscalPrinter.DecodeFF0E(const Data: AnsiString);
begin
  if TagNumber <> $FFFF then
    TLVData := Data
  else
    TLVData := '';
end;

// Минимальная версия загрузчика для DFU 129
function TFiscalPrinter.ReadLoaderVersion: Integer;
begin
  FECode := $EC;
  Result := Send(#$FE#$EC#$00#$00#$00#$00);
end;

function TFiscalPrinter.FNOpenCheckCorrection: Integer;
var
  RecType: Byte;
begin
  try
    RecType := GetCheckType;
    SetBit(RecType, 7);
    Result := SafeOpenSession;
    if Result <> 0 then
      Exit;
    Result := Send(#$8D + FPassw + AnsiChar(RecType));
    DrvOpenCheck;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{
  Синхронизировать регистры со счётчиком ФН FF62H
  Код команды FF62h . Длина сообщения: 6 байт.
  Пароль системного администратора: 4 байта
  Ответ:    FF62h Длина сообщения: 1 байт.
  Код ошибки: 1 байт
}

function TFiscalPrinter.FNCountersSync: Integer;
begin
  Result := Send(#$FF#$62 + FPassw);
end;

{
  Запрос ресурса свободной памяти  в ФН FF63H
  Код команды FF63h . Длина сообщения: 6 байт.
  Пароль системного администратора: 4 байта
  Ответ:    FF63h Длина сообщения: 9 байт.
  Код ошибки: 1 байт
  Ресурс данных 5 летнего хранения 1:4 байта
  Ресурс данных 30 дневного хранения 2:4 байта

  Примечание
  1  - Ориентировочное кол-во документов, которые можно создать в ФН
  2 - Размер свободной области (в килобайтах) для записи документов 30 хранения. После 30 дней работы значение может колебаться на постоянном уровне
}

function TFiscalPrinter.FNGetFreeMemoryResource: Integer;
begin
  Result := Send(#$FF#$63 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF63(const Data: AnsiString);
begin
  CheckMinLength(Data, 8);
  FN5YearResource := BinToInt(Data, 1, 4);
  FN30DayResource := BinToInt(Data, 5, 4);
  if Length(Data) > 8 then
    FNMarkingFillPercentage := BinToInt(Data, 9, 1)
  else
    FNMarkingFillPercentage := -1;
end;

function TFiscalPrinter.PrintText(const AText: WideString; AWrap: Boolean = True): Integer;
var
  SaveStr: WideString;
begin
  SaveStr := StringForPrinting;
  try
    StringForPrinting := AText;
    if AWrap then
      Result := PrintStringWithWrap
    else
      Result := PrintString;
  finally
    StringForPrinting := SaveStr;
  end;
end;

function TFiscalPrinter.SetDFUMode: Integer;
begin
  FECode := $ED;
  Result := Send(#$FE#$ED#$00#$00#$00#$00);
end;

function TFiscalPrinter.UpdateFirmware: Integer;
var
  SavedOFDExchangeSuspended: Boolean;
  FFDParams: TFFDUpdateParams;
  doSaveTables: Boolean;
begin
  Logger.Debug('UpdateFirmware');
  EnablePlugins(False);
  SavedOFDExchangeSuspended := OFDExchangeSuspended;
  OFDExchangeSuspended := True;
  SetFWUpdater(UpdateFirmwareMethod);
  try
    try
      Result := ClearResult;
      if UpdateFirmwareSuspended then
        Exit;
      if FFwupdater.Started then
        RaiseError(E_FW_UPDATE_STARTED, GetRes(@SFwUpdateStarted));
      if IsModelType2(PrinterModel.ModelID) or (PrinterModel.ModelID = 152) then
        RaiseError(E_DFU_MODE_NOT_SUPPORTED, GetRes(@SDfuModeNotSupported));

      if not FileExists(FileName) then
        RaiseError(E_FILENOTFOUND, GetRes(@SFileNotFound));
      // Check(ReadLoaderVersion);
      // if (StrToInt(LoaderVersion) < 129) and (UpdateFirmwareMethod = FWUPDATE_METHOD_DFU) then
      // raise Exception.Create('Loader version does not support dfu update: ' + LoaderVersion);
      FSaveOFDExchangeSuspended := OFDExchangeSuspended;
      OFDExchangeSuspended := True;
      Disconnect;
      FFDParams.Enabled := TestBit(FWUpdateFFDParams, 0);
      FFDParams.Marking := TestBit(FWUpdateFFDParams, 1);
      FFDParams.Pawnshop := TestBit(FWUpdateFFDParams, 2);
      FFDParams.Insurance := TestBit(FWUpdateFFDParams, 3);
      FFDParams.WaitForDocumentSendingCompleteMin := FWUpdateFFDWaitInterval;
      doSaveTables := FWUpdateSaveTables;
      if GetECRStatus = 0 then
      begin
        doSaveTables := Pos('D', FECRSoftVersion) <> 1;
      end;
      Disconnect;
      FFwupdater.Start(FileName, ConnectionType, FConnectionParams, doSaveTables, FWUpdateSaveCashCounter, FFDParams);
    except
      on E: Exception do
        Result := HandleException(E);
    end;
  finally
    OFDExchangeSuspended := SavedOFDExchangeSuspended;
    EnablePlugins(True);
    Plugins.Disconnect;
  end;
end;

function TFiscalPrinter.CancelFirmwareUpdate: Integer;
begin
  Result := ClearResult;
  FFwupdater.Stop;
end;

function TFiscalPrinter.GetUpdateFirmwareStatus: Integer;
begin
  Result := FFwupdater.Status;
end;

function TFiscalPrinter.GetUpdateFirmwareStatusMessage: WideString;
begin
  Result := FFwupdater.StatusMessage;
end;

procedure TFiscalPrinter.OnDFUUpdateFinished(Sender: TObject);
begin
  OFDExchangeSuspended := FSaveOFDExchangeSuspended;
  FPlugins.Disconnect;
end;

procedure TFiscalPrinter.OnDisconnectTimer(Sender: TObject);
begin
  if FDisconnectTimerLastCommandTime = 0 then
    Exit;
  if not DisconnectOnIdle then
    Exit;
  try
    if abs(GetTickCount - FDisconnectTimerLastCommandTime) > DisconnectOnIdleTimeout then
    begin
      FDisconnectTimer.Enabled := False;
      FDisconnectTimerLastCommandTime := 0;
      Logger.Debug('On Disconnect Timer event');
      Disconnect;
    end;
  except

  end;
end;

procedure TFiscalPrinter.EnablePlugins(AEnabled: Boolean);
begin
  PluginsEnabled := AEnabled;
end;

function TFiscalPrinter.ReadRNMTj: Integer;
begin
  Result := Send(#$0F + FPassw);
end;

function TFiscalPrinter.WriteRNMTj: Integer;
begin
  Result := Send(#$0E + FPassw + AddFinalZeroByts(RNM, 16));
end;

function TFiscalPrinter.FNGetNonClearableSummEx: Integer;
begin
  try
    if (CheckType < 0) or (CheckType > 5) then
      InvalidProp('CheckType');
    FECode := $F4FF;
    Result := Send(#$FE#$F4 + AnsiChar(CheckType) + #$00#$00#$00);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetCashControlEnabledLicense: Boolean;
// Для этих ИНН лицензии не проверяются
const
  INNs: array[1..10] of string = ('7825439514', '7701285928', '5902182943', '7453011758', '2309051942', '3444066707', '3664082704', '5260136595', '6449013710', '7709356049');
var
  i: Integer;
  sPass: Integer;
  Res: Integer;
begin
  Result := True;
  if FCashControlINN = '' then
  begin
    Logger.Debug('Get INN: ' + FCashControlINN);
    sPass := Password;
    Password := SysAdminPassword;
    try
      Res := FNGetFiscalizationResult2;
      if Res = 0 then
        FCashControlINN := INN
      else
        FCashControlINN := '1';
      if Length(FCashControlINN) < 10 then
        FCashControlINN := '1';
      Logger.Debug('Get INN: ' + FCashControlINN);
    finally
      Password := sPass;
    end;
  end;

  for i := 1 to 10 do
  begin
    if INNs[i] = Trim(FCashControlINN) then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function TFiscalPrinter.GetFWUpdateEnabled: Boolean;
begin
  FWUpdateParams.Load;
  Result := FWUpdateParams.Enabled;
end;

function TFiscalPrinter.GetFWUpdatePollInterval: Integer;
begin
  FWUpdateParams.Load;
  Result := FWUpdateParams.PollInterval;
end;

procedure TFiscalPrinter.SetFWUpdateEnabled(const Value: Boolean);
begin
  FWUpdateParams.Enabled := Value;
  FWUpdateParams.Save;
end;

procedure TFiscalPrinter.SetFWUpdatePollInterval(const Value: Integer);
begin
  FWUpdateParams.PollInterval := Value;
  FWUpdateParams.Save;
end;

function TFiscalPrinter.GetFWUpdateServerURL: WideString;
begin
  FWUpdateParams.Load;
  Result := FWUpdateParams.ServerUrl;
end;

procedure TFiscalPrinter.SetFWUpdateServerURL(const Value: WideString);
begin
  FWUpdateParams.ServerUrl := Value;
  FWUpdateParams.Save;
end;

{ Авторизоваться  FF66H
  Код команды FF66h. Длина сообщения: 22 байт.
  Пароль: 4 байта
  Данные для авторизации: 16 байт
  Ответ: FF66h Длина сообщения: 1 байт.
  Код ошибки: 1 байт }

function TFiscalPrinter.Authorization(const AuthData: AnsiString): Integer;
begin
  Result := Send(#$FF#$66 + FPassw + AuthData);
end;

{ Получить случайную последовательность FF65H
  Код команды FF65h. Длина сообщения: 6 байт.
  Пароль: 4 байта
  Ответ: FF65h Длина сообщения: 17 байт.
  Код ошибки: 1 байт
  Данные:16  Байт }

function TFiscalPrinter.ReadRandomSequence: Integer;
begin
  Result := Send(#$FF#$65 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF65(const Data: AnsiString);
begin
  CheckMinLength(Data, 16);
  FRandomSequence := Copy(Data, 1, 16);
end;

function TFiscalPrinter.SendAuth(const Data: AnsiString): Integer;
var
  S: AnsiString;
begin
  if not PrinterModel.CapAuthorization then
  begin
    Result := Send(Data);
    Exit;
  end;
  try
    Result := ReadRandomSequence;
    { Logger.Debug('===AUTH===');
      Logger.Debug('RandomSequence = ' + StrToHex(FRandomSequence));
      Logger.Debug('Key = ' + StrToHex(GetAuthKey));
      Logger.Debug('Data = ' + StrToHex(Data));
      Logger.Debug('PKCS7(RandomSequence + Data) = ' + StrToHex(PKCS7Padding(Copy(FRandomSequence, 1 , 16) + AnsiChar(Length(DAta)) + Data))); }
    { Logger.Debug('AES = ' + StrToHex(AESEncrypt(PKCS7Padding(Copy(FRandomSequence, 1 , 16) + AnsiChar(Length(Data)) +  Data), HexToStr(GetAuthKey)))); }
    if Result <> 0 then
      Exit;
    S := AESEncrypt(PKCS7Padding(Copy(FRandomSequence, 1, 16) + AnsiChar(Length(Data)) + Data), GetAuthKey);
    Result := Authorization(RightStr(S, 16));
    if Result = 0 then
      Result := Send(Data);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ResetAuthKey: Integer;
begin
  FECode := $E8;
  Result := Send(#$FE#$E8#$01#$02#$03#$04);
  if Result = 0 then
  begin
    FGetDeviceMetrics := False;
    FGetExDeviceMetrics := False;
    FGetPrinterModel := False;
  end;
end;

{ Если ключ авторизации не прописан, то надо параметры такие:
  16 байт ключ, 8 байт UIN (LE), 8 байт паддинг (любые байты.)
  2. Если в ФРе уже есть ключ авторизации:
  Надо сформировать блок данных 16 байт новый ключ, 8 байт UIN.
  Зашифровать AES-128 на старом ключе в режиме CBC с iv = 0 с любым паддингом.
  На выходе будет 2 блока (32 байта), их и передать в команде. }

function TFiscalPrinter.RewriteAuthKey: Integer;
var
  uin: Int64;
  Dat: AnsiString;
begin
  try
    if Length(HexToStr(AuthKey)) <> 16 then
      InvalidProp('AuthKey');

    TableNumber := 23;
    RowNumber := 1;
    FieldNumber := 11;
    Result := ReadTable;
    if Result <> 0 then
      Exit;
    try
      uin := StrToInt64(Trim(ValueOfFieldString));
    except
      on E: Exception do
        raise Exception.Create('Некорректный uin');
    end;
    { Logger.Debug('AuthKey = '  + StrToHex(GetAuthKey));
      Logger.Debug('uin = '  + Int64ToStr(uin) + ' ' + IntToHex(uin, 8));
      Logger.Debug('Data = '  + StrToHex(PKCS7Padding(HexToStr(AuthKey) + IntToBin(uin, 8)))); }
    Dat := AESEncrypt(PKCS7Padding(HexToStr(AuthKey) + IntToBin(uin, 8)), GetAuthKey);
    FECode := $E9;
    Result := Send(#$FE#$E9 + Dat);
    if Result = 0 then
    begin
      untAuthKey.SaveAuthKey(HexToStr(AuthKey));
      SavedAuthKey := '';
      FGetDeviceMetrics := False;
      FGetExDeviceMetrics := False;
      FGetPrinterModel := False;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.WriteAuthKey: Integer;
var
  uin: Int64;
begin
  try
    if Length(HexToStr(AuthKey)) <> 16 then
      InvalidProp('AuthKey');

    TableNumber := 23;
    RowNumber := 1;
    FieldNumber := 11;
    Result := ReadTable;
    if Result <> 0 then
      Exit;
    try
      uin := StrToInt64(Trim(ValueOfFieldString));
    except
      on E: Exception do
        raise Exception.Create('Некорректный uin');
    end;
    FECode := $E9;
    Result := Send(#$FE#$E9 + Copy(HexToStr(AuthKey), 1, 16) + IntToBin(uin, 8) + #$00#$00#$00#$00#$00#$00#$00#$00);
    if Result = 0 then
    begin
      untAuthKey.SaveAuthKey(HexToStr(AuthKey));
      SavedAuthKey := '';
      FGetDeviceMetrics := False;
      FGetExDeviceMetrics := False;
      FGetPrinterModel := False;
    end;

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.GetAuthKey: AnsiString;
begin
  if AuthKeyStorageType = 0 then
    Result := HexToStr(AuthKey)
  else
  begin
    if SavedAuthKey = '' then
      SavedAuthKey := ReadauthKey;
    Result := SavedAuthKey;
  end;
end;

function TFiscalPrinter.SaveAuthKey: Integer;
begin
  Result := ClearResult;
  try
    untAuthKey.SaveAuthKey(HexToStr(AuthKey));
    AuthKey := '';
    SavedAuthKey := '';
    GetAuthKey;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.DeleteAuthKey: Integer;
begin
  Result := ClearResult;
end;

function TFiscalPrinter.FNAcceptMakringCode: Integer;
begin
  Result := Send(#$FF#$69 + FPassw + #$01);
end;

function TFiscalPrinter.FNDeclineMarkingCode: Integer;
begin
  Result := Send(#$FF#$69 + FPassw + #$00);
end;

function TFiscalPrinter.FNMarkingClearBuffer: Integer;
begin
  Result := Send(#$FF#$69 + FPassw + #$02);
end;

function TFiscalPrinter.FNBindMarkingItem: Integer;
begin
  try
    if Length(Barcode) > $FF then
      InvalidProp('BarCode');

    Result := LoadBarcodeData(1, Barcode);
    if Result = 0 then
    begin
      Result := Send(#$FF#$67 + FPassw + IntToBin(Length(Barcode), 1));
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

{ Возвращается команда FF68 - Получить состояние по передачи уведомлений (о реализации маркированных товаров)
  Входных параметров нет. Выход - копия ответа ФН-М, таблица 132 протокола ККТ-ФНМ }

function TFiscalPrinter.FNGetKMServerExchangeStatus: Integer;
begin
  Result := Send(#$FF#$68 + FPassw);
end;

{ Возвращается команда FF68 - Получить состояние по передачи уведомлений (о реализации маркированных товаров)
  Входных параметров нет. Выход - копия ответа ФН-М, таблица 132 протокола ККТ-ФНМ

  -Состояние по передачи уведомлений	[Byte	1]
  0 - нет активного обмена;
  1 - начато чтение уведомления;
  2 - ожидание квитанции на уведомление;
  -Количество уведомлений в очереди	[Uint16, LE	2]
  0, если на все уведомления была получена квитанция
  -Номер текущего уведомления	[Uint32, LE	4]
  Номер уведомления для передачи, или уведомления на которое ожидается квитанция
  -Дата и время текущего уведомления	[DATE_TIME	5]
  0, если на все уведомления получена квитанция
  -Процент заполнения области хранения уведомлений	Byte	1


}

procedure TFiscalPrinter.DecodeFF68(const Data: AnsiString);
begin
  CheckMinLength(Data, 13);
  // ConnectionStatus := BinToInt(Data, 1, 1);
  MessageState := BinToInt(Data, 1, 1);
  // Состояние по передачи уведомлений	[Byte	1]
  MessageCount := BinToInt(Data, 2, 2);
  // Количество уведомлений в очереди	[Uint16, LE	2]
  MessageNumber := BinToInt(Data, 4, 4);
  // Номер текущего уведомления	[Uint32, LE	4]
  DecodeDataTime(Copy(Data, 8, 5));
  // Дата и время текущего уведомления	[DATE_TIME	5]
  FreeMemorySize := BinToInt(Data, 13, 1);
  // Процент заполнения области хранения уведомлений	Byte	1
end;

// Запрос статуса по работе с кодами маркировки
function TFiscalPrinter.FNGetMarkingCodeWorkStatus: Integer;
begin
  Result := Send(#$FF#$70 + FPassw);
end;

{
  - Состояние по проверке КМ	[Byte	1]  MCCheckStatus
  0 - работа с КМ временно заблокирована
  1 - нет КМ на проверке
  2 - передан КМ в команде B1h
  3 - сформирован запрос о статусе КМ в команде B5h
  4 -  получен ответ на запрос о статусе КМ в команде B6h
  - Состояние по формированию уведомления	[Byte	1] MCNotificationStatus
  0 - уведомление о реализации не формируется
  1 - начато формирование уведомления о реализации
  - Флаги разрешения команд работы с КМ	[Byte	1]  MCCommandFlags
  См. таблицу "Флаги разрешения команд работы с КМ"
  Биты	Код разрешенной команды
  0	0	0	0	0	0	0	1	B1h
  0	0	0	0	0	0	1	0	B2h
  0	0	0	0	0	1	0	0	B3h
  0	0	0	0	1	0	0	0	B5h
  0	0	0	1	0	0	0	0	B6h
  0	0	1	0	0	0	0	0	B7h с доп. кодом 1
  0	1	0	0	0	0	0	0	B7h с доп. кодом 2
  1	0	0	0	0	0	0	0	B7h с доп. кодом 3
  - Количество сохранённых результатов проверки КМ	[Byte	1] MCCheckResultSavedCount
  Количество КМ, результаты проверки которых, сохранены в ФН командой B2h c кодом 1
  - Количество КМ, включенных в уведомление о реализации	[Byte	1] MCRealizationCount
  - Предупреждение о заполнении области хранения уведомлений о реализации маркированного товара	[Byte	1] MCStorageSize
  В этом параметре ФН информирует ККТ о заполнении области хранения маркированного товара. Возможные следующие значения
  0 - область заполнена менее чем на 50%
  1 - область от 50 до 80%
  2 - область от 80 до 90%
  3 - область заполнена более чем на 90%
  - Количество уведомлений в очереди	[Uint16,LE	2]	Количество неподтверждённых или невыгруженных уведомлений о реализации маркированного товара
}

procedure TFiscalPrinter.DecodeFF70(const Data: AnsiString);
begin
  CheckMinLength(Data, 8);
  MCCheckStatus := Ord(Data[1]);
  MCNotificationStatus := Ord(Data[2]);
  MCCommandFlags := Ord(Data[3]);
  MCCheckResultSavedCount := Ord(Data[4]);
  MCRealizationCount := Ord(Data[5]);
  MCStorageSize := Ord(Data[6]);
  MessageCount := BinToInt(Data, 7, 2);
end;

procedure TFiscalPrinter.UpdateStringForPrinting;
begin
  if ItemNameLength > 0 then
    StringForPrinting := Copy(StringForPrinting, 1, ItemNameLength);
end;

function TFiscalPrinter.ReadFeatureLicenses: Integer;
begin
  FECode := $E7;
  Result := Send(#$FE#$E7#$00#$00#$00#$00);
end;

function TFiscalPrinter.WriteFeatureLicenses: Integer;
var
  Lic: AnsiString;
  Sign: AnsiString;
begin
  try
    Lic := HexToStr(License);
    if (Length(Lic) > 64) or (Length(Lic) = 0) then
      InvalidProp('License');
    Sign := HexToStr(DigitalSign);
    if Length(Sign) <> 64 then
      InvalidProp('DigitalSign');

    Lic := Lic + StringOfChar(#$00, 64 - Length(Lic));
    FECode := $E6;
    Result := Send(#$FE#$E6 + Lic + Sign);
  except
    on E: Exception do
      Result := HandleException(E);
  end
end;

function TFiscalPrinter.ReadDefaultFont: Integer;
var
  sTN, sRN, SFN: Integer;
  sPass: Integer;
begin
  if FDefaultFont <> 0 then
  begin
    Result := FDefaultFont;
    Exit;
  end;

  if IsModelType2(PrinterModel.ModelID) then
  begin
    Result := 1;
    FDefaultFont := 1;
    Exit;
  end;

  sPass := Password;
  Password := SysAdminPassword;
  sTN := TableNumber;
  sRN := RowNumber;
  SFN := FieldNumber;
  try
    TableNumber := 8;
    RowNumber := 1;
    FieldNumber := 23;
    if ReadTable <> 0 then
    begin
      Result := 1;
      FDefaultFont := 1;
    end else
    begin
      Result := ValueOfFieldInteger;
      FDefaultFont := Result;
    end;
  finally
    Password := sPass;
    TableNumber := sTN;
    RowNumber := sRN;
    FieldNumber := SFN;
  end;
end;

procedure TFiscalPrinter.SetFWUpdater(AMethod: Integer);
begin
  if AMethod = FWUPDATE_METHOD_XMODEM then
    FFwupdater := FUpdaterXModem
  else
    FFwupdater := FUpdaterDFU;
end;

function TFiscalPrinter.PlainTransferEnable: Integer;
begin
  FECode := $05;
  Result := Send(#$FE#$05);
end;

function TFiscalPrinter.PlainTransferDisable: Integer;
begin
  FECode := $06;
  Result := Send(#$FE#$06);
end;

function TFiscalPrinter.PluginsUpdateSettings: Integer;
begin
  Result := ClearResult;
  try
    Plugins.LoadParams;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNSendUserAttribute: Integer;
begin
  TagNumber := 1084;
  Result := FNBeginSTLVTag;
  if Result <> 0 then
    Exit;

  TagNumber := 1085;
  TagType := ttString;
  TagValueStr := UserAttributeName;
  Result := FNAddTag;
  if Result <> 0 then
    Exit;

  TagNumber := 1086;
  TagType := ttString;
  TagValueStr := UserAttributeValue;
  Result := FNAddTag;
  if Result <> 0 then
    Exit;

  Result := FNSendSTLVTag;
end;

procedure TFiscalPrinter.OnDeviceArrived(Sender: TObject; DeviceType: Integer; const Description: AnsiString);
begin
  Logger.Debug('DEVICE ARRIVED: ' + ShtrihDeviceTypeToString(DeviceType) + ' (' + Description + ')');
end;

procedure TFiscalPrinter.OnDeviceRemoved(Sender: TObject; DeviceType: Integer; const Description: AnsiString);
begin
  Logger.Debug('DEVICE REMOVED: ' + ShtrihDeviceTypeToString(DeviceType) + ' (' + Description + ')');
end;

function TFiscalPrinter.StrToInteger64(const Value: AnsiString; const AName: string): Int64;
begin
  try
    Result := StrToInt64(Value);
  except
    raise Exception.Create('Incorrect' + AName + 'value');
  end;
end;

procedure TFiscalPrinter.SetTagValueVLN(const Value: AnsiString);
var
  V: Int64;
begin
  FTagValueVLN := Value;
  try
    V := StrToInt64(Value);
  except
    Logger.Debug('Incorrect TagValueVLN value');
    Exit;
  end;
  TagValueBin := IntToBin(V, 8);
  Logger.Debug('TagValueBin: ' + StrToHex(TagValueBin));
end;

function TFiscalPrinter.GetTLSMode: Integer;
begin
  Result := FConnectionParams.TLSMode;
end;

procedure TFiscalPrinter.SetTLSMode(const Value: Integer);
begin
  FConnectionParams.TLSMode := Value;
end;

function TFiscalPrinter.GetTLVDataHex: AnsiString;
begin
  try
    Result := StrToHex(TLVData);
  except
    Result := '';
  end;
end;

procedure TFiscalPrinter.SetTLVDataHex(const Value: AnsiString);
begin
  try
    TLVData := HexToStr(Value);
  except
    on E: Exception do
    begin
      Logger.Error(E.Message);
      TLVData := '';
    end;
  end;
end;

// Начать чтение архива
// Вх:
function TFiscalPrinter.FNBeginReadArchive: Integer;
var
  Header: TFNReportHeader;
  Document: TFNDocumentRec;
begin
  try
    Result := ClearResult;
    FFNReport.Clear;
    Header.Signature := $54505243;
    Header.DocNumber := 0;
    FFNReport.Header := Header;
    FReadTicket := True;

    Document.Data := ReadFiscalizationParams;
    Document.DocumentNumber := 0;
    Document.DocumentType := 1;
    FFNReport.Add(Document);

  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNReadArchiveItem: Integer;
var
  Document: TFNDocumentRec;
begin
  Result := ClearResult;
  try
    Document := ReadFNDocument(DocumentNumber, FReadTicket);
    if Document.DataLength <> 0 then
    begin
      if Length(Document.Ticket.Data) = 0 then
        FReadTicket := False;
      FFNReport.Add(Document);
      if FFNReport.Documents.Count = 2 then
      begin
        if FFNReport.Documents[1].Data.Data = FFNReport.Documents[0].Data.Data then
          FFNReport.Documents[1].Free;
      end;
    end
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNSaveArchive: Integer;
var
  Writer: TFNReportWriter;
  Params: FNReport.TSaveParams;
begin
  Result := ClearResult;
  try
    FFNReport.ParseDocuments;
    case FNArchiveType of
      0:
        Writer := TFNReportBinWriter.Create;
      1:
        Writer := TFNReportTextWriter.Create;
    else
      InvalidProp('FNArchiveType');
    end;
    try
      Params.FileName := FileName;
      Params.Only1162 := MarkingOnly;
      Params.IncludeCRC := True;
      Writer.SaveToFile(FFNReport, Params);
    finally
      Writer.Free;
    end;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.ReadFiscalDocumentTLV: AnsiString;
var
  i: Integer;
  ResultCode: Integer;
const
  MaxRepeatCount = 3;
begin
  Result := '';
  repeat
    for i := 1 to MaxRepeatCount do
    begin
      ResultCode := FNReadFiscalDocumentTLV;
      if ResultCode <> -1 then
        Break;
    end;
    if ResultCode = 0 then
    begin
      Result := Result + TLVData;
      if Length(TLVData) = 0 then
        Break;
    end;
  until ResultCode <> 0;
  if ResultCode < 0 then
    Result := '';
end;

function TFiscalPrinter.FNInterruptFiscalDocumentReading: Integer;
var
  i: Integer;
const
  MaxRepeatCount = 3;
begin
  Result := 0;
  repeat
    for i := 1 to MaxRepeatCount do
    begin
      Result := FNReadFiscalDocumentTLV;
      if Result <> -1 then
        Break;
    end;
    if Result = 0 then
      if Length(TLVData) = 0 then
        Break;
  until Result <> 0;
end;

function TFiscalPrinter.ReadFNDocument(ADocumentNumber: Integer; ReadTicket: Boolean): TFNDocumentRec;
begin
  Result.Data := '';
  Result.DataLength := 0;
  Result.DocumentType := 0;
  Result.Ticket.Data := '';
  Result.DocumentNumber := ADocumentNumber;
  DocumentNumber := ADocumentNumber;
  if FNRequestFiscalDocumentTLV = 0 then
  begin
    Result.DocumentType := DocumentType;
    Result.DataLength := DataLength;
    Result.Data := ReadFiscalDocumentTLV;
    // Ticket
    Result.Ticket.Data := '';
    if ReadTicket then
      Result.Ticket := ReadFNTicket(ADocumentNumber);
  end;
end;

function TFiscalPrinter.ReadFNTicket(ADocumentNumber: Integer): TFNTicketRec;
begin
  Result.Data := '';
  DocumentNumber := ADocumentNumber;
  if FNGetOFDTicketByDocNumber = 0 then
  begin
    Result.Data := DocumentData;
    Result.Date := ECRDate + ECRTime;
    Result.DocumentMac := FiscalSignOFD;
    Result.DocumentNum := ADocumentNumber;
  end;
end;

function TFiscalPrinter.ReadFontHash: Integer;
begin
  FECode := $09;
  Result := Send(#$FE#$09#$00#$00#$00#$00);
end;

function TFiscalPrinter.ReadFiscalizationParams: AnsiString;
begin
  Check(FNGetExpirationTime);
  TagNumber := $FFFF;
  Check(FNRequestRegistrationTLV);
  Result := TLVData + ReadFiscalDocumentTLV;
end;

function TFiscalPrinter.FNOperationMdlp: Integer;
begin
  Result := FNOperation;
  if Result <> 0 then
    Exit;

  TagNumber := 1191;
  TagType := ttString;
  TagValueStr := Copy(UserAttributeValue, 1, 64);
  Result := FNSendTagOperation;
  if Result <> 0 then
    Exit;

  Result := FNSendItemBarcode;
end;

function TFiscalPrinter.FNCloseCheckMdlp: Integer;
begin
  Result := FNSendUserAttribute;
  if Result <> 0 then
    Exit;
  Result := FNCloseCheckEx;
end;

function TFiscalPrinter.GetTagValueBinHex: AnsiString;
begin
  Result := StrToHex(TagValueBin);
end;

procedure TFiscalPrinter.SetTagValueBinHex(const Value: AnsiString);
begin
  try
    TagValueBin := HexToStr(Value);
  except
    on E: Exception do
    begin
      TagValueBin := '';
      Logger.Error(E.Message);
    end;
  end;
end;

procedure TFiscalPrinter.DecodeFF69(const Data: AnsiString);
begin
  if Length(Data) > 0 then
    KMServerCheckingStatus := Ord(Data[1]);
end;

{
  FF 71 - Начать выгрузку уведомлений  о реализации маркированных товаров (в автономном режиме). Входных параметров нет.
  На выходе:
  Смещение	Параметр	Значение	Примечание
  0	Общее число уведомлений	Uint16_t	NotificationCount
  2	Номер первого уведомления	Uint32_t	NotificationNumber
  6	Размер первого уведомления	Uint16_t	NotificationSize
}

function TFiscalPrinter.FNBeginReadNotifications: Integer;
begin
  Result := Send(#$FF#$71 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF71(const Data: AnsiString);
begin
  CheckMinLength(Data, 8);
  NotificationCount := BinToInt(Data, 1, 2);
  NotificationNumber := BinToInt(Data, 3, 4);
  NotificationSize := BinToInt(Data, 7, 2);
end;

{
  FNReadNotificationBlock FF 72 -Прочитать блок уведомления (в автономном режиме). Входных параметров нет.
  На выходе:
  Смещение	Параметр	Значение	Примечание
  0	Номер текущего уведомления	Uint32_t	NotificationNumber
  4	Полный размер текущего уведомления	Uint16_t	NotificationSize
  6	Смещение от начала текущего уведомления	Uint16_t	DataOffset
  8	Размер прочитанного блока данных	Uint16_t	DataBlockSize
  10	Блок данных	Uint8_t[]	DataBlock
  ККТ выполняет поблочное всех доступных уведомлений (максимально ККТ может прочитать блок 128 байт). Следует вызывать команду до получения ошибки "нет данных" или на основании общего числа уведомлений, полученного из команды FF 71. Допускается прочитать лишь часть уведомлений и подтвердить их. В любой момент до подтверждения чтения можно вызвать команду FF 71 и начать чтение неподтвержденных уведомлений заново.

}

function TFiscalPrinter.FNReadNotificationBlock: Integer;
begin
  Result := Send(#$FF#$72 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF72(const Data: AnsiString);
begin
  CheckMinLength(Data, 10);
  NotificationNumber := BinToInt(Data, 1, 4);
  NotificationSize := BinToInt(Data, 5, 2);
  DataOffset := BinToInt(Data, 7, 2);
  DataBlockSize := BinToInt(Data, 9, 2);
  if DataBlockSize > 0 then
    DataBlock := Copy(Data, 11, DataBlockSize);
end;

{
  FF 73 - Подтвердить выгрузку уведомления (в автономном режиме).
  На входе:
  смещение	параметр	Значение
  0	Номер уведомления NotificationNumber	Получается из ответа на команду  FF 72
  4	CRC16
  CheckSum	Контрольная сумма уведомления
  На выходе данных нет. Драйвер должен выгрузить из ККТ уведомления (все или часть), сохранить их в файл, посчитать контрольные суммы и подтвердить выгрузку в ККТ. Если была выгружена часть уведомлений, необходимо повторить процедуру. Формат и алгоритм выгрузки описан в ФФД, пункты 174-178.

}

function TFiscalPrinter.FNConfirmNotificationRead: Integer;
begin
  Result := Send(#$FF#$73 + FPassw + IntToBin(NotificationNumber, 4) + IntToBin(CheckSum, 2));
end;

function TFiscalPrinter.FNReadFiscalBarcode: Integer;
var
  DocNumber: Cardinal;
begin
  try
    DocNumber := DocumentNumber;
    Result := FNGetStatus;
    if Result <> 0 then
      Exit;

    DocumentNumber := DocNumber;
    Result := FNFindDocument;
    if Result <> 0 then
      Exit;
    if DocumentType <> 3 then
      InvalidProp('DocumentType (' + DocumentType.ToString + ')');

    Barcode := MakeFiscalQR(ECRDate + ECRTime, Summ1, SerialNumber, DocumentNumber.ToString, FiscalSignAsString, OperationType);
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

const
  rtInt = 1;
  rtString = 2;
  rtBool = 3;

procedure SplitRegPath(const AName: string; var ArPath: string; var ArName: string);
var
  S: TArray<string>;
begin
  ArPath := '';
  ArName := '';
  S := AName.Split(['\']);
  if Length(S) < 2 then
    Exit;
  ArName := S[Length(S) - 1];
  ArPath := Copy(AName, 1, Length(AName) - Length(ArName) - 1);
end;

function TFiscalPrinter.ReadRegistryParam: Integer;
var
  Reg: TRegistry;
  rPath, rName: string;
  DataType: TRegDataType;
begin
  SplitRegPath(RegistryParamName, rPath, rName);
  Result := ClearResult;
  SetDefParams;
  Reg := TRegistry.Create;
  try
    try
      Reg.Access := KEY_READ;
      Reg.RootKey := GetRegRootKey(GetStorageType);
      if Reg.OpenKey(REGSTR_KEY_DRIVER + '\' + rPath, False) then
      begin
        if not Reg.ValueExists(rName) then
          raise Exception.Create('registry value not found: ' + REGSTR_KEY_DRIVER + '\' + rPath + '\' + rName);
        DataType := Reg.GetDataType(rName);

        case RegistryParamType of
          rtInt:
            RegistryParamValue := Reg.ReadInteger(rName).ToString;
          rtString:
            RegistryParamValue := Reg.ReadString(rName);
          rtBool:
            begin
              if Reg.ReadBool(rName) then
                RegistryParamValue := 'true'
              else
                RegistryParamValue := 'false'
            end;
        end;
      end;
    except
      on E: Exception do
        Result := HandleException(E);
    end;
  finally
    Reg.Free;
  end;
end;

function TFiscalPrinter.WriteRegistryParam: Integer;
var
  Reg: TRegistry;
  rPath, rName: string;
begin
  SplitRegPath(RegistryParamName, rPath, rName);
  Result := ClearResult;
  Reg := TRegistry.Create;
  try
    try
      Reg.RootKey := GetRegRootKey(GetStorageType);
      if Reg.OpenKey(REGSTR_KEY_DRIVER + '\' + rPath, True) then
      begin
        case RegistryParamType of
          rtInt:
            Reg.WriteInteger(rName, StrToInt(RegistryParamValue));
          rtString:
            Reg.WriteString(rName, RegistryParamValue);
          rtBool:
            begin
              if RegistryParamValue = 'true' then
                Reg.WriteBool(rName, True)
              else
                Reg.WriteBool(rName, False);
            end;
        end;
      end;
      LoadDrvParams;
      Plugins.LoadParams;
    except
      on E: Exception do
        Logger.Error(SParamsWriteError, E);
    end;
  finally
    Reg.Free;
  end;
end;

// Запрос исполнения ФН (3F)
function TFiscalPrinter.FNGetImplementation: Integer;
begin
  Result := Send(#$FF#$74 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF74(const Data: AnsiString);
begin
  CheckMinLength(Data, 48);
  FNImplementation := Str866To1251(Trim(Copy(Data, 1, 48)));
end;

// Запрос размера данных документа в ФН (A7)
function TFiscalPrinter.FNGetDocumentSize: Integer;
begin
  Result := Send(#$FF#$75 + FPassw);
end;

procedure TFiscalPrinter.DecodeFF75(const Data: AnsiString);
begin
  CheckMinLength(Data, 8);
  // Размер в байтах текущего документа для ОФД
  DocumentSize := BinToInt(Data, 1, 4);
  // Размер в байтах текущего уведомления о реализации маркированных товаров для ОИСМ
  NotificationSize := BinToInt(Data, 5, 4);
end;

procedure TFiscalPrinter.DecodeFF76(const Data: AnsiString);
begin
  CheckMinLength(Data, 13);
  Change := BinToAmount(Data, 1, 5);
  DocumentNumber := BinToInt(Data, 6, 4);
  FiscalSign := BinToInt(Data, 10, 4);
end;

procedure TFiscalPrinter.DecodeFFF0(const Data: AnsiString);
begin
  DataBlock := Data;
  BlockDataHex := StrToHex(DataBlock);
end;

procedure TFiscalPrinter.DecodeFFF1(const Data: AnsiString);
begin
  DataBlock := Data;
  BlockDataHex := StrToHex(DataBlock);
end;

// Запрос поддержки ФН ОСУ
// возвращает FNOSUSupportStatus
// FF если не поддерживает
// 00 если поддерживает и ОСУ не активна (на чистом ФНе так будет)
// 01 если поддерживает и ОСУ активна (зафискалена с одним из этих новых битов)

function TFiscalPrinter.FNGetOSUSupportStatus: Integer;
begin
  FECode := $0F;
  Result := Send(#$FE#$0F#$02#$00#$00#$00);
end;

function TFiscalPrinter.FNCloseCheckEx3: Integer;
var
  Command: AnsiString;
begin
  try
    Command := #$FF#$76 + FPassw + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetSumm5 + GetSumm6 + GetSumm7 + GetSumm8 + GetSumm9 + GetSumm10 + GetSumm11 + GetSumm12 + GetSumm13 + GetSumm14 + GetSumm15 + GetSumm16 + AnsiChar(RoundingSumm) + GetTaxValue1 + GetTaxValue2 + GetTaxValue3 + GetTaxValue4 + GetTaxValue5 + GetTaxValue6 + GetTaxValue7 + GetTaxValue8 + GetTaxValue9 + GetTaxValue10 + AnsiChar(TaxType) + Copy(GetPrintString, 1, 64);

    Result := SendAuth(Command);
    DrvCloseCheck;
    // WaitForPrinting;
{$IFDEF dkkt}
{$IFDEF usealtlogger}
    FAltLogger.Debug('FNCloseCheckEx3.Result = ' + IntToStr(Result));
{$ENDIF}
    if Result = 0 then
    begin
{$IFDEF usealtlogger}
      FAltLogger.Debug('FNCloseCheckEx3.LengthKI = ' + IntToStr(Length(FExKi)));
{$ENDIF}
      try
        if (Length(FExKi) > 0) and (CheckEcrToSubscript(FDkktSN)) then
        begin
          FRData.receipt_id := DocumentNumber;
          dkkt_server.receiptDataEvent(FDkktSN, FRData, FExKi);
          ClearKi;
        end;
      except
        on E: Exception do
        begin
          Logger.Error('DKKT Error: "' + E.Message + '"', E);
        end;
      end;
    end;
{$ENDIF}
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TFiscalPrinter.FNBuildCorrectionReceipt3: Integer;
begin
  try
    Result := SafeOpenSession;
    if Result <> 0 then
      Exit;
    Result := SendAuth(#$FF#$77 + FPassw + AnsiChar(CorrectionType) + AnsiChar(CalculationSign) + GetSumm1 + GetSumm2 + GetSumm3 + GetSumm4 + GetSumm5 + GetSumm6 + GetSumm7 + GetSumm8 + GetSumm9 + GetSumm10 + GetSumm11 + GetSumm12 + GetSumm13 + GetSumm14 + GetSumm15 + GetSumm16 + AnsiChar(TaxType));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

(*
  Команды шифрования и дешифрования 0x78 и 0x79 соответственно. Формат одинаковый.
  3 варианта выполнения:
  Запись данных в буфер шифрования/дешифрования:
  2 байта - смещение
  X байт - данные
  Возвращается успешное/неуспешное завершение, без данных.
  Шифрование/дешифрование:
  Команда без данных
  При успешном завершении возвращается длина зашифрованных/дешифрованных данных, 2 байта.
  Чтение результата:
  2 байта смещение.
  Возвращаются данные результата выполнения.

  Примеры команд шифрования/расшифровки которые поддерживаем ФР:

  Отправить данные:
  FF 78 | 1E 00 00 00 | 00 00 | 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF
  Зашифровать данные:
  FF 78 | 1E 00 00 00
  Прочитать данные:
  FF 78 | 1E 00 00 00 | 00 00
  Для дешифрования то же самое, но только FF 79

  Если надо  отправить большой объем данных, то в несколько команд:
  Отправить данные:
  FF 78 | 1E 00 00 00 | 00 00 | 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF ....
  FF 78 | 1E 00 00 00 | 80 00 | 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF ....
  FF 78 | 1E 00 00 00 | 00 01 | 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF ....
  ....
  Зашифровать данные (длина зашифрованного в ответе, 2 байта):
  FF 78 | 1E 00 00 00
  Прочитать данные:
  FF 78 | 1E 00 00 00 | 00 00
  FF 78 | 1E 00 00 00 | 80 00
  FF 78 | 1E 00 00 00 | 00 10
  ...


*)

function TFiscalPrinter.FNEncryptData: Integer;
var
  Command: AnsiString;
begin
  Command := #$FF#$78 + FPassw;
  Result := SendCommand(Command);
end;

function TFiscalPrinter.FNEncryptWriteData: Integer;
var
  Command: AnsiString;
begin
  Command := #$FF#$78 + FPassw + IntToBin(DataOffset, 2) + HexToStr(BlockDataHex);
  Result := SendCommand(Command);
end;

function TFiscalPrinter.FNEncryptReadData: Integer;
var
  Command: AnsiString;
begin
  Command := #$FF#$78 + FPassw + IntToBin(DataOffset, 2);
  Result := SendCommand(Command);
end;

function TFiscalPrinter.FNDecryptData: Integer;
begin
  Result := SendCommand(#$FF#$79 + FPassw);
end;

function TFiscalPrinter.FNDecryptReadData: Integer;
var
  Command: AnsiString;
begin
  Command := #$FF#$79 + FPassw + IntToBin(DataOffset, 2);
  Result := SendCommand(Command);
end;

function TFiscalPrinter.FNDecryptWriteData: Integer;
var
  Command: AnsiString;
begin
  Command := #$FF#$79 + FPassw + IntToBin(DataOffset, 2) + HexToStr(BlockDataHex);
  Result := SendCommand(Command);
end;

function TFiscalPrinter.GetEncryptPassword(var Password: AnsiString): Integer;
const
  SUPER_PASSWORD = #$F4#$F3#$F2#$F1;
begin
  Result := 0;
  if FEncryptPassword = '' then
  begin
    Result := GetECRStatus;
    if Result <> 0 then Exit;

    FEncryptPassword := FPassw;
    if (ECRSoftVersion = 'T.3') and (ECRBuild >= 7283) then
      FEncryptPassword := SUPER_PASSWORD;

    Exit;
  end;
  Password := FEncryptPassword;
end;

function TFiscalPrinter.FNEncryptData2: Integer;
var
  Count: Integer;
  Proto: AnsiChar;
  Data: AnsiString;
  Command: AnsiString;
  PasswordBin: AnsiString;
begin
  Result := GetEncryptPassword(PasswordBin);
  if Result <> 0 then Exit;

  Proto := #$01;
  if RequestType <> 1 then
    Proto := #$02;

  Data := HexToStr(BlockDataHex);
  Count := Length(Data) mod 16;
  if Count <> 0 then
  begin
    Data := Data + StringOfChar(AnsiChar(#0), 16 - Count);
  end;

  Command := #$FF#$F0 + PasswordBin + Proto + '00' + Data;
  Result := SendCommand(Command);
end;

function TFiscalPrinter.FNDecryptData2: Integer;
var
  Count: Integer;
  Proto: AnsiChar;
  Data: AnsiString;
  Command: AnsiString;
  PasswordBin: AnsiString;
begin
  Result := GetEncryptPassword(PasswordBin);
  if Result <> 0 then Exit;

  Proto := #$01;
  if RequestType <> 1 then
    Proto := #$02;

  Data := HexToStr(BlockDataHex);
  Count := Length(Data) mod 16;
  if Count <> 0 then
  begin
    Data := Data + StringOfChar(AnsiChar(#0), 16 - Count);
  end;

  Command := #$FF#$F1 + PasswordBin + Proto + '00' + Data;
  Result := SendCommand(Command);
end;

end.

