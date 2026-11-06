unit EmulFNState;

interface

uses
  SysUtils, FptrTypes, EmulBinUtils;

type
  TEmulFNDocument = record
    DocNumber: Cardinal;
    FiscalSign: Cardinal;
    DocType: Byte;
    SessionNumber: Word;
    ReceiptNumber: Word;
    Data: AnsiString;
  end;

  TEmulFNState = class
  private
    FDocuments: array of TEmulFNDocument;
    FDocCount: Integer;
    FReceiptTotal: Int64;
    FReceiptOpened: Boolean;
    FCheckType: Byte;
    FTLVBuffer: AnsiString;
    FDataBuffer: AnsiString;
    FDataBlockSize: Integer;
    FRandomSequence: AnsiString;
    FNotificationCount: Word;
    FNotificationNumber: Cardinal;
    FNotificationSize: Word;
    FNotificationOffset: Word;

    function NextDocNumber: Cardinal;
    function NextFiscalSign: Cardinal;
    function BuildDateTime5(Device: TObject): AnsiString;
    function PadRight(const S: AnsiString; Len: Integer): AnsiString;
    function RequireOperator(Device: TObject; const Data: AnsiString;
      out Operator: Integer): AnsiString;
    function OkOnly: AnsiString;
    function OkOperator(Operator: Integer): AnsiString;
    function CloseCheckResult(Total, CashPay: Int64): AnsiString;
    procedure SaveDocument(DocType: Byte; SessionNum: Word; ReceiptNum: Word);
    function FindDocument(DocNum: Cardinal; out Doc: TEmulFNDocument): Boolean;
  public
    LifeState: Byte;
    CurrentDocument: Byte;
    DocumentData: Byte;
    SessionState: Byte;
    WarningFlags: Byte;
    FNSerial: AnsiString;
    SoftVersion: AnsiString;
    SoftType: Byte;
    INN: AnsiString;
    KKTRegNumber: AnsiString;
    TaxType: Byte;
    WorkMode: Byte;
    WorkModeEx: Byte;
    SessionNumber: Word;
    ReceiptNumber: Word;
    DocumentNumber: Cardinal;
    FiscalSign: Cardinal;
    ExpirationDay: Byte;
    ExpirationMonth: Byte;
    ExpirationYear: Byte;
    FreeRegistration: Byte;
    RegNumber: Byte;
    UnconfirmedDocCount: Cardinal;
    InfoExchangeStatus: Byte;
    MessageState: Byte;
    MessageCount: Word;
    FN5YearResource: Cardinal;
    FN30DayResource: Cardinal;
    FNImplementation: AnsiString;

    constructor Create;
    procedure Reset;
    procedure SyncFromDevice(Device: TObject);
    procedure OnLegacySessionOpen;
    procedure OnLegacySessionClose;
    procedure OnLegacyReceiptOpen(RecType: Integer);
    procedure OnLegacyReceiptClosed(Total: Int64);
    function ExecuteCommand(Code: Integer; Device: TObject;
      const Data: AnsiString): AnsiString;
  end;

implementation

uses
  PrinterEmulator;

function EmulDevice(Device: TObject): TPrinterEmulator;
begin
  Result := TPrinterEmulator(Device);
end;

constructor TEmulFNState.Create;
begin
  Reset;
end;

procedure TEmulFNState.Reset;
begin
  LifeState := $03;
  CurrentDocument := 0;
  DocumentData := 0;
  SessionState := 0;
  WarningFlags := 0;
  FNSerial := '0289610204000839';
  SoftVersion := 'FN 1.2.0       ';
  SoftType := 1;
  INN := '1234567890  ';
  KKTRegNumber := '00000000000000000000';
  TaxType := 1;
  WorkMode := 0;
  WorkModeEx := 0;
  SessionNumber := 1;
  ReceiptNumber := 0;
  DocumentNumber := 1;
  FiscalSign := $12345678;
  ExpirationDay := 31;
  ExpirationMonth := 12;
  ExpirationYear := 30;
  FreeRegistration := 16;
  RegNumber := 1;
  UnconfirmedDocCount := 0;
  InfoExchangeStatus := 0;
  MessageState := 0;
  MessageCount := 0;
  FN5YearResource := 3000;
  FN30DayResource := 256;
  FNImplementation := 'FN-1.2';
  FReceiptTotal := 0;
  FReceiptOpened := False;
  FCheckType := 0;
  FTLVBuffer := '';
  FDataBuffer := '';
  FDataBlockSize := 64;
  FRandomSequence := #0#1#2#3#4#5#6#7#8#9#10#11#12#13#14#15;
  FDocCount := 0;
  SetLength(FDocuments, 0);
  FNotificationCount := 0;
  FNotificationNumber := 0;
  FNotificationSize := 0;
  FNotificationOffset := 0;
