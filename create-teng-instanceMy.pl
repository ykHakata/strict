use strict;
use warnings;
use utf8;
use Teng;
use Teng::Schema::Loader;

my $dbh = DBI->connect(
    'dbi:SQLite:db/strict.db',
    '', '',
    {   RaiseError        => 1,
        PrintError        => 0,
        AutoCommit        => 1,
        sqlite_unicode    => 1,
        mysql_enable_utf8 => 1,
    }
);
my $teng = Teng::Schema::Loader->load(
    dbh       => $dbh,
    namespace => 'MyApp::DB',
);
