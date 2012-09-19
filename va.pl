#!/usr/bin/perl

####use XML::Simple;
use File::Spec;
use File::Basename;

use Data::Dumper;

#
# The "FindBin" command will allow us to locate our "require"
# modules in the same folder as the executable, this way we
# don't have any pathing issues
#
use FindBin ();
use lib "$FindBin::Bin";

$CACHE_FOLDER=".mc";                # UNIX likes "." files.. they are "hidden"
$CACHE_EXTENTION=".yml";             # Extention of metadata file

# What OS am I running? ( $^O is the perlvar for OSType)
my $RUNNINGWINDOWS = 0; # Assume we are NOT on Windows
if ( $^O =~ /MS/ )      # If the OS string has "MS" in it, assume Windows.
{
    $RUNNINGWINDOWS = 1;  
}

$CACHE_FOLDER=".mc";                # UNIX likes "." files.. they are "hidden"



# The SHA1 hashes are stored in this field.
$sha1field = 'custom2';

# path to the eject tool
$eject = '/usr/bin/eject';

# cdrom to use (reads it from commandline)
$device = $ARGV[ 0 ];
$device = "/writer" unless (defined($device));

# do the mount ?
$do_mount = 0;

# if you use the multiuser feature you may want to give an
# owner of the movies to add here - if you don't need it just
# set it to a blank string 
$owner_id = 1;

# Database stuff
$driver   = "mysql";
$database = "videodb";
$hostname = "localhost";
$user     = "videodb";
$password = "videodb";

################################################################################
use DBI;

#Connect to database
$dsn = "DBI:$driver:database=$database;host=$hostname";
$dbh = DBI->connect($dsn, $user, $password);

#quote this only once:
$owner = $dbh->quote($owner);

if (-f $device)
{
   $plain = $device;
   $plain =~ s#.*/([^/]+)$#\1#i;
   add($device,$plain);
}
else
{

   # mount
   ($do_mount) && system("$eject -t $device");
   ($do_mount) && system("mount $device");
   
   #work
   &readfiles($device);
   
   #umount
   ($do_mount) && system("umount $device");
   ($do_mount) && system("$eject $device");
}

#disconnect
$dbh->disconnect();

#
###############################################################################

sub readfiles($)
{
   my $path = $_[ 0 ];
   
   opendir(ROOT, $path);
   my @files = readdir(ROOT);
   closedir(ROOT);
   
   my ($file, $ffile);
   foreach $file (@files)
   {
      $ffile = "$path/$file";

      next if ($file =~ /^\.|\.\.$/);    #skip upper dirs
      if (-d $ffile)
      {
         readfiles($ffile);
      }

      if ($ffile =~ /^.*(avi|bin|mpe?g|ra?m|mov|asf|wmv|mkv)$/i)
      {
         &add($ffile, $file);    #add it
#         print STDERR "$ffile\n";
      }
   }
}

