package DBIx::Class::Storage::DBI::SQLite;

use strict;
use warnings;

use base qw/DBIx::Class::Storage::DBI/;
use mro 'c3';

use DBIx::Class::_Util 'modver_gt_or_eq';
use DBIx::Class::Carp;
use Try::Tiny;
use namespace::clean;

__PACKAGE__->sql_maker_class('DBIx::Class::SQLMaker::SQLite');
__PACKAGE__->sql_limit_dialect ('LimitOffset');
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->datetime_parser_type ('DateTime::Format::SQLite');

=head1 NAME

DBIx::Class::Storage::DBI::SQLite - Automatic primary key class for SQLite

=head1 SYNOPSIS

  # In your table classes
  use base 'DBIx::Class::Core';
  __PACKAGE__->set_primary_key('id');

=head1 DESCRIPTION

This class implements autoincrements for SQLite.

=head2 Known Issues

=over

=item RT79576

 NOTE - This section applies to you only if ALL of these are true:

  * You are or were using DBD::SQLite with a version lesser than 1.38_01

  * You are or were using DBIx::Class versions between 0.08191 and 0.08209
    (inclusive) or between 0.08240-TRIAL and 0.08242-TRIAL (also inclusive)

  * You use objects with overloaded stringification and are feeding them
    to DBIC CRUD methods directly

An unfortunate chain of events led to DBIx::Class silently hitting the problem
described in L<RT#79576|https://rt.cpan.org/Public/Bug/Display.html?id=79576>.

In order to trigger the bug condition one needs to supply B<more than one>
bind value that is an object with overloaded stringification (nummification
is not relevant, only stringification is). When this is the case the internal
DBIx::Class call to C<< $sth->bind_param >> would be executed in a way that
triggers the above-mentioned DBD::SQLite bug. As a result all the logs and
tracers will contain the expected values, however SQLite will receive B<all>
these bind positions being set to the value of the B<last> supplied
stringifiable object.

Even if you upgrade DBIx::Class (which works around the bug starting from
version 0.08210) you may still have corrupted/incorrect data in your database.
DBIx::Class will currently detect when this condition (more than one
stringifiable object in one CRUD call) is encountered and will issue a warning
pointing to this section. This warning will be removed 2 years from now,
around April 2015, You can disable it after you've audited your data by
setting the C<DBIC_RT79576_NOWARN> environment variable. Note - the warning
is emited only once per callsite per process and only when the condition in
question is encountered. Thus it is very unlikey that your logsystem will be
flooded as a result of this.

=back

=head1 METHODS

=cut

sub backup {

  require File::Spec;
  require File::Copy;
  require POSIX;

  my ($self, $dir) = @_;
  $dir ||= './';

  ## Where is the db file?
  my $dsn = $self->_dbi_connect_info()->[0];

  my $dbname = $1 if($dsn =~ /dbname=([^;]+)/);
  if(!$dbname)
  {
    $dbname = $1 if($dsn =~ /^dbi:SQLite:(.+)$/i);
  }
  $self->throw_exception("Cannot determine name of SQLite db file")
    if(!$dbname || !-f $dbname);

#  print "Found database: $dbname\n";
#  my $dbfile = file($dbname);
  my ($vol, $dbdir, $file) = File::Spec->splitpath($dbname);
#  my $file = $dbfile->basename();
  $file = POSIX::strftime("%Y-%m-%d-%H_%M_%S", localtime()) . $file;
  $file = "B$file" while(-f $file);

  mkdir($dir) unless -f $dir;
  my $backupfile = File::Spec->catfile($dir, $file);

  my $res = File::Copy::copy($dbname, $backupfile);
  $self->throw_exception("Backup failed! ($!)") if(!$res);

  return $backupfile;
}

sub _exec_svp_begin {
  my ($self, $name) = @_;

  $self->_dbh->do("SAVEPOINT $name");
}

sub _exec_svp_release {
  my ($self, $name) = @_;

  $self->_dbh->do("RELEASE SAVEPOINT $name");
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;

  # For some reason this statement changes the value of $dbh->{AutoCommit}, so
  # we localize it here to preserve the original value.
  local $self->_dbh->{AutoCommit} = $self->_dbh->{AutoCommit};

  $self->_dbh->do("ROLLBACK TRANSACTION TO SAVEPOINT $name");
}

