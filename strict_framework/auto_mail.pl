use strict;
use Time::Piece;
use Readonly;
use Encode;
use utf8;
binmode STDOUT,":utf8";

Readonly my $SECONDS_3  => q{ 3 * 1};
Readonly my $SECONDS_5  => q{ 5 * 1};
Readonly my $SECONDS_10 => q{10 * 1};
Readonly my $SECONDS_30 => q{30 * 1};
Readonly my $SECONDS_60 => q{60 * 1};

# Readonly my $STATUS_MAIL_1 => 'entry_comp';
# Readonly my $STATUS_MAIL_2 => 'res_comp';
# Readonly my $STATUS_MAIL_3 => 'res_cancel';
# Readonly my $STATUS_MAIL_4 => 'res_change';

Readonly my $MAIL_UNSENT_0 => 0;
Readonly my $MAIL_SENT_1   => 1;

Readonly my $RECEPTION_0   => 0;




#sql(teng)と接続
my $teng = do('create-teng-instanceMy.pl')
or die $@;

# 始まりの時刻
my $now = localtime;
#
my $start_time = localtime;
#
my $seconds_after = $start_time + $SECONDS_10;

# タイトルの無名サブルーチン
my $title_parts_ref = sub {
    my ($select_title) = @_;

    my $today = localtime;
    
    my $common_title     = q{のお知らせ【}.$today->datetime(date => q{-}, T => q{ }).q{】};
    
    my $entry_comp_title = '[strict]お問い合わせ受付完了'  . $common_title;
    
#     my $entry_comp_title = '[yoyakku]ID登録完了'     . $common_title;
#     my $res_comp_title   = '[yoyakku]予約完了'       . $common_title;
#     my $res_cancel_title = '[yoyakku]予約キャンセル' . $common_title;
#     my $res_change_title = '[yoyakku]予約変更'       . $common_title;
    
    my $title = ($select_title eq 0) ? $entry_comp_title
#               : ($select_title eq 1) ? $res_comp_title
#               : ($select_title eq 2) ? $res_cancel_title
#               : ($select_title eq 3) ? $res_comp_title
#               : ($select_title eq 4) ? $res_cancel_title
#               : ($select_title eq 5) ? $res_change_title
              :                        'no_title'
              ;
           
    return $title;
};

# ここまで

# メールのbody部品の変数定義
my $body_parts_ref = sub {
    my ($contact_id , $select_body) = @_;
    
    my $contact_ref  = $teng->single('contact', +{id => $contact_id});
    
    my $contact_name      = $contact_ref->name      ;
    my $contact_read_name = $contact_ref->read_name ;
    my $contact_email     = $contact_ref->email     ;
    my $contact_inquiry   = $contact_ref->inquiry   ;
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
    
    my $body  = ($select_body eq 0) ? $entry_comp_body
#               : ($select_body eq 1) ? $res_comp_body
#               : ($select_body eq 2) ? $res_cancel_body
#               : ($select_body eq 3) ? $admin_res_comp_body
#               : ($select_body eq 4) ? $admin_res_cancel_body
#               : ($select_body eq 5) ? $admin_res_change_body
              :                       'no_body'
              ;
              
    return $body;

};
    #type_mail ->0 問合せ
    #status    ->0 メール未送信　->1 メール送信済

my $transmission_mail = sub {

    my ($contact_id) = @_;
    
    my $contact_ref  = $teng->single('contact', +{id => $contact_id});
    
    my $type_mail    = $RECEPTION_0         ;
    my $admin_mail   = 'strictquery@gmail.com';
    my $general_mail = $contact_ref->email  ;

    my $utf8 = find_encoding('utf8');
    # メール作成
    my $subject = $utf8->encode( $title_parts_ref->($type_mail              ) );
    my $body    = $utf8->encode( $body_parts_ref->( $contact_id , $type_mail) );
    
    use Email::MIME;
    my $email = Email::MIME->create(
        header => [
            From    => 'strictquery@gmail.com'    , # 送信元
            To      => $admin_mail   ,    # 送信先
            To      => $general_mail ,    # 送信先
            Subject => $subject,           # 件名
        ],
        body => $body,                     # 本文
        attributes => {
            content_type => 'text/plain',
            charset      => 'UTF-8',
            encoding     => '7bit',
        },
    );
    
    # SMTP接続設定
    #gmail
    use Email::Sender::Transport::SMTP::TLS;
    my $transport = Email::Sender::Transport::SMTP::TLS->new(
        {
            host     => 'smtp.gmail.com',
            port     => 587,
            username => 'strictquery@gmail.com',
            password => 'googlestrict',
        }
    );
    # メール送信
    use Try::Tiny;
    use Email::Sender::Simple 'sendmail';
    try {
        sendmail($email, {'transport' => $transport});
    } catch {
        my $e = shift;
        die "Error: $e";
    };            
    
    # ステータスを送信済に->1
    my $today = localtime;
    
    my $modify_on = $today->datetime(date => q{-}, T => q{ });
    
    my $count = $teng->update('contact' => {
        'status'        => $MAIL_SENT_1,
        'modify_on'     => $modify_on,
    },{
        'id'            => $contact_id, 
    });
    
};


while (1) {
    my $newest_time = localtime;
    
    if ($newest_time eq $seconds_after) {
    
        my @contacts = $teng->search_named(q{
        select * from contact 
        where status = '0' order by id asc;
        });
        
        if (@contacts) {
            for my $contact_ref (@contacts) {
                my $contact_id = $contact_ref->id;
                
                $transmission_mail->($contact_id);
            }
        }
        else {
        }
        $newest_time = localtime;
        
        print "mail comp " . $newest_time->datetime . "\n";
        
        $seconds_after = $newest_time + $SECONDS_30;
        
    }
    else {
    
    }
}







