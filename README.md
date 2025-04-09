# Naro2mobi外部ダウンローダー用GUI-2(Extdl_GUI2)
Naro2mobi用外部ダウンローダーをGUI(Windowsのグラフィックユーザーインターフェイス)から使用するためのフロントエンドアプリケーションです。

Extdl_GUIではシンプルなインターフェイスで都度ダウンロードしたいWeb小説作品トップページURLを指定してダウンロードする櫃世yがありましたが、このExtdl_GUI2ではNaro2mobiのDLリストのように複数の作品URLを登録して連続でダウンロードすることが出来ます。


## 使い方
Extdl_GUI2.exeをNaro2mobi用外部ダウンローダーと同じフォルダ内にコピーして下さい。尚、外部ダウンローダーを認識するために定義ファイルであるExtDLoade.txtも必要です。

Extdl_GUI2.exeを起動すると、最初に使用できる外部ダウンローダーの一覧が表示されます。
![extdlgui1](https://github.com/user-attachments/assets/0557d2fe-3492-4e3e-ab04-d560c83ad187)

ダウンロードしたい作品のトップページURLをクリップボードにコピーするか、Webブラウザのアドレスバーからリストボックス部分にドラッグ＆ドロップします。クリップボードへコピーするURLは複数行に渡っていればそれらを一括で登録します。

また、リストボックス右下のある「開く」「保存」ボタンで、ファイルからURLリストを読み込んだり、ファイルに保存したりできます。

保存フォルダを指定したい場合は、保存フォルダ右側の「･･･」ボタンを押して指定します。
![extdlgui2](https://github.com/user-attachments/assets/1167f2c4-bbf6-40d7-85d6-e9b22381b29b)

あとは「実行」ボタンを押せばURLリストに従って連続でダウンロードします。
![extdlgui3](https://github.com/user-attachments/assets/0bb7017c-194d-40af-b658-f4d7998ba815)


## ビルド方法
Lazarus 3.2以降でプロジェクトファイルextdl_gui2.lpiを開いてビルドして下さい。尚、ビルドするためには以下の追加ライブラリが必要です。

・TRegExpr  https://github.com/andgineer/TRegExprからCloneまたはダウンロードする

・DragDrop  LazarusのパッケージメニューにあるOnline Package Managerからインストールする


