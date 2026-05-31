unit untDriver;

interface

uses
  // VCL
  Classes, SysUtils, ActiveX, ComObj, Forms,
  // This
  DrvFRLib_TLB, DriverError, BinUtils;

type
  { TDriver }

  TDriver = class(TDrvFR)
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Check(AResultCode: Integer);

    function GetCapEJournal: Boolean;
    function CapJrnSensor: Boolean;
    function CapSKNO: Boolean;
    function CapJrnOpticalSensor: Boolean;
    function CapJrnLeverSensor: Boolean;
    function CapRecSensor: Boolean;
    function CapRecOpticalSensor: Boolean;
    function CapRecLeverSensor: Boolean;
    function CapSlpDocumentHiSensor: Boolean;
    function CapSlpDocumentLoSensor: Boolean;
    function CapCoverSensor: Boolean;
    function CapEKLZOverflowSensor: Boolean;
    function CapCashDrawerAsPresenter: Boolean;
    function CapTaxCalc: Boolean;
    function CapCashDrawerSensor: Boolean;
    function CapPrsPaperInSensor: Boolean;
    function CapPrsPaperOutSensor: Boolean;
    function CapPresenter: Boolean;
    function CapPresenterCommands: Boolean;
    function CapBillAcceptor: Boolean;
    function CapSlip: Boolean;
    function CapNonfiscalDocument: Boolean;
    function CapJournal: Boolean;
    function CapTaxKeyboard: Boolean;
    function CapCashCore: Boolean;
    function CapEJournal: Boolean;
    function CapCutterPresent: Boolean;
    function SwapLineBytes: Boolean;
    function TaxCalcField: Integer;
    function Font1Width: Integer;
    function Font2Width: Integer;
    function FirstDrawLine: Integer;
    function InnDigitCount: Integer;
    function RnmDigitCount: Integer;
    function LongRnmDigitCount: Integer;
    function LongSerialDigitCount: Integer;
    function DefaultTaxPassword: Integer;
    function DefaultSysPassword: Integer;
    function CapTaxPasswordLock: Boolean;
    function CapInnLeadingZeros: Boolean;
    function CapRnmLeadingZeros: Boolean;
    function CapAltProtocol: Boolean;
    function CapWrapNonFiscalString: Boolean;
    function CapWrapWithFontNonFiscapString: Boolean;
    function CapWrapFiscalString: Boolean;
    function CapWrapWithFontFiscalString: Boolean;
    function CapChiefCashier: Boolean;
    function CapLastPrintResult: Boolean;
    function CapLoadBlockGraphics: Boolean;
    function CapErrorDescription: Boolean;
    function CapPrintFlagsGraphics: Boolean;
    function FSTableNumber: Integer;
    function CapFN: Boolean;
    function MaxCmdLength: Integer;
    function MaxLineWidth: Integer;
    function IsModelType2: Boolean;
    function ReadIntParam(ParamID: Integer): Integer;
    function ReadBoolParam(ParamID: Integer): Boolean;
    procedure WriteTableInt(ATable, ARow, AField, AValue: Cardinal);
    procedure WriteTableStr(ATable, ARow, AField: Integer; const AValue: string);
    function ReadTableDef(ATableNumber, ARowNumber, AFieldNumber, ADefValue: Integer): Integer;
    function ReadTableInt(ATableNumber, ARowNumber, AFieldNumber: Integer): Integer;
    function ReadTableStr(ATableNumber, ARowNumber, AFieldNumber: Integer): string;
    function CorrectTableNumber(ANumber: Integer): Integer;
    procedure SendTagStr(ATag: Integer; const AValue: string);
    procedure SendTagUnixTime(ATag: Integer; const AValue: TDateTime);
    procedure SendTagStrOperation(ATag: Integer; const AValue: string);
    procedure SendTagUnixTimeOperation(ATag: Integer; const AValue: TDateTime);
    procedure BeginSTLVTag(ATag: Integer);
    procedure SendSTLVTag(ATag: Integer);
    procedure SendSTLVTagOperation(ATag: Integer);
    procedure AddTagStr(ATag: Integer; const AValue: string);
    procedure AddTagByte(ATag: Integer; const AValue: Byte);
    procedure AddTagUnixTime(ATag: Integer; const AValue: TDateTime);
    function AmountToStr(Value: Currency): string;
    function GetModelID: Integer;
    function GetPrintStringWidth(AFont: Integer = 0): Integer;
  end;


implementation

uses
  Windows;

resourcestring
  SDriverCreateFailed = 'Ошибка создания объекта драйвера: ';
  SCommandNotSupportedInMode = 'Команда не поддерживается в данном режиме';
  SCommandNotSupportedInSubMode = 'Команда не поддерживается в данном подрежиме';

