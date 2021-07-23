unit JK.RTTIUtils;

interface

uses
  Data.DB,
  System.RTTI,
  System.Generics.Collections,
  System.SysUtils;

type
  TRTTIUtils = class sealed
  public
    class var TRttiCTX: TRttiContext;
    class var TValueToStringFormatSettings: TFormatSettings;

  public
    class function MethodCall(AObject: TObject; AMethodName: String; AParameters: array of TValue;
      RaiseExceptionIfNotFound: Boolean = true): TValue;
    class function GetMethod(AObject: TObject; AMethodName: String): TRttiMethod;
    class procedure SetProperty(Obj: TObject; const PropertyName: String; const Value: TValue); overload; Static;
    class function GetFieldType(AProp: TRttiProperty): String;
    class function GetPropertyType(AObject: TObject; APropertyName: String): String;
    class procedure ObjectToDataSet(Obj: TObject; Field: TField; var Value: Variant);
    class function ExistsProperty(AObject: TObject; const APropertyName: String; out AProperty: TRttiProperty): Boolean;
    class procedure DatasetToObject(Dataset: TDataset; Obj: TObject);
    class function GetProperty(Obj: TObject; const PropertyName: String): TValue;
    class function GetPropertyAsString(Obj: TObject; const PropertyName: String): String; overload;

    class function GetPropertyAsString(Obj: TObject; AProperty: TRttiProperty): String; overload;
    class function GetField(Obj: TObject; const PropertyName: String): TValue; overload;
    class procedure SetField(Obj: TObject; const PropertyName: String; const Value: TValue); overload;
    class function Clone(Obj: TObject): TObject; Static;
    class procedure CopyObject(SourceObj, TargetObj: TObject); Static;
{$IF CompilerVersion >= 24.0} // not supported in xe3
    class procedure CopyObjectAS<LRttiType: class>(SourceObj, TargetObj: TObject); Static;
{$IFEND}
    class function CreateObject(ARttiType: TRttiType): TObject; overload; Static;
    class function CreateObject(AQualifiedClassName: String): TObject; overload; Static;
    class function GetAttribute<LRttiType: TCustomAttribute>(const Obj: TRttiObject): LRttiType; overload;
    class function GetAttribute<LRttiType: TCustomAttribute>(const Obj: TRttiType): LRttiType; overload;

    class function HasAttribute<LRttiType: TCustomAttribute>(const Obj: TRttiObject): Boolean; overload;
    class function HasAttribute<LRttiType: TCustomAttribute>(const Obj: TRttiObject; out AAttribute: LRttiType): Boolean; overload;
    class function HasAttribute<LRttiType: class>(AObj: TObject; out AAttribute: LRttiType): Boolean; overload;
    class function HasAttribute<LRttiType: class>(ARTTIMember: TRttiMember; out AAttribute: LRttiType): Boolean; overload;
    class function HasAttribute<LRttiType: class>(ARTTIMember: TRttiType; out AAttribute: LRttiType): Boolean; overload;

    class function TValueAsString(const Value: TValue; const PropertyType, CustomFormat: String): String;
    class function EqualValues(source, destination: TValue): Boolean;
    class function FindByProperty<LRttiType: class>(List: TObjectList<LRttiType>; PropertyName: String; PropertyValue: TValue): LRttiType;
    class procedure ForEachProperty(Clazz: TClass; Proc: TProc<TRttiProperty>);
    class function HasStringValueAttribute<LRttiType: class>(ARTTIMember: TRttiMember; out Value: String): Boolean;
    class function BuildClass(AQualifiedName: String; Params: array of TValue): TObject;
    class function FindType(QualifiedName: String): TRttiType;
    class function GetGUID<LRttiType>: TGUID;

  end;

function FieldFor(const PropertyName: String): String; Inline;

implementation

uses
  Classes,
  TypInfo,
  JK.ObjectsMappers,
  JK.TypedList;

class function TRTTIUtils.MethodCall(AObject: TObject; AMethodName: String; AParameters: array of TValue;
  RaiseExceptionIfNotFound: Boolean): TValue;
var
  LRttiMethod: TRttiMethod;
  LRttiType: TRttiType;
  LFound: Boolean;
  LParLen: Integer;
  LMethodParamsLen: Integer;
