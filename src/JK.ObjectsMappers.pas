unit JK.ObjectsMappers;

interface

uses
  Data.DB,
  System.RTTI,
  System.IOUtils,
  System.SysUtils,
  Data.DBXPLatform,

  System.Generics.Collections,
{$IF CompilerVersion < 27}
  Data.DBXJSON,
  Data.SqlExpr,
  Data.DBXCommon,
{$ELSE}
  System.JSON,
{$ENDIF}
{$IF CompilerVersion > 25}
  FireDAC.Comp.Client, FireDAC.Stan.Param,
{$IFEND}
  JK.TypedList;

type
  TFieldNamePolicy = (fpLowerCase, fpUpperCase, fpAsIs);

  EMapperException = class(Exception)

  end;

  TSerializationType = (Properties, Fields);

  TJSONObjectActionProc = reference to procedure(const AJSONObject
    : TJSONObject);

  Mapper = class
  strict private
    class var ctx: TRTTIContext;

  private
{$IF CompilerVersion > 25}
    class function InternalExecuteFDQuery(AQuery: TFDQuery; AObject: TObject;
      WithResult: Boolean): Int64;
{$ELSE}
    class function InternalExecuteSQLQuery(AQuery: TSQLQuery; AObject: TObject;
      WithResult: Boolean): Int64;
{$IFEND}
    class function GetKeyName(const ARttiField: TRttiField; AType: TRttiType)
      : String; overload;
    class function GetKeyName(const ARttiProp: TRttiProperty; AType: TRttiType)
      : String; overload;
    class procedure InternalJSONObjectToObject(ctx: TRTTIContext;
      AJSONObject: TJSONObject; AObject: TObject); Static;
    class procedure InternalJSONObjectFieldsToObject(ctx: TRTTIContext;
      AJSONObject: TJSONObject; AObject: TObject); Static;

    { following methods are used by the serializer/unserializer to handle with the ser/unser logic }
    class function SerializeFloatProperty(AObject: TObject;
      ARTTIProperty: TRttiProperty): TJSONValue;
    class function SerializeFloatField(AObject: TObject; ARttiField: TRttiField)
      : TJSONValue;
    class function SerializeEnumerationProperty(AObject: TObject;
      ARTTIProperty: TRttiProperty): TJSONValue;
    class function SerializeEnumerationField(AObject: TObject;
      ARttiField: TRttiField): TJSONValue;
  public
    class function HasAttribute<T: class>(ARTTIMember: TRttiNamedObject)
      : Boolean; overload;
    class function HasAttribute<T: class>(ARTTIMember: TRttiNamedObject;
      out AAttribute: T): Boolean; overload;

    /// Do not restore nested classes

    class function JSONObjectToObject<T: constructor, class>(AJSONObject: TJSONObject): T; overload; Static;
    class function JSONObjectStringToObject<T: constructor, class>(const AJSONObjectString: String): T;

    class function JSONObjectToObject(Clazz: TClass; AJSONObject: TJSONObject): TObject; overload; Static;
    class function JSONObjectToObject(ClazzName: String; AJSONObject: TJSONObject): TObject; overload; Static;
    class function JSONObjectToObjectFields<T: constructor, class>(AJSONObject: TJSONObject): T; Static;
    class procedure ObjectToDataSet(Obj: TObject; Field: TField; var LValue: Variant); Static;
    class procedure DataSetToObject(ADataSet: TDataSet; AObject: TObject);
    class function ObjectToJSONObject(AObject: TObject; AIgnoredProperties: array of String): TJSONObject; overload;
    /// <summary>
    /// Serializes an object to a LJSONObject using fields LValue, not property values. WARNING! This        / Serializa um objeto para um LJSONObject usando valores de campos, não valores de propriedades. AVISO! Esta
    /// method do not generate the $dmvc_classname property in the LJSONObject. To have the $dmvc_classname / método não gera a propriedade $ dmvc_classname no LJSONObject. Para ter o $ dmvc_classname
    /// into the json you should use ObjectToJSONObjectFields.                                             / no json, você deve usar ObjectToJSONObjectFields.
    /// </summary>
    class function ObjectToJSONObjectFields(AObject: TObject;
      AIgnoredProperties: array of String): TJSONObject; overload;
    class function ObjectToJSONObjectFieldsString(AObject: TObject;
      AIgnoredProperties: array of String): String; overload;

    /// <summary>
    /// Restore the object stored in the JSON object using the $dmvc_classname property                                        / Restaure o objeto armazenado no objeto JSON usando a propriedade $ dmvc_classname
    /// to know the qualified full class name. Values readed from the json are restored directly to the object fields.         / para saber o nome completo da classe qualificada. Os valores lidos do json são restaurados diretamente nos campos do objeto.
    /// Fields MUST be exists into the json. This kind of deserialization is way more strit than the properties based.         / Os campos DEVEM existir no json. Esse tipo de desserialização é muito mais estrito do que as propriedades baseadas.
    /// It should not be used to serialize object for a thin client, but to serialize objects that must be deserialized using  / Não deve ser usado para serializar objetos para um cliente fino, mas para serializar objetos que devem ser desserializados usando
    /// the same delphi class. So this method is useful when you are developing a delphi-delphi solution. Exceptions apply.    / a mesma classe Delphi. Portanto, este método é útil quando você está desenvolvendo uma solução delphi-delphi. Exceções se aplicam.
    /// </summary>
    class function JSONObjectFieldsToObject(AJSONObject: TJSONObject): TObject;
    /// <summary>
    /// Serialize an object to a LJSONObject using properties values. It is useful when you         / Serialize um objeto para um LJSONObject usando valores de propriedades. É útil quando você
    /// have to send derived or calculated properties. It is not a simple serialization, it bring  / tem que enviar propriedades derivadas ou calculadas. Não é uma serialização simples, traz
    /// also all logic applied to object properties                                                / também toda a lógica aplicada às propriedades do objeto
    /// (es. Price,Q.ty, Discount, Total. Total is a derived property)                             / (es. Price,Q.ty, Discount, Total. Total is uma propriedade derivada)
    /// </summary>
    class function ObjectToJSONObject(AObject: TObject): TJSONObject; overload;
    /// <summary>
    /// Identical to ObjectToJSONObject but it return a String representation instead of a json object / Idêntico a ObjectToJSONObject, mas retorna uma representação String em vez de um objeto json
    /// </summary>
    class function ObjectToJSONObjectString(AObject: TObject): String;
    class function ObjectToJSONArray(AObject: TObject): TJSONArray;
    class function JSONArrayToObjectList(AListOf: TClass; AJSONArray: TJSONArray; AInstanceOwner: Boolean = True;
      AOwnsChildObjects: Boolean = True): TObjectList<TObject>; overload;
    class procedure JSONArrayToObjectList(AList: IWrappedList; AListOf: TClass; AJSONArray: TJSONArray;
      AInstanceOwner: Boolean = True; AOwnsChildObjects: Boolean = True); overload;
    class function JSONArrayToObjectList<T: class, constructor> (AJSONArray: TJSONArray; AInstanceOwner: Boolean = True;
      AOwnsChildObjects: Boolean = True): TObjectList<T>; overload;
    class procedure JSONArrayToObjectList<T: class, constructor>(AList: TObjectList<T>; AJSONArray: TJSONArray;
      AInstanceOwner: Boolean = True; AOwnsChildObjects: Boolean = True); overload;
{$IF CompilerVersion <= 25}
    class procedure ReaderToObject(AReader: TDBXReader; AObject: TObject);
    class procedure ReaderToObjectList<T: class, constructor>(AReader: TDBXReader; AObjectList: TObjectList<T>);
    class procedure ReaderToJSONObject(AReader: TDBXReader; AJSONObject: TJSONObject; AReaderInstanceOwner: Boolean = True);
{$ENDIF}
    class procedure DataSetToJSONObject(ADataSet: TDataSet; AJSONObject: TJSONObject; ADataSetInstanceOwner: Boolean = True;
      AJSONObjectActionProc: TJSONObjectActionProc = nil; AFieldNamePolicy: TFieldNamePolicy = fpLowerCase);
    class procedure JSONObjectToDataSet(AJSONObject: TJSONObject; ADataSet: TDataSet; AJSONObjectInstanceOwner: Boolean = True); overload;
    class procedure JSONObjectToDataSet(AJSONObject: TJSONObject; ADataSet: TDataSet; AIgnoredFields: TArray<String>;
      AJSONObjectInstanceOwner: Boolean = True; AFieldNamePolicy: TFieldNamePolicy = fpLowerCase); overload;
    class procedure DataSetToObjectList<T:
    class, constructor>(ADataSet: TDataSet; AObjectList: TObjectList<T>; ACloseDataSetAfterScroll: Boolean = True);
    class function DataSetToJSONArrayOf<T: class, constructor>(ADataSet: TDataSet): TJSONArray;
{$IF CompilerVersion <= 25}
    class procedure ReaderToList<T: class, constructor>(AReader: TDBXReader; AList: IWrappedList);
    class procedure ReaderToJSONArray(AReader: TDBXReader; AJSONArray: TJSONArray;
      AReaderInstanceOwner: Boolean = True);
{$ENDIF}
    class procedure DataSetToJSONArray(ADataSet: TDataSet; AJSONArray: TJSONArray; ADataSetInstanceOwner: Boolean = True;
      AJSONObjectActionProc: TJSONObjectActionProc = nil);
    class procedure JSONArrayToDataSet(AJSONArray: TJSONArray; ADataSet: TDataSet; AJSONArrayInstanceOwner: Boolean = True); overload;
    class procedure JSONArrayToDataSet(AJSONArray: TJSONArray; ADataSet: TDataSet; AIgnoredFields: TArray<String>;
      AJSONArrayInstanceOwner: Boolean = True; AFieldNamePolicy: TFieldNamePolicy = fpLowerCase); overload;
    // class procedure DataSetRowToXML(ADataSet: TDataSet; Row: IXMLNode; ADataSetInstanceOwner: Boolean = True);
    // class procedure DataSetToXML(ADataSet: TDataSet; XMLDocument: String; ADataSetInstanceOwner: Boolean = True);
    class function ObjectListToJSONArray<T: class>(AList: TObjectList<T>; AOwnsInstance: Boolean = False;
      AForEach: TJSONObjectActionProc = nil): TJSONArray; overload;
    class function ObjectListToJSONArray(AList: IWrappedList; AOwnsChildObjects: Boolean = True;
      AForEach: TJSONObjectActionProc = nil): TJSONArray; overload;
    class function ObjectListToJSONArrayFields<T: class>(AList: TObjectList<T>; AOwnsInstance: Boolean = False;
      AForEach: TJSONObjectActionProc = nil): TJSONArray;
    class function ObjectListToJSONArrayString<T: class>(AList: TObjectList<T>;
      AOwnsInstance: Boolean = False): String; overload;
    class function ObjectListToJSONArrayString(AList: IWrappedList;
      AOwnsChildObjects: Boolean = True): String; overload;
    class function ObjectListToJSONArrayOfJSONArray<T: class, constructor>
      (AList: TObjectList<T>): TJSONArray;
    class function GetProperty(Obj: TObject; const PropertyName: String): TValue; Static;
{$IF CompilerVersion <= 25}
    class function ExecuteSQLQueryNoResult(AQuery: TSQLQuery; AObject: TObject): Int64;
    class procedure ExecuteSQLQuery(AQuery: TSQLQuery; AObject: TObject = nil);
    class function ExecuteSQLQueryAsObjectList<T: class, constructor>(AQuery: TSQLQuery; AObject: TObject = nil): TObjectList<T>;
    class function CreateQuery(AConnection: TSQLConnection; ASQL: String): TSQLQuery;
{$ENDIF}
    { FIREDAC RELATED METHODS }
{$IF CompilerVersion > 25}
    class function ExecuteFDQueryNoResult(AQuery: TFDQuery; AObject: TObject): Int64;
    class procedure ExecuteFDQuery(AQuery: TFDQuery; AObject: TObject);
    class procedure ObjectToFDParameters(AFDParams: TFDParams; AObject: TObject; AParamPrefix: String = '');
{$IFEND}
    // SAFE TJSONObject getter
    class function GetPair(LJSONObject: TJSONObject; PropertyName: String)
      : TJSONPair;
    class function GetStringDef(LJSONObject: TJSONObject; PropertyName: String;
      DefaultValue: String = ''): String;
    class function GetNumberDef(LJSONObject: TJSONObject; PropertyName: String;
      DefaultValue: Extended = 0): Extended;
    class function GetJSONObj(LJSONObject: TJSONObject; PropertyName: String)
      : TJSONObject;
    class function GetJSONArray(LJSONObject: TJSONObject; PropertyName: String)
      : TJSONArray;
    class function GetIntegerDef(LJSONObject: TJSONObject; PropertyName: String;
      DefaultValue: Integer = 0): Integer;
    class function GetInt64Def(LJSONObject: TJSONObject; PropertyName: String;
      DefaultValue: Int64 = 0): Int64;
    class function GetBooleanDef(LJSONObject: TJSONObject; PropertyName: String;
      DefaultValue: Boolean = False): Boolean;
    class function PropertyExists(LJSONObject: TJSONObject;
      PropertyName: String): Boolean;
  end;

  TDataSetHelper = class Helper for TDataSet
  public
    function AsJSONArray: TJSONArray;
    function AsJSONArrayString: String;
    function AsJSONObject(AReturnNilIfEOF: Boolean = False; AFieldNamePolicy: TFieldNamePolicy = fpLowerCase): TJSONObject;
    function AsJSONObjectString(AReturnEmptyStringIfEOF: Boolean = False): String;
    procedure LoadFromJSONObject(AJSONObject: TJSONObject; AFieldNamePolicy: TFieldNamePolicy = fpLowerCase); overload;
    procedure LoadFromJSONObject(AJSONObject: TJSONObject; AIgnoredFields: TArray<String>;
      AFieldNamePolicy: TFieldNamePolicy = fpLowerCase); overload;
    procedure LoadFromJSONArray(AJSONArray: TJSONArray;
      AFieldNamePolicy: TFieldNamePolicy = TFieldNamePolicy.fpLowerCase); overload;
    procedure LoadFromJSONArrayString(AJSONArrayString: String);
    procedure LoadFromJSONArray(AJSONArray: TJSONArray; AIgnoredFields: TArray<String>); overload;
    procedure LoadFromJSONObjectString(AJSONObjectString: String); overload;
    procedure LoadFromJSONObjectString(AJSONObjectString: String; AIgnoredFields: TArray<String>); overload;
    procedure AppendFromJSONArrayString(AJSONArrayString: String); overload;
    procedure AppendFromJSONArrayString(AJSONArrayString: String; AIgnoredFields: TArray<String>); overload;
    function AsObjectList<T: class, constructor>(CloseAfterScroll: Boolean = False): TObjectList<T>;
    function AsObject<T: class, constructor>(CloseAfterScroll: Boolean = False): T;
  end;

  MapperTransientAttribute = class(TCustomAttribute)

  end;

  DoNotSerializeAttribute = class(TCustomAttribute)

  end;

  MapperItemsClassType = class(TCustomAttribute)
  private
    FValue: TClass;
    procedure SetValue(const LValue: TClass);
  public
    constructor Create(LValue: TClass);
    property LValue: TClass read FValue write SetValue;
  end;

  MapperListOf = MapperItemsClassType; // just to be more similar to TypedList / apenas para ser mais semelhante ao TypedList

  TJSONNameCase = (JSONNameUpperCase, JSONNameLowerCase);

  HideInGrids = class(TCustomAttribute)

  end;

  StringValueAttribute = class abstract(TCustomAttribute)
  private
    FValue: String;
    procedure SetValue(const LValue: String);
  public
    constructor Create(LValue: String);
    property LValue: String read FValue write SetValue;
  end;

  FormatFloatValue = class(StringValueAttribute)

  end;

  FormatDateTimeValue = class(StringValueAttribute)

  end;

  MapperSerializeAsString = class(TCustomAttribute)
  strict private
    FEncoding: String;
    procedure SetEncoding(const LValue: String);
  const
    DefaultEncoding = 'utf-8';
  public
    constructor Create(AEncoding: String = DefaultEncoding);
    property Encoding: String read FEncoding write SetEncoding;
  end;

  MapperJSONNaming = class(TCustomAttribute)
  private
    FJSONKeyCase: TJSONNameCase;
    function GetKeyCase: TJSONNameCase;
  public
    constructor Create(JSONKeyCase: TJSONNameCase);
    property KeyCase: TJSONNameCase read GetKeyCase;
  end;

  MapperJSONSer = class(TCustomAttribute)
  private
    FName: String;
    function GetName: String;
  public
    constructor Create(AName: String);
    property name: String read GetName;
  end;

  MapperColumnAttribute = class(TCustomAttribute)
  private
    FFieldName: String;
    FIsPK: Boolean;
    procedure SetFieldName(const LValue: String);
    procedure SetIsPK(const LValue: Boolean);
  public
    constructor Create(AFieldName: String; AIsPK: Boolean = False);
    property FieldName: String read FFieldName write SetFieldName;
    property IsPK: Boolean read FIsPK write SetIsPK;
  end;

  TGridColumnAlign = (caLeft, caCenter, caRight);

  GridColumnProps = class(TCustomAttribute)
  private
    FCaption: String;
    FAlign: TGridColumnAlign;
    FWidth: Integer;
    function GetAlignAsString: String;
  public
    constructor Create(ACaption: String; AAlign: TGridColumnAlign = caCenter;
      AWidth: Integer = -1);
    property Caption: String read FCaption;
    property Align: TGridColumnAlign read FAlign;
    property AlignAsString: String read GetAlignAsString;
    property Width: Integer read FWidth;
  end;

