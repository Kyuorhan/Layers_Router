unit Layers_Router;

{$I Layers_Router.inc}

interface

uses
  System.Generics.Collections,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  SysUtils,
  {$IFDEF HAS_FMX}
  FMX.Types,
  {$ELSE}
  Vcl.ExtCtrls,
  {$ENDIF}
  Layers_Router.Interfaces,
  Layers_Router.Story,
  Layers_Router.Render,
  Layers_Router.Link;

type
  TLayers_Router = class(TInterfacedObject, ILayers_Router)
    private
    public
      constructor Create;
      destructor Destroy; override;
      class function New : ILayers_Router;
      class function Render<T : class, constructor> : ILayers_RouterRender;
      class function Link : ILayers_RouterLink;
      class function Switch : ILayers_RouterSwitch;

      {$IFDEF HAS_FMX}
      class function SideBar : ILayers_RouterSidebars;
      {$ENDIF}
  end;

implementation

{ TRouter4Delphi }

uses
  Layers_Router.Utils,
  Layers_Router.Switch,
  Layers_Router.Sidebars;

constructor TLayers_Router.Create;
begin

end;

destructor TLayers_Router.Destroy;
begin

  inherited;
end;

class function TLayers_Router.Link: ILayers_RouterLink;
begin
  Result := TLayers_RouterLink.New;
end;

class function TLayers_Router.New: ILayers_Router;
begin
  Result := Self.Create;
end;

class function TLayers_Router.Render<T>: ILayers_RouterRender;
begin
  Layers_RouterStory
    .AddStory(
      TPersistentClass(T).ClassName,
      TPersistentClass(T)
    );


  Result :=
    TLayers_RouterRender
      .New(
        Layers_RouterStory
          .GetStory(
            TPersistentClass(T)
              .ClassName
          )
      );
end;

{$IFDEF HAS_FMX}

class function TLayers_Router.SideBar: ILayers_RouterSidebars;
begin
  Result := TLayers_RouterSidebar.New;
end;

{$ENDIF}

class function TLayers_Router.Switch: ILayers_RouterSwitch;
begin
  Result := TLayers_RouterSwitch.New;
end;

end.
