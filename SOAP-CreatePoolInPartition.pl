#!/usr/bin/perl
#----------------------------------------------------------------------------
# The contents of this file are subject to the "END USER LICENSE AGREEMENT FOR F5
# Software Development Kit for iControl"; you may not use this file except in
# compliance with the License. The License is included in the iControl
# Software Development Kit.
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is iControl Code and related documentation
# distributed by F5.
#
# The Initial Developer of the Original Code is F5 Networks,
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2004 F5 Networks,
# Inc. All Rights Reserved.  iControl (TM) is a registered trademark of F5 Networks, Inc.
#
# Alternatively, the contents of this file may be used under the terms
# of the GNU General Public License (the "GPL"), in which case the
# provisions of GPL are applicable instead of those above.  If you wish
# to allow use of your version of this file only under the terms of the
# GPL and not to allow others to use your version of this file under the
# License, indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by the GPL.
# If you do not delete the provisions above, a recipient may use your
# version of this file under either the License or the GPL.
#----------------------------------------------------------------------------

#use SOAP::Lite + trace => qw(method debug);
use SOAP::Lite;
use MIME::Base64;

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------
my $sHost = $ARGV[0];
my $sUID = $ARGV[1];
my $sPWD = $ARGV[2];
my $sPool = $ARGV[3];
my $sPartition = $ARGV[4];

if ( $Partition eq "") { $Partition = "/Dev"; }

if ( ($sHost eq "") or ($sUID eq "") or ($sPWD eq "") )
{
	die ("Usage: LocalLBPoolCreate.pl host uid pwd [pool_name partition]\n");
}

#----------------------------------------------------------------------------
# Transport Information
#----------------------------------------------------------------------------
sub SOAP::Transport::HTTP::Client::get_basic_credentials
{
	return "$sUID" => "$sPWD";
}

$Pool = SOAP::Lite
	-> uri('urn:iControl:LocalLB/Pool')
	-> proxy("https://$sHost/iControl/iControlPortal.cgi");
eval { $Pool->transport->http_request->header
(
	'Authorization' => 
		'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };

if ( $sPool eq "" )
{
	&getPoolList();
	#&getAllPoolInfo();
}
else
{
	&createPool($sPartition, $sPool);
	#&getPoolInfo($sPool);
}

#----------------------------------------------------------------------------
# checkResponse
#----------------------------------------------------------------------------
sub checkResponse()
{
	my ($soapResponse) = (@_);
	if ( $soapResponse->fault )
	{
		print $soapResponse->faultcode, " ", $soapResponse->faultstring, "\n";
		exit();
	}
}

#----------------------------------------------------------------------------
# getPoolList
#----------------------------------------------------------------------------
sub getPoolList()
{
	$soapResponse = $Pool->get_list();
	&checkResponse($soapResponse);
	my @pool_list = @{$soapResponse->result};
	print "POOL LIST\n";
	print "---------\n";
	foreach $pool (@pool_list) {
		print "  ${pool}\n";
	}
}

#----------------------------------------------------------------------------
# createPool()
#----------------------------------------------------------------------------
sub createPool()
{
	my ($partition, $pool) = @_;

	print "CREATING POOL $pool\n";

	my @pool_names = [$pool];
	my @lb_methods = ["LB_METHOD_ROUND_ROBIN"]; 
  $member = 
  {
    address => "10.10.10.10",
    port => 80
  };
  
  # memberA is the 1st dimension of the array, we need one for each pool
  push @memberA, $member;
  # memberAofA is the 2nd dimension. push pool members for each pool here.
  push @memberAofA, [@memberA];

	$soapResponse = $Pool->create(
		SOAP::Data->name( pool_names => ["/$partition/$pool"]),
		SOAP::Data->name( lb_methods => ["LB_METHOD_ROUND_ROBIN"]),
    SOAP::Data->name(members => [@memberAofA])
	);
	&checkResponse($soapResponse);

	print "POOL ${pool} created in partition ${partition}...\n";
}

