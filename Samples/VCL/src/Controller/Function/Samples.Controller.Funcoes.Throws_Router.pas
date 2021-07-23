unit Samples.Controller.Funcoes.Throws_Router;

interface

type
  TThrows_Router = class
    private
    public
      constructor Create;
      destructor Destroy; override;
      class function New : TThrows_Router;
  end;

var
  Throws_Router : TThrows_Router;

implementation

{ TRouters }

uses
  Layers_Router,
  Samples.View.Pages.Standards_Principal,
  Samples.View.Pages.Template,
  Samples.View.Pages.Usuarios,
  Samples.View.Pages.Cidades,
  Samples.View.Frames.Menu;

constructor TThrows_Router.Create;
begin
  TLayers_Router
    .Switch
      .Router('Principal', TfPageStandards)
      .Router('Menu', TFrameMenu)
      .Router('Template', TfPageTemplate)
      .Router('Usuario', TfPageUsuario)
      .Router('Cidade', TfPageCidades);
end;

destructor TThrows_Router.Destroy;
begin

  inherited;
end;

class function TThrows_Router.New: TThrows_Router;
begin
   Result := Self.Create;
end;

initialization
  Throws_Router := TThrows_Router.New;

finalization
  if Assigned(Throws_Router) then
    Throws_Router.Free;

end.
