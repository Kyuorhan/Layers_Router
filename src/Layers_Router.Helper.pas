unit Layers_Router.Helper;

interface

uses
  System.Classes,
  System.Threading,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Controls;

type
  TLayers_RouterHelper = class Helper for TPanel
  public
    procedure AddObject(AValue: TForm); overload;
    procedure AddObject(AValue: TFrame); overload;
    procedure RemoveObject; overload;
  end;

var
  FTask: ITask;

implementation

procedure TLayers_RouterHelper.AddObject(AValue: TForm);
begin
  if AValue is TForm then
  begin
    FTask := TTask.Run(
      procedure
      begin
        TThread.Synchronize(TThread.CurrentThread,
          procedure
          begin
            AValue.Parent := Self;
            AValue.Show;
          end);
      end);
  end;
end;

procedure TLayers_RouterHelper.AddObject(AValue: TFrame);
begin
  if AValue is TFrame then
  begin
    FTask := TTask.Run(
      procedure
      begin
        TThread.Synchronize(TThread.CurrentThread,
          procedure
          begin
            AValue.Parent := Self;
            AValue.Show;
          end);
      end);
  end;
end;

procedure TLayers_RouterHelper.RemoveObject;
var
  LIndex: Integer;
begin
  for LIndex := Self.ControlCount - 1 downto 0 do
  begin
    if (Self.Controls[LIndex] is TForm) then
      (Self.Controls[LIndex] as TForm).Close;

    if (Self.Controls[LIndex] is TFrame) then
      (Self.Controls[LIndex] as TFrame).Free;
  end;
end;

end.
