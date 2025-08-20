unit UNamedMatrix;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  System.Classes, System.StrUtils;

//  Tfunc<>

type
  TNamedMatrix<T> = class
  private
    FData: TArray<TArray<T>>;
    FRows, FCols: Integer;

    // Ordered lists for name-by-index
    FRowNames: TList<string>;
    FColNames: TList<string>;

    // Fast lookup name -> index
    FRowIndex: TDictionary<string, Integer>;
    FColIndex: TDictionary<string, Integer>;

    function GetItem(Row, Col: Integer): T;
    procedure SetItem(Row, Col: Integer; const Value: T);
    function GetByName(const RowName, ColName: string): T;
    procedure SetByName(const RowName, ColName: string; const Value: T);
    procedure CheckBounds(Row, Col: Integer);
    procedure Rename(var Names: TList<string>;
                     var Index: TDictionary<string,Integer>;
                     Idx: Integer; const NewName: string);
  public
    constructor Create; overload;
    constructor Create(Rows, Cols: Integer); overload;
    destructor Destroy; override;

    procedure SetSize(Rows, Cols: Integer);
    procedure WriteToCSV(const fName: string;
       const CellToString: TFunc<T, string>; const IncludeRowNames: Boolean = True);

    function AddRow(const Name: string = ''): Integer;
    function AddCol(const Name: string = ''): Integer;

    procedure SetRowName(Index: Integer; const Name: string);
    procedure SetColName(Index: Integer; const Name: string);
    function IndexOfRow(const Name: string): Integer;
    function IndexOfCol(const Name: string): Integer;

    property Rows: Integer read FRows;
    property Cols: Integer read FCols;

    // numeric indexing
    property Items[Row, Col: Integer]: T read GetItem write SetItem; default;
    // named indexing
    property Values[const RowName, ColName: string]: T
             read GetByName write SetByName;

    property RowNames: TList<string> read FRowNames;
    property ColNames: TList<string> read FColNames;
  end;

  TNamedMatrixDoubleHelper = class helper for TNamedMatrix<Double>
    procedure WriteToCSV_Double(const fName: string; const IncludeRowNames: Boolean = True);
  end;


  function CsvEscape(const S: string): string;

  function MyFloatToStr(Value: double):string;


implementation


{ TNamedMatrix<T> }

constructor TNamedMatrix<T>.Create;
begin
  inherited;
  FRowNames := TList<string>.Create;
  FColNames := TList<string>.Create;
  FRowIndex := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
  FColIndex := TDictionary<string, Integer>.Create(TIStringComparer.Ordinal);
end;

constructor TNamedMatrix<T>.Create(Rows, Cols: Integer);
begin
  Create;
  SetSize(Rows, Cols);
end;

destructor TNamedMatrix<T>.Destroy;
begin
  FRowIndex.Free;
  FColIndex.Free;
  FRowNames.Free;
  FColNames.Free;
  inherited;
end;

procedure TNamedMatrix<T>.CheckBounds(Row, Col: Integer);
begin
  if (Row < 0) or (Row >= FRows) or (Col < 0) or (Col >= FCols) then
    raise EArgumentOutOfRangeException.CreateFmt(
      'Index out of range: row=%d col=%d (size %dx%d)', [Row, Col, FRows, FCols]);
end;

function TNamedMatrix<T>.GetItem(Row, Col: Integer): T;
begin
  CheckBounds(Row, Col);
  Result := FData[Row][Col];
end;

procedure TNamedMatrix<T>.SetItem(Row, Col: Integer; const Value: T);
begin
  CheckBounds(Row, Col);
  FData[Row][Col] := Value;
end;

function TNamedMatrix<T>.GetByName(const RowName, ColName: string): T;
var r, c: Integer;
begin
  if not FRowIndex.TryGetValue(RowName, r) then
//    raise EDictionaryError.CreateFmt('Unknown row name "%s"', [RowName]);
//  raise EDictionaryError.CreateFmt('Unknown row name "%s"', [RowName]);
  raise EListError.CreateFmt('Unknown row name "%s"', [RowName]);


  if not FColIndex.TryGetValue(ColName, c) then
//    raise EDictionaryError.CreateFmt('Unknown column name "%s"', [ColName]);
  raise EListError.CreateFmt('Unknown row name "%s"', [RowName]);
  Result := GetItem(r, c);
end;

procedure TNamedMatrix<T>.SetByName(const RowName, ColName: string; const Value: T);
var r, c: Integer;
begin
  if not FRowIndex.TryGetValue(RowName, r) then
 //   raise EKeyNotFoundException.CreateFmt('Unknown row name "%s"', [RowName]);
  raise EListError.CreateFmt('Unknown row name "%s"', [RowName]);
  if not FColIndex.TryGetValue(ColName, c) then
 //   raise EKeyNotFoundException.CreateFmt('Unknown column name "%s"', [ColName]);
  raise EListError.CreateFmt('Unknown row name "%s"', [RowName]);
  SetItem(r, c, Value);
end;

procedure TNamedMatrix<T>.SetSize(Rows, Cols: Integer);
var
  r: Integer;
