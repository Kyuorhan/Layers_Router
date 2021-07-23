program Samples;

uses
  Vcl.Forms,
  Samples.View.Pages.Template in 'src\View\Pages\Samples.View.Pages.Template.pas' {fPageTemplate},
  Samples.View.Main in 'src\View\Samples.View.Main.pas' {fMain},
  Samples.Controller.Funcoes.Throws_Router in 'src\Controller\Function\Samples.Controller.Funcoes.Throws_Router.pas',
  Samples.View.Frames.Menu in 'src\View\Frames\Samples.View.Frames.Menu.pas' {FrameMenu: TFrame},
  JK.EventBus.Core in '..\..\src\JK.EventBus.Core.pas',
  JK.EventBus.Subscribers in '..\..\src\JK.EventBus.Subscribers.pas',
  JK.ObjectsMappers in '..\..\src\JK.ObjectsMappers.pas',
  JK.RTTIUtils in '..\..\src\JK.RTTIUtils.pas',
  JK.TypedList in '..\..\src\JK.TypedList.pas',
  Layers_Router.Helper in '..\..\src\Layers_Router.Helper.pas',
  Layers_Router.Interfaces in '..\..\src\Layers_Router.Interfaces.pas',
  Layers_Router.Link in '..\..\src\Layers_Router.Link.pas',
  Layers_Router in '..\..\src\Layers_Router.pas',
  Layers_Router.Propersys in '..\..\src\Layers_Router.Propersys.pas',
  Layers_Router.Render in '..\..\src\Layers_Router.Render.pas',
  Layers_Router.Sidebars in '..\..\src\Layers_Router.Sidebars.pas',
  Layers_Router.Story in '..\..\src\Layers_Router.Story.pas',
  Layers_Router.Switch in '..\..\src\Layers_Router.Switch.pas',
  Layers_Router.Utils in '..\..\src\Layers_Router.Utils.pas',
  Samples.View.Pages.Standards_Principal in 'src\View\Pages\Samples.View.Pages.Standards_Principal.pas' {fPageStandards},
  Samples.View.Pages.Usuarios in 'src\View\Pages\Samples.View.Pages.Usuarios.pas' {fPageUsuario},
  Samples.View.Pages.Cidades in 'src\View\Pages\Samples.View.Pages.Cidades.pas' {fPageCidades};

{$R *.res}

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := True;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfPageStandards, fPageStandards);
  Application.CreateForm(TfPageUsuario, fPageUsuario);
  Application.CreateForm(TfPageCidades, fPageCidades);
  Application.Run;
end.
