#!/usr/bin/perl -w
use strict;

use File::Find::Rule;
use File::Basename;

# Global Variables
use vars qw($DEBUG $WINDOWS_CACHE_FOLDER $UNIX_CACHE_FOLDER);

#
# Returns an array of file paths given a pathList and a fileSpec
#
sub getFileList 
{
	my ($pathList, $fileSpec) = @_;

	my @validPathList;

	foreach my $path (@$pathList)
	{
		if (-e $path)
		{
			push (@validPathList, File::Spec->canonpath($path));
		}
		else
		{
			print (STDERR "WARNING\t$path does not exist.\n" );
		}
	}

	my @fileList = ();

	foreach my $path (@validPathList)
	{
		if ( -e $path )
		{
			print ("INFO\tSearching: [$path]\n") if $DEBUG;
		}
		else
		{
			print (STDERR "WARNING\tPath does not exist! [$path]\n");
			next;
		}

		my @files = find (name => [ @$fileSpec ] , in => [ @validPathList ]);

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

			# Don't recurse into folders that begin with . or _
			if ($directory =~ m/\/${UNIX_CACHE_FOLDER}$/ | $directory =~ /\\${WINDOWS_CACHE_FOLDER}$/)
			{
				next;
			}

			print ("INFO\tReading $file\n") if $DEBUG;

			push (@fileList, $file);

		}
	}

	return (@fileList);
}

1;