unit Layers_Router.Propersys;

{$I Layers_Router.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.Rtti;

type

  TThread_Mode = (Posting, Main, Async, Background);

  TCloneEventCallback = function(const AObject: TObject): TObject of object;
  TCloneEventMethod = TFunc<TObject, TObject>;

  IEvent_Bus = Interface
    ['{7BDF4536-F2BA-4FBA-B186-09E1EE6C7E35}']
    procedure RegisterSubscriber(ASubscriber: TObject);
    function IsRegistered(ASubscriber: TObject): Boolean;
    procedure Unregister(ASubscriber: TObject);
    procedure Post(AEvent: TObject; const AContext: String = '';
      AEventOwner: Boolean = True);

    procedure SetOnCloneEvent(const aCloneEvent: TCloneEventCallback);
    procedure AddCustomClassCloning(const AQualifiedClassName: String;
      const aCloneEvent: TCloneEventMethod);
    procedure RemoveCustomClassCloning(const AQualifiedClassName: String);

    property OnCloneEvent: TCloneEventCallback write SetOnCloneEvent;
  end;

  Subscribe_Attributes = class(TCustomAttribute)
  private
    FContext: String;
    FThreadMode: TThread_Mode;
  public
    constructor Create(AThreadMode: TThread_Mode = TThread_Mode.Posting;
      const AContext: String = '');
    property ThreadMode: TThread_Mode read FThreadMode;
    property Context: String read FContext;
  end;

  TDEBEvent<T> = class(TObject)
  private
    FDataOwner: Boolean;
    FData: T;
    procedure SetData(const Value: T);
    procedure SetDataOwner(const Value: Boolean);
  public
    constructor Create; overload;
    constructor Create(AData: T); overload;
    destructor Destroy; override;
    property DataOwner: Boolean read FDataOwner write SetDataOwner;
    property Data: T read FData write SetData;
  end;

  TPropersys = class
  private
    FPropersyString: String;
    FPropersyInteger: Integer;
    FPropersyCurrency: Currency;
    FPropersyDouble: Double;
    FPropersyValue: TValue;
    FPropersyObject: TObject;
    FPropersyDateTime: TDateTime;
    FKey: String;
  public
    constructor Create;
    destructor Destroy; override;
    function ProprsString(APropersy: String): TPropersys; overload;
    function ProprsString: String; overload;
    function ProprsInteger(APropersy: Integer): TPropersys; overload;
    function ProprsInteger: Integer; overload;
    function ProprsCurrency(APropersy: Currency): TPropersys; overload;
    function ProprsCurrency: Currency; overload;
    function ProprsDouble(APropersy: Double): TPropersys; overload;
    function ProprsDouble: Double; overload;
    function ProprsValue(APropersy: TValue): TPropersys; overload;
    function ProprsValue: TValue; overload;
    function ProprsObject(APropersy: TObject): TPropersys; overload;
    function ProprsObject: TObject; overload;
    function ProprsDateTime(APropersy: TDateTime): TPropersys; overload;
    function ProprsDateTime: TDateTime; overload;
    function Key(AKey: String): TPropersys; overload;
    function Key: String; overload;
  end;

function GlobalEventBus: IEvent_Bus;

implementation

uses
  JK.EventBus.Core,
  JK.RTTIUtils;

var
  FGlobalEventBus: IEvent_Bus;

  { Subscribe_Attribute }

constructor Subscribe_Attributes.Create(AThreadMode: TThread_Mode = TThread_Mode.Posting;
  const AContext: String = '');
begin
  inherited Create;
  FContext := AContext;
  FThreadMode := AThreadMode;
end;

{ TDEBSimpleEvent<T> }

constructor TDEBEvent<T>.Create(AData: T);
begin
  inherited Create;
  DataOwner := True;
  Data := AData;
end;

constructor TDEBEvent<T>.Create;
begin
  inherited Create;
end;

destructor TDEBEvent<T>.Destroy;
var
  LValue: TValue;
begin
  LValue := TValue.From<T>(Data);
  if (LValue.IsObject) and DataOwner then
    LValue.AsObject.Free;
  inherited;
end;

procedure TDEBEvent<T>.SetData(const Value: T);
begin
  FData := Value;
end;

procedure TDEBEvent<T>.SetDataOwner(const Value: Boolean);
begin
  FDataOwner := Value;
end;

function GlobalEventBus: IEvent_Bus;
begin
  if not Assigned(FGlobalEventBus) then
    FGlobalEventBus := TEvent_Bus.Create;
  Result := FGlobalEventBus;
end;

{ TPropersys }

constructor TPropersys.Create;
begin

end;

destructor TPropersys.Destroy;
begin

  inherited;
end;

function TPropersys.Key(AKey: String): TPropersys;
begin
  Result := Self;
  FKey := AKey;
end;

function TPropersys.Key: String;
begin
  Result := FKey;
end;

function TPropersys.ProprsCurrency: Currency;
begin
  Result := FPropersyCurrency;
end;

function TPropersys.ProprsDateTime: TDateTime;
begin
  Result := FPropersyDateTime;
end;

function TPropersys.ProprsDateTime(APropersy: TDateTime): TPropersys;
begin
  Result := Self;
  FPropersyDateTime := APropersy;
end;

function TPropersys.ProprsDouble: Double;
begin
  Result := FPropersyDouble;
end;

function TPropersys.ProprsDouble(APropersy: Double): TPropersys;
begin
  Result := Self;
  FPropersyDouble := APropersy;
end;

function TPropersys.ProprsCurrency(APropersy: Currency): TPropersys;
begin
  Result := Self;
  FPropersyCurrency := APropersy;
end;

function TPropersys.ProprsInteger: Integer;
begin
  Result := FPropersyInteger;
end;

function TPropersys.ProprsObject: TObject;
begin
  Result := FPropersyObject;
end;

function TPropersys.ProprsObject(APropersy: TObject): TPropersys;
begin
  Result := Self;
  FPropersyObject := APropersy;
end;

function TPropersys.ProprsInteger(APropersy: Integer): TPropersys;
begin
  Result := Self;
  FPropersyInteger := APropersy;
end;

function TPropersys.ProprsString(APropersy: String): TPropersys;
begin
  Result := Self;
  FPropersyString := APropersy;
end;

function TPropersys.ProprsString: String;
begin
  Result := FPropersyString;
end;

function TPropersys.ProprsValue: TValue;
begin
  Result := FPropersyValue;
end;

function TPropersys.ProprsValue(APropersy: TValue): TPropersys;
begin
  Result := Self;
  FPropersyValue := APropersy;
end;

initialization

GlobalEventBus;

finalization

end.
