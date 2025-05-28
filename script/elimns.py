#
# タイトルから連載状況【・・・】を除去する
#
import sys
import re

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
        print('  python elimns.py 入力テキストファイル名')
        quit()

    fin = open(sys.argv[1], 'r', encoding='utf_8_sig')
    title = str.strip(fin.readline());
    if re.match(r'【.*?】', title):
        title = re.sub(r'【.*?】', '', title)
    fname = path_filter(title) + '.txt'
    fout = open(fname, 'w', encoding='UTF-8')
    fout.writelines(title + '\n')
    for inline in fin.readlines():
        fout.writelines(inline)
    fout.close()
    fin.close()
    print('タイトルから連載状況を除去しました.\n')


if __name__ == '__main__':
    main()
