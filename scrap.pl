#!/usr/bin/perl

use warnings;
use strict;

use URI;
use Web::Scraper;
use Encode;
use Data::Dumper;
my $lexuri = "https://static.slov-lex.sk/static/SK/ZZ";
my $lexdump;
my $since;
my $till;
my %stats;
my $file;
my $cache;
my $proxy;

#use LWP::UserAgent;
#my $ua = LWP::UserAgent->new;
use LWP::UserAgent::Determined;
my $ua = LWP::UserAgent::Determined->new;
$ua->agent('Mozilla/5.0');

use Getopt::Long;    
GetOptions ("since=s" => \$since,
            "till=s"  => \$till,
            "proxy=s" => \$proxy,
            "file=s"  => \$file,
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
        NoUpdate  => 60*60,
    } );
}

sub to_file {
    #json output
    use JSON;
    use File::Path qw(make_path);
    use POSIX 'strftime';
    use File::stat;
    my $datestamp = strftime '%Y-%m-%d', localtime;

    open(FH, '>', "$file.$datestamp") or die $!;
    print FH to_json($lexdump, {utf8 => 1, pretty => 1, canonical => 1,
                                allow_blessed => 1, convert_blessed => 1, allow_tags => 1});
    close(FH);
}

sub lex_scrap {
    my $year = shift;
    die "Wrong year: $year" unless $year =~ m/\d{4}/;
    my $lexscraper = scraper {
	    process '//table[@id="YearTable"]/tbody/tr', "lexs[]" => scraper {
	      # And, in each TD,
	      process '//td[1]', index => [ 'TEXT', qr/(\d+\/\d{4})/ ];
	      process '//td[2]/a', uri => '@href';
	      process '//td[2]/a', fullname => 'TEXT';
	    };
    };
    $lexscraper->user_agent($ua);
    my $res = $lexscraper->scrape( URI->new("$lexuri/$year/") );
    return get_lextype($res);
}

sub lex_info {
    my $h = shift;
    my $x = shift;
    #$x = "main" if (!defined $x);
    
    my $revs = scraper {
        process '//table[@id="InfoTable"]/tr', "infos[]" => scraper {
        # And, in each TD,
        process '//td[1]', info => [ 'TEXT', qr/(.*):$/ ];
        process '//td[2]', value => [ 'TEXT'];
        };
    };
	$revs->user_agent($ua);
    my $dup = $h->clone();
    $dup->path_segments($dup->path_segments(), "vyhlasene_znenie.html") if ($x eq "main");
    my $arr = $revs->scrape( $dup )->{infos};
    my $a;
    foreach my $f (@$arr) {
        $a->{lc($f->{info})} = $f->{value};
    }
    undef $dup;
    return $a;
}

sub lex_history {
    my $h = shift;
    my @ra;
    
    foreach my $lex (@{$h->{lexs}}){
        undef @ra;
        print STDERR "   $lex->{index}\n";
        my $revs = scraper {
              #process '//table[@id="HistoriaTable"]/tbody/tr', "revisions[]" => scraper {
              process '//tr[@class="effectivenessHistoryItem"]', "revisions[]" => scraper {
              # And, in each TD,
              process '//td[1]', index => [ 'TEXT' ];
              process '//td[2]/a', uri => '@href';
              #process '//td[2]/a/span', desc => 'TEXT';
            };
         };
	 $revs->user_agent($ua);
         $lex->{revisions} = $revs->scrape( $lex->{uri} )->{revisions};
         $lex->{info} = lex_info($lex->{uri}, "main");
    }
}

sub lex_structure {
    my $h = shift;

    my $revs = scraper {
        process '//div[@class="obsah"]', "structure[]" => scraper {
            # And, in each TD,
            process '//a', uri => '@href';
            #process '//a/span', name => [ 'TEXT' ];
            #process '//td[2]/a/span', desc => 'TEXT';
        };
    };
    $h->{structure} = $revs->scrape( $h->{uri} )->{structure};
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

    for my $lex (@{$lexdump->{$year}->{'lexs'}}) {
        print Encode::encode("utf8", join "%", $lex->{'index'}, $lex->{'type'}, $lex->{'fullname'}, $lex->{'uri'});
        print "\n";
    }
}

sub print_stats {
    print "Years processed: ";
    print scalar keys %{$lexdump};
    print "\n";
    print "Lexs per year:\n";

    foreach my $y (keys %{$lexdump}){
        $stats{$y}{'lexno'} = scalar @{$lexdump->{$y}{lexs}};
        print "  $y $stats{$y}{'lexno'} \n";
    }
}

for my $y ($since..$till) {
    print STDERR "Processing: $y";
    $lexdump->{$y} = lex_scrap($y);

    lex_history($lexdump->{$y});
    #lex_info($lexdump->{$y}, "main");

    foreach my $lex (@{$lexdump->{$y}->{lexs}}){
        #print Dumper $lex;
        foreach my $rev (@{$lex->{revisions}}){
            $rev->{structure} = lex_structure($rev);
            $rev->{info} = lex_info($rev->{uri}, "revision");
        }
    }

    print STDERR ". Done\n";
    print_lex($y);
}

to_file() if (defined $file);
#print_stats;
#print Dumper $lexdump;


1;