function ISODateTimeToString(ADateTime: TDateTime): String;
function ISODateToString(ADate: TDateTime): String;
function ISOTimeToString(ATime: TTime): String;

function ISOStrToDateTime(DateTimeAsString: String): TDateTime;
function ISOStrToDate(DateAsString: String): TDate;
function ISOStrToTime(TimeAsString: String): TTime;

// function ISODateToStr(const ADate: TDate): String;

// function ISOTimeToStr(const ATime: TTime): String;

implementation

{$WARN SYMBOL_DEPRECATED OFF}

uses
  TypInfo,
  FmtBcd,
  Math,
  SqlTimSt,
  DateUtils,
  Classes,
  JK.RTTIUtils,
  Xml.adomxmldom,
{$IF CompilerVersion >= 28}
  System.NetEncoding,
  // so that the old functions in Soap.EncdDecd can be inlined / para que as funções antigas em Soap.EncdDecd possam ser embutidas
{$ENDIF}
  Soap.EncdDecd;

const
  DMVC_CLASSNAME = '$dmvc_classname';
  { Mapper }

function ContainsFieldName(const FieldName: String;
  var FieldsArray: TArray<String>): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(FieldsArray) - 1 do
  begin
    if SameText(FieldsArray[I], FieldName) then
      Exit(True);
  end;
  Result := False;
end;

function ISOTimeToString(ATime: TTime): String;
var
  fs: TFormatSettings;
begin
  fs.TimeSeparator := ':';
  Result := FormatDateTime('HH:nn:ss', ATime, fs);
end;

function ISODateToString(ADate: TDateTime): String;
begin
  Result := FormatDateTime('YYYY-MM-DD', ADate);
end;

function ISODateTimeToString(ADateTime: TDateTime): String;
var
  fs: TFormatSettings;
begin
  fs.TimeSeparator := ':';
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', ADateTime, fs);
end;

function ISOStrToDateTime(DateTimeAsString: String): TDateTime;
begin
  Result := EncodeDateTime(StrToInt(Copy(DateTimeAsString, 1, 4)),
    StrToInt(Copy(DateTimeAsString, 6, 2)),
    StrToInt(Copy(DateTimeAsString, 9, 2)),
    StrToInt(Copy(DateTimeAsString, 12, 2)),
    StrToInt(Copy(DateTimeAsString, 15, 2)),
    StrToInt(Copy(DateTimeAsString, 18, 2)), 0);
end;

function ISOStrToTime(TimeAsString: String): TTime;
begin
  Result := EncodeTime(StrToInt(Copy(TimeAsString, 1, 2)),
    StrToInt(Copy(TimeAsString, 4, 2)), StrToInt(Copy(TimeAsString, 7, 2)), 0);
end;

function ISOStrToDate(DateAsString: String): TDate;
begin
  Result := EncodeDate(StrToInt(Copy(DateAsString, 1, 4)),
    StrToInt(Copy(DateAsString, 6, 2)), StrToInt(Copy(DateAsString, 9, 2)));
  // , StrToInt
  // (Copy(DateAsString, 12, 2)), StrToInt(Copy(DateAsString, 15, 2)),
  // StrToInt(Copy(DateAsString, 18, 2)), 0);
end;


// function ISODateToStr(const ADate: TDate): String;
// begin
// Result := FormatDateTime('YYYY-MM-DD', ADate);
// end;
//
// function ISOTimeToStr(const ATime: TTime): String;
// begin
// Result := FormatDateTime('HH:nn:ss', ATime);
// end;

{$IF CompilerVersion <= 25}

class function Mapper.InternalExecuteSQLQuery(AQuery: TSQLQuery;
  AObject: TObject; WithResult: Boolean): Int64;
var
  I: Integer;
  LName: String;
  _rttiType: TRttiType;
  LObj_Fields: TArray<TRttiProperty>;
  LObj_Field: TRttiProperty;
  LObj_Field_Attr: MapperColumnAttribute;
  LMap: TObjectDictionary<String, TRttiProperty>;
  LRttiProperty: TRttiProperty;
  LValue: TValue;
begin
  LMap := TObjectDictionary<String, TRttiProperty>.Create;
  try
    if Assigned(AObject) then
    begin
      _rttiType := ctx.GetType(AObject.ClassType);
      LObj_Fields := _rttiType.GetProperties;
      for LObj_Field in LObj_Fields do
      begin
        if HasAttribute<MapperColumnAttribute>(LObj_Field, LObj_Field_Attr) then
        begin
          LMap.Add(MapperColumnAttribute(LObj_Field_Attr).FieldName, LObj_Field);
        end
        else
        begin
          LMap.Add(LowerCase(LObj_Field.Name), LObj_Field);
        end
      end;
    end;
    for I := 0 to AQuery.Params.Count - 1 do
    begin
      LName := AQuery.Params[I].Name;
      if LMap.TryGetValue(LName, LRttiProperty) then
      begin
        LValue := LRttiProperty.GetValue(AObject);
        AQuery.Params[I].LValue := LValue.AsVariant;
      end
      else
      begin
        AQuery.Params[I].Clear;
        AQuery.Params[I].DataType := ftString; // just to make dbx happy / apenas para deixar o dbx feliz

      end;
    end;
    Result := 0;
    if WithResult then
      AQuery.Open
    else
      Result := AQuery.ExecSQL;
  finally
    LMap.Free;
  end;
end;

class procedure Mapper.ReaderToJSONArray(AReader: TDBXReader;
  AJSONArray: TJSONArray; AReaderInstanceOwner: Boolean);
var
  Obj: TJSONObject;
begin
  while AReader.Next do
  begin
    Obj := TJSONObject.Create;
    AJSONArray.AddElement(Obj);
    ReaderToJSONObject(AReader, Obj, False);
  end;
  if AReaderInstanceOwner then
    FreeAndNil(AReader);
end;

class procedure Mapper.ReaderToJSONObject(AReader: TDBXReader;
  AJSONObject: TJSONObject; AReaderInstanceOwner: Boolean);
var
  I: Integer;
  key: String;
  dt: TDateTime;
  Time: TTimeStamp;
  ts: TSQLTimeStamp;
begin
  for I := 0 to AReader.ColumnCount - 1 do
  begin
    key := LowerCase(AReader.LValue[I].ValueType.Name);
    case AReader.LValue[I].ValueType.DataType of
      TDBXDataTypes.Int16Type : AJSONObject.AddPair
        (key, TJSONNumber.Create(AReader.LValue[I].AsInt16));
      TDBXDataTypes.Int32Type : AJSONObject.AddPair
        (key, TJSONNumber.Create(AReader.LValue[I].AsInt32));
      TDBXDataTypes.Int64Type : AJSONObject.AddPair
        (key, TJSONNumber.Create(AReader.LValue[I].AsInt64));
      TDBXDataTypes.DoubleType : AJSONObject.AddPair
        (key, TJSONNumber.Create(AReader.LValue[I].AsDouble));
      TDBXDataTypes.AnsiStringType, TDBXDataTypes.WideStringType : AJSONObject.AddPair
        (key, AReader.LValue[I].AsString);
      TDBXDataTypes.BcdType : AJSONObject.AddPair(key, TJSONNumber.Create(BcdToDouble(AReader.LValue[I].AsBcd)));
      TDBXDataTypes.DateType:
        begin
          if not AReader.LValue[I].IsNull then
          begin
            Time.Time := 0;
            Time.date := AReader.LValue[I].AsDate;
            dt := TimeStampToDateTime(Time);
            AJSONObject.AddPair(key, ISODateToString(dt));
          end
          else
            AJSONObject.AddPair(key, TJSONNull.Create);
        end;
      TDBXDataTypes.TimeType:
        begin
          if not AReader.LValue[I].IsNull then
          begin
            ts := AReader.LValue[I].AsTimeStamp;
            AJSONObject.AddPair(key, SQLTimeStampToStr('HH:nn:ss', ts));
          end
          else
            AJSONObject.AddPair(key, TJSONNull.Create);
        end
    else
      raise EMapperException.Create('Cannot find type');
    end;
  end;
  if AReaderInstanceOwner then
    FreeAndNil(AReader);
end;

class procedure Mapper.ReaderToList<T>(AReader: TDBXReader;
  AList: IWrappedList);
var
  Obj: T;
begin
  while AReader.Next do
  begin
    Obj := T.Create;
    ReaderToObject(AReader, Obj);
    AList.Add(Obj);
  end;
  AReader.Close;
end;

class procedure Mapper.ReaderToObject(AReader: TDBXReader; AObject: TObject);
var
        _type : TRttiType;
      _fields : TArray<TRttiProperty>;
       _field : TRttiProperty;
  _attribute  : MapperColumnAttribute;
        _dict : TDictionary<String, String>;
        _keys : TDictionary<String, Boolean>;
           mf : MapperColumnAttribute;
   field_name : String;
        LValue : TValue;
           ts : TTimeStamp;
        sqlts : TSQLTimeStamp;
