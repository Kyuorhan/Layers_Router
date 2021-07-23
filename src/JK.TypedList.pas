unit JK.TypedList;

interface

uses
  System.RTTI,
  System.Classes,
  // superobject,
  System.Generics.Collections,
  System.SysUtils,
  System.TypInfo;

type

  ITypedList = interface
    ['{80A44F93-6CE4-42FE-806B-1DB54A115F5A}']
    function Add(const Value: TObject): Integer;
    procedure Clear;
    function Count: Integer;
    function GetItem(Index: Integer): TObject;
  end;

  TJKTypedList = class;

  TJKObjectStatus = (osDirty = 0, osClean, osUnknown, osDeleted);

  EJKException = class(Exception)

  end;

  EJKValidationException = class(EJKException)

  end;

  TJKEnvironment = (JKeDevelopment, JKeTest, JKERelease);
  TJKObjectOwner = (JKooItSelf, JKooParent);
  TJKSaveType = (JKstAllGraph, JKstSingleObject);
  TJKRelations = set of (JKrBelongsTo, JKrHasMany, JKrHasOne);
  TJKFillOptions = set of (CallAfterLoadEvent);

  TJKEnumerator = class(TEnumerator<TObject>)
  protected
    FPosition: Int64;
    FTypedList: TJKTypedList;

  protected
    function DoGetCurrent: TObject; override;
    function DoMoveNext: boolean; override;

  public
    constructor Create(AJKTypedList: TJKTypedList);
  end;

  TJKSortingType = (JKsoAscending, JKsoDescending);

  IWrappedList = interface
    ['{EC645EF9-DB2A-4730-9156-0540D1263788}']
    function Count: Integer;
    function GetItem(const Index: Integer): TObject;
    procedure Add(const AObject: TObject);
    procedure Clear;
    function GetEnumerator: TJKEnumerator;
    function WrappedObject: TObject;
    procedure Sort(const PropertyName: String; Order: TJKSortingType = JKsoAscending);
    function GetOwnsObjects: boolean;
    procedure SetOwnsObjects(const Value: boolean);
    property OwnsObjects: boolean Read GetOwnsObjects Write SetOwnsObjects;
  end;

  TJKTypedList = class(TInterfacedObject, IWrappedList)
  protected
    FCTX: TRTTIContext;
    FObject: TObject;
    FAddMethod: TRttiMethod;
    FClearMethod: TRttiMethod;
    FCountProperty: TRttiProperty;
    FGetItemMethod: TRttiMethod;
    FGetCountMethod: TRttiMethod;
    function Count: Integer;
    function GetItem(const Index: Integer): TObject;
    procedure Add(const AObject: TObject);
    procedure Clear;
    function WrappedObject: TObject;
    procedure QuickSort(List: IWrappedList; L, R: Integer; SCompare: TFunc<TObject, TObject, Integer>); overload;
    procedure QuickSort(List: IWrappedList; SCompare: TFunc<TObject, TObject, Integer>); overload;
    procedure Sort(const PropertyName: String; Order: TJKSortingType = JKsoAscending);

  public
    constructor Create(AObject: TObject);
    destructor Destroy; override;
    function GetEnumerator: TJKEnumerator;
    function GetOwnsObjects: boolean;
    procedure SetOwnsObjects(const Value: boolean);
    property OwnsObjects: boolean Read GetOwnsObjects Write SetOwnsObjects;
    class function CanBeWrappedAsList(const AObject: TObject): boolean;
  end;

function WrapAsList(const AObject: TObject): IWrappedList;

implementation

uses
  System.Math,
  JK.RTTIUtils;

constructor TJKEnumerator.Create(AJKTypedList: TJKTypedList);
begin
  inherited Create;
  FTypedList := AJKTypedList;
  FPosition := -1;
end;

function TJKEnumerator.DoGetCurrent: TObject;
begin
  if FPosition > -1 then
    Result := FTypedList.GetItem(FPosition)
  else
    raise Exception.Create('Enumerator error: Call MoveNext first');
end;

function TJKEnumerator.DoMoveNext: boolean;
begin
  if FPosition < FTypedList.Count - 1 then
  begin
    Inc(FPosition);
    Result := True;
  end
  else
    Result := false;
end;

function TJKTypedList.GetEnumerator: TJKEnumerator;
begin
  Result := TJKEnumerator.Create(self);
end;

procedure TJKTypedList.Add(const AObject: TObject);
begin
  FAddMethod.Invoke(FObject, [AObject]);
end;

class function TJKTypedList.CanBeWrappedAsList(const AObject: TObject): boolean;
var
  LCTX: TRTTIContext;
begin
  Result := (LCTX.GetType(AObject.ClassInfo).GetMethod('Add') <> nil)
    and (LCTX.GetType(AObject.ClassInfo).GetMethod('Clear') <> nil)

{$IF CompilerVersion >= 23}
    and (LCTX.GetType(AObject.ClassInfo).GetIndexedProperty('Items').ReadMethod <> nil)
{$IFEND}
    and ((LCTX.GetType(AObject.ClassInfo).GetMethod('GetItem') <> nil)
    or (LCTX.GetType(AObject.ClassInfo).GetMethod('GetElement') <> nil))
    and (LCTX.GetType(AObject.ClassInfo).GetProperty('Count') <> nil)

