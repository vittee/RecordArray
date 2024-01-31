unit Vittee.RecordArray;

interface

uses
  TypInfo, RTTI, SysUtils, Classes;

type
  {$SCOPEDENUMS ON}
  TEndianness = (Little, Big);

  IRecordArray<T> = interface
    ['{8B71B837-E9F6-40B0-AFFB-882F436F287B}']
    procedure SetLength(const Value: Integer);
    function GetElement(Index: Integer): T;
    function GetData: T;
    function GetLength: Integer;
    function GetEndianness: TEndianness;
    function ElementSize: Integer;
    function DataSize: Integer;
    procedure Wipe;
    //
    procedure Append(AOther: IRecordArray<T>);
    //
    property Length: Integer read GetLength write SetLength;
    property Data: T read GetData;
    property Elements[Index: Integer]: T read GetElement; default;
    property Endianness: TEndianness read GetEndianness;
  end;

  TRecordArray<T> = class(TInterfacedObject, IRecordArray<T>)
  private
    FPtr: Pointer;
    FOwned: Boolean;
    FData: T;
    FElementSize: Integer;
    FDataSize: Integer;
    FLength: Integer;
    FEndianness: TEndianness;

    procedure SetLength(const Value: Integer);
    function GetElement(Index: Integer): T;
    function GetData: T;
    function GetLength: Integer;
    function GetEndianness: TEndianness;
  public
    class function GetElementSize: Integer;

    constructor Create(ALength: Integer; AEndianness: TEndianness = TEndianness.Little); overload;
    constructor Create(APointer: T; ALength: Integer; AEndianness: TEndianness = TEndianness.Little); overload;

    destructor Destroy; override;
    //
    procedure Append(AOther: IRecordArray<T>);
    function ElementSize: Integer;
    function DataSize: Integer;
    procedure Wipe;
    //
    property Length: Integer read GetLength write SetLength;
    property Data: T read GetData;
    property Elements[Index: Integer]: T read GetElement; default;
    property Endianness: TEndianness read GetEndianness;
  end;

implementation

{ TRecordArray<T> }

class function TRecordArray<T>.GetElementSize: Integer;
var
  Info: PTypeInfo;
  RttiType: TRttiPointerType;
begin
  Info := TypeInfo(T);

  if (Info.Kind = tkPointer) and (Info.TypeData.RefType  = nil) then
  begin
    raise EInvalidPointer.CreateFmt('%s is not a typed pointer', [Info.Name]);
  end else
  if Info.Kind <> tkPointer then
  begin
    raise EInvalidOperation.CreateFmt('%s is not a pointer', [Info.Name]);
  end;

  with TRttiContext.Create do
  begin
    RttiType := TRttiPointerType(GetType(Info));
    Exit(RttiType.ReferredType.TypeSize);
  end;
end;


function TRecordArray<T>.GetEndianness: TEndianness;
begin
  Result := FEndianness;
end;

constructor TRecordArray<T>.Create(ALength: Integer; AEndianness: TEndianness = TEndianness.Little);
begin
  FElementSize := GetElementSize;
  FData := default(T);
  FOwned := True;
  FPtr := nil;
  FEndianness := AEndianness;
  SetLength(ALength);
end;

constructor TRecordArray<T>.Create(APointer: T; ALength: Integer; AEndianness: TEndianness = TEndianness.Little);
begin
  FElementSize := GetElementSize;
  FOwned := False;
  FLength := ALength;
  FDataSize := FElementSize * ALength;
  FPtr := PPointer(@APointer)^;
  FData := APointer;
  FEndianness := AEndianness;
end;

function TRecordArray<T>.DataSize: Integer;
begin
  Result := FDataSize;
end;

destructor TRecordArray<T>.Destroy;
begin
  if FOwned and (FPtr <> nil) then
  begin
    FreeMem(FPtr);
  end;

  inherited;
end;

procedure TRecordArray<T>.Append(AOther: IRecordArray<T>);
var
  Other: TRecordArray<T>;
  JointIndex: Integer;
  Joint: T;
begin
  Other := AOther as TRecordArray<T>;
  JointIndex := Length;
  Length := Length + Other.Length;
  Joint := Self[Length];
  //
  Move(Pointer(Other.FPtr)^, PPointer(@Joint)^, Other.FDataSize);
end;


function TRecordArray<T>.ElementSize: Integer;
begin
  Result := FElementSize;
end;

function TRecordArray<T>.GetData: T;
begin
  Result := FData;
end;

function TRecordArray<T>.GetElement(Index: Integer): T;
begin
  PPointer(@Result)^ := Pointer(NativeInt(FPtr) + Index * FElementSize);
end;

function TRecordArray<T>.GetLength: Integer;
begin
  Result := FLength;
end;

procedure TRecordArray<T>.SetLength(const Value: Integer);
begin
  if not FOwned then
    raise EInvalidOperation.Create('Could not set length, the memory was created by an external source');

  if FLength = Value then
    Exit;

  FLength := Value;
  FDataSize := FElementSize * Value;

  if FPtr = nil then
  begin
    FPtr := AllocMem(FDataSize);
  end else
  begin
    ReallocMem(FPtr, FDataSize);
  end;

  PPointer(@FData)^ := FPtr;
end;

procedure TRecordArray<T>.Wipe;
begin
  FillChar(FPtr^, FDataSize, 0);
end;

end.


