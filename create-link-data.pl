#!/usr/bin/perl
use strict;
use File::Spec;
use File::Basename;
use DBI;

# Sister program: filelink.pl

#
# The "FindBin" command will allow us to locate our "require"
# modules in the same folder as the executable, this way we
# don't have any pathing issues
#
use FindBin ();
use lib "$FindBin::Bin";

# Database stuff
my $driver   = "mysql";
my $database = "videodb";
my $hostname = "bigbox";
#$hostname = "localhost";
my $user     = "root";
my $password = "";

my %directors = {};
my %actors = {};

#
# Connect to database
#
my $dsn = "DBI:$driver:database=$database;host=$hostname";
my $dbh = DBI->connect($dsn, $user, $password);

# Make sure this sha1 hash does not exist in the database
my $sth = $dbh->prepare("select id,title,director,actors,subtitle,filedate,filename,year,custom1,custom3,custom2,custom4 from videodata");

$sth->execute;

my $PREFIX = "";

while ( my $row = $sth->fetchrow_hashref )
{

	my $filename;
	my $path;
	my $sha1 = $row->{custom2};
	my $mpaa = $row->{custom1};
	my $custom3 = $row->{custom3};
	my $rating = $row->{custom4};
	my $folder;
	my $ext;

	# Regex to grab file extension
	$_ = $row->{filename};
	(undef, $ext) = (/^(.*?)\.?([^\.]*)$/); # (Undef is the name)

	if ( $ext eq '' )
	{
		print (STDERR "FATAL\nUnable to get extension from filename!\n");
		exit (1);
	}

	# Derived from custom3 field
	my $upc;
	my $dvdDate;

	# custom3 stores the upc[slash]dvddate
	($upc, $dvdDate) = split (/\//,$custom3);

	# Trim the day off of the dvdDate
	$dvdDate =~ s/-[0123456789][0123456789]$//;


	# Create a filename link based on title
	if ( $row->{subtitle} eq "" )
	{
		$filename = $row->{title} . ".$ext";
	}
	else
	{
		$filename = $row->{title} . " - " . $row->{subtitle} . ".$ext";
	}

	if ( $row->{title} eq "" )
	{
		print (STDERR "ERROR\tTitle is missing for id=$row->{id}\n");
		next;
	}

	# director hash build
	if ( $row->{director} eq "" )
	{
		print (STDERR "ERROR\tDirector is missing for id=$row->{id}\n");
		$row->{director} = "UNKNOWN";
	}

	$directors{$row->{director}}{count}++;
	$folder = $row->{director};
	$path = $PREFIX . "/director/$folder";
	$directors{$row->{director}}{list} = $directors{$row->{director}}{list} . "$sha1\t$path\t$filename\n";


	# actor hash build
	# Bill Paxton::William Harding::nm0000200
	my @actorList = split (/\n/, $row->{actors});
	foreach my $actor (@actorList)
	{
		(my $name, my $charactor, my $id) = split (/::/, $actor);
		$actors{$name}{count}++;
		$folder = $name;
		$path = $PREFIX . "/actors/$folder";
		$actors{$name}{list} = $actors{$name}{list} . "$sha1\t$path\t$filename\n";
	}


	# genre
	my $query = "SELECT videodata.*, genres.* FROM videodata INNER JOIN videogenre ON videodata.id=videogenre.video_id INNER JOIN genres ON videogenre.genre_id=genres.id WHERE videodata.id='" . $row->{id} ."'";
	my $q1 = $dbh->prepare($query);

	$q1->execute;
	while ( my $rr = $q1->fetchrow_hashref )
	{
		$folder = $rr->{name};
		$path = $PREFIX . "/genre/$folder/";
		print ("$sha1\t$path\t$filename\n");
	}


	# dvdDate
	if ( $dvdDate eq "" )
	{
		print (STDERR "ERROR\tdvdDate (Custom3 part2) is missing for id=$row->{id}\n");
		$dvdDate = "UNKNOWN";
	}
	$path = $PREFIX . "/DVD-Release-Date/$dvdDate";
	print ("$sha1\t$path\t$filename\n");


	# title
	$path = $PREFIX . "/title/";
	print ("$sha1\t$path\t$filename\n");


	# title-a..z
	$folder = substr ($row->{title}, 0, 1);
	$folder =~ tr/a-z/A-Z/;
	$path = $PREFIX . "/title-a..z/$folder/";
	print ("$sha1\t$path\t$filename\n");


	# title-filename
	$path = $PREFIX . "/title-filename/";
	print ("$sha1\t$path\t$row->{filename}\n");


	# title-a..z
	$folder = substr ($row->{title}, 0, 1);
	$folder =~ tr/a-z/A-Z/;
	$path = $PREFIX . "/title-filename/a..z/$folder/";
	print ("$sha1\t$path\t$filename\n");


	# date-added
	my $prefix = $row->{filedate};
	$prefix =~ s/-//g;
	$prefix =~ s/ //g;
	$prefix =~ s/://g;
	$path = $PREFIX . "/date/";
	print ("$sha1\t$path\t$prefix - $filename\n");


	# year
	if ( $row->{year} eq "" )
	{
		print (STDERR "ERROR\tYear is missing for id=$row->{id}\n");
		$row->{year} = "UNKNOWN";
	}
	$folder = $row->{year};
	$path = $PREFIX . "/year/$folder/";
	print ("$sha1\t$path\t$filename\n");


	# mpaa
	$folder = $mpaa;
	$folder =~ s/^Rated //;
	$folder =~ s/ .*$//;
	$folder =~ s/^\s+//;
	$folder =~ s/\s+$//;
	if ( $folder eq "" )
	{
		print (STDERR "WARNING\tNo MPAA Rating for $row->{id}\n");
	}
	else
	{
		$path = $PREFIX . "/mpaa/$folder";
		print ("$sha1\t$path\t$filename\n");
	}


	# rating
	if ( $rating eq "100" )
	{
		$rating = "90";
	}

	if ( $rating eq "" )
	{
		$rating = "na";
	}
	
	$folder = int ( $rating / 10 ) . "0";
	$path = $PREFIX . "/rating/$folder";
	print ("$sha1\t$path\t$filename\n");

}



#disconnect
$dbh->disconnect();


my $dcount = 0;

for my $key ( keys %directors )
{
	if ( $directors{$key}{count} >= 2 )
	{
		print ($directors{$key}{list});
		$dcount++;
	}
	
}

##print (STDERR "Director count = $dcount\n");

my $acount = 0;

for my $key ( keys %actors )
{
	if ( $actors{$key}{count} >= 5 )
	{
		print ($actors{$key}{list});
		$acount++;
	}
	
}

##print (STDERR "Actor count = $acount\n");

