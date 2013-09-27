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
        $data_version = `cat /data/DATA_VERSION`;
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

    unless (-d $DATA_WEBAPOLLO_CONFIG) {
        print STDERR "Making $DATA_WEBAPOLLO_CONFIG\n";
        make_path($DATA_WEBAPOLLO_CONFIG) or die $!;
    }

    unless (-f $DATA_WEBAPOLLO_CONFIG . 'config.xml') {
        print STDERR "Copying $LOCAL_WEBAPOLLO_CONFIG" . "config.xml\n";
        copy     ($LOCAL_WEBAPOLLO_CONFIG . 'config.xml',
                  $DATA_WEBAPOLLO_CONFIG) or die $!;
    }

    unless (-f $DATA_WEBAPOLLO_CONFIG . 'canned_comments.xml') { 
        print STDERR "Copying $LOCAL_WEBAPOLLO_CONFIG" . "canned_comments.xml\n";
        copy     ($LOCAL_WEBAPOLLO_CONFIG . 'canned_comments.xml',
                  $DATA_WEBAPOLLO_CONFIG) or die $!;
    }

    unless (-d $DATA_TOMCAT_BIN) {
        print STDERR "Making $DATA_TOMCAT_BIN\n"; 
        make_path($DATA_TOMCAT_BIN) or die $!;
    }

    unless (-f $DATA_TOMCAT_BIN . 'setenv.sh' ) {
        print STDERR "Copying $LOCAL_TOMCAT_BIN" . "setenv.sh\n";
        copy     ($LOCAL_TOMCAT_BIN . 'setenv.sh',
                  $DATA_TOMCAT_BIN) or die $!; 
    }

    print STDERR "\nAdding WebApollo as a JBrowse plugin\n\n";
    chdir("/var/lib/tomcat7/webapps/WebApollo/jbrowse") or die $!;
    system("perl bin/add-webapollo-plugin.pl -i data/trackList.json");

    open (VERS, '>', '/data/DATA_VERSION') or die $!;
    print VERS "2.03\n";
    close VERS;

    print STDERR <<END

IMPORTANT: This version of GMOD in the Cloud moved the these files to the
/data partition:  

    /var/lib/tomcat7/webapps/WebApollo/config/config.xml
    /var/lib/tomcat7/webapps/WebApollo/config/canned_comments.xml
    /usr/share/tomcat7/bin/setenv.sh

If you modified any of these files in your previous instance of GMOD in
the Cloud, please obtain those files from the old instance and carefully
merge them into their counterparts on the /data partition.  DO NOT just
replace them, as there are new configuration items particularly in the
WebApollo config.xml file.

END
;
}

