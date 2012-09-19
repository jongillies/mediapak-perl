#!/usr/bin/perl -w
my $PROGRAM_NAME="cleaner";
my $PROGRAM_DESC="Clean and validate .xml cach files";
my $PROGRAM_VERSION="v2 _____VERSION_____ _____DATE_____";

use strict;
use Getopt::Std;
use File::Find::Rule;

use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Spec;
use File::Basename;
use File::Path;
#use XML::Simple;

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

require ("lib-dumbassreadcache.pl");

##############################################################################
# Global variables
##############################################################################
my %option = ();                             # Command line options hash
my $status = getopts('du', \%option);  # Parse the options

my $DEBUG = $option{d};                 # Turn on debug if -d is an option
my $UNLINK = $option{u};                # Unlink Orphan Files

my $STDIN_REDIRECTED = ! -t STDIN;      # Is STDIN redirected from a file?

my @pathList;                           # Declare the path list to search
my @fileSpec;                           # Used by the "find" command

my $CACHE_FOLDER;                       # Subfolder name to store metadata
my $SEPARATOR;                          # Directory Separator

my $WINDOWS_CACHE_FOLDER="_mc";         # Windows does not like "." files.
my $UNIX_CACHE_FOLDER=".mc";            # UNIX likes "." files.. they are "hidden"

my $fileCount = 0;

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
	print ("Usage: $PROGRAM_NAME [-u] [path ...] and/or [ < pathtxtfile]\n" );
	print ("        [path] is a file path to search\n");
	print ("        -u will remove orphan xml files in the cache folders\n");
	print ("        NOTE: paths can also be on STDIN from a text file.\n");
	exit (0);
}

print (STDOUT "INFO\tRaw parameters: @ARGV\n") if $DEBUG;

##############################################################################

# We are only searching cache files
push (@fileSpec, "*.xml");

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

		my @dirParts;

		# Can't figure out if perl has a module to split a whole directory
		# path using the appropriate spearator.  This is hack that will
		# work on Windows and UNIX
		#
		if ( $RUNNINGWINDOWS == 1 )
		{
			@dirParts = split(/\\/, $directory); # Split on \
		}
		else
		{
			@dirParts = split(/\//, $directory); # Split on /
		}

		# If this isn't my platforms cache folder, get out!
		if ( ! ($dirParts[@dirParts -1] eq $CACHE_FOLDER) )
		{
			next;
		}

		$fileCount++;

		$cache = dumbAssReadCache ($file);

		# Construct a path to the source file in the parent directory.
		my $sourceDir = $directory;
		$sourceDir =~ s/${SEPARATOR}${CACHE_FOLDER}$//;

		# Remove the xml extention
		my $sourceFileName = $fileName;
		$sourceFileName =~ s/.xml$//;

		# Create a complete file path
		my $sourceFile = File::Spec->catfile ($sourceDir, $sourceFileName);


		if ( $cache->{name} ne $sourceFileName )
		{
			print ("ERROR\tXML file name does not match source file name XML[$cache->{name}], Filename[$file]!\n");
		}

		# Check to see if the parent exists
		if ( ! -e $sourceFile )
		{
			print ("ERROR\tOrphan xml file found [$file] for [$sourceFile]\n");

			if ( $UNLINK )
			{
				print ("UNLINKED\t$file\n");
				unlink ($file);
			}
		}
		else
		{
			print ("OK\t$sourceFile\n");
		}

	} # foreach my $file (@files)

}

print ("INFO\tFile Count is $fileCount\n");


