program extdl_gui2;

{$MODE DELPHI}
{$CODEPAGE UTF8}

uses
  Interfaces,
  Forms, MainUnit;

{$R *.res}

begin
	Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

