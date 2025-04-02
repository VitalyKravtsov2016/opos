unit uZintBarcode;

interface

uses
  // VCL
  Windows, Classes, SysUtils, Graphics,
  // This
  uZintInterface;

type
  { TZintBarcode }

  TZintBarcode = class
  private
    FData: string;
    FScale: Single;
    FStacked: Boolean;
    FRotation: Integer;
    FSymbol: PZintSymbol;
    FOnChanged: TNotifyEvent;

    procedure CheckForError(AReturnValue: Integer);
    function ErrorTextFromSymbol: AnsiString;
    procedure SetData(const Value: AnsiString);
    procedure Changed;

    procedure FreeSymbol;
    procedure CreateSymbol;

    procedure SetType(const Value: Integer);
    procedure SetScale(const Value: Single);
    procedure SetHeight(const Value: Single);
    procedure SetBorderWidth(const Value: Integer);

    function GetType: Integer;
    function GetSHRT: Boolean;
    function GetHeight: Single;
    function GetData: AnsiString;
    function GetInputMode: Integer;
    function GetBarcodeSize: TPoint;
    function GetPrimary: AnsiString;
    function GetBorderWidth: Integer;
    function GetOutputOptions: Integer;
    function GetColor(const Index: Integer): TColor;
    function GetOption(const Index: Integer): Integer;

    procedure SetSHRT(const Value: Boolean);
    procedure SetStacked(const Value: Boolean);
    procedure SetRotation(const Value: Integer);
    procedure SetInputMode(const Value: Integer);
    procedure SetPrimary(const Value: AnsiString);
    procedure SetOutputOptions(const Value: Integer);
    procedure SetOption(const Index, Value: Integer);
    procedure SetColor(const Index: Integer; const Value: TColor);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure EncodeNow;

    property Symbol: PZintSymbol read FSymbol;
    property BarcodeSize: TPoint read GetBarcodeSize;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  published
    property Data: AnsiString read GetData write SetData;
    property Height: Single read GetHeight write SetHeight;
    property BarcodeType: Integer read GetType write SetType;
    property Scale: Single read FScale write SetScale stored true;
    property BorderWidth: Integer read GetBorderWidth write SetBorderWidth;
    property OutputOptions: Integer read GetOutputOptions write SetOutputOptions;
    property FGColor: TColor index 0 read GetColor write SetColor;
    property BGColor: TColor index 1 read GetColor write SetColor;
    property Option1: Integer index 1 read GetOption write SetOption;
    property Option2: Integer index 2 read GetOption write SetOption;
    property Option3: Integer index 3 read GetOption write SetOption;
    property Rotation: Integer read FRotation write SetRotation;
    property Primary: AnsiString read GetPrimary write SetPrimary;
    property ShowHumanReadableText: Boolean read GetSHRT write SetSHRT;
    property Stacked: Boolean read FStacked write SetStacked;
    property InputMode: Integer read GetInputMode write SetInputMode;
  end;

  EZintError = type Exception;

implementation

{ TZintBarcode }

constructor TZintBarcode.Create;
begin
  inherited Create;
  CreateSymbol;

  FScale := 1;
  FStacked := false;
  FSymbol.show_hrt := 0;
  FSymbol.input_mode := DATA_MODE;
  FRotation := 0;
  Data := '123456789';
end;

procedure TZintBarcode.Changed;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TZintBarcode.CheckForError(AReturnValue: Integer);
begin
  if AReturnValue >= ZINT_ERROR then
    raise EZintError.Create(ErrorTextFromSymbol);
end;

procedure TZintBarcode.Clear;
begin
  if Assigned(FSymbol) then
  begin
    ZBarcode_Clear(FSymbol);
    FSymbol := nil;
  end;
end;

procedure TZintBarcode.CreateSymbol;
begin
  FSymbol := nil;
  FSymbol := ZBarcode_Create;
  if not Assigned(FSymbol) then
    raise EZintError.Create('Can not create internal symbol structure');
end;

destructor TZintBarcode.Destroy;
begin
  FreeSymbol;
  inherited Destroy;
end;