begin
  LFound := False;
  LRttiType := TRttiCTX.GetType(AObject.ClassInfo);
  LParLen := Length(AParameters);
  LRttiMethod := nil;
  for LRttiMethod in LRttiType.GetMethods do
  begin
    LMethodParamsLen := Length(LRttiMethod.GetParameters);
    if LRttiMethod.Name.Equals(AMethodName) and (LMethodParamsLen = LParLen) then
    begin
      LFound := true;
      Break;
    end;
  end;

  if LFound then
    Result := LRttiMethod.Invoke(AObject, AParameters)
  else if RaiseExceptionIfNotFound then
    raise Exception.CreateFmt('Cannot find compatible method "%s" in the object', [AMethodName]);
end;

function FieldFor(const PropertyName: String): String; Inline;
begin
  Result := 'F' + PropertyName;
end;

class function TRTTIUtils.GetAttribute<LRttiType>(const Obj: TRttiObject): LRttiType;
var
  Attr: TCustomAttribute;
begin
  Result := nil;
  for Attr in Obj.GetAttributes do
  begin
    if Attr.ClassType.InheritsFrom(LRttiType) then
      Exit(LRttiType(Attr));
  end;
end;

class function TRTTIUtils.GetAttribute<LRttiType>(const Obj: TRttiType): LRttiType;
var
  Attr: TCustomAttribute;
begin
  Result := nil;
  for Attr in Obj.GetAttributes do
  begin
    if Attr.ClassType.InheritsFrom(LRttiType) then
      Exit(LRttiType(Attr));
  end;
end;

class function TRTTIUtils.GetField(Obj: TObject; const PropertyName: String): TValue;
var
  Field: TRttiField;
  Prop: TRttiProperty;
  ARttiType: TRttiType;
begin
  ARttiType := TRttiCTX.GetType(Obj.ClassType);
  if not Assigned(ARttiType) then
    raise Exception.CreateFmt('Cannot get RTTI for type [%s]', [ARttiType.ToString]);
  Field := ARttiType.GetField(FieldFor(PropertyName));
  if Assigned(Field) then
    Result := Field.GetValue(Obj)
  else
  begin
    Prop := ARttiType.GetProperty(PropertyName);
    if not Assigned(Prop) then
      raise Exception.CreateFmt('Cannot get RTTI for property [%s.%s]', [ARttiType.ToString, PropertyName]);
    Result := Prop.GetValue(Obj);
  end;
end;

class function TRTTIUtils.GetProperty(Obj: TObject; const PropertyName: String): TValue;
var
  Prop: TRttiProperty;
  ARttiType: TRttiType;
begin
  ARttiType := TRttiCTX.GetType(Obj.ClassType);
  if not Assigned(ARttiType) then
    raise Exception.CreateFmt('Cannot get RTTI for type [%s]', [ARttiType.ToString]);
  Prop := ARttiType.GetProperty(PropertyName);
  if not Assigned(Prop) then
    raise Exception.CreateFmt('Cannot get RTTI for property [%s.%s]', [ARttiType.ToString, PropertyName]);
  if Prop.IsReadable then
    Result := Prop.GetValue(Obj)
  else
    raise Exception.CreateFmt('Property is not readable [%s.%s]', [ARttiType.ToString, PropertyName]);
end;

class function TRTTIUtils.GetPropertyAsString(Obj: TObject; AProperty: TRttiProperty): String;
var
  P: TValue;
  FT: String;
  CustomFormat: String;
begin
  if AProperty.IsReadable then
  begin
    P := AProperty.GetValue(Obj);
    FT := GetFieldType(AProperty);
    HasStringValueAttribute<StringValueAttribute>(AProperty, CustomFormat);
    Result := TValueAsString(P, FT, CustomFormat);
  end
  else
    Result := '';
end;

class function TRTTIUtils.GetPropertyAsString(Obj: TObject; const PropertyName: String): String;
var
  Prop: TRttiProperty;
begin
  Prop := TRttiCTX.GetType(Obj.ClassType).GetProperty(PropertyName);
  if Assigned(Prop) then
    Result := GetPropertyAsString(Obj, Prop)
  else
    Result := '';
