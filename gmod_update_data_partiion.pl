#!/usr/bin/perl 
use strict;
use warnings;

use FindBin qw($Bin);
use File::Path qw(make_path);
use File::Copy;

my $root_version = 0;
my $data_version = 0;

exit 0 unless (update_needed()) ;

update0to2_03();

exit 0;

sub update_needed {
    if (-f "/etc/gmod/ROOT_VERSION") {
        $root_version = `cat /etc/gmod/ROOT_VERSION`;
    }

    if (-f "/data/DATA_VERSION") {
        $data_version = `cat /data/version`;
    }

    if ($data_version >= $root_version) {
        return 0;
    }

    return 1;
}

sub update0to2_03 {
    my $LOCAL_FILES            = $Bin . '/update_data/data/';
    my $LOCAL_WEBAPOLLO_CONFIG = $LOCAL_FILES . 'var/lib/tomcat7/webapps/WebApollo/config/';
    my $DATA_WEBAPOLLO_CONFIG  = '/data/var/lib/tomcat7/webapps/WebApollo/config/'; 
    my $LOCAL_TOMCAT_BIN       = $LOCAL_FILES . 'usr/share/tomcat7/bin/';
    my $DATA_TOMCAT_BIN        ='/data/usr/share/tomcat7/bin/';

    print STDERR "Making $DATA_WEBAPOLLO_CONFIG\n";
    make_path($DATA_WEBAPOLLO_CONFIG) or die $!;
    print STDERR "Copying $LOCAL_WEBAPOLLO_CONFIG" . "config.xml\n";
    copy     ($LOCAL_WEBAPOLLO_CONFIG . 'config.xml',
              $DATA_WEBAPOLLO_CONFIG) or die $!;
    print STDERR "Copying $LOCAL_WEBAPOLLO_CONFIG" . "canned_comments.xml\n";
    copy     ($LOCAL_WEBAPOLLO_CONFIG . 'canned_comments.xml',
              $DATA_WEBAPOLLO_CONFIG) or die $!;

    print STDERR "Making $DATA_TOMCAT_BIN\n"; 
    make_path($DATA_TOMCAT_BIN) or die $!;
    print STDERR "Copying $LOCAL_TOMCAT_BIN" . "setenv.sh\n";
    copy     ($LOCAL_TOMCAT_BIN . 'setenv.sh',
              $DATA_TOMCAT_BIN) or die $!; 
}

