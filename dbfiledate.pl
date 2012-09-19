#!/usr/bin/perl -w
my $PROGRAM_NAME="dbfiledate";
my $PROGRAM_DESC="Check Database vs File Dates";
my $PROGRAM_VERSION="_____VERSION_____";

use strict;
use Getopt::Std;
use File::Find::Rule;
use Env;
use DBI;
use Time::Local;
use File::Touch;

use File::Spec;
use File::Basename;
use File::Path;

use File::Find::Rule;

my $PATH_SEPARATOR = ":";  # Used on UNIX

# What OS am I running? ( $^O is the perlvar for OSType)
my $RUNNINGWINDOWS = 0; # Assume we are NOT on Windows
if ( $^O =~ /MS/ )      # If the OS string has "MS" in it, assume Windows.
{
	$RUNNINGWINDOWS = 1;  
	$PATH_SEPARATOR = ";";
}

#
# The "FindBin" command will allow us to locate our "require"
# modules in the same folder as the executable, this way we
# don't have any pathing issues
#
use FindBin ();
use lib "$FindBin::Bin";

require ("dumbassreadcache.pl");

sub slurp
{
	(my $file) = @_;             # $file is the 1st parameter
	
	if ( ! -e $file )
	{
		return ("");
	}
	
	my $holdTerminator = $/;     # Save the current $/ reference
	undef $/;                    # Go into slurp mode
	open THEFILE, "<" . $file;   # open the file
	my $buffer = <THEFILE>;      # Read the file into #buffer
	close (THEFILE);             # Close the file
	$/ = $holdTerminator;        # Reset the $/ reference
	return ($buffer);            # Return what we got
}

##############################################################################
# Global variables
##############################################################################
my %option = ();                        # Command line options hash
my $status = getopts('dc:X', \%option);    # Parse the options

my $DEBUG = $option{d};                 # Turn on debug if -d is an option
my $OFFLINE_CACHE_OPT = $option{c};     # Location of off-line media cache folder
my $XCHANGE = $option{X};               # Use the other platforms cache folder directory

my $STDIN_REDIRECTED = ! -t STDIN;      # Is STDIN redirected from a file?

my @pathList;                           # List of paths to search for media

my @fileSpec;                           # Used by the "find" command

my %localFile;                          # Hash of local path files

my $CACHE_FOLDER;                       # Subfolder name to store metadata

my $WINDOWS_CACHE_FOLDER="_mc";         # Windows does not like "." files.
my $UNIX_CACHE_FOLDER=".mc";            # UNIX likes "." files.. they are "hidden"

# Set the CACH_FOLDER name for the appropriate OS
if ( $RUNNINGWINDOWS == 1 )
{
	$CACHE_FOLDER= $WINDOWS_CACHE_FOLDER;
	
	if ( $XCHANGE )
	{
		$CACHE_FOLDER= $UNIX_CACHE_FOLDER;
	}
}
else
{
	$CACHE_FOLDER= $UNIX_CACHE_FOLDER;

	if ( $XCHANGE )
	{
		$CACHE_FOLDER= $WINDOWS_CACHE_FOLDER;
	}
	
}

my $CACHE_EXTENTION=".xml";             # Extention of metadata file

##############################################################################

##############################################################################
# Build a list of paths from STDIN and/or the command line
##############################################################################
if ($STDIN_REDIRECTED)
{
	print (STDOUT "INFO\tSTDIN is redirected\n") if $DEBUG;

	# Read all lines from STDIN into the pathList array 
	while (my $path = <STDIN>)
	{
		chomp ($path);
		if (-e $path)
		{
			push (@pathList, File::Spec->canonpath($path));
			print ("Added $path to search list.\n") if $DEBUG;
		}
		else
		{
			print (STDERR "WARNING\t$path does not exist.\n" );
		}
	}
}
else
{
	print (STDOUT "INFO\tSTDN is NOT redirected\n") if $DEBUG;
}

## Add any paths from the command line to the pathList array
foreach my $path (@ARGV)
{
	# NOTE: If the path does not exist, it might be cached?  Add it!
	push (@pathList, File::Spec->canonpath($path));
}

##############################################################################

##############################################################################
# Die if command line parsing fails (status) or we dont' have at least 1 path
##############################################################################
if ($status == 0 || @pathList < 1)
{
	print ("$PROGRAM_NAME (Build $PROGRAM_VERSION) - $PROGRAM_DESC\n");
	print ("Usage: $PROGRAM_NAME [-d] [-q] [-c offline-cache-folder] packToCheck [path ...] and/or [ < pathtxtfile]\n" );
	print ("        [-d] will turn on debug messages sent to STDERR\n");
	exit (0);
}

#
# Should check to see that $LINK_PATH exists and that it is writable
#

print (STDOUT "INFO\tRaw parameters: @ARGV\n") if $DEBUG;