begin
  _dict := TDictionary<String, String>.Create();
  _keys := TDictionary<String, Boolean>.Create();
  _type := ctx.GetType(AObject.ClassInfo);
  _fields := _type.GetProperties;
  for _field in _fields do
    if HasAttribute<MapperColumnAttribute>(_field, _attribute) then
    begin
      mf := _attribute;
      _dict.Add(_field.Name, mf.FieldName);
      _keys.Add(_field.Name, mf.IsPK);
    end
    else
    begin
      _dict.Add(_field.Name, _field.Name);
      _keys.Add(_field.Name, False);
    end;

  for _field in _fields do
  begin
    if (not _dict.TryGetValue(_field.Name, field_name)) or
      (not _field.IsWritable) or (HasAttribute<MapperTransientAttribute>(_field))
    then
      Continue;
    case _field.PropertyType.TypeKind of
      tkInteger:
          LValue := AReader.LValue[field_name].AsInt32;
      tkFloat:
        begin
          if AReader.LValue[field_name].IsNull then
            LValue := 0
          else
          begin
            if AReader.LValue[field_name].ValueType.DataType = TDBXDataTypes.DateType
            then
            begin
              ts.Time := 0;
              ts.date := AReader.LValue[field_name].AsDate;
              LValue := TimeStampToDateTime(ts);
            end
            else if AReader.LValue[field_name]
              .ValueType.DataType = TDBXDataTypes.DoubleType then
              LValue := AReader.LValue[field_name].AsDouble
            else if AReader.LValue[field_name]
              .ValueType.DataType = TDBXDataTypes.BcdType then
              LValue := BcdToDouble(AReader.LValue[field_name].AsBcd)
            else if AReader.LValue[field_name]
              .ValueType.DataType = TDBXDataTypes.TimeType then
            begin
              sqlts := AReader.LValue[field_name].AsTimeStamp;
              LValue := SQLTimeStampToDateTime(sqlts);
            end
            else
              raise EMapperException.Create('Unknown tkFloat Type');
          end;
        end;

      tkString, tkUString, tkWChar, tkLString, tkWString:
        begin
          if AReader.LValue[field_name].IsNull then
            LValue := ''
          else
            LValue := AReader.LValue[field_name].AsString;
        end;
    else
      raise EMapperException.Create('Unknown field type for ' + field_name);
    end;
    _field.SetValue(AObject, LValue);
  end;
  _dict.Free;
  _keys.Free;
end;

class procedure Mapper.ReaderToObjectList<T>(AReader: TDBXReader;
  AObjectList: TObjectList<T>);
var
  Obj: T;
begin
  while AReader.Next do
  begin
    Obj := T.Create;
    ReaderToObject(AReader, Obj);
    AObjectList.Add(Obj);
  end;
  AReader.Close;
end;

class function Mapper.CreateQuery(AConnection: TSQLConnection; ASQL: String)
  : TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.SQLConnection := AConnection;
  Result.CommandText := ASQL;
end;
{$IFEND}

class procedure Mapper.DataSetToJSONArray(ADataSet: TDataSet;
  AJSONArray: TJSONArray; ADataSetInstanceOwner: Boolean;
  AJSONObjectActionProc: TJSONObjectActionProc);
var
  Obj: TJSONObject;
begin
  while not ADataSet.Eof do
  begin
    Obj := TJSONObject.Create;
    AJSONArray.AddElement(Obj);
    DataSetToJSONObject(ADataSet, Obj, False, AJSONObjectActionProc);
    ADataSet.Next;
  end;
  // repeat
  // Obj := TJSONObject.Create;
  // AJSONArray.AddElement(Obj);
  // DataSetToJSONObject(ADataSet, Obj, False);
  // ADataSet.Next;
  // until ADataSet.Eof;

  if ADataSetInstanceOwner then
    FreeAndNil(ADataSet);
end;

class function Mapper.DataSetToJSONArrayOf<T>(ADataSet: TDataSet): TJSONArray;
var
  LWrappList: TObjectList<T>;
begin
  LWrappList := TObjectList<T>.Create;
  try
    Mapper.DataSetToObjectList<T>(ADataSet, LWrappList);
    Result := Mapper.ObjectListToJSONArray<T>(LWrappList);
  finally
    LWrappList.Free;
  end;
end;

class procedure Mapper.DataSetToJSONObject(ADataSet: TDataSet;
  AJSONObject: TJSONObject; ADataSetInstanceOwner: Boolean;
  AJSONObjectActionProc: TJSONObjectActionProc;
  AFieldNamePolicy: TFieldNamePolicy);
var
  I: Integer;
  key: String;
  ts: TSQLTimeStamp;
  MS: TMemoryStream;
  SS: TStringStream;
begin
  for I := 0 to ADataSet.FieldCount - 1 do
  begin
    // Name policy { ***** Daniele Spinetti ***** }
    case AFieldNamePolicy of
      fpLowerCase:
        key := LowerCase(ADataSet.Fields[I].FieldName);
      fpUpperCase:
        key := UpperCase(ADataSet.Fields[I].FieldName);
      fpAsIs:
        key := ADataSet.Fields[I].FieldName;
    end;

    if ADataSet.Fields[I].IsNull then
    begin
      AJSONObject.AddPair(key, TJSONNull.Create);
      Continue;
    end;
    case ADataSet.Fields[I].DataType of
      TFieldType.ftInteger, TFieldType.ftAutoInc, TFieldType.ftSmallint,
        TFieldType.ftShortint:
        AJSONObject.AddPair(key,
          TJSONNumber.Create(ADataSet.Fields[I].AsInteger));
      TFieldType.ftLargeint:
        begin
          AJSONObject.AddPair(key,
            TJSONNumber.Create(ADataSet.Fields[I].AsLargeInt));
        end;
      TFieldType.ftSingle, TFieldType.ftFloat:
        AJSONObject.AddPair(key,
          TJSONNumber.Create(ADataSet.Fields[I].AsFloat));
      ftWideString, ftMemo, ftWideMemo:
        AJSONObject.AddPair(key, ADataSet.Fields[I].AsWideString);
      ftString:
        AJSONObject.AddPair(key, ADataSet.Fields[I].AsString);
      TFieldType.ftDate:
        begin
          AJSONObject.AddPair(key,
            ISODateToString(ADataSet.Fields[I].AsDateTime));
        end;
      TFieldType.ftDateTime:
        begin
          AJSONObject.AddPair(key,
            ISODateTimeToString(ADataSet.Fields[I].AsDateTime));
        end;
      TFieldType.ftTimeStamp:
        begin
          ts := ADataSet.Fields[I].AsSQLTimeStamp;
          AJSONObject.AddPair(key,
            SQLTimeStampToStr('yyyy-mm-dd hh:nn:ss', ts));
        end;
      TFieldType.ftCurrency:
        begin
          // AJSONObject.AddPair(key, FormatCurr('0.00##', ADataSet.Fields[I].AsCurrency));
          AJSONObject.AddPair(key,
            TJSONNumber.Create(ADataSet.Fields[I].AsCurrency));
        end;
      TFieldType.ftBCD, TFieldType.ftFMTBcd:
        begin
          AJSONObject.AddPair(key,
            TJSONNumber.Create(BcdToDouble(ADataSet.Fields[I].AsBcd)));
        end;
      TFieldType.ftGraphic, TFieldType.ftBlob, TFieldType.ftStream:
        begin
          MS := TMemoryStream.Create;
          try
            TBlobField(ADataSet.Fields[I]).SaveToStream(MS);
            MS.Position := 0;
            SS := TStringStream.Create('', TEncoding.ASCII);
            try
              EncodeStream(MS, SS);
              SS.Position := 0;
              AJSONObject.AddPair(key, SS.DataString);
            finally
              SS.Free;
            end;
          finally
            MS.Free;
          end;
        end;

      // else
      // raise EMapperException.Create('Cannot find type for field ' + key);
    end;
  end;
  if ADataSetInstanceOwner then
    FreeAndNil(ADataSet);
  if Assigned(AJSONObjectActionProc) then
    AJSONObjectActionProc(AJSONObject);
end;

class procedure Mapper.DataSetToObject(ADataSet: TDataSet; AObject: TObject);
var
  _type: TRttiType;
  _fields: TArray<TRttiProperty>;
  _field: TRttiProperty;
  _attribute: TCustomAttribute;
  _dict: TDictionary<String, String>;
  _keys: TDictionary<String, Boolean>;
  mf: MapperColumnAttribute;
  field_name: String;
  LValue: TValue;
  FoundAttribute: Boolean;
  FoundTransientAttribute: Boolean;
begin
  _dict := TDictionary<String, String>.Create();
  _keys := TDictionary<String, Boolean>.Create();
  _type := ctx.GetType(AObject.ClassInfo);
  _fields := _type.GetProperties;
  for _field in _fields do
  begin
    FoundAttribute := False;
    FoundTransientAttribute := False;
    for _attribute in _field.GetAttributes do
    begin
      if _attribute is MapperColumnAttribute then
      begin
        FoundAttribute := True;
        mf := MapperColumnAttribute(_attribute);
        _dict.Add(_field.Name, mf.FieldName);
        _keys.Add(_field.Name, mf.IsPK);
      end
      else if _attribute is MapperTransientAttribute then
        FoundTransientAttribute := True;
    end;
    if ((not FoundAttribute) and (not FoundTransientAttribute)) then
    begin
      _dict.Add(_field.Name, _field.Name);
      _keys.Add(_field.Name, False);
    end;
  end;
  for _field in _fields do
  begin
    if not _dict.TryGetValue(_field.Name, field_name) then
      Continue;
    case _field.PropertyType.TypeKind of
      tkEnumeration: // tristan
        begin
          if _field.PropertyType.Handle = TypeInfo(Boolean) then
          begin
            case ADataSet.FieldByName(field_name).DataType of
              ftInteger, ftSmallint, ftLargeint:
                begin
                  LValue := (ADataSet.FieldByName(field_name).AsInteger = 1);
                end;
              ftBoolean:
                begin
                  LValue := ADataSet.FieldByName(field_name).AsBoolean;
                end;
            else
              Continue;
            end;
          end;
        end;
      tkInteger:
        LValue := ADataSet.FieldByName(field_name).AsInteger;
      tkInt64:
        LValue := ADataSet.FieldByName(field_name).AsLargeInt;
      tkFloat:
        LValue := ADataSet.FieldByName(field_name).AsFloat;
      tkString:
        LValue := ADataSet.FieldByName(field_name).AsString;
      tkUString, tkWChar, tkLString, tkWString:
        LValue := ADataSet.FieldByName(field_name).AsWideString;
    else
      Continue;
    end;
    _field.SetValue(AObject, LValue);
  end;
  _dict.Free;
  _keys.Free;
end;

class function Mapper.ObjectListToJSONArrayFields<T>(AList: TObjectList<T>;
  AOwnsInstance: Boolean = False; AForEach: TJSONObjectActionProc = nil)
  : TJSONArray;
var
  I: Integer;
  LJSONObject: TJSONObject;
begin
  Result := TJSONArray.Create;
  if Assigned(AList) then
    for I := 0 to AList.Count - 1 do
    begin
      LJSONObject := ObjectToJSONObjectFields(AList[I], []);
      if Assigned(AForEach) then
        AForEach(LJSONObject);
      Result.AddElement(LJSONObject);
    end;
  if AOwnsInstance then
    AList.Free;
end;

class function Mapper.ObjectListToJSONArray<T>(AList: TObjectList<T>; AOwnsInstance: Boolean; AForEach: TJSONObjectActionProc): TJSONArray;
var
  I: Integer;
  LJSONObject: TJSONObject;
begin
  Result := TJSONArray.Create;
  if Assigned(AList) then
    for I := 0 to AList.Count - 1 do
    begin
      LJSONObject := ObjectToJSONObject(AList[I]);
      if Assigned(AForEach) then
        AForEach(LJSONObject);
      Result.AddElement(LJSONObject);
    end;
  if AOwnsInstance then
    AList.Free;
end;

class function Mapper.ObjectListToJSONArray(AList: IWrappedList;
  AOwnsChildObjects: Boolean; AForEach: TJSONObjectActionProc): TJSONArray;
var
  I: Integer;
  LJSONObject: TJSONObject;
begin
  Result := TJSONArray.Create;
  if Assigned(AList) then
  begin
    AList.OwnsObjects := AOwnsChildObjects;
    for I := 0 to AList.Count - 1 do
    begin
      LJSONObject := ObjectToJSONObject(AList.GetItem(I));
      if Assigned(AForEach) then
        AForEach(LJSONObject);
      Result.AddElement(LJSONObject);
    end;
  end;
end;

class function Mapper.ObjectListToJSONArrayOfJSONArray<T>(AList: TObjectList<T>)
  : TJSONArray;
var
  I: Integer;
begin
  Result := TJSONArray.Create;
  for I := 0 to AList.Count - 1 do
    Result.AddElement(ObjectToJSONArray(AList[I]));
end;

class function Mapper.ObjectListToJSONArrayString<T>(AList: TObjectList<T>;
  AOwnsInstance: Boolean): String;
var
  LJSONArray: TJSONArray;
begin
  LJSONArray := Mapper.ObjectListToJSONArray<T>(AList, AOwnsInstance);
  try
    Result := LJSONArray.ToString;
  finally
    LJSONArray.Free;
  end;
end;

class function Mapper.ObjectListToJSONArrayString(AList: IWrappedList;
  AOwnsChildObjects: Boolean): String;
var
  LJSONArray: TJSONArray;
begin
  LJSONArray := Mapper.ObjectListToJSONArray(AList, AOwnsChildObjects);
  try
    Result := LJSONArray.ToString;
  finally
    LJSONArray.Free;
  end;
end;

class procedure Mapper.ObjectToDataSet(Obj: TObject; Field: TField;
var
  LValue: Variant);
begin
  LValue := GetProperty(Obj, Field.FieldName).AsVariant;
end;

class function Mapper.ObjectToJSONArray(AObject: TObject): TJSONArray;
var
  LRTTIType: TRttiType;
  LProperties: TArray<TRttiProperty>;
  LProperty: TRttiProperty;
  LKeyName: String;
  LJArray: TJSONArray;
  LObj: TObject;
  LList: IWrappedList;
  LJArr: TJSONArray;
  LObjItem: TObject;
