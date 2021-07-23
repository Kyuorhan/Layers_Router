unit Layers_Router.Render;

{$I Layers_Router.inc}

interface

uses
  Vcl.Forms,
{$IFDEF HAS_FMX}
  FMX.Types,
{$ELSE}
  Vcl.ExtCtrls,
  Layers_Router.Helper,
{$ENDIF}
  Layers_Router.Interfaces;

type
  TLayers_RouterRender = class(TInterfacedObject, ILayers_RouterRender)
  private
    [weak]
    FParent: ILayers_RouterComponent;
  public
    constructor Create(Parent: ILayers_RouterComponent);
    destructor Destroy; override;
    class function New(Parent: ILayers_RouterComponent): ILayers_RouterRender;
{$IFDEF HAS_FMX}
    function SetElement(AComponent: TFMXObject; AIndexComponent: TFMXObject = nil): ILayers_RouterRender;
{$ELSE}
    function SetElement(AComponent: TPanel; AIndexComponent: TPanel = nil): ILayers_RouterRender;
{$ENDIF}
  end;

implementation

uses
  Layers_Router.Story;

{ TRouter4DelphiRender }

constructor TLayers_RouterRender.Create(Parent: ILayers_RouterComponent);
begin
  FParent := Parent;
end;

destructor TLayers_RouterRender.Destroy;
begin

  inherited;
end;

{$IFDEF HAS_FMX}

function TLayers_RouterRender.SetElement(AComponent: TFMXObject;
  AIndexComponent: TFMXObject = nil): ILayers_RouterRender;
begin
  Result := Self;
  Router4DHistory.MainRouter(AComponent);

  if AIndexComponent <> nil then
    Router4DHistory.IndexRouter(AIndexComponent);

  if Assigned(FParent) then
  begin
    AComponent.RemoveObject(0);
    AComponent.AddObject(FParent.Render);
  end;
end;

{$ELSE}

function TLayers_RouterRender.SetElement(AComponent: TPanel;
  AIndexComponent: TPanel = nil): ILayers_RouterRender;
begin
  Result := Self;
  Layers_RouterStory.MainRouter(AComponent);

  if AIndexComponent <> nil then
    Layers_RouterStory.IndexRouter(AIndexComponent);

  AComponent.RemoveObject;
  if FParent is TForm then
    AComponent.AddObject(FParent.RendTheForm);

  if FParent is TFrame then
    AComponent.AddObject(FParent.RendTheFrame);
end;

{$ENDIF}

class function TLayers_RouterRender.New(Parent: ILayers_RouterComponent): ILayers_RouterRender;
begin
  Result := Self.Create(Parent);
end;

end.
