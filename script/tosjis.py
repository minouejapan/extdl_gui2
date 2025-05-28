#
# Shift-JISで保存する
#
import sys
import codecs
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
        print('  python tosjis.py 入力テキストファイル名')
        quit()

    with codecs.open(sys.argv[1], 'r', encoding='utf_8_sig') as utf8_file:
        title = str.strip(utf8_file.readline())
        fname = path_filter(title) + '(sjis).txt'
        # errors='replace'オプションを付けることでshift-jisにない文字が現れた場合
        # 他の文字(おそらく近似した文字?)に自動置換する
        with codecs.open(fname, 'w', encoding='shift_jis', errors='replace') as sjis_file:
            sjis_file.writelines(title + '\n')
            for inline in utf8_file.readlines():
                sjis_file.writelines(inline)
            utf8_file.close()
        sjis_file.close()
    print(fname + 'に保存しました.\n')


if __name__ == '__main__':
    main()