begin
  LJArray := TJSONArray.Create;
  LRTTIType := ctx.GetType(AObject.ClassInfo);
  LProperties := LRTTIType.GetProperties;
  for LProperty in LProperties do
  begin
    if HasAttribute<DoNotSerializeAttribute>(LProperty) then
      Continue;
    LKeyName := GetKeyName(LProperty, LRTTIType);
    case LProperty.PropertyType.TypeKind of
      tkEnumeration:
        begin
          LJArray
            .AddElement(SerializeEnumerationProperty(AObject, LProperty));
          // if LProperty.PropertyType.QualifiedName = 'System.Boolean' then
          // begin
          // if LProperty.GetValue(AObject).AsBoolean then
          // LJArray.AddElement(TJSONTrue.Create)
          // else
          // LJArray.AddElement(TJSONFalse.Create)
          // end;
        end;
      tkInteger, tkInt64:
        LJArray
          .AddElement(TJSONNumber.Create(LProperty.GetValue(AObject).AsInteger));
      tkFloat:
        begin
          LJArray
            .AddElement(SerializeFloatProperty(AObject, LProperty));
        end;
      tkString, tkLString, tkWString, tkUString:
        LJArray
          .AddElement(TJSONString.Create(LProperty.GetValue(AObject).AsString));
      tkClass:
        begin
          LObj := LProperty.GetValue(AObject).AsObject;
          if Assigned(LObj) then
          begin
            LList := nil;
            if TJKTypedList.CanBeWrappedAsList(LObj) then
              LList := WrapAsList(LObj);
            if Assigned(LList) then
            begin
              LJArr := TJSONArray.Create;
              LJArray.AddElement(LJArr);
              for LObjItem in LList do
              begin
                LJArr.AddElement(ObjectToJSONObject(LObjItem));
              end;
            end
            else
            begin
              LJArray
                .AddElement(ObjectToJSONObject(LProperty.GetValue(AObject).AsObject));
            end;
          end
          else
            LJArray.AddElement(TJSONNull.Create);
        end;
    end;
  end;

  Result := LJArray;
end;

class function Mapper.ObjectToJSONObject(AObject: TObject;
  AIgnoredProperties: array of String): TJSONObject;
var
  _type: TRttiType;
  _properties: TArray<TRttiProperty>;
  _property: TRttiProperty;
  LRttiProperty: String;
  LJSONObject: TJSONObject;
  LJSONArray: TJSONArray;
  LWrappList: IWrappedList;
  Obj, o: TObject;
  LDoNotSerializeThis: Boolean;
  I: Integer;
  LThereAreIgnoredProperties: Boolean;
  ts: TTimeStamp;
  sr: TStringStream;
  SS: TStringStream;
  _attrser: MapperSerializeAsString;
  LSerEnc: TEncoding;
  LATTRs: MapperItemsClassType;
  LListCount: Integer;
  LListItems: TRttiMethod;
  LListItemValue: TValue;
begin
  LThereAreIgnoredProperties := Length(AIgnoredProperties) > 0;
  LJSONObject := TJSONObject.Create;
  _type := ctx.GetType(AObject.ClassInfo);
  _properties := _type.GetProperties;
  for _property in _properties do
  begin
    // LRttiProperty := LowerCase(_property.Name);
    LRttiProperty := GetKeyName(_property, _type);
    // Delete(LRttiProperty, 1, 1);
    if LThereAreIgnoredProperties then
    begin
      LDoNotSerializeThis := False;
      for I := low(AIgnoredProperties) to high(AIgnoredProperties) do
        if SameText(LRttiProperty, AIgnoredProperties[I]) then
        begin
          LDoNotSerializeThis := True;
          Break;
        end;
      if LDoNotSerializeThis then
        Continue;
    end;

    if HasAttribute<DoNotSerializeAttribute>(_property) then
      Continue;

    case _property.PropertyType.TypeKind of
      tkInteger, tkInt64:
        LJSONObject
          .AddPair(LRttiProperty, TJSONNumber.Create(_property.GetValue(AObject).AsInteger));

      tkFloat:
        begin
          LJSONObject.AddPair(LRttiProperty, SerializeFloatProperty(AObject, _property));
          {
            if _property.PropertyType.QualifiedName = 'System.TDate' then
            begin
            if _property.GetValue(AObject).AsExtended = 0 then
            LJSONObject.AddPair(LRttiProperty, TJSONNull.Create)
            else
            LJSONObject.AddPair(LRttiProperty, ISODateToString(_property.GetValue(AObject).AsExtended))
            end
            else if _property.PropertyType.QualifiedName = 'System.TDateTime' then
            begin
            if _property.GetValue(AObject).AsExtended = 0 then
            LJSONObject.AddPair(LRttiProperty, TJSONNull.Create)
            else
            LJSONObject.AddPair(LRttiProperty, ISODateTimeToString(_property.GetValue(AObject).AsExtended))
            end
            else if _property.PropertyType.QualifiedName = 'System.TTime' then
            LJSONObject.AddPair(LRttiProperty, ISOTimeToString(_property.GetValue(AObject).AsExtended))
            else
            LJSONObject.AddPair(LRttiProperty, TJSONNumber.Create(_property.GetValue(AObject).AsExtended));
          }
        end;

      tkString, tkLString, tkWString, tkUString:
        LJSONObject
          .AddPair(LRttiProperty, _property.GetValue(AObject).AsString);

      tkEnumeration:
        begin
          LJSONObject
            .AddPair(LRttiProperty, SerializeEnumerationProperty(AObject, _property));
          // if _property.PropertyType.QualifiedName = 'System.Boolean' then
          // begin
          // if _property.GetValue(AObject).AsBoolean then
          // LJSONObject.AddPair(LRttiProperty, TJSONTrue.Create)
          // else
          // LJSONObject.AddPair(LRttiProperty, TJSONFalse.Create);
          // end
          // else
          // begin
          // LJSONObject.AddPair(LRttiProperty, TJSONNumber.Create(_property.GetValue(AObject).AsOrdinal));
          // end;
        end;

      tkRecord:
        begin
          if _property.PropertyType.QualifiedName = 'System.SysUtils.TTimeStamp'
          then
          begin
            ts := _property.GetValue(AObject).AsType<System.SysUtils.TTimeStamp>;
            LJSONObject
              .AddPair(LRttiProperty, TJSONNumber.Create(TimeStampToMsecs(ts)));
          end;
        end;

      tkClass:
        begin
          o := _property.GetValue(AObject).AsObject;
          if Assigned(o) then
          begin
            if TJKTypedList.CanBeWrappedAsList(o) then
            begin
              if Mapper.HasAttribute<MapperItemsClassType>(_property, LATTRs)
                  or Mapper.HasAttribute<MapperItemsClassType>(_property.PropertyType, LATTRs) then
              begin
                LWrappList := WrapAsList(o);
                if Assigned(LWrappList) then
                begin
                  LJSONArray := TJSONArray.Create;
                  LJSONObject
                    .AddPair(LRttiProperty, LJSONArray);

                  for Obj in LWrappList do
                    if Assigned(Obj) then
                    // nil element into the LWrappList are not serialized / elemento nulo no LWrappList não é serializado
                      LJSONArray
                        .AddElement(ObjectToJSONObject(Obj));
                end;
              end
              else // convert regular LWrappList / converter LWrappList regular
              begin
                LListCount := ctx.GetType(o.ClassInfo).GetProperty('Count')
                  .GetValue(o).AsInteger;
                LListItems := ctx.GetType(o.ClassInfo)
                  .GetIndexedProperty('Items').ReadMethod;
                if (LListCount > 0) and (LListItems <> nil) then
                begin
                  LJSONArray := TJSONArray.Create;
                  LJSONObject.AddPair(LRttiProperty, LJSONArray);
                  for I := 0 to LListCount - 1 do
                  begin
                    LListItemValue := LListItems.Invoke(o, [I]);
                    case LListItemValue.TypeInfo.Kind of
                      tkInteger:
                        LJSONArray
                          .AddElement(TJSONNumber.Create(LListItemValue.AsInteger));

                      tkInt64:
                        LJSONArray
                          .AddElement(TJSONNumber.Create(LListItemValue.AsInt64));

                      tkFloat:
                        LJSONArray
                          .AddElement(TJSONNumber.Create(LListItemValue.AsExtended));
                      tkString, tkLString, tkWString, tkUString:
                        LJSONArray
                          .AddElement(TJSONString.Create(LListItemValue.AsString));
                    end;
                  end;
                end;
              end;
            end
            else if o is TStream then
            begin
              if HasAttribute<MapperSerializeAsString>(_property, _attrser) then
              begin
                // serialize the stream as a normal String... / serializar o stream como uma String normal...
                TStream(o).Position := 0;
                LSerEnc := TEncoding.GetEncoding(_attrser.Encoding);
                sr := TStringStream.Create('', LSerEnc);
                try
                  sr.LoadFromStream(TStream(o));
                  LJSONObject.AddPair(LRttiProperty, sr.DataString);
                finally
                  sr.Free;
                end;
              end
              else
              begin
                // serialize the stream as Base64 encoded String... / serializar o stream como String codificada em Base64...
                TStream(o).Position := 0;
                SS := TStringStream.Create;
                try
                  EncodeStream(TStream(o), SS);
                  LJSONObject
                    .AddPair(LRttiProperty, SS.DataString);
                finally
                  SS.Free;
                end;
              end;
            end
            else
            begin
              LJSONObject
                .AddPair(LRttiProperty, ObjectToJSONObject(_property.GetValue(AObject).AsObject));
            end;
          end
          else
          begin
            if HasAttribute<MapperSerializeAsString>(_property) then
              LJSONObject
                .AddPair(LRttiProperty, '')
            else
              LJSONObject
                .AddPair(LRttiProperty, TJSONNull.Create);
          end;
        end;
    end;
  end;
  Result := LJSONObject;
end;

class function Mapper.ObjectToJSONObject(AObject: TObject): TJSONObject;
begin
  Result := ObjectToJSONObject(AObject, []);
end;

class function Mapper.ObjectToJSONObjectFields(AObject: TObject;
  AIgnoredProperties: array of String): TJSONObject;
var
  _type: TRttiType;
  _fields: TArray<TRttiField>;
  _field: TRttiField;
  LRttiProperty: String;
  LJSONObject: TJSONObject;
  LJSONArray: TJSONArray;
  LWrappList: IWrappedList;
  Obj, o: TObject;
  LDoNotSerializeThis: Boolean;
  I: Integer;
  LThereAreIgnoredProperties: Boolean;
  LJObj: TJSONObject;
begin
  LThereAreIgnoredProperties := Length(AIgnoredProperties) > 0;
  LJSONObject := TJSONObject.Create;
  try
    // add the $dmvc.classname property to allows a strict deserialization
    LJSONObject
      .AddPair(DMVC_CLASSNAME, AObject.QualifiedClassName);
    _type := ctx.GetType(AObject.ClassInfo);
    _fields := _type.GetFields;
    for _field in _fields do
    begin
      LRttiProperty := GetKeyName(_field, _type);
      if LThereAreIgnoredProperties then
      begin
        LDoNotSerializeThis := False;
        for I := low(AIgnoredProperties) to high(AIgnoredProperties) do
          if SameText(LRttiProperty, AIgnoredProperties[I]) then
          begin
            LDoNotSerializeThis := True;
            Break;
          end;
        if LDoNotSerializeThis then
          Continue;
      end;
      case _field.FieldType.TypeKind of

        tkInteger, tkInt64:
          LJSONObject
            .AddPair(LRttiProperty, TJSONNumber.Create(_field.GetValue(AObject).AsInteger));

        tkFloat:
          LJSONObject
            .AddPair(LRttiProperty, SerializeFloatField(AObject, _field));

        tkString, tkLString, tkWString, tkUString:
          LJSONObject
            .AddPair(LRttiProperty, _field.GetValue(AObject).AsString);

        tkEnumeration:
          LJSONObject
            .AddPair(LRttiProperty, SerializeEnumerationField(AObject, _field));

        tkClass:
          begin
            o := _field.GetValue(AObject).AsObject;
            if Assigned(o) then
            begin
              if TJKTypedList.CanBeWrappedAsList(o) then
              begin
                LWrappList := WrapAsList(o);
                LJObj := TJSONObject.Create;
                LJSONObject
                  .AddPair(LRttiProperty, LJObj);
                LJObj
                  .AddPair(DMVC_CLASSNAME, o.QualifiedClassName);
                LJSONArray := TJSONArray.Create;
                LJObj
                  .AddPair('items', LJSONArray);
                for Obj in LWrappList do
                begin
                  LJSONArray
                    .AddElement(ObjectToJSONObjectFields(Obj, []));
                end;
              end
              else
              begin
                LJSONObject
                  .AddPair(LRttiProperty, ObjectToJSONObjectFields(_field.GetValue(AObject).AsObject, []));
              end;
            end
            else
              LJSONObject
                .AddPair(LRttiProperty, TJSONNull.Create);
          end;
      end;
    end;
    Result := LJSONObject;
  except
    FreeAndNil(LJSONObject);
    raise;
  end;
end;

class function Mapper.ObjectToJSONObjectFieldsString(AObject: TObject;
  AIgnoredProperties: array of String): String;
var
  LJObj: TJSONObject;
begin
  LJObj := ObjectToJSONObjectFields(AObject, AIgnoredProperties);
  try
{$IF CompilerVersion >= 28}
    Result := LJObj.ToJSON;
{$ELSE}
    Result := LJObj.ToString
{$ENDIF}
  finally
    LJObj.Free;
  end;
end;

class function Mapper.ObjectToJSONObjectString(AObject: TObject): String;
var
  JObj: TJSONObject;
begin
  JObj := ObjectToJSONObject(AObject);
  try
    Result := JObj.ToString;
  finally
    JObj.Free;
  end;
end;

class function Mapper.PropertyExists(LJSONObject: TJSONObject;
  PropertyName: String): Boolean;
begin
  Result := Assigned(GetPair(LJSONObject, PropertyName));
end;

class function Mapper.SerializeEnumerationField(AObject: TObject;
  ARttiField: TRttiField): TJSONValue;
begin
  if ARttiField.FieldType.QualifiedName = 'System.Boolean' then
  begin
    if ARttiField.GetValue(AObject).AsBoolean then
      Result := TJSONTrue.Create
    else
      Result := TJSONFalse.Create;
  end
  else
  begin
    Result := TJSONNumber.Create(ARttiField.GetValue(AObject).AsOrdinal);
  end;
end;

class function Mapper.SerializeEnumerationProperty(AObject: TObject;
  ARTTIProperty: TRttiProperty): TJSONValue;
