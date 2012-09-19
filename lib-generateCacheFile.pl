#!/usr/bin/perl -w
use strict;

require ("lib-filedigest.pl");

use File::Path;

sub generateCacheFile
{
	my ($file, $cachePath) = @_;

	# Get file metadata
	( my $dev, my $ino, my $mode, my $nlink, my $uid, my $gid, my $rdev,
	  my $size, my $atime, my $mtime, my $ctime, my $blksize, my $blocks )
	  = stat($file);

	my $directory = dirname($file);       # Directory of $file
	my $fileName = basename($file);       # File name of $file

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


	my $startTime = time();
	print (STDOUT "INFO\tCalculating SHA1 checksum ($file)...\n");
	my $sha1 = filedigest($file);

	open (INFO, ">$cachePath" ) or die ("FATAL: could not open file [$cachePath], errno => $! ");	# Open for output

	print (INFO "<file>\n");
	print (INFO "\t<dev>$dev</dev>\n");
	print (INFO "\t<ino>$ino</ino>\n");
	print (INFO "\t<mode>$mode</mode>\n");
	print (INFO "\t<nlink>$nlink</nlink>\n");
	print (INFO "\t<uid>$uid</uid>\n");
	print (INFO "\t<gid>$gid</gid>\n");
	print (INFO "\t<rdev>$rdev</rdev>\n");
	print (INFO "\t<size>$size</size>\n");
	print (INFO "\t<atime>$atime</atime>\n");
	print (INFO "\t<mtime>$mtime</mtime>\n");
	print (INFO "\t<ctime>$ctime</ctime>\n");
	print (INFO "\t<blksize>$blksize</blksize>\n");
	print (INFO "\t<blocks>$blocks</blocks>\n");
	print (INFO "\t<name>" . $fileName . "</name>\n");
	print (INFO "\t<directory>" . $directory . "</directory>\n");
	print (INFO "\t<path>$file</path>\n");
	print (INFO "\t<sha1>" .  $sha1 . "</sha1>\n");
	print (INFO "\t<computetime>" . (time() - $startTime) . "</computetime>\n");
	print (INFO "</file>\n");
	
	close (INFO);

	print (STDOUT "CREATE\t$cachePath\n");

}

1;
