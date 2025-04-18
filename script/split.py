#
# Naro2mobi外部ダウンローダーでダウンロードした青空文庫形式準拠テキストを
# １話毎に分割してファイルに保存する
#
import sys
import re
import os
import ptext    #プレーンテキスト出力モジュールptext.pyが必要
# タイトル名をファイル名として使用出来るかどうかチェックし、使用不可文字が
# あれば修正する('-'に置き換える)
def path_filter(title: str) -> str:
    title = re.sub('[\\*?+.\t/:;,.| ]', '-', title)
    if len(title) > 32:
        title = title[:32]
    return title

def main():
    if len(sys.argv) == 1:
        print('Usage:')
        print('  python split.py 青空文庫形式準拠テキストファイル名')
        quit()
    # 入力ファイル名のフォルダを準備する
    fnm = path_filter(os.path.splitext(sys.argv[1])[0])
    if not os.path.isdir(fnm):
        os.mkdir(fnm)
    fin = open(sys.argv[1], 'r', encoding='UTF-8')
    f = False
    n = 1
    # テキストファイルを１行ずつ読み込んで処理する
    for inline in fin.readlines():
        # 中見出しタグが来たら１話分の処理を開始する
        if re.search('［＃中見出し］.*?［＃中見出し終わり］', inline):
            # 最初の中見出しタグ
            if f == False:
                # 保存するファイル名を作成する
                sname = path_filter(str.strip(re.sub('［＃.*?］', '', inline)))
                fout = open(fnm + '\\' + str(n) + ' ' + sname + '.txt', 'w', encoding='UTF-8')
                fout.writelines(ptext.eliminate_tags(inline))
                f = True
            # ２話目以降の中見出しタグ
            else:
                fout.close()
                n += 1
                # 保存するファイル名を作成する
                sname = path_filter(str.strip(re.sub('［＃.*?］', '', inline)))
                fout = open(fnm + '\\' + str(n) + ' ' + sname + '.txt', 'w', encoding='UTF-8')
                fout.writelines(ptext.eliminate_tags(inline))
        # 大見出しタグは無視する
        elif re.search('［＃大見出し］.*?［＃大見出し終わり］', inline):
            inline = ''
        else:
            if f == True:
                fout.writelines(ptext.eliminate_tags(inline))

    fin.close()
    fout.close()
    print(str(n) + ' 話のファイルに分割しました.\n')

if __name__ == '__main__':
    main()
