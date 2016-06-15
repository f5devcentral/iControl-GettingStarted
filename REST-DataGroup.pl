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
my $DATAGROUP = "";
my $ACTION = "";
my $AUTH_TOKEN = "";
my $RESOURCE = "";
my $DEBUG = 0;

GetOptions(
	'bigip=s' => \$BIGIP,
	"user=s" => \$USER,
	"pass=s" => \$PASS,
	"user=s" => \$USER,
	"datagroup=s" => \$DATAGROUP,
	"action=s" => \$ACTION,
	"debug" => \$DEBUG
);

sub usage() {
	print "Usage: REST-DataGroup.pl [options] \n";
	print "     options\n";
	print "     ----------------\n";
	print "     --bigip bigip_addr\n";
	print "     --user  bigip_username\n";
	print "     --pass  bigip_password\n";
	print "     --datagroup  dg_name\n";
	print "     --action  [create|remove_from|add_to|delete]\n";
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

	$json = httpRequestWithBody("POST", $url, $body, 1);

	$obj = decode_json($json);
	$AUTH_TOKEN = $obj->{token}->{token};

	if ( $DEBUG ) {
		print "TOKEN: $AUTH_TOKEN\n";
	}

	return $AUTH_TOKEN;
}

#---------------------------------------------------
sub httpRequestWithoutBody() {
#---------------------------------------------------
	my ($verb, $url) = (@_);

	if ( $DEBUG ) {
		print "REQUESTING URL : ${url} ${verb}\n";
	}

	$content = "";
	if ( $url ) {
		my $ua = LWP::UserAgent->new;
		my $req;
		if ( $verb eq "DELETE" ) {
			$req = HTTP::Request->new(DELETE => $url);
		} else {
			$req = HTTP::Request->new(GET => $url);
		}
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
sub httpRequestWithBody() {
#---------------------------------------------------
	my ($verb, $url, $body, $basicauth) = (@_);

	if ( $DEBUG ) {
		print "REQUESTING URL (POST) : ${url}\n";
	}

	$content = "";
	if ( $url ) {
		my $ua = LWP::UserAgent->new;

		my $req;
		if ( $verb eq "PUT" ) {
			$req = HTTP::Request->new(PUT => $url);
		} elsif ( $verb eq "PATCH" ) {
			$req = HTTP::Request->new(PATCH => $url);
		} else {
			$req = HTTP::Request->new(POST => $url);
		}

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

	$resp = &httpRequestWithoutBody("GET", $url);

	return $resp;
}

#---------------------------------------------------
sub handleDELETE() {
#---------------------------------------------------
	my ($resource) = @_;

	$url = &buildURL($resource);

	$resp = &httpRequestWithoutBody("DELETE", $url);

	return $resp;
}

#---------------------------------------------------
sub handlePOST() {
#---------------------------------------------------
	my ($resource, $body) = @_;

	if ( $body eq "" ) { &usage(); }

	$url = &buildURL($resource);

	$resp = &httpRequestWithBody("POST", $url, $body);

	return $resp;
}

#---------------------------------------------------
sub handlePUT() {
#---------------------------------------------------
	my ($resource, $body) = @_;

	if ( $body eq "" ) { &usage(); }

	$url = &buildURL($resource);

	$resp = &httpRequestWithBody("PUT", $url, $body);

	return $resp;
}

#---------------------------------------------------
sub handlePATCH() {
#---------------------------------------------------
	my ($resource, $body) = @_;

	if ( $body eq "" ) { &usage(); }

	$url = &buildURL($resource);

	$resp = &httpRequestWithBody("PATCH", $url, $body);

	return $resp;
}

#---------------------------------------------------
sub getDataGroupList() {
#---------------------------------------------------
	$uri = "/mgmt/tm/ltm/data-group/internal";
	$resp_json = &handleGET($uri);
	$resp = decode_json($resp_json);
	@items = @{$resp->{"items"}};

	print "DATA GROUPS\n";
	print "----------\n";
	foreach $item (@items) {
		$fullPath = $item->{"fullPath"};
		print "  $fullPath\n";
		#print "-----------------------------------\n";
		#print Dumper($item);
		#print "-----------------------------------\n";
	}
}

#---------------------------------------------------
sub getDataGroup() {
#---------------------------------------------------
	my ($datagroup) = @_;
	$datagroup =~ s/\//~/g;
	my $uri = "/mgmt/tm/ltm/data-group/internal/${datagroup}";
	$resp_json = &handleGET($uri);
	$resp = decode_json($resp_json);

	print Dumper($resp);
}

#---------------------------------------------------
sub createDataGroup() {
#---------------------------------------------------
	my ($datagroup) = @_;

	print "CREATE DATA GROUP\n";

	my $uri = "/mgmt/tm/ltm/data-group/internal";

	my $dgObj;
	$dgObj->{"name"} = $datagroup;
	$dgObj->{"type"} = "string";

	$dgObj->{"records"} = [
		{ name => 'a', data => 'data 1' },
		{ name => 'b', data => 'data 2' },
		{ name => 'c', data => 'data 3' }
	];

	my $json = encode_json($dgObj);

	$resp = &handlePOST($uri, $json);
	print Dumper($resp);
}

#---------------------------------------------------
sub deleteDataGroup($DATAGROUP) {
#---------------------------------------------------
	my ($datagroup) = @_;

	$datagroup =~ s/\//~/g;
	$uri = "/mgmt/tm/ltm/data-group/internal/${datagroup}";

	$resp = &handleDELETE($uri);
	print Dumper($resp);
}

#---------------------------------------------------
sub removeFromDataGroup($DATAGROUP) {
#---------------------------------------------------
	my ($datagroup) = @_;

	$datagroup =~ s/\//~/g;
	$uri = "/mgmt/tm/ltm/data-group/internal/${datagroup}";

	my $dgObj;
	$dgObj->{"name"} = $datagroup;

	$dgObj->{"records"} = [
		{ name => 'a', data => 'data 1' },
		{ name => 'b', data => 'data 2' }
	];

	my $json = encode_json($dgObj);

	$resp = &handlePATCH($uri, $json);
	print Dumper($resp);
	
}

#---------------------------------------------------
sub addToDataGroup($DATAGROUP) {
#---------------------------------------------------
	my ($datagroup) = @_;

	$datagroup =~ s/\//~/g;
	$uri = "/mgmt/tm/ltm/data-group/internal/${datagroup}";

	my $dgObj;
	$dgObj->{"name"} = $datagroup;

	$dgObj->{"records"} = [
		{ name => 'a', data => 'data 1' },
		{ name => 'b', data => 'data 2' },
		{ name => 'd', data => 'data 4' },
		{ name => 'e', data => 'data 5' }
	];

	my $json = encode_json($dgObj);

	$resp = &handlePUT($uri, $json);
	print Dumper($resp);
	
}

#===================================================

#===================================================


if ( ($BIGIP eq "") || ($USER eq "") || ($PASS eq "") ) {
	&usage();
} else {
	if ( $DATAGROUP eq "" ) {
		&getDataGroupList();
	} else {
		if ( $ACTION eq "create" ) {
			&createDataGroup($DATAGROUP);
		} elsif ( $ACTION eq "remove_from" ) {
			&removeFromDataGroup($DATAGROUP);
		} elsif ( $ACTION eq "add_to" ) {
			&addToDataGroup($DATAGROUP);
		} elsif ( $ACTION eq "delete" ) {
			&deleteDataGroup($DATAGROUP);
		} else {
			&getDataGroup($DATAGROUP);
		}
	}
}
