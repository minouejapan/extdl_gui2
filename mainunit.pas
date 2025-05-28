{
  ExtDL_GUI2

  Lazarus(ver3.2以降)でビルドする差に必要なライブラリ
    TRegExpr  https://github.com/andgineer/TRegExprからCloneまたはダウンロードする
    DragDrop  LazarusのパッケージメニューにあるOnline Package Managerからインストールする
    MetaDarkStyle  LazarusのパッケージメニューにあるOnline Package Managerからインストールする

    1.81     05/28  URLパターンマッチング処理を修正した
    1.8 2025/05/28  shinich39さんからのpull requestをmergeした
                    URLマッチ確認でマッチした場合はそのマッチURLだけを抽出するようにした
    1.71     05/14  Scriptコマンドをiniファイルを編集することで追加・削除出来るようにした
    1.7 2025/05/14  保存フォルダを指定していない場合ダウンロードエラーとなる不具合を修正した
                    Scriptコマンドをextdl_gui.iniファイルで編集できるようにした
    1.6 2025/05/08  ファイル名作成処理をShift-JIS変換からUTF16変換に変更した
    1.5 2025/05/04  ウィンドウ高さを決め打ちではなくDPI補正値を使用するようにした
    1.4 2025/05/03  ダウンロード結果もログ表示するようにした
                    ダークモードの自動切換えに対応した
    1.3 2025/04/21  外部実行ファイルの起動をShellExecuteExからRunCommandIndir(Lazarus依存)に
                    変更してスクリプトの実行結果(コンソール出力)を表示するようにした
    1.2 2025/04/18  ダウンロード後にPython/Ruby/Perlスクリプトを実行する機能を追加した
                    上記に合わせてプレーンテキストで保存するオプションを廃止した
    1.1 2025/04/12  プレーンテキストで保存するオプションを追加した
                    URLリストの削除メニューを追加した
    1.0 2025/04/09  単純なGUIから実用的なランチャー型に作り変えた
                    開発環境をLazarusに変更した

}
unit MainUnit;


