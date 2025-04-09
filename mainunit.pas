{
  ExtDL_GUI

  Lazarus(ver3.2以降)でビルドする差に必要なライブラリ
    TRegExpr  https://github.com/andgineer/TRegExprからCloneまたはダウンロードする
    DragDrop  LazarusのパッケージメニューにあるOnline Package Managerからインストールする

  ver1.0  2025/04/09  単純なGUIから実用的なランチャー型に作り変えた
                      開発環境をLazarusに変更した

}
unit MainUnit;


{$MODE DELPHI}
{$CODEPAGE UTF8}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Clipbrd, Controls,
  Forms, Dialogs, StdCtrls, EditBtn, ExtCtrls, ComCtrls, Buttons,
  DragDropInternet, LazUTF8, RegExpr, Types, IniFiles, ShellAPI;

type

  { TMainForm }
  {$IFDEF FPC}
    TWMCopyData = record
      Msg: Cardinal;
      MsgFiller: TDWordFiller;
      From: HWND;
      CopyDataStruct: PCopyDataStruct;
      Result: LRESULT;
    end;
  {$ENDIF}
  TMainForm = class(TForm)
    ExecBtn: TButton;
    AbortBtn: TButton;
    DropURLTarget1: TDropURLTarget;
    NvSite: TLabel;
    OD: TOpenDialog;
    Prgrs: TLabel;
    NvTitle: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    PrgrsBar: TProgressBar;
    SD: TSaveDialog;
    SaveFolder: TEditButton;
    Label1: TLabel;
    AddResult: TLabel;
    Label2: TLabel;
    FD: TSelectDirectoryDialog;
    OpenBtn: TSpeedButton;
    SaveBtn: TSpeedButton;
    URLList: TListBox;
    procedure AbortBtnClick(Sender: TObject);
    procedure DropURLTarget1Drop(Sender: TObject; ShiftState: TShiftState;
      APoint: TPoint; var Effect: Longint);
    procedure ExecBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure SaveFolderButtonClick(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
  private
    FNextClipboardOwner: HWnd;
    ExtDLDat: array[0..64, 0..4] of string;
    ExtDLCnt: integer;
    InitFlag,
    ExecFlag,
    AbortFlag: boolean;
    TextName,
    LogName: string;
    function WMChangeCBChain(AwParam: WParam; AlParam: LParam):LRESULT;
    function WMDrawClipboard(AwParam: WParam; AlParam: LParam):LRESULT;
    procedure AddItems(URLList: string);
    procedure AddItem(URL: string);
    function isMatchURL(URL, RePattern: string): Boolean;
    function IsAffectURL(URL: string): string;
    function LoadExtDLoader(FileName: string): Boolean;
    function IsExtDLoader(URL: string): string;
    function Download(URL: string): boolean;
  public

  protected

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

var
  PrevWndProc: WNDPROC;

{ TMainForm }

// タイトル名にファイル名として使用出来ない文字を'-'に置換する
// Lazarus(FPC)とDelphiで文字コード変換方法が異なるためコンパイル環境で
// 変換処理を切り替える
function PathFilter(PassName: string): string;
var
  path: string;
  tmp: AnsiString;
begin
  // ファイル名を一旦ShiftJISに変換して再度Unicode化することでShiftJISで使用
  // 出来ない文字を除去する
{$IFDEF FPC}
  tmp  := UTF8ToWinCP(PassName);
  path := WinCPToUTF8(tmp);      // これでUTF-8依存文字は??に置き換わる
{$ELSE}
  tmp  := AnsiString(PassName);
	path := string(tmp);
{$ENDIF}
  // ファイル名として使用できない文字を'-'に置換する
  path := ReplaceRegExpr('[\\/:;\*\?\+,."<>|\.\t ]', path, '-');

  Result := path;
end;

// Delphiではprocedure xxx(var Message WMxxx); message WM_XXXX;と宣言することで
// 指定したMessageを受け取った際の処理を記述することが出来るが、Lazarusでは出来
// ないので登録したメッセージ処理内で対応する
//
function WndCallback(Ahwnd: HWND; uMsg: UINT; wParam: WParam; lParam: LParam):LRESULT; stdcall;
var
  ws: WideString;
  s: string;
  sl: TStringList;
begin
  case uMsg of
    WM_COPYDATA:
      begin
        // 送られてくる文字コードはUTF16形式なのでUTF8に変換する
        ws := PWideChar(PCopyDataStruct(LParam).lpData);
        s := UTF16ToUTF8(ws);
        with MainForm do
        begin
          // タイトル名,作者名で送られてくるのでタイトルだけを分離する
          sl := TStringList.Create;
          try
            sl.Delimiter := ',';
            sl.StrictDelimiter := True;
            sl.CommaText := s;
            if sl.Count > 0 then
              s := sl[0];
          finally
            sl.Free;
          end;
          PrgrsBar.Max := PCopyDataStruct(LParam).dwData - 1;
          NvTitle.Caption := 'タイトル：' + s;
          s := UTF8Copy(PathFilter(s), 1, 32);
          TextName := SaveFolder.Text + '\' + s + '.txt';
          LogName  := SaveFolder.Text + '\' + s + '.log';
        end;
      end;
    WM_USER + 30:
      begin
        with MainForm do
        begin
          PrgrsBar.Position := wParam;
          Prgrs.Caption := '[' + IntToStr(PrgrsBar.Position) + '/' + IntToStr(PrgrsBar.Max) + ']';
        end;
      end;
    // https://wiki.lazarus.freepascal.org/Clipboard
    WM_CHANGECBCHAIN:
      begin
        Result := MainForm.WMChangeCBChain(wParam, lParam);
      end;
    WM_DRAWCLIPBOARD:
      begin
        Result := MainForm.WMDrawClipboard(wParam, lParam);
      end;
    else
      Result := CallWindowProc(PrevWndProc, Ahwnd, uMsg, WParam, LParam);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  ini: TIniFile;
  fn: string;
begin
  Clipboard.Clear;
  InitFlag  := False;
  ExecFlag  := False;
  AbortFlag := False;
  // メッセージ処理を登録する
  PrevWndProc := Windows.WNDPROC(SetWindowLongPtr(Self.Handle, GWL_WNDPROC, PtrUInt(@WndCallback)));
  FNextClipboardOwner := SetClipboardViewer(Self.Handle);
  LoadExtDLoader('ExtDLoader.txt');
  fn  := ExtractFilePath(Application.ExeName) + 'extdl_gui.ini';
  ini := TIniFile.Create(fn);
  try
    SaveFolder.Text := ini.ReadString('Options', 'SaveFolder', ExtractFileDir(fn));
    Left := ini.ReadInteger('options', 'WindowsLeft', Left);
    Top  := ini.ReadInteger('options', 'WindowsTop', Top);
  finally
    ini.Free;
  end;
end;

procedure TMainForm.DropURLTarget1Drop(Sender: TObject;
  ShiftState: TShiftState; APoint: TPoint; var Effect: Longint);
var
  tmp: string;
begin
  SetForegroundWindow(Handle);
  tmp := string(DropURLTarget1.URL);
  AddItems(tmp);
end;

procedure TMainForm.AbortBtnClick(Sender: TObject);
begin
  AbortFlag := True;
end;

// URLから対応する外部ダウンローダーを返す
function TMainForm.IsExtDLoader(URL: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to ExtDLCnt do
  begin
    if isMatchURL(URL, ExtDLDat[i][0]) then
    begin
      NvSite.Caption := ExtDLDat[i][1];
      Result := ExtDLDat[i][2];
      Break;
    end;
  end;
end;

// 外部ダウンローダーを起動させる
function TMainForm.Download(URL: string): boolean;
var
  cmd, hstr, cdir, enam, fnam, lnam: string;
  SXInfo: TShellExecuteInfo;
  ret: cardinal;
begin
  Result := False;

  enam := IsExtDLoader(URL);
  if enam = '' then
  begin
    NvTitle.Caption := 'エラー：URLに対応する外部ダウンローダーが見つかりません.';
  end;
  cdir := ExtractFilePath(Application.ExeName);
  enam := cdir + enam;
  fnam := cdir + 'dltxt.txt';
  lnam := cdir + 'dltxt.log';
  hstr := IntToStr(Handle);  // 外部ダウンローダーに渡すNaro2mobiのハンドル
  cmd  := URL + ' "' + fnam + '" -h' + hstr;   // 外部ローダーの3番めの引数に"-hハンドルの文字列"を指定する
  if FileExists(fnam) then
    DeleteFile(fnam);

  Application.ProcessMessages;

  with SXInfo do//TShellExecuteInfo構造体の初期化
  begin
    cbSize := SizeOf(SXInfo);
    fMask  := SEE_MASK_NOCLOSEPROCESS; //これがないと終了待ち出来ない
    Wnd    := Handle;
    lpVerb := nil;
    lpFile := PChar('"' + enam + '"');
    lpParameters := PChar(cmd);
    lpDirectory  := nil;
    nShow := SW_HIDE;
  end;

  ShellExecuteEx(LPSHELLEXECUTEINFO(@SXInfo));

  //起動したアプリケーションの終了待ち
  while WaitForSingleObject(SXInfo.hProcess, 0) = WAIT_TIMEOUT do
  begin
    Application.ProcessMessages;
    Sleep(100);
    if AbortFlag then
    begin
      TerminateProcess(SXInfo.hProcess, ret);
    end;
  end;
  // 終了コードを取得する
  GetExitCodeProcess(SXInfo.hProcess, ret);
  CloseHandle(SXInfo.hProcess);

  PrgrsBar.Position := 0;
  if not FileExists(fnam) then
	  NvTitle.Caption := 'エラー：ダウンロードに失敗しました.'
  else begin
	  NvTitle.Caption := 'ダウンロードしました.';
    // ダウンロードしたテキストファイルを保存フォルダにタイトル名でコピーする
    // 保存ファイル名はそのままだと文字化けするので文字コードをAnsiに変換する
    CopyFile(PChar(fnam), PChar(UTF8ToWinCP(TextName)), False);
    CopyFile(PChar(lnam), PChar(UTF8ToWinCP(LogName)), False);
    if FileExists(TextName) then
      DeleteFile(fnam)
    else
      NvTitle.Caption := 'エラー：ダウンロードテキストの保存に失敗しました.';
    // コピー出来たなら元のファイルを削除する
    if FileExists(LogName) then
      DeleteFile(lnam)
    else
      NvTitle.Caption := 'エラー：ダウンロードテキストの保存に失敗しました.';
    Result := True;
  end;
end;

procedure TMainForm.ExecBtnClick(Sender: TObject);
var
  i, cnt: integer;
  url: string;
begin
  AbortFlag := False;
  ExecFlag  := True;
  ExecBtn.Enabled  := False;
  AbortBtn.Enabled := True;
  cnt := URLList.Items.Count;
  for i := 1 to cnt do
  begin
    url := URLList.Items[0];
    URLList.Selected[0] := True;
    AddResult.Caption := 'ダウンロード：' + url + ' [' + IntToStr(i) + '/' + IntToStr(cnt) + ']';
    Download(url);
    if AbortFlag then
      Break;
    URLList.Items.Delete(0);
  end;
  ExecFlag := False;
  ExecBtn.Enabled  := True;
  AbortBtn.Enabled := False;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  ini: TIniFile;
  fn: string;
begin
  fn  := ExtractFilePath(Application.ExeName) + 'extdl_gui.ini';
  ini := TIniFile.Create(fn);
  try
    ini.WriteString('Options', 'SaveFolder', SaveFolder.Text);
    ini.WriteInteger('options', 'WindowsLeft', Left);
    ini.WriteInteger('options', 'WindowsTop', Top);
  finally
    ini.Free;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  ChangeClipboardChain(Handle, FNextClipboardOwner);
end;

procedure TMainForm.SaveBtnClick(Sender: TObject);
begin
  if SD.Execute then
  begin
    URLList.Items.SaveToFile(SD.FileName);
  end;
end;

procedure TMainForm.SaveFolderButtonClick(Sender: TObject);
begin
  if DirectoryExists(SaveFolder.Text) then
    FD.InitialDir := SaveFolder.Text
  else
    FD.InitialDir := '';
  if FD.Execute then
    SaveFolder.Text := FD.FileName;
end;

procedure TMainForm.OpenBtnClick(Sender: TObject);
var
  sl: TStringList;
begin
  if OD.Execute then
  begin
    sl := TStringList.Create;
    try
      sl.LoadFromFile(OD.FileName);
      URLList.Items.Clear;
      AddItems(sl.Text);
    finally
      sl.Free;
    end;
  end;
end;

// https://wiki.lazarus.freepascal.org/Clipboard
function TMainForm.WMChangeCBChain(AwParam: WParam; AlParam: LParam): LRESULT;
var
  Remove, Next: THandle;
begin
  Remove := AwParam;
  Next := AlParam;
  if FNextClipboardOwner = Remove then FNextClipboardOwner := Next
    else if FNextClipboardOwner <> 0 then
      SendMessage(FNextClipboardOwner, WM_ChangeCBChain, Remove, Next);
  Result := 0;
end;

function TMainForm.WMDrawClipboard(AwParam: WParam; AlParam: LParam): LRESULT;
begin
  if Clipboard.HasFormat(CF_TEXT) Then
  Begin
    SetForegroundWindow(Handle);
    AddItems(Clipboard.AsText);
  end;
  SendMessage(FNextClipboardOwner, WM_DRAWCLIPBOARD, 0, 0);
  Result := 0;
end;

// 複数のURLがある場合は分解してURLリストに追加する
procedure TMainForm.AddItems(URLList: string);
var
  i: integer;
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Text := URLList;
    // 一行ずつURLを追加する
    for i := 0 to sl.Count - 1 do
      AddItem(sl[i]);
  finally
    sl.Free;
  end;
  NvTitle.Caption := 'タイトル：';
  Prgrs.Caption   := '[0/0]';
  NvSite.Caption  := '';
end;

// URLをリストに追加する
procedure TMainForm.AddItem(URL: string);
var
  furl: string;
  i: integer;
begin
  furl := IsAffectURL(URL);
  if furl <> '' then
  begin
    // 重複チェック
    for i := 0 to URLList.Items.Count - 1 do
      if furl = URLList.Items[i] then
      begin
        AddResult.Caption := '追加できません：既に存在しているURLです.';
        Exit;
      end;
    if not InitFlag then
    begin
      URLList.Items.Clear;
      InitFlag := True;
    end;
    URLList.Items.Add(URL);
    AddResult.Caption := 'URLを追加しました(' + IntToStr(URLList.Items.Count) + ')';
    if not ExecFlag then
      ExecBtn.Enabled := True;
  end;
end;

// 外部ダウンローダー定義ファイルを読み込む
function TMainForm.LoadExtDLoader(FileName: string): Boolean;
var
  extdl, extdat: TStringList;
  i: integer;
begin
  Result := False;
  ExtDLCnt := 0;
  if FileExists(FileName) then
  begin
    extdl := TStringList.Create;
    try
      extdat := TStringList.Create;
      try
        extdl.WriteBOM := False;
        extdl.LoadFromFile(FileName, TEncoding.UTF8);
        // 起動時に有効な外部ダウンローダーをチェックする
        URLList.Items.Add('有効なNaro2mobi外部ダウンローダー');
        for i := 0 to extdl.Count - 1 do
        begin
          if Pos('#', extdl[i]) = 1 then   // コメント行
            Continue;
          extdat.CommaText := extdl[i];
          if extdat.Count < 5 then
            Continue;
          ExtDLDat[ExtDLCnt][0] := extdat[0];
          ExtDLDat[ExtDLCnt][1] := extdat[1];
          ExtDLDat[ExtDLCnt][2] := extdat[2];
          ExtDLDat[ExtDLCnt][3] := extdat[3];
          if extdat.Count > 4 then
            ExtDLDat[ExtDLCnt][4] := extdat[4]
          else
            ExtDLDat[ExtDLCnt][4] := '0';
          if FileExists(ExtractFilePath(Application.ExeName) + ExtDLDat[ExtDLCnt][2]) then
            URLList.Items.Add('　' + extdat[1] + ' (' + extdat[2] + ')');
          Inc(ExtDLCnt);
        end;
        if URLList.Items.Count = 1 then
          URLList.Items.Add('　外部ダウンローダーがありません.');
      finally
        extdat.Free;
      end;
    finally
      extdl.Free;
    end;
  end;
end;

// 正規表現によるURLチェック
function TMainForm.isMatchURL(URL, RePattern: string): Boolean;
var
  r: TRegExpr;
begin
  Result := False;
  if RePattern = '' then
    Exit;
  r := TRegExpr.Create;
  try
    r.InputString := URL;
    r.Expression  := RePattern;
    Result := r.Exec;
  finally
    r.Free;
  end;
end;

// URLが有効かどうかチェックする
function TMainForm.IsAffectURL(URL: string): string;
var
  i: integer;
  furl: string;
begin
  Result := '';
  if URL = '' then
    Exit;

  furl := Trim(URL);
  for i := 0 to ExtDLCnt do
  begin
    if isMatchURL(furl, ExtDLDat[i][0]) then
    begin
      Result := furl;
      Exit;
    end;
  end;
  AddResult.Caption := '追加できません：有効なURLではありません.';
end;

end.