function GetParamsFileName: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.dat');
end;

var
  FDriver: TDriver = nil;

procedure FreeDriver;
begin
  FDriver.Free;
  FDriver := nil;
end;

function DriverExists: Boolean;
begin
  Result := FDriver <> nil;
end;

function Driver: TDriver;
begin
  if FDriver = nil then
  try
    FDriver := TDriver.Create(nil);
  except
    on E: Exception do
    begin
      E.Message := SDriverCreateFailed + E.Message;
      raise;
    end;
  end;
  Result := FDriver;
end;

function DriverIsNil: Boolean;
begin
  Result := FDriver = nil;
end;

{ TDriver }

constructor TDriver.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TDriver.Destroy;
begin
  inherited Destroy;
end;

procedure TDriver.Check(AResultCode: Integer);
var
  Text: string;
begin
  if AResultCode = 0 then
    Exit;

  case AResultCode of
    $72:
      begin
        Text := SCommandNotSupportedInSubMode;
        if GetECRStatus = 0 then
          Text := Text + Format(' (%s)', [ECRAdvancedModeDescription]);
        raise EDriverError.Create2($72, Text);
      end;

    $73:
      begin
        Text := SCommandNotSupportedInMode;
        if GetECRStatus = 0 then
          Text := Text + Format(' (%s)', [ECRModeDescription]);
        raise EDriverError.Create2($73, Text);
      end;
  else
    raise EDriverError.Create2(AResultCode, ResultCodeDescription);
  end
end;

function TDriver.ReadTableDef(ATableNumber, ARowNumber, AFieldNumber, ADefValue: Integer): Integer;
begin
  RowNumber := ARowNumber;
  TableNumber := ATableNumber;
  FieldNumber := AFieldNumber;
  if ReadTable = 0 then
    Result := ValueOfFieldInteger
  else
    Result := ADefValue;
end;

function TDriver.ReadTableInt(ATableNumber, ARowNumber, AFieldNumber: Integer): Integer;
begin
  RowNumber := ARowNumber;
  TableNumber := CorrectTableNumber(ATableNumber);
  FieldNumber := AFieldNumber;
  Check(ReadTable);
  Result := ValueOfFieldInteger
end;

function TDriver.CorrectTableNumber(ANumber: Integer): Integer;
begin
  if ANumber = 18 then
  begin
    ModelParamNumber := mpFSTableNumber;
    Check(ReadModelParamValue);
    Result := ModelParamValue;
  end
  else if ANumber = 19 then
  begin
    ModelParamNumber := mpOFDTableNumber;
    Check(ReadModelParamValue);
    Result := ModelParamValue;
  end
  else
    Result := ANumber;
end;

function TDriver.ReadIntParam(ParamID: Integer): Integer;
begin
  ModelParamNumber := ParamID;
  Check(ReadModelParamValue);
  Result := StrToInt(ModelParamValue);
end;

function TDriver.ReadBoolParam(ParamID: Integer): Boolean;
begin
  ModelParamNumber := ParamID;
  Check(ReadModelParamValue);
  Result := ModelParamValue = True;
end;

function TDriver.GetCapEJournal: Boolean;
begin
  Result := ReadBoolParam(mpCapEJournal);
end;

procedure TDriver.AddTagByte(ATag: Integer; const AValue: Byte);
begin
  TagNumber := ATag;
  TagType := ttByte;
  TagValueInt := AValue;
  Check(FNAddTag);
end;

procedure TDriver.AddTagStr(ATag: Integer; const AValue: string);
begin
  TagNumber := ATag;
  TagType := ttString;
  TagValueStr := AValue;
  Check(FNAddTag);
end;

procedure TDriver.AddTagUnixTime(ATag: Integer; const AValue: TDateTime);
begin
  TagNumber := ATag;
  TagType := ttUnixTime;
  TagValueDateTime := AValue;
  Check(FNAddTag);
end;

function TDriver.AmountToStr(Value: Currency): string;
begin
  if PointPosition then
    Result := Format('%.2f', [Value])
  else
    Result := IntToStr(Trunc(Value));
end;

function TDriver.CapBillAcceptor: Boolean;
begin
  Result := ReadBoolParam(mpCapBillAcceptor);
end;

function TDriver.CapCashCore: Boolean;
begin
  Result := ReadBoolParam(mpCapCashCore);
end;

function TDriver.CapCashDrawerAsPresenter: Boolean;
begin
  Result := ReadBoolParam(mpCapCashDrawerAsPresenter);
end;