end;

procedure TEmulFNState.SyncFromDevice(Device: TObject);
var
  Dev: TPrinterEmulator;
begin
  Dev := EmulDevice(Device);
  if Dev.Serial.Valid then
    FNSerial := PadRight(IntToStr(Dev.Serial.Number), 16);
end;

procedure TEmulFNState.OnLegacySessionOpen;
begin
  SessionState := 1;
  LifeState := LifeState or $02;
end;

procedure TEmulFNState.OnLegacySessionClose;
begin
  SessionState := 0;
  Inc(SessionNumber);
  ReceiptNumber := 0;
end;

procedure TEmulFNState.OnLegacyReceiptOpen(RecType: Integer);
begin
  FReceiptOpened := True;
  FReceiptTotal := 0;
  FCheckType := RecType;
  CurrentDocument := 1;
end;

procedure TEmulFNState.OnLegacyReceiptClosed(Total: Int64);
begin
  FReceiptOpened := False;
  Inc(ReceiptNumber);
  SaveDocument(FCheckType + 1, SessionNumber, ReceiptNumber);
  FReceiptTotal := 0;
  CurrentDocument := 0;
end;

function TEmulFNState.NextDocNumber: Cardinal;
begin
  Result := DocumentNumber;
  Inc(DocumentNumber);
end;

function TEmulFNState.NextFiscalSign: Cardinal;
begin
  Result := FiscalSign;
  Inc(FiscalSign);
end;

function TEmulFNState.PadRight(const S: AnsiString; Len: Integer): AnsiString;
begin
  Result := Copy(S, 1, Len);
  if Length(Result) < Len then
    Result := Result + StringOfChar(' ', Len - Length(Result));
end;

function TEmulFNState.BuildDateTime5(Device: TObject): AnsiString;
var
  Dev: TPrinterEmulator;
begin
  Dev := EmulDevice(Device);
  Result := AnsiChar(Dev.Date.Year) +
    AnsiChar(Dev.Date.Month) +
    AnsiChar(Dev.Date.Day) +
    AnsiChar(Dev.Time.Hour) +
    AnsiChar(Dev.Time.Min);
end;

function TEmulFNState.RequireOperator(Device: TObject;
  const Data: AnsiString; out Operator: Integer): AnsiString;
var
  Dev: TPrinterEmulator;
begin
  Dev := EmulDevice(Device);
  if Length(Data) < 4 then
  begin
    Result := AnsiChar(FPTR_E_INVALID_CMD_LEN);
    Operator := 0;
    Exit;
  end;
  Operator := Dev.FindOperator(BinToInt(Data, 1, 4), 0);
  Result := '';
end;

function TEmulFNState.OkOnly: AnsiString;
begin
  Result := #$00;
end;

function TEmulFNState.OkOperator(Operator: Integer): AnsiString;
begin
  Result := #$00 + AnsiChar(Operator);
end;

function TEmulFNState.CloseCheckResult(Total, CashPay: Int64): AnsiString;
var
  Change: Int64;
  DocNum: Cardinal;
  Sign: Cardinal;
begin
  if CashPay >= Total then
    Change := CashPay - Total
  else
    Change := 0;
  DocNum := NextDocNumber;
  Sign := NextFiscalSign;
  SaveDocument(FCheckType + 1, SessionNumber, ReceiptNumber + 1);
  Inc(ReceiptNumber);
  FReceiptOpened := False;
  FReceiptTotal := 0;
  CurrentDocument := 0;
  Result := #$00 +
    IntToBin(Change, 5) +
    IntToBin(DocNum, 4) +
    IntToBin(Sign, 4);
end;

procedure TEmulFNState.SaveDocument(DocType: Byte; SessionNum: Word;
  ReceiptNum: Word);
begin
  if FDocCount >= Length(FDocuments) then
    SetLength(FDocuments, FDocCount + 16);
  FDocuments[FDocCount].DocNumber := DocumentNumber - 1;
  FDocuments[FDocCount].FiscalSign := FiscalSign - 1;
  FDocuments[FDocCount].DocType := DocType;
  FDocuments[FDocCount].SessionNumber := SessionNum;
  FDocuments[FDocCount].ReceiptNumber := ReceiptNum;
  FDocuments[FDocCount].Data := FTLVBuffer;
  Inc(FDocCount);
