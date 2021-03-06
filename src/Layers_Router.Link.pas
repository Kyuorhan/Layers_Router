unit Layers_Router.Link;
{$I Layers_Router.inc}

interface

uses
  Vcl.Forms,
{$IFDEF HAS_FMX}
  FMX.Types,
  FMX.Layouts,
{$ELSE}
  Vcl.ExtCtrls,
  Layers_Router.Helper,
{$ENDIF}
  SysUtils,
  Layers_Router.Interfaces,
  Layers_Router.Propersys;

type
  TLayers_RouterLink = class(TInterfacedObject, ILayers_RouterLink)
  private
{$IFDEF HAS_FMX}
    FLayer_Animation: TProc<TFMXObject>;
{$ELSE}
    FLayer_Animation: TProc<TPanel>;
{$ENDIF}
    FParent: ILayers_RouterComponent;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: ILayers_RouterLink;
{$IFDEF HAS_FMX}
    function Layer_Animation(ALayer_Animation: TProc<TFMXObject>): ILayers_RouterLink;
    function &Throw(APatch: String; AComponent: TFMXObject): ILayers_RouterLink; overload;
{$ELSE}
    function Layer_Animation(ALayer_Animation: TProc<TPanel>): ILayers_RouterLink;
    function &Throw(APatch: String; AComponent: TPanel): ILayers_RouterLink; overload;
{$ENDIF}
    function &Throw(APatch: String): ILayers_RouterLink; overload;
    function &Throw(APatch: String; ANamedContainer: String): ILayers_RouterLink; overload;
    function &Throw(APatch: String; APropersys: TPropersys; AKey: String = ''): ILayers_RouterLink; overload;
    function IndexLink(APatch: String): ILayers_RouterLink;
  end;

var
  Layers_RouterLink: ILayers_RouterLink;

implementation

{ TLayers_RouterLink }
uses
  Layers_Router.Story;
{$IFDEF HAS_FMX}

function TLayers_RouterLink.Layer_Animation(ALayer_Animation: TProc<TFMXObject>)
  : ILayers_RouterLink;
begin
  Result := Self;
  FLayer_Animation := ALayer_Animation;
end;

function TLayers_RouterLink.&Throw(APatch: String; AComponent: TFMXObject)
  : ILayers_RouterLink;
begin
  Result := Self;
  AComponent.RemoveObject(0);
  Layers_RouterStory.InstanteObject.UnRender;

  AComponent.AddObject(Layers_RouterStory
    .GetStory(APatch).Render);
end;

{$ELSE}

function TLayers_RouterLink.Layer_Animation(ALayer_Animation: TProc<TPanel>)
  : ILayers_RouterLink;
begin
  Result := Self;
  FLayer_Animation := ALayer_Animation;
end;

function TLayers_RouterLink.&Throw(APatch: String; AComponent: TPanel)
  : ILayers_RouterLink;
begin
  Result := Self;
  AComponent.RemoveObject;
  Layers_RouterStory.InstanteObject.UnRender;

  if FParent is TForm then
    AComponent.AddObject(Layers_RouterStory.GetStory(APatch).RendTheForm);

  if FParent is TFrame then
    AComponent.AddObject(Layers_RouterStory.GetStory(APatch).RendTheFrame);
end;

{$ENDIF}

constructor TLayers_RouterLink.Create;
begin

end;

destructor TLayers_RouterLink.Destroy;
begin
  inherited;
end;

class function TLayers_RouterLink.New: ILayers_RouterLink;
begin
  if not Assigned(Layers_RouterLink) then
    Layers_RouterLink := Self.Create;

  Result := Layers_RouterLink;
end;

function TLayers_RouterLink.&Throw(APatch: String): ILayers_RouterLink;
begin
  Result := Self;
{$IFDEF HAS_FMX}
  Layers_RouterStory.MainRouter.RemoveObject(0);
{$ELSE}
  Layers_RouterStory.MainRouter.RemoveObject;
{$ENDIF}
  Layers_RouterStory.InstanteObject.UnRender;

  Layers_RouterStory.MainRouter.AddObject(Layers_RouterStory.GetStory(APatch)
    .RendTheForm);

  Layers_RouterStory.MainRouter.AddObject(Layers_RouterStory.GetStory(APatch)
    .RendTheFrame);

  if Assigned(FLayer_Animation) then
    FLayer_Animation(Layers_RouterStory.MainRouter);
end;

function TLayers_RouterLink.&Throw(APatch: String; APropersys: TPropersys;
  AKey: String = ''): ILayers_RouterLink;
begin
  Result := Self;
{$IFDEF HAS_FMX}
  Layers_RouterStory.MainRouter.RemoveObject(0);
{$ELSE}
  Layers_RouterStory.MainRouter.RemoveObject;
{$ENDIF}
  Layers_RouterStory.InstanteObject.UnRender;

  Layers_RouterStory.MainRouter.AddObject(Layers_RouterStory.GetStory(APatch)
    .RendTheForm);

  Layers_RouterStory.MainRouter.AddObject(Layers_RouterStory.GetStory(APatch)
    .RendTheFrame);

  if Assigned(FLayer_Animation) then
    FLayer_Animation(Layers_RouterStory.MainRouter);

  if AKey <> '' then
    APropersys.Key(AKey);
  GlobalEventBus.Post(APropersys);
end;

function TLayers_RouterLink.&Throw(APatch, ANamedContainer: String)
  : ILayers_RouterLink;
var
{$IFDEF HAS_FMX}
  LContainer: TFMXObject;
{$ELSE}
  LContainer: TPanel;
{$ENDIF}
begin
  Result := Self;
  Layers_RouterStory.InstanteObject.UnRender;
  LContainer := Layers_RouterStory.GetStoryContainer(ANamedContainer);
{$IFDEF HAS_FMX}
  LContainer.RemoveObject(0);
{$ELSE}
  LContainer.RemoveObject;
{$ENDIF}
    LContainer
      .AddObject(Layers_RouterStory.GetStory(APatch).RendTheForm);

    LContainer
        .AddObject(Layers_RouterStory.GetStory(APatch).RendTheFrame);

  if Assigned(FLayer_Animation) then
    FLayer_Animation(LContainer);
end;

function TLayers_RouterLink.IndexLink(APatch: String): ILayers_RouterLink;
begin
  Result := Self;
{$IFDEF HAS_FMX}
  Layers_RouterStory.IndexRouter.RemoveObject(0);
{$ELSE}
  Layers_RouterStory.IndexRouter.RemoveObject;
{$ENDIF}
  Layers_RouterStory.InstanteObject.UnRender;

  if FParent is TForm then
  begin
    Layers_RouterStory.IndexRouter.AddObject(Layers_RouterStory.GetStory(APatch).RendTheForm);
  end;

  if FParent is TFrame then
  begin
    Layers_RouterStory.IndexRouter.AddObject(Layers_RouterStory.GetStory(APatch)
      .RendTheFrame);
  end;

  if Assigned(FLayer_Animation) then
    FLayer_Animation(Layers_RouterStory.IndexRouter);
end;

initialization

Layers_RouterLink := TLayers_RouterLink.New;

end.
