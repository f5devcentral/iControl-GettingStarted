#----------------------------------------------------------------------------
# The contents of this file are subject to the "END USER LICENSE AGREEMENT 
# FOR F5 Software Development Kit for iControl"; you may not use this file 
# except in compliance with the License. The License is included in the 
# iControl Software Development Kit.
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
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2009 
# F5 Networks, Inc. All Rights Reserved.  iControl (TM) is a registered 
# trademark of F5 Networks, Inc.
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
param(
  [string]$Bigip = "",
  [string]$User = "",
  [string]$Pass = "",
  [string]$Type = "",
  [string]$Name = ""
);

#----------------------------------------------------------------------------
function Get-StatsValue()
#
#  Description:
#    This function extracts a named property from an object
#----------------------------------------------------------------------------
{
	param($obj, $prop);
	return ($obj.entries | Select -ExpandProperty $prop).value
}

#----------------------------------------------------------------------------
function Get-StatsDescription()
#
#  Description:
#    This function extracts a named description from an object
#----------------------------------------------------------------------------
{
	param($obj, $prop);
	return ($obj.entries | Select -ExpandProperty $prop).description
}

#----------------------------------------------------------------------------
function Get-VirtualList()
#
#  Description:
#    This function lists all virtual servers.
#
#  Parameters:
#    None
#----------------------------------------------------------------------------
{
	$uri = "/mgmt/tm/ltm/virtual";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method GET -Headers $headers -Uri $link -Credential $mycreds
	$items = $obj.items;
	Write-Host "POOL NAMES";
	Write-Host "----------";
	for($i=0; $i -lt $items.length; $i++) {
		$name = $items[$i].fullPath;
		Write-Host "  $name";
	}
}

#----------------------------------------------------------------------------
function Get-VirtualStats()
#
#  Description:
#    This function returns the statistics for a virtual server
#
#  Parameters:
#    Name - The name of the virtual server
#----------------------------------------------------------------------------
{
  param(
    [string]$Name
	);
	$uri = "/mgmt/tm/ltm/virtual/${Name}/stats";

	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method GET -Headers $headers -Uri $link -Credential $mycreds

	$entries = $obj.entries;
	$names = $entries | get-member -MemberType NoteProperty | select -ExpandProperty Name;

	$desc = $entries | Select -ExpandProperty $names
	$nestedStats = $desc.nestedStats;

	Write-Host ("--------------------------------------");
	Write-Host ("NAME                  : $(Get-StatsDescription $nestedStats 'tmName')");
	Write-Host ("--------------------------------------");
	Write-Host ("DESTINATION           : $(Get-StatsDescription $nestedStats 'destination')");
	Write-Host ("AVAILABILITY STATE    : $(Get-StatsDescription $nestedStats 'status.availabilityState')");
	Write-Host ("ENABLED STATE         : $(Get-StatsDescription $nestedStats 'status.enabledState')");
	Write-Host ("REASON                : $(Get-StatsDescription $nestedStats 'status.statusReason')");
	Write-Host ("CLIENT BITS IN        : $(Get-StatsValue $nestedStats 'clientside.bitsIn')");
	Write-Host ("CLIENT BITS OUT       : $(Get-StatsValue $nestedStats 'clientside.bitsOut')");
	Write-Host ("CLIENT PACKETS IN     : $(Get-StatsValue $nestedStats 'clientside.pktsIn')");
	Write-Host ("CLIENT PACKETS OUT    : $(Get-StatsValue $nestedStats 'clientside.pktsOut')");
	Write-Host ("CURRENT CONNECTIONS   : $(Get-StatsValue $nestedStats 'clientside.curConns')");
	Write-Host ("MAXIMUM CONNECTIONS   : $(Get-StatsValue $nestedStats 'clientside.maxConns')");
	Write-Host ("TOTAL CONNECTIONS     : $(Get-StatsValue $nestedStats 'clientside.totConns')");
	Write-Host ("TOTAL REQUESTS        : $(Get-StatsValue $nestedStats 'totRequests')");
}

