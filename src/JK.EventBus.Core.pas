unit JK.EventBus.Core;

interface

uses
  System.SyncObjs,
  System.SysUtils,
  System.Classes,
  Generics.Collections,
  JK.EventBus.Subscribers,
  Layers_Router.Propersys;

type

  TEvent_Bus = class(TInterfacedObject, IEvent_Bus)
  var
    FTypesOfGivenSubscriber: TObjectDictionary<TObject, TList<TClass>>;
    FSubscriptionsOfGivenEventType: TObjectDictionary<TClass, TObjectList<TSubscription>>;
    FCustomClonerDict: TDictionary<String, TCloneEventMethod>;
    FOnCloneEvent: TCloneEventCallback;
    procedure Subscribe(ASubscriber: TObject;
      ASubscriberMethod: TSubscriber_Method);
    procedure UnsubscribeByEventType(ASubscriber: TObject; AEventType: TClass);
    procedure InvokeSubscriber(ASubscription: TSubscription; AEvent: TObject);
    function GenerateTProc(ASubscription: TSubscription; AEvent: TObject): TProc;
    function GenerateThreadProc(ASubscription: TSubscription; AEvent: TObject): TThreadProcedure;
  protected
    procedure SetOnCloneEvent(const aCloneEvent: TCloneEventCallback);
    function CloneEvent(AEvent: TObject): TObject; virtual;
    procedure PostToSubscription(ASubscription: TSubscription; AEvent: TObject; AIsMainThread: Boolean); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure RegisterSubscriber(ASubscriber: TObject); virtual;
    function IsRegistered(ASubscriber: TObject): Boolean;
    procedure Unregister(ASubscriber: TObject); virtual;
    procedure Post(AEvent: TObject; const AContext: String = '';
      AEventOwner: Boolean = true); virtual;
    property TypesOfGivenSubscriber: TObjectDictionary < TObject,
      TList < TClass >> read FTypesOfGivenSubscriber;
    property SubscriptionsOfGivenEventType: TObjectDictionary < TClass,
      TObjectList < TSubscription >> read FSubscriptionsOfGivenEventType;
    property OnCloneEvent: TCloneEventCallback write SetOnCloneEvent;
    procedure AddCustomClassCloning(const AQualifiedClassName: String;
      const aCloneEvent: TCloneEventMethod);
    procedure RemoveCustomClassCloning(const AQualifiedClassName: String);
  end;

implementation

uses
  System.Rtti,
{$IF CompilerVersion >= 28.0}
  System.Threading,
{$ENDIF}
  JK.RTTIUtils;

var
  FMREWSync: TMultiReadExclusiveWriteSynchronizer;

  { TEvent_Bus }

constructor TEvent_Bus.Create;
begin
  inherited Create;
  FSubscriptionsOfGivenEventType := TObjectDictionary < TClass,
    TObjectList < TSubscription >>.Create([doOwnsValues]);
  FTypesOfGivenSubscriber := TObjectDictionary < TObject,
    TList < TClass >>.Create([doOwnsValues]);
  FCustomClonerDict := TDictionary<String, TCloneEventMethod>.Create;
end;

destructor TEvent_Bus.Destroy;
begin
  FreeAndNil(FSubscriptionsOfGivenEventType);
  FreeAndNil(FTypesOfGivenSubscriber);
  FreeAndNil(FCustomClonerDict);
  inherited;
end;

procedure TEvent_Bus.AddCustomClassCloning(const AQualifiedClassName: String;
  const aCloneEvent: TCloneEventMethod);
begin
  FCustomClonerDict.Add(AQualifiedClassName, aCloneEvent);
end;

function TEvent_Bus.CloneEvent(AEvent: TObject): TObject;
var
  LCloneEvent: TCloneEventMethod;
begin
  if FCustomClonerDict.TryGetValue(AEvent.QualifiedClassName, LCloneEvent) then
    Result := LCloneEvent(AEvent)
  else if Assigned(FOnCloneEvent) then
    Result := FOnCloneEvent(AEvent)
  else
    Result := TRTTIUtils.Clone(AEvent);
end;

