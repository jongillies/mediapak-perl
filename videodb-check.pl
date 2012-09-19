#!/usr/bin/perl

#use XML::Simple;
use File::Spec;
use File::Basename;

# What OS am I running? ( $^O is the perlvar for OSType)
my $RUNNINGWINDOWS = 0; # Assume we are NOT on Windows
if ( $^O =~ /MS/ )      # If the OS string has "MS" in it, assume Windows.
{
	$RUNNINGWINDOWS = 1;  
}


my $PAK_FILE = $ARGV[0];                # Grab the pack file path from the 1'st argument
shift;                                  # "shift" the arguemnts to get rid of the first
                                        # one, so only paths remain.

if ($PAK_FILE eq "")
{
	print ("Usage: $0 pakfile\n" );
	exit (0);
}

if ( ! -e $PAK_FILE )
{
	print (STDERR "FATAL\tMediaPak file [$PAK_FILE] does not exist!\n");
	exit (1);
}

# Database stuff
$driver   = "mysql";
$database = "videodb";
$hostname = "bigbox";
$user     = "root";
$password = "";

################################################################################
use DBI;

#Connect to database
$dsn = "DBI:$driver:database=$database;host=$hostname";
$dbh = DBI->connect($dsn, $user, $password);

#quote this only once:
$owner = $dbh->quote($owner);

my $sth = $dbh->prepare("select id, custom2, filename, title from videodata order by id");

$sth->execute;

%database = {};

my $count = 1;
while ( my @row = $sth->fetchrow_array )
{
	#print "@row\n";
	# Key is row[1]=hash and row[2] = file name

	$sha1 = $row[1];
	$fileName = $row[2];

	$database{$sha1} = $fileName;

	#print ("DB ($count) [".$sha1."] value [$fileName]]\n");
	$count++;

}

#disconnect
$dbh->disconnect();


$count = 1;
for my $key ( keys %database )
{
	my $value = $database{$key};
	
	# For some goddamn reason, the has has an exta entry that prints out
	# like this:
	#
	# HA (251) [HASH(0x211d9b8)] value []
	#
	# I can't figure out how it is getting in there so we will bypass it
	# by checking for a value in the $value.
	#

	if ( $value ne "" )
	{
		#print "HA ($count) [$key] value [$value]\n";
		$count++;
	}
	else
	{
		delete ($database{$key});
	}
}


#for my $key ( keys %database ) 
#{
#        my $value = $database{$key};
#        print "$key => $value\n";
#}


%pakFile = {};

#
# Read in the pak file to a hash
#
open( FILE, "< $PAK_FILE" ) or die "Can't open $PAK_FILE : $!";

while( <FILE> ) {

	s/#.*//;            # ignore comments by erasing them
	next if /^(\s)*$/;  # skip blank lines

	chomp;              # remove trailing newline characters
	
	(my $sha1, my $filename, my $path) = split (/\t/);

	if ( $filename =~ /\.avi$/i )
	{	
	$pakFile{$sha1} = $filename . "\t" . $path;
	}

}

close FILE;

$totalErrors = 0;
$totalFiles = 0;

#
# Verify files in the "pakList" exist in the database hash
#
for my $sha1 ( keys %pakFile )
{
	my ( $filename, $path) = split (/\t/, $pakFile{$sha1});
	
	$totalFiles++;
	
	if ( $filename ne "" )
		{
		if ( $database{$sha1} )
		{
			print ("FOUND_DATABASE\t$sha1\t$filename\t$path\n");
		}
		else
		{
			print ("NOT_FOUND_DATABASE\t$sha1\t$filename\t$path\n");
			$totalErrors++;
		}
	}
}


$totalErrors = 0;
$totalFiles = 0;

#
# Verify the database files exist int eh "pakList" (Reverse from above)
#

for my $sha1 ( keys %database )
{
	##my ( $filename, $path) = split (/\t/, $database{$sha1});
	
	$filename = $database{$sha1};
	
	$totalFiles++;
	
	if ( $pakFile{$sha1} )
	{
		print ("FOUND_PAK\t$sha1\t$filename\t$pakFile{$sha1}\n");
	}
	else
	{
		print ("NOT_FOUND_PAK\t$sha1\t$filename\t$filename\n");
		$totalErrors++;
	}
}



