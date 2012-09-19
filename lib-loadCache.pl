#!/usr/bin/perl -w
use strict;

use File::Spec;
require ("lib-readPakFile.pl");

# Global Variables
use vars qw($DEBUG $OFFLINE_CACHE);

sub loadCache
{
	my ($pathList) = @_;

	my %metaData;

	if ( !defined($OFFLINE_CACHE) )
	{
		print (STDERR "WARNING\tOff-Line Cache is not specified (-c path)!\n");
		return (%metaData);
	}

	foreach my $path (@$pathList)
	{
		if (-e $path)
		{
			print (STDERR "INFO\t$path is on-line\n") if $DEBUG;
		}
		else
		{
			print (STDERR "WARNING\t$path not found.\n" );

			my $mediaCacheFile = File::Spec->catfile ($OFFLINE_CACHE, sha1_hex($path));

			if ( -e $mediaCacheFile )
			{
				print (STDERR "INFO\tLoading Cache File for $path with $mediaCacheFile\n");

				my %pathMetaData;

				%pathMetaData = readPakFile ($mediaCacheFile);
				
				while ((my $key, my $val) = each %pathMetaData)
				{
						$metaData{$key} = $val;
				}

			}
		}
	}
	
	return (%metaData);
}

1;
