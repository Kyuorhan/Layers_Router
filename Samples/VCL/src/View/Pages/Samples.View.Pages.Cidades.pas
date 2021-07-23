unit Samples.View.Pages.Cidades;

interface

uses
  Data.DB,
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.ImageList,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ImgList,
  Vcl.Grids,
  Vcl.DBGrids,
  Vcl.StdCtrls,
  Vcl.Buttons,
  Vcl.ExtCtrls,

  Samples.View.Pages.Template,
  // Layers_Router - Library
  Layers_Router.Interfaces;


type
  TfPageCidades = class(TfPageTemplate, ILayers_RouterComponent)
  private
    { Private declarations }
    function RendTheForm : TForm;
    function RendTheFrames : TFrame;
    procedure UnRender;
  public
    { Public declarations }
  end;

var
  fPageCidades: TfPageCidades;

implementation

{$R *.dfm}

{ TfPageCidades }

function TfPageCidades.RendTheForm: TForm;
begin
  Result := Self;
end;

function TfPageCidades.RendTheFrames: TFrame;
begin

end;

procedure TfPageCidades.UnRender;
begin

end;

end.