begin
  if ARTTIProperty.PropertyType.QualifiedName = 'System.Boolean' then
  begin
    if ARTTIProperty.GetValue(AObject).AsBoolean then
      Result := TJSONTrue.Create
    else
      Result := TJSONFalse.Create;
  end
  else
  begin
    Result := TJSONNumber.Create(ARTTIProperty.GetValue(AObject).AsOrdinal);
  end;
end;

class function Mapper.SerializeFloatField(AObject: TObject;
  ARttiField: TRttiField): TJSONValue;
begin
  if ARttiField.FieldType.QualifiedName = 'System.TDate' then
  begin
    if ARttiField.GetValue(AObject).AsExtended = 0 then
      Result := TJSONNull.Create
    else
      Result := TJSONString.Create(ISODateToString(ARttiField.GetValue(AObject).AsExtended))
  end
  else if ARttiField.FieldType.QualifiedName = 'System.TDateTime' then
  begin
    if ARttiField.GetValue(AObject).AsExtended = 0 then
      Result := TJSONNull.Create
    else
      Result := TJSONString.Create
        (ISODateTimeToString(ARttiField.GetValue(AObject).AsExtended))
  end
  else if ARttiField.FieldType.QualifiedName = 'System.TTime' then
    Result := TJSONString.Create(ISOTimeToString(ARttiField.GetValue(AObject).AsExtended))
  else
    Result := TJSONNumber.Create(ARttiField.GetValue(AObject).AsExtended);
end;

class function Mapper.SerializeFloatProperty(AObject: TObject;
  ARTTIProperty: TRttiProperty): TJSONValue;
begin
  if ARTTIProperty.PropertyType.QualifiedName = 'System.TDate' then
  begin
    if ARTTIProperty.GetValue(AObject).AsExtended = 0 then
      Result := TJSONNull.Create
    else
      Result := TJSONString.Create
        (ISODateToString(ARTTIProperty.GetValue(AObject).AsExtended));
  end
  else if ARTTIProperty.PropertyType.QualifiedName = 'System.TDateTime' then
  begin
    if ARTTIProperty.GetValue(AObject).AsExtended = 0 then
      Result := TJSONNull.Create
    else
      Result := TJSONString.Create
        (ISODateTimeToString(ARTTIProperty.GetValue(AObject).AsExtended))
  end
  else if ARTTIProperty.PropertyType.QualifiedName = 'System.TTime' then
    Result := TJSONString.Create(ISOTimeToString(ARTTIProperty.GetValue(AObject)
      .AsExtended))
  else
    Result := TJSONNumber.Create(ARTTIProperty.GetValue(AObject).AsExtended);

  // if ARTTIProperty.PropertyType.QualifiedName = 'System.TDate' then
  // Result := TJSONString.Create(ISODateToString(ARTTIProperty.GetValue(AObject).AsExtended))
  // else if ARTTIProperty.PropertyType.QualifiedName = 'System.TDateTime' then
  // Result := TJSONString.Create(ISODateTimeToString(ARTTIProperty.GetValue(AObject).AsExtended))
  // else if ARTTIProperty.PropertyType.QualifiedName = 'System.TTime' then
  // Result := TJSONString.Create(ISOTimeToString(ARTTIProperty.GetValue(AObject).AsExtended))
  // else
  // Result := TJSONNumber.Create(ARTTIProperty.GetValue(AObject).AsExtended);
end;

class function Mapper.GetKeyName(const ARttiField: TRttiField;
  AType: TRttiType): String;
var
  LATTRArray: TArray<TCustomAttribute>;
  LATTRs: TCustomAttribute;
begin
  // JSONSer property attribute handling
  LATTRArray := ARttiField.GetAttributes;
  for LATTRs in LATTRArray do
  begin
    if LATTRs is MapperJSONSer then
      Exit(MapperJSONSer(LATTRs).Name);
  end;

  // JSONNaming class attribute handling
  LATTRArray := AType.GetAttributes;
  for LATTRs in LATTRArray do
  begin
    if LATTRs is MapperJSONNaming then
    begin
      case MapperJSONNaming(LATTRs).GetKeyCase of
        JSONNameUpperCase:
          begin
            Exit(UpperCase(ARttiField.Name));
          end;
        JSONNameLowerCase:
          begin
            Exit(LowerCase(ARttiField.Name));
          end;
      end;
    end;
  end;

  // Default
  Result := ARttiField.Name;
end;

class function Mapper.GetBooleanDef(LJSONObject: TJSONObject;
  PropertyName: String; DefaultValue: Boolean): Boolean;
var
  pair: TJSONPair;
begin
  pair := GetPair(LJSONObject, PropertyName);
  if pair = nil then
    Exit(DefaultValue);
  if pair.JsonValue is TJSONFalse then
    Exit(False)
  else if pair.JsonValue is TJSONTrue then
    Exit(True)
  else
    raise EMapperException.CreateFmt('Property %s is not a Boolean Property',
      [PropertyName]);
end;

class function Mapper.GetInt64Def(LJSONObject: TJSONObject; PropertyName: String;
  DefaultValue: Int64): Int64;
var
  pair: TJSONPair;
begin
  pair := GetPair(LJSONObject, PropertyName);
  if pair = nil then
    Exit(DefaultValue);
  if pair.JsonValue is TJSONNumber then
    Exit(TJSONNumber(pair.JsonValue).AsInt64)
  else
    raise EMapperException.CreateFmt('Property %s is not a Int64 Property',
      [PropertyName]);
end;

class function Mapper.GetIntegerDef(LJSONObject: TJSONObject;
  PropertyName: String; DefaultValue: Integer): Integer;
var
  pair: TJSONPair;
begin
  pair := GetPair(LJSONObject, PropertyName);
  if pair = nil then
    Exit(DefaultValue);
  if pair.JsonValue is TJSONNumber then
    Exit(TJSONNumber(pair.JsonValue).AsInt)
  else
    raise EMapperException.CreateFmt('Property %s is not an Integer Property',
      [PropertyName]);

end;

class function Mapper.GetJSONArray(LJSONObject: TJSONObject;
  PropertyName: String): TJSONArray;
var
  pair: TJSONPair;
begin
  pair := GetPair(LJSONObject, PropertyName);
  if pair = nil then
    Exit(nil);
  if pair.JsonValue is TJSONArray then
    Exit(TJSONArray(pair.JsonValue))
  else
    raise EMapperException.Create('Property is not a JSONArray');

end;

class function Mapper.GetJSONObj(LJSONObject: TJSONObject; PropertyName: String)
  : TJSONObject;
var
  pair: TJSONPair;
begin
  pair := GetPair(LJSONObject, PropertyName);
  if pair = nil then
    Exit(nil);
  if pair.JsonValue is TJSONObject then
    Exit(TJSONObject(pair.JsonValue))
  else
    raise EMapperException.Create('Property is not a JSONObject');
end;

class function Mapper.GetKeyName(const ARttiProp: TRttiProperty;
  AType: TRttiType): String;
var
  LATTRArray: TArray<TCustomAttribute>;
  LATTRs: TCustomAttribute;
begin
  // JSONSer property attribute handling
  LATTRArray := ARttiProp.GetAttributes;
  for LATTRs in LATTRArray do
  begin
    if LATTRs is MapperJSONSer then
      Exit(MapperJSONSer(LATTRs).Name);
  end;

  // JSONNaming class attribute handling
  LATTRArray := AType.GetAttributes;
  for LATTRs in LATTRArray do
  begin
    if LATTRs is MapperJSONNaming then
    begin
      case MapperJSONNaming(LATTRs).GetKeyCase of
        JSONNameUpperCase:
          begin
            Exit(UpperCase(ARttiProp.Name));
          end;
        JSONNameLowerCase:
          begin
            Exit(LowerCase(ARttiProp.Name));
          end;
      end;
    end;
  end;

  // Default
  Result := ARttiProp.Name;
end;

class function Mapper.GetNumberDef(LJSONObject: TJSONObject;
  PropertyName: String; DefaultValue: Extended): Extended;
var
  pair: TJSONPair;
begin
  pair := GetPair(LJSONObject, PropertyName);
  if pair = nil then
    Exit(DefaultValue);
  if pair.JsonValue is TJSONNumber then
    Exit(TJSONNumber(pair.JsonValue).AsDouble)
  else
    raise EMapperException.Create('Property is not a Number Property');
end;

class function Mapper.GetPair(LJSONObject: TJSONObject; PropertyName: String)
  : TJSONPair;
var
  pair: TJSONPair;
begin
  if not Assigned(LJSONObject) then
    raise EMapperException.Create('JSONObject is nil');
  pair := LJSONObject.Get(PropertyName);
  Result := pair;
end;

class function Mapper.GetProperty(Obj: TObject;
  const PropertyName: String): TValue;
var
  Prop: TRttiProperty;
  ARTTIType: TRttiType;
begin
  ARTTIType := ctx.GetType(Obj.ClassType);
  if not Assigned(ARTTIType) then
    raise EMapperException.CreateFmt('Cannot get RTTI for type [%s]',
      [ARTTIType.ToString]);
  Prop := ARTTIType.GetProperty(PropertyName);
  if not Assigned(Prop) then
    raise EMapperException.CreateFmt('Cannot get RTTI for property [%s.%s]',
      [ARTTIType.ToString, PropertyName]);
  if Prop.IsReadable then
    Result := Prop.GetValue(Obj)
  else
    raise EMapperException.CreateFmt('Property is not readable [%s.%s]',
      [ARTTIType.ToString, PropertyName]);
end;

class function Mapper.GetStringDef(LJSONObject: TJSONObject;
  PropertyName, DefaultValue: String): String;
var
  pair: TJSONPair;
begin
  pair := GetPair(LJSONObject, PropertyName);
  if pair = nil then
    Exit(DefaultValue);
  if pair.JsonValue is TJSONString then
    Exit(TJSONString(pair.JsonValue).Value)
  else
    raise EMapperException.Create('Property is not a String Property');
end;

class function Mapper.HasAttribute<T>(ARTTIMember: TRttiNamedObject;
  out AAttribute: T): Boolean;
var
  LATTRArray: TArray<TCustomAttribute>;
  LATTRs: TCustomAttribute;
begin
  AAttribute := nil;
  Result := False;
  LATTRArray := ARTTIMember.GetAttributes;
  for LATTRs in LATTRArray do
    if LATTRs is T then
    begin
      AAttribute := T(LATTRs);
      Exit(True);
    end;
end;

class function Mapper.HasAttribute<T>(ARTTIMember: TRttiNamedObject): Boolean;
var
  LATTRArray: TArray<TCustomAttribute>;
  LATTRs: TCustomAttribute;
begin
  Result := False;
  LATTRArray := ARTTIMember.GetAttributes;
  for LATTRs in LATTRArray do
    if LATTRs is T then
      Exit(True);
end;

class procedure Mapper.JSONArrayToDataSet(AJSONArray: TJSONArray; ADataSet: TDataSet;
    AJSONArrayInstanceOwner: Boolean);
begin
  JSONArrayToDataSet(AJSONArray, ADataSet, TArray<String>.Create(),
    AJSONArrayInstanceOwner);
end;

class procedure Mapper.JSONArrayToDataSet(AJSONArray: TJSONArray; ADataSet: TDataSet; AIgnoredFields: TArray<String>;
  AJSONArrayInstanceOwner: Boolean; AFieldNamePolicy: TFieldNamePolicy);
var
  I: Integer;
begin
  for I := 0 to AJSONArray.Size - 1 do
  begin
    ADataSet.Append;
    Mapper.JSONObjectToDataSet(AJSONArray.Get(I) as TJSONObject, ADataSet,
      AIgnoredFields, False, AFieldNamePolicy);
    ADataSet.Post;
  end;
  if AJSONArrayInstanceOwner then
    AJSONArray.Free;
end;

class function Mapper.JSONArrayToObjectList(AListOf: TClass; AJSONArray: TJSONArray; AInstanceOwner: Boolean = True;
  AOwnsChildObjects: Boolean = True): TObjectList<TObject>;
var
  I: Integer;
begin
  Result := nil;
  if Assigned(AJSONArray) then
  begin
    Result := TObjectList<TObject>.Create(AOwnsChildObjects);
    for I := 0 to AJSONArray.Size - 1 do
      Result.Add(Mapper.JSONObjectToObject(AListOf,
        AJSONArray.Get(I) as TJSONObject));
    if AInstanceOwner then
      AJSONArray.Free;
  end;
end;

class procedure Mapper.JSONArrayToObjectList(AList: IWrappedList; AListOf: TClass; AJSONArray: TJSONArray;
  AInstanceOwner: Boolean = True; AOwnsChildObjects: Boolean = True);
var
  I: Integer;
begin
  if Assigned(AJSONArray) then
  begin
    AList.OwnsObjects := AOwnsChildObjects;
    for I := 0 to AJSONArray.Size - 1 do
      AList.Add(Mapper.JSONObjectToObject(AListOf,
        AJSONArray.Get(I) as TJSONObject));
    if AInstanceOwner then
      AJSONArray.Free;
  end;
end;

class procedure Mapper.JSONArrayToObjectList<T>(AList: TObjectList<T>; AJSONArray: TJSONArray; AInstanceOwner,
  AOwnsChildObjects: Boolean);
var
  I: Integer;
begin
  if Assigned(AJSONArray) then
  begin
    for I := 0 to AJSONArray.Size - 1 do
      AList.Add(Mapper.JSONObjectToObject<T>(AJSONArray.Get(I) as TJSONObject));

    if AInstanceOwner then
      AJSONArray.Free;
  end;
end;

class function Mapper.JSONArrayToObjectList<T>(AJSONArray: TJSONArray; AInstanceOwner: Boolean;
  AOwnsChildObjects: Boolean): TObjectList<T>;
begin
  Result := TObjectList<T>.Create(AOwnsChildObjects);
  JSONArrayToObjectList<T>(Result, AJSONArray, AInstanceOwner, AOwnsChildObjects);
