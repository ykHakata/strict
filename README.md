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
$ echo "requires 'FormValidator::Lite', '0.40';" >> cpanfile;
$ echo "requires 'HTML::FillInForm', '2.21';" >> cpanfile;
$ echo "requires 'Teng', '0.31';" >> cpanfile;
$ echo "requires 'DBD::SQLite', '1.64';" >> cpanfile;
$ echo "requires 'Readonly', '2.05';" >> cpanfile;
$ echo "requires 'Email::MIME', '1.946';" >> cpanfile;
$ echo "requires 'Email::Sender::Transport::SMTP::TLS', '0.16';" >> cpanfile;
$ carton install

(雛形作成、パーミッションが 0744 の実行ファイルがつくられる)
$ carton exec -- mojo generate lite_app strict.pl

(git設定)
$ echo 'local/' >> .gitignore;
$ echo '.DS_Store' >> .gitignore;
$ echo 'db/*.db' >> .gitignore;

(起動テスト)
$ carton exec -- morbo strict.pl

(終了は control + c)
```

```sql
DROP TABLE IF EXISTS contact;
CREATE TABLE contact (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,  -- お問い合わせID (例: 5)
    name        TEXT,                               -- 氏名 (例: '野比のび太')
    read_name   TEXT,                               -- ふりがな (例: 'のびのびた')
    email       TEXT,                               -- メールアドレス (例: 'strictquery@gmail.com')
    inquiry     TEXT,                               -- 問合せ内容 (例: 'サイト作成についての質問')
    status      INTEGER,                            -- ステータス (例: 0: メール送信していない, 1: メール送信済み)
    create_on   TEXT,                               -- 登録日時 (例: '2020-02-08 11:01:27')
    modify_on   TEXT                                -- 修正日時 (例: '2020-02-08 11:01:27')
);
```

```
(sqlite3 のデータベース準備)
$ cd ~/github/strict/db/
$ sqlite3 ./strict.db < ./schema.sql
```

```
(メールの送信スクリプト)
$ cd ~/github/strict/
$ carton exec -- perl auto_mail.pl

(環境変数設定)
$ STRICT_FROM_MAIL=strictquery@gmail.com \
STRICT_ADMIN_MAIL=strictquery@gmail.com \
STRICT_GOOGLE_USER=strictquery@gmail.com \
STRICT_GOOGLE_PASS=googlestrict \
carton exec -- perl auto_mail.pl
```

# MEMO

- 2013/6
    - webサイト製作のスキルアップの目的として自社サイト製作
    - お問い合わせフォームからのメール配信は開発当時はMysqlを活用
    - 開発の経緯の詳細などは`doc`配下の資料参照
- 2020/2
    - 過去の資料を整理のためgithubにアーカイブ作業
    - メール配信のためのdbはsqlite3に変更
    - メール配信までの確認はできるが配信メッセージが途中で切れてしまう問題は未解決

# SEE ALSO
