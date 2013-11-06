package EngDatabase::AD;
use lib './lib/';
use EngDatabase::AdUser;
use base qw/Net::LDAP EngDatabase::AdUser/;
use Net::LDAP::Extra qw(AD);
use strict;
use warnings;

use Exporter qw(import);
my $pwenc = "/usr/local/sbin/pwenc" unless $::pwenc;

our @EXPORT_OK = qw(ad_unbind ad_adduser get_ad_prod ad_finduser);

#my $opt_debug=1;

my $domain_name = "DC=ad,DC=eng,DC=cam,DC=ac,DC=uk";

{
    my $ad;
    my $result;

    sub get_ad_prod {
        unless ( defined $ad ) {
            $ad = Net::LDAP->new( 'ldaps://colada.eng.cam.ac.uk', )
              or die "$@";
        }
        unless ( defined $result ) {
            $result = $ad->bind( 'AD\gmj33', password => 'stihl123' );
            if ( $result->code ) {
                warn "Can't connect:", $result->error;
            }
        }
        print "Debugging\n" if $::opt_debug;
        $ad->debug(12) if $::opt_debug;
        return $ad;
    }

    sub ad_unbind {
        $ad->unbind;
    }
}

sub decode_password {
    my $crypt = shift;
    chomp( my $password = `$::pwenc -d $crypt` );
    return $password;
}

sub ad_finduser {
    my $username = shift;
    my $ad       = &get_ad_prod();

    my $result = $ad->search(    # perform a search
        base   => $domain_name,
        filter => "(&(objectClass=person)(sAMAccountName=$username))",
    );
    die "More than on AD entry for $username\n" if $result->count() > 1;
    return if $result->count() == 0;
    return $result->shift_entry();
}

sub ad_deluser {
    my ( $ad, $result ) = &get_ad_prod();
    my $username = shift;
    my $dn         = "CN=$username,CN=Users,$domain_name";
    my $email      = $username . "@" . "ad.eng.cam.ac.uk";
    $result = $ad->delete($dn);
    if ( $result->code ) {
        warn "Failed to delete user $username: ", $result->error;
    }
    else {
        print "Deleted user $username\n" if $::opt_debug;
    }
}

sub ad_set_gecos {
    my $self = shift;
    my $gecos = @_;
    $self->replace( displayName => $gecos );
    return $self;
}



sub ad_update_or_create_user {
    my ( $ad, $result ) = &get_ad_prod();
    my $username = shift;
    my $dn         = "CN=$username,CN=Users,$domain_name";
    my $self = shift;
    my ( $username, $password, $gecos ) = @_;
    if ( my $user_obj = &ad_find_user($username) ) {
        print "Found user\n";
        &ad_update_user($user_obj, $password, $gecos);

        if ( $result->code ) {
            warn "failed to update entry: ", $result->error;
        }
        else {
            print "Added user $username to AD\n" if $::opt_debug;
        }

        if ( $password && $password ne "" && $ad->is_AD || $ad->is_ADAM ) {
            $ad->reset_ADpassword( $dn, $password );
            $result = $ad->modify(
                $dn,
                replace => {
                    userAccountControl =>
                      512,    # ahhh finally we get to enable the account!!!
                }
            );
        }
        if ( $result->code ) {
            warn "Failed to set the password for $username\n";
        }
        else {
            print "Changed password for $username in AD\n" if $::opt_debug;
        }
    }
}

    sub ad_adduser {
        my ( $ad, $result ) = &get_ad_prod();
        my ( $username, $password, $gecos ) = @_;
        my $email = $username . "@" . "ad.eng.cam.ac.uk";
        my $dn    = "CN=$username,CN=Users,$domain_name";
        if ( $result = $ad->search($dn) ) {
            print "$username is already in AD!!\n";
            print $result->count();
        }
        $result = $ad->delete($dn);
        if ( $result->code ) {
            warn "Failed to delete user $username: ", $result->error;
        }
        $result = $ad->add(
            $dn,
            attrs => [
                objectClass =>
                  [ "top", "person", "organizationalPerson", "user" ],
                cn                => $username,
                sn                => 'User',
                distinguishedName => $dn,
                sAMAccountName    => $username,
                displayName       => $gecos,
                userPrincipalName => $email,
                objectCategory =>
"CN=Person,CN=Schema,CN=Configuration,dc=ad,dc=eng,dc=cam,dc=ac,dc=uk",
                userAccountControl =>
                  2    #disable the regular user, use 512 to enable
            ]
        );
        if ( $result->code ) {
            warn "failed to add entry: ", $result->error;
        }
        else {
            print "Added user $username to AD\n" if $::opt_debug;
        }

        if ( $password && $password ne "" && $ad->is_AD || $ad->is_ADAM ) {
            chomp( $password = &decode_password($password) );
            $password = "password123";
            $ad->reset_ADpassword( $dn, $password );
            $result = $ad->modify(
                $dn,
                replace => {
                    userAccountControl =>
                      512,    # ahhh finally we get to enable the account!!!
                }
            );
        }
        if ( $result->code ) {
            warn "Failed to set the password for $username\n";
        }
        else {
            print "Changed password for $username in AD\n" if $::opt_debug;
        }
    }

    1;
## Please see file perltidy.ERR
