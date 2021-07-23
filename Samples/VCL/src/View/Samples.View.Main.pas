unit Samples.View.Main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Threading,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.WinXCtrls,
  Vcl.Buttons,
  Vcl.Imaging.pngimage,

  // Layers_Router Library
  Layers_Router;

type
  TfMain = class(TForm)
    pnlMain: TPanel;
    pnlPrincipal: TPanel;
    pnlLayout_Style: TPanel;
    lbTitle: TLabel;
    splMenu: TSplitView;
    pnlCreate_Menu: TPanel;
    pnlLayout_StyleBtn: TPanel;
    btnMaximized: TSpeedButton;
    btnClose: TSpeedButton;
    btnMinimized: TSpeedButton;
    procedure Layout_State(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    FTask: ITask;
    function Layout_Maxzed(AState: TForm): Tform;
    function Layout_Minzed(AState: TForm): Tform;
  public
    { Public declarations }
    procedure TaskOn_Menu(ASleep: Cardinal);
    procedure TaskEnd_Menu(ASleep: Cardinal);

  end;

var
  fMain: TfMain;

implementation

{$R *.dfm}

uses
  Samples.View.Pages.Standards_Principal,
  Samples.View.Frames.Menu;

procedure TfMain.FormCreate(Sender: TObject);
begin
  TLayers_Router.Render<TFrameMenu>.SetElement(pnlCreate_Menu, pnlMain);
  TLayers_Router.Render<TfPageStandards>.SetElement(pnlPrincipal, pnlMain);
end;

procedure TfMain.FormDblClick(Sender: TObject);
begin
  Layout_Maxzed(Self);
end;

procedure TfMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const
   sc_DragMove = $f012;
begin
  ReleaseCapture;
  Perform(WM_SYSCOMMAND, sc_DragMove, 0);
end;

procedure TfMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if splMenu.Opened then
    TaskEnd_Menu(0);
end;

function TfMain.Layout_Maxzed(AState: TForm): Tform;
begin
  if AState.WindowState = wsMaximized then
    AState.WindowState := wsNormal
  else
  begin
    AState.WindowState := wsMaximized;
  end;
 Result := AState;
end;

function TfMain.Layout_Minzed(AState: TForm): Tform;
begin
  AState.WindowState := wsMinimized;
  Result := AState;
end;

procedure TfMain.Layout_State(Sender: TObject);
begin
  if TComponent(Sender).Name = 'btnMaximized' then
  begin
    Layout_Maxzed(Self);
  end

  else if TComponent(Sender).Name = 'btnMinimized' then
  begin
    Layout_Minzed(Self);
  end

  else if TComponent(Sender).Name = 'btnClose' then
    Self.Close;
end;

procedure TfMain.TaskOn_Menu(ASleep: Cardinal);
begin
  FTask := TTask.Run(
    procedure
    begin
      Sleep(ASleep);
      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          Self.splMenu.Open;
        end);
    end);
end;

procedure TfMain.TaskEnd_Menu(ASleep: Cardinal);
begin
  FTask := TTask.Run(
    procedure
    begin
      Sleep(ASleep);
      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          Self.splMenu.Close;
        end);
    end);
end;

end.
