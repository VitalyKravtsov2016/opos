unit ReceiptFormat;

interface

uses
  // VCL
  Windows, SysUtils,
  // This
  PrinterTypes;

type
  { TReceiptFormatItem }

  TReceiptFormatItem = record
    Line: Integer;
    Offset: Integer;
    Width: Integer;
    Alignment: Integer;
    Name: string;
  end;

  { TReceiptFormat }

  TReceiptFormat = record
    Enabled: Boolean;
    TextItem: TReceiptFormatItem;            // ������������ � ��������
    QuantityItem: TReceiptFormatItem;        // ���������� X ���� � ��������
    DepartmentItem: TReceiptFormatItem;      // ������ � ��������
    AmountItem: TReceiptFormatItem;          // ��������� � ��������
    StornoItem: TReceiptFormatItem;          // ������� ������ � ��������
    DscText: TReceiptFormatItem;             // ����� � ������
    DscName: TReceiptFormatItem;             // ������� ������
    DscAmount: TReceiptFormatItem;           // ����� ������
    CrgText: TReceiptFormatItem;             // ����� � ��������
    CrgName: TReceiptFormatItem;             // ������� ��������
    CrgAmount: TReceiptFormatItem;           // ����� ��������
    DscStornoText: TReceiptFormatItem;       // ����� � ������ ������
    DscStornoName: TReceiptFormatItem;       // ������� ������ ������
    DscStornoAmount: TReceiptFormatItem;     // ����� ������ ������
    CrgStornoText: TReceiptFormatItem;       // ����� � ������ ��������
    CrgStornoName: TReceiptFormatItem;       // ������� ������ ��������
    CrgStornoAmount: TReceiptFormatItem;     // ����� ������ ��������
  end;

implementation

end.