procedure TZintBarcode.FreeSymbol;
begin
  if Assigned(FSymbol) then
  begin
    ZBarcode_Delete(FSymbol);
    FSymbol := nil;
  end;
end;

procedure TZintBarcode.EncodeNow;
begin
  CheckForError(ZBarcode_Encode_and_Buffer(FSymbol, PByte(FData), Length(FData), rotation));
end;

function TZintBarcode.ErrorTextFromSymbol: AnsiString;
begin
  Result := FSymbol.errtxt;
end;

function TZintBarcode.GetBarcodeSize: TPoint;
begin
  Result := Point(FSymbol.bitmap_width, FSymbol.bitmap_height);
end;

function TZintBarcode.GetBorderWidth: Integer;
begin
  Result := FSymbol.border_width;
end;

function TZintBarcode.GetColor(const Index: Integer): TColor;
var
  S: AnsiString;
begin
  case Index of
    0: S := FSymbol.fgcolour;
    1: S := FSymbol.bgcolour;
  end;

  Result := StrToInt('$' + S);
end;

function TZintBarcode.GetData: AnsiString;
begin
  Result := FData;
end;

function TZintBarcode.GetHeight: Single;
begin
  Result := FSymbol.height;
end;

function TZintBarcode.GetInputMode: Integer;
begin
  Result := FSymbol.input_mode;
end;

function TZintBarcode.GetOption(const Index: Integer): Integer;
begin
  case Index of
    1: Result := FSymbol.option_1;
    2: Result := FSymbol.option_2;
    3: Result := FSymbol.option_3;
    else
      Result := 0;
  end;
end;

function TZintBarcode.GetOutputOptions: Integer;
begin
  Result := FSymbol.output_options;
end;

function TZintBarcode.GetPrimary: AnsiString;
begin
  Result := StrPas(PAnsiChar(@FSymbol.primary));
end;

function TZintBarcode.GetSHRT: Boolean;
begin
  Result := FSymbol.show_hrt = 1;
end;

function TZintBarcode.GetType: Integer;
begin
  Result := FSymbol.symbology;
end;

procedure TZintBarcode.SetBorderWidth(const Value: Integer);
begin
  FSymbol.border_width := Value;
  Changed;
end;

procedure TZintBarcode.SetColor(const Index: Integer; const Value: TColor);
var
  S: AnsiString;
begin
  S := Format('%.6x', [ColorToRGB(Value)]);
  case Index of
    0: StrPCopy(@FSymbol.fgcolour, S);
    1: StrPCopy(@FSymbol.bgcolour, S);
  end;

  Changed;
end;

procedure TZintBarcode.SetData(const Value: AnsiString);
begin
  FData := Value;
  Changed;
end;

procedure TZintBarcode.SetHeight(const Value: Single);
begin
  FSymbol.height := Value;
  Changed;
end;

procedure TZintBarcode.SetInputMode(const Value: Integer);
begin
  FSymbol.input_mode := Integer(Value);
  Changed;
end;

procedure TZintBarcode.SetOption(const Index, Value: Integer);
begin
  case Index of
    1: FSymbol.option_1 := Value;
    2: FSymbol.option_2 := Value;
    3: FSymbol.option_3 := Value;
  end;
end;

procedure TZintBarcode.SetOutputOptions(const Value: Integer);
begin
  FSymbol.output_options := Value;
  Changed;
end;

procedure TZintBarcode.SetPrimary(const Value: AnsiString);
begin
  StrPCopy(@FSymbol.primary, Value);
  Changed;
end;

procedure TZintBarcode.SetRotation(const Value: Integer);
begin
  FRotation := Value;
  Changed;
end;

procedure TZintBarcode.SetScale(const Value: Single);
begin
  FScale := Value;
  Changed;
end;

procedure TZintBarcode.SetSHRT(const Value: Boolean);
begin
  if Value then
    FSymbol.show_hrt := 1
  else
    FSymbol.show_hrt := 0;

  Changed;
end;

procedure TZintBarcode.SetStacked(const Value: Boolean);
begin
  FStacked := Value;
  Changed;
end;

procedure TZintBarcode.SetType(const Value: Integer);
begin
  FSymbol.symbology := Value;
  Changed;
end;

end.
