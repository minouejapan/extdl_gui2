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

    fin = open(sys.argv[1], 'r', encoding='UTF-8')
    atext = fin.read()
    fin.close()

    ptext = eliminate_tags(atext)

    fout = open(sys.argv[1] + '.txt', 'w', encoding='UTF-8')
    fout.write(ptext)
    fout.close()

if __name__ == '__main__':
    main()
