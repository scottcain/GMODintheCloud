#!/usr/bin/perl 

# put this script in /etc/gmod/, make it executable and add 
#   /etc/gmod/GMODCallHome.pl
#   exit 0
# to /etc/rc.local
#

use strict;
use warnings;
use HTTP::Request::Common;
use LWP::UserAgent;
use FindBin '$Bin';
use IO::Prompter;
use Net::Address::IP::Local;
use constant REGISTRATION_SERVER 
           => 'http://modencode.oicr.on.ca/cgi-bin/gbrowse_registration';

#check to see if this instance all ready called
exit 0 if (-f "$Bin/gitc_lock");

#interactively get permission and user data
my $assent = 
  prompt("\nWould you be willing to have info about this instance sent to GMOD?", "-y");

unless ($assent) {
    open (LOCK, ">$Bin/gitc_lock");
    print LOCK "Not sending the 'call home' email.  If you would like to rerun the call home\nscript, just delete this file\n";
    close LOCK;
    exit 0;
}

my $username = prompt "Your name:";
my $email    = prompt "Your email address:";
my $org      = prompt "Your organization:";
my $organism = prompt "Organism or clade this will be used with:";

my $ipaddress = Net::Address::IP::Local->public;

my @callhome = ( user     => 'GiaB|'.$username,
                 email    => $email     || '',
                 org      => $org       || '',
                 organism => $organism  || '',
                 site     => $ipaddress || ''
                );

my $ua       = LWP::UserAgent->new;
my $response = $ua->request(
                 POST(REGISTRATION_SERVER,
                      \@callhome
               ));

#to prevent the same instance from calling home more than once
open (LOCK, ">$Bin/gitc_lock");
print LOCK "Sending the 'call home' email. If you would like to run the call homse script\nagain, delete this file.\n";
close LOCK;

print "\nThanks!\n\n";

exit 0;
