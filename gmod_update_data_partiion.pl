#!/usr/bin/perl 
use strict;
use warnings;

use FindBin qw($Bin);
use File::Path qw(make_path);
use File::Copy;

my $root_version = 0;
my $data_version = 0;

exit 0 unless (update_needed()) ;



sub update_needed {
    if (-e "/etc/gmod/ROOT_VERSION") {
        $root_version = `cat /etc/gmod/ROOT_VERSION`;
    }

    if (-e "/data/DATA_VERSION") {
        $data_version = `cat /data/version`;
    }

    if ($data_version >= $root_version) {
        return 0;
    }

    return 1;
}

sub update0to2_03 {
    my $LOCAL_FILES            = $Bin . '/update_data/data/';
    my $LOCAL_WEBAPOLLO_CONFIG = $LOCAL_FILES . '/var/lib/tomcat7/webapps/WebApollo/config/';
    my $DATA_WEBAPOLLO_CONFIG  = '/data/var/lib/tomcat7/webapps/WebApollo/config/'; 
    my $LOCAL_TOMCAT_BIN       = $LOCAL_FILES . 'usr/share/tomcat7/bin/';
    my $DATA_TOMCAT_BIN        ='/data/usr/share/tomcat7/bin/';

    make_path($DATA_WEBAPOLLO_CONFIG) or die $!;
    copy     ($LOCAL_WEBAPOLLO_CONFIG . 'config.xml',
              $DATA_WEBAPOLLO_CONFIG) or die $!;
    copy     ($LOCAL_WEBAPOLLO_CONFIG . 'canned_comments.xml',
              $DATA_WEBAPOLLO_CONFIG) or die $!;
 
    make_path($DATA_TOMCAT_BIN) or die $!;
    copy     ($LOCAL_TOMCAT_BIN . 'setenv.sh',
              $DATA_TOMCAT_BIN) or die $!; 
}