function TDriver.CapCashDrawerSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapCashDrawerSensor);
end;

function TDriver.CapCoverSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapCoverSensor);
end;

function TDriver.CapCutterPresent: Boolean;
begin
  Result := ReadBoolParam(mpCapCutterPresent);
end;

function TDriver.CapEJournal: Boolean;
begin
  Result := ReadBoolParam(mpCapEJournal);
end;

function TDriver.CapEKLZOverflowSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapEKLZOverflowSensor);
end;

function TDriver.CapJournal: Boolean;
begin
  Result := ReadBoolParam(mpCapJournal);
end;

function TDriver.CapJrnLeverSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapJrnLeverSensor);
end;

function TDriver.CapJrnOpticalSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapJrnOpticalSensor);
end;

function TDriver.CapJrnSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapJrnSensor);
end;

function TDriver.CapNonfiscalDocument: Boolean;
begin
  Result := ReadBoolParam(mpCapNonfiscalDocument);
end;

function TDriver.CapPresenter: Boolean;
begin
  Result := ReadBoolParam(mpCapPresenter);
end;

function TDriver.CapPresenterCommands: Boolean;
begin
  Result := ReadBoolParam(mpCapPresenterCommands);
end;

function TDriver.CapPrsPaperInSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapPrsPaperInSensor);
end;

function TDriver.CapPrsPaperOutSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapPrsPaperOutSensor);
end;

function TDriver.CapRecLeverSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapRecLeverSensor);
end;

function TDriver.CapRecOpticalSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapRecOpticalSensor);
end;

function TDriver.CapRecSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapRecSensor);
end;

function TDriver.CapSlip: Boolean;
begin
  Result := ReadBoolParam(mpCapSlip);
end;

function TDriver.CapSlpDocumentHiSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapSlpDocumentHiSensor);
end;

function TDriver.CapSlpDocumentLoSensor: Boolean;
begin
  Result := ReadBoolParam(mpCapSlpDocumentLoSensor);
end;

function TDriver.CapTaxCalc: Boolean;
begin
  Result := ReadBoolParam(mpCapTaxCalc);
end;

function TDriver.CapTaxKeyboard: Boolean;
begin
  Result := ReadBoolParam(mpCapTaxKeyboard);
end;

function TDriver.CapTaxPasswordLock: Boolean;
begin
  Result := ReadBoolParam(mpCapTaxPasswordLock);
end;

function TDriver.DefaultSysPassword: Integer;
begin
  Result := ReadIntParam(mpDefaultSysPassword);
end;

function TDriver.DefaultTaxPassword: Integer;
begin
  Result := ReadIntParam(mpDefaultTaxPassword);
end;

function TDriver.FirstDrawLine: Integer;
begin
  Result := ReadIntParam(mpFirstDrawLine);
end;

function TDriver.Font1Width: Integer;
begin
  Result := ReadIntParam(mpFont1Width);
end;

function TDriver.Font2Width: Integer;
begin
  Result := ReadIntParam(mpFont2Width);
end;

function TDriver.InnDigitCount: Integer;
begin
  Result := ReadIntParam(mpInnDigitCount);
end;

function TDriver.LongRnmDigitCount: Integer;
begin
  Result := ReadIntParam(mpLongRnmDigitCount);
end;

function TDriver.LongSerialDigitCount: Integer;
begin
  Result := ReadIntParam(mpLongSerialDigitCount);
end;

function TDriver.RnmDigitCount: Integer;
begin
  Result := ReadIntParam(mpRnmDigitCount);
end;

procedure TDriver.SendSTLVTag(ATag: Integer);
begin
  TagNumber := ATag;
  Check(FNSendSTLVTag);
end;

procedure TDriver.SendSTLVTagOperation(ATag: Integer);
begin
  TagNumber := ATag;
  Check(FNSendSTLVTagOperation);
end;

procedure TDriver.SendTagStr(ATag: Integer; const AValue: string);
begin
  TagNumber := ATag;
  TagType := ttString;
  TagValueStr := AValue;
  Check(FNSendTag);
end;

procedure TDriver.SendTagStrOperation(ATag: Integer; const AValue: string);
begin
  TagNumber := ATag;
  TagType := ttString;
  TagValueStr := AValue;
  Check(FNSendTagOperation);
end;

procedure TDriver.SendTagUnixTime(ATag: Integer; const AValue: TDateTime);
begin
  TagNumber := ATag;
  TagType := ttUnixTime;
  TagValueDateTime := AValue;
  Check(FNSendTag);
end;

