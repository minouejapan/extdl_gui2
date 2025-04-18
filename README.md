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

あとは「実行」ボタンを押せばURLリストに従って連続でダウンロードします。
![extdl4](https://github.com/user-attachments/assets/d86d0031-f822-4c05-9e37-d9da34450c4b)



## ビルド方法
Lazarus 3.2以降でプロジェクトファイルextdl_gui2.lpiを開いてビルドして下さい。尚、ビルドするためには以下の追加ライブラリが必要です。

・TRegExpr  https://github.com/andgineer/TRegExprからCloneまたはダウンロードする

・DragDrop  LazarusのパッケージメニューにあるOnline Package Managerからインストールする


