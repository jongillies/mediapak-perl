#!/usr/bin/perl -w
use strict;

# Global Variables
use vars qw($OFFLINE_CACHE_OPT);

require ("lib-read_file.pl");

sub readPakFile
{
	my ($path) = @_;

	my %metaData;

	if ( ! -e $path )
	{
		print (STDERR "WARNING\t$path does not exist!\n");
		return (%metaData);
	}

	my @fileContents = read_file($path);

	# Put the file contents into the hash
	foreach my $line ( @fileContents )
	{

		(my $sha1, my $fileName, my $directory) = split (/\t/, $line);

		my $cache;
		$cache->{sha1} = $sha1;
		$cache->{name} = $fileName;
		$cache->{directory} = $directory;

		if ( $metaData{$cache->{sha1}} )
		{
			print (STDERR "DUPLICATE_SHA1\t(readPakFile) Duplicate SHA1 detected, possible duplicate file! This File:[$fileName] Cache File: ". $metaData{$cache->{sha1}}{fileName} ."\n");
		}
		else
		{
			$metaData{$sha1} = $cache;
		}
	}
	
	return (%metaData);
}

1;
