unit Vittee.RecordArray;

interface

uses
  TypInfo, RTTI, SysUtils, Classes;

type
  IRecordArray<T> = interface
    ['{8B71B837-E9F6-40B0-AFFB-882F436F287B}']
    procedure SetLength(const Value: Integer);
    function GetElement(Index: Integer): T;
    function GetData: T;
    function GetLength: Integer;
    function ElementSize: Integer;
    function DataSize: Integer;
    procedure Wipe;
    //
    procedure Append(AOther: IRecordArray<T>);
    //
    property Length: Integer read GetLength write SetLength;
    property Data: T read GetData;
    property Elements[Index: Integer]: T read GetElement; default;
  end;

  TRecordArray<T> = class(TInterfacedObject, IRecordArray<T>)
  private
    FPtr: Pointer;
    FData: T;
    FElementSize: Integer;
    FDataSize: Integer;
    FLength: Integer;
    procedure SetLength(const Value: Integer);
    function GetElement(Index: Integer): T;
    function GetData: T;
    function GetLength: Integer;
  public
    constructor Create(ALength: Integer);
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
  end;

implementation

{ TRecordArray<T> }

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

constructor TRecordArray<T>.Create(ALength: Integer);
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
    FElementSize := RttiType.ReferredType.TypeSize;
  end;

  FData := default(T);
  FPtr := nil;
  SetLength(ALength);
end;

function TRecordArray<T>.DataSize: Integer;
begin
  Result := FDataSize;
end;

destructor TRecordArray<T>.Destroy;
begin
  if FPtr <> nil then
  begin
    FreeMem(FPtr);
  end;

  inherited;
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
