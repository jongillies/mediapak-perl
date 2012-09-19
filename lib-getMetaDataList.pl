#!/usr/bin/perl -w
use strict;

# Global Variables
use vars qw($DEBUG $CACHE_FOLDER $CACHE_EXTENTION);

use File::Basename;
use File::Spec;

require ("lib-getFileList.pl");
require ("lib-generateCacheFile.pl");
require ("lib-loadCache.pl");
require ("lib-updateCacheFiles.pl");
require ("lib-dumbassreadcache.pl");

#
# Given a list of files, read the cache data
#
sub getMetaDataList
{
	my ($pathList, $spec, $regenerateOption) = @_;

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

		if (-e $cachePath)
		{

			if ( -z $cachePath )
			{
				print (STDERR "WARNING\t$cachePath is zero bytes\n");
				next;
			}

			my $cache = dumbAssReadCache($cachePath);

			# Get file metadata
			( my $dev, my $ino, my $mode, my $nlink, my $uid, my $gid, my $rdev,
			  my $size, my $atime, my $mtime, my $ctime, my $blksize, my $blocks )
			  = stat($file);

			my $VALID_CACHE_FILE = ($mtime == $cache->{mtime}) && ($size == $cache->{size});

			if ( ! $VALID_CACHE_FILE || $regenerateOption )
			{
				print (STDERR "ERROR\tModify Time Stamps differ - File:$mtime Cache:$cache->{mtime}\t$cachePath\n") if ($mtime != $cache->{mtime});
				print (STDERR "ERROR\tSize differs - File:$size Cache:$cache->{size}\t$cachePath\n") if ($size != $cache->{size});
				
				# Re-generate Cache File!
				generateCacheFile ( $file, $cachePath );

				# Read it again!
				$cache = dumbAssReadCache($cachePath);
			}

			my $sha1 = $cache->{sha1};

			if ( $metaData{$cache->{sha1}} )
			{
				print (STDERR "DUPLICATE_SHA1\t(getMetaDataList) Duplicate SHA1 detected, possible duplicate file! This File:[$file] Cache File: ". $cache->{path} ."\n");
			}
			else
			{
				$metaData{$sha1} = $cache;
			}

			# Make sure and update the hash with the "real" values of where we found the file.
			$cache->{name} = $fileName;
			$cache->{name} = $fileName;
			$cache->{path} = $file;

		}
		else
		{
			print (STDERR "WARNING\tCache file does not exist for [$file]\n");
		}

	}

	return (%metaData);
}
1;