end;

class procedure Mapper.InternalJSONObjectFieldsToObject(ctx: TRTTIContext;
  AJSONObject: TJSONObject; AObject: TObject);
  procedure RaiseExceptForField(FieldName: String);
  begin
    raise EMapperException.Create
      (FieldName + ' key field is not present in the JSONObject');
  end;

var
  _type: TRttiType;
  _fields: TArray<TRttiField>;
  _field: TRttiField;
  LRttiProperty: String;
  LJSONValue: TJSONValue;
  v: TValue;
  o: TObject;
  LWrappList: IWrappedList;
  I: Integer;
  LJSONArray: TJSONArray;
  n: TJSONNumber;
  SerStreamASString: String;
  sw: TStreamWriter;
  SS: TStringStream;
  _attrser: MapperSerializeAsString;
  LSerEnc: TEncoding;
  LClassName: String;
  LJSONKeyIsNotPresent: Boolean;
begin
  LJSONValue := nil;
  _type := ctx.GetType(AObject.ClassInfo);
  _fields := _type.GetFields;

  for _field in _fields do
  begin
    if HasAttribute<MapperTransientAttribute>(_field) then
      Continue;
    LRttiProperty := GetKeyName(_field, _type);
    if Assigned(AJSONObject.Get(LRttiProperty)) then
    begin
      LJSONKeyIsNotPresent := False;
      LJSONValue := AJSONObject.Get(LRttiProperty).JsonValue;
    end
    else
    begin
      LJSONKeyIsNotPresent := True;
    end;

    case _field.FieldType.TypeKind of
      tkEnumeration:
        begin
          if LJSONKeyIsNotPresent then
            RaiseExceptForField(_field.Name);
          if _field.FieldType.QualifiedName = 'System.Boolean' then
          begin
            if LJSONValue is TJSONTrue then
              _field.SetValue(TObject(AObject), True)
            else if LJSONValue is TJSONFalse then
              _field.SetValue(TObject(AObject), False)
            else
              raise EMapperException.Create('Invalid value for property ' +
                _field.Name);
          end
          else // it is an enumerated LValue but it's not a boolean.
          begin
            TValue.Make((LJSONValue as TJSONNumber).AsInt,
              _field.FieldType.Handle, v);
            _field.SetValue(TObject(AObject), v);
          end;
        end;

      tkInteger, tkInt64:
        begin
          if LJSONKeyIsNotPresent then
            _field.SetValue(TObject(AObject), 0)
          else
            _field.SetValue(TObject(AObject), StrToIntDef(LJSONValue.Value, 0));
        end;

      tkFloat:
        begin
          if LJSONKeyIsNotPresent then
          begin
            _field.SetValue(TObject(AObject), 0);
          end
          else
          begin
            if _field.FieldType.QualifiedName = 'System.TDate' then
            begin
              if LJSONValue is TJSONNull then
                _field.SetValue(TObject(AObject), 0)
              else
                _field.SetValue(TObject(AObject),
                  ISOStrToDateTime(LJSONValue.Value + ' 00:00:00'))
            end
            else if _field.FieldType.QualifiedName = 'System.TDateTime' then
            begin
              if LJSONValue is TJSONNull then
                _field.SetValue(TObject(AObject), 0)
              else
                _field.SetValue(TObject(AObject),
                  ISOStrToDateTime(LJSONValue.Value))
            end
            else if _field.FieldType.QualifiedName = 'System.TTime' then
            begin
              if LJSONValue is TJSONString then
                _field.SetValue(TObject(AObject), ISOStrToTime(LJSONValue.Value))
              else
                raise EMapperException.CreateFmt
                  ('Cannot deserialize [%s], expected [%s] got [%s]',
                  [_field.Name, 'TJSONString', LJSONValue.ClassName]);
            end
            else { if _field.PropertyType.QualifiedName = 'System.Currency' then }
            begin
              if LJSONValue is TJSONNumber then
                _field.SetValue(TObject(AObject), TJSONNumber(LJSONValue).AsDouble)
              else
                raise EMapperException.CreateFmt
                  ('Cannot deserialize [%s], expected [%s] got [%s]',
                  [_field.Name, 'TJSONNumber', LJSONValue.ClassName]);
            end;
          end;
        end;

      tkString, tkLString, tkWString, tkUString:
        begin
          if LJSONKeyIsNotPresent then
            _field.SetValue(TObject(AObject), '')
          else
            _field.SetValue(TObject(AObject), LJSONValue.Value);
        end;

      tkRecord:
        begin
          if _field.FieldType.QualifiedName = 'System.SysUtils.TTimeStamp' then
          begin
            if LJSONKeyIsNotPresent then
            begin
              _field.SetValue(TObject(AObject),
                TValue.From<TTimeStamp>(MSecsToTimeStamp(0)));
            end
            else
            begin
              n := LJSONValue as TJSONNumber;
              _field.SetValue(TObject(AObject),
                TValue.From<TTimeStamp>(MSecsToTimeStamp(n.AsInt64)));
            end;
          end;
        end;

      tkClass: // try to restore child properties... but only if the collection is not nil!!! / tente restaurar as propriedades dos filhos ... mas apenas se a coleção não for nula !!!
        begin
          o := _field.GetValue(TObject(AObject)).AsObject;
          if LJSONKeyIsNotPresent then
          begin
            o.Free;
            o := nil;
            _field.SetValue(AObject, nil);
          end;

          if Assigned(o) then
          begin
            if o is TStream then
            begin
              if LJSONValue is TJSONString then
              begin
                SerStreamASString := TJSONString(LJSONValue).Value;
              end
              else
                raise EMapperException.Create('Expected JSONString in ' +
                  AJSONObject.Get(LRttiProperty).JsonString.Value);

              if HasAttribute<MapperSerializeAsString>(_field, _attrser) then
              begin
                // serialize the stream as a normal String... / serializar o stream como uma string normal...
                TStream(o).Position := 0;
                LSerEnc := TEncoding.GetEncoding(_attrser.Encoding);
                SS := TStringStream.Create(SerStreamASString, LSerEnc);
                try
                  SS.Position := 0;
                  TStream(o).CopyFrom(SS, SS.Size);
                finally
                  SS.Free;
                end;
              end
              else
              begin
                // deserialize the stream as Base64 encoded String...
                TStream(o).Position := 0;
                sw := TStreamWriter.Create(TStream(o));
                try
                  sw.Write(DecodeString(SerStreamASString));
                finally
                  sw.Free;
                end;
              end;
            end
            else if TJKTypedList.CanBeWrappedAsList(o) then
            begin // restore collection / restaurar a colecao
              if not(LJSONValue is TJSONObject) then
                raise EMapperException.Create('Wrong serialization for ' +
                  o.QualifiedClassName);
              LClassName := TJSONObject(LJSONValue).Get(DMVC_CLASSNAME)
                .JsonValue.Value;
              if o = nil then // recreate the object as it should be
              begin
                o := TRTTIUtils.CreateObject(LClassName);
              end;
              LJSONValue := TJSONObject(LJSONValue).Get('items').JsonValue;
              if LJSONValue is TJSONArray then
              begin
                LJSONArray := TJSONArray(LJSONValue);
                begin
                  LWrappList := WrapAsList(o);
                  for I := 0 to LJSONArray.Size - 1 do
                  begin
                    LWrappList.Add(Mapper.JSONObjectFieldsToObject(LJSONArray.Get(I)
                      as TJSONObject));
                  end;
                end;
              end
              else
                raise EMapperException.Create('Cannot restore ' + LRttiProperty +
                  ' because the related json property is not an array');
            end
            else // try to deserialize into the property... but the json MUST be an object
            begin
              if LJSONValue is TJSONObject then
              begin
                InternalJSONObjectFieldsToObject(ctx, TJSONObject(LJSONValue), o);
              end
              else if LJSONValue is TJSONNull then
              begin
                FreeAndNil(o);
                _field.SetValue(AObject, nil)
              end
              else
                raise EMapperException.Create('Cannot deserialize property ' +
                  _field.Name);
            end;
          end;
        end;
    end;
  end;
end;

class procedure Mapper.InternalJSONObjectToObject(ctx: TRTTIContext; AJSONObject: TJSONObject; AObject: TObject);
var
  _type: TRttiType;
  _fields: TArray<TRttiProperty>;
  _field: TRttiProperty;
  LRttiProperty: String;
  LJSONValue: TJSONValue;
  v: TValue;
  o: TObject;
  LWrappList: IWrappedList;
  I: Integer;
  cref: TClass;
  LATTRs: MapperItemsClassType;
  LJSONArray: TJSONArray;
  n: TJSONNumber;
  SerStreamASString: String;
  // EncBytes: TBytes;
  sw: TStreamWriter;
  SS: TStringStream;
  _attrser: MapperSerializeAsString;
  LSerEnc: TEncoding;
  ListMethod: TRttiMethod;
  ListItem: TValue;
  ListParam: TRttiParameter;
begin
  _type := ctx.GetType(AObject.ClassInfo);
  _fields := _type.GetProperties;
  for _field in _fields do
  begin
    if ((not _field.IsWritable) and (_field.PropertyType.TypeKind <> tkClass))
      or (HasAttribute<MapperTransientAttribute>(_field)) then
      Continue;
    LRttiProperty := GetKeyName(_field, _type);
    if Assigned(AJSONObject.Get(LRttiProperty)) then
      LJSONValue := AJSONObject.Get(LRttiProperty).JsonValue
    else
      Continue;
    case _field.PropertyType.TypeKind of
      tkEnumeration:
        begin
          if _field.PropertyType.QualifiedName = 'System.Boolean' then
          begin
            if LJSONValue is TJSONTrue then
              _field.SetValue(TObject(AObject), True)
            else if LJSONValue is TJSONFalse then
              _field.SetValue(TObject(AObject), False)
            else
              raise EMapperException.Create('Invalid value for property ' +
                _field.Name);
          end
          else // it is an enumerated LValue but it's not a boolean. / é um LValue enumerado, mas não é um booleano.
          begin
            TValue.Make((LJSONValue as TJSONNumber).AsInt,
              _field.PropertyType.Handle, v);
            _field.SetValue(TObject(AObject), v);
          end;
        end;

      tkInteger, tkInt64:
        _field.SetValue(TObject(AObject), StrToIntDef(LJSONValue.Value, 0));

      tkFloat:
        begin
          if _field.PropertyType.QualifiedName = 'System.TDate' then
          begin
            if LJSONValue is TJSONNull then
              _field.SetValue(TObject(AObject), 0)
            else
              _field.SetValue(TObject(AObject),
                ISOStrToDateTime(LJSONValue.Value + ' 00:00:00'))
          end
          else if _field.PropertyType.QualifiedName = 'System.TDateTime' then
          begin
            if LJSONValue is TJSONNull then
              _field.SetValue(TObject(AObject), 0)
            else
              _field.SetValue(TObject(AObject), ISOStrToDateTime(LJSONValue.Value))
          end
          else if _field.PropertyType.QualifiedName = 'System.TTime' then
          begin
            if LJSONValue is TJSONString then
              _field.SetValue(TObject(AObject), ISOStrToTime(LJSONValue.Value))
            else
              raise EMapperException.CreateFmt
                ('Cannot deserialize [%s], expected [%s] got [%s]',
                [_field.Name, 'TJSONString', LJSONValue.ClassName]);
          end
          else { if _field.PropertyType.QualifiedName = 'System.Currency' then }
          begin
            if LJSONValue is TJSONNumber then
              _field.SetValue(TObject(AObject), TJSONNumber(LJSONValue).AsDouble)
            else
              raise EMapperException.CreateFmt
                ('Cannot deserialize [%s], expected [%s] got [%s]',
                [_field.Name, 'TJSONNumber', LJSONValue.ClassName]);
          end {
            else
            begin
            _field.SetValue(TObject(AObject), (LJSONValue as TJSONNumber).AsDouble)
            end; }
        end;

      tkString, tkLString, tkWString, tkUString:
        begin
          _field.SetValue(TObject(AObject), LJSONValue.Value);
        end;

      tkRecord:
        begin
          if _field.PropertyType.QualifiedName = 'System.SysUtils.TTimeStamp'
          then
          begin
            n := LJSONValue as TJSONNumber;
            _field.SetValue(TObject(AObject),
              TValue.From<TTimeStamp>(MSecsToTimeStamp(n.AsInt64)));
          end;
        end;

      tkClass: // try to restore child properties... but only if the collection is not nil!!! / tente restaurar as propriedades dos filhos... mas apenas se a coleção não for nula!!!
        begin
          o := _field.GetValue(TObject(AObject)).AsObject;
          if Assigned(o) then
          begin
            if o is TStream then
            begin
              if LJSONValue is TJSONString then
              begin
                SerStreamASString := TJSONString(LJSONValue).Value;
              end
              else
                raise EMapperException.Create('Expected JSONString in ' +
                  AJSONObject.Get(LRttiProperty).JsonString.Value);

              if HasAttribute<MapperSerializeAsString>(_field, _attrser) then
              begin
                // serialize the stream as a normal String... / serializar o stream como uma string normal...
                TStream(o).Position := 0;
                LSerEnc := TEncoding.GetEncoding(_attrser.Encoding);
                SS := TStringStream.Create(SerStreamASString, LSerEnc);
                try
                  SS.Position := 0;
                  TStream(o).CopyFrom(SS, SS.Size);
                finally
                  SS.Free;
                end;
              end
              else
              begin
                // deserialize the stream as Base64 encoded String... / desserializar o stream como String codificada em Base64...
                TStream(o).Position := 0;
                sw := TStreamWriter.Create(TStream(o));
                try
                  sw.Write(DecodeString(SerStreamASString));
                finally
                  sw.Free;
                end;
              end;
            end
            else if TJKTypedList.CanBeWrappedAsList(o) then
            begin // restore collection
              if LJSONValue is TJSONArray then
              begin
                LJSONArray := TJSONArray(LJSONValue);
                // look for the MapperItemsClassType on the property itself or on the property type c / procure o MapperItemsClassType na própria propriedade ou no tipo de propriedade c
                if Mapper.HasAttribute<MapperItemsClassType>(_field, LATTRs)
                    or Mapper.HasAttribute<MapperItemsClassType>(_field.PropertyType, LATTRs) then
                begin
                  cref := LATTRs.LValue;
                  LWrappList := WrapAsList(o);
                  for I := 0 to LJSONArray.Size - 1 do
                  begin
                    LWrappList
                      .Add(Mapper.JSONObjectToObject(cref, LJSONArray.Get(I) as TJSONObject));
                  end;
                end
                else // convert regular LWrappList / converter LWrappList regular
                begin
                  ListMethod := ctx.GetType(o.ClassInfo).GetMethod('Add');
                  if (ListMethod <> nil) then
                  begin
                    for I := 0 to LJSONArray.Size - 1 do
                    begin
                      ListItem := TValue.Empty;

                      for ListParam in ListMethod.GetParameters do
                        case ListParam.ParamType.TypeKind of
                          tkInteger, tkInt64:
                            ListItem := StrToIntDef(LJSONArray.Get(I).Value, 0);

                          tkFloat:
                            ListItem := TJSONNumber(LJSONArray.Get(I).Value).AsDouble;

                          tkString, tkLString, tkWString, tkUString:
                            ListItem := LJSONArray.Get(I).Value;
                        end;
                      if not ListItem.IsEmpty then
                        ListMethod.Invoke(o, [ListItem]);
                    end;
                  end;
                end;
              end
              else
                raise EMapperException.Create('Cannot restore ' + LRttiProperty +
                  ' because the related json property is not an array');
            end
            else // try to deserialize into the property... but the json MUST be an object / tente desserializar na propriedade ... mas o JSON DEVE ser um objeto
            begin
              if LJSONValue is TJSONObject then
              begin
                InternalJSONObjectToObject(ctx, TJSONObject(LJSONValue), o);
              end
              else if LJSONValue is TJSONNull then
              begin
                FreeAndNil(o);
                _field.SetValue(AObject, nil);
              end
              else
                raise EMapperException.Create('Cannot deserialize property ' + _field.Name);
            end;
          end;
        end;
    end;
  end;
