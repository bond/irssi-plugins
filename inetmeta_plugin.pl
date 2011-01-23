use warnings;
use strict;

use vars qw($VERSION %IRSSI);

$VERSION = '0.1';

%IRSSI = (
	authors			=> 'Daniel Bond',
  name 				=> 'Internet-link url meta lookup',
  description => 'Provides meta-information for URLs',
	license			=> 'GPL',
	url					=> 'http://danielbond.org'
);

use Irssi;
use POSIX qw/floor/;
use URI;
use WebService::GData::YouTube;

my $yt = new WebService::GData::YouTube();

sub own_inetmeta_request {
	my($server, $msg, $target) = @_;

	inetmeta_request($server,$msg,$server->{nick},$target);
}

sub public_inetmeta_request {
	my($server, $msg, $nick, $address, $target) = @_;

	inetmeta_request($server,$msg,$nick,$target);
}

sub channel_is_target {
    my $target = shift;
    return 0 unless $target;

    my $filter = Irssi::settings_get_str('inetmeta_channels');

    # if no channels are set enable it on all
    return 1 unless( $filter );
    return 1 if ($filter =~ /^\s*$/);

    foreach ( split(/\s*,\s*/, $filter) ) {
	return 1 if( lc($target) eq lc($_) );
    }
    return 0;
}

sub inetmeta_request {
	my($server,$msg,$nick,$target) = @_;

	# /set inetmeta_channels #channel1, #channel2
	return unless ( channel_is_target($target) );
	    
	# match URLs
	if ( $msg =~ /\b(http:\/\/[^\s\b]+)\b/ ) {
		my $u = new URI($1);

		# youtube?
		if( $u->host =~ /youtube\.com$/ &&
				($u->path eq '/watch' || $u->path eq '/watch/') &&
				($u->query =~ /v=([^&]+)/) ) {

				my $video;
				my $duration;

				# lookup youtube
				eval { $video = $yt->get_video_by_id($1); };
				return if $@;

				$duration = floor( $video->duration / 60 ) . "m" if ( $video->duration >= 60 );
				$duration .= ( $video->duration % 60 ) . "s";
				
				$server->command("^NOTICE $target ($nick) YouTube: " . $video->title . " ($duration, " . $video->view_count . " views)");
				$server->print($target, "$nick posted YouTube: " . $video->title . " ($duration, " . $video->view_count . " views)");
		}
	}

}

Irssi::signal_add('message public', 'public_inetmeta_request');
Irssi::signal_add('message own_public', 'own_inetmeta_request');

Irssi::settings_add_str('inetmeta', 'inetmeta_channels', "");
