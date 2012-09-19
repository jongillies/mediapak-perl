#!/usr/bin/perl -w
use strict;



sub dumbAssReadCache
{
	 my $file = shift;

	open(FILE, $file) || die("Could not open file!");
	my @raw_data=<FILE>;
	close FILE;

	chomp (@raw_data);

	# Remove any \r's that my have been part of a DOS generated file
	my $counter = 0;
	foreach my $line (@raw_data)
	{
		$raw_data[$counter] =~ s/\r//g;
		$counter++;
	}

#00 <file>
#01	<dev>1042</dev>
#02	<ino>89827333</ino>
#03	<mode>33252</mode>
#04      <nlink>1</nlink>
#05	<uid>2005</uid>
#06	<gid>2005</gid>
#07	<rdev>358851664</rdev>
#08	<size>31426782</size>
#09	<atime>1125883931</atime>
#10	<mtime>1125874619</mtime>
#11	<ctime>1125883808</ctime>
#12	<blksize>16384</blksize>
#13	<blocks>61440</blocks>
#14	<name>3 Doors Down - Away From The Sun - 01 - When I'm Gone.flac</name>
#15	<directory>/u/media/music/flac-albums/3 Doors Down/Away From the Sun</directory>
#16	<path>/u/media/music/flac-albums/3 Doors Down/Away From the Sun/3 Doors Down - Away From The Sun - 01 - When I'm Gone.flac</path>
#17	<sha1>7ddd09a4d7000181034622c92011988cf5735b4a</sha1>
#18	<computetime>2</computetime>
#19</file>

	my $cache;

	$cache->{dev} = $raw_data[1];    
	$cache->{dev} =~ s/^\t<dev>//g;
	$cache->{dev} =~ s/<\/dev>$//g;

	$cache->{ino} = $raw_data[2];    
	$cache->{ino} =~ s/^\t<ino>//g;
	$cache->{ino} =~ s/<\/ino>$//g;

	$cache->{mode} = $raw_data[3];    
	$cache->{mode} =~ s/^\t<mode>//g;
	$cache->{mode} =~ s/<\/mode>$//g;

	$cache->{nlink} = $raw_data[4];    
	$cache->{nlink} =~ s/^\t<nlink>//g;
	$cache->{nlink} =~ s/<\/nlink>$//g;

	$cache->{uid} = $raw_data[5];    
	$cache->{uid} =~ s/^\t<uid>//g;
	$cache->{uid} =~ s/<\/uid>$//g;

	$cache->{gid} = $raw_data[6];    
	$cache->{gid} =~ s/^\t<gid>//g;
	$cache->{gid} =~ s/<\/gid>$//g;

	$cache->{rdev} = $raw_data[7];    
	$cache->{rdev} =~ s/^\t<rdev>//g;
	$cache->{rdev} =~ s/<\/rdev>$//g;

	$cache->{size} = $raw_data[8];    
	$cache->{size} =~ s/^\t<size>//g;
	$cache->{size} =~ s/<\/size>$//g;

	$cache->{atime} = $raw_data[9];    
	$cache->{atime} =~ s/^\t<atime>//g;
	$cache->{atime} =~ s/<\/atime>$//g;

	$cache->{mtime} = $raw_data[10];    
	$cache->{mtime} =~ s/^\t<mtime>//g;
	$cache->{mtime} =~ s/<\/mtime>$//g;

	$cache->{ctime} = $raw_data[11];    
	$cache->{ctime} =~ s/^\t<ctime>//g;
	$cache->{ctime} =~ s/<\/ctime>$//g;

	$cache->{blksize} = $raw_data[12];    
	$cache->{blksize} =~ s/^\t<blksize>//g;
	$cache->{blksize} =~ s/<\/blksize>$//g;

	$cache->{blocks} = $raw_data[13];    
	$cache->{blocks} =~ s/^\t<blocks>//g;
	$cache->{blocks} =~ s/<\/blocks>$//g;

	$cache->{name} = $raw_data[14];    
	$cache->{name} =~ s/^\t<name>//g;
	$cache->{name} =~ s/<\/name>$//g;

	$cache->{directory} = $raw_data[15];    
	$cache->{directory} =~ s/^\t<directory>//g;
	$cache->{directory} =~ s/<\/directory>$//g;

	$cache->{path} = $raw_data[16];    
	$cache->{path} =~ s/^\t<path>//g;
	$cache->{path} =~ s/<\/path>$//g;

	$cache->{sha1} = $raw_data[17];
	$cache->{sha1} =~ s/^\t<sha1>//g;
	$cache->{sha1} =~ s/<\/sha1>$//g;

	$cache->{computetime} = $raw_data[18];    
	$cache->{computetime} =~ s/^\t<computetime>//g;
	$cache->{computetime} =~ s/<\/computetime>$//g;

	return ($cache);    

}
# This is a comment222222
1;
