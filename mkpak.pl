#!/usr/bin/perl -w
use strict;
use File::Spec;
use Getopt::Std;

#
# Program Identification Section (____VERSION____ is replaced with the subversion revision number when the package is built)
#                                (____DATE____ is replaced with package build time stamp)
#
my $PROGRAM_NAME="mkpak";
my $PROGRAM_DESC="Generate mediapak from xml data";
my $PROGRAM_VERSION="v2 _____VERSION_____ _____DATE_____";

# Use FindBin to locate our "require" modules in the scripts run directory
use FindBin ();
use lib "$FindBin::Bin";

# Reference and include global variables
use vars qw ($DEBUG $CACHE_FOLDER $CACHE_EXTENTION $RUNNINGWINDOWS $OFFLINE_CACHE);
require ("lib-globals.pl");

# Usage subroutine
sub usage
{
	print ("$PROGRAM_NAME (Build $PROGRAM_VERSION) - $PROGRAM_DESC\n");
	print ("Usage: $PROGRAM_NAME [-d] [-i include-ext] [-c offline-cache-folder] [path] [path ...]\n" );
	print ("        [-d] will turn on debug messages sent to STDERR\n");
	print ("        [-i] is a comma delimited list of file extentsions to match (Case Sensitive!)\n");
	print ("        [-c] is the off-line folder to cache metadata summary for ckpak\n");
	print ("        [path] is a file path to search\n");
	print ("        Redirect the output of this file to create your media pack file.\n");
	exit (0);
}



#
# Local Variables
my %cmdline_option = ();                # Command line options hash
my @pathList;                           # List of paths to search
my @includeExtList;                     # List of file extentions to match
my $includeExt;                         # Include Extension cmd asdfasdfasdf
my $overwrite;                          # -o overwrite metadata (like running the 1st time)
my $valid_sha1;                         # -s validate the sha1

# Parse and validate command line options
if (! getopts('di:c:', \%cmdline_option) )
{
	print (STDOUT "WARNING\tInvalid commmand line parameters!\n");
	usage ();
}

# Set local and global variables from command line
$OFFLINE_CACHE = $cmdline_option{c};
$DEBUG = $cmdline_option{d};
$includeExt = $cmdline_option{i};

require ("lib-gatherPathList.pl");
@pathList = gatherPathList();

require ("lib-gatherIncludeList.pl");
@includeExtList = gatherIncludeList($includeExt);

if ( $DEBUG )
{
	print ("INFO\tARG -d is $DEBUG\n") if defined ($overwrite);
	print ("INFO\tARG -i is $includeExt\n") if defined ($includeExt);
	foreach my $ext (@includeExtList)
	{
		print ("INFO\tARG Include Extentsions: $ext\n");
	}
	print ("INFO\tARG -c is $OFFLINE_CACHE\n") if defined ($OFFLINE_CACHE);
	foreach my $path (@pathList)
	{
		print ("INFO\tARG Searching: $path\n");
	}
}

require ("lib-getMetaDataList.pl");
require ("lib-writePakFile.pl");

my %metaData = getMetaDataList (\@pathList, \@includeExtList);

writePakFile (\%metaData);

print (STDOUT "INFO\tDone!\n") if $DEBUG;

1;


