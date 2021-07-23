unit Layers_Router.Interfaces;

{$I Layers_Router.inc}

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.UITypes,
  SysUtils,
{$IFDEF HAS_FMX}
  FMX.Types,
{$ELSE}
  Vcl.ExtCtrls,
  Vcl.Forms,
{$ENDIF}
  Layers_Router.Propersys;

type

  ILayers_Router = interface
    ['{56BF88E9-25AB-49C7-8CB2-F89C95F34816}']
  end;

  ILayers_RouterComponent = interface
    ['{C605AEFB-36DC-4952-A3D9-BA372B998BC3}']
{$IFDEF HAS_FMX}
    function Render: TFMXObject;
{$ELSE}
    function RendTheForm: TForm;
    function RendTheFrame: TFrame;
{$ENDIF}
    procedure UnRender;
  end;

  ILayers_RouterComponentProperty = interface
    ['{FAF5DD55-924F-4A8B-A436-208891FFE30A}']
    procedure Props(APropertys: TPropersys);
  end;

  ILayers_RouterLink = interface
    ['{3C80F86A-D6B8-470C-A30E-A82E620F6F1D}']
{$IFDEF HAS_FMX}
    function &Throw(APatch: String; AComponent: TFMXObject)
      : ILayers_RouterLink; overload;
    function Layer_Animation(ALayer_Animation: TProc<TFMXObject>)
      : ILayers_RouterLink;
{$ELSE}
    function &Throw(APatch: String; AComponent: TPanel)
      : ILayers_RouterLink; overload;
    function Layer_Animation(ALayer_Animation: TProc<TPanel>)
      : ILayers_RouterLink;
{$ENDIF}
    function &Throw(APatch: String): ILayers_RouterLink; overload;
    function &Throw(APatch: String; APropertys: TPropersys; aKey: String = '')
      : ILayers_RouterLink; overload;
    function &Throw(APatch: String; ANameContainer: String)
      : ILayers_RouterLink; overload;
    function IndexLink(APatch: String): ILayers_RouterLink;
  end;

  ILayers_RouterRender = interface
    ['{2BD026ED-3A92-44E9-8CD4-38E80CB2F000}']

{$IFDEF HAS_FMX}
    function SetElement(AComponent: TFMXObject;
      AIndexComponent: TFMXObject = nil): ILayers_RouterRender;

{$ELSE}
    function SetElement(AComponent: TPanel; AIndexComponent: TPanel = nil)
      : ILayers_RouterRender;
{$ENDIF}
  end;

  ILayers_RouterSwitch = interface
    ['{0E49AFE7-9329-4F0C-B289-A713FA3DFE45}']
    function Router(APath: String; aRouter: TPersistentClass;
      ASidebarKey: String = 'SBIndex'; IsVisible: Boolean = True)
      : ILayers_RouterSwitch;
    function UnRouter(APath: String): ILayers_RouterSwitch;
  end;

  ILayers_RouterSidebars = interface
    ['{B4E8C229-A801-4FCA-AF7B-DEF8D0EE5DFE}']
    function Name(AValue: String): ILayers_RouterSidebars; overload;
{$IFDEF HAS_FMX}
    function MainContainer(AValue: TFMXObject): ILayers_RouterSidebars;
      overload;
    function MainContainer: TFMXObject; overload;
    function LinkContainer(AValue: TFMXObject): ILayers_RouterSidebars;
    function Layer_Animation(ALayer_Animation: TProc<TFMXObject>)
      : ILayers_RouterSidebars;
    function RenderToListBox: ILayers_RouterSidebars;
{$ELSE}
    function MainContainer(AValue: TPanel): ILayers_RouterSidebars; overload;
    function MainContainer: TPanel; overload;
    function LinkContainer(AValue: TPanel): ILayers_RouterSidebars;
    function Layer_Animation(ALayer_Animation: TProc<TPanel>): ILayers_RouterSidebars;
{$ENDIF}
    function Name: String; overload;
    function FontSize(AValue: Integer): ILayers_RouterSidebars;
    function FontColor(AValue: TAlphaColor): ILayers_RouterSidebars;
    function ItemHeigth(AValue: Integer): ILayers_RouterSidebars;

  end;

implementation

end.
