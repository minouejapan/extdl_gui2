# このperlスクリプトは以下のサイトでptext.rbから自動変換して編集したものです
# converted from ruby to perl by https://codingfleet.com/code-converter/ruby/perl/
# Naro2mobi外部ダウンローダーでダウンロードした青空文庫形式準拠テキストを
# プレーンテキストに変換する
#
use strict;
use warnings;
use utf8;

sub eliminate_tags {
    my ($str) = @_;
    my $tmp = $str;

    $tmp =~ s/［＃.*?］//g;
    $tmp =~ s/［＃.*?（//g;
    $tmp =~ s/）入る］//g;
    $tmp =~ s/｜//g;
    $tmp =~ s/《/（/g;
    $tmp =~ s/》/）/g;
    # エンコードされた青空文庫特殊文字をデコードする
    $tmp =~ s/※［＃始め二重山括弧、1-1-52］/《/g;
    $tmp =~ s/※［＃終わり二重山括弧、1-1-53］/》/g;
    $tmp =~ s/※［＃縦線、1-1-35］/｜/g;

    return $tmp;
}

if (@ARGV == 0) {
    print "Usage:\n";
    print "  perl ptext.pl 青空文庫形式準拠テキストファイル名\n";
    exit 1;
}

my $infile  = $ARGV[0];
my $outfile = $infile . '.txt';

open my $fin, '<:encoding(UTF-8)', $infile
  or die "Cannot open '$infile' for reading: $!\n";
local $/ = undef;
my $atext = <$fin>;
close $fin;

my $ptext = eliminate_tags($atext);

open my $fout, '>:encoding(UTF-8)', $outfile
  or die "Cannot open '$outfile' for writing: $!\n";
print $fout $ptext;
close $fout;

