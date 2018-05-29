unit MalinaReceipt;

interface

uses
  // VCL
  Classes, SysUtils,
  // Tnt
  TntSysUtils, TntClasses;

type
  { TMalinaParamsRec }

  TMalinaParamsRec = record
    SaleText: WideString;         // ����������� ������
    CardPrefix: WideString;       // ����� �����:
    MalinaCoeff: Double;      // �����������
    MalinaPoints: Integer;    // ���������� ������
  end;

  { TMalinaReceipt }

  TMalinaReceipt = class
  public
    class function CreateReceipt(const Params: TMalinaParamsRec): WideString;
  end;

implementation

{ TMalinaReceipt }

class function TMalinaReceipt.CreateReceipt(const Params: TMalinaParamsRec): WideString;
var
  Line: WideString;
  Points: Integer;
  Lines: TTntStrings;
begin
  Lines := TTntStringList.Create;
  try
    Lines.Add('     �� ����������� (��� 009)       ');
    Lines.Add('  ��� "���-�� �������� �������"     ');
    Lines.Add('  �������� ��., 2, ���. 332-72-56   ');
    Lines.Add('                                    ');
    Lines.Add('��� 00019976 ��� 007802411512  #8552');
    Lines.Add('22.08.10 23:14                      ');
    Lines.Add('�������                        �1283');
    Lines.Add('��� 4: ������ 95          ���  41457');
    Lines.Add('                      23.59 X 51.710');
    Lines.Add('1                           =1219.84');

    Line := Copy(Params.CardPrefix, 1, 20);
    Line := Line + StringOfChar(' ', 20 - Length(Line));
    Lines.Add(Line + '6393000039070330');

    Lines.Add('------------------------------------');
    Lines.Add('�������:                     1219.84');

    Line := Copy(Params.SaleText, 1, 36);
    Lines.Add(Line);
    Lines.Add('� ����� ������:     6393000039070330');

    Points := 0;
    if Params.MalinaCoeff <> 0 then
      Points := Trunc(1219.84/Params.MalinaCoeff)*Params.MalinaPoints;

    Line := Tnt_WideFormat('��������� %d ������', [Points]);
    Lines.Add(Line);
    Lines.Add('                                    ');
    Lines.Add('��������: ������� �.�. ID: 254889   ');
    Lines.Add('����                        =1219.84');
    Lines.Add('���������                   =1500.00');
    Lines.Add('�����                        =280.16');
    Lines.Add('------------ �� --------------------');
    Lines.Add('                     ���� 0670467138');
    Lines.Add('                    00102672 #056284');
    Lines.Add('       ������� �������              ');
    Lines.Add('     �������� ����� ����            ');

    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

(*
     �� ����������� (��� 009)
  ��� "���-�� �������� �������"
  �������� ��., 2, ���. 332-72-56

��� 00019976 ��� 007802411512  #8552
22.08.10 23:14
�������                        �1283
��� 4: ������ 95          ���  41457
                      23.59 X 51.710
1                           =1219.84
����� �����:        6393000039070330
------------------------------------
�������:                     1219.84
- 1.5%
������                        =18.30
����������� ������
1                             =18.30

��������: ������� �.�. ID: 254889
����                        =1219.84
���������                   =1500.00
�����                        =280.16
------------ �� --------------------
                     ���� 0670467138
                    00102672 #056284
       ������� �������
     �������� ����� ����

*)

end.

