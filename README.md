# Naro2mobi外部ダウンローダー用GUI-2(Extdl_GUI2)
Naro2mobi用外部ダウンローダーをGUI(Windowsのグラフィックユーザーインターフェイス)から使用するためのフロントエンドアプリケーションです。

Extdl_GUIではシンプルなインターフェイスで都度ダウンロードしたいWeb小説作品トップページURLを指定してダウンロードする櫃世yがありましたが、このExtdl_GUI2ではNaro2mobiのDLリストのように複数の作品URLを登録して連続でダウンロードすることが出来ます。


## 使い方
Extdl_GUI2.exeをNaro2mobi用外部ダウンローダーと同じフォルダ内にコピーして下さい。尚、外部ダウンローダーを認識するために定義ファイルであるExtDLoade.txtも必要です。

Extdl_GUI2.exeを起動すると、最初に使用できる外部ダウンローダーの一覧が表示されます。
![exdl1](https://github.com/user-attachments/assets/64ea17c2-4daf-4f61-903f-4133756d0cd7)

ダウンロードしたい作品のトップページURLをクリップボードにコピーするか、Webブラウザのアドレスバーからリストボックス部分にドラッグ＆ドロップします。クリップボードへコピーするURLは複数行に渡っていればそれらを一括で登録します。

また、リストボックス右下のある「開く」「保存」ボタンで、ファイルからURLリストを読み込んだり、ファイルに保存したりできます。

保存フォルダを指定したい場合は、[▼ オプション]ボタンを押して保存フォルダ右側の「･･･」ボタンを押して指定します。
![extdl2](https://github.com/user-attachments/assets/91f5766f-121e-4497-8328-9ae49f6a9f2d)

また、Pythonコンボボックスからpy/python/python3/ruby/perlのいずれかを選択することで、ダウンロードしたテキストファイルを指定したスクリプトで処理することも出来ます。スクリプトを実行しない場合はPythonコンボボックスから「実行しない」を選択してください。
実行できるスクリプトは
py/pytho/pytho3・・・Pytheoスクリプト
ruby・・・rubyスクリプト
perl・・・perlスクリプト
です。
尚、これらのスクリプトを実行するためには、それぞれの実行環境のインストールが必要です。

scriptフォルダ内のサンプルについて

　ptext.py, ptext.rb, ptext.pl：青空文庫形式準拠テキストファイルから青空文庫タグを除去したプレーンテキストを出力します

　split.py：青空文庫形式準拠テキストファイルを１話毎に分割して作成したサブフォルダ内にプレーンテキストとして出力します

　dl_pic.py：青空文庫形式準拠テキストファイル内の［＃リンクの図（xxxx）入る］から挿絵画像をダウンロードして作成したサブフォルダ内に保存します。　

　　　　　　　また合わせて［＃リンクの図（xxxx）入る］を［＃挿絵001（001.jpg）入る］のように置換したファイルを出力します

あとは「実行」ボタンを押せばURLリストに従って連続でダウンロードします。
![extdl4](https://github.com/user-attachments/assets/11a321fd-3966-4351-ad59-745e8f6c0415)

ver1.3からスクリプトの実行結果を確認出来るようになりました(スクリプトのSTDOUTへの出力を表示します)。
![extdl=gui2-5](https://github.com/user-attachments/assets/cbc7b50f-b644-4292-a131-8873ec34bb7c)

scriptコマンドの追加・削除について

　extdl_gui.iniファイルを編集することでScriptコマンドを追加したり削除したりすることが出来ます。

　extdl_gui.ini内のエントリーScriptCommand=以降を編集して下さい。Scriptコマンド同士はカンマ","で区切ってください。

　尚、ここで言うScriptコマンドとは、コマンドラインから実行出来るScript実行コマンドのことを言います。例えばcscriptを追加すればコンソール出力形式のVBScriptを実行出来るかもしれません(確実に出来るとは言っていない)。

 

## ビルド方法
Lazarus 3.2以降でプロジェクトファイルextdl_gui2.lpiを開いてビルドして下さい。尚、ビルドするためには以下の追加ライブラリが必要です。

・TRegExpr  https://github.com/andgineer/TRegExprからCloneまたはダウンロードする

・DragDrop  LazarusのパッケージメニューにあるOnline Package Managerからインストールする

・MeteDarkStyle LazarusのパッケージメニューにあるOnline Package Managerからインストールする

