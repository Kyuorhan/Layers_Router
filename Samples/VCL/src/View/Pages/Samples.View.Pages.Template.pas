unit Samples.View.Pages.Template;

interface

uses
  Data.DB,
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Grids,
  Vcl.DBGrids,
  Vcl.Buttons,
  System.ImageList,
  Vcl.ImgList,

  // Framework Layers_Router
  Layers_Router,
  Layers_Router.Interfaces,
  Layers_Router.Propersys;

type
  TfPageTemplate = class(TForm, ILayers_RouterComponent)
    imgList32: TImageList;
    pnlPrincipal: TPanel;
    pnlLayout_Style: TPanel;
    lbLayout_Title: TLabel;
    pnlLayout_StyleBtn: TPanel;
    btnMinimized: TSpeedButton;
    btnMaximized: TSpeedButton;
    btnClose: TSpeedButton;
    pnlMain: TPanel;
    pnlMain_Body: TPanel;
    pnlMain_BodyTop: TPanel;
    pnlMain_Body_TopLine: TPanel;
    pnlMain_TopBody_Menu: TPanel;
    btnAtualizar: TSpeedButton;
    btnNovo: TSpeedButton;
    pnlMain_TopBody_Search: TPanel;
    lbSearch: TLabel;
    pnlMain_TopBody_SearchLine: TPanel;
    edtSearch: TEdit;
    pnlMain_BodyData: TPanel;
    pnlMain_Body_DataForm: TPanel;
    pnMain_BottomBody_DataForm: TPanel;
    btnExcluir: TSpeedButton;
    btnSalvar: TSpeedButton;
    btnCancelar: TSpeedButton;
    pnMain_TopBody_DataForm: TPanel;
    pnlMain_Body_DataSearch: TPanel;
    pnlTop: TPanel;
    pnlTop_Body: TPanel;
    btnConfig: TSpeedButton;
    btnRelatorio: TSpeedButton;
    btnHistorico: TSpeedButton;
    pnlTop_BodyTitle: TPanel;
    lbTitle: TLabel;
    pnlMain_BottomBody_DataSearch: TPanel;
    btnBack: TSpeedButton;
    lbPagina: TLabel;
    btnNext: TSpeedButton;
    DBGrid1: TDBGrid;
    procedure btnBackClick(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure btnNovoClick(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
  private
    function RendTheForm : TForm;
    function RendTheFrame : TFrame;
    procedure UnRender;
    procedure ChangeListForm;
  public
    [Subscribe_Attributes]
    procedure Propersys(AValue: TPropersys);
  end;

type
  TGridHack = class(TDBGrid);

var
  fPageTemplate: TfPageTemplate;

implementation

uses
  Samples.View.Main;

{$R *.dfm}

{ TfViewPageTemplate }

procedure TfPageTemplate.btnBackClick(Sender: TObject);
begin
  ChangeListForm;

  pnlMain_Body_DataForm.Visible := False;
//  TLayers_Router.Link
//    .&Throw('Principal',
//      TPropersys
//        .Create
//        .ProprsString('PRINCIPAL')
//        .Key('TelaCidades')
//    );
end;
procedure TfPageTemplate.btnNovoClick(Sender: TObject);
begin
  ChangeListForm;
end;

procedure TfPageTemplate.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if fMain.splMenu.Opened then
    fMain.TaskEnd_Menu(0);
end;

procedure TfPageTemplate.Propersys(AValue: TPropersys);
begin
  lbTitle.Caption := AValue.ProprsString;

  AValue.Free;
end;

procedure TfPageTemplate.ChangeListForm;
begin
  pnlMain_Body_DataForm.Visible := not pnlMain_Body_DataForm.Visible;
  pnlMain_Body_DataSearch.Visible := not pnlMain_Body_DataSearch.Visible;

  if pnlMain_Body_DataForm.Visible = True then
    pnlMain_Body_DataForm.Align := TAlign.alClient
//  else
//    pnlMain_Body_DataForm.Align := TAlign.alClient;
end;

procedure TfPageTemplate.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
begin
  // Style-Font(Linhas)
  TGridHack(DBGrid1).Canvas.Font.Color := clWhite;
  // Mundando a posição e alinhamento dos Textos de cada Linha
  TGridHack(DBGrid1)
    .Canvas
      .TextRect(Rect, Rect.Left + 8, Rect.Top + 8, Column.Field.DisplayText);
end;

function TfPageTemplate.RendTheForm: TForm;
begin
  Result := Self;
end;

function TfPageTemplate.RendTheFrame: TFrame;
begin
//
end;

procedure TfPageTemplate.UnRender;
begin

end;

end.

