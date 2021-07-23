unit Samples.View.Frames.Menu;

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
  Vcl.Buttons,
  Vcl.Imaging.pngimage,
  Vcl.ExtCtrls,

  // Layers_Rotuer - Library
  Layers_Router,
  Layers_Router.Interfaces,
  Layers_Router.Propersys;

type
  TFrameMenu = class(TFrame, ILayers_RouterComponent)
    pnlMenu: TPanel;
    imgTools: TImage;
    imgUsuario: TImage;
    imgReport: TImage;
    imgCidades: TImage;
    btnCidades: TSpeedButton;
    btnReport: TSpeedButton;
    btnUsuario: TSpeedButton;
    btnTools: TSpeedButton;
    procedure FrameMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure btnCidadesClick(Sender: TObject);
    procedure btnUsuarioClick(Sender: TObject);
    procedure btnReportClick(Sender: TObject);
  private
    { Private declarations }
    function RendTheForm : TForm;
    function RendTheFrame : TFrame;
    procedure UnRender;
  public
    { Public declarations }
  end;

implementation

uses
  Samples.View.Main;

{$R *.dfm}

{ TFrameMenu }

procedure TFrameMenu.btnCidadesClick(Sender: TObject);
begin
  TLayers_Router.Link
    .&Throw('Cidade',
      TPropersys
        .Create
        .ProprsString('Cadastro de Cidades')
        .Key('TelaCidades')
    );

end;

procedure TFrameMenu.btnReportClick(Sender: TObject);
begin
  TLayers_Router.Link
    .&Throw('Template',
      TPropersys
        .Create
        .ProprsString('TITLE')
    );
end;

procedure TFrameMenu.btnUsuarioClick(Sender: TObject);
begin
  TLayers_Router.Link
    .&Throw('Usuario');
end;

procedure TFrameMenu.FrameMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if fMain.splMenu.Opened = False then
    fMain.TaskOn_Menu(0);
end;

function TFrameMenu.RendTheForm: TForm;
begin

end;

function TFrameMenu.RendTheFrame: TFrame;
begin
  Result := Self;
end;

procedure TFrameMenu.UnRender;
begin

end;

end.
