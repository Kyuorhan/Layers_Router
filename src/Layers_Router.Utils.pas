unit Layers_Router.Utils;

{$I Layers_Router.inc}

interface

uses
  System.Rtti,
  System.SysUtils,
  System.Classes,
  Layers_Router.Propersys;

type
  TLayers_RouterUtils = class
  private
  public
    class function CreateInstance<T>: T;
  end;

  TNotifyEventWrapper = class(TComponent)
  private
    FProc: TProc<TObject, String>;
    FAux: String;
  public
    constructor Create(Owner: TComponent; Proc: TProc<TObject, String>;
      Aux: String = ''); Virtual;
    class function AnonProc2NotifyEvent(Owner: TComponent;
      Proc: TProc<TObject, String>; Aux: String = ''): TNotifyEvent;
  published
    procedure Event(Sender: TObject);
  end;

implementation

{ TLayers_RouterUtils }

class function TLayers_RouterUtils.CreateInstance<T>: T;
var
  LValue: TValue;
  LRttiCTX: TRttiContext;
  LRttiType: TRttiType;
  LRttiMethod: TRttiMethod;
  LRttiInstanceType: TRttiInstanceType;
begin
  LRttiCTX := TRttiContext.Create;
  LRttiType := LRttiCTX.GetType(TypeInfo(T));
  for LRttiMethod in LRttiType.GetMethods do
  begin
    if (LRttiMethod.IsConstructor) and (Length(LRttiMethod.GetParameters) = 1)
    then
    begin
      LRttiInstanceType := LRttiType.AsInstance;
      LValue := LRttiMethod.Invoke(LRttiInstanceType.MetaclassType, [nil]);
      Result := LValue.AsType<T>;

      try
        GlobalEventBus.RegisterSubscriber(LValue.AsType<TObject>);
      except

      end;

      Exit;
    end;
  end;

end;

{ TNotifyEventWrapper }

class function TNotifyEventWrapper.AnonProc2NotifyEvent(Owner: TComponent;
  Proc: TProc<TObject, String>; Aux: String = ''): TNotifyEvent;
begin
  Result := Self.Create(Owner, Proc, Aux).Event;
end;

constructor TNotifyEventWrapper.Create(Owner: TComponent;
  Proc: TProc<TObject, String>; Aux: String = '');
begin
  inherited Create(Owner);
  FProc := Proc;
  FAux := Aux;
end;

procedure TNotifyEventWrapper.Event(Sender: TObject);
begin
  FProc(Sender, FAux);
end;

end.
