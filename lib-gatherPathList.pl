#!/usr/bin/perl -w
use strict;
use File::Spec;

sub gatherPathList
{
	my @pathList;

	# Gather the search list from the command line and add to the @pathList array
	# Don't bother checking of the path exists, another function will do that
	foreach my $path (@ARGV)
	{
			push (@pathList, File::Spec->canonpath($path));
	}

	# Valdate we have at lease 1 path to search
	if ( @pathList < 1 )
	{
		print (STDOUT "WARNING\tYou must specify 1 or more paths on the command line!\n");
		usage();
	}

	return (@pathList);
}
1;