# Guess we are looking for *.*, should use the -i ext,ext,ext like gencache does!!!

push (@fileSpec, "*.*");

#
# Create a "hash" of all files in the Path list based on SHA1 key
#
foreach my $path (@pathList)
{
	if ( -e $path )
	{
		print ("INFO\tSearching: [$path]\n") if $DEBUG;
		my @files = find (name => [ @fileSpec ] , in => $path);
	
		foreach my $file (@files)
		{
	
			# Ignore directories
			if (-d $file)
			{
				next;
			}
	
			$file = File::Spec->rel2abs($file);   # Dereference the file path
			$file = File::Spec->canonpath($file); # Make name pretty for the platform
	
			print ("INFO\tReading $file\n") if $DEBUG;
	
			my $directory = dirname($file);       # Directory of $file
			my $fileName = basename($file);       # File name of $file
	
			# Don't recurse into folders that are cache folders
			if ($directory =~ /${UNIX_CACHE_FOLDER}$/)
			{
				next;
			}
	
			# Don't recurse into folders that are cache folders
			if ($directory =~ /${WINDOWS_CACHE_FOLDER}$/)
			{
				next;
			}
			
			
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
	
				#my $cache = XMLin($cachePath);
				my $cache = dumbAssReadCache($cachePath);
				
				my $sha1 = $cache->{sha1};

				# Only consider avi files
				if ( $fileName =~ /\.avi$/i )
				{
					$localFile{$sha1} = $fileName . "\t" . $directory;
				}
			}
			else
			{
				print (STDERR "WARNING\tCache file does not exist for [$file]\n");
			}
			#print ("Found: $file\n");
		}
	}
	else
	{
		print (STDERR "WARNING\tPath does not exist! [$path]\n");

		# Try and read the cach file
		if ( $OFFLINE_CACHE_OPT )
		{
			my $mediaCacheFile = File::Spec->catfile ($OFFLINE_CACHE_OPT, sha1_hex($path));

			print (STDERR "WARNING\tUsing off-line cache file $mediaCacheFile for $path\n");

			if ( -e $mediaCacheFile )
			{
				my $fileContents = slurp($mediaCacheFile);
				
				# Put the file contents into the hash
				my @lines = split (/\n/, $fileContents);
				foreach my $line ( @lines )
				{
					(my $sha1, my $fileName, my $directory) = split (/\t/, $line);
					
					# Only consider avi files
					if ( $fileName =~ /\.avi$/i )
					{
						$localFile{$sha1} = $fileName . "\t" . $directory;
					}
				}

			}
			else
			{
				print (STDERR "WARNING\t$mediaCacheFile does not exist for $path\n");
			}

		}

	}

}

# Database stuff
my $driver   = "mysql";
my $database = "videodb";
my $hostname = "bigbox";
my $user     = "root";
my $password = "";

#Connect to database
my $dsn = "DBI:$driver:database=$database;host=$hostname";
my $dbh = DBI->connect($dsn, $user, $password);

my $sth = $dbh->prepare("select id, custom2, filename, title, filedate from videodata order by id");

$sth->execute;

#my %database = {};
my %database = ();

my $count = 1;
while ( my @row = $sth->fetchrow_array )
{
	#print "@row\n";
	# Key is row[1]=hash and row[2] = file name

	#my $count = 0;
	#foreach my $col (@row)
	#{
	#	print ("[$count]: $col\n");
	#	$count++;
	#}
	
	my $sha1 = $row[1];
	my $fileName = $row[2];
	my $fileDate = $row[4];

	my $junk = $localFile{$sha1};

	if ( defined ( $junk ) )
	{

		my ( $filename, $path) = split (/\t/, $localFile{$sha1});

		my $filePath = File::Spec->catfile ($path, $filename);

		print "Found local file >$filePath<\n";


		# Get file metadata
		( my $dev, my $ino, my $mode, my $nlink, my $uid, my $gid, my $rdev,
		  my $size, my $atime, my $mtime, my $ctime, my $blksize, my $blocks )
		  = stat($filePath);

		print ("File Date is: $mtime\n");
		print ("DB   Date is: $fileDate\n");
		
		(my $yearPart, my $timePart) = split (/ /,$fileDate);
		(my $year, my $month, my $day) = split (/-/, $yearPart);
		(my $hour, my $minute, my $second) = split (/:/, $timePart);
		my $time = timelocal ($second, $minute, $hour, $day, $month-1, $year-1900);

		print ("EPOC Date is: $time\n");

		if ( $mtime == $time )
		{
			print ("Match!\n");
		}
		else
		{
			my $ref = File::Touch->new( mtime => $time, no_create => 1 );
			$ref->touch($filePath);
		}
	}
	

	$count++;

}

#disconnect
$dbh->disconnect();




