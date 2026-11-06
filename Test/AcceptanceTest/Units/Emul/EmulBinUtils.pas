unit EmulBinUtils;

interface

uses
  Windows, SysUtils;

function Min(V1, V2: Integer): Integer;
function IntToBin(Value, Count: Int64): AnsiString;
function BinToInt(const S: AnsiString; Index, Count: Integer): Int64;

implementation

function Min(V1, V2: Integer): Integer;
begin
  if V1 < V2 then
    Result := V1
  else
    Result := V2;
end;

function BinToInt(const S: AnsiString; Index, Count: Integer): Int64;
var
  N: Integer;
begin
  Result := 0;
  if (Index > 0) and (Index <= Length(S)) then
  begin
    N := Min(Length(S) - Index + 1, 8);
    if Count <= N then
      Move(S[Index], Result, Count);
  end;
end;

function IntToBin(Value, Count: Int64): AnsiString;
begin
  Result := '';
  if Count in [1..8] then
  begin
    SetLength(Result, Count);
    Move(Value, Result[1], Count);
  end;
end;

end.
