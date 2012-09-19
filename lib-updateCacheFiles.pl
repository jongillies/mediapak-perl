#!/usr/bin/perl -w
use strict;

# Global Variables
use vars qw($DEBUG $OFFLINE_CACHE);

sub updateCacheFiles
{
	my ($metaData, $pathList) = @_;

	if ( ! $OFFLINE_CACHE ) { return };

	foreach my $path (@$pathList)
	{
		if ( -e $path )
		{
			my $mediaCacheFile = File::Spec->catfile ($OFFLINE_CACHE, sha1_hex($path));

			print (STDOUT "INFO\tCache File for $path is $mediaCacheFile\n") if $DEBUG;


			if ( open (CACHE, ">$mediaCacheFile" ) )
			{
				print ("INFO\tCaching path $path to file $mediaCacheFile\n") if $DEBUG;

				while ( my ($key, $value) = each(%$metaData) )
				{
					my $filePath = $value->{directory};

					if ( defined($filePath) && defined ($path) )
					{
						my $string = substr($filePath,0,length($path));
	
						if ( $string eq $path )
						{
							my $value = $$metaData{$key};
							print ( CACHE "$value->{sha1}\t$value->{name}\t$value->{directory}\n" );
						}
					}
				}
				close (CACHE);
			}
			else
			{
				print (STDERR "WARNING\tCould not open file [$mediaCacheFile], errno => $!\n");
			}
		}
	}
	
	
	
	
}
1;
