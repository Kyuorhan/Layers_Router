unit Samples.View.Pages.Standards_Principal;

interface

uses
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
  Vcl.Buttons,
  Vcl.Imaging.pngimage,

  // Layers_Router Library
  Layers_Router.Interfaces;

type
  TfPageStandards = class(TForm, ILayers_RouterComponent)
    pnlMain: TPanel;
    pnlPrincipal: TPanel;
    Panel1: TPanel;
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    function RendTheForm : TForm;
    function RendTheFrame : TFrame;
    procedure UnRender;
  public
    { Public declarations }
  end;

var
  fPageStandards: TfPageStandards;

implementation

uses
  Samples.View.Main;

{$R *.dfm}

{ TfPageStandards }

procedure TfPageStandards.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if fMain.splMenu.Opened then
    fMain.TaskEnd_Menu(0);
end;

function TfPageStandards.RendTheForm: TForm;
begin
  Result := Self;
end;

function TfPageStandards.RendTheFrame: TFrame;
begin

end;

procedure TfPageStandards.UnRender;
begin

end;

end.