end;

class function TRTTIUtils.GetPropertyType(AObject: TObject; APropertyName: String): String;
begin
  Result := GetFieldType(TRttiCTX.GetType(AObject.ClassInfo).GetProperty(APropertyName));
end;

class function TRTTIUtils.HasAttribute<LRttiType>(const Obj: TRttiObject): Boolean;
begin
  Result := Assigned(GetAttribute<LRttiType>(Obj));
end;

class function TRTTIUtils.HasAttribute<LRttiType>(ARTTIMember: TRttiMember; out AAttribute: LRttiType): Boolean;
var
  attrs: TArray<TCustomAttribute>;
  Attr: TCustomAttribute;
begin
  AAttribute := nil;
  Result := False;
  attrs := ARTTIMember.GetAttributes;
  for Attr in attrs do
    if Attr is LRttiType then
    begin
      AAttribute := LRttiType(Attr);
      Exit(true);
    end;
end;

class function TRTTIUtils.HasAttribute<LRttiType>(ARTTIMember: TRttiType; out AAttribute: LRttiType): Boolean;
var
  attrs: TArray<TCustomAttribute>;
  Attr: TCustomAttribute;
begin
  AAttribute := nil;
  Result := False;
  attrs := ARTTIMember.GetAttributes;
  for Attr in attrs do
    if Attr is LRttiType then
    begin
      AAttribute := LRttiType(Attr);
      Exit(true);
    end;

end;

class function TRTTIUtils.HasAttribute<LRttiType>(const Obj: TRttiObject; out AAttribute: LRttiType): Boolean;
begin
  AAttribute := GetAttribute<LRttiType>(Obj);
  Result := Assigned(AAttribute);
end;

class function TRTTIUtils.HasStringValueAttribute<LRttiType>(ARTTIMember: TRttiMember; out Value: String): Boolean;
var
  Attr: LRttiType; // StringValueAttribute;
begin
  Result := HasAttribute<LRttiType>(ARTTIMember, Attr);
  if Result then
    Value := StringValueAttribute(Attr).LValue
  else
    Value := '';
end;

class procedure TRTTIUtils.SetField(Obj: TObject; const PropertyName: String; const Value: TValue);
var
  Field: TRttiField;
  Prop: TRttiProperty;
  ARttiType: TRttiType;
begin
  ARttiType := TRttiCTX.GetType(Obj.ClassType);
  if not Assigned(ARttiType) then
    raise Exception.CreateFmt('Cannot get RTTI for type [%s]', [ARttiType.ToString]);
  Field := ARttiType.GetField(FieldFor(PropertyName));
  if Assigned(Field) then
    Field.SetValue(Obj, Value)
  else
  begin
    Prop := ARttiType.GetProperty(PropertyName);
    if Assigned(Prop) then
    begin
      if Prop.IsWritable then
        Prop.SetValue(Obj, Value)
    end
    else
      raise Exception.CreateFmt('Cannot get RTTI for field or property [%s.%s]', [ARttiType.ToString, PropertyName]);
  end;
end;

class procedure TRTTIUtils.SetProperty(Obj: TObject; const PropertyName: String; const Value: TValue);
var
  Prop: TRttiProperty;
  ARttiType: TRttiType;
begin
  ARttiType := TRttiCTX.GetType(Obj.ClassType);
  if not Assigned(ARttiType) then
    raise Exception.CreateFmt('Cannot get RTTI for type [%s]', [ARttiType.ToString]);
  Prop := ARttiType.GetProperty(PropertyName);
  if not Assigned(Prop) then
    raise Exception.CreateFmt('Cannot get RTTI for property [%s.%s]', [ARttiType.ToString, PropertyName]);
  if Prop.IsWritable then
    Prop.SetValue(Obj, Value)
  else
    raise Exception.CreateFmt('Property is not writeable [%s.%s]', [ARttiType.ToString, PropertyName]);
end;

