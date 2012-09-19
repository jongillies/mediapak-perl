#!/usr/bin/perl -w
use strict;
use File::Spec;
use Getopt::Std;

#
# Program Identification Section (____VERSION____ is replaced with the subversion revision number when the package is built)
#                                (____DATE____ is replaced with package build time stamp)
#
my $PROGRAM_NAME="gencache";
my $PROGRAM_DESC="Generate .xml cach files for data";
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
	print ("Usage: $PROGRAM_NAME [-d] [-i include-ext] [-c offline-cache-folder] [-s | -o] [path] [path ...]\n" );
	print ("        [-d] will turn on debug messages sent to STDERR\n");
	print ("        [-o] will overwrite exiting xml files, like running for the 1st time\n");
	print ("        [-i] is a comma delimited list of file extentsions to match (Case Sensitive!)\n");
	print ("        [-c] is the off-line folder to cache metadata summary for ckpak\n");
	print ("        [-s] will validate using the SHA1, takes a long time.\n");
	print ("        [path] is a file path to search\n");
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
if (! getopts('dstoi:c:', \%cmdline_option) )
{
	print (STDOUT "WARNING\tInvalid commmand line parameters!\n");
	usage ();
}

# Set local and global variables from command line
$OFFLINE_CACHE = $cmdline_option{c};
$DEBUG = $cmdline_option{d};
$includeExt = $cmdline_option{i};
$overwrite = $cmdline_option{o};
$valid_sha1 = $cmdline_option{s};

# Make sure these are defined for later use
$overwrite = 0 if !defined ($overwrite);
$valid_sha1 = 0 if !defined ($valid_sha1);

# Validate program modes
if ( $overwrite && $valid_sha1 )
{
	print (STDERR "WARNING\t-c and -s are mutually exclusive, choose 1 or the other\n");
	usage();
}

require ("lib-gatherPathList.pl");
@pathList = gatherPathList();

require ("lib-gatherIncludeList.pl");
@includeExtList = gatherIncludeList($includeExt);


if ( $DEBUG )
{
	print ("INFO\tARG -d is $DEBUG\n") if defined ($overwrite);
	print ("INFO\tARG -o is $overwrite\n") if defined ($overwrite);
	print ("INFO\tARG -i is $includeExt\n") if defined ($includeExt);
	foreach my $ext (@includeExtList)
	{
		print ("INFO\tARG Include Extentsions: $ext\n");
	}
	print ("INFO\tARG -c is $OFFLINE_CACHE\n") if defined ($OFFLINE_CACHE);
	print ("INFO\tARG -s is $valid_sha1\n") if defined ($valid_sha1);
	foreach my $path (@pathList)
	{
		print ("INFO\tARG Searching: $path\n");
	}
}

require ("lib-createMetadata.pl");

my %metaData = createMetaData (\@pathList, \@includeExtList, $overwrite, $valid_sha1);

# Update Cache Files
updateCacheFiles (\%metaData, \@pathList);

print (STDOUT "INFO\tDone!\n");

1;


