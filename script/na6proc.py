#
# na6dlでダウンロードしたテキストファイルに改行コードを挿入して読みやすく成形する
# 2025/12/4
#
import sys
import re
import os

def main():
    if len(sys.argv) == 1:
        print('Usage:')
        print('  python na6proc.py 青空文庫形式準拠テキストファイル名')
        quit()
    # ファイル名
    inname = sys.argv[1]
    dr, fnm = os.path.split(inname)   # フルパス名をパス名とファイル名に分離
    nm, ext = os.path.splitext(fnm) # ファイル名を名前と拡張子に分離
    if dr != '':
        outname = dr + '\\' + nm + '[整形済み]' + ext
    else:
        outname = nm + '[整形済み]' + ext
    # 入力・出力ファイルをオープン
    fin = open(inname, 'r', encoding='UTF-8')
    fout = open(outname, 'w', encoding='UTF-8')
    # テキストファイルを１行ずつ読み込んで処理する
    for inline in fin.readlines():
        # ［＃改ページ］
        if re.search('［＃改ページ］', inline):
            fout.writelines(inline)
            fout.writelines('\n')  # 空行を挿入
        # ［＃中見出し］
        elif re.search('［＃中見出し］.*?［＃中見出し終わり］', inline):
            fout.writelines(inline)
            fout.writelines('\n')  # 空行を挿入
        # ［＃水平線］
        elif re.search('［＃水平線］', inline):
            fout.writelines(inline)
            fout.writelines('\n')  # 空行を挿入
        else:
            fout.writelines(inline)

    fin.close()
    fout.close()
    print('整形後のテキストを' + outname + ' に保存しました.\n')

if __name__ == '__main__':
    main()
