#!/usr/bin/env perl
# <@(#)tag:tw@lukas.uberbaud.foo,2026-06-25:19.59.09z/462b072>

use v5.40;
use utf8;
use open qw( :std :encoding(UTF-8) );   # undeclared streams in UTF-8

#use Unicode::Normalize;                # decompose in, recompose out
use Encode qw(decode);
use File::Which;
use Tw::Toolkit qw(sparkle bolt bleat brief NOT_IMPLEMENTED);  # also commify
use JSON;
use File::Which;
use List::Util qw(zip_shortest);

my $firefox_tabs = which("ls-tabs-firefox")
    or die "required command not found: ls-tabs-firefox";
my $mailstore   = '/var/www/htdocs/twSite/mailstore';
my $twsite      = 'http://localhost/twSite';
my $webpath     = "$twsite/mailstore";
my $fbatch      = $ENV{XDG_PUBLICSHARE_DIR} . '/mail/.batch';
my $current_prefix = do { local (@ARGV,$/) = $fbatch; <> };
chomp $current_prefix;

chomp $current_prefix;

# Usage {{{1
my ($this_pgm) = $0 =~ m/([^\/]*$)/;
my $Usage = sparkle( <<".", $this_pgm, $this_pgm );
^NUSAGE^n: ^T%s^t
           Clean messages not open in firefox or with the prefix being used
           by an open mailreader instance.
.
# }}}1
sub usage { print STDERR $Usage; exit 0; }
sub clean_inactive_pages { # {{{1
    # get all open urls
    my @firefox_urls = qx($firefox_tabs);
    chomp(@firefox_urls);

    # filter everything not a mailreader tab
    my %msg_files = map { $_ => 1 } grep { s|^$webpath|| } @firefox_urls;

    # filter everything not a message
    my %reader_fracs = map { $_ => 1 } grep {
            s|^$twsite/mailreader\.html#||;
        } @firefox_urls;
    $reader_fracs{$current_prefix} = 1; # save the latest batch in case we
                                        # havent started the reader yet
    foreach my $file (glob "*.html") {
        next if exists $msg_files{$file};
        my $prefix = $file =~ s/-.*$//r;
        next if exists $reader_fracs{$prefix};
        unlink $file or bleat('Could not delete ^B%s^b.',$file);
      }
} #}}}1
sub print_to_json_file ($fbase,$obj) { # {{{1
    my $fname = "$fbase.json";
    open(my $fout, '>', "$fname") or die "$fname: $!";
    print $fout encode_json($obj);
    close $fout;
} # }}}1
sub by_msg_id { # {{{1
    my @A = split /\./, $a;
    my @B = split /\./, $b;
    my $gteqlt = 0;
    for my ($z) (zip_shortest \@A, \@B) {
        my ($c,$d) = @$z;
        $gteqlt = ($c//0) <=> ($d//0);
        last unless $gteqlt == 0;
      }
    return $gteqlt unless $gteqlt == 0;
    return $#A <=> $#B;
} # }}}1
sub maxtag ($a,$b) { # {{{1
    my $a_pre = substr $a, 0, 3;
    my $a_num = substr $a, 3;
    my $b_pre = substr $b, 0, 3;
    my $b_num = substr $b, 3;
    return $a if $a_pre gt $b_pre;
    return $b if $b_pre gt $a_pre;
    # $a_pre and $b_pre are equal;
    return $a if $a_num > $b_num;
    return $b if $b_num > $b_num;
    # should never be here
    bleat("tags ^T%s^t and ^T%s^t are unexpectedly equal.", $a, $b);
    return $a; # either would do, they're the same!
} # }}}1
sub latest_tag { # {{{1
    my $max = '!!!0'; # less than any valid tab
    $max = maxtag($max,$_) for (@_);
    return $max eq '!!!0' ? undef : $max;
} #}}}1
sub refresh_msg_list { # {{{1
    # First, clean work files
    unlink foreach (glob "work/*-msg-list.json");

    # Second, make them anew
    my %msgmap;
    for my $file (glob "*.html") {
        $file =~ m|(?<tag>[^-]+)-(?<id>[0-9.]+)\.html|n
            or bleat("weirdly named file: $file");
        push @{$msgmap{$+{tag}}}, $+{id};
      }

    foreach my $key (keys %msgmap) {
        my @sorted = sort by_msg_id @{$msgmap{$key}};
        $msgmap{$key} = \@sorted;
        print_to_json_file("work/$key-msg-list",\@sorted);
      }

    # Finally, remake msg-list.json
    print_to_json_file('msg-list', {
        newest  => latest_tag(keys %msgmap),
        batches => \%msgmap
      });
} # }}}1

my $verbose = 0;

usage if (@ARGV);

chdir $mailstore
    or bolt('Could not ^Tcd^t to ^B%s^b.',$mailstore);

clean_inactive_pages();
refresh_msg_list();

__END__
{{{1 POD Documentation
=head1 NAME

clean-web-mail.pl - Clean mailreader html files not in use.

=head1 USAGE

clean-web-mail.pl

Uses C<ls-tabs-firefox> to get urls in use by B<firefox>, and deletes files
in C</var/www/htdocs/twSite/mailstore> not matching any corresponding B<url>
or the latest prefix found in C<$XDG_PUBLICSHARE_DIR/mail/.batch>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Tom Davis <tom@greyshirt.net>.

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

=head1 DISCLAIMER OF WARRANTY

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut
}}}1
