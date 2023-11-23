#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use v5.32;

my $pStore  = "$ENV{XDG_DATA_HOME}/gw1100";
my $dbfile  = "$pStore/gw1100.db3";
my (%vars, $dbh, $insStmt);
my $rxSkip = qr/
        ^(
            ID              |
            PASS(KEY|WORD)  |
            action          |
            baromrelin      |
            dateutc         |
            freq            |
            realtime        |
            rtfreq          |
            runtime
        )$
    /x;
sub getLatestVars { # {{{1
    my $dbh = shift;
    my %vars;
    my $getLatestStmt = $dbh->prepare(
        q(SELECT k, val FROM latest;)
      ) or die $dbh->errstr;
    $getLatestStmt->execute();
    my ($key,$val);
    $vars{$key} = $val
        while ($key,$val) = $getLatestStmt->fetchrow_array;
    return %vars;
} # }}}1
sub set_tuple { # {{{1
    my $ts  = shift;
    my $key = shift;
    my $val = shift;
    # ignore some keys and values
    return if $key =~ m/$rxSkip/;
    return if $val eq "-9999";

    if (!defined $vars{$key} or $val ne $vars{$key} ) {
        $insStmt->execute($ts,$key,$val) or warn $insStmt->errstr;
        $vars{$key} = $val;
      }
} # }}}1

$dbh = DBI->connect(
    "dbi:SQLite:dbname=$dbfile",
    "", # no username
    "", # no password
    { RaiseError => 0, AutoCommit => 1, PrintError => 0 }
  );
END { $dbh->disconnect if defined $dbh; }

%vars = getLatestVars($dbh);

$insStmt = $dbh->prepare(<<~'---') or die $dbh->errstr;
    INSERT INTO rawdat (unixts,key,val) VALUES (?,?,?);
    ---

package ReqDumper { # {{{1
    use base qw(HTTP::Server::Simple::CGI);

    my $html = <<~'---';
        <html>
        <header><title>Okay</title></header>
        <body><p>Okay</p></body>
        </html>
        ---
    my $len = length $html;
    my $header = <<~"---";
        HTTP/1.1 200 OK
        Connection: close
        Content-type: text/html; charset=UTF-8
        Content-Length: $len
        ---
    my $doc = "$header\n$html";

    sub handle_request {
        my ($self,$cgi) = @_;

        my $ts = time;

        # POST parameters
        for my $key ($cgi->param) {
            my $val = $cgi->param($key);
            main::set_tuple( $ts, $key, $val );
          }
        # URL parameters (GET or POST)
        for my $key ($cgi->url_param) {
            my $val = $cgi->url_param($key);
            main::set_tuple( $ts, $key, $val );
          }

        # return document
        print $doc;
    }
}; # }}}1

sub sighandler { die "Exiting ...\n"; }
$SIG{"INT"}  = \&sighandler;
$SIG{"QUIT"} = \&sighandler;
$SIG{"TERM"} = \&sighandler;
$SIG{"HUP"}  = 'IGNORE';

my $pid = ReqDumper->new(8080)->run();

