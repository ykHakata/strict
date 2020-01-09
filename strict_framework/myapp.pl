#!/usr/bin/env perl
use Mojolicious::Lite;
use utf8;
binmode STDOUT,":utf8";
use Time::Piece;
use Readonly;
use Encode;
use HTML::FillInForm;
use FormValidator::Lite;


app->config(hypnotoad => {listen => ['http://*:80']});


FormValidator::Lite->load_constraints(qw/Japanese Email/);

Readonly my $MAIL_UNSENT_0 => 0;
Readonly my $MAIL_SENT_1   => 1;

#sql(teng)と接続
my $teng = do('create-teng-instanceMy.pl')
or die $@;

get '/' => sub {
    my $self = shift;
    
    my $today = localtime;
    
    my $date_today = $today->datetime( T => " ");
    
    $self->stash(
        date_today => $date_today
    );
    
    
    $self->render('home');
};

get 'service' => sub {
  my $self = shift;
  $self->render('service');
};

get 'case' => sub {
  my $self = shift;
  $self->render('case');
};

any 'contact' => sub {
  my $self = shift;
  
  my $message = $self->flash('message');
  
  $self->stash( message => $message );
  
# HTTPメソッド(post)取得
my $method = $self->req->method;

if (uc $method eq "POST") {

    my $validator = FormValidator::Lite->new($self->req);

     $validator->set_message(
        'name.not_null'         => '必ず入力',
        'name.length'           => '30文字以下',
        'read_name.not_null'    => '必ず入力',
        'read_name.length'      => '30文字以下',
        'email.not_null'        => '必ず入力',
        'email.email'           => '形式が違います',
        'email_conf.not_null'   => '必ず入力',
        'email_conf.email'      => '形式が違います',
        'mails.duplication'     => '同じメールアドレスを入力',
        'inquiry.not_null'      => '必ず入力',
        'inquiry.length'        => '200文字以下',
    );
    
    my $res = $validator->check(
        name       => [qw/NOT_NULL/],
        name       => [[qw/LENGTH 1 30/]],
        read_name  => [qw/NOT_NULL/],
        read_name  => [[qw/LENGTH 1 30/]],
        email      => [qw/NOT_NULL EMAIL/],
        email_conf => [qw/NOT_NULL EMAIL/],
        {mails     => [qw/email email_conf/]} => ['DUPLICATION'] ,
        inquiry    => [qw/NOT_NULL/],
        inquiry    => [[qw/LENGTH 1 200/]],
    );
    #バリデ不合格->フィルインフォーム
    if ($validator->has_error) {
        my @name_vali       = $validator->get_error_messages_from_param('name');
        my @read_name_vali  = $validator->get_error_messages_from_param('read_name');
        my @email_vali      = $validator->get_error_messages_from_param('email');
        my @email_conf_vali = $validator->get_error_messages_from_param('email_conf');
        my @emails_vali     = $validator->get_error_messages_from_param('mails');
        my @inquiry_vali    = $validator->get_error_messages_from_param('inquiry');

        $self->stash(
            name_vali       => \@name_vali       ,
            read_name_vali  => \@read_name_vali  ,
            email_vali      => \@email_vali      ,
            email_conf_vali => \@email_conf_vali ,
            emails_vali     => \@emails_vali ,
            inquiry_vali    => \@inquiry_vali ,
        );
#        my $html = $self->render_partial()->to_string;
#        my $html = $self->render(data => 'partial')->to_string;
#        my $html = $self->render('contact' , partial => 1);
        my $html = $self->render(partial => 1)->to_string;
        $html = HTML::FillInForm->fill(\$html, $self->req->params,);
#        return $self->render_text($html, format => 'html');
        return $self->render(text => $html , format => 'html');
    }
    #バリデ合格->DB書き込み
    else {
        my $today      = localtime;
        my $date_today = $today->datetime( T => " ");
        
        my $param_ref  = $self->req->params->to_hash; 
        
        my $row = $teng->insert( 'contact' => +{
        #          id        => $id        ,
            name      => $param_ref->{name}      ,
            read_name => $param_ref->{read_name} ,
            email     => $param_ref->{email}     ,
            inquiry   => $param_ref->{inquiry}   ,
            status    => $MAIL_UNSENT_0          ,
            create_on => $date_today             ,
        #          modify_on => $modify_on ,
        });
        $self->flash( message => 'お問い合わせを受け付けました');
        return $self->redirect_to('');
    }
}    
else {}
    $self->render('contact');
};


app->start;
