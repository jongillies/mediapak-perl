#!/usr/bin/perl -w
use strict;
use File::Spec;
use Getopt::Std;

#
# Program Identification Section (____VERSION____ is replaced with the subversion revision number when the package is built)
#                                (____DATE____ is replaced with package build time stamp)
#
my $PROGRAM_NAME="vlink";
my $PROGRAM_DESC="Create Movie Links by MetaData";
my $PROGRAM_VERSION="v2 _____VERSION_____ _____DATE_____";

# Use FindBin to locate our "require" modules in the scripts run directory
use FindBin ();
use lib "$FindBin::Bin";

# Reference and include global variables
use vars qw ($DEBUG $CACHE_FOLDER $CACHE_EXTENTION $RUNNINGWINDOWS $OFFLINE_CACHE);
require ("lib-globals.pl");

# Usage subroutine
sub usage
{
	print ("$PROGRAM_NAME (Build $PROGRAM_VERSION) - $PROGRAM_DESC\n");
	print ("Usage: $PROGRAM_NAME [-d] [-i include-ext] [-c offline-cache-folder] [-l link_path] [path] [path ...]\n" );
	print ("        [-d] will turn on debug messages sent to STDERR\n");
	print ("        [-i] is a comma delimited list of file extentsions to match (Case Sensitive!)\n");
	print ("        [-c] is the off-line folder to cache metadata summary for ckpak\n");
	print ("        [-l] Path to link files\n");
	print ("        [path] is a file path to search\n");
	exit (0);
}



#
# Local Variables
my %cmdline_option = ();                # Command line options hash
my @pathList;                           # List of paths to search
my @includeExtList;                     # List of file extentions to match
my $includeExt;                         # Include Extension cmd asdfasdfasdf

# Parse and validate command line options
if (! getopts('di:c:l:', \%cmdline_option) )
{
	print (STDOUT "WARNING\tInvalid commmand line parameters!\n");
	usage ();
}

# Set local and global variables from command line
$OFFLINE_CACHE = $cmdline_option{c};
$DEBUG = $cmdline_option{d};
$includeExt = $cmdline_option{i};
my $LINK_PATH = $cmdline_option{l};

if ( ! -e $LINK_PATH )
{
	print ("ABORT\t$LINK_PATH does not exist or no permissions to read!\n");
	exit (1);
}

require ("lib-gatherPathList.pl");
@pathList = gatherPathList();

require ("lib-gatherIncludeList.pl");
@includeExtList = gatherIncludeList($includeExt);

if ( $DEBUG )
{
	print ("INFO\tARG -d is $DEBUG\n");
	print ("INFO\tARG -i is $includeExt\n") if defined ($includeExt);
	foreach my $ext (@includeExtList)
	{
		print ("INFO\tARG Include Extentsions: $ext\n");
	}
}

require ("lib-getMetaDataList.pl");
require ("lib-writePakFile.pl");

my %metaData = getMetaDataList (\@pathList, \@includeExtList);

# Database stuff
my $driver   = "mysql";
my $database = "videodb";
my $hostname = "bigbox";
my $user     = "root";
my $password = "";

my %actorHash;

#
# Connect to database
#
my $dsn = "DBI:$driver:database=$database;host=$hostname";
my $dbh = DBI->connect($dsn, $user, $password);

my $sth = $dbh->prepare("select * from videodata order by id");
$sth->execute;

