#!/usr/bin/perl -w
use strict;

#!/usr/bin/perl

use File::Which;          # exports which()

sub trim {
	for (@_) {
		s/^\s*//; # trim leading spaces
		s/\s*$//; # trim trailing spaces
	}
	return @_;
}


sub getTags
{
	my $exe_path = which('tag');
	if ( $exe_path eq "" )
	{
		print ( STDERR "FATAL: unable to locate 'tag' in the path!\n");
		exit (0);
	}

	(my $file) = @_ ;

	open(TAGOUT, "\"$exe_path\" \"$file\"  2>&1|");

#Format:  Monkey's Audio 3.99
#Details: 24 Hz, playtime 49286:38:13
#Tag:     APE v2.0
#Title:   Inside Looking Out
#Artist:  Dokken
#Album:   Dysfunctional
#Year:    1995
#Track:   01
#Genre:   Rock
#Comment:

my %tag;

my $details;
my $tagString;
my $title;
my $artist;
my $album;
my $year;
my $track;
my $genre;


	while ( <TAGOUT> )
	{
		chomp;

		if ( /^.*Details: /i )
		{

			$details = $_;
			$details =~ s/^.*Details: //i;
			trim ($details);

			$tag{"details"} = $details;
		}

		if ( /^Tag:/i )
		{
			$tagString = $_;
			$tagString =~ s/^Tag:     //i;
			trim($tagString);
			$tag{"tag"} = $tagString;
		}

		if ( /^.*Title: /i )
		{
			$title = $_;
			$title =~ s/^.*Title: //i;
			trim ($title);
			$tag{"title"} = $title;
		}

	 	if ( /^.*Artist: /i )
		{
			$artist = $_;
			$artist =~ s/^.*Artist: //i;
			trim($artist);
			$tag{"artist"} = $artist;
		}

		if ( /^.*Album: /i )
		{
			$album = $_;
			$album =~ s/^.*Album: //i;
			trim ($album);
			$tag{"album"} = $album;
		}

		if ( /^.*Year: /i )
		{
			$year = $_;
			$year =~ s/^.*Year: //i;
			trim ($year);
			$tag{"year"} = $year;
		}

		if ( /^.*Track: /i )
		{
			$track = $_;
			$track =~ s/^.*Track: //i;
			$track =~ s/^.*0//i;  # remove leading 0's
			trim ($track);
			$tag{"track"} = $track;
		}

		if ( /^.*Genre: /i )
		{
			$genre = $_;
			$genre =~ s/^.*Genre: //i;
			trim ($genre);
			$tag{"genre"} = $genre;
		}


	}

	close(TAGOUT);

	# It is always FLAC for a .flac file!
	$tag{"format"} = "FLAC";
}


1;
