package Kwiki::Users::Auth;
use Kwiki::Users -Base;
our $VERSION = 0.01;

const class_id => 'users';
const class_title => 'Kwiki users registered online';
const user_class => 'Kwiki::User::Auth';

sub current {
    return $self->{current} = shift if @_;
    return $self->{current} if defined $self->{current};
    $self->{current} = $self->new_user();
}

sub new_user {
    $self->user_class->new();
}

package Kwiki::User::Auth;
use base 'Kwiki::User';

field 'name' => '';

sub set_user_name {
    return unless $self->is_in_cgi;
    my $name = '';
    my $cookie = $self->hub->cookie->jar->{users_auth};
    $cookie && $cookie->{name} or return;
    $self->name($cookie->{name});
}

package Kwiki::Users::Auth;

=head1 NAME

Kwiki::Users::Auth - Properl 'users_class' that works with Kwiki::UserName::Auth

=head1 DESCRIPTION

Please read the documentation in L<Kwiki::UserName::Auth>.

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

