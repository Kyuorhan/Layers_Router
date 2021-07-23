unit Samples.View.Pages.Usuarios;

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
  Samples.View.Pages.Template;

type
  TfPageUsuario = class(TfPageTemplate)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fPageUsuario: TfPageUsuario;

implementation

{$R *.dfm}

end.
