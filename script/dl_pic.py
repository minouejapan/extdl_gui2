#
# Naro2mobi外部ダウンローダーでダウンロードした青空文庫形式準拠テキストに
# に含まれる［リンクの図］をダウンロードしてその青空文庫タグをローカルの
# 画像ファイル名に置換する
#
import sys
import os
import re
import requests # ない場合はpip install requestsでインストールする

#グローバル変数
pic_n = 1

# タイトル名をファイル名として使用出来るかどうかチェックし、使用不可文字が
# あれば修正する('-'に置き換える)
def path_filter(title: str) -> str:
    title = re.sub(r'[\\*?+.\t/:;,.| ]', '-', title)
    if len(title) > 32:
        title = title[:32]
    return title

# URLから画像ファイルをダウンロードして保存する
def get_pic(url, file_name: str) -> str:
    # なろうの挿絵URLはhttpd:が省略されているので補完する
    if url.find('https:') != 0:
        url = 'https:' + url
    response = requests.get(url)
    pict  = response.content
    ptype = response.headers['Content-Type']
    if ptype == 'image/gif':
        ext = '.gif'
    elif ptype == 'image/jpeg':
        ext = '.jpg'
    elif ptype == 'image/png':
        ext = '.png'
    elif (ptype == 'image/bmp') or (ptype == 'image/x-ms-bmp'):
        ext = '.bmp'
    else:
        ext = ''
    if ext != '':
        fname = file_name + ext
        # 画像ファイルが既に存在すれば削除する
        if os.path.isfile(fname):
            os.remove(fname)
        with open(fname, "wb") as picfile:
            picfile.write(pict)
            # ファイルがあるかチェックする
            if not os.path.isfile(fname):
                fname = ''
    else:
        fname = ''
    # ファイル名だけにする
    fname = os.path.basename(fname)
    # 画像ファイルを保存出来たらそのファイル名を失敗したらnullを返す
    return fname

def url_to_pic(atxtfile: str):
    global pic_n

    sys.stdout.write('リンクの図を検索中...\n')
    # 入力ファイル名のフォルダを準備する
    fdn = path_filter(os.path.splitext(atxtfile)[0])
    if not os.path.isdir(fdn):
        os.mkdir(fdn)
    fin = open(atxtfile, 'r', encoding='UTF-8')
    fout = open(fdn + '\\' + atxtfile, 'w', encoding='UTF-8')
    for inline in fin.readlines():
        outline = inline
        purl = re.search('［＃リンクの図（.*?）入る］', inline)
        if purl:
            url = re.sub('［＃リンクの図（', '', purl.group(0))
            url = re.sub('）入る］', '', url)
            sys.stdout.write('\r' + str(pic_n) + ' 個の挿絵画像をダウンロードしました.')
            pnum = '{:03}'.format(pic_n)
            pic_n += 1
            pfile = get_pic(url, fdn + '\\' + pnum)
            if pfile != '':
                outline = re.sub('［＃リンクの図（.*?）入る］', '［＃挿絵' + pnum + '（' + pfile + '）入る］', outline)
        fout.writelines(outline)
    if pic_n == 1:
        sys.stdout.write('\nリンクの図が見つかりませんでした.\n')
    sys.stdout.write('\n完了しました.\n')

def main():
    if len(sys.argv) == 1:
        print('Usage:')
        print('  python download_pic.py 青空文庫形式準拠テキストファイル名')
        quit()
    # 入力ファイル名のフォルダを準備する
    url_to_pic(sys.argv[1])

if __name__ == '__main__':
    main()
