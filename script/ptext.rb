#
# Naro2mobi外部ダウンローダーでダウンロードした青空文庫形式準拠テキストを
# プレーンテキストに変換する
#
def eliminate_tags(str)
	tmpstr = str
  tmpstr = tmpstr.gsub(/［＃.*?］/, '')
  tmpstr = tmpstr.gsub(/［＃.*?（/, '')
  tmpstr = tmpstr.gsub('）入る］', '')
  tmpstr = tmpstr.gsub('｜', '')
  tmpstr = tmpstr.gsub('《', '（')
  tmpstr = tmpstr.gsub('》', '）')
  # エンコードされた青空文庫特殊文字をデコードする
  tmpstr = tmpstr.gsub('※［＃始め二重山括弧、1-1-52］', '《')
  tmpstr = tmpstr.gsub('※［＃終わり二重山括弧、1-1-53］', '》')
  tmpstr = tmpstr.gsub('※［＃縦線、1-1-35］', '｜')
	return tmpstr
end

ptext = ''

if ARGV.length == 0
	puts('Usage:')
  puts('  ruby ptext.rb 青空文庫形式準拠テキストファイル名')
  exit
end

File.open(ARGV[0], "r:UTF-8") do |fin|
  atext = fin.read
	ptext = eliminate_tags(atext)
	fin.close
end

File.open(ARGV[0] + '.txt', "w:UTF-8") do |fout|
  fout.write(ptext)
	fout.close
end

