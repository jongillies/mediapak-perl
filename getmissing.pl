#!/usr/bin/perl -w
my $PROGRAM_NAME="getmissing";
my $PROGRAM_DESC="Create script to copy missing files from remote system";
my $PROGRAM_VERSION="_____VERSION_____";

use strict;
use Getopt::Std;
use File::Find::Rule;
use Env;

use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Spec;
use File::Basename;
use File::Path;
#use XML::Simple;


my $PATH_SEPARATOR = ":";  # Used on UNIX

# What OS am I running? ( $^O is the perlvar for OSType)
my $RUNNINGWINDOWS = 0; # Assume we are NOT on Windows
if ( $^O =~ /MS/ )      # If the OS string has "MS" in it, assume Windows.
{
	$RUNNINGWINDOWS = 1;  
	$PATH_SEPARATOR = ";";
}

# The read_file in File::Slurp did not work like I wanted it to
sub read_file
{
	my( $filename ) = shift;
	my @lines;

	open( FILE, "< $filename" ) or die "Can't open $filename : $!";

	while( <FILE> )
	{
		s/#.*//;            # ignore comments by erasing them
		next if /^(\s)*$/;  # skip blank lines

		chomp;              # remove trailing newline characters

		push @lines, $_;    # push the data line onto the array
	}

	close FILE;

	return @lines;  # Use a \@ to return a reference, in original example
}
    
##############################################################################
# Global variables
##############################################################################
my %option = ();                        # Command line options hash
my $status = getopts('dquwf:', \%option);  # Parse the options

my $DEBUG = $option{d};                 # Turn on debug if -d is an option
my $QUIET = $option{q};                 # Quiet option
my $UNIX = $option{u};                  # Unix script output
my $WINDOWS = $option{w};               # Windows script output
my $ERROR_FILE = $option{f};            # Error file from ckpak.pl


##############################################################################


##############################################################################
# Die if command line parsing fails (status) or we dont' have at least 1 path
##############################################################################
if ( ($status == 0) || (!defined($ERROR_FILE)) )
{
	print ("$PROGRAM_NAME (Build $PROGRAM_VERSION) - $PROGRAM_DESC\n");
	print ("Usage: $PROGRAM_NAME [-d] [-q] [-u -w] [-f missingFileReport]\n" );
	print ("        [-q] quiet mode.  Only print the result.\n");
	print ("        [-d] will turn on debug messages sent to STDERR\n");
	print ("        [-u -w] -u = Unix script, -w = WINDOWS script\n");
	print ("        [-f] Missing file report generated by ckpak.pl.\n");
	exit (0);
}



print (STDOUT "INFO\tRaw parameters: @ARGV\n") if $DEBUG;

#
# Read the error file into errorList
#
my @errorList = read_file($ERROR_FILE);

my $totalErrors = 0;
my $totalFiles = 0;

if ( $WINDOWS )
{
	print ("REM\n");
	print ("REM Windows script to copy files missing from remote system\n");
	print ("REM\n");
	print ("\n");
	print ("SET DEST=" . '%1%' . "\n");
	print ("\n");
	print ("echo Specify the destination to copy to on the command line.\n");
	print ("echo The destination to copy to is set to: " . '%DEST%' . "\n");
	print ("echo Please edit the batch file if this is not correct\n");
	print ("pause\n");
	print ("\n");
}

if ( $UNIX )
{
	print ("#!/bin/bash\n");
	print ("# UNIX script to copy files missing from remote system\n");
	print ("#\n");
	print ("\n");
	print ("export DEST=" . '$1' . "\n");
	print ("\n");
	print ("echo Specify the destination to copy to on the command line.\n");
	print ("echo The destination to copy to is set to: " . '$DEST' . "\n");
	print ("echo Please edit the script file if this is not correct\n");
	print ("pause\n");
	print ("\n");
}

#
#
foreach my $line (@errorList)
{
	chomp ($line);

	$totalFiles++;
	
	if ( $line =~ /NOT_FOUND_LOCAL/ )
	{
		(my $status, my $sha1, my $filename, my $path) = split (/\t/, $line, 4);

		if ( $WINDOWS )
		{
			print ('copy "' . $path . "\\" . $filename . '" "' . '%DEST%' .'"' . "\n");
		}

		if ( $UNIX )
		{
			print ('cp "' . $path . "/" . $filename . '" "' . '%DEST%' .'"' . "\n");
		}
	}
}



