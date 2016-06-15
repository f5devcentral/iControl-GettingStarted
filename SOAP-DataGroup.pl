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
use Data::Dumper;

$Data::Dumper::Deepcopy = 1;

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

#----------------------------------------------------------------------------
# Validate Arguments
#----------------------------------------------------------------------------
my $sHost = $ARGV[0];
my $sUID = $ARGV[1];
my $sPWD = $ARGV[2];
my $sDataGroup = $ARGV[3];
my $sAction = $ARGV[4];

if ( ($sHost eq "") or ($sUID eq "") or ($sPWD eq "") )
{
	die ("Usage: DataGroup.pl host uid pwd [datagroup action (create|remove_from_add_to|delete)]\n");
}

#----------------------------------------------------------------------------
# Transport Information
#----------------------------------------------------------------------------
sub SOAP::Transport::HTTP::Client::get_basic_credentials
{
	return "$sUID" => "$sPWD";
}

$Class = SOAP::Lite
	-> uri('urn:iControl:LocalLB/Class')
	-> proxy("https://$sHost/iControl/iControlPortal.cgi");
eval { $Class->transport->http_request->header
(
	'Authorization' => 
		'Basic ' . MIME::Base64::encode("$sUID:$sPWD", '')
); };

if ( $sDataGroup eq "" ) {
	&getDataGroupList();
} else {
	if ( $sAction eq "create" ) {
		&createDataGroup($sDataGroup);
	} elsif ( $sAction eq "remove_from" ) {
		&removeFromDataGroup($sDataGroup);
	} elsif ( $sAction eq "add_to" ) {
		&addToDataGroup($sDataGroup);
	} elsif ( $sAction eq "delete" ) {
		&deleteDataGroup($sDataGroup);
	} else {
		&getDataGroup($sDataGroup);
	}
}

#----------------------------------------------------------------------------
sub checkResponse()
#----------------------------------------------------------------------------
{
	my ($soapResponse) = (@_);
	if ( $soapResponse->fault )
	{
		print $soapResponse->faultcode, " ", $soapResponse->faultstring, "\n";
		exit();
	}
}

#----------------------------------------------------------------------------
sub getDataGroupList()
#----------------------------------------------------------------------------
{

	print "DATA GROUPS\n";
	print "-----------\n";
	$soapResponse = $Class->get_address_class_list();
	&checkResponse($soapResponse);
	@ClassList = @{$soapResponse->result};
	foreach $ClassName (@ClassList)
	{
		print "  $ClassName - address\n";
	}
	$soapResponse = $Class->get_string_class_list();
	&checkResponse($soapResponse);
	@ClassList = @{$soapResponse->result};
	foreach $ClassName (@ClassList)
	{
		print "  $ClassName - string\n";
	}
	$soapResponse = $Class->get_value_class_list();
	&checkResponse($soapResponse);
	@ClassList = @{$soapResponse->result};
	foreach $ClassName (@ClassList)
	{
		print "  $ClassName - value\n";
	}
}

#----------------------------------------------------------------------------
sub getDataGroup()
#----------------------------------------------------------------------------
{
	my ($datagroup) = @_;
	$soapResponse = $Class->get_string_class(
		SOAP::Data->name(class_names => [$datagroup])
	);
	my @StringClassA = @{$soapResponse->result};

	$soapResponse = $Class->get_string_class_member_data_value(
		SOAP::Data->name(class_members => [@StringClassA])
	);
	@DataValuesAofA = @{$soapResponse->result};
	@DataValuesA = @{$DataValuesAofA[0]};

	$len = scalar(@StringClassA);
	for ($i=0; $i < scalar(@StringClassA);  $i++) {
		$StringClass = $StringClassA[$i];
		$DataValueA = $DataValueAofA[$i];

		$name = $StringClass->{"name"};
		@members = @{$StringClass->{"members"}};

		print "Data Group $name: [\n";
		for($j=0; $j < scalar(@members); $j++) {
			my $member = @members[$j];
			my $value = $DataValuesA[$j];
			print "  { $member : $value }\n";
		}
		print "]\n";
	}
}

#----------------------------------------------------------------------------
sub createDataGroup()
#----------------------------------------------------------------------------
{
	my ($datagroup) = @_;

  my @names = ("a", "b", "c");

  my $StringClass =
  {
    name => $datagroup,
    members => [@names]
  };

	# Create Data group with names
	$soapResponse = $Class->create_string_class(
		SOAP::Data->name(classes => [$StringClass])
	);
	&checkResponse($soapResponse);

	# Set values
  # Build Values 2-D Array for values parameter
  my @valuesA = ("data 1", "data 2", "data 3");
  my @valuesAofA;
  push @valuesAofA, [@valuesA];
  $soapResponse = $Class->set_string_class_member_data_value
  (
    SOAP::Data->name(class_members => [$StringClass]),
    SOAP::Data->name(values => [@valuesAofA])
  );
  &checkResponse($soapResponse);

	&getDataGroup($datagroup);
}

#----------------------------------------------------------------------------
sub deleteDataGroup()
#----------------------------------------------------------------------------
{
	my ($datagroup) = @_;

	$soapResponse = $Class->delete_class(
		SOAP::Data->name(classes => [$datagroup])
	);
	&checkResponse($soapResponse);

	print "Data group $datagroup deleted...\n";
}

#----------------------------------------------------------------------------
sub removeFromDataGroup()
#----------------------------------------------------------------------------
{
	my ($datagroup) = @_;

  my @names = ("c");

  my $StringClass =
  {
    name => $datagroup,
    members => [@names]
  };

	# Create Data group with names
	$soapResponse = $Class->delete_string_class_member(
		SOAP::Data->name(class_members => [$StringClass])
	);
	&checkResponse($soapResponse);

	&getDataGroup($datagroup);
}

#----------------------------------------------------------------------------
sub addToDataGroup()
#----------------------------------------------------------------------------
{
	my ($datagroup) = @_;

  my @names = ("d", "e");

  my $StringClass =
  {
    name => $datagroup,
    members => [@names]
  };

	# Create Data group with names
	$soapResponse = $Class->add_string_class_member(
		SOAP::Data->name(class_members => [$StringClass])
	);
	&checkResponse($soapResponse);

	# Set values
  # Build Values 2-D Array for values parameter
  my @valuesA = ("data 4", "data 5");
  my @valuesAofA;
  push @valuesAofA, [@valuesA];
  $soapResponse = $Class->set_string_class_member_data_value
  (
    SOAP::Data->name(class_members => [$StringClass]),
    SOAP::Data->name(values => [@valuesAofA])
  );
  &checkResponse($soapResponse);

	&getDataGroup($datagroup);
}


