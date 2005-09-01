package Kwiki::UserName::Auth;
use Kwiki::UserName -Base;
use mixin 'Kwiki::Installer';
use DBI;

our $VERSION = '0.01';

const cgi_class => 'Kwiki::UserName::Auth::CGI';
const css_file  => 'user_name_auth.css';

sub register {
    my $registry = shift;
    $registry->add(preload => 'user_name');
    $registry->add(action => 'user_name_setup');
    $registry->add(action => 'user_name_create');
    $registry->add(action => 'user_name_login');
    $registry->add(action => 'user_name_logout');
    $registry->add(action => 'user_name_mail_password');
}

## Override Plugin.pm's render_screen()
sub render_screen {
    $self->template_process($self->screen_template, @_);
}

sub user_name_setup {
    $self->render_screen(content_pane => 'user_name_setup.html');
}

sub user_name_login {
    if(my $user = $self->db_verify($self->cgi->user_name_email, $self->cgi->user_name_password)) {
	$self->hub->cookie->write('users_auth' => {name => $user });
	return $self->render_screen(content_pane => 'user_name_login_success.html')
    }
    $self->render_screen(content_pane => 'user_name_login_failed.html');
}

sub user_name_logout {
    $self->hub->cookie->write('users_auth' => {}, { -expires => '-3d' });
    $self->render_screen(content_pane => 'user_name_logout_success.html');
}

sub user_name_create {
    if($self->cgi->user_name_password) {
	if($self->cgi->user_name_password_verify eq $self->cgi->user_name_password) {
	    if($self->db_add($self->cgi->all)) {
		$self->render_screen(content_pane => 'user_name_register_ok.html');
	    } else {
		$self->render_screen(content_pane => 'user_name_duplicate.html');
	    }
	} else {
	    $self->render_screen(content_pane => 'user_name_password_not_match.html');
	}
    } else {
	$self->render_screen(content_pane => 'user_name_registration_form.html');
    }
}

sub user_name_mail_password {
}

# DB subs


sub dbinit {
    my $db = shift;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","",
			   { RaiseError => 1, AutoCommit => 1 });
    $dbh->do('CREATE TABLE user_name (displayname,email,password)');
    $dbh->disconnect;
}

sub dbpath {
    my $path = $self->plugin_directory;
    my $filename =  io->catfile($path,"user_name.sqlt")->name;
    $self->dbinit($filename) unless -f $filename;
    return $filename;
}

sub db_connect {
    my $db  = $self->dbpath;
    DBI->connect("dbi:SQLite:dbname=$db","","",
                 { RaiseError => 1, AutoCommit => 1 });
}

sub db_verify {
    my ($email,$password) = @_;
    my $dbh = $self->db_connect;
    my $user = $dbh->selectrow_hashref('SELECT displayname,email from user_name WHERE email=? AND password=?',undef,$email,$password);
    $dbh->disconnect;
    if($user) {
        return $user->{displayname} unless $user->{displayname} =~ /^\s*$/;
        $email =~ s/(.+?)@.*$/$1/;
        return $email;
    }
    return;
}

sub db_add {
    my %vars = @_;
    return 0 if $self->db_exists($vars{user_name_email});
    my $dbh = $self->db_connect;
    my $sth = $dbh->prepare('INSERT INTO user_name values(?,?,?)');
    $sth->execute(@vars{qw(user_name_display_name user_name_email user_name_password )});
    $sth->finish;
    $dbh->disconnect;
    return 1;
}

sub db_exists {
    my $email = shift;
    my $dbh = $self->db_connect;
    my $r = $dbh->selectrow_arrayref('SELECT email FROM user_name WHERE email=?',undef,$email);
    $dbh->disconnect;
    return $r;
}

package Kwiki::UserName::Auth::CGI;
use base 'Kwiki::CGI';

cgi user_name_submit          => -utf8;
cgi user_name_display_name    => -utf8;
cgi user_name_email           => -utf8;
cgi user_name_password        => -utf8;
cgi user_name_password_verify => -utf8;

package Kwiki::UserName::Auth;

__DATA__

=head1 NAME

  Kwiki::UserName::Auth - Online user regsitration plugin for Kwiki

=head1 SYNOPSIS

  # Replce other UserName plugin with Kwiki::UserName::Auth
  % vim plugins
  # Use Kwiki::Users::Auth as a alternative of Kwiki::Users
  % echo "users_class: Kwiki::Users::Auth" >> config.yaml
  % kwiki -update

