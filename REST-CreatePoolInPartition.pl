#!/usr/bin/perl

use LWP;
use LWP::UserAgent;
use Data::Dumper;
use JSON;
use Scalar::Util qw(reftype);
use HTTP::Request::Common;
use MIME::Base64;
use Getopt::Long;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

$Data::Dumper::Deepcopy = 1;

my $JSONDECODER = JSON->new->allow_nonref;

my $BIGIP = "";
my $USER = "";
my $PASS = "";
my $POOL = "";
my $PARTITION = "";
my $AUTH_TOKEN = "";
my $RESOURCE = "";
my $DEBUG = 0;

GetOptions(
	'bigip=s' => \$BIGIP,
	"user=s" => \$USER,
	"pass=s" => \$PASS,
	"user=s" => \$USER,
	"pool=s" => \$POOL,
	"partition=s" => \$PARTITION,
	"debug" => \$DEBUG
);

sub usage() {
	print "Usage: REST-CreatePoolInPartition.pl [options] \n";
	print "     options\n";
	print "     ----------------\n";
	print "     --bigip bigip_addr\n";
	print "     --user  bigip_username\n";
	print "     --pass  bigip_password\n";
	print "     --pool  pool_name\n";
	print "     --partition  partition_name\n";
	print "\n";
	exit();
};

#---------------------------------------------------
sub getAuthToken() {
#---------------------------------------------------
	$url = "https://${BIGIP}/mgmt/shared/authn/login";
	$user = $USER;
	$pass = $PASS;

	$body = "{'username':'$user','password':'$pass','loginProviderName':'tmos'}";

	$json = postHttpRequest($url, $body, 1);

	$obj = decode_json($json);
	$AUTH_TOKEN = $obj->{token}->{token};

	if ( $DEBUG ) {
		print "TOKEN: $AUTH_TOKEN\n";
	}

	return $AUTH_TOKEN;
}

#---------------------------------------------------
sub getHttpRequest() {
#---------------------------------------------------
	my ($url) = (@_);

	if ( $DEBUG ) {
		print "REQUESTING URL : ${url}\n";
	}

	$content = "";
	if ( $url ) {
		my $ua = LWP::UserAgent->new;
		my $req = HTTP::Request->new(GET => $url);
		#$req->authorization_basic($USER, $PASS);
		my $auth_token = &getAuthToken();
		if ( "" ne $auth_token ) {
			$req->header("X-F5-Auth-Token" => $auth_token);
		}

		$resp = $ua->request($req);
		if ( $DEBUG ) {
			print Dumper($resp);
		}

		if ( $resp->is_success ) {
			$content = $resp->content;
			#print "CONTENT: ${content}\n";
		} else {
			$code = $resp->code;
			$msg = $resp->message;
			$content = $resp->content;
			die "HTTP ERROR ${code} : \"${msg}\" : \"${content}\"\n";
		}
	}
	return $content;
}

#---------------------------------------------------
sub postHttpRequest() {
#---------------------------------------------------
	my ($url, $body, $basicauth) = (@_);

	if ( $DEBUG ) {
		print "REQUESTING URL (POST) : ${url}\n";
	}

	$content = "";
	if ( $url ) {
		my $ua = LWP::UserAgent->new;
		my $req = HTTP::Request->new(POST => $url);

		if ( $basicauth == 1 ) {
			$req->authorization_basic($USER, $PASS);
		} else {
			my $auth_token = &getAuthToken();
			if ( "" ne $auth_token ) {
				$req->header("X-F5-Auth-Token" => $auth_token);
			}
		}

		$req->header("Content-Type" => "application/json");
		$req->content($body);

		$resp = $ua->request($req);
		if ( $DEBUG ) {
			print Dumper($resp);
		}

		if ( $resp->is_success ) {
			$content = $resp->content;
			#print "CONTENT: ${content}\n";
		} else {
			$code = $resp->code;
			$msg = $resp->message;
			$content = $resp->content;
			die "HTTP ERROR ${code} : \"${msg}\" : \"${content}\"\n";
		}
	}
	return $content;
}

#---------------------------------------------------
sub buildURL() {
#---------------------------------------------------
	my ($resource) = @_;

	$url = "https://${BIGIP}/$resource";

	return $url;
}

#---------------------------------------------------
sub handleGET() {
#---------------------------------------------------
	my ($resource) = @_;

	$url = &buildURL($resource);

	$resp = &getHttpRequest($url);

	return $resp;
}

#---------------------------------------------------
sub handlePOST() {
#---------------------------------------------------
	my ($resource, $body) = @_;

	if ( $body eq "" ) { &usage(); }

	$url = &buildURL($resource);

	$resp = &postHttpRequest($url, $body);

	return $resp;
}

#---------------------------------------------------
sub getPoolList() {
#---------------------------------------------------
	$resp_json = &handleGET("/mgmt/tm/ltm/pool");
	$resp = decode_json($resp_json);
	@items = @{$resp->{"items"}};

	print "POOL NAMES\n";
	print "----------\n";
	foreach $item (@items) {
		$fullPath = $item->{"fullPath"};
		print "  $fullPath\n";
		print Dumper($item);
	}
}

#---------------------------------------------------
sub createPool() {
#---------------------------------------------------
	my ($pool, $partition) = @_;

	my $poolObj;
	$poolObj->{"name"} = $pool;
	$poolObj->{"partition"} = $partition;

	my $json = encode_json($poolObj);

print "JSON: $json\n";
exit();

	$resp = &handlePOST("/mgmt/tm/ltm/pool", $json);

	print Dumper($resp);
}



#===================================================

#===================================================


if ( ($BIGIP eq "") || ($USER eq "") || ($PASS eq "") ) {
	&usage();
} else {
	if ( ($POOL eq "") || ($PARTITION eq "") ) {
		&getPoolList($POOL, $PARTITION);
	} else {
		&createPool($POOL, $PARTITION);
	}
}
