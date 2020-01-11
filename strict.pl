#!/usr/bin/env perl
use Mojolicious::Lite;
use Time::Piece;
use HTML::FillInForm;
use FormValidator::Lite;
use Mojo::Util qw{dumper};
FormValidator::Lite->load_constraints(qw/Email/);

get '/' => sub {
    my $c          = shift;
    my $today      = localtime;
    my $date_today = $today->datetime( T => " " );
    $c->stash( date_today => $date_today );
    $c->render('home');
    return;
};

get 'service' => sub {
    my $c = shift;
    $c->render('service');
    return;
};

get 'case' => sub {
    my $c = shift;
    $c->render('case');
    return;
};

sub _validator_set {
    my $req       = shift;
    my $validator = FormValidator::Lite->new($req);
    $validator->set_message(
        'name.not_null'       => '必ず入力',
        'name.length'         => '30文字以下',
        'read_name.not_null'  => '必ず入力',
        'read_name.length'    => '30文字以下',
        'email.not_null'      => '必ず入力',
        'email.email'         => '形式が違います',
        'email_conf.not_null' => '必ず入力',
        'email_conf.email'    => '形式が違います',
        'mails.duplication'   => '同じメールアドレスを入力',
        'inquiry.not_null'    => '必ず入力',
        'inquiry.length'      => '200文字以下',
    );
    $validator->check(
        name                                => [qw/NOT_NULL/],
        name                                => [ [qw/LENGTH 1 30/] ],
        read_name                           => [qw/NOT_NULL/],
        read_name                           => [ [qw/LENGTH 1 30/] ],
        email                               => [qw/NOT_NULL EMAIL/],
        email_conf                          => [qw/NOT_NULL EMAIL/],
        { mails => [qw/email email_conf/] } => ['DUPLICATION'],
        inquiry                             => [qw/NOT_NULL/],
        inquiry                             => [ [qw/LENGTH 1 200/] ],
    );
    return $validator;
}

# 入力フォーム表示
get 'contact' => sub {
    my $c = shift;
    $c->render('contact');
    return;
};

# 入力フォーム送信
post 'contact' => sub {
    my $c = shift;

    my $validator = _validator_set( $c->req );
    if ( $validator->has_error ) {
        my @name_vali = $validator->get_error_messages_from_param('name');
        my @read_name_vali
            = $validator->get_error_messages_from_param('read_name');
        my @email_vali = $validator->get_error_messages_from_param('email');
        my @email_conf_vali
            = $validator->get_error_messages_from_param('email_conf');
        my @emails_vali = $validator->get_error_messages_from_param('mails');
        my @inquiry_vali
            = $validator->get_error_messages_from_param('inquiry');
        $c->stash(
            name_vali       => \@name_vali,
            read_name_vali  => \@read_name_vali,
            email_vali      => \@email_vali,
            email_conf_vali => \@email_conf_vali,
            emails_vali     => \@emails_vali,
            inquiry_vali    => \@inquiry_vali,
        );
        my $html = $c->render_to_string->to_string;
        my $output
            = HTML::FillInForm->fill( \$html, $c->req->params->to_hash );
        $c->render( text => $output, format => 'html' );
        return;
    }

    my $today      = localtime;
    my $date_today = $today->datetime( T => " " );

    # my $param_ref  = $c->req->params->to_hash;
    # my $row        = $teng->insert(
    #     'contact' => +{
    #         name      => $param_ref->{name},
    #         read_name => $param_ref->{read_name},
    #         email     => $param_ref->{email},
    #         inquiry   => $param_ref->{inquiry},
    #         status    => $MAIL_UNSENT_0,
    #         create_on => $date_today,
    #     }
    # );
    $c->flash( message => 'お問い合わせを受け付けました' );
    $c->redirect_to('/contact');
    return;
};

app->start;
