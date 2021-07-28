unit Layers_Router.Sidebars;

{$I Layers_Router.inc}

interface

{$IFDEF HAS_FMX}

uses
  Classes,
  SysUtils,
  FMX.Types,
  FMX.ListBox,
  FMX.SearchBox,
  FMX.Layouts,
  Layers_Router.Interfaces,
  System.UITypes;

type
  TLayers_RouterSidebar = class(TInterfacedObject, ILayers_RouterSidebars)
  private
    FName: String;
    FMainContainer: TFMXObject;
    FLinkContainer: TFMXObject;
    FAnimation: TProc<TFMXObject>;
    FFontSize: Integer;
    FFontColor: TAlphaColor;
    FItemHeigth: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: ILayers_RouterSidebars;
    function Layer_Animation(ALayer_Animation: TProc<TFMXObject>): ILayers_RouterSidebars;
    function MainContainer(AValue: TFMXObject): ILayers_RouterSidebars; overload;
    function MainContainer: TFMXObject; overload;
    function LinkContainer(AValue: TFMXObject): ILayers_RouterSidebars;
    function RenderToListBox: ILayers_RouterSidebars;
    function Name(AValue: String): ILayers_RouterSidebars; overload;
    function Name: String; overload;
    function FontSize(AValue: Integer): ILayers_RouterSidebars;
    function FontColor(AValue: TAlphaColor): ILayers_RouterSidebars;
    function ItemHeigth(AValue: Integer): ILayers_RouterSidebars;
  end;

implementation

uses
  Layers_Router,
  Layers_Router.Story,
  Layers_Router.Utils;

{ TLayers_RouterSidebar }

function TLayers_RouterSidebar.Layer_Animation(ALayer_Animation: TProc<TFMXObject>): ILayers_RouterSidebars;
begin
  Result := Self;
  FAnimation := ALayer_Animation;
end;

function TLayers_RouterSidebar.LinkContainer(AValue: TFMXObject): ILayers_RouterSidebars;
begin
  Result := Self;
  FLinkContainer := AValue;
end;

function TLayers_RouterSidebar.MainContainer(AValue: TFMXObject): ILayers_RouterSidebars;
begin
  Result := Self;
  FMainContainer := AValue;
end;

function TLayers_RouterSidebar.MainContainer: TFMXObject;
begin
  Result := FMainContainer;
end;

function TLayers_RouterSidebar.RenderToListBox: ILayers_RouterSidebars;
var
  LListBox: TListBox;
  LListBoxItem: TListBoxItem;
  LListBoxSearch: TSearchBox;
  LItem: TCachePersistent;
begin
  LListBox := TListBox.Create(FMainContainer);
  LListBox.Align := TAlignLayout.Client;

  LListBox.StyleLookup := 'transparentlistboxstyle';

  LListBox.BeginUpdate;

  LListBoxSearch := TSearchBox.Create(LListBox);
  LListBoxSearch.Height := FItemHeigth - 25;
  LListBox.ItemHeight := FItemHeigth;

  LListBox.AddObject(LListBoxSearch);

  for LItem in Layers_RouterStory.RoutersListPersistent.Values do
  begin
    if LItem.FisVisible and (LItem.FSBKey = FName) then
    begin
      LListBoxItem := TListBoxItem.Create(LListBox);
      LListBoxItem.Parent := LListBox;
      LListBoxItem.StyledSettings := [TStyledSetting.Other];
      LListBoxItem.TextSettings.Font.Size := FFontSize;
      LListBoxItem.FontColor := FFontColor;
      LListBoxItem.Text := LItem.FPatch;
      LListBox.AddObject(LListBoxItem);
    end;
  end;
  LListBox.EndUpdate;

  Layers_RouterHistory.AddHistoryConteiner(FName, FLinkContainer);

  LListBox.OnClick :=

    TNotifyEventWrapper.AnonProc2NotifyEvent(LListBox,
    procedure(Sender: TObject; Aux: String)
    begin
      TLayers_Router.Link.Layer_Animation(
        procedure(AObject: TFMXObject)
        begin
          TLayout(AObject).Opacity := 0;
          TLayout(AObject).AnimateFloat('Opacity', 1, 0.2);
        end).&Throw((Sender as TListBox).Items[(Sender as TListBox)
        .ItemIndex], Aux)
    end, FName);

  FMainContainer.AddObject(LListBox);
end;

constructor TLayers_RouterSidebar.Create;
begin
  FName := 'SBIndex';
  FLinkContainer := Layers_RouterHistory.MainRouter;
end;

destructor TLayers_RouterSidebar.Destroy;
begin

  inherited;
end;

function TLayers_RouterSidebar.FontColor(AValue: TAlphaColor)
  : ILayers_RouterSidebars;
begin
  Result := Self;
  FFontColor := AValue;
end;

function TLayers_RouterSidebar.FontSize(AValue: Integer)
  : ILayers_RouterSidebars;
begin
  Result := Self;
  FFontSize := AValue;
end;

function TLayers_RouterSidebar.ItemHeigth(AValue: Integer)
  : ILayers_RouterSidebars;
begin
  Result := Self;
  FItemHeigth := AValue;
end;

function TLayers_RouterSidebar.Name(AValue: String): ILayers_RouterSidebars;
begin
  Result := Self;
  FName := AValue;
end;

function TLayers_RouterSidebar.Name: String;
begin
  Result := FName;
end;

class function TLayers_RouterSidebar.New: ILayers_RouterSidebars;
begin
  Result := Self.Create;
end;

{$ELSE}

implementation

{$ENDIF}

end.
