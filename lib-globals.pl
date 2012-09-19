#!/usr/bin/perl -w
use strict;

#
# Global Variables
#
our $DEBUG;                              # Usually activated by -d on the command line
our $CACHE_FOLDER;                       # Platform specific xml folder (.mc or _mc)
our $CACHE_EXTENTION = ".xml";           # Extention to use for cache files
our $RUNNINGWINDOWS = $^O =~ /MS/;       # Are we running on Windows?

#
# NOTE: 2007-04-18 I decided to use a .mc folder for Windows too.
# This enables me to do ckpaks between Windows and non-Windows shares.
# The code will still ingore the _mc folders for legacy reasons
#
our $WINDOWS_CACHE_FOLDER=".mc";         # Windows does not like "." directories so use _

our $UNIX_CACHE_FOLDER=".mc";            # UNIX likes "." files.. they are "hidden"
our $OFFLINE_CACHE;                      # Off-line media cache file location (folder)


# Set the appropriate CACHE_FOLDER for the platform
$RUNNINGWINDOWS ? ($CACHE_FOLDER = $WINDOWS_CACHE_FOLDER) : ($CACHE_FOLDER = $UNIX_CACHE_FOLDER);

1;
