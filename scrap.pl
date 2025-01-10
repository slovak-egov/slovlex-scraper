#!/usr/bin/perl

use warnings;
use strict;

use URI;
use Web::Scraper;
use Encode;
use Data::Dumper;
my $lexuri = "https://static.slov-lex.sk/static/SK/ZZ";
my %lexdump;
my @years = (2020..2024);
my %stats;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
    
GetOptions ("years=s" => \@years,
            "proxy=s" => \$proxy,
	    "cache=s" => \$cache)
or die("Error in arguments!\n");

# proxy support
if(defined $proxy){
    $ua->proxy(['http', 'https'], $proxy);
    $ua->agent('Mozilla/5.0');
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
    my $res = $lexs->scrape( URI->new("$lexuri/$year/") );
    $lexs->user_agent($ua);
    return get_lextype($res);
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

for my $y (@years) {
    print STDERR "Processing: $y";
    my $rs = lex_scrap($y);
    $lexdump{$y} = $rs;
    print STDERR ". Done\n";
    print_lex($y);
}

#print_stats;
#print Dumper %lexdump;

1;
