#!/usr/bin/perl -w
use strict;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);

##############################################################################
# Calculate a HEX SHA1 value for a file's contents
##############################################################################
sub filedigest
{
	my $file = shift;

	my $ctx = Digest::SHA1->new;

	unless (open FILE, "< $file")
	{
		print (STDERR "FATAL: could not open file [$file], errno => $! ");
		return "";
	}

	binmode FILE;

	my $digest = $ctx->addfile(*FILE)->hexdigest;

	close FILE;
	return $digest;
}
##############################################################################

1;
