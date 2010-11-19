#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  database-testtool.pl
#
#        USAGE:  ./database-testtool.pl 
#
#  DESCRIPTION:  Testing database connections
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Martin von Oertzen <maletin@cpan.org>
#      COMPANY:  
#      VERSION:  0.1.0
#      CREATED:  19.11.2010 19:54:25 UTC
#     REVISION:  $Id$
#===============================================================================

use strict;
use warnings;
use 5.010;
use version; our $VERSION = qv('0.1.0');
use Log::Log4perl qw(:easy);
use Data::Dumper;
use Readonly;
use Pod::Usage;
use DBI;
use Config::IniFiles;
use Getopt::Long;
use Curses;
use POE qw(Wheel::Curses);

my %opt;
GetOptions( \%opt, 'config=s', 'help|?', 'verbose|v' ) or pod2usage(2);
pod2usage( -verbose => 2 ) if $opt{help};

my $cfg = new Config::IniFiles( -file => $opt{config} );
DEBUG( '$cfg=', Dumper($cfg) );
Readonly my $LOGFILE => $opt{log} || $cfg->val( 'log', 'file' );
Log::Log4perl->easy_init(
    {
        level => $opt{verbose} ? $DEBUG : $INFO,
        file => ':utf8>>' . $LOGFILE,
        layout => $opt{layout},
    },
);

POE::Session->create(
    inline_states => {
        _start => sub {
            $_[HEAP]{console} =
              POE::Wheel::Curses->new( InputEvent => 'got_keystroke', );
              move( 0, 0 );
              addstr( 'press "c" to connect, "h" for help' );
              move( 1, 0 );
        },
        got_keystroke => sub {
            my $keystroke = $_[ARG0];

            # Make control and extended keystrokes printable.
            if ( $keystroke lt ' ' ) {
                $keystroke = '<' . uc( unctrl($keystroke) ) . '>';
            }
            elsif ( $keystroke =~ /^\d{2,}$/ ) {
                $keystroke = '<' . uc( keyname($keystroke) ) . '>';
            }

            # Just display it.
            addstr($keystroke);
            noutrefresh();
            if ( $keystroke eq 'c' ) {
                my ( $x, $y );
                getyx( $y, $x );
                move( 1, 0 );
                addstr( scalar localtime() );
                move( $y, $x );
            }
            doupdate;

            # Gotta exit somehow.
            delete $_[HEAP]{console} if $keystroke eq "<^C>";
        },
    }
);

POE::Kernel->run();