=head1 DESCRIPTION

For people who want to have a little control over their Kwiki site visitors,
this is the plugin for them. It provides a registration process for users,
instead of just a preference field in the preferences page. User are asked
to give their email address and password to login.

It only works with L<Kwiki::Users::Auth>, which could read proper
account information from cookie after user login. So you must edit
your config.yaml and put this line in:

  users_class: Kwiki::Users::Auth

Please remove or comment any other lines if they also set users_class.

Upon registration, user are asked to fill 3 fields: email, display name, and
password. email and password are required as they are used to identify a
particular user. The display name is optional, if it's not given, it would be
the account name (anything before '@') in the email address..

=head1 CAUTION

This plugin is still in early alpha. Which means it's still too early to
be deployed to any production site. Use at your on risk, and give me help
if you want.

So far the password are stored in clear text.

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>


=cut
__template/tt2/user_name_title.html__
<div id="user_name_title">
<em>(You are 
<a href="[% script_name %]?action=user_name_setup">
[%- hub.users.current.name || 'an UnknownUser' -%]
</a>)
</em>
</div>

__template/tt2/user_name_setup.html__
[% IF hub.users.current.name %]
[% INCLUDE user_name_logout_form.html %]
[% ELSE %]
[% INCLUDE user_name_login_form.html %]
[% INCLUDE user_name_registration_form.html %]
[% INCLUDE user_name_mail_password_form.html %]
[% END %]
__template/tt2/user_name_mail_password_form.html__
[% IF 0 %]
<form action="[% script_name %]" method="post" id="user_name_mail_password" class="user_name">
<input type="hidden" name="action" value="user_name_mail_password" />
<fieldset>
<legend>Password Recovery</legend>
<p>
If you forgot your passowrd, give us your email address to recover it.
</p>
<label>Email</label>
<input type="text" name="user_name_email" />
<hr />
<input type="submit" name="user_name_submit" value="Recover" />
</fieldset>
</form>
[% END %]
__template/tt2/user_name_logout_form.html__
<p>You're now logined as [% hub.users.current.name %]</p>

You could <a href="[% script_name %]?action=user_name_logout">Logout</a>.
__template/tt2/user_name_login_success.html__
<h1>Logined</h1>
__template/tt2/user_name_logout_success.html__
<h1>You just logout</h1>
__template/tt2/user_name_login_failed.html__
<h1>Email or Passowrd Error</h1>
[% INCLUDE user_name_login_form.html %]
__template/tt2/user_name_login_form.html__
<form action="[% script_name %]" method="post" id="user_name_login" class="user_name">
<input type="hidden" name="action" value="user_name_login" />
<fieldset>
<legend>Login</legend>

<label>Email</label>
<input type="text" name="user_name_email" />

<label>Password</label>
<input type="password" name="user_name_password" />
<hr />
<input type="submit" name="user_name_submit" value="Login" />
</fieldset>
</form>
__template/tt2/user_name_registration_form.html__
<form action="[% script_name %]" method="post" id="user_name_create" class="user_name">
<input type="hidden" name="action" value="user_name_create" />
<fieldset>
<legend>Registration</legend>

<label>Email</label>
<input type="text" name="user_name_email" />

<label>Display Name</label>
<input type="text" name="user_name_display_name" />

<label>Password</label>
<input type="password" name="user_name_password" />

<label>Password(Verify)</label>
<input type="password" name="user_name_password_verify" />

<hr />
<input type="submit" name="user_name_submit" value="Register" />
</fieldset>
</form>
__template/tt2/user_name_register_ok.html__
<h1>Your account is added. Please Login:</h1>
[% INCLUDE user_name_login_form.html %]
__template/tt2/user_name_duplicate.html__
<h1>This Email is already used</h1>
[% INCLUDE user_name_registration_form.html %]
__template/tt2/user_name_password_not_match.html__
<h1>Your Password doesn't match</h1>
[% INCLUDE user_name_registration_form.html %]
__css/user_name_auth.css__

div#user_name_title {
    font-size: small;
    float: right;
}

form.user_name label { display:block; line-height: 1.5em;}
form.user_name label:after { content: ': ';}
form.user_name input { margin-left: 2em; margin-bottom: 1em;}
