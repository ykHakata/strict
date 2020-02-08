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
