#!/usr/bin/perl -w
use strict;

# Global Variables
use vars qw($OFFLINE_CACHE_OPT);

sub writePakFile
{
	my ($metaData, $path) = @_;

	if ( defined($path) )
	{
		open (CACHE, ">$path") or die "ERROR\tCould not open file [$path] to write, errno => $!\n";
	}
	
	for my $key ( keys %$metaData )
	{
		my $cache = $$metaData{$key};

		if ( defined($path) )
		{
			print ( CACHE "$cache->{sha1}\t$cache->{name}\t$cache->{directory}\n" );
		}
		else
		{
			if ( !defined($cache->{sha1}) )
			{
				print (STDERR "WARNING\tsha1 not defined!\n");
			}
			if ( !defined($cache->{name}) )
			{
				print (STDERR "WARNING\tname not defined!\n");
			}
			if ( !defined($cache->{directory}) )
			{
				print (STDERR "WARNING\tdirectory not defined! $cache->{name} $cache->{sha1}\n");
			}


			print ( "$cache->{sha1}\t$cache->{name}\t$cache->{directory}\n" );
		}
		
	}

	if ( defined($path) )
	{
		close (CACHE);
	}
}
1;