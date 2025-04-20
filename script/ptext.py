#
#
# Naro2mobi外部ダウンローダーでダウンロードした青空文庫形式準拠テキストを
# プレーンテキストに変換する
#
import sys
import re

# 青空文庫タグを除去する
def eliminate_tags(line: str) -> str:
    tmpstr = re.sub('［＃.*?］', '', line)
    tmpstr = re.sub('［＃.*?（', '', tmpstr)
    tmpstr = re.sub('）入る］', '', tmpstr)
    tmpstr = re.sub('｜', '', tmpstr)
    tmpstr = re.sub('《', '（', tmpstr)
    tmpstr = re.sub('》', '）', tmpstr)
    # エンコードされた青空文庫特殊文字をデコードする
    tmpstr = re.sub('※［＃始め二重山括弧、1-1-52］', '《', tmpstr)
    tmpstr = re.sub('※［＃終わり二重山括弧、1-1-53］', '》', tmpstr)
    tmpstr = re.sub('※［＃縦線、1-1-35］', '｜', tmpstr)
    return tmpstr

def main():
    if len(sys.argv) == 1:
        print('Usage:')
        print('  python ptext.py 青空文庫形式準拠テキストファイル名')
        quit()

    infile = sys.argv[1]
    print(infile + '->')
    try:
        fin = open(infile, 'r', encoding='UTF-8')
        atext = fin.read()
        fin.close()
    except:
        print('ファイル読み込みエラー.')
        quit()
    ptext = eliminate_tags(atext)
    try:
        fout = open(infile + '.txt', 'w', encoding='UTF-8')
        fout.write(ptext)
        fout.close()
    except:
        print('ファイル書き込みエラー.')
        quit()
    print(infile + '.txt として保存しました.')

if __name__ == '__main__':
    main()
