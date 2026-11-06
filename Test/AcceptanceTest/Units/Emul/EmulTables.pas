unit EmulTables;

interface

uses
  Classes, SysUtils;

type
  TEmulFieldDef = record
    Table: Integer;
    Row: Integer;
    Field: Integer;
    Size: Integer;
    FieldType: Integer;
    MinValue: Int64;
    MaxValue: Int64;
    Name: string;
    Value: string;
  end;

  TEmulTableDef = record
    Number: Integer;
    Name: string;
    RowCount: Integer;
    FieldCount: Integer;
  end;

  { TEmulTables }

  TEmulTables = class
  private
    FFields: TList;
    FTables: TList;
    FHeader: TStringList;
    function GetFieldCount: Integer;
    function GetField(Index: Integer): TEmulFieldDef;
    function GetTableCount: Integer;
    function GetTable(Index: Integer): TEmulTableDef;
    function FieldKey(Table, Row, Field: Integer): string;
    function FindFieldIndex(Table, Row, Field: Integer): Integer;
    procedure RebuildTableDefs;
    function ParseCsvString(const Text: string; Number: Integer): string;
    procedure AddFieldFromLine(const Line: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromFile(const FileName: string);
    function FindTable(TableNumber: Integer): TEmulTableDef;
    function ReadFieldValue(Table, Row, Field: Integer): string;
    procedure WriteFieldValue(Table, Row, Field: Integer; const Value: string);
    function ReadFieldDef(Table, Row, Field: Integer; out Def: TEmulFieldDef): Boolean;
    property Header: TStringList read FHeader;
    property FieldCount: Integer read GetFieldCount;
    property Fields[Index: Integer]: TEmulFieldDef read GetField;
    property TableCount: Integer read GetTableCount;
    property Tables[Index: Integer]: TEmulTableDef read GetTable;
  end;

implementation

type
  PEmulFieldDef = ^TEmulFieldDef;
  PEmulTableDef = ^TEmulTableDef;

function IsQuote(C: Char): Boolean;
begin
  Result := (C = '"') or (C = '''');
end;

{ TEmulTables }

constructor TEmulTables.Create;
begin
  inherited Create;
  FFields := TList.Create;
  FTables := TList.Create;
  FHeader := TStringList.Create;
end;

destructor TEmulTables.Destroy;
var
  i: Integer;
begin
  Clear;
  FFields.Free;
  FTables.Free;
  FHeader.Free;
  inherited Destroy;
end;

procedure TEmulTables.Clear;
var
  i: Integer;
begin
  for i := 0 to FFields.Count - 1 do
    Dispose(FFields[i]);
  FFields.Clear;
  for i := 0 to FTables.Count - 1 do
    Dispose(FTables[i]);
  FTables.Clear;
  FHeader.Clear;
end;

function TEmulTables.FieldKey(Table, Row, Field: Integer): string;
begin
  Result := Format('%d:%d:%d', [Table, Row, Field]);
end;

function TEmulTables.ParseCsvString(const Text: string; Number: Integer): string;
var
  i: Integer;
  Count: Integer;
  InText: Boolean;
  StartPos: Integer;
  EndPos: Integer;
begin
  Result := '';
  Count := 1;
  StartPos := 1;
  InText := False;
  EndPos := Length(Text);
  for i := 1 to Length(Text) do
  begin
    if Text[i] = ',' then
    begin
      if not InText then
      begin
        Inc(Count);
        if Count = Number then
          StartPos := i + 1;
        if Count = (Number + 1) then
          EndPos := i - 1;
      end;
    end;
    if IsQuote(Text[i]) then
      InText := not InText;
  end;
  Result := Copy(Text, StartPos, EndPos - StartPos + 1);
  if (Result <> '') and IsQuote(Result[1]) and IsQuote(Result[Length(Result)]) then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

procedure TEmulTables.AddFieldFromLine(const Line: string);
var
  Def: PEmulFieldDef;
  Value: string;
begin
  New(Def);
  try
    Def^.Table := StrToInt(ParseCsvString(Line, 1));
    Def^.Row := StrToInt(ParseCsvString(Line, 2));
    Def^.Field := StrToInt(ParseCsvString(Line, 3));
    Def^.Size := StrToInt(ParseCsvString(Line, 4));
    Def^.FieldType := StrToInt(ParseCsvString(Line, 5));
    Def^.MinValue := StrToInt64(ParseCsvString(Line, 6));
    Def^.MaxValue := StrToInt64(ParseCsvString(Line, 7));
    Def^.Name := ParseCsvString(Line, 8);
    Value := ParseCsvString(Line, 9);
    Def^.Value := Value;
    FFields.Add(Def);
  except
    Dispose(Def);
    raise;
  end;
end;

procedure TEmulTables.RebuildTableDefs;
var
  i, j: Integer;
  Def: PEmulFieldDef;
  Table: PEmulTableDef;
  TableNumber: Integer;
  Found: Boolean;
begin
  for i := 0 to FTables.Count - 1 do
    Dispose(FTables[i]);
  FTables.Clear;

  for i := 0 to FFields.Count - 1 do
  begin
    Def := FFields[i];
    Found := False;
    for j := 0 to FTables.Count - 1 do
    begin
      Table := FTables[j];
      if Table^.Number = Def^.Table then
      begin
        Found := True;
        if Def^.Row > Table^.RowCount then
          Table^.RowCount := Def^.Row;
        if Def^.Field > Table^.FieldCount then
          Table^.FieldCount := Def^.Field;
        Break;
      end;
    end;
    if not Found then
    begin
      New(Table);
      Table^.Number := Def^.Table;
      Table^.Name := Format('Table %d', [Def^.Table]);
      Table^.RowCount := Def^.Row;
      Table^.FieldCount := Def^.Field;
      FTables.Add(Table);
    end;
  end;

  for i := 0 to FTables.Count - 1 do
  begin
    Table := FTables[i];
    TableNumber := Table^.Number;
    for j := 0 to FHeader.Count - 1 do
    begin
      if Pos(Format('// %d', [TableNumber]), FHeader[j]) > 0 then
      begin
        Table^.Name := Trim(Copy(FHeader[j], Pos(',', FHeader[j]) + 1, MaxInt));
        Break;
      end;
    end;
  end;
end;

procedure TEmulTables.LoadFromFile(const FileName: string);
var
  Lines: TStringList;
  i: Integer;
  Line: string;
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('File not found: %s', [FileName]);
  Clear;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    for i := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[i]);
      if Line = '' then
        Continue;
      if Copy(Line, 1, 2) = '//' then
      begin
        if Copy(Line, 1, 3) = '///' then
          FHeader.Add(Copy(Line, 5, MaxInt));
        Continue;
      end;
      AddFieldFromLine(Line);
    end;
    RebuildTableDefs;
  finally
    Lines.Free;
  end;
end;

function TEmulTables.GetFieldCount: Integer;
begin
  Result := FFields.Count;
end;

function TEmulTables.GetField(Index: Integer): TEmulFieldDef;
begin
  Result := PEmulFieldDef(FFields[Index])^;
end;

function TEmulTables.GetTableCount: Integer;
begin
  Result := FTables.Count;
end;

function TEmulTables.GetTable(Index: Integer): TEmulTableDef;
begin
  Result := PEmulTableDef(FTables[Index])^;
end;

function TEmulTables.FindFieldIndex(Table, Row, Field: Integer): Integer;
var
  i: Integer;
  Def: PEmulFieldDef;
begin
  Result := -1;
  for i := 0 to FFields.Count - 1 do
  begin
    Def := FFields[i];
    if (Def^.Table = Table) and (Def^.Row = Row) and (Def^.Field = Field) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

function TEmulTables.FindTable(TableNumber: Integer): TEmulTableDef;
var
  i: Integer;
  Table: PEmulTableDef;
  Found: Boolean;
begin
  Found := False;
  for i := 0 to FTables.Count - 1 do
  begin
    Table := FTables[i];
    if Table^.Number = TableNumber then
    begin
      Result := Table^;
      Found := True;
      Exit;
    end;
  end;
  if not Found then
    raise Exception.CreateFmt('Table %d not found', [TableNumber]);
end;

function TEmulTables.ReadFieldValue(Table, Row, Field: Integer): string;
var
  Index: Integer;
begin
  Index := FindFieldIndex(Table, Row, Field);
  if Index < 0 then
    Result := ''
  else
    Result := PEmulFieldDef(FFields[Index])^.Value;
end;

procedure TEmulTables.WriteFieldValue(Table, Row, Field: Integer; const Value: string);
var
  Index: Integer;
begin
  Index := FindFieldIndex(Table, Row, Field);
  if Index < 0 then
    raise Exception.CreateFmt('Field %d.%d.%d not found', [Table, Row, Field]);
  PEmulFieldDef(FFields[Index])^.Value := Value;
end;

function TEmulTables.ReadFieldDef(Table, Row, Field: Integer; out Def: TEmulFieldDef): Boolean;
var
  Index: Integer;
begin
  Index := FindFieldIndex(Table, Row, Field);
  Result := Index >= 0;
  if Result then
    Def := PEmulFieldDef(FFields[Index])^;
end;

end.