sub _ping {
  my $self = shift;

  # Be extremely careful what we do here. SQLite is notoriously bad at
  # synchronizing its internal transaction state with {AutoCommit}
  # https://metacpan.org/source/ADAMK/DBD-SQLite-1.37/lib/DBD/SQLite.pm#L921
  # There is a function http://www.sqlite.org/c3ref/get_autocommit.html
  # but DBD::SQLite does not expose it (nor does it seem to properly use it)

  # Therefore only execute a "ping" when we have no other choice *AND*
  # scrutinize the thrown exceptions to make sure we are where we think we are
  my $dbh = $self->_dbh or return undef;
  return undef unless $dbh->FETCH('Active');
  return undef unless $dbh->ping;

  my $ping_fail;

  # older DBD::SQLite does not properly synchronize commit state between
  # the libsqlite and the $dbh
  unless (defined $DBD::SQLite::__DBIC_TXN_SYNC_SANE__) {
    $DBD::SQLite::__DBIC_TXN_SYNC_SANE__ = modver_gt_or_eq('DBD::SQLite', '1.38_02');
  }

  # fallback to travesty
  unless ($DBD::SQLite::__DBIC_TXN_SYNC_SANE__) {
    # since we do not have access to sqlite3_get_autocommit(), do a trick
    # to attempt to *safely* determine what state are we *actually* in.
    # FIXME
    # also using T::T here leads to bizarre leaks - will figure it out later
    my $really_not_in_txn = do {
      local $@;

      # older versions of DBD::SQLite do not properly detect multiline BEGIN/COMMIT
      # statements to adjust their {AutoCommit} state. Hence use such a statement
      # pair here as well, in order to escape from poking {AutoCommit} needlessly
      # https://rt.cpan.org/Public/Bug/Display.html?id=80087
      eval {
        # will fail instantly if already in a txn
        $dbh->do("-- multiline\nBEGIN");
        $dbh->do("-- multiline\nCOMMIT");
        1;
      } or do {
        ($@ =~ /transaction within a transaction/)
          ? 0
          : undef
        ;
      };
    };

    # if we were unable to determine this - we may very well be dead
    if (not defined $really_not_in_txn) {
      $ping_fail = 1;
    }
    # check the AC sync-state
    elsif ($really_not_in_txn xor $dbh->{AutoCommit}) {
      carp_unique (sprintf
        'Internal transaction state of handle %s (apparently %s a transaction) does not seem to '
      . 'match its AutoCommit attribute setting of %s - this is an indication of a '
      . 'potentially serious bug in your transaction handling logic',
        $dbh,
        $really_not_in_txn ? 'NOT in' : 'in',
        $dbh->{AutoCommit} ? 'TRUE' : 'FALSE',
      );

      # it is too dangerous to execute anything else in this state
      # assume everything works (safer - worst case scenario next statement throws)
      return 1;
    }
  }

  # do the actual test and return on no failure
  ( $ping_fail ||= ! try { $dbh->do('SELECT * FROM sqlite_master LIMIT 1'); 1 } )
    or return 1; # the actual RV of _ping()

  # ping failed (or so it seems) - need to do some cleanup
  # it is possible to have a proper "connection", and have "ping" return
  # false anyway (e.g. corrupted file). In such cases DBD::SQLite still
  # keeps the actual file handle open. We don't really want this to happen,
  # so force-close the handle via DBI itself
  #
  local $@; # so that we do not clober the real error as set above
  eval { $dbh->disconnect }; # if it fails - it fails
  undef; # the actual RV of _ping()
}

sub deployment_statements {
  my $self = shift;
  my ($schema, $type, $version, $dir, $sqltargs, @rest) = @_;

  $sqltargs ||= {};

  if (
    ! exists $sqltargs->{producer_args}{sqlite_version}
      and
    my $dver = $self->_server_info->{normalized_dbms_version}
  ) {
    $sqltargs->{producer_args}{sqlite_version} = $dver;
  }

  $self->next::method($schema, $type, $version, $dir, $sqltargs, @rest);
}

sub bind_attribute_by_data_type {
  $_[1] =~ /^ (?: int(?:eger)? | (?:tiny|small|medium)int ) $/ix
    ? DBI::SQL_INTEGER()
    : undef
  ;
}

# DBD::SQLite (at least up to version 1.31 has a bug where it will
# non-fatally nummify a string value bound as an integer, resulting
# in insertions of '0' into supposed-to-be-numeric fields
# Since this can result in severe data inconsistency, remove the
# bind attr if such a sitation is detected
#
# FIXME - when a DBD::SQLite version is released that eventually fixes
# this sutiation (somehow) - no-op this override once a proper DBD
# version is detected
sub _dbi_attrs_for_bind {
  my ($self, $ident, $bind) = @_;

  my $bindattrs = $self->next::method($ident, $bind);

  # an attempt to detect former effects of RT#79576, bug itself present between
  # 0.08191 and 0.08209 inclusive (fixed in 0.08210 and higher)
  my $stringifiable = 0;

  for (0.. $#$bindattrs) {

    $stringifiable++ if ( length ref $bind->[$_][1] and overload::Method($bind->[$_][1], '""') );

    if (
      defined $bindattrs->[$_]
        and
      defined $bind->[$_][1]
        and
      $bindattrs->[$_] eq DBI::SQL_INTEGER()
        and
      $bind->[$_][1] !~ /^ [\+\-]? [0-9]+ (?: \. 0* )? $/x
    ) {
      carp_unique( sprintf (
        "Non-integer value supplied for column '%s' despite the integer datatype",
        $bind->[$_][0]{dbic_colname} || "# $_"
      ) );
      undef $bindattrs->[$_];
    }
  }

  carp_unique(
    'POSSIBLE *PAST* DATA CORRUPTION detected - see '
  . 'DBIx::Class::Storage::DBI::SQLite/RT79576 or '
  . 'http://v.gd/DBIC_SQLite_RT79576 for further details or set '
  . '$ENV{DBIC_RT79576_NOWARN} to disable this warning. Trigger '
  . 'condition encountered'
  ) if (!$ENV{DBIC_RT79576_NOWARN} and $stringifiable > 1);

  return $bindattrs;
}

=head2 connect_call_use_foreign_keys

Used as:

    on_connect_call => 'use_foreign_keys'

In L<connect_info|DBIx::Class::Storage::DBI/connect_info> to turn on foreign key
(including cascading) support for recent versions of SQLite and L<DBD::SQLite>.

Executes:

  PRAGMA foreign_keys = ON

See L<http://www.sqlite.org/foreignkeys.html> for more information.

=cut

sub connect_call_use_foreign_keys {
  my $self = shift;

  $self->_do_query(
    'PRAGMA foreign_keys = ON'
  );
}

1;

=head1 AUTHOR AND CONTRIBUTORS

See L<AUTHOR|DBIx::Class/AUTHOR> and L<CONTRIBUTORS|DBIx::Class/CONTRIBUTORS> in DBIx::Class

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut