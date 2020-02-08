use strict;
use warnings;
use utf8;
use Time::Piece;
use Readonly;
use Email::MIME;
use Email::Sender::Simple 'sendmail';
use Email::Sender::Transport::SMTP::TLS;
use Try::Tiny;
use lib '.';
Readonly my $SECONDS_3          => q{ 3 * 1};
Readonly my $SECONDS_5          => q{ 5 * 1};
Readonly my $SECONDS_10         => q{10 * 1};
Readonly my $SECONDS_30         => q{30 * 1};
Readonly my $SECONDS_60         => q{60 * 1};
Readonly my $MAIL_UNSENT_0      => 0;
Readonly my $MAIL_SENT_1        => 1;
Readonly my $RECEPTION_0        => 0;
Readonly my $STRICT_FROM_MAIL   => $ENV{STRICT_FROM_MAIL};
Readonly my $STRICT_ADMIN_MAIL  => $ENV{STRICT_ADMIN_MAIL};
Readonly my $STRICT_GOOGLE_USER => $ENV{STRICT_GOOGLE_USER};
Readonly my $STRICT_GOOGLE_PASS => $ENV{STRICT_GOOGLE_PASS};

#sql(teng)と接続
my $teng = do('create-teng-instanceMy.pl')
    or die $@;

# 始まりの時刻
my $now           = localtime;
my $start_time    = localtime;
my $seconds_after = $start_time + $SECONDS_10;

# タイトルの無名サブルーチン
my $title_parts_ref = sub {
    my ($select_title) = @_;
    my $today          = localtime;
    my $common_title   = q{のお知らせ【}
        . $today->datetime( date => q{-}, T => q{ } ) . q{】};
    my $entry_comp_title
        = '[strict]お問い合わせ受付完了' . $common_title;
    my $title
        = ( $select_title eq 0 )
        ? $entry_comp_title
        : 'no_title';
    return $title;
};

# メールのbody部品の変数定義
my $body_parts_ref = sub {
    my ( $contact_id, $select_body ) = @_;
    my $contact_ref  = $teng->single( 'contact', +{ id => $contact_id } );
    my $contact_name = $contact_ref->name;
    my $contact_read_name = $contact_ref->read_name;
    my $contact_email     = $contact_ref->email;
    my $contact_inquiry   = $contact_ref->inquiry;

    # ヘッダー部分
    my $header_body = <<EOD;
　　$contact_name ( $contact_read_name ) 様
---------------------------------------------------------------------

この度は、strictにお問い合わせ頂き、誠にありがとうございます。
後ほど担当者より回答のメールが送られて参りますのでしばらくお待ちください。

今回のお問い合わせ内容は下記の通りです。

EOD

    my $entry_message = <<EOD;
お問い合わせ内容----------

$contact_inquiry

---------------------------------------------------------------------
EOD

    # フッター部分
    my $footer_body = <<EOD;
このメールに身に覚えがない場合や、上記内容に間違いがある場合、
ご不明な点がありましたら <strictquery\@gmail.com> までご連絡ください。
---------------------------------------------------------------------

strictに対する疑問・質問などにすばやく対応・解決します！
お気軽にお問い合わせください。

　[ strict お問い合わせ ]
　strictquery\@gmail.com

---------------------------------------------------------------------
EOD

    my $entry_comp_body = $header_body . $entry_message . $footer_body;
    my $body
        = ( $select_body eq 0 )
        ? $entry_comp_body
        : 'no_body';
    return $body;

};

#type_mail ->0 問合せ
#status    ->0 メール未送信　->1 メール送信済
my $transmission_mail = sub {
    my ($contact_id) = @_;
    my $contact_ref = $teng->single( 'contact', +{ id => $contact_id } );

    my $type_mail    = $RECEPTION_0;
    my $admin_mail   = $STRICT_ADMIN_MAIL;
    my $general_mail = $contact_ref->email;

    # メール作成
    my $subject = $title_parts_ref->($type_mail);
    my $body    = $body_parts_ref->( $contact_id, $type_mail );
    my $email   = Email::MIME->create(
        header => [
            From    => $STRICT_FROM_MAIL,    # 送信元
            To      => $admin_mail,          # 送信先
            To      => $general_mail,        # 送信先
            Subject => $subject,             # 件名
        ],
        body       => $body,                 # 本文
        attributes => {
            content_type => 'text/plain',
            charset      => 'UTF-8',
            encoding     => '7bit',
        },
    );

    # SMTP接続設定
    #gmail
    my $transport = Email::Sender::Transport::SMTP::TLS->new(
        {   host     => 'smtp.gmail.com',
            port     => 587,
            username => $STRICT_GOOGLE_USER,
            password => $STRICT_GOOGLE_PASS,
        }
    );

    # メール送信
    try {
        sendmail( $email, { 'transport' => $transport } );
    }
    catch {
        my $e = shift;
        die "Error: $e";
    };

    # ステータスを送信済に->1
    my $today     = localtime;
    my $modify_on = $today->datetime( date => q{-}, T => q{ } );
    my $count     = $teng->update(
        'contact' => {
            'status'    => $MAIL_SENT_1,
            'modify_on' => $modify_on,
        },
        { 'id' => $contact_id, }
    );
};

while (1) {
    my $newest_time = localtime;
    if ( $newest_time eq $seconds_after ) {
        my @contacts = $teng->search_named(
            q{select * from contact where status = '0' order by id asc;});
        if (@contacts) {
            for my $contact_ref (@contacts) {
                my $contact_id = $contact_ref->id;
                $transmission_mail->($contact_id);
            }
        }
        else { }
        $newest_time = localtime;
        print "mail comp " . $newest_time->datetime . "\n";
        $seconds_after = $newest_time + $SECONDS_30;
    }
    else { }
}