end;

function TEmulFNState.FindDocument(DocNum: Cardinal;
  out Doc: TEmulFNDocument): Boolean;
var
  i: Integer;
begin
  for i := 0 to FDocCount - 1 do
  begin
    if FDocuments[i].DocNumber = DocNum then
    begin
      Doc := FDocuments[i];
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function TEmulFNState.ExecuteCommand(Code: Integer; Device: TObject;
  const Data: AnsiString): AnsiString;
var
  Dev: TPrinterEmulator;
  Operator: Integer;
  Doc: TEmulFNDocument;
  DocNum: Cardinal;
  CashPay: Int64;
  ItemAmount: Int64;
  TagNum: Word;
begin
  Dev := EmulDevice(Device);
  SyncFromDevice(Device);
  case Code of
    $FF01:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      SessionState := 1;
      Result := #$00 +
        AnsiChar(LifeState) +
        AnsiChar(CurrentDocument) +
        AnsiChar(DocumentData) +
        AnsiChar(SessionState) +
        AnsiChar(WarningFlags) +
        BuildDateTime5(Device) +
        PadRight(FNSerial, 16) +
        IntToBin(DocumentNumber, 4);
    end;

    $FF02:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + PadRight(FNSerial, 16);
    end;

    $FF03:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        AnsiChar(ExpirationYear) +
        AnsiChar(ExpirationMonth) +
        AnsiChar(ExpirationDay) +
        AnsiChar(FreeRegistration) +
        AnsiChar(RegNumber);
    end;

    $FF04:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + Copy(PadRight(SoftVersion, 16), 1, 16) + AnsiChar(SoftType);
    end;

    $FF05, $FF07, $FF08, $FF35, $FF37, $FF3D, $FF41, $FF42, $FF4D, $FF4E,
    $FF62, $FF64, $FF66, $FF73:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOnly;
    end;

    $FF06, $FF34, $FF3E:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF09, $FF4C:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        BuildDateTime5(Device) +
        PadRight(INN, 12) +
        PadRight(KKTRegNumber, 20) +
        AnsiChar(TaxType) +
        AnsiChar(WorkMode) +
        AnsiChar(WorkModeEx) +
        PadRight('', 12) +
        IntToBin(0, 4) +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF0A:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) < 8 then
      begin
        Result := AnsiChar(FPTR_E_INVALID_CMD_LEN);
        Exit;
      end;
      DocNum := BinToInt(Data, 5, 4);
      if FindDocument(DocNum, Doc) then
        Result := #$00 + AnsiChar(Doc.DocType) + #1 + Doc.Data
      else
        Result := #$00 + #1#0;
    end;

    $FF0B:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Dev.OpenSession(BinToInt(Data, 1, 4));
      SessionState := 1;
      Result := #$00 +
        IntToBin(SessionNumber, 2) +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF0C:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) > 4 then
        FTLVBuffer := FTLVBuffer + Copy(Data, 5, Length(Data));
      Result := OkOnly;
    end;

    $FF0D, $FF44, $FF46:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      FReceiptOpened := True;
      if Length(Data) >= 1 then
        FCheckType := Ord(Data[5]);
      if Length(Data) >= 22 then
        ItemAmount := BinToInt(Data, 17, 5)
      else
        ItemAmount := 0;
      if ItemAmount = 0 then
        ItemAmount := 100;
      Inc(FReceiptTotal, ItemAmount);
      CurrentDocument := 1;
      Result := OkOperator(Operator);
    end;

    $FF0E:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 7 then
      begin
        TagNum := BinToInt(Data, 5, 2);
        if TagNum = $FFFF then
          Result := OkOnly
        else
          Result := #$00 + FTLVBuffer;
      end else
        Result := OkOnly;
    end;

    $FF16:
      Result := OkOnly;

    $FF1A:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + AnsiChar(Operator) + StringOfChar(#0, 48);
    end;

    $FF30:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + IntToBin(Length(FDataBuffer), 2) + AnsiChar(FDataBlockSize);
    end;

    $FF31:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 7 then
        Result := #$00 + Copy(FDataBuffer, BinToInt(Data, 5, 2) + 1,
          BinToInt(Data, 7, 1))
      else
        Result := #$00 + FDataBuffer;
    end;

    $FF32:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 6 then
        SetLength(FDataBuffer, BinToInt(Data, 5, 2));
      Result := #$00 + AnsiChar(FDataBlockSize);
    end;

    $FF33:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 7 then
        FDataBuffer := Copy(FDataBuffer, 1, BinToInt(Data, 5, 2)) +
          Copy(Data, 8, BinToInt(Data, 7, 1));
      Result := OkOnly;
    end;

    $FF36, $FF4A:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Inc(ReceiptNumber);
      Result := #$00 +
        IntToBin(ReceiptNumber, 2) +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF38:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(DocumentNumber, 4) +
        IntToBin(FiscalSign, 4) +
        IntToBin(UnconfirmedDocCount, 4) +
        AnsiChar(Dev.Date.Year) +
        AnsiChar(Dev.Date.Month) +
        AnsiChar(Dev.Date.Day);
    end;

    $FF39:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        AnsiChar(InfoExchangeStatus) +
        AnsiChar(MessageState) +
        IntToBin(MessageCount, 2) +
        IntToBin(DocumentNumber, 4) +
        BuildDateTime5(Device);
    end;

    $FF3A:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + IntToBin(1, 2) + IntToBin(Length(FTLVBuffer), 2);
    end;

    $FF3B:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + FTLVBuffer;
    end;

    $FF3C:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + BuildDateTime5(Device) +
        PadRight('OFD-TICKET-DATA', 18) +
        IntToBin(DocumentNumber, 4);
    end;

    $FF3F:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + IntToBin(UnconfirmedDocCount, 2);
    end;

    $FF40:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        AnsiChar(SessionState) +
        IntToBin(SessionNumber, 2) +
        IntToBin(ReceiptNumber, 2);
    end;

    $FF43:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      OnLegacySessionClose;
      Result := #$00 +
        IntToBin(SessionNumber, 2) +
        IntToBin(NextDocNumber, 4) +
        IntToBin(NextFiscalSign, 4);
    end;

    $FF45, $FF76:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      CashPay := 0;
      if Length(Data) >= 9 then
        CashPay := BinToInt(Data, 5, 5);
      if FReceiptTotal <= 0 then
        FReceiptTotal := CashPay;
      Result := CloseCheckResult(FReceiptTotal, CashPay);
    end;

    $FF4B:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOperator(Operator);
    end;

    $FF50:
    begin
      if Length(Data) < 4 then
        Result := OkOnly
      else
        Result := OkOnly;
    end;

    $FF51:
      Result := #$00 + #0#0 + IntToBin(0, 5) + #0;

    $FF52:
      Result := #$00;

    $FF53:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOnly;
    end;

    $FF61, $FF67:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + #0#1#0#0;
    end;

    $FF63:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(FN5YearResource, 4) +
        IntToBin(FN30DayResource, 4);
    end;

    $FF65:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + FRandomSequence;
    end;

    $FF68:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        AnsiChar(MessageState) +
        IntToBin(MessageCount, 2) +
        IntToBin(FNotificationNumber, 4) +
        BuildDateTime5(Device) +
        #0;
    end;

    $FF69:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      if Length(Data) >= 5 then
        Result := OkOnly
      else
        Result := #$00 + #0;
    end;

    $FF70:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + #1#0#$FF#0#0#0 + IntToBin(MessageCount, 2);
    end;

    $FF71:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(FNotificationCount, 2) +
        IntToBin(FNotificationNumber, 4) +
        IntToBin(FNotificationSize, 2);
    end;

    $FF72:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 +
        IntToBin(FNotificationNumber, 4) +
        IntToBin(FNotificationSize, 2) +
        IntToBin(FNotificationOffset, 2) +
        IntToBin(0, 2);
    end;

    $FF74:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + PadRight(FNImplementation, 48);
    end;

    $FF75:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := #$00 + IntToBin(Length(FTLVBuffer), 4) + IntToBin(0, 4);
    end;

    $FF77, $FF78, $FF79, $FFF0, $FFF1:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOnly;
    end;

    $FF47, $FF48, $FF49, $FF4F, $FF54, $FF55, $FF56, $FF57, $FF58, $FF59,
    $FF5A, $FF5B, $FF5C, $FF5D, $FF5E, $FF5F, $FF60, $FF6A, $FF6B, $FF6C,
    $FF6D, $FF6E, $FF6F:
    begin
      Result := RequireOperator(Device, Data, Operator);
      if Result <> '' then Exit;
      Result := OkOperator(Operator);
    end;
  else
    Result := AnsiChar(FPTR_E_CMD_NOT_SUPPORT);
  end;
end;

end.
