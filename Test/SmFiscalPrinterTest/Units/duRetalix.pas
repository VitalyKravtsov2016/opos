unit duRetalix;

interface

uses
  // VCL
  Windows, SysUtils,
  // DUnit
  TestFramework,
  // This
  FileUtils, Retalix, RegExpr, MalinaParams, DriverContext;

type
  { TRetalixTest }

  TRetalixTest = class(TTestCase)
  private
    Context: TDriverContext;
  protected
    procedure Setup; override;
    procedure Teardown; override;
    function GetDBPath: string;
  published
    procedure CheckOpen;
    procedure CheckReadTaxGroup;
    procedure CheckReadTaxGroup2;
    procedure CheckParseOperator;
    procedure CheckParseItemName;
    procedure CheckParseCashierName;
    procedure CheckReplaceOperator;
  end;

implementation

{ TRetalixTest }

procedure TRetalixTest.Setup;
begin
  Context := TDriverContext.Create;
end;

procedure TRetalixTest.Teardown;
begin
  Context.Free;
end;

function TRetalixTest.GetDBPath: string;
begin
  //Result := 'c:\positive\datapdx\';
  Result := GetModulePath + 'Retalix';
end;

procedure TRetalixTest.CheckReadTaxGroup;
begin
  // DBPath must exists!
  if not DirectoryExists(GetDBPath) then Exit;

  Context.MalinaParams.RetalixSearchCI := False;

  CheckEquals(4, RetalixReadTaxGroup(GetDBPath, '���  4   : ��-95-�5           ', Context), '��-95-�5');
  CheckEquals(-1, RetalixReadTaxGroup(GetDBPath, '���  4   : ��-95-�5', Context), '��-95-�5');
  CheckEquals(1, RetalixReadTaxGroup(GetDBPath, '��� ������ 5��', Context));
  CheckEquals(2, RetalixReadTaxGroup(GetDBPath, '����� ������� 5 ��', Context));
  CheckEquals(4, RetalixReadTaxGroup(GetDBPath, '��� 120 �� �������', Context));

  Context.MalinaParams.RetalixSearchCI := True;
  CheckEquals(4, RetalixReadTaxGroup(GetDBPath, '���  4   : ��-95-�5', Context), '��-95-�5');
end;

procedure TRetalixTest.CheckReadTaxGroup2;
var
  RetalixDB: TRetalix;
begin
  // DBPath must exists!
  if not DirectoryExists(GetDBPath) then Exit;

  RetalixDB := TRetalix.Create(GetDBPath, Context);
  try
    RetalixDB.Open;
    CheckEquals(1, RetalixDB.ReadTaxGroup('��� ������ 5��'));
    CheckEquals(2, RetalixDB.ReadTaxGroup('����� ������� 5 ��'));
    CheckEquals(4, RetalixDB.ReadTaxGroup('��� 120 �� �������'));
    CheckEquals(2, RetalixDB.ReadTaxGroup('ERNO''S'));
  finally
    RetalixDB.Free;
  end;
end;

procedure TRetalixTest.CheckParseCashierName;
var
  Cashier: string;
begin
  Check(TRetalix.ParseCashierName('��������: ts ID:    3945140', Cashier));
  CheckEquals('ts', Cashier);
  Check(TRetalix.ParseCashierName('��������:tS ID:    3945140', Cashier));
  CheckEquals('tS', Cashier);
  Check(TRetalix.ParseCashierName('��������:tS ID:    3945140', Cashier));
  CheckEquals('tS', Cashier);
  Check(TRetalix.ParseCashierName('��������:tS ', Cashier));
  CheckEquals('tS', Cashier);
  Check(TRetalix.ParseCashierName('��������:tS', Cashier));
  CheckEquals('tS', Cashier);
end;

procedure TRetalixTest.CheckParseOperator;
var
  Text: string;
  Cashier: string;
  Retalix: TRetalix;
begin
  // DBPath must exists!
  if not DirectoryExists(GetDBPath) then Exit;

  Retalix := TRetalix.Create(GetDBPath, Context);
  try
    Retalix.Open;

    Text := '��������: ������ ���';
    Check(Retalix.ParseOperator(Text, Cashier));
    CheckEquals('������� ����� ������ �����', Cashier);

    Text := '��������:  ������ ����� ID: 723645';
    Check(Retalix.ParseOperator(Text, Cashier));
    CheckEquals('������� ����� ������ �����', Cashier);

    Text := '��������:��������  ';
    Check(Retalix.ParseOperator(Text, Cashier));
    CheckEquals('����������� ��� ������� ��������', Cashier);

    Text := '��������: ���������� �.�.';
    Check(Retalix.ParseOperator(Text, Cashier));
    CheckEquals('������ ���������� �.�.', Cashier);

    Text := '��������: ���������� �.�.';
    Check(Retalix.ParseOperator(Text, Cashier));
    CheckEquals('������ ���������� �.�.', Cashier);
  finally
    Retalix.Free;
  end;
end;


procedure TRetalixTest.CheckParseItemName;
begin
  CheckEquals('��-95-�5', TRetalix.ParseItemName('���  4   : ��-95-�5           '));
  CheckEquals('��-95-�5', TRetalix.ParseItemName('��� 4:��-95-�5               ���1449'));
  CheckEquals('��-95-�5', TRetalix.ParseItemName('��� 4:��-95-�5               ���1449'));
  CheckEquals('�������� �������', TRetalix.ParseItemName('�������� �������'));
  CheckEquals('Coca-cola light 0.5�', TRetalix.ParseItemName('Coca-cola light 0.5�'));
end;

procedure TRetalixTest.CheckReplaceOperator;
var
  Line: string;
  Cashier: string;
begin
  Cashier := '������ ������';
  Line := '��������:ts ID:    3945140';
  Line := TRetalix.ReplaceOperator(Line, Cashier);
  CheckEquals('������ ������ ID:    3945140', Line);

  Cashier := '������ ������';
  Line := '��������:  ts ';
  Line := TRetalix.ReplaceOperator(Line, Cashier);
  CheckEquals('������ ������', Line);

  Cashier := '������ ������';
  Line := '��������:ts';
  Line := TRetalix.ReplaceOperator(Line, Cashier);
  CheckEquals('������ ������', Line);
end;

procedure TRetalixTest.CheckOpen;
var
  i: Integer;
  Retalix: TRetalix;
begin
  // DBPath must exists!
  if not DirectoryExists(GetDBPath) then Exit;

  Retalix := TRetalix.Create(GetDBPath, Context);
  try
    for i := 1 to 3 do
    begin
      Retalix.Open;
      Retalix.Close;
    end;
  finally
    Retalix.Free;
  end;
end;

{$IFDEF MALINA}
initialization
  RegisterTest('', TRetalixTest.Suite);
{$ENDIF}

end.
