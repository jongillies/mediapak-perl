#!/usr/bin/perl -w
use strict;

use vars qw ($DEBUG);

sub gatherIncludeList
{
	my $includeExt = shift;

	my @includeExtList;

	# Process any include extentsions
	if ($includeExt)
	{
		my @exts = split (/,/ , $includeExt);
	
		foreach my $ext (@exts)
		{
			print (STDOUT "INFO\tConsidering Extentions: $ext\n") if $DEBUG;
			
			push (@includeExtList, "*." . $ext);
		}
	}
	else
	{
		print (STDOUT "INFO\tConsidering all files.\n") if $DEBUG;
	
		push (@includeExtList, "*");
	}
	return (@includeExtList);
}
1;