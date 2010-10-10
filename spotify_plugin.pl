use warnings;
use strict;

use vars qw($VERSION %IRSSI);

$VERSION = '0.1';

%IRSSI = (
	authors			=> 'Daniel Bond',
  name 				=> 'Spotify lookup',
  description => 'Resolves spotify URIs',
	license			=> 'GPL',
	url					=> 'http://danielbond.org'
);

use Irssi;
use Net::Spotify;
use XML::XPath;

my $spotify = new Net::Spotify;

sub own_spotify_request {
	my($server, $msg, $target) = @_;
	# make own spotify links work too!
	spotify_request($server,$msg,$server->{nick},$target);
}

sub public_spotify_request {
	my($server, $msg, $nick, $address, $target) = @_;

	spotify_request($server,$msg,$nick,$target);
}

sub spotify_request {
	my($server,$msg,$nick,$target) = @_;

	# make plugin understand http-based links too
	$msg =~ s/open.spotify.com\/(track|album|artist)\/(\S+)/spotify:$1:$2/;

	# we found a track
	if($msg =~ /(spotify:(track|album|artist):\S+)/ && $target ne '#linux.no') {
		# lookup a spotify uri
		my $data = $spotify->lookup( uri => $1 );

		# check for invalid track (Net::Spotify completly lacks error-handling)
		if(substr($data,0,1) ne '<') { return; }

		# parse the resulting XML
		my $x = XML::XPath->new( xml => $data );
		my $output = "";
		if($x->exists('/track')) {
			my $name =  $x->findvalue('/track/name');
			my $artist = $x->findvalue('/track/artist/name');
			my $album = $x->findvalue('/track/album/name');

			$output = "spotify track: '$name' by '$artist' ($album)";
		} elsif($x->exists('/album')) {
			my $name = $x->findvalue('/album/name');
			my $artist = $x->findvalue('/album/artist/name');
			my $released = $x->findvalue('/album/released');

			$output = "spotify album: '$name' by '$artist' ($released)";
		} elsif($x->exists('/artist')) {
			my $artist = $x->findvalue('/artist/name');

			$output = "spotify artist: '$artist'";
		}

		if($output) {
			$server->command("^NOTICE $target ($nick) $output");
			$server->print($target, "$nick posted $output", MSGLEVEL_NOTICES);
		}
	}
}

Irssi::signal_add('message public', 'public_spotify_request');
Irssi::signal_add('message own_public', 'own_spotify_request');