while ( my @row = $sth->fetchrow_array )
{
	my $id=$row[0];
	my $md5=$row[1];
	my $title=$row[2];
	my $subtitle=$row[3];
	my $language=$row[4];
	my $diskit=$row[5];
	my $comment=$row[6];
	my $disklabel=$row[7];
	my $imdbID=$row[8];
	my $year=$row[9];
	my $imgurl=$row[10];
	my $director=$row[11];
	my $actors=$row[12];
	my $runtime=$row[13];
	my $country=$row[14];
	my $plot=$row[15];
	my $filename=$row[16];
	my $filesize=$row[17];
	my $filedate=$row[18];
	my $audio_codec=$row[19];
	my $video_codec=$row[20];
	my $video_width=$row[21];
	my $video_height=$row[22];
	my $istv=$row[23];
	my $lastupdate=$row[24];
	my $seen=$row[25];
	my $mediatype=$row[26];
	my $mpaa = $row[27];
	my $sha1 = $row[28];
	my $barcode=$row[29];
	my $custom4=$row[30];
	my $created=$row[31];
	my $owner_id=$row[32];

	my $YEAR_PATH     = File::Spec->catfile ($LINK_PATH, "Year");
	my $ACTOR_PATH    = File::Spec->catfile ($LINK_PATH, "Actor");
	my $MPAA_PATH     = File::Spec->catfile ($LINK_PATH, "Rating");
	my $GENRE_PATH    = File::Spec->catfile ($LINK_PATH, "Genre");
	my $DIRECTOR_PATH = File::Spec->catfile ($LINK_PATH, "Director");
	my $TITLE_PATH    = File::Spec->catfile ($LINK_PATH, "Title");

	my $FILENAME_PATH = File::Spec->catfile ($LINK_PATH, "FileName");
	my $LETTER_PATH   = File::Spec->catfile ($LINK_PATH, "A-Z");



# create a link based on 1st letter

	if ( $metaData{$sha1} )
	{
		print ("found $title at $metaData{$sha1}\n");

		my $directory = dirname($metaData{$sha1});
		my $fileName = basename($metaData{$sha1});

		my $source = $metaData{$sha1};


		#
		# FileName Path
		#
		my $target = File::Spec->catfile ($FILENAME_PATH, $fileName);
		do_symlink($source,$target);


		#
		# Letter Path
		#
		my $firstLetter = uc(substr ($fileName,0,1));
		$target = File::Spec->catfile ($LETTER_PATH, $firstLetter, $fileName);
		do_symlink($source,$target);


		#
		# Title - Subtitle
		#
		if ( $title ne "" )
		{
			my $fileName = $title;
			if ( $subtitle ne "" )
			{
				$fileName = $fileName . " - " . $subtitle;
			}

			############# KRAP, have to add an extentsion!!!!!!!
			$target = File::Spec->catfile ($TITLE_PATH, $fileName);
			do_symlink($source,$target);
		}

		#
		# Year Link
		#
		if ( $year ne "" )
		{
			my $target = File::Spec->catfile ($YEAR_PATH, $year, $fileName);
			
			do_symlink($source,$target);
		}


		##
		## Actors Link (Formated as "Actor Name::Character Name::IMDBID\n...)
		##
		#if ( $actors ne "" )
		#{
		#	my @actor = split ("\n", $actors);
		#	foreach my $nameList (@actor)
		#	{
		#		my @name = split ("::", $nameList);
		#
		#		my $target = File::Spec->catfile ($ACTOR_PATH, $name[0], $fileName);
		#
		#		do_symlink($source,$target);
		#
		#	}
		#}


		#
		# Genre Link
		#
		# Thanks to Uncle Andy for the SQL code!
		my $sql = "SELECT genres.name FROM videodata INNER JOIN videogenre ON videodata.id=videogenre.video_id INNER JOIN genres ON videogenre.genre_id=genres.id WHERE videodata.id='$id'";

		my $sth1 = $dbh->prepare($sql);
		$sth1->execute;

		while ( my @row1 = $sth1->fetchrow_array )
		{
			my $target = File::Spec->catfile ($GENRE_PATH, $row1[0], $fileName);
			do_symlink($source,$target);
		}


		#
		# MPAA Link (Format is "Rating RatingClass Why} all we need is RatingClass)
		#
		if ( $mpaa ne "" )
		{
			my @rating = split (' ', $mpaa);
			my $target = File::Spec->catfile ($MPAA_PATH, $rating[1], $fileName);
			do_symlink($source,$target);
		}


		#
		# Director Link
		#
		if ( $director ne "" )
		{
			my $target = File::Spec->catfile ($DIRECTOR_PATH, $director, $fileName);
			
			do_symlink($source,$target);
		}

	}
	else
	{
		print ("ERROR! Cant find $title\t$sha1\n");
	}
}

#disconnect
$dbh->disconnect();


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

