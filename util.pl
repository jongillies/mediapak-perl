#!/usr/bin/perl -w
use strict;
use FindBin ();
use lib "$FindBin::Bin";

our $DEBUG = 1;
our $CACHE_FOLDER;
our $CACHE_EXTENTION = ".xml";
our $RUNNINGWINDOWS = $^O =~ /MS/;
our $WINDOWS_CACHE_FOLDER="_mc";         # Windows does not like "." files.
our $UNIX_CACHE_FOLDER=".mc";            # UNIX likes "." files.. they are "hidden"

$RUNNINGWINDOWS ? ($CACHE_FOLDER = $WINDOWS_CACHE_FOLDER) : ($CACHE_FOLDER = $UNIX_CACHE_FOLDER);

our $OFFLINE_CACHE_OPT = "c:\\mediapak";

my @paths = ("c:\\foo", "c:\\temp");
my @spec = ("*.*");

require ("getMetaDataList.pl");
require ("writePakFile.pl");

my %metaData = getMetaDataList (\@paths, \@spec, 0);

while (my($sha1, $cache) = each(%metaData))
{
	print ($cache->{sha1} . "\n");
}

writePakFile (\%metaData, "c:\\foo.pak");


print ("Done!\n");

1;


