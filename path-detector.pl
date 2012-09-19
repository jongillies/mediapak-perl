#!/usr/bin/perl -w
my $PROGRAM_NAME="path-detector";
my $PROGRAM_DESC="Validate Mediapk Paths are not too long";
my $PROGRAM_VERSION="_____VERSION_____";

use strict;
use Getopt::Std;
use File::Find::Rule;

use File::Spec;
use File::Basename;
use File::Path;

# What OS am I running? ( $^O is the perlvar for OSType)
my $RUNNINGWINDOWS = 0; # Assume we are NOT on Windows
if ( $^O =~ /MS/ )      # If the OS string has "MS" in it, assume Windows.
{
	$RUNNINGWINDOWS = 1;  
}

#
# The "FindBin" command will allow us to locate our "require"
# modules in the same folder as the executable, this way we
# don't have any pathing issues
#
use FindBin ();
use lib "$FindBin::Bin";

##############################################################################
# Global variables
##############################################################################
my %option = ();                             # Command line options hash
my $status = getopts('du', \%option);        # Parse the options

my $DEBUG = $option{d};                 # Turn on debug if -d is an option

my $STDIN_REDIRECTED = ! -t STDIN;      # Is STDIN redirected from a file?

my @pathList;                           # Declare the path list to search
my @fileSpec;                           # Used by the "find" command

my $CACHE_FOLDER;                       # Subfolder name to store metadata
my $SEPARATOR;                          # Directory Separator

my $WINDOWS_CACHE_FOLDER="_mc";         # Windows does not like "." files.
my $UNIX_CACHE_FOLDER=".mc";            # UNIX likes "." files.. they are "hidden"

my $fileCount = 0;

my $CACHE_EXTENTION=".xml";             # Extention of metadata file

my $MAX_WIN_FILE_LENGTH=260;            # http://forums.microsoft.com/MSDN/ShowPost.aspx?PostID=399638&SiteID=1
my $MAX_WIN_DIR_LENGTH=248;             # http://forums.microsoft.com/MSDN/ShowPost.aspx?PostID=399638&SiteID=1

##############################################################################

if ( $RUNNINGWINDOWS == 1 )
{
	$CACHE_FOLDER= $WINDOWS_CACHE_FOLDER;
	$SEPARATOR = "\\";
}
else
{
	$CACHE_FOLDER= $UNIX_CACHE_FOLDER;
	$SEPARATOR = "\/";
}

##############################################################################
# Build a list of paths from STDIN and/or the command line
##############################################################################
if ($STDIN_REDIRECTED)
{
	print (STDOUT "INFO\tSTDIN is redirected\n") if $DEBUG;

	# Read all lines from STDIN into the pathList array 
	while (my $path = <STDIN>)
	{
		chomp ($path);
		if (-e $path)
		{
			push (@pathList, File::Spec->canonpath($path));
		}
		else
		{
			print (STDERR "WARNING\t$path does not exist.\n" );
		}
	}
}
else
{
	print (STDOUT "INFO\tSTDN is NOT redirected\n") if $DEBUG;
}

# Add any paths from the command line to the pathList array
foreach my $path (@ARGV)
{
	if (-e $path)
	{
		push (@pathList, File::Spec->canonpath($path));
	}
	else
	{
		print (STDERR "WARNING\t$path does not exist.\n" );
	}
}
##############################################################################


##############################################################################
# Die if command line parsing fails (status) or we dont' have at least 1 path
##############################################################################
if ($status == 0 or @pathList < 1)
{
	print ("$PROGRAM_NAME (Build $PROGRAM_VERSION) - $PROGRAM_DESC\n");
	print ("Usage: $PROGRAM_NAME [-d] [path ...] and/or [ < pathtxtfile]\n" );
	print ("        [path] is a file path to search\n");
	print ("        -d debug mode\n");
	print ("        NOTE: paths can also be on STDIN from a text file.\n");
	exit (0);
}

print (STDOUT "INFO\tRaw parameters: @ARGV\n") if $DEBUG;

##############################################################################

# We are only searching cache files
push (@fileSpec, "*.*");

##############################################################################
# Search the path list and generate the metadata XML files
##############################################################################

foreach my $searchPath (@pathList)
{
	print ("INFO\tSearching $searchPath...\n");

	my @files = find (name => [ @fileSpec ] , in => $searchPath);

	my $startTime;
	my $sha1;

	my $cache;

	foreach my $file (@files)
	{
		# Ignore directories
		if (-d $file)
		{
			next;
		}
	
		$file = File::Spec->rel2abs($file);   # Dereference the file path
		$file = File::Spec->canonpath($file); # Make name pretty for the platform
	
		my $directory = dirname($file);       # Directory of $file
		my $fileName = basename($file);       # File name of $file

		# Don't recurse into folders that are cache folders
		if ($directory =~ /\/${UNIX_CACHE_FOLDER}$/)
		{
			next;
		}
	
		# Don't recurse into folders that are cache folders
		if ($directory =~ /\\${WINDOWS_CACHE_FOLDER}$/)
		{
			next;
		}

		my $cacheFolder = File::Spec->catfile ($directory, $CACHE_FOLDER); # Cache folder Name
		my $cacheFile = $fileName . $CACHE_EXTENTION;                      # Cache file name
		my $cachePath = File::Spec->catfile ($cacheFolder, $cacheFile);    # Absolute path to cache file

		$fileCount++;


		my $fileLen = length($file);
		my $cacheLen = length($cachePath);

		my $fileDir = basename($file);
		my $cacheDir = basename($cachePath);

		my $fileDirLen = length($fileDir);
		my $cacheDirLen = length($cacheDir);

		print ("DEBUG\tfileLen=$fileLen\tcacheLen=$cacheLen\tfileDirLen=$fileDirLen\tcacheDirLen=$cacheDirLen\n") if $DEBUG;
		print ("DEBUG\t$file\n") if $DEBUG;
		print ("DEBUG\t$cachePath\n") if $DEBUG;

		if ( $fileLen > $MAX_WIN_FILE_LENGTH )
		{
			print (STDOUT "WARNING\t$fileName > $MAX_WIN_FILE_LENGTH in characters.  May cause problems in Windows!\n");
		}

		if ( $cacheLen > $MAX_WIN_FILE_LENGTH )
		{
			print (STDOUT "WARNING\t$cachePath > $MAX_WIN_FILE_LENGTH in characters.  May cause problems in Windows!\n");
		}

		if ( $fileDirLen > $MAX_WIN_DIR_LENGTH )
		{
			print (STDOUT "WARNING\t$fileDir > $MAX_WIN_FILE_LENGTH in characters.  May cause problems in Windows!\n");
		}

		if ( $cacheDirLen > $MAX_WIN_DIR_LENGTH )
		{
			print (STDOUT "WARNING\t$cacheDir > $MAX_WIN_FILE_LENGTH in characters.  May cause problems in Windows!\n");
		}
		
#		print ("FILE  is: $fileName\n");
#		print ("CACHE is: $cachePath");

	} # foreach my $file (@files)

}

print ("INFO\tFile Count is $fileCount\n");



