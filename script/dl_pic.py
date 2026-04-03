#
# Naro2mobi外部ダウンローダーでダウンロードした青空文庫形式準拠テキストに
# に含まれる［リンクの図］をダウンロードしてその青空文庫タグをローカルの
# 画像ファイル名に置換する
#
# 2026/04/03 挿絵がない場合はなにもしないようにした
# 2025/05/12 重複画像のダウンロードをスキップするようにした
# 2025/04/20 ハーメルンの挿絵に対応した
#
import sys
import os
import shutil
import re
import requests # ない場合はpip install requestsでインストールする

#グローバル変数
pic_n = 1
dl_n = 1

# タイトル名をファイル名として使用出来るかどうかチェックし、使用不可文字が
# あれば修正する('-'に置き換える)
def path_filter(title: str) -> str:
    title = re.sub(r'[\\*?+.\t/:;,.| ]', '-', title)
    if len(title) > 32:
        title = title[:32]
    return title

# URLから画像ファイルをダウンロードして保存する
def get_pic(url, basedir, file_name: str) -> str:
    global dl_n

    # なろうの挿絵URLはhttps:が省略されているので補完する
    # ハーメルンではhttp:もあったりするのでチェックする
    if (url.find('http:') != 0) and (url.find('https:') !=0):
        url = 'https:' + url
    # http:をhttps:に書き換える(ハーメルン対応))
    url = re.sub('http:', 'https:', url)
    # ドメインがsyosetuであればimg.syosetuに書き換える(ハーメルン対応)
    url = re.sub('//syosetu', '//img.syosetu', url)
    response = requests.get(url)
    # リダイレクトされているかどうかチェックする
    pname = ''
    rurl = response.url
    if rurl != url:
        # 画像ファイル名の末尾が.580.jpgの場合はそれを削除してフルサイズファイル名にする
        rurl = re.sub('.580.jpg', '', rurl)
        response = requests.get(rurl)
        pname = re.sub('http.*/', '', rurl)
    fname = ''
    pict  = response.content
    if pname != '':
        fname = basedir + '\\' + pname
    else:
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
            fname = basedir + '\\' + file_name + ext
    # 画像ファイルを所得出来なければファイル名なしで終了する
    if fname == '':
        return ''

    # 画像ファイルが存在しなければ保存する
    if not os.path.isfile(fname):
        with open(fname, "wb") as picfile:
            picfile.write(pict)
            # ファイルがあるかチェックする
            if not os.path.isfile(fname):
                fname = ''
            else:
                dl_n += 1
    # ファイル名だけにする
    fname = os.path.basename(fname)
    # 画像ファイルを保存出来たらそのファイル名を失敗したらnullを返す
    return fname

def url_to_pic(atxtfile: str):
    global pic_n

    toutnm = os.path.basename(atxtfile) # ファイル名を保存
    crt_n = 1
    sys.stdout.write('リンクの図を検索中...\n')
    # 入力ファイル名のフォルダを準備する
    fdn = os.path.splitext(atxtfile)[0] # フォルダ名を準備
    if not os.path.isdir(fdn):
        os.mkdir(fdn)
    # 既にフォルダが存在すればフォルダ内のファイルを全て削除する
    else:
        sys.stdout.write('既にフォルダが存在するためフォルダ内のファイルを全て削除します.\n')
        shutil.rmtree(fdn)
        os.mkdir(fdn)
    # 入力ファイルと出力ファイルを開く
    fin = open(atxtfile, 'r', encoding='UTF-8')
    fout = open(fdn + '\\' + toutnm, 'w', encoding='UTF-8')
    for inline in fin.readlines():
        outline = inline
        purl = re.search('［＃リンクの図（.*?）入る］', inline)
        if purl:
            url = re.sub('［＃リンクの図（', '', purl.group(0))
            url = re.sub('）入る］', '', url)
            pnum = '{:04}'.format(pic_n)
            pfile = get_pic(url, fdn, pnum)
            if pfile != '':
                outline = re.sub('［＃リンクの図（.*?）入る］', '［＃挿絵' + pnum + '（' + pfile + '）入る］', outline)
                if dl_n > crt_n:
                    sys.stdout.write('\r' + str(crt_n) + ' 個の挿絵画像をダウンロードしました.\n')
                    crt_n += 1
                pic_n += 1

        fout.writelines(outline)
    fin.close()
    fout.close()
    if pic_n == 1:
        sys.stdout.write('\nリンクの図が見つかりませんでした.\n')
        # 保存したテキストファイルをフォルダ毎削除する
        shutil.rmtree(fdn)
    skip_n = pic_n - dl_n
    if skip_n > 0:
        sys.stdout.write('\n' + str(skip_n) + '個の挿絵画像が重複していたためスキップしました.')
    sys.stdout.write('\n完了しました.\n')

def main():
    if len(sys.argv) == 1:
        print('Usage:')
        print('  python dl_pic.py 青空文庫形式準拠テキストファイル名')
        quit()
    # 入力ファイル名のフォルダを準備する
    url_to_pic(sys.argv[1])

if __name__ == '__main__':
    main()