#----------------------------------------------------------------------------
function Get-PoolList()
#
#  Description:
#    This function returns the list of pools
#
#  Parameters:
#    None
#----------------------------------------------------------------------------
{
	$uri = "/mgmt/tm/ltm/pool";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method GET -Headers $headers -Uri $link -Credential $mycreds
	$items = $obj.items;
	Write-Host "POOL NAMES";
	Write-Host "----------";
	for($i=0; $i -lt $items.length; $i++) {
		$name = $items[$i].fullPath;
		Write-Host "  $name";
	}
}

#----------------------------------------------------------------------------
function Get-PoolStats()
#
#  Description:
#    This function returns the statistics for a pool
#
#  Parameters:
#    Name - The name of the pool
#----------------------------------------------------------------------------
{
	$uri = "/mgmt/tm/ltm/pool/${Name}/stats";

	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method GET -Headers $headers -Uri $link -Credential $mycreds

	$entries = $obj.entries;
	$names = $entries | get-member -MemberType NoteProperty | select -ExpandProperty Name;

	$desc = $entries | Select -ExpandProperty $names
	$nestedStats = $desc.nestedStats;

	Write-Host ("--------------------------------------");
	Write-Host ("NAME                  : $(Get-StatsDescription $nestedStats 'tmName')");
	Write-Host ("--------------------------------------");
	Write-Host ("AVAILABILITY STATE    : $(Get-StatsDescription $nestedStats 'status.availabilityState')");
	Write-Host ("ENABLED STATE         : $(Get-StatsDescription $nestedStats 'status.enabledState')");
	Write-Host ("REASON                : $(Get-StatsDescription $nestedStats 'status.statusReason')");
	Write-Host ("SERVER BITS IN        : $(Get-StatsValue $nestedStats 'serverside.bitsIn')");
	Write-Host ("SERVER BITS OUT       : $(Get-StatsValue $nestedStats 'serverside.bitsOut')");
	Write-Host ("SERVER PACKETS IN     : $(Get-StatsValue $nestedStats 'serverside.pktsIn')");
	Write-Host ("SERVER PACKETS OUT    : $(Get-StatsValue $nestedStats 'serverside.pktsOut')");
	Write-Host ("CURRENT CONNECTIONS   : $(Get-StatsValue $nestedStats 'serverside.curConns')");
	Write-Host ("MAXIMUM CONNECTIONS   : $(Get-StatsValue $nestedStats 'serverside.maxConns')");
	Write-Host ("TOTAL CONNECTIONS     : $(Get-StatsValue $nestedStats 'serverside.totConns')");
	Write-Host ("TOTAL REQUESTS        : $(Get-StatsValue $nestedStats 'totRequests')");
}

#----------------------------------------------------------------------------
function Show-Usage()
#
#  Description:
#    This function will print the script usage information.
#
#----------------------------------------------------------------------------
{
  Write-Host @"
Usage: CreatePoolInPartition.ps1 Arguments
       Argument   - Description
       ----------   -----------
       Bigip      - The ip/hostname of your BIG-IP.
       User       - The Managmenet username for your BIG-IP.
       Pass       - The Management password for your BIG-IP.
       Type       - The type of object [virtual|pool].
       Name       - The name of the object to get stats for.
"@;
}

#============================================================================
# Main application logic
#============================================================================
if ( ($Bigip.Length -eq 0) -or ($User.Length -eq 0) -or ($Pass.Length -eq 0) -or ($Type.Length -eq 0) ) {
  Show-Usage;
} elseif ( $Type -eq "virtual" ) {
	if ( $Name.Length -eq 0 ) {
		Get-VirtualList;
	} else {
		Get-VirtualStats -Name $Name;
	}
} elseif ( $Type -eq "pool" ) {
	if ( $Name.Length -eq 0 ) {
		Get-PoolList;
	} else {
		Get-PoolStats -Name $Name;
	}
}