end;

class function Mapper.JSONObjectToObject(Clazz: TClass;
  AJSONObject: TJSONObject): TObject;
var
  LObject: TObject;
begin
  LObject := TRTTIUtils.CreateObject(Clazz.QualifiedClassName);
  try
    InternalJSONObjectToObject(ctx, AJSONObject, LObject);
    Result := LObject;
  except
    // It is important to pass on the exception, to be able to identify the problem you are experiencing. É importante passar a exceção para poder identificar o problema que você está enfrentando.
    on E: Exception do
    begin
      FreeAndNil(LObject);
      raise EMapperException.Create(E.Message);
    end;
  end;
end;

class procedure Mapper.JSONObjectToDataSet(AJSONObject: TJSONObject;
  ADataSet: TDataSet; AJSONObjectInstanceOwner: Boolean);
begin
  JSONObjectToDataSet(AJSONObject, ADataSet, TArray<String>.Create(),
    AJSONObjectInstanceOwner);
end;

class function Mapper.JSONObjectFieldsToObject(AJSONObject: TJSONObject): TObject;
var
  LJClassName: TJSONString;
  LObj: TObject;
begin
{$IF CompilerVersion <= 26}
  if Assigned(AJSONObject.Get(DMVC_CLASSNAME)) then
  begin
    LJClassName := AJSONObject.Get(DMVC_CLASSNAME).JsonValue as TJSONString;
  end
  else
    raise EMapperException.Create('No $classname property in the JSON object');
{$ELSE}
  if not AJSONObject.TryGetValue<TJSONString>(DMVC_CLASSNAME, LJClassName) then
    raise EMapperException.Create('No $classname property in the JSON object');
{$ENDIF}
  LObj := TRTTIUtils.CreateObject(LJClassName.Value);
  try
    InternalJSONObjectFieldsToObject(ctx, AJSONObject, LObj);
    Result := LObj;
  except
    FreeAndNil(LObj);
    raise;
  end;
end;

class function Mapper.JSONObjectStringToObject<T>(const AJSONObjectString
  : String): T;
var
  JObj: TJSONObject;
begin
  JObj := TJSONObject.ParseJSONValue(AJSONObjectString) as TJSONObject;
  try
    Result := JSONObjectToObject<T>(JObj);
  finally
    JObj.Free;
  end;
end;

class procedure Mapper.JSONObjectToDataSet(AJSONObject: TJSONObject; ADataSet: TDataSet; AIgnoredFields: TArray<String>;
  AJSONObjectInstanceOwner: Boolean; AFieldNamePolicy: TFieldNamePolicy);
var
  I: Integer;
  key: String;
  v: TJSONValue;
  jp: TJSONPair;
  fs: TFormatSettings;
  MS: TMemoryStream;
  SS: TStringStream;
begin
  for I := 0 to ADataSet.FieldCount - 1 do
  begin
    if ContainsFieldName(ADataSet.Fields[I].FieldName, AIgnoredFields) then
      Continue;

    case AFieldNamePolicy of
      fpLowerCase:
        key := LowerCase(ADataSet.Fields[I].FieldName);
      fpUpperCase:
        key := UpperCase(ADataSet.Fields[I].FieldName);
      fpAsIs:
        key := ADataSet.Fields[I].FieldName;
    end;

    v := nil;
    jp := AJSONObject.Get(key);
    if Assigned(jp) then
      if not(jp.JsonValue is TJSONNull) then
        v := AJSONObject.Get(key).JsonValue;
    if not Assigned(v) then
    begin
      ADataSet.Fields[I].Clear;
      Continue;
    end;

    case ADataSet.Fields[I].DataType
      of TFieldType.ftInteger, TFieldType.ftAutoInc, TFieldType.ftSmallint, TFieldType.ftShortint:
        begin
          ADataSet.Fields[I].AsInteger := (v as TJSONNumber).AsInt;
        end;
      TFieldType.ftLargeint:
        begin
          ADataSet.Fields[I].AsLargeInt := (v as TJSONNumber).AsInt64;
        end;
      TFieldType.ftSingle, TFieldType.ftFloat:
        begin
          ADataSet.Fields[I].AsFloat := (v as TJSONNumber).AsDouble;
        end;
      ftString, ftWideString, ftMemo, ftWideMemo:
        begin
          ADataSet.Fields[I].AsString := (v as TJSONString).Value;
        end;
      TFieldType.ftDate:
        begin
          ADataSet.Fields[I].AsDateTime :=
            ISOStrToDate((v as TJSONString).Value);
        end;
      TFieldType.ftDateTime:
        begin
          ADataSet.Fields[I].AsDateTime :=
            ISOStrToDateTime((v as TJSONString).Value);
        end;
      TFieldType.ftTimeStamp:
        begin
          ADataSet.Fields[I].AsSQLTimeStamp :=
            StrToSQLTimeStamp((v as TJSONString).Value);
        end;
      TFieldType.ftCurrency:
        begin
          fs.DecimalSeparator := '.';
{$IF CompilerVersion <= 27}
          ADataSet.Fields[I].AsCurrency :=
            StrToCurr((v as TJSONString).LValue, fs);
{$ELSE} // Delphi XE7 introduces method "ToJSON" to fix some old bugs...
          ADataSet.Fields[I].AsCurrency :=
            StrToCurr((v as TJSONNumber).ToJSON, fs);
{$ENDIF}
        end;
      TFieldType.ftFMTBcd:
        begin
          ADataSet.Fields[I].AsBcd := DoubleToBcd((v as TJSONNumber).AsDouble);
        end;
      TFieldType.ftGraphic, TFieldType.ftBlob, TFieldType.ftStream:
        begin
          MS := TMemoryStream.Create;
          try
            SS := TStringStream.Create((v as TJSONString).Value,
              TEncoding.ASCII);
            try
              DecodeStream(SS, MS);
              MS.Position := 0;
              TBlobField(ADataSet.Fields[I]).LoadFromStream(MS);
            finally
              SS.Free;
            end;
          finally
            MS.Free;
          end;
        end;
      // else
      // raise EMapperException.Create('Cannot find type for field ' + key);
    end;
  end;
  if AJSONObjectInstanceOwner then
    FreeAndNil(AJSONObject);
end;

class function Mapper.JSONObjectToObject(ClazzName: String; AJSONObject: TJSONObject): TObject;
var
  LObject: TObject;
  _rttiType: TRttiType;
begin
  _rttiType := Mapper.ctx.FindType(ClazzName);
  if Assigned(_rttiType) then
  begin
    LObject := TRTTIUtils.CreateObject(_rttiType);
    try
      InternalJSONObjectToObject(ctx, AJSONObject, LObject);
      Result := LObject;
    except
      LObject.Free;
      // Result := nil;
      raise; // added 20140630
    end;
  end
  else
    raise EMapperException.CreateFmt('Class not found [%s]', [ClazzName]);
end;

class function Mapper.JSONObjectToObject<T>(AJSONObject: TJSONObject): T;
begin
  if not Assigned(AJSONObject) then
    raise EMapperException.Create('JSONObject not assigned');
  Result := Mapper.JSONObjectToObject(T.QualifiedClassName, AJSONObject) as T;
  // Result := JSONObjectToObject(TObject.ClassInfo, AJSONObject);
end;

class function Mapper.JSONObjectToObjectFields<T>(AJSONObject: TJSONObject): T;
var
  _type: TRttiType;
  _fields: TArray<TRttiField>;
  _field: TRttiField;
  LRttiProperty: String;
  LObject: T;
  LJSONValue: TJSONValue;
begin
  LObject := T.Create;
  try
    _type := ctx.GetType(LObject.ClassInfo);
    _fields := _type.GetFields;
    for _field in _fields do
    begin
      LRttiProperty := LowerCase(_field.Name);
      Delete(LRttiProperty, 1, 1);
      if Assigned(AJSONObject.Get(LRttiProperty)) then
        LJSONValue := AJSONObject.Get(LRttiProperty).JsonValue
      else
        Continue;
      case _field.FieldType.TypeKind
        of tkInteger, tkInt64:
          _field.SetValue(TObject(LObject), StrToIntDef(LJSONValue.Value, 0));

        tkFloat:
          begin
            if _field.FieldType.QualifiedName = 'System.TDate' then
              _field.SetValue(TObject(LObject), StrToDate(LJSONValue.Value))
            else if _field.FieldType.QualifiedName = 'System.TDateTime' then
              _field.SetValue(TObject(LObject), StrToDateTime(LJSONValue.Value))
            else
              _field.SetValue(TObject(LObject),
                (LJSONValue as TJSONNumber).AsDouble)
          end;

        tkString, tkLString, tkWString, tkUString:
          begin
            _field.SetValue(TObject(LObject), LJSONValue.Value);
          end;
      end;
    end;

    Result := LObject;
  except
    LObject.Free;
    LObject := nil;
    Result := nil;
  end;
end;

class procedure Mapper.DataSetToObjectList<T>(ADataSet: TDataSet; AObjectList: TObjectList<T>; ACloseDataSetAfterScroll: Boolean);
var
  LObj: T;
  SavedPosition: TArray<Byte>;
begin
  ADataSet.DisableControls;
  try
    SavedPosition := ADataSet.Bookmark;
    while not ADataSet.Eof do
    begin
      LObj := T.Create;
      DataSetToObject(ADataSet, LObj);
      AObjectList.Add(LObj);
      ADataSet.Next;
    end;
    if ADataSet.BookmarkValid(SavedPosition) then
      ADataSet.Bookmark := SavedPosition;
  finally
    ADataSet.EnableControls;
  end;
  if ACloseDataSetAfterScroll then
    ADataSet.Close;
end;
//
// class procedure Mapper.DataSetToXML(ADataSet: TDataSet;
// XMLDocument: String; ADataSetInstanceOwner: Boolean);
// var
// Xml: IXMLDocument;
// Row: IXMLNode;
// begin
// DefaultDOMVendor := 'ADOM XML v4';
// Xml := NewXMLDocument();
// while not ADataSet.Eof do
// begin
// Row := Xml.CreateNode('row');
// // Row := Xml.DocumentElement.AddChild('row');
// // DataSetRowToXML(ADataSet, Row, False);
// Xml.ChildNodes.Add(Row);
// break;
// ADataSet.Next;
// end;
// if ADataSetInstanceOwner then
// FreeAndNil(ADataSet);
// Xml.SaveToXML(XMLDocument);
// end;
//
// class procedure Mapper.DataSetRowToXML(ADataSet: TDataSet;
// Row: IXMLNode; ADataSetInstanceOwner: Boolean);
// var
// I: Integer;
// key: String;
// dt: TDateTime;
// tt: TTime;
// Time: TTimeStamp;
// ts: TSQLTimeStamp;
// begin
// for I := 0 to ADataSet.FieldCount - 1 do
// begin
// key := LowerCase(ADataSet.Fields[I].FieldName);
// case ADataSet.Fields[I].DataType of
// TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
// Row.Attributes[key] := ADataSet.Fields[I].AsInteger;
// // AJSONObject.AddPair(key, TJSONNumber.Create(ADataSet.Fields[I].AsInteger));
// TFieldType.ftLargeint:
// begin
// Row.Attributes[key] := ADataSet.Fields[I].AsLargeInt;
// end;
// TFieldType.ftSingle, TFieldType.ftFloat:
// Row.Attributes[key] := ADataSet.Fields[I].AsFloat;
// ftString, ftWideString, ftMemo:
// Row.Attributes[key] := ADataSet.Fields[I].AsWideString;
// TFieldType.ftDate:
// begin
// if not ADataSet.Fields[I].IsNull then
// begin
// Row.Attributes[key] := ISODateToString(ADataSet.Fields[I].AsDateTime);
// end
// end;
// TFieldType.ftDateTime:
// begin
// if not ADataSet.Fields[I].IsNull then
// begin
// Row.Attributes[key] := ISODateTimeToString(ADataSet.Fields[I].AsDateTime);
// end
// end;
// TFieldType.ftTimeStamp:
// begin
// if not ADataSet.Fields[I].IsNull then
// begin
// ts := ADataSet.Fields[I].AsSQLTimeStamp;
// Row.Attributes[key] := SQLTimeStampToStr('hh:nn:ss', ts);
// end
// end;
// TFieldType.ftCurrency:
// begin
// if not ADataSet.Fields[I].IsNull then
// begin
// Row.Attributes[key] := FormatCurr('0.00##', ADataSet.Fields[I].AsCurrency);
// end
// end;
// TFieldType.ftFMTBcd:
// begin
// if not ADataSet.Fields[I].IsNull then
// begin
// Row.Attributes[key] := BcdToDouble(ADataSet.Fields[I].AsBcd);
// end
// end
// else
// raise EMapperException.Create('Cannot find type for field ' + key);
// end;
// end;
// if ADataSetInstanceOwner then
// FreeAndNil(ADataSet);
// end;