class function TRTTIUtils.TValueAsString(const Value: TValue; const PropertyType, CustomFormat: String): String;
begin
  case Value.Kind of
    tkUnknown:
      Result := '';
    tkInteger:
      Result := IntToStr(Value.AsInteger);
    tkChar:
      Result := Value.AsString;
    tkEnumeration:
      if PropertyType = 'boolean' then
        Result := BoolToStr(Value.AsBoolean, true)
      else
        Result := '(enumeration)';
    tkFloat:
      begin
        if PropertyType = 'datetime' then
        begin
          if CustomFormat = '' then
            Exit(DateTimeToStr(Value.AsExtended))
          else
            Exit(FormatDateTime(CustomFormat, Value.AsExtended))
        end
        else if PropertyType = 'date' then
        begin
          if CustomFormat = '' then
            Exit(DateToStr(Value.AsExtended))
          else
            Exit(FormatDateTime(CustomFormat, Trunc(Value.AsExtended)))
        end
        else if PropertyType = 'time' then
        begin
          if CustomFormat = '' then
            Exit(TimeToStr(Value.AsExtended))
          else
            Exit(FormatDateTime(CustomFormat, Frac(Value.AsExtended)))
        end;
        if CustomFormat.IsEmpty then
          Result := FloatToStr(Value.AsExtended)
        else
          Result := FormatFloat(CustomFormat, Value.AsExtended);
      end;
    tkString:
      Result := Value.AsString;
    tkSet:
      ;
    tkClass:
      Result := Value.AsObject.QualifiedClassName;
    tkMethod:
      ;
    tkWChar:
      Result := Value.AsString;

    tkLString:
      Result := Value.AsString;

    tkWString:
      Result := Value.AsString;

    tkVariant:
      Result := String(Value.AsVariant);

    tkArray:
      Result := '(array)';
    tkRecord:
      Result := '(record)';
    tkInterface:
      Result := '(interface)';

    tkInt64:
      Result := IntToStr(Value.AsInt64);

    tkDynArray:
      Result := '(array)';

    tkUString:
      Result := Value.AsString;
    tkClassRef:
      Result := '(classref)';

    tkPointer:
      Result := '(pointer)';

    tkProcedure:
      Result := '(procedure)';
  end;
end;

class function TRTTIUtils.GetFieldType(AProp: TRttiProperty): String;
var
  _PropInfo: PTypeInfo;
begin
  _PropInfo := AProp.PropertyType.Handle;
  if _PropInfo.Kind in [tkString, tkWString, tkChar, tkWChar, tkLString, tkUString] then
    Result := 'string'
  else if _PropInfo.Kind in [tkInteger, tkInt64] then
    Result := 'integer'
  else if _PropInfo = TypeInfo(TDate) then
    Result := 'date'
  else if _PropInfo = TypeInfo(TDateTime) then
    Result := 'datetime'
  else if _PropInfo = TypeInfo(Currency) then
    Result := 'decimal'
  else if _PropInfo = TypeInfo(TTime) then
  begin
    Result := 'time'
  end
  else if _PropInfo.Kind = tkFloat then
  begin
    Result := 'float'
  end
  else if (_PropInfo.Kind = tkEnumeration) { and (_PropInfo.Name = 'Boolean') } then
    Result := 'boolean'
  else if AProp.PropertyType.IsInstance and AProp.PropertyType.AsInstance.MetaclassType.InheritsFrom(TStream) then
    Result := 'blob'
  else
    Result := EmptyStr;
end;

class function TRTTIUtils.GetGUID<LRttiType>: TGUID;
var
  Tp: TRttiType;
begin
  Tp := TRttiCTX.GetType(TypeInfo(LRttiType));
  if not (Tp.TypeKind = tkInterface) then
    raise Exception.Create('Type is no interface');
  Result := TRttiInterfaceType(Tp).GUID;
end;

class function TRTTIUtils.GetMethod(AObject: TObject; AMethodName: String): TRttiMethod;
var
  LRttiType: TRttiType;
begin
  LRttiType := TRttiCTX.GetType(AObject.ClassInfo);
  Result := LRttiType.GetMethod(AMethodName);
end;

class procedure TRTTIUtils.ObjectToDataSet(Obj: TObject; Field: TField; var Value: Variant);
begin
  Value := GetProperty(Obj, Field.FieldName).AsVariant;
end;

class procedure TRTTIUtils.DatasetToObject(Dataset: TDataset; Obj: TObject);
var
  ARttiType: TRttiType;
  props: TArray<TRttiProperty>;
  Prop: TRttiProperty;
  f: TField;
