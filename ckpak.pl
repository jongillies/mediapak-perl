#!/usr/bin/perl -w
use strict;
use File::Spec;
use Getopt::Std;

#
# Program Identification Section (____VERSION____ is replaced with the subversion revision number when the package is built)
#                                (____DATE____ is replaced with package build time stamp)
#
my $PROGRAM_NAME="ckpak";
my $PROGRAM_DESC="Validate a mediapak from xml data";
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
	print ("Usage: $PROGRAM_NAME [-d] [-i include-ext] [-q] [-c offline-cache-folder] [-f packFileToCheck] [path] [path ...]\n" );
	print ("        [-d] will turn on debug messages sent to STDERR\n");
	print ("        [-i] is a comma delimited list of file extentsions to match\n");
	print ("        [-q] quiet mode.  Only print the result.\n");
	print ("        [-c] is the off-line folder to cache metadata summary for ckpak\n");
	print ("        [-f packFileToCheck] - Actual .pak file to compare against\n");
	print ("        [path] is a file path to search\n");
	exit (0);
}

#
# Local Variables
my %cmdline_option = ();                # Command line options hash
my $cmdline_status;                     # Command line parsing status
my @pathList;                           # List of paths to search
my @includeExtList;                     # List of file extentions to match
my $includeExt;                         # Include Extension cmd asdfasdfasdf
my $overwrite;                          # -o overwrite metadata (like running the 1st time)
my $valid_sha1;                         # -s validate the sha1
my $pakFile;                            # Pak file to check
my $quietOperation;                     # -q quiet, only print the result

# Parse and validate command line options
if (! getopts('dqi:f:c:', \%cmdline_option))
{
	print (STDOUT "WARNING\tInvalid commmand line parameters!\n");
	usage ();
}


# Set local and global variables from command line
$OFFLINE_CACHE = $cmdline_option{c};
$DEBUG = $cmdline_option{d};
$includeExt = $cmdline_option{i};
$pakFile = $cmdline_option{f};
$quietOperation = $cmdline_option{q};

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
require ("lib-readPakFile.pl");

my %metaData = getMetaDataList (\@pathList, \@includeExtList);

my %pakData;
%pakData = readPakFile($pakFile);

my $totalErrors = 0;
my $totalFiles = 0;

#
# Verify files in the "pakList" exist in the localFiles hash
#
for my $sha1 ( keys %pakData )
{
#	my ( $filename, $path) = split (/\t/, $pakData{$sha1});

	$totalFiles++;

	if ( $metaData{$sha1} )
	{
		my $cache = $metaData{$sha1};

		print ("FOUND_LOCAL\t" . $cache->{sha1} . "\t$cache->{name}\t$cache->{directory}\n") if ! $quietOperation;
	}
	else
	{
		print ("NOT_FOUND_LOCAL\t$sha1\t$pakData{$sha1}->{name}\t$pakData{$sha1}->{directory}\n") if ! $quietOperation;
		$totalErrors++;
	}
}

my $errorMessage = "";

if ( $totalErrors > 0 )
{
	$errorMessage = "Get files from remote system!"
}

print ("$totalErrors total errors from $totalFiles remote files.  $errorMessage\n");


$totalErrors = 0;
$totalFiles = 0;

#
# Verify the localFiles existin the pakList (Reverse from above)
#

for my $sha1 ( keys %metaData )
{
#	my ( $filename, $path) = split (/\t/, $localFile{$sha1});

	$totalFiles++;

	if ( $pakData{$sha1} )
	{
		my $cache = $pakData{$sha1};

		print ("FOUND_REMOTE\t$sha1\t" . $cache->{name} . "\t$cache->{directory}\n") if ! $quietOperation;
	}
	else
	{
		print ("NOT_FOUND_REMOTE\t$sha1\t" . $metaData{$sha1}->{name} . "\t" . $metaData{$sha1}->{directory} . "\n") if ! $quietOperation;
		$totalErrors++;
	}
}

$errorMessage = "";

if ( $totalErrors > 0 )
{
	$errorMessage = "Send files to remote system! (cpmissing)"
}

print ("$totalErrors total errors from $totalFiles local files.  $errorMessage\n");

print (STDOUT "INFO\tDone!\n") if $DEBUG;

1;


