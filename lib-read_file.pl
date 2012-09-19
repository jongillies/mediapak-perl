#!/usr/bin/perl -w
use strict;

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

1;
