#!/usr/bin/perl -w
use strict;

# Global Variables
use vars qw($DEBUG $CACHE_FOLDER $CACHE_EXTENTION);

use File::Basename;
use File::Spec;

require ("lib-getFileList.pl");
require ("lib-generateCacheFile.pl");
require ("lib-updateCacheFile.pl");
require ("lib-loadCache.pl");
require ("lib-updateCacheFiles.pl");
require ("lib-dumbassreadcache.pl");

#
# Given a list of files, read the cache data
#
sub createMetaData
{
	my ($pathList, $spec, $regenerateOption, $valid_sha1) = @_;

	my @fileList = getFileList ($pathList, $spec);

	my %metaData;

	%metaData = loadCache ($pathList);

	# Attempt to load the cache file if the path is not on-line

	foreach my $file (@fileList)
	{
		print ("FILE: $file\n") if $DEBUG;

		my $directory = dirname($file);       # Directory of $file
		my $fileName = basename($file);       # File name of $file

		my $cacheFolder = File::Spec->catfile ($directory, $CACHE_FOLDER); # Cache folder Name
		my $cacheFile = $fileName . $CACHE_EXTENTION;                      # Cache file name
		my $cachePath = File::Spec->catfile ($cacheFolder, $cacheFile);    # Absolute path to cache file

		my $cache;

		if ( $regenerateOption )
		{
			generateCacheFile ( $file, $cachePath );

			# Read it again!
			$cache = dumbAssReadCache($cachePath);

			my $sha1 = $cache->{sha1};

			if ( $metaData{$cache->{sha1}} )
			{
				print (STDERR "DUPLICATE_SHA1\t(createMetaData) Duplicate SHA1 detected, possible duplicate file! This File:[$file] Cache File: ". $metaData{$sha1}->{path} ."\n");
			}
			else
			{
				$metaData{$sha1} = $cache;
			}
		}
		else
		{
			if (! -e $cachePath)
			{

				generateCacheFile ( $file, $cachePath );

				# Read it again!
				$cache = dumbAssReadCache($cachePath);

				my $sha1 = $cache->{sha1};

				if ( $metaData{$cache->{sha1}} )
				{
					print (STDERR "DUPLICATE_SHA1\tDuplicate SHA1 detected, possible duplicate file! This File:[$file] Cache File: ". $metaData{$sha1}->{path} ."\n");
				}
				else
				{
					$metaData{$sha1} = $cache;
				}
			}
			else
			{
				if ( -z $cachePath )
				{
					print (STDERR "WARNING\t$cachePath is zero bytes\n");
				}

				my $cache = dumbAssReadCache($cachePath);

				# Get file metadata
				( my $dev, my $ino, my $mode, my $nlink, my $uid, my $gid, my $rdev,
				  my $size, my $atime, my $mtime, my $ctime, my $blksize, my $blocks )
				  = stat($file);

				if ( $valid_sha1 )
				{
					print (STDOUT "INFO\tCalculating SHA1 checksum ($file)...\n");
					my $sha1 = filedigest ($file);
					my $VALID_SHA1 = ($sha1 eq $cache->{sha1});
					
					if ( ! $VALID_SHA1 )
					{
						print (STDERR "ERROR\tSHA1 does not match!! Cache: $cache->{sha1} File: $sha1 for $file\n");
					}
					else
					{
						print (STDOUT "INFO\tSHA1 is valid.\n");
					}
				}

				my $VALID_CACHE_FILE = ($mtime == $cache->{mtime}) && ($size == $cache->{size});

				if ( ! $VALID_CACHE_FILE )
				{
					print (STDERR "ERROR\tModify Time Stamps differ - File:$mtime Cache:$cache->{mtime}\t$cachePath\n") if ($mtime != $cache->{mtime});
					print (STDERR "ERROR\tSize differs - File:$size Cache:$cache->{size}\t$cachePath\n") if ($size != $cache->{size});
					
					# Re-generate Cache File!
					generateCacheFile ( $file, $cachePath );

					# Read it again!
					$cache = dumbAssReadCache($cachePath);
				}
				else
				{
					print (STDOUT "VALID\tValid Cache file for $file\n");

					my $updateCacheFile = 0;

					# Update actual Path and name in the cache structure
					# Verify the current Path is correct in the Cache File
					# if it is not, updated it in the hash and updated the file
					if ( $cache->{name} ne $fileName )
					{
						#print (STDERR "WARNING\tFile has been renamed from $cache->{name} to $fileName since current cache file created.\n");
						$cache->{name} = $fileName;
						$updateCacheFile = 1;
					}

					if ( $cache->{directory} ne $directory )
					{
						$cache->{name} = $fileName;
						#print (STDERR "WARNING\tFile has been moved from $cache->{directory} to $directory since current cache file created.\n");
						$cache->{directory} = $directory;
						$updateCacheFile = 1;
					}

					if ( $cache->{path} ne $file )
					{
						# Don't bother printing a warning here, one of the above must have been triggered.
						$cache->{path} = $file;
						$updateCacheFile = 1;
					}

					# I really don't think we need to update the cach file
					# as long as the paths are correct in the hash
					#
					#if ( $updateCacheFile == 1 )
					#{
					#	# Re-generate Cache File!
					#	updateCacheFile ( $cache, $cachePath );
					#	
					#	# Read it again!
					#	$cache = dumbAssReadCache($cachePath);
					#}

				}
				

				my $sha1 = $cache->{sha1};

				if ( $metaData{$cache->{sha1}} )
				{
					print (STDERR "DUPLICATE_SHA1\tDuplicate SHA1 detected, possible duplicate file! This File:[$file] Cache File: ". $metaData{$sha1}->{path} ."\n");
				}
				else
				{
					$metaData{$sha1} = $cache;
				}
			}
		}
	}

	# Update Cacheed Files
	updateCacheFiles (\%metaData, \@$pathList);

	return (%metaData);
}
1;