function TEvent_Bus.GenerateThreadProc(ASubscription: TSubscription;
  AEvent: TObject): TThreadProcedure;
begin
  Result := procedure
    begin
      if ASubscription.Active then
      begin
        ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
          [AEvent]);
      end;
    end;
end;

function TEvent_Bus.GenerateTProc(ASubscription: TSubscription;
  AEvent: TObject): TProc;
begin
  Result := procedure
    begin
      if ASubscription.Active then
      begin
        ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
          [AEvent]);
      end;
    end;
end;

procedure TEvent_Bus.InvokeSubscriber(ASubscription: TSubscription;
  AEvent: TObject);
begin
  try
    ASubscription.SubscriberMethod.Method.Invoke(ASubscription.Subscriber,
      [AEvent]);
  except
    on E: Exception do begin
      raise Exception.CreateFmt
        ('Error invoking subscriber method. Subscriber class: %s. Event type: %s. Original exception: %s: %s',
        [ASubscription.Subscriber.ClassName, ASubscription.SubscriberMethod.EventType.ClassName, E.ClassName, E.Message]);
    end;
  end;
end;

function TEvent_Bus.IsRegistered(ASubscriber: TObject): Boolean;
begin
  FMREWSync.BeginRead;
  try
    Result := FTypesOfGivenSubscriber.ContainsKey(ASubscriber);
  finally
    FMREWSync.EndRead;
  end;
end;

procedure TEvent_Bus.Post(AEvent: TObject; const AContext: String = '';
  AEventOwner: Boolean = true);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSubscription: TSubscription;
  LEvent: TObject;
  LIsMainThread: Boolean;
begin
  FMREWSync.BeginRead;
  try
    try
      LIsMainThread := MainThreadID = TThread.CurrentThread.ThreadID;

      FSubscriptionsOfGivenEventType.TryGetValue(AEvent.ClassType,
        LSubscriptions);

      if (not Assigned(LSubscriptions)) then
        Exit;

      for LSubscription in LSubscriptions do
      begin

        if not LSubscription.Active then
          Continue;

        if ((not AContext.IsEmpty) and (LSubscription.Context <> AContext)) then
          Continue;

        LEvent := CloneEvent(AEvent);
        PostToSubscription(LSubscription, LEvent, LIsMainThread);
      end;
    finally
      if (AEventOwner and Assigned(AEvent)) then
        AEvent.Free;
    end;
  finally
    FMREWSync.EndRead;
  end;
end;

procedure TEvent_Bus.PostToSubscription(ASubscription: TSubscription;
  AEvent: TObject; AIsMainThread: Boolean);
begin

  if not Assigned(ASubscription.Subscriber) then
    Exit;

  case ASubscription.SubscriberMethod.ThreadMode of
    Posting:
      InvokeSubscriber(ASubscription, AEvent);
    Main:
      if (AIsMainThread) then
        InvokeSubscriber(ASubscription, AEvent)
      else
        TThread.Queue(nil, GenerateThreadProc(ASubscription, AEvent));
    Background:
      if (AIsMainThread) then
{$IF CompilerVersion >= 28.0}
        TTask.Run(GenerateTProc(ASubscription, AEvent))
{$ELSE}
        TThread.CreateAnonymousThread(GenerateTProc(ASubscription,
          AEvent)).Start
{$ENDIF}
      else
        InvokeSubscriber(ASubscription, AEvent);
    Async:
{$IF CompilerVersion >= 28.0}
      TTask.Run(GenerateTProc(ASubscription, AEvent));
{$ELSE}
      TThread.CreateAnonymousThread(GenerateTProc(ASubscription, AEvent)).Start;
{$ENDIF}
  else
    raise Exception.Create('Unknown thread mode');
  end;

end;

procedure TEvent_Bus.RegisterSubscriber(ASubscriber: TObject);
var
  LSubscriberClass: TClass;
  LSubscriberMethods: TArray<TSubscriber_Method>;
  LSubscriberMethod: TSubscriber_Method;