procedure TDriver.SendTagUnixTimeOperation(ATag: Integer; const AValue: TDateTime);
begin
  TagNumber := ATag;
  TagType := ttUnixTime;
  TagValueDateTime := AValue;
  Check(FNSendTagOperation);
end;

function TDriver.SwapLineBytes: Boolean;
begin
  Result := ReadBoolParam(mpSwapLineBytes);
end;

function TDriver.TaxCalcField: Integer;
begin
  Result := ReadIntParam(mpTaxCalcField);
end;

procedure TDriver.BeginSTLVTag(ATag: Integer);
begin
  TagNumber := ATag;
  Check(FNBeginSTLVTag);
end;

function TDriver.CapAltProtocol: Boolean;
begin
  Result := ReadBoolParam(mpCapAltProtocol);
end;

function TDriver.CapChiefCashier: Boolean;
begin
  Result := ReadBoolParam(mpCapChiefCashier);
end;

function TDriver.CapErrorDescription: Boolean;
begin
  Result := ReadBoolParam(mpCapErrorDescription);
end;

function TDriver.CapInnLeadingZeros: Boolean;
begin
  Result := ReadBoolParam(mpCapInnLeadingZeros);
end;

function TDriver.CapLastPrintResult: Boolean;
begin
  Result := ReadBoolParam(mpCapLastPrintResult);
end;

function TDriver.CapLoadBlockGraphics: Boolean;
begin
  Result := ReadBoolParam(mpCapLoadBlockGraphics);
end;

function TDriver.CapRnmLeadingZeros: Boolean;
begin
  Result := ReadBoolParam(mpCapRnmLeadingZeros);
end;

function TDriver.CapWrapFiscalString: Boolean;
begin
  Result := ReadBoolParam(mpCapWrapFiscalString);
end;

function TDriver.CapWrapNonFiscalString: Boolean;
begin
  Result := ReadBoolParam(mpCapWrapNonFiscalString);
end;

function TDriver.CapWrapWithFontFiscalString: Boolean;
begin
  Result := ReadBoolParam(mpCapWrapWithFontFiscalString);
end;

function TDriver.CapWrapWithFontNonFiscapString: Boolean;
begin
  Result := ReadBoolParam(mpCapWrapWithFontNonFiscapString);
end;

function TDriver.MaxCmdLength: Integer;
begin
  Result := ReadIntParam(mpMaxCmdLength);
end;

function TDriver.MaxLineWidth: Integer;
begin
  Result := ReadIntParam(mpMaxLineWidth);
end;

function TDriver.CapPrintFlagsGraphics: Boolean;
begin
  Result := ReadBoolParam(mpCapPrintFlagsGraphics);
end;

function TDriver.CapSKNO: Boolean;
begin
  Result := ReadBoolParam(mpCapSKNO);
end;

function TDriver.CapFN: Boolean;
begin
  Result := ReadBoolParam(mpCapFN);
end;

function TDriver.IsModelType2: Boolean;
begin
  Result := ReadIntParam(mpModelID) in [16, 19, 20, 21, 27, 28, 29, 30, 32, 33, 34, 35, 36, {37,} 38, 39, 40, 41, 42, 45, 45, 45, 46];
end;

procedure TDriver.WriteTableInt(ATable, ARow, AField, AValue: Cardinal);
begin
  TableNumber := ATable;
  RowNumber := ARow;
  FieldNumber := AField;
  ValueOfFieldInteger := AValue;
  Check(WriteTable);
end;

procedure TDriver.WriteTableStr(ATable, ARow, AField: Integer;
  const AValue: string);
begin
  TableNumber := ATable;
  RowNumber := ARow;
  FieldNumber := AField;
  ValueOfFieldString := AValue;
  Check(WriteTable);
end;

function TDriver.FSTableNumber: Integer;
begin
  Result := ReadIntParam(mpFSTableNumber);
end;

function TDriver.ReadTableStr(ATableNumber, ARowNumber, AFieldNumber: Integer): string;
begin
  RowNumber := ARowNumber;
  TableNumber := CorrectTableNumber(ATableNumber);
  FieldNumber := AFieldNumber;
  Check(ReadTable);
  Result := ValueOfFieldString;
end;

function TDriver.GetModelID: Integer;
begin
  Result := ReadIntParam(mpModelID);
end;

function TDriver.GetPrintStringWidth(AFont: Integer): Integer;
var
  sPassword: Integer;
begin
  sPassword := Password;
  try
    Password := SysAdminPassword;
    FontType := AFont;
    Check(GetFontMetrics);
    if CharWidth <> 0 then
      Result := Trunc(PrintWidth / CharWidth)
    else
      Result := 40;
  finally
    Password := sPassword;
  end;
end;

end.