end;

procedure TJKTypedList.Clear;
begin
  FClearMethod.Invoke(FObject, []);
end;

function TJKTypedList.Count: Integer;
begin
  if Assigned(FCountProperty) then
    Result := FCountProperty.GetValue(FObject).AsInteger
  else
    Result := FGetCountMethod.Invoke(FObject, []).AsInteger;

end;

constructor TJKTypedList.Create(AObject: TObject);
begin
  inherited Create;
  FObject := AObject;
  FAddMethod := FCTX.GetType(AObject.ClassInfo).GetMethod('Add');
  if not Assigned(FAddMethod) then
    raise EJKException.Create('Cannot find method "Add" in the duck object');

  FClearMethod := FCTX.GetType(AObject.ClassInfo).GetMethod('Clear');
  if not Assigned(FClearMethod) then
    raise EJKException.Create('Cannot find method "Clear" in the duck object');

  FGetItemMethod := nil;

{$IF CompilerVersion >= 23}
  FGetItemMethod := FCTX.GetType(AObject.ClassInfo).GetIndexedProperty('Items').ReadMethod;
{$IFEND}
  if not Assigned(FGetItemMethod) then
    FGetItemMethod := FCTX.GetType(AObject.ClassInfo).GetMethod('GetItem');

  if not Assigned(FGetItemMethod) then
    FGetItemMethod := FCTX.GetType(AObject.ClassInfo).GetMethod('GetElement');

  if not Assigned(FGetItemMethod) then
    raise EJKException.Create
      ('Cannot find method Indexed property "Items" or method "GetItem" or method "GetElement" in the duck object');

  FCountProperty := FCTX.GetType(AObject.ClassInfo).GetProperty('Count');
  if not Assigned(FCountProperty) then
  begin
    FGetCountMethod := FCTX.GetType(AObject.ClassInfo).GetMethod('Count');
    if not Assigned(FGetCountMethod) then

    raise EJKException.Create
      ('Cannot find property/method "Count" in the duck object');
  end;
end;

destructor TJKTypedList.Destroy;
begin

  inherited;
end;

function TJKTypedList.GetItem(const Index: Integer): TObject;
begin
  Result := FGetItemMethod.Invoke(FObject, [Index]).AsObject;
end;

function TJKTypedList.GetOwnsObjects: boolean;
begin
  Result := TRTTIUtils.GetProperty(FObject, 'OwnsObjects').AsBoolean
end;

function TJKTypedList.WrappedObject: TObject;
begin
  Result := FObject;
end;

function WrapAsList(const AObject: TObject): IWrappedList;
begin
  try
    Result := TJKTypedList.Create(AObject);
  except
    Result := nil;
  end;
end;

procedure TJKTypedList.QuickSort(List: IWrappedList; L, R: Integer; SCompare: TFunc<TObject, TObject, Integer>);
var
  I, J: Integer;
  p: TObject;
begin
  { 07/08/2013: This method is based on QuickSort procedure from
    Classes.pas, (c) Borland Software Corp.
    but modified to be part of TDuckListU unit.  It implements the
    standard quicksort algorithm,
    delegating comparison operation to an anonimous.
    The Borland version delegates to a pure function
    pointer, which is problematic in some cases. }
  repeat
    I := L;
    J := R;
    p := List.GetItem((L + R) shr 1);
    repeat
      while SCompare(TObject(List.GetItem(I)), p) < 0 do
        Inc(I);
      while SCompare(TObject(List.GetItem(J)), p) > 0 do
        Dec(J);
      if I <= J then
      begin
        TRTTIUtils.MethodCall(List.WrappedObject, 'Exchange', [I, J]);
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(List, L, J, SCompare);
    L := I;
  until I >= R;
end;

procedure TJKTypedList.QuickSort(List: IWrappedList; SCompare: TFunc<TObject, TObject, Integer>);
begin
  QuickSort(List, 0, List.Count - 1, SCompare);
end;

function CompareValue(const Left, Right: TValue): Integer;
begin
  if Left.IsOrdinal then
  begin
    Result := System.Math.CompareValue(Left.AsOrdinal, Right.AsOrdinal);
  end
  else if Left.Kind = tkFloat then
  begin
    Result := System.Math.CompareValue(Left.AsExtended, Right.AsExtended);
  end
  else if Left.Kind in [tkString, tkUString, tkWString, tkLString] then
  begin
    Result := CompareText(Left.AsString, Right.AsString);
  end
  else
  begin
    Result := 0;
  end;
end;

procedure TJKTypedList.SetOwnsObjects(const Value: boolean);
begin
  TRTTIUtils.SetProperty(FObject, 'OwnsObjects', Value);
end;

procedure TJKTypedList.Sort(const PropertyName: String; Order: TJKSortingType);
begin
  if Order = JKsoAscending then
    QuickSort(self,
      function(Left, Right: TObject): Integer
      begin
        Result := CompareValue(TRTTIUtils.GetProperty(Left, PropertyName),
          TRTTIUtils.GetProperty(Right, PropertyName));
      end)
  else
    QuickSort(self,
      function(Left, Right: TObject): Integer
      begin
        Result := -1 * CompareValue(TRTTIUtils.GetProperty(Left, PropertyName),
          TRTTIUtils.GetProperty(Right, PropertyName));
      end);
end;

end.