begin
  if (Rows < 0) or (Cols < 0) then
    raise EArgumentException.Create('Rows/Cols must be >= 0');

  // resize outer dimension, preserve existing
  SetLength(FData, Rows);
  for r := 0 to Rows - 1 do
    SetLength(FData[r], Cols);

  // adjust counters
  FRows := Rows;
  FCols := Cols;

  // keep name lists in sync with sizes
  while FRowNames.Count < FRows do FRowNames.Add('');
  while FRowNames.Count > FRows do begin
    if (FRowNames.Last <> '') then FRowIndex.Remove(FRowNames.Last);
    FRowNames.Delete(FRowNames.Count - 1);
  end;

  while FColNames.Count < FCols do FColNames.Add('');
  while FColNames.Count > FCols do begin
    if (FColNames.Last <> '') then FColIndex.Remove(FColNames.Last);
    FColNames.Delete(FColNames.Count - 1);
  end;
end;

function TNamedMatrix<T>.AddRow(const Name: string): Integer;
begin
  SetSize(FRows + 1, FCols);
  Result := FRows - 1;
  if Name <> '' then SetRowName(Result, Name);
end;

function TNamedMatrix<T>.AddCol(const Name: string): Integer;
begin
  SetSize(FRows, FCols + 1);
  Result := FCols - 1;
  if Name <> '' then SetColName(Result, Name);
end;

procedure TNamedMatrix<T>.Rename(var Names: TList<string>;
  var Index: TDictionary<string, Integer>; Idx: Integer; const NewName: string);
begin
  if (Idx < 0) or (Idx >= Names.Count) then
    raise EArgumentOutOfRangeException.Create('Name index out of range');

  // remove old mapping if present
  if Names[Idx] <> '' then
    Index.Remove(Names[Idx]);

  if NewName <> '' then begin
    if Index.ContainsKey(NewName) then
      raise EArgumentException.CreateFmt('Duplicate name "%s"', [NewName]);
    Index.Add(NewName, Idx);
  end;

  Names[Idx] := NewName;
end;

procedure TNamedMatrix<T>.SetRowName(Index: Integer; const Name: string);
begin
  Rename(FRowNames, FRowIndex, Index, Name);
end;

procedure TNamedMatrix<T>.SetColName(Index: Integer; const Name: string);
begin
  Rename(FColNames, FColIndex, Index, Name);
end;

function TNamedMatrix<T>.IndexOfRow(const Name: string): Integer;
begin
  if not FRowIndex.TryGetValue(Name, Result) then
    Result := -1;
end;

function TNamedMatrix<T>.IndexOfCol(const Name: string): Integer;
begin
  if not FColIndex.TryGetValue(Name, Result) then
    Result := -1;
end;



function CsvEscape(const S: string): string;
var
  T: string;
begin
  T := S;
  if Pos('"', T) > 0 then
    T := StringReplace(T, '"', '""', [rfReplaceAll]);
  if (Pos(',', T) > 0) or (Pos(#10, T) > 0) or (Pos(#13, T) > 0) then
    Result := '"' + T + '"'
  else
    Result := T;
end;

procedure TNamedMatrix<T>.WriteToCSV(const fName: string;
  const CellToString: TFunc<T, string>; const IncludeRowNames: Boolean = True);
var
  W: TStreamWriter;
  i, j, Offset: Integer;
  Fields: TArray<string>;
begin
  if not Assigned(CellToString) then
    raise EArgumentNilException.Create('CellToString formatter is required');

  W := TStreamWriter.Create(fName, False, TEncoding.UTF8);
  try
    // Header
    Offset := Ord(IncludeRowNames);             // 1 if true, else 0
    SetLength(Fields, FCols + Offset);
    if IncludeRowNames then
      Fields[0] := '';                          // top-left blank (row-name header)
    for j := 0 to FCols - 1 do
      Fields[Offset + j] := CsvEscape(FColNames[j]);
    W.WriteLine(String.Join(',', Fields));

    // Rows
    for i := 0 to FRows - 1 do
    begin
      SetLength(Fields, FCols + Offset);
      if IncludeRowNames then
        Fields[0] := CsvEscape(FRowNames[i]);

      for j := 0 to FCols - 1 do
        Fields[Offset + j] := CsvEscape(CellToString(FData[i][j]));

      W.WriteLine(String.Join(',', Fields));
    end;
  finally
    W.Free;
  end;
end;


function MyFloatToStr(Value: double):string;
var
  Fmt: TFormatSettings;
begin
  Fmt := TFormatSettings.Create('en-US'); // decimal point = '.'
  Result := FloatToStr(Value, Fmt)
end;






procedure TNamedMatrixDoubleHelper.WriteToCSV_Double(const fName: string; const IncludeRowNames: Boolean);
var
  Fmt: TFormatSettings;
begin
  Fmt := TFormatSettings.Create('en-US'); // decimal point = '.'
  WriteToCSV(
    fName, function (V: Double): string
    begin
      Result := FloatToStr(V, Fmt);
    end,
    IncludeRowNames
  );
end;



end.