begin
  ARttiType := TRttiCTX.GetType(Obj.ClassType);
  props := ARttiType.GetProperties;
  for Prop in props do
    if not SameText(Prop.Name, 'ID') then
    begin
      f := Dataset.FindField(Prop.Name);
      if Assigned(f) and not f.ReadOnly then
      begin
        if f is TIntegerField then
          SetProperty(Obj, Prop.Name, TIntegerField(f).Value)
        else
          SetProperty(Obj, Prop.Name, TValue.From<Variant>(f.Value))
      end;
    end;
end;

class function TRTTIUtils.EqualValues(source, destination: TValue): Boolean;
begin
  // Really UniCodeCompareStr (Annoying VCL Name for backwards compatablity)
  Result := AnsiCompareStr(source.ToString, destination.ToString) = 0;
end;

class function TRTTIUtils.ExistsProperty(AObject: TObject; const APropertyName: String; out AProperty: TRttiProperty): Boolean;
begin
  AProperty := TRttiCTX.GetType(AObject.ClassInfo).GetProperty(APropertyName);
  Result := Assigned(AProperty);
end;

class function TRTTIUtils.FindByProperty<LRttiType>(List: TObjectList<LRttiType>; PropertyName: String; PropertyValue: TValue): LRttiType;
var
  elem: LRttiType;
  V: TValue;
  LFound: Boolean;
begin
  LFound := False;
  for elem in List do
  begin
    V := GetProperty(elem, PropertyName);
    case V.Kind of
      tkInteger:
        LFound := V.AsInteger = PropertyValue.AsInteger;
      tkFloat:
        LFound := abs(V.AsExtended - PropertyValue.AsExtended) < 0.001;
      tkString, tkLString, tkWString, tkUString:
        LFound := V.AsString = PropertyValue.AsString;
      tkInt64:
        LFound := V.AsInt64 = PropertyValue.AsInt64;
    else
      raise Exception.Create('Property type not supported');
    end;
    if LFound then
      Exit(elem);
  end;
  Result := nil;
end;

class function TRTTIUtils.FindType(QualifiedName: String): TRttiType;
begin
  Result := TRttiCTX.FindType(QualifiedName);
end;

class procedure TRTTIUtils.ForEachProperty(Clazz: TClass; Proc: TProc<TRttiProperty>);
var
  _rtti: TRttiType;
  P: TRttiProperty;
begin
  _rtti := TRttiCTX.GetType(Clazz);
  if Assigned(_rtti) then
  begin
    for P in _rtti.GetProperties do
      Proc(P);
  end;
end;

class procedure TRTTIUtils.CopyObject(SourceObj, TargetObj: TObject);
var
  _ARttiType: TRttiType;
  Field: TRttiField;
  master, cloned: TObject;
  Src: TObject;
  sourceStream: TStream;
  SavedPosition: Int64;
  targetStream: TStream;
  targetCollection: IWrappedList;
  sourceCollection: IWrappedList;
  I: Integer;
  sourceObject: TObject;
  targetObject: TObject;
  Tar: TObject;
begin
  if not Assigned(TargetObj) then
    Exit;

  _ARttiType := TRttiCTX.GetType(SourceObj.ClassType);
  cloned := TargetObj;
  master := SourceObj;
  for Field in _ARttiType.GetFields do
  begin
    if not Field.FieldType.IsInstance then
      Field.SetValue(cloned, Field.GetValue(master))
    else
    begin
      Src := Field.GetValue(SourceObj).AsObject;
      if Src is TStream then
      begin
        sourceStream := TStream(Src);
        SavedPosition := sourceStream.Position;
        sourceStream.Position := 0;
        if Field.GetValue(cloned).IsEmpty then
        begin
          targetStream := TMemoryStream.Create;
          Field.SetValue(cloned, targetStream);
        end
        else
          targetStream := Field.GetValue(cloned).AsObject as TStream;
        targetStream.Position := 0;
        targetStream.CopyFrom(sourceStream, sourceStream.Size);
        targetStream.Position := SavedPosition;
        sourceStream.Position := SavedPosition;
      end
      else if TJKTypedList.CanBeWrappedAsList(Src) then
      begin
        sourceCollection := WrapAsList(Src);
        Tar := Field.GetValue(cloned).AsObject;
        if Assigned(Tar) then
        begin
          targetCollection := WrapAsList(Tar);
          targetCollection.Clear;
          for I := 0 to sourceCollection.Count - 1 do
            targetCollection.Add(TRTTIUtils.Clone(sourceCollection.GetItem(I)));
        end;
      end
      else
      begin
        sourceObject := Src;

        if Field.GetValue(cloned).IsEmpty then
        begin
          targetObject := TRTTIUtils.Clone(sourceObject);
          Field.SetValue(cloned, targetObject);
        end
        else
        begin
          targetObject := Field.GetValue(cloned).AsObject;
          TRTTIUtils.CopyObject(sourceObject, targetObject);
        end;
      end;
    end;
  end;
