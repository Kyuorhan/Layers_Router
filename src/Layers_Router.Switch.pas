unit Layers_Router.Switch;

{$I Layers_Router.inc}

interface

uses
  Classes,
  System.Generics.Collections,
  Layers_Router.Interfaces,
  Layers_Router.Story;

type
  TLayers_RouterSwitch = class(TInterfacedObject, ILayers_RouterSwitch)
  private
    FSideBarList: TDictionary<String, ILayers_RouterSidebars>;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: ILayers_RouterSwitch;
    function Router(APath: String; ARouter: TPersistentClass; ASidebarKey: String = 'SBIndex';
      IsVisible: Boolean = True): ILayers_RouterSwitch;
    function UnRouter(APath: String): ILayers_RouterSwitch;
    function SidebarAdd(APatch: String; ASideBar: ILayers_RouterSidebars): ILayers_RouterSwitch;
    function SideBarList: TDictionary<String, ILayers_RouterSidebars>;
  end;

implementation

{ TLayers_RouterSwitch }

uses
  Layers_Router.Utils;

constructor TLayers_RouterSwitch.Create;
begin
  FSideBarList := TDictionary<String, ILayers_RouterSidebars>.Create;
end;

destructor TLayers_RouterSwitch.Destroy;
begin
  FSideBarList.Free;
  inherited;
end;

class function TLayers_RouterSwitch.New: ILayers_RouterSwitch;
begin
  Result := Self.Create;
end;

function TLayers_RouterSwitch.Router(APath: String; ARouter: TPersistentClass; ASidebarKey: String = 'SBIndex';
  IsVisible: Boolean = True): ILayers_RouterSwitch;
begin  // Where will it register the routes / Onde vai registrar as rotas
  Result := Self;
  RegisterClass(ARouter);
  Layers_RouterStory.AddStory(APath, ARouter, ASidebarKey, IsVisible);
end;

function TLayers_RouterSwitch.SidebarAdd(APatch: String;
  ASideBar: ILayers_RouterSidebars): ILayers_RouterSwitch;
begin
  Result := Self;
  FSideBarList.Add(APatch, ASideBar);
end;

function TLayers_RouterSwitch.SideBarList
  : TDictionary<String, ILayers_RouterSidebars>;
begin
  Result := FSideBarList;
end;

function TLayers_RouterSwitch.UnRouter(APath: String): ILayers_RouterSwitch;
begin
  Result := Self;
  Layers_RouterStory.RemoveStory(APath);
end;

end.
