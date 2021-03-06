use strict;
use warnings;
use utf8;
use DBI;
use Teng;
use Teng::Schema::Loader;
# use Data::Dumper;

my $dbh = DBI->connect('dbi:mysql:strict', 'root', '0520', {
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
    sqlite_unicode => 1,
    mysql_enable_utf8 => 1,
});

my $teng = Teng::Schema::Loader->load(
    dbh => $dbh,
    namespace => 'MyApp::DB',
);

