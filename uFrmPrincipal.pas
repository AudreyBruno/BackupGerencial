unit uFrmPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls, Vcl.StdCtrls, FireDAC.Stan.Def,
  FireDAC.Phys.IBWrapper, FireDAC.Phys.FBDef, FireDAC.Phys, FireDAC.Phys.IBBase, FireDAC.Phys.FB,
  FireDAC.Stan.Intf, FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Comp.UI, System.UITypes, System.ImageList,
  Vcl.ImgList, System.Zip, IniFiles, Vcl.AppEvnts, Vcl.Menus;

type
  TFrmPrincipal = class(TForm)
    pnlTopo: TPanel;
    img42x42: TImage;
    mmoProgresso: TMemo;
    pnlRodape: TPanel;
    btnIniciar: TButton;
    btnFechar: TButton;
    FDIBBackup1: TFDIBBackup;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    imgs16x16: TImageList;
    FDIBRestore1: TFDIBRestore;
    ApplicationEvents: TApplicationEvents;
    TrayIcon: TTrayIcon;
    PopupMenu: TPopupMenu;
    Maximizar1: TMenuItem;
    Fechar1: TMenuItem;
    Timer1: TTimer;
    procedure btnFecharClick(Sender: TObject);
    procedure btnIniciarClick(Sender: TObject);
    procedure FDIBBackup1Progress(ASender: TFDPhysDriverService; const AMessage: string);
    procedure FormCreate(Sender: TObject);
    procedure ApplicationEventsMinimize(Sender: TObject);
    procedure Maximizar1Click(Sender: TObject);
    procedure Fechar1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    I: TIniFile;
    procedure HabilitarBotoes(bHabilitar: Boolean = True);
    procedure GerarBackup;
    procedure ThreadTerminateBackup(Sender: TObject);
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.dfm}

procedure TFrmPrincipal.ThreadTerminateBackup(Sender: TObject);
begin
  HabilitarBotoes();
end;

procedure TFrmPrincipal.ApplicationEventsMinimize(Sender: TObject);
begin
  Self.Hide();
  Self.WindowState := wsMinimized;
  TrayIcon.Visible := True;
  TrayIcon.Animate := True;
  //TrayIcon.ShowBalloonHint;
end;

procedure TFrmPrincipal.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmPrincipal.btnIniciarClick(Sender: TObject);
begin
  GerarBackup;
end;

procedure TFrmPrincipal.FDIBBackup1Progress(ASender: TFDPhysDriverService; const AMessage: string);
begin
  mmoProgresso.Lines.Add(AMessage);
end;

procedure TFrmPrincipal.Fechar1Click(Sender: TObject);
begin
  Close;
end;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
  I:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  Self.WindowState := wsMinimized;
  TrayIcon.Visible := True;
  TrayIcon.Animate := True;
end;

procedure TFrmPrincipal.GerarBackup;
var
  ZipFile: TZipFile;
  data, CaminhoBanco, CaminhoBackup, CaminhoBackupRede, Tipo, FilePath: string;
  t: TThread;
begin
  t := TThread.CreateAnonymousThread(procedure
  begin
    try
      HabilitarBotoes(False);
      data := FormatDateTime('YYYYMMDD',strtodate(DateToStr(Date)));
      CaminhoBanco := I.ReadString('PARAMETROS','CaminhoBanco','');
      CaminhoBackup := I.ReadString('PARAMETROS','CaminhoBackup','');
      CaminhoBackupRede := I.ReadString('PARAMETROS','CaminhoBackupRede','');
      Tipo := I.ReadString('PARAMETROS','Tipo','');

      FDIBBackup1.UserName  := 'sysdba';
      FDIBBackup1.Password  := 'masterkey';
      FDIBBackup1.Host      := 'localhost';
      FDIBBackup1.Protocol  := ipTCPIP;
      FDIBBackup1.Verbose   := True;
      FDIBBackup1.Database  := CaminhoBanco + '\ASDB.FDB';
      FDIBBackup1.BackupFiles.Add(CaminhoBackup + '\ASDB.FBK');
      FDIBBackup1.Backup;

      FDIBRestore1.UserName := 'sysdba';
      FDIBRestore1.Password := 'masterkey';
      FDIBRestore1.Host := 'localhost';
      FDIBRestore1.Protocol := ipTCPIP;
      FDIBRestore1.Verbose   := True;
      FDIBRestore1.Database := CaminhoBackup + '\' + data + '_ASDB.FDB';
      FDIBRestore1.BackupFiles.Add(CaminhoBackup + '\ASDB.FBK');
      FDIBRestore1.Restore;

      ZipFile := TZipFile.Create;
      try
        ZipFile.Open(CaminhoBackup + '\' + data + '_ASDB.zip', zmWrite);
        ZipFile.Add(CaminhoBackup + '\' + data + '_ASDB.FDB');

        if Tipo = '1' then
          begin
            ZipFile.Open(CaminhoBackupRede + '\' + data + '_ASDB.zip', zmWrite);
            ZipFile.Add(CaminhoBackup + '\' + data + '_ASDB.FDB');
          end;

      finally
        ZipFile.Free;
      end;

      FilePath := CaminhoBackup + '\ASDB.FBK';
      if FileExists(FilePath) then
        DeleteFile(FilePath);

      FilePath := CaminhoBackup + '\' + data + '_ASDB.FDB';
      if FileExists(FilePath) then
        DeleteFile(FilePath);

    except on E: Exception do
      begin
        MessageDlg('Erro ao gerar backup!' + sLineBreak + E.Message, mtError, [mbOK], 0);
      end;
    end;
  end);

  t.OnTerminate := ThreadTerminateBackup;
  t.Start;
end;

procedure TFrmPrincipal.HabilitarBotoes(bHabilitar: Boolean);
begin
  btnIniciar.Enabled  := bHabilitar;
  btnFechar.Enabled   := bHabilitar;
end;

procedure TFrmPrincipal.Maximizar1Click(Sender: TObject);
begin
  TrayIcon.Visible := False;
  Show();
  WindowState := wsNormal;
  Application.BringToFront();
end;

procedure TFrmPrincipal.Timer1Timer(Sender: TObject);
var
  hora, horai, horaf, timer, a: string;
begin
  timer := TimeToStr(Time);
  hora := I.ReadString('PARAMETROS','Hora','');
  horai := hora+':00';
  horaf := hora+':59';
  if (timer > horai) and (timer < horaf) then
    begin
      Timer1.Enabled := False;
      GerarBackup;
    end;
end;

end.
