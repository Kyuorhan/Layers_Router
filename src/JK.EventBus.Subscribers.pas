unit JK.EventBus.Subscribers;

interface

uses
  System.RTTI,
  Layers_Router.Propersys;

type

  TSubscriber_Method = class(TObject)
  private
    FEvent_Type: TClass;
    FThread_Mode: TThread_Mode;
    FMethod: TRttiMethod;
    FContext: string;
    procedure SetEventType(const Value: TClass);
    procedure SetMethod(const Value: TRttiMethod);
    procedure SetThreadMode(const Value: TThread_Mode);
    procedure SetContext(const Value: String);
  public
    constructor Create(ARttiMethod: TRttiMethod; AEventType: TClass; AThreadMode: TThread_Mode;
      const AContext: String = ''; APriority: Integer = 1);
    destructor Destroy; override;
    property EventType: TClass read FEvent_Type write SetEventType;
    property Method: TRttiMethod read FMethod write SetMethod;
    property ThreadMode: TThread_Mode read FThread_Mode write SetThreadMode;
    property Context: String read FContext write SetContext;
    function Equals(Obj: TObject): Boolean; override;
  end;

  TSubscription = class(TObject)
  private
    FSubscriberMethod: TSubscriber_Method;
    FSubscriber: TObject;
    FActive: Boolean;
    procedure SetActive(const Value: Boolean);
    function GetActive: Boolean;
    procedure SetSubscriberMethod(const Value: TSubscriber_Method);
    procedure SetSubscriber(const Value: TObject);
    function GetContext: String;
  public
    constructor Create(ASubscriber: TObject; ASubscriberMethod: TSubscriber_Method);
    destructor Destroy; override;
    property Active: Boolean read GetActive write SetActive;
    property Subscriber: TObject read FSubscriber write SetSubscriber;
    property SubscriberMethod: TSubscriber_Method read FSubscriberMethod
      write SetSubscriberMethod;
    property Context: String read GetContext;
    function Equals(Obj: TObject): Boolean; override;

  end;

  TSubscriber_Finder = class(TObject)
    class function FindSubscriberMethods(ASubscriberClass: TClass;
      ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriber_Method>;
  end;

implementation

uses
  JK.RTTIUtils,
  System.SysUtils,
  System.TypInfo;

{ TSubscriber_Method }

constructor TSubscriber_Method.Create(ARttiMethod: TRttiMethod; AEventType: TClass; AThreadMode: TThread_Mode;
  const AContext: String = ''; APriority: Integer = 1);
begin
  FMethod := ARttiMethod;
  FEvent_Type := AEventType;
  FThread_Mode := AThreadMode;
  FContext := AContext;
end;

destructor TSubscriber_Method.Destroy;
begin
  inherited;
end;

function TSubscriber_Method.Equals(Obj: TObject): Boolean;
var
  LOtherSubscriberMethod: TSubscriber_Method;
begin
  if (inherited Equals(Obj)) then
    Exit(True)
  else if (Obj is TSubscriber_Method) then
  begin
    LOtherSubscriberMethod := TSubscriber_Method(Obj);
    Exit(LOtherSubscriberMethod.Method.ToString = Method.ToString);
  end
  else
    Exit(False);
end;

procedure TSubscriber_Method.SetContext(const Value: String);
begin
  FContext := Value;
end;

procedure TSubscriber_Method.SetEventType(const Value: TClass);
begin
  FEvent_Type := Value;
end;

procedure TSubscriber_Method.SetMethod(const Value: TRttiMethod);
begin
  FMethod := Value;
end;

procedure TSubscriber_Method.SetThreadMode(const Value: TThread_Mode);
begin
  FThread_Mode := Value;
end;

{ TSubscriber_Finder }

class function TSubscriber_Finder.FindSubscriberMethods
  (ASubscriberClass: TClass; ARaiseExcIfEmpty: Boolean = False): TArray<TSubscriber_Method>;
var
  LRttiType: TRttiType;
  LSubscribeAttribute: Subscribe_Attributes;
  LRttiMethods: TArray<System.RTTI.TRttiMethod>;
  LMethod: TRttiMethod;
  LParamsLength: Integer;
  LEventType: TClass;
  LSubMethod: TSubscriber_Method;
begin
  LRttiType := TRTTIUtils.TRttiCTX.GetType(ASubscriberClass);
  LRttiMethods := LRttiType.GetMethods;
  for LMethod in LRttiMethods do
    if TRTTIUtils.HasAttribute<Subscribe_Attributes>(LMethod, LSubscribeAttribute) then
    begin
      LParamsLength := Length(LMethod.GetParameters);
      if (LParamsLength <> 1) then
        raise Exception.CreateFmt
          ('Method  %s has Subscribe attribute but requires %d arguments. Methods must require a single argument.',
          [LMethod.Name, LParamsLength]);
      LEventType := LMethod.GetParameters[0].ParamType.Handle.TypeData.
        ClassType;
      LSubMethod := TSubscriber_Method.Create(LMethod, LEventType,
        LSubscribeAttribute.ThreadMode, LSubscribeAttribute.Context);
{$IF CompilerVersion >= 28.0}
      Result := Result + [LSubMethod];
{$ELSE}
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LSubMethod;
{$ENDIF}
    end;
  // if (Length(Result) < 1) and ARaiseExcIfEmpty then
  // raise Exception.CreateFmt
  // ('The class %s and its super classes have no public methods with the Subscribe attributes',
  // [ASubscriberClass.QualifiedClassName]);
end;

{ TSubscription }

constructor TSubscription.Create(ASubscriber: TObject;
  ASubscriberMethod: TSubscriber_Method);
begin
  inherited Create;
  FSubscriber := ASubscriber;
  FSubscriberMethod := ASubscriberMethod;
  FActive := True;
end;

destructor TSubscription.Destroy;
begin
  if Assigned(FSubscriberMethod) then
    FreeAndNil(FSubscriberMethod);
  inherited;
end;

function TSubscription.Equals(Obj: TObject): Boolean;
var
  LOtherSubscription: TSubscription;
begin
  if (Obj is TSubscription) then
  begin
    LOtherSubscription := TSubscription(Obj);
    Exit((Subscriber = LOtherSubscription.Subscriber) and (SubscriberMethod.Equals(LOtherSubscription.SubscriberMethod)));
  end
  else
    Exit(False);
end;

function TSubscription.GetActive: Boolean;
begin
  TMonitor.Enter(Self);
  try
    Result := FActive;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TSubscription.GetContext: String;
begin
  Result := SubscriberMethod.Context;
end;

procedure TSubscription.SetActive(const Value: Boolean);
begin
  TMonitor.Enter(Self);
  try
    FActive := Value;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TSubscription.SetSubscriberMethod(const Value: TSubscriber_Method);
begin
  FSubscriberMethod := Value;
end;

procedure TSubscription.SetSubscriber(const Value: TObject);
begin
  FSubscriber := Value;
end;

end.