begin
  FMREWSync.BeginWrite;
  try
    LSubscriberClass := ASubscriber.ClassType;
    LSubscriberMethods := TSubscriber_Finder.FindSubscriberMethods(LSubscriberClass, True);

    for LSubscriberMethod in LSubscriberMethods do
          Subscribe(ASubscriber, LSubscriberMethod);
  finally
    FMREWSync.EndWrite;
  end;
end;

procedure TEvent_Bus.RemoveCustomClassCloning(const AQualifiedClassName: String);
begin
  // No exception is thrown if the key is not in the dictionary / Nenhuma exceção é lançada se a chave não estiver no dicionário
  FCustomClonerDict.Remove(AQualifiedClassName);
end;

procedure TEvent_Bus.SetOnCloneEvent(const aCloneEvent: TCloneEventCallback);
begin
  FOnCloneEvent := aCloneEvent;
end;

procedure TEvent_Bus.Subscribe(ASubscriber: TObject; ASubscriberMethod: TSubscriber_Method);
var
  LEventType: TClass;
  LNewSubscription: TSubscription;
  LSubscriptions: TObjectList<TSubscription>;
  LSubscribedEvents: TList<TClass>;
begin
  LEventType := ASubscriberMethod.EventType;
  LNewSubscription := TSubscription.Create(ASubscriber, ASubscriberMethod);
  if (not FSubscriptionsOfGivenEventType.ContainsKey(LEventType)) then
  begin
    LSubscriptions := TObjectList<TSubscription>.Create();
    FSubscriptionsOfGivenEventType.Add(LEventType, LSubscriptions);
  end

  else
  begin
    LSubscriptions := FSubscriptionsOfGivenEventType.Items[LEventType];
    if (LSubscriptions.Contains(LNewSubscription)) then
      raise Exception.CreateFmt('Subscriber %s already registered to event %s ',
        [ASubscriber.ClassName, LEventType.ClassName]);
  end;

  LSubscriptions.Add(LNewSubscription);

  if (not FTypesOfGivenSubscriber.TryGetValue(ASubscriber, LSubscribedEvents))
  then
  begin
    LSubscribedEvents := TList<TClass>.Create;
    FTypesOfGivenSubscriber.Add(ASubscriber, LSubscribedEvents);
  end;

  LSubscribedEvents.Add(LEventType);
end;

procedure TEvent_Bus.Unregister(ASubscriber: TObject);
var
  LSubscribedTypes: TList<TClass>;
  LEventType: TClass;
begin
  FMREWSync.BeginWrite;
  try
    if FTypesOfGivenSubscriber.TryGetValue(ASubscriber, LSubscribedTypes) then
    begin
      for LEventType in LSubscribedTypes do
        UnsubscribeByEventType(ASubscriber, LEventType);

      FTypesOfGivenSubscriber.Remove(ASubscriber);
    end;
    // else {
    // Log.w(TAG, "Subscriber to unregister was not registered before: " + subscriber.getClass());
    // }
  finally
    FMREWSync.EndWrite;
  end;
end;

procedure TEvent_Bus.UnsubscribeByEventType(ASubscriber: TObject;
  AEventType: TClass);
var
  LSubscriptions: TObjectList<TSubscription>;
  LSize, I: Integer;
  LSubscription: TSubscription;
begin
  LSubscriptions := FSubscriptionsOfGivenEventType.Items[AEventType];
  if (not Assigned(LSubscriptions)) or (LSubscriptions.Count < 1) then
    Exit;
  LSize := LSubscriptions.Count;
  for I := LSize - 1 downto 0 do
  begin
    LSubscription := LSubscriptions[I];

    // Notes: In case the subscriber has been freed but it didn't unregister itself, calling / Obs: Caso o assinante tenha sido liberado, mas não tenha cancelado o registro, chamar
    // LSubscription.Subscriber.Equals() will cause Access Violation, so we use '=' instead. / LSubscription.Subscriber.Equals () causará violação de acesso, portanto, usamos '=' no lugar.

    if LSubscription.Subscriber = ASubscriber then
    begin
      LSubscription.Active := false;
      LSubscriptions.Delete(I);
    end;
  end;
end;

initialization

FMREWSync := TMultiReadExclusiveWriteSynchronizer.Create;

finalization

FMREWSync.Free;

end.