{$IF CompilerVersion > 25}

class procedure Mapper.ObjectToFDParameters(AFDParams: TFDParams;  AObject: TObject; AParamPrefix: String);
var
  I: Integer;
  LName: String;
  _rttiType: TRttiType;
  LObj_Fields: TArray<TRttiProperty>;
  LObj_Field: TRttiProperty;
  LObj_Field_Attr: MapperColumnAttribute;
  LMap: TObjectDictionary<String, TRttiProperty>;
  LRttiProperty: TRttiProperty;
  LValue: TValue;
  LPrefixLength: Integer;

  function KindToFieldType(AKind: TTypeKind; AProp: TRttiProperty): TFieldType;
  begin
    case AKind of
      tkInteger:
        Result := ftInteger;
      tkFloat:
        begin
          if AProp.PropertyType.QualifiedName = 'System.TDate' then
            Result := ftDate
          else if AProp.PropertyType.QualifiedName = 'System.TDateTime' then
            Result := ftDateTime
          else if AProp.PropertyType.QualifiedName = 'System.TTime' then
            Result := ftTime
          else
            Result := ftFloat;
        end;
      tkChar, tkString:
          Result := ftString;

      tkWChar, tkUString, tkLString, tkWString:
          Result := ftWideString;

      tkVariant:
          Result := ftVariant;

      tkArray:
          Result := ftArray;

      tkInterface:
          Result := ftInterface;

      tkInt64:
          Result := ftLongWord;
    else
      Result := ftUnknown;
    end;
  end;

begin
  LPrefixLength := Length(AParamPrefix);
  LMap := TObjectDictionary<String, TRttiProperty>.Create;
  try
    if Assigned(AObject) then
    begin
      _rttiType := ctx.GetType(AObject.ClassType);
      LObj_Fields := _rttiType.GetProperties;
      for LObj_Field in LObj_Fields do
      begin
        if HasAttribute<MapperColumnAttribute>(LObj_Field, LObj_Field_Attr) then
        begin
          LMap.Add(MapperColumnAttribute(LObj_Field_Attr).FieldName.ToLower,
            LObj_Field);
        end
        else
        begin
          LMap.Add(LObj_Field.Name.ToLower, LObj_Field);
        end
      end;
    end;
    for I := 0 to AFDParams.Count - 1 do
    begin
      LName := AFDParams[I].Name.ToLower;
      if LName.StartsWith(AParamPrefix, True) then
        Delete(LName, 1, LPrefixLength);
      if LMap.TryGetValue(LName, LRttiProperty) then
      begin
        LValue := LRttiProperty.GetValue(AObject);
        AFDParams[I].DataType := KindToFieldType(LValue.Kind, LRttiProperty);
        // DmitryG - 2014-03-28
        AFDParams[I].Value := LValue.AsVariant;
      end
      else
      begin
        AFDParams[I].Clear;
      end;
    end;
  finally
    LMap.Free;
  end
end;

class function Mapper.InternalExecuteFDQuery(AQuery: TFDQuery; AObject: TObject;
  WithResult: Boolean): Int64;
begin
  ObjectToFDParameters(AQuery.Params, AObject);
  Result := 0;
  if WithResult then
    AQuery.Open
  else
  begin
    AQuery.ExecSQL;
    Result := AQuery.RowsAffected;
  end;
end;

class function Mapper.ExecuteFDQueryNoResult(AQuery: TFDQuery; AObject: TObject): Int64;
begin
  Result := InternalExecuteFDQuery(AQuery, AObject, False);
end;

class procedure Mapper.ExecuteFDQuery(AQuery: TFDQuery; AObject: TObject);
begin
  InternalExecuteFDQuery(AQuery, AObject, True);
end;

{$ENDIF}
{$IF CompilerVersion <= 25}

class function Mapper.ExecuteSQLQueryNoResult(AQuery: TSQLQuery; AObject: TObject): Int64;
begin
  Result := InternalExecuteSQLQuery(AQuery, AObject, False);
end;

class procedure Mapper.ExecuteSQLQuery(AQuery: TSQLQuery; AObject: TObject);
begin
  InternalExecuteSQLQuery(AQuery, AObject, True);
end;

class function Mapper.ExecuteSQLQueryAsObjectList<T>(AQuery: TSQLQuery; AObject: TObject): TObjectList<T>;
begin
  ExecuteSQLQuery(AQuery, AObject);
  Result := TObjectList<T>.Create(True);
  DataSetToObjectList<T>(AQuery, Result);
end;

{$IFEND}
{ MappedField }

constructor MapperColumnAttribute.Create(AFieldName: String; AIsPK: Boolean);
begin
  inherited Create;
  FFieldName := AFieldName;
  FIsPK := AIsPK;
end;

procedure MapperColumnAttribute.SetFieldName(const LValue: String);
begin
  FFieldName := LValue;
end;

procedure MapperColumnAttribute.SetIsPK(const LValue: Boolean);
begin
  FIsPK := LValue;
end;

{ GridColumnProps }

constructor GridColumnProps.Create(ACaption: String; AAlign: TGridColumnAlign;
  AWidth: Integer);
begin
  inherited Create;
  FCaption := ACaption;
  FAlign := AAlign;

{$IF CompilerVersion >= 23.0}
  FWidth := System.Math.Max(AWidth, 50);

{$ELSE}
  FWidth := Math.Max(AWidth, 50);

{$IFEND}
end;

function GridColumnProps.GetAlignAsString: String;
begin
  case FAlign of
    caLeft:
      Result := 'left';
    caCenter:
      Result := 'center';
    caRight:
      Result := 'right';
  end;
end;

{ JSONSer }

constructor MapperJSONSer.Create(AName: String);
begin
  inherited Create;
  FName := AName;
end;

function MapperJSONSer.GetName: String;
begin
  Result := FName;
end;

{ JSONNaming }

constructor MapperJSONNaming.Create(JSONKeyCase: TJSONNameCase);
begin
  inherited Create;
  FJSONKeyCase := JSONKeyCase;
end;

function MapperJSONNaming.GetKeyCase: TJSONNameCase;
begin
  Result := FJSONKeyCase;
end;

{ StringValueAttribute }

constructor StringValueAttribute.Create(LValue: String);
begin
  inherited Create;
  FValue := LValue;
end;

procedure StringValueAttribute.SetValue(const LValue: String);
begin
  FValue := LValue;
end;

{ ItemsClassType }

constructor MapperItemsClassType.Create(LValue: TClass);
begin
  inherited Create;
  FValue := LValue;
end;

procedure MapperItemsClassType.SetValue(const LValue: TClass);
begin
  FValue := LValue;
end;

{ TDataSetHelper }

function TDataSetHelper.AsJSONArray: TJSONArray;
var
  LJSONArray: TJSONArray;
begin

  LJSONArray := TJSONArray.Create;
  try
    if not Eof then
      Mapper.DataSetToJSONArray(Self, LJSONArray, False);
    Result := LJSONArray;
  except
    FreeAndNil(LJSONArray);
    raise;
  end;
end;

function TDataSetHelper.AsJSONArrayString: String;
var
  LJSONArray: TJSONArray;
begin
  LJSONArray := AsJSONArray;
  try
{$IF CompilerVersion >= 28}
    Result := LJSONArray.ToJSON;
{$ELSE}
    Result := LJSONArray.ToString;
{$ENDIF}
  finally
    LJSONArray.Free;
  end;
end;

function TDataSetHelper.AsJSONObject(AReturnNilIfEOF: Boolean; AFieldNamePolicy: TFieldNamePolicy): TJSONObject;
var
  LJSONObject: TJSONObject;
begin
  LJSONObject := TJSONObject.Create;
  try
    Mapper.DataSetToJSONObject(Self, LJSONObject, False);
    if AReturnNilIfEOF and (LJSONObject.Size = 0) then
      FreeAndNil(LJSONObject);
    Result := LJSONObject;
  except
    FreeAndNil(LJSONObject);
    raise;
  end;
end;

function TDataSetHelper.AsJSONObjectString(AReturnEmptyStringIfEOF: Boolean): String;
var
  LJSONObject: TJSONObject;
begin
  LJSONObject := AsJSONObject(True);
  if not Assigned(LJSONObject) then
  begin
    if AReturnEmptyStringIfEOF then
      Result := ''
    else
      Result := '{}';
  end
  else
    try
{$IF CompilerVersion >= 28}
      Result := LJSONObject.ToJSON;
{$ELSE}
      Result := LJSONObject.ToString
{$ENDIF}
    finally
      LJSONObject.Free;
    end;
end;

function TDataSetHelper.AsObject<T>(CloseAfterScroll: Boolean): T;
var
  LJSONObject: T;
begin
  if not Self.Eof then
  begin
    LJSONObject := T.Create;
    try
      Mapper.DataSetToObject(Self, LJSONObject);
      Result := LJSONObject;
    except
      FreeAndNil(LJSONObject);
      raise;
    end;
  end
  else
    Result := nil;
end;

function TDataSetHelper.AsObjectList<T>(CloseAfterScroll: Boolean): TObjectList<T>;
var
  LObjectList: TObjectList<T>;
begin
  LObjectList := TObjectList<T>.Create(True);
  try
    Mapper.DataSetToObjectList<T>(Self, LObjectList, CloseAfterScroll);
    Result := LObjectList;
  except
    FreeAndNil(LObjectList);
    raise;
  end;
end;

procedure TDataSetHelper.LoadFromJSONArray(AJSONArray: TJSONArray; AFieldNamePolicy: TFieldNamePolicy);
begin
  Self.DisableControls;
  try
    Mapper.JSONArrayToDataSet(AJSONArray, Self, TArray<String>.Create(), False,
      AFieldNamePolicy);
  finally
    Self.EnableControls;
  end;
end;

procedure TDataSetHelper.LoadFromJSONArray(AJSONArray: TJSONArray; AIgnoredFields: TArray<String>);
begin
  Self.DisableControls;
  try
    Mapper.JSONArrayToDataSet(AJSONArray, Self, AIgnoredFields, False);
  finally
    Self.EnableControls;
  end;
end;

procedure TDataSetHelper.LoadFromJSONArrayString(AJSONArrayString: String);
begin
  AppendFromJSONArrayString(AJSONArrayString);
end;

procedure TDataSetHelper.AppendFromJSONArrayString(AJSONArrayString: String;
  AIgnoredFields: TArray<String>);
var
  LJSONOValue: TJSONValue;
begin
  LJSONOValue := TJSONObject.ParseJSONValue(AJSONArrayString);
  try
    if LJSONOValue is TJSONArray then
      LoadFromJSONArray(TJSONArray(LJSONOValue), AIgnoredFields)
    else
      raise EMapperException.Create
        ('Expected JSONArray in LoadFromJSONArrayString');
  finally
    LJSONOValue.Free;
  end;
end;

procedure TDataSetHelper.AppendFromJSONArrayString(AJSONArrayString: String);
begin
  AppendFromJSONArrayString(AJSONArrayString, TArray<String>.Create());
end;

procedure TDataSetHelper.LoadFromJSONObject(AJSONObject: TJSONObject; AIgnoredFields: TArray<String>;
  AFieldNamePolicy: TFieldNamePolicy);
begin
  Mapper.JSONObjectToDataSet(AJSONObject, Self, AIgnoredFields, False, AFieldNamePolicy);
end;

procedure TDataSetHelper.LoadFromJSONObjectString(AJSONObjectString: String;
  AIgnoredFields: TArray<String>);
var
  LJSONOValue: TJSONValue;
begin
  LJSONOValue := TJSONObject.ParseJSONValue(AJSONObjectString);
  try
    if LJSONOValue is TJSONObject then
      LoadFromJSONObject(TJSONObject(LJSONOValue), AIgnoredFields)
    else
      raise EMapperException.Create
        ('Extected JSONObject in LoadFromJSONObjectString');
  finally
    LJSONOValue.Free;
  end;
end;

procedure TDataSetHelper.LoadFromJSONObject(AJSONObject: TJSONObject; AFieldNamePolicy: TFieldNamePolicy);
begin
  LoadFromJSONObject(AJSONObject, TArray<String>.Create());
end;

procedure TDataSetHelper.LoadFromJSONObjectString(AJSONObjectString: String);
begin
  LoadFromJSONObjectString(AJSONObjectString, TArray<String>.Create());
end;

{ MapperSerializeAsString }

constructor MapperSerializeAsString.Create(AEncoding: String);
begin
  inherited Create;
  if AEncoding.IsEmpty then
    FEncoding := DefaultEncoding
  else
    FEncoding := AEncoding;
end;

procedure MapperSerializeAsString.SetEncoding(const LValue: String);
begin
  FEncoding := LValue;
end;

end.
