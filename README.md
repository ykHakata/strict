# NAME

strict - IT企業サイトの試作

# SYNOPSIS

# SETUP

```sh
(perl 準備)
$ cd ~/.plenv/ && git pull
$ cd ~/.plenv/plugins/perl-build/ && git pull
$ plenv install 5.30.0
$ plenv rehash
$ plenv global 5.30.0
$ plenv install-cpanm
$ cpanm Carton

$ cd ~/github/strict/

(Perl のバージョンを固定 Mojolicious をインストール)
$ echo '5.30.0' > .perl-version;
$ echo "requires 'Mojolicious', '8.29';" >> cpanfile;
$ carton install

(雛形作成、パーミッションが 0744 の実行ファイルがつくられる)
$ carton exec -- mojo generate lite_app strict.pl

(git設定)
$ echo 'local/' >> .gitignore;
$ echo '.DS_Store' >> .gitignore;

(起動テスト)
$ carton exec -- morbo strict.pl

(終了は control + c)
```

# SEE ALSO