{$MODE DELPHI}
{$CODEPAGE UTF8}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Clipbrd, Controls,
  Forms, Dialogs, StdCtrls, EditBtn, ExtCtrls, ComCtrls, Buttons, Menus,
  DragDropInternet, LazUTF8, RegExpr, Types, IniFiles, ShellAPI, Process,
  uDarkStyleParams, uMetaDarkStyle, uDarkStyleSchemes;

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
    CmdLog: TMemo;
    Label5: TLabel;
    OD2: TOpenDialog;
    PyStat: TLabel;
    PyScript: TEditButton;
    PyCommand: TComboBox;
    ExecBtn: TButton;
    AbortBtn: TButton;
    DropURLTarget1: TDropURLTarget;
    DelItem: TMenuItem;
    Label3: TLabel;
    NvSite: TLabel;
    OD: TOpenDialog;
    PM: TPopupMenu;
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
    OptBtn: TSpeedButton;
    CmdLogBtn: TSpeedButton;
    URLList: TListBox;
    procedure AbortBtnClick(Sender: TObject);
    procedure CmdLogBtnClick(Sender: TObject);
    procedure DelItemClick(Sender: TObject);
    procedure DropURLTarget1Drop(Sender: TObject; ShiftState: TShiftState;
      APoint: TPoint; var Effect: Longint);
    procedure ExecBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OptBtnClick(Sender: TObject);
    procedure PMPopup(Sender: TObject);
    procedure PyScriptButtonClick(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure SaveFolderButtonClick(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
    procedure URLListSelectionChange(Sender: TObject; User: boolean);
  private
    FNextClipboardOwner: HWnd;
    ExtDLDat: array[0..64, 0..4] of string;
    ExtDLCnt: integer;
    InitFlag,
    ExecFlag,
    AbortFlag: boolean;
    TextName,
    LogName: string;
    HNormal,
    HExpand: integer;
    function WMChangeCBChain(AwParam: WParam; AlParam: LParam):LRESULT;
    function WMDrawClipboard(AwParam: WParam; AlParam: LParam):LRESULT;
    procedure AddItems(URLList: string);
    procedure AddItem(URL: string);
    function isMatchURL(URL, RePattern: string): string;
    function IsAffectURL(URL: string): string;
    function LoadExtDLoader(FileName: string): Boolean;
    function IsExtDLoader(URL: string): string;
    function Download(URL: string): boolean;
    function ExecPython(TextName: string): boolean;
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
  tmp: WideString;
begin
  // ファイル名を一旦ShiftJISに変換して再度Unicode化することでShiftJISで使用
  // 出来ない文字を除去する
{$IFDEF FPC}
  tmp  := UTF8ToUTF16(PassName);
  path := UTF16ToUTF8(tmp);      // これでUTF-8依存文字は??に置き換わる
{$ELSE}
  tmp  := WideString(PassName);
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
  pn: integer;
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
          pn := PCopyDataStruct(LParam).dwData - 1;
          PrgrsBar.Max := pn;
          if pn = 0 then
            pn := 1;
          NvTitle.Caption := 'タイトル：' + s;
          CmdLog.Lines.Add('タイトル：' + s + ' (' + IntToStr(pn) + '話)');
          s := UTF8Copy(PathFilter(s), 1, 48);
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
  sdpi: integer;
  wscale: double;
begin
  Clipboard.Clear;
  InitFlag  := False;
  ExecFlag  := False;
  AbortFlag := False;

  sdpi      := Screen.PixelsPerInch;
  wscale    := sdpi / 96.0;

  HNormal   := Trunc(390 * wscale);
  HExpand   := Trunc(470 * wscale);
  // メッセージ処理を登録する
  PrevWndProc := Windows.WNDPROC(SetWindowLongPtr(Self.Handle, GWL_WNDPROC, PtrUInt(@WndCallback)));
  FNextClipboardOwner := SetClipboardViewer(Self.Handle);
  LoadExtDLoader('ExtDLoader.txt');
  fn  := ExtractFilePath(Application.ExeName) + 'extdl_gui.ini';
  ini := TIniFile.Create(fn);
  try
    SaveFolder.Text := ini.ReadString('Options', 'SaveFolder', ExtractFileDir(Application.ExeName));
    PyScript.Text := ini.ReadString('options', 'PyScript', '');
    Left := ini.ReadInteger('options', 'WindowsLeft', Left);
    Top  := ini.ReadInteger('options', 'WindowsTop', Top);
    // Scroptコマンド
    with PyCommand do
    begin
      Items.CommaText := Ini.ReadString('options', 'ScriptCommand', '');
      // 初期状態ではiniファイルがないため読み込み結果が''の場合は初期値を設定して書き込む
      if Items.CommaText = '' then
      begin
        Items.CommaText := '実行しない,py,python,python3,ruby,perl';
        Ini.WriteString('options', 'ScriptCommand', Items.CommaText);
      end;
      // 最初のインデックスは'実行しない'固定なので違っていれば’実行しない’を先頭に挿入する
      if Items[0] <> '実行しない' then
      begin
        Items.Insert(0, '実行しない');
        Ini.WriteString('options', 'ScriptCommand', Items.CommaText);
      end;
      ItemIndex := ini.ReadInteger('options', 'pycommand', 0);
    end;
    if not DirectoryExists(SaveFolder.Text) then
      SaveFolder.Text := ExtractFileDir(Application.ExeName);
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

procedure TMainForm.CmdLogBtnClick(Sender: TObject);
begin
  inherited;

  CmdLog.Visible := CmdLogBtn.Down;
end;

procedure TMainForm.DelItemClick(Sender: TObject);
begin
  URLList.Items.Delete(URLList.ItemIndex);
end;

// URLから対応する外部ダウンローダーを返す
function TMainForm.IsExtDLoader(URL: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to ExtDLCnt do
  begin
    if isMatchURL(URL, ExtDLDat[i][0]) <> '' then
    begin
      NvSite.Caption := ExtDLDat[i][1];
      Result := ExtDLDat[i][2];
      Break;
    end;
  end;
end;

// TextNameで指定されたテキストファイルにPythonスクリプトを実行する
function TMainForm.ExecPython(TextName: string): boolean;
var
  pycmd, cmdline, output: string;
begin
  pycmd := PyCommand.Items[PyCommand.ItemIndex];
  if Height = HNormal then
    Height := HExpand;
  CmdLog.Visible := True;
  CmdLogBtn.Down := True;
  PyStat.Caption := 'Scriptを実行中...';
  Application.ProcessMessages;
  cmdline := '> ' + pycmd + ' "' + PyScript.Text + '" "' + TextName + '"';
  CmdLog.Lines.Add(cmdline);
  // Lazarusに依存
  Result := RunCommandIndir(SaveFolder.Text, pycmd, ['"' + PyScript.Text + '"', '"' + TextName + '"'],
                            output, [poWaitOnExit], swoHide);
  CmdLog.Text := CmdLog.Text + #13#10 + WinCPToUTF8(output);
  CmdLog.VertScrollBar.Position := 1000000; // 強引な強制スクロール処理
  if Result then
    PyStat.Caption := 'スクリプトを実行しました.'
  else
    PyStat.Caption := 'スクリプトの実行に失敗しました.';
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
  begin
    CmdLog.Lines.Add('エラー：ダウンロードに失敗しました.'#13#10);
  end else begin
	  CmdLog.Lines.Add('ダウンロードしました.'#13#10);
    // ダウンロードしたテキストファイルを保存フォルダにタイトル名でコピーする
    // 保存ファイル名はそのままだと文字化けするので文字コードをUTF16に変換する
    CopyFileW(PWideChar(UTF8ToUTF16(fnam)), PWideChar(UTF8ToUTF16(TextName)), False);
    CopyFileW(PWideChar(UTF8ToUTF16(lnam)), PWideChar(UTF8ToUTF16(LogName)), False);
    // コピー出来たなら元のファイルを削除する
    if FileExists(LogName) then
      DeleteFile(lnam)
    else
      NvTitle.Caption := 'エラー：ダウンロードテキストの保存に失敗しました.';
    if FileExists(TextName) then
    begin
      DeleteFile(fnam);
      if PyCommand.ItemIndex > 0 then
      begin
        if FileExists(PyScript.Text) then
          if ExecPython(ExtractFileName(TextName)) then
            NvTitle.Caption := 'Pythonスクリプトでダウンロードファイルを処理しました.'
          else
            NvTitle.Caption := 'Pythonスクリプトの実行に失敗しました.';
      end;
    end else
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
  PyStat.Caption := '';
  if not DirectoryExists(SaveFolder.Text) then
    SaveFolder.Text := ExtractFileDir(Application.ExeName);
  if Height = HNormal then
    OptBtnClick(nil);
  CmdLog.Visible := True;
  CmdLogBtn.Down := True;

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
    ini.WriteInteger('options', 'pycommand', PyCommand.ItemIndex);
    ini.WriteString('options', 'PyScript', PyScript.Text);
    ini.WriteInteger('options', 'WindowsLeft', Left);
    ini.WriteInteger('options', 'WindowsTop', Top);
  finally
    ini.Free;
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // 実行中は終了させない
  if ExecFlag then
    CanClose := False;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  ChangeClipboardChain(Handle, FNextClipboardOwner);
end;

procedure TMainForm.OptBtnClick(Sender: TObject);
begin
  if Height = HNormal then
  begin
    Height := HExpand;
    OptBtn.Caption := '▲ オプション';
  end else begin
    Height := HNormal;
    OptBtn.Caption := '▼ オプション';
    CmdLog.Visible := False;
    CmdLogBtn.Down := False;
  end;
end;

procedure TMainForm.PMPopup(Sender: TObject);
begin
  DelItem.Enabled := URLList.SelCount > 0;
end;

procedure TMainForm.PyScriptButtonClick(Sender: TObject);
begin
  if FileExists(PyScript.Text) then
    OD2.FileName := PyScript.Text;
  if OD2.Execute then
    PyScript.Text := OD2.FileName;
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

procedure TMainForm.URLListSelectionChange(Sender: TObject; User: boolean);
begin
  SaveBtn.Enabled := URLList.Count > 0;
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
    URLList.Items.Add(furl);
    AddResult.Caption := 'URLを追加しました(' + IntToStr(URLList.Items.Count) + ')';
    SetForegroundWindow(Handle);
    if not ExecFlag then
      ExecBtn.Enabled := True;
  end;
end;

procedure GetAllExeFiles(const Dir: string; ExeList: TStrings);
var
  SearchRec: TSearchRec;
  Path: string;
begin
  Path := IncludeTrailingPathDelimiter(Dir);

  // Find .exe files in the current directory
  if FindFirst(Path + '*.exe', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then
        ExeList.Add(Path + SearchRec.Name);
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;

  // Recurse into subdirectories
  if FindFirst(Path + '*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Attr and faDirectory) <> 0 then
      begin
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          GetAllExeFiles(Path + SearchRec.Name, ExeList);
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

function FindExeFile(ExeList: TStrings; FileName: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to ExeList.Count - 1 do
  begin
    if AnsiCompareText(ExtractFileName(ExeList[i]), FileName) = 0 then
    begin
      Result := ExeList[i];
      Exit;
    end;
  end;
end;

function JoinPath(Path1, Path2: string): string;
begin
  if (Length(Path1) > 0) and (Path1[Length(Path1)] <> '\') then
    Path1 := Path1 + '\';
  Result := Path1 + Path2;
end;

// 外部ダウンローダー定義ファイルを読み込む
function TMainForm.LoadExtDLoader(FileName: string): Boolean;
var
  extdl, extdat: TStringList;
  i: integer;
  ExeFiles: TStringList;
  FoundPath: string;
  DirPath: string;
begin
  Result := False;
  ExtDLCnt := 0;
  
  // Find external downloaders from "."
  DirPath := ExtractFilePath(Application.ExeName);

  if FileExists(FileName) = False then
  begin
    // No ExtDLoader.txt
    URLList.Items.Add(FileName + ' がありません.');
  end
  else
  begin
    extdl := TStringList.Create;
    ExeFiles := TStringList.Create;
    GetAllExeFiles(DirPath, ExeFiles);
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
          FoundPath := FindExeFile(ExeFiles, extdat[2]);
          if FoundPath = '' then
            Continue;

          ExtDLDat[ExtDLCnt][0] := extdat[0];
          ExtDLDat[ExtDLCnt][1] := extdat[1];
          ExtDLDat[ExtDLCnt][2] := ExtractRelativePath(ExtractFilePath(Application.ExeName), FoundPath);
          ExtDLDat[ExtDLCnt][3] := extdat[3];

          if extdat.Count > 4 then
            ExtDLDat[ExtDLCnt][4] := extdat[4]
          else
            ExtDLDat[ExtDLCnt][4] := '0';

          URLList.Items.Add('　' + extdat[1] + ' (' + ExtDLDat[ExtDLCnt][2] + ')');

          Inc(ExtDLCnt);
        end;
        if URLList.Items.Count = 1 then
          URLList.Items.Add('　外部ダウンローダーがありません.');
      finally
        extdat.Free;
      end;
    finally
      extdl.Free;
      ExeFiles.Free;
    end;
  end;
end;

// 正規表現によるURLチェック
function TMainForm.isMatchURL(URL, RePattern: string): string;
var
  r: TRegExpr;
begin
  Result := '';

  if RePattern = '' then
    Exit;
  r := TRegExpr.Create;
  try
    r.InputString := URL;
    r.Expression  := RePattern;
    if r.Exec then
      Result := r.Match[0];
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
    furl := isMatchURL(furl, ExtDLDat[i][0]);
    if furl <> '' then
    begin
      Result := furl;
      Exit;
    end;
    furl := Trim(URL);
  end;
  AddResult.Caption := '追加できません：有効なURLではありません.';
end;

end.