end;

{$IF CompilerVersion >= 24.0}

class procedure TRTTIUtils.CopyObjectAS<LRttiType>(SourceObj, TargetObj: TObject);
var
  _ARttiType: TRttiType;
  _ARttiTypeTarget: TRttiType;
  Field, FieldDest: TRttiField;
  master, cloned: TObject;
  Src: TObject;
  sourceStream: TStream;
  SavedPosition: Int64;
  targetStream: TStream;
  targetCollection: IWrappedList;
  sourceCollection: IWrappedList;
  I: Integer;
  sourceObject: TObject;
  targetObject: TObject;
  Tar: TObject;
begin
  if not Assigned(TargetObj) then
    Exit;

  _ARttiType := TRttiCTX.GetType(SourceObj.ClassType);
  _ARttiTypeTarget := TRttiCTX.GetType(TargetObj.ClassType);

  cloned := TargetObj;
  master := SourceObj;
  for Field in _ARttiType.GetFields do
  begin
    FieldDest := _ARttiTypeTarget.GetField(Field.Name);
    if not Assigned(FieldDest) then
      continue;
    if not Field.FieldType.IsInstance then
    begin
      FieldDest.SetValue(cloned, Field.GetValue(master));
    end
    else
    begin
      Src := Field.GetValue(SourceObj).AsObject;
      if not Assigned(Src) then
      begin
        FieldDest.SetValue(cloned, Src);

      end
      else if Src is TStream then
      begin
        sourceStream := TStream(Src);
        SavedPosition := sourceStream.Position;
        sourceStream.Position := 0;
        if FieldDest.GetValue(cloned).IsEmpty then
        begin
          targetStream := TMemoryStream.Create;
          FieldDest.SetValue(cloned, targetStream);
        end
        else
          targetStream := FieldDest.GetValue(cloned).AsObject as TStream;

        targetStream.Position := 0;
        targetStream.CopyFrom(sourceStream, sourceStream.Size);
        targetStream.Position := SavedPosition;
        sourceStream.Position := SavedPosition;
      end
      else if TJKTypedList.CanBeWrappedAsList(Src) then
      begin
        sourceCollection := WrapAsList(Src);
        Tar := FieldDest.GetValue(cloned).AsObject;
        if Assigned(Tar) then
        begin
          targetCollection := WrapAsList(Tar);
          targetCollection.Clear;
          for I := 0 to sourceCollection.Count - 1 do
            targetCollection.Add(TRTTIUtils.Clone(sourceCollection.GetItem(I)));
        end;
      end
      else
      begin
        sourceObject := Src;

        if FieldDest.GetValue(cloned).IsEmpty then
        begin
          targetObject := TRTTIUtils.Clone(sourceObject);
          FieldDest.SetValue(cloned, targetObject);
        end
        else
        begin
          targetObject := FieldDest.GetValue(cloned).AsObject;
          TRTTIUtils.CopyObject(sourceObject, targetObject);
        end;
      end;
    end;
  end;
end;
{$IFEND}

class function TRTTIUtils.CreateObject(AQualifiedClassName: String): TObject;
var
  rttitype: TRttiType;
begin
  rttitype := TRttiCTX.FindType(AQualifiedClassName);
  if Assigned(rttitype) then
    Result := CreateObject(rttitype)
  else
    raise Exception.Create('Cannot find RTTI for ' + AQualifiedClassName + '. Hint: Is the specified classtype linked in the module?');
