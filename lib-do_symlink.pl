#!/usr/bin/perl -w
use strict;

sub do_symlink
{
	(my $from, my $to) = @_;

	if (! -e $from )
	{
		print (STDERR "ERROR\t$from does not exist, can't create symlink\n");
		return (1);
	}

	if ( -e $to )
	{
		print (STDOUT "WARNING\t$to already exists!\n");
		
		if ( -l $to )
		{
			my $status = unlink ($to);
			if (!$status)
			{
				print (STDERR "FATAL\tUnable to unlink $to\n");
				return (1);
			}

		}
		else
		{
			print (STDERR "ERROR\t$to is not a symlink! Skipping.\n");
			return (1);
		}
	}		

	# Create a destination directory if it is emtpy
	my $directory = dirname($to);
	mkpath($directory);

	my $status = symlink ($from, $to);
	
	if (!$status)
	{
		print (STDERR "FATAL\tUnable to link [$from] -> [$to]\n");
		return (1);
	}

	print (STDOUT "SUCCESS\t[$from] -> [$to]\n");

	return (0);
	
	
}

1;
