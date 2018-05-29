unit duElectronicJournal;

interface

uses
  // VCL
  Windows, SysUtils, Classes,
  // DUnit
  TestFramework,
  // This
  ElectronicJournal;

type
  { ElectronicJournal }

  TElectronicJournalTest = class(TTestCase)
  published
    procedure CheckDecodeDateLine;
  end;

implementation

{ TElectronicJournalTest }

procedure TElectronicJournalTest.CheckDecodeDateLine;
var
  Data: WideString;
  Result1: WideString;
  Result2: WideString;
begin
  Data := '����.��. 0162 13/08/08  11:22 ��������30 ';
  Result1 := TElectronicJournal.DecodeDateLine(Data);
  Result2 := '130820081122';
  Check(Result1 = Result2, Format('"%s" <> "%s"', [Result1, Result2]));
end;

initialization
  RegisterTest('', TElectronicJournalTest.Suite);

end.
