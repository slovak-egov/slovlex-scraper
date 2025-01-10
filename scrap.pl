#!/usr/bin/perl

use warnings;
use strict;

use URI;
use Web::Scraper;
use Encode;
use Data::Dumper;
my $lexuri = "https://static.slov-lex.sk/static/SK/ZZ";
my %lexdump;
my $since;
my $till;
my %stats;
my $cache;
my $proxy;

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0');

use Getopt::Long;    
GetOptions ("since=s" => \$since,
            "till=s"  => \$till,
            "proxy=s" => \$proxy,
	    "cache=s" => \$cache)
or die("Error in arguments!\n");

# proxy support
if(defined $proxy){
    $ua->proxy(['http', 'https'], $proxy);
}

if (defined $cache) {
    use HTTP::Cache::Transparent;
    HTTP::Cache::Transparent::init( {
        BasePath => $cache,
        Verbose   => 1,
        MaxAge    => 8*24,
        NoUpdate  => 15*60,
    } );
}

sub lex_scrap {
    my $year = shift;
    die "Wrong year: $year" unless $year =~ m/\d{4}/;
    my $lexs = scraper {
	    process '//table[@id="YearTable"]/tbody/tr', "lexs[]" => scraper {
	      # And, in each TD,
	      process '//td[1]', index => [ 'TEXT', qr/(\d+\/\d{4})/ ];
	      process '//td[2]/a', uri => '@href';
	      process '//td[2]/a', fullname => 'TEXT';
	    };
    };
    $ua->agent('Mozilla/5.0');
    $lexs->user_agent($ua);
    my $res = $lexs->scrape( URI->new("$lexuri/$year/") );
    return get_lextype($res);
}

sub lex_history {
    my $h = shift;
    #my $revs;
    my @ra;
    
    foreach my $lex (@{$h->{lexs}}){
        undef @ra;
        print STDERR "   $lex->{index}\n";
        print Dumper $lex->{uri};
        my $revs = scraper {
              #process '//table[@id="HistoriaTable"]/tbody/tr', "revisions[]" => scraper {
              process '//tr[@class="effectivenessHistoryItem"]', "revisions[]" => scraper {
              # And, in each TD,
              process '//td[1]', index => [ 'TEXT' ];
              process '//td[2]/a', uri => '@href';
              #process '//td[2]/a/span', desc => 'TEXT';
            };
         };
         $lex->{revisions} = $revs->scrape( $lex->{uri} );
         #print Dumper $x;
    }
    #return @ra;
}

sub get_lextype {
    my $x = shift;
    foreach my $a (@{$x->{'lexs'}}){
        $a->{'fullname'} =~ /^(\w+)/;
        $a->{'type'} = $1;
    }
    return $x;
}

sub print_lex {
    my $year = shift;
    die "Wrong year: $year" unless $year =~ m/\d{4}/;

    for my $lex (@{$lexdump{$year}->{'lexs'}}) {
        print Encode::encode("utf8", join "%", $lex->{'index'}, $lex->{'type'}, $lex->{'fullname'}, $lex->{'uri'});
        print "\n";
    }
}

sub print_stats {
    print "Years processed: ";
    print scalar keys %lexdump;
    print "\n";
    print "Lexs per year:\n";

    foreach my $y (keys %lexdump){
        $stats{$y}{'lexno'} = scalar @{$lexdump{$y}{lexs}};
        print "  $y $stats{$y}{'lexno'} \n";
    }
}

for my $y ($since..$till) {
    print STDERR "Processing: $y";
    $lexdump{$y} = lex_scrap($y);
    #$lexdump{$y} = $rs;
    lex_history($lexdump{$y});
    print STDERR ". Done\n";
    print_lex($y);
}

#print_stats;
print Dumper %lexdump;

1;
