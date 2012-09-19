#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use File::Find::Rule;

use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Spec;
use File::Basename;
use File::Path;
use XML::Simple;

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

require ("dumbassreadcache.pl");


##############################################################################
# Global variables
##############################################################################
my %option = ();                            # Command line options hash
my $status = getopts('dto', \%option);  # Parse the options

my $DEBUG = $option{d};                 # Turn on debug if -d is an option
my $TESTING = $option{t};               # Turn on testing if -t is an option
my $OVERWRITE = $option{o};             # Overwrite exiting metadata file

my $STDIN_REDIRECTED = ! -t STDIN;      # Is STDIN redirected from a file?

my @pathList;                           # Declare the path list to search
my @includeExtentions;                  # Declare file extentsions to match
my @fileSpec;                           # Used by the "find" command

my $CACHE_FOLDER;                       # Subfolder name to store metadata

my $WINDOWS_CACHE_FOLDER="_mc";         # Windows does not like "." files.
my $UNIX_CACHE_FOLDER=".mc";            # UNIX likes "." files.. they are "hidden"

if ( $RUNNINGWINDOWS == 1 )
{
	$CACHE_FOLDER= $WINDOWS_CACHE_FOLDER;
}
else
{
	$CACHE_FOLDER= $UNIX_CACHE_FOLDER 
}


my $CACHE_EXTENTION=".xml";             # Extention of metadata file
##############################################################################



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
	print ("Usage: $0 [-t] [-d] [-o] [path ...] and/or [ < pathtxtfile]\n" );
	print ("        [-t] will turn on the TEST mode\n");
	print ("        [-d] will turn on debug messages sent to STDERR\n");
	print ("        [-o] will overwrite exiting metadata files\n");
	print ("        NOTE: paths can also be on STDIN from a text file.\n");
	exit (0);
}



print (STDOUT "INFO\tRaw parameters: @ARGV\n") if $DEBUG;

foreach my $path (@pathList)
{
	print (STDOUT "INFO\tSearching: $path\n") if $DEBUG;    
}
##############################################################################


##############################################################################
# Search the path list and look for $CACHE_FOLDER directories
##############################################################################

# Initial search specfiication
push (@fileSpec, "*.xml");

my @files = find (name => [ @fileSpec ] , in => [ @pathList ]);

foreach my $file (@files)
{
	# Don't Cosider directories
	if ( (-d $file))
	{
		next;
	}

	$file = File::Spec->rel2abs($file);   # Dereference the file path
	$file = File::Spec->canonpath($file); # Make name pretty for the platform

	my $directory = dirname($file);       # Directory of $file
	my $fileName = basename($file);       # File name of $file

	# Only consider CACHE folder files
	# Ingore anything other than a folder that ends with _mc or .mc
	if ( !( ($directory =~ /\\${WINDOWS_CACHE_FOLDER}$/) || ($directory =~ /\/${UNIX_CACHE_FOLDER}$/) ) )
	{
		next;
	}

	#if ( ! $directory =~ /mc$/ )
	#{
	#	next;
	#}


	#
	# Read using the OLD method
	#
	my $cache = dumbAssReadCache ($file);


	my %file_data = (
		dev         => $cache->{dev},
		ino         => $cache->{ino},
		mode        => $cache->{mode},
		nlink       => $cache->{nlink},
		uid         => $cache->{uid},
		gid         => $cache->{gid},
		rdev        => $cache->{rdev},
		size        => $cache->{size},
		atime       => $cache->{atime},
		mtime       => $cache->{mtime},
		ctime       => $cache->{ctime},
		blksize     => $cache->{blksize},
		blocks      => $cache->{blocks},
		filename    => $cache->{name},
		directory   => $cache->{directory},
		path        => $cache->{path},
		sha1        => $cache->{sha1},
		computetime => $cache->{computetime}   
	);
	

	my $xsimple = XML::Simple->new();

	my $xml_string = $xsimple->XMLout(\%file_data, noattr => 1, RootName=>'file', xmldecl => '<?xml version="1.0"?>');

	print "Converted: $file\n";

	print $xml_string . "\n"; 

	if ( $OVERWRITE )
	{
		open (INFO, ">$file.foo" ) or die ("FATAL: could not open file [$file], errno => $! ");	# Open for output
		print (INFO $xml_string);
		close (INFO);
	}

}



