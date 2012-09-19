#!/usr/bin/perl -w
my $PROGRAM_NAME="linkfiles";
my $PROGRAM_DESC="Create symbolic links from files";
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


##############################################################################
# Global variables
##############################################################################
my %option = ();                            # Command line options hash
my $status = getopts('df', \%option);  # Parse the options

my $DEBUG = $option{d};                 # Turn on debug if -d is an option
my $OPTION_USE_FOLDERS = $option{f};    # Create output folder hierarchy

#my $STDIN_REDIRECTED = ! -t STDIN;      # Is STDIN redirected from a file?

my @fileSpec;                           # Used by the "find" command
my @pathList;

my $CACHE_FOLDER;                       # Subfolder name to store metadata

if ( $RUNNINGWINDOWS == 1 )
{
	$CACHE_FOLDER="_mc";                # Windows does not like "." files.
}
else
{
	$CACHE_FOLDER=".mc";                # UNIX likes "." files.. they are "hidden"
}

##############################################################################


my $sourcePath = $ARGV[0];
push (@pathList, $sourcePath);
my $destPath = $ARGV[1];

push (@fileSpec, "*.*");



##############################################################################
# Die if command line parsing fails (status) or we dont' have at least 1 path
##############################################################################
if ($status == 0 or @pathList < 1 or !defined($destPath) or !defined($sourcePath))
{
	print ("$PROGRAM_NAME (Build $PROGRAM_VERSION) - $PROGRAM_DESC\n");
	print ("Usage: $PROGRAM_NAME [-d] SourceFolder DestinationFolder\n" );
	print ("        [-d] will turn on debug messages sent to STDERR\n");
	exit (0);
}

#
# Create some temporary string replace translations
# This will allow us to replace the sourceDir with destDir and preserve the
# exiting folder hierarchy for the sourceDir
#
my $fooSourcePath = $sourcePath;
$fooSourcePath =~ s/\\/__BACKSLASH__/g;

my $fooDestPath = $destPath;
$fooDestPath =~ s/\\/__BACKSLASH__/g;

print (STDOUT "INFO\tRaw parameters: @ARGV\n") if $DEBUG;

foreach my $path (@pathList)
{
	print (STDOUT "INFO\tSearching: $path\n") if $DEBUG;    
}
##############################################################################
    

##############################################################################
# Search the path list and generate the metadata XML files
##############################################################################

my @files = find (name => [ @fileSpec ] , in => [ @pathList ]);

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
	if ($directory =~ /${CACHE_FOLDER}$/)
	{
		next;
	}

	my $destFile;
	
	if ( $OPTION_USE_FOLDERS )
	{
		$destFile = $file;
		$destFile =~ s/\.flac$/.wav/;
		$destFile =~ s/\\/__BACKSLASH__/g;
		$destFile =~ s/$fooSourcePath/$fooDestPath/;
		$destFile =~ s/__BACKSLASH__/\\/g;
	}
	else
	{
		$destFile = File::Spec->catfile ($destPath, $fileName);
	}

	$destFile = File::Spec->canonpath( $destFile );


	print (STDOUT "Found $fileName\n");

	if ( ! -e $destFile )
	{
		symlink ( $file, $destFile);
		print (STDOUT "Create Link [$file] to [$destFile]\n");
	}
	else
	{
		print (STDOUT "Link Exists [$destFile]\n");
	}
}



