#!/usr/bin/perl 
use strict;
use warnings;

use FindBin qw($Bin);
use File::Path qw(make_path);
use File::Copy;
use File::Temp qw(tempfile);;

#webapollo directories that we'll use
my $LOCAL_FILES            = $Bin . '/update_data/data/';
my $LOCAL_WEBAPOLLO_CONFIG = $LOCAL_FILES . 'var/lib/tomcat7/webapps/WebApollo/config/';
my $DATA_WEBAPOLLO_CONFIG  = '/data/var/lib/tomcat7/webapps/WebApollo/config/';
my $LOCAL_TOMCAT_BIN       = $LOCAL_FILES . 'usr/share/tomcat7/bin/';
my $DATA_TOMCAT_BIN        ='/data/usr/share/tomcat7/bin/';

my $root_version = 0;
my $data_version = 0;

exit 0 unless (update_needed()) ;

update0to2_03() if $data_version < 2.03;

update2_03to2_05() if $data_version < 2.05;

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

sub update2_03to2_05 {

    unless (-f $DATA_WEBAPOLLO_CONFIG . 'gff3_config.xml') {
        print STDERR "Copying $LOCAL_WEBAPOLLO_CONFIG" . "gff3_config.xml\n";
        copy     ($LOCAL_WEBAPOLLO_CONFIG . 'gff3_config.xml',
                  $DATA_WEBAPOLLO_CONFIG) or die $!;
    }

    unless (-f $DATA_WEBAPOLLO_CONFIG . 'fasta_config.xml') {
        print STDERR "Copying $LOCAL_WEBAPOLLO_CONFIG" . "fasta_config.xml\n";
        copy     ($LOCAL_WEBAPOLLO_CONFIG . 'fasta_config.xml',
                  $DATA_WEBAPOLLO_CONFIG) or die $!;
    }

    unless (-f $DATA_WEBAPOLLO_CONFIG . 'blat_config.xml') {
        print STDERR "Copying $LOCAL_WEBAPOLLO_CONFIG" . "blat_config.xml\n";
        copy     ($LOCAL_WEBAPOLLO_CONFIG . 'blat_config.xml',
                  $DATA_WEBAPOLLO_CONFIG) or die $!;
    }

    update2_05WebApollo_config();

    open (VERS, '>', '/data/DATA_VERSION') or die $!;
    print VERS "2.05\n";
    close VERS;

    print STDERR <<END

IMPORTANT: This version of GMOD in the Cloud moved the these files to the
/data partition:  

    /var/lib/tomcat7/webapps/WebApollo/config/gff3_config.xml
    /var/lib/tomcat7/webapps/WebApollo/config/fasta_config.xml
    /var/lib/tomcat7/webapps/WebApollo/config/blat_config.xml

If you modified any of these files in your previous instance of GMOD in
the Cloud, please obtain those files from the old instance and carefully
merge them into their counterparts on the /data partition.  DO NOT just
replace them, as there are new configuration items.

The script also attempted an in place edit of the WebApollo config file,
$DATA_WEBAPOLLO_CONFIG/config.xml, and placed the old copy in
$DATA_WEBAPOLLO_CONFIG/config.xml.old.

END
;

}

    sub update2_05WebApollo_config {
#update config.xml (joy)
###first test that it needs updating!
        my $configfile = $DATA_WEBAPOLLO_CONFIG . 'config.xml';

        my @result = `grep use_pure_memory_store $configfile`;
        return if @result > 0; #doesn't need updating

        my ($newconfigfh, $newconfig) = tempfile();
        open (my $fh,"<",$configfile) or die "couldn't open $configfile for reading";
        while ( <$fh> ) {
            if (/use_cds_for_new_transcripts/) {
                print $newconfigfh $_;
                print $newconfigfh <<FIRST

        <!-- set to false to use hybrid disk/memory store which provides a little slower performance
        but uses a lot less memory - great for annotation rich genomes -->
        <use_pure_memory_store>true</use_pure_memory_store>

FIRST
;
            }
            elsif (/\<annotation_info_editor\>/) {
                print $newconfigfh $_;
                print $newconfigfh <<SECOND

                <!-- grouping for the configuration.  The "feature_types" attribute takes a list of
                SO terms (comma separated) to apply this configuration to
                (e.g., feature_types="sequence:transcript,sequence:mRNA" will make it so the group
                configuration will only apply to features of type "sequence:transcript" or "sequence:mRNA").
                A value of "default" will make this the default configuration for any types not explicitly
                defined in other groups.  You can have any many groups as you'd like -->
                <annotation_info_editor_group feature_types="default">

SECOND
;
            }
            elsif(/\<\/annotation_info_editor\>/) {
                print $newconfigfh <<THIRD

             </annotation_info_editor_group>
THIRD
;
                print $newconfigfh $_;
            } 
            elsif(/\<\/data_adapters\>/) {
                print $newconfigfh <<FOURTH

                <!-- group the <data_adapter> children elements together -->
                <data_adapter_group>

                        <!-- display name for adapter group -->
                        <key>FASTA</key>

                        <!-- required permission for using data adapter group
                        available options are: read, write, publish -->
                        <permission>read</permission>

                        <!-- one child <data_adapter> for each data adapter in the group -->
                        <data_adapter>

                                <!-- display name for data adapter -->
                                <key>peptide</key>

                                <!-- class for data adapter plugin -->
                                <class>org.bbop.apollo.web.dataadapter.fasta.FastaDataAdapter</class>

                                <!-- required permission for using data adapter
                                available options are: read, write, publish -->
                                <permission>read</permission>

                                <!-- configuration file for data adapter -->
                                <config>/config/fasta_config.xml</config>

                                <!-- options to be passed to data adapter -->
                                <options>output=file&amp;format=gzip&amp;seqType=peptide</options>

                        </data_adapter>
                        <data_adapter>

                                <!-- display name for data adapter -->
                                <key>cDNA</key>

                                <!-- class for data adapter plugin -->
                                <class>org.bbop.apollo.web.dataadapter.fasta.FastaDataAdapter</class>

                                <!-- required permission for using data adapter
                                available options are: read, write, publish -->
                                <permission>read</permission>

                                <!-- configuration file for data adapter -->
                                <config>/config/fasta_config.xml</config>

                                <!-- options to be passed to data adapter -->
                                <options>output=file&amp;format=gzip&amp;seqType=cdna</options>

                        </data_adapter>
                        <data_adapter>

                                <!-- display name for data adapter -->
                                <key>CDS</key>

                                <!-- class for data adapter plugin -->
                                <class>org.bbop.apollo.web.dataadapter.fasta.FastaDataAdapter</class>

                                <!-- required permission for using data adapter
                                available options are: read, write, publish -->
                                <permission>read</permission>

                                <!-- configuration file for data adapter -->
                                <config>/config/fasta_config.xml</config>

                                <!-- options to be passed to data adapter -->
                                <options>output=file&amp;format=gzip&amp;seqType=cds</options>

                        </data_adapter>

                </data_adapter_group>

FOURTH
;
                print $newconfigfh $_;
            }
            else {
                print $newconfigfh $_;
            }

        } #close the file looping while

        close $fh;
        close $newconfigfh;

        copy ($configfile, "$configfile.old") or die $!;
        copy ($newconfig,  $configfile)       or die $!;

        return;
    }