sub add($$)
{
   my $ffile = $_[ 0 ];    #full path
   my $file  = $_[ 1 ];    #file only


   my $directory = dirname($ffile);       # Directory of $file
   my $fileName = basename($ffile);       # File name of $file
        
        
   my $cacheFolder = File::Spec->catfile ($directory, $CACHE_FOLDER); # Cache folder Name
   my $cacheFile = $fileName . $CACHE_EXTENTION;                      # Cache file name
   my $cachePath = File::Spec->catfile ($cacheFolder, $cacheFile);    # Absolute path to cache file

   my $ignoreFile = File::Spec->catfile ($directory, "." . $fileName);
      
   if ( -e $ignoreFile )
   {
      print (STDOUT "INFO\tIngoring $ffile via $ignoreFile\n");
      return;
   }

   if ( ! -e $cachePath )
   {
      print (STDERR "ERROR\tCache File ($cachePath) does not exist! File not added!\n");
      return;
   }
   
   #my $cache = dumbAssReadCache ($cachePath);
   #my $sha1 = $cache->{sha1};
   $command = "grep ^checksum \"$cachePath\" | awk '{ print \$2 }'";
   my $sha1 = `$command`;

   chomp($sha1);

   # Make sure this sha1 hash does not exist in the database
   my $sth = $dbh->prepare("select id, custom2, title from videodata where custom2='$sha1' order by id");
   
   $sth->execute;

   while ( my @row = $sth->fetchrow_array )
   {
      #print "@row\n";
      print ("NOT_ADDED\t$sha1\tThis SHA1 already exists in the database (ID=$row[0])\t$ffile\n");
      return;
   }
   
   
   # get filestatistics
   my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($ffile);

   # Declare stats from mplayer. Have to do outside of the RUNNINGWINDOWS if clause or we lose scope for later
   my ($audio_codec, $video_codec, $video_width, $video_height, $runtime);

   if ( $RUNNINGWINDOWS != 1 )
   {

      # get videoinfos
      print qq(`mplayer -identify  -ao null -vo null -frames 0 "$ffile" 2>/dev/null);
      my @out = `mplayer -identify  -ao null -vo null -frames 0 "$ffile" 2>/dev/null`;

#print Dumper (@out);

      foreach my $line (@out)
      {
         next unless ($line =~ m/^ID_/);
         chomp($line);

         if ($line =~ m/^ID_VIDEO_FORMAT=(.*)/)
         {
            $video_codec = $1;
            $video_codec = 'MPEG1' if ($video_codec eq '0x10000001');
   
            #FIXME id's of other mpegs??
         }
         elsif ($line =~ m/^ID_VIDEO_WIDTH=(.*)/)
         {
            $video_width = $1;
print ("WIDTH = $video_width\n");
         }
         elsif ($line =~ m/^ID_VIDEO_HEIGHT=(.*)/)
         {
            $video_height = $1;
print ("HEIGHT = $video_height\n");
         }
         elsif ($line =~ m/^ID_AUDIO_CODEC=(.*)/)
         {
            $audio_codec = $1;
print ("CODEC = $video_codec\n");
         }
         elsif ($line =~ m/^ID_LENGTH=(.*)/)
         {
            $runtime = $1;
            $runtime = sprintf("%d", $runtime / 60);
print ("RUNTIME = $runtime\n");
         }
      }
   }
   
   # get titles
   my ($lang, $title, $subtitle, $istv) = &guessnames($file);
	
   # prepare for inserts
   $file         = $dbh->quote($file);
   $size         = $dbh->quote($size);
   $audio_codec  = $dbh->quote($audio_codec);
   $video_codec  = $dbh->quote($video_codec);
   $video_width  = $dbh->quote($video_width);
   $video_height = $dbh->quote($video_height);
   $runtime      = $dbh->quote($runtime);
   $lang         = $dbh->quote($lang);
   $title        = $dbh->quote($title);
   $subtitle     = $dbh->quote($subtitle);
   $sha1         = $dbh->quote($sha1);
		
   # insert
   $INSERT = "INSERT INTO videodata
               SET filename = $file,
                   filesize = $size,
                   audio_codec = $audio_codec,
                   video_codec = $video_codec,
                   video_width = $video_width,
                   video_height = $video_height,
                   language = $lang,
                   title = $title,
                   subtitle = $subtitle,
                   runtime = $runtime,
                   mediatype = 4,
                   istv = $istv,
                   filedate = FROM_UNIXTIME($mtime),
                   $sha1field = $sha1,
                   created = NOW(),
                   owner_id = $owner_id";
  
print ("INSERT\n\n$INSERT\n\n");
 
###   $dbh->do($INSERT);

   print "\nADDED\t$file\t$title - $subtitle\t$sha1\n\n";
}

sub guessnames($)
{
   my $episode = "";
   my $istv    = 0;

   my $file = $_[ 0 ];    #file only

   # try to get language:
   my $lang = "";
   $lang = "german"  if ($file =~ m/\b(german|ger|de)\b/i);
   $lang = "english" if ($file =~ m/\b(english|eng|en)\b/i);

   # remove add. info
   $file =~ s/\(.*\)//;

   #remove common Trash
   $file =~ s/(\[[^\]]\]|mkv|avi|mp?g|bin|cd\d|dvd\d|divx|xvid|vcd|dvdscr|dvdrip|shareconnector|eselfilme)//gi;

   # get episode Number
   if ($file =~ s/(s\d+e\d+)/-/i)
   {
      $episode = $1;
   }
   elsif ($file =~ s/(\d+x\d+)/-/i)
   {
      $episode = $1;
   }

   # change dots to underscores
   $file =~ s/\./_/g;

   # change underscores to spaces
   $file =~ s/_/ /g;

   # remove extension(s):
   $file =~ s/\..{1,10}$//;
   my @parts = split ("-", $file, 2);
   my $title    = $parts[ 0 ];
   my $subtitle = $parts[ 1 ];
   $title    =~ s/^[\s-]*//g;
   $title    =~ s/[\s-]*$//g;
   $subtitle =~ s/^[\s-]*//g;
   $subtitle =~ s/[\s-]*$//g;

   if ($episode)
   {
      $subtitle = "[$episode] $subtitle";
      $istv     = 1;
   }

   unless ($title =~ s/^(for the)\b(.*)$/$2, $1/i)
   {
      unless ($title =~ s/^(for a)\b(.*)$/$2, $1/i)
      {
         unless ($title =~ s/^(for)\b(.*)$/$2, $1/i)
         {
            unless ($title =~ s/^(the)\b(.*)$/$2, $1/i)
            {
               unless ($title =~ s/^(a)\b(.*)$/$2, $1/i)
               {
                  ($title =~ s/^(der|die|das)\b(.*)$/$2, $1/i);
               }
            }
         }
      }
   }
   $title =~ s/^ *//g;
   $title =~ s/ *$//g;

   return ($lang, $title, $subtitle, $istv);
}