end;

class function TRTTIUtils.CreateObject(ARttiType: TRttiType): TObject;
var
  Method: TRttiMethod;
  metaClass: TClass;
begin
  { First solution, clear and slow }
  metaClass := nil;
  Method := nil;
  for Method in ARttiType.GetMethods do
    if Method.HasExtendedInfo and Method.IsConstructor then
      if Length(Method.GetParameters) = 0 then
      begin
        metaClass := ARttiType.AsInstance.MetaclassType;
        Break;
      end;
  if Assigned(metaClass) then
    Result := Method.Invoke(metaClass, []).AsObject
  else
    raise Exception.Create('Cannot find a propert constructor for ' + ARttiType.ToString);

  { Second solution, dirty and fast }
  // Result := TObject(ARttiType.GetMethod('Create')
  // .Invoke(ARttiType.AsInstance.MetaclassType, []).AsObject);
end;

class function TRTTIUtils.BuildClass(AQualifiedName: String; Params: array of TValue): TObject;
var
  LRttiType: TRttiType;
  V: TValue;
begin

  LRttiType := FindType(AQualifiedName);
  V := LRttiType.GetMethod('Create').Invoke(LRttiType.AsInstance.MetaclassType, Params);
  Result := V.AsObject;
end;

class function TRTTIUtils.Clone(Obj: TObject): TObject;
var
  _ARttiType: TRttiType;
  Field: TRttiField;
  master, cloned: TObject;
  Src: TObject;
  sourceStream: TStream;
  SavedPosition: Int64;
  targetStream: TStream;
  targetCollection: TObjectList<TObject>;
  sourceCollection: TObjectList<TObject>;
  I: Integer;
  sourceObject: TObject;
  targetObject: TObject;
begin
  Result := nil;
  if not Assigned(Obj) then
    Exit;

  _ARttiType := TRttiCTX.GetType(Obj.ClassType);
  cloned := CreateObject(_ARttiType);
  master := Obj;
  for Field in _ARttiType.GetFields do
  begin
    if not Field.FieldType.IsInstance then
      Field.SetValue(cloned, Field.GetValue(master))
    else
    begin
      Src := Field.GetValue(Obj).AsObject;
      if Src is TStream then
      begin
        sourceStream := TStream(Src);
        SavedPosition := sourceStream.Position;
        sourceStream.Position := 0;
        if Field.GetValue(cloned).IsEmpty then
        begin
          targetStream := TMemoryStream.Create;
          Field.SetValue(cloned, targetStream);
        end
        else
          targetStream := Field.GetValue(cloned).AsObject as TStream;
        targetStream.Position := 0;
        targetStream.CopyFrom(sourceStream, sourceStream.Size);
        targetStream.Position := SavedPosition;
        sourceStream.Position := SavedPosition;
      end
      else if Src is TObjectList<TObject> then
      begin
        sourceCollection := TObjectList<TObject>(Src);
        if Field.GetValue(cloned).IsEmpty then
        begin
          targetCollection := TObjectList<TObject>.Create;
          Field.SetValue(cloned, targetCollection);
        end
        else
          targetCollection := Field.GetValue(cloned).AsObject as TObjectList<TObject>;
        for I := 0 to sourceCollection.Count - 1 do
        begin
          targetCollection.Add(TRTTIUtils.Clone(sourceCollection[I]));
        end;
      end
      else
      begin
        sourceObject := Src;

        if Field.GetValue(cloned).IsEmpty then
        begin
          targetObject := TRTTIUtils.Clone(sourceObject);
          Field.SetValue(cloned, targetObject);
        end
        else
        begin
          targetObject := Field.GetValue(cloned).AsObject;
          TRTTIUtils.CopyObject(sourceObject, targetObject);
        end;
        Field.SetValue(cloned, targetObject);
      end;
    end;

  end;
  Result := cloned;
end;

{ TListDuckTyping }

class function TRTTIUtils.HasAttribute<LRttiType>(AObj: TObject; out AAttribute: LRttiType): Boolean;
begin
  Result := HasAttribute<LRttiType>(TRttiCTX.GetType(AObj.ClassType), AAttribute)
end;

end.
