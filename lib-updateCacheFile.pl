#!/usr/bin/perl -w
use strict;

use File::Path;

sub updateCacheFile
{
	my ($cache, $cachePath) = @_;

	my $cacheFolder = dirname($cachePath);

		if (! -e $cacheFolder)
		{
			print (STDOUT "MKDIR\t$cacheFolder\n");
			mkpath($cacheFolder);

			if (! -e $cacheFolder)
			{
				print (STDERR "ERROR\tUnable to create $cacheFolder\n");
			}
		}

	open (INFO, ">$cachePath" ) or die ("FATAL: could not open file [$cachePath], errno => $! ");	# Open for output

	print (INFO "<file>\n");
	print (INFO "\t<dev>$cache->{dev}</dev>\n");
	print (INFO "\t<ino>$cache->{ino}</ino>\n");
	print (INFO "\t<mode>$cache->{mode}</mode>\n");
	print (INFO "\t<nlink>$cache->{nlink}</nlink>\n");
	print (INFO "\t<uid>$cache->{uid}</uid>\n");
	print (INFO "\t<gid>$cache->{gid}</gid>\n");
	print (INFO "\t<rdev>$cache->{rdev}</rdev>\n");
	print (INFO "\t<size>$cache->{size}</size>\n");
	print (INFO "\t<atime>$cache->{atime}</atime>\n");
	print (INFO "\t<mtime>$cache->{mtime}</mtime>\n");
	print (INFO "\t<ctime>$cache->{ctime}</ctime>\n");
	print (INFO "\t<blksize>$cache->{blksize}</blksize>\n");
	print (INFO "\t<blocks>$cache->{blocks}</blocks>\n");
	print (INFO "\t<name>$cache->{name}</name>\n");
	print (INFO "\t<directory>$cache->{directory}</directory>\n");
	print (INFO "\t<path>$cache->{path}</path>\n");
	print (INFO "\t<sha1>$cache->{sha1}</sha1>\n");
	print (INFO "\t<computetime>$cache->{computetime}</computetime>\n");
	print (INFO "</file>\n");
	
	close (INFO);

	print (STDOUT "REGEN\t$cachePath\n");

}

1;
