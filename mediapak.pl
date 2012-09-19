#!/usr/bin/perl -w
use strict;
use XML::Simple;

my $xsimple = XML::Simple->new();
my %data =
(
	'medialocation' => [
				{
				  'mediapath' => '/media/001/dvd2avi',
				  'cachepath' => '/u/media/.mediapak/data/dvd2avi-001.txt',
				  'comment'   => 'AVI Files'
				},
				{
				  'mediapath' => '/media/002/dvd2avi',
				  'cachepath' => '/u/media/.mediapak/data/dvd2avi-002.txt',
				  'comment'   => 'More AVI Files'
				}
			  ]
);


my $xml_string = $xsimple->XMLout(\%data, noattr => 1, RootName=>'config', xmldecl => '<?xml version="1.0"?>');

print ("$xml_string\n");

print "Stuff: " . $data{medialocation}[0]{mediapath} . "\n";
print "Stuff: " . $data{medialocation}[1]{mediapath} . "\n";

my @foo = $data{medialocation};

print "heh \n";







