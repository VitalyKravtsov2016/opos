unit BinUtils;

interface

uses
  // VCL
  Windows, SysUtils, Forms, Classes, Controls, Registry, Consts, ComObj, Math;

function StrToHex(const S: AnsiString): string;

function HexToStr(const Data: string): AnsiString;

procedure SetBit(var Value: Word; Bit: Byte);

function TestBit(Value, Bit: Integer): Boolean;

implementation

procedure SetBit(var Value: Word; Bit: Byte);
begin
  Value := Value or (1 shl Bit);
end;

function TestBit(Value, Bit: Integer): Boolean;
begin
  Result := (Value and (1 shl Bit)) <> 0;
end;


function StrToHex(const S: AnsiString): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    if i <> 1 then
      Result := Result + ' ';
    Result := Result + IntToHex(Ord(S[i]), 2);
  end;
end;

function HexToStr(const Data: string): AnsiString;
var
  S: string;
  i: Integer;
  V, Code: Integer;
begin
  S := '';
  Result := '';
  for i := 1 to Length(Data) do
  begin
    S := Trim(S + Data[i]);
    if (Length(S) <> 0) and ((Length(S) = 2) or (Data[i] = ' ')) then
    begin
      Val('$' + S, V, Code);
      if Code <> 0 then
        Exit;
      Result := Result + AnsiChar(V);
      S := '';
    end;
  end;
  // последний символ
  if Length(S) <> 0 then
  begin
    Val('$' + S, V, Code);
    if Code <> 0 then
      Exit;
    Result := Result + AnsiChar(V);
  end;
end;

end.

