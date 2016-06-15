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
  [string]$Pool = "",
  [string]$Partition = ""
);

#----------------------------------------------------------------------------
function Get-PoolList()
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
function Create-Pool()
#
#  Description:
#    This function creates a new pool if the given pool name doesn't
#    already exist.
#
#  Parameters:
#    Name       - The Name of the pool you wish to create.
#    Partition  - The name of the partition to place the pool in.
#----------------------------------------------------------------------------
{
  param(
    [string]$Name,
		[string]$Partition
  );

	$uri = "/mgmt/tm/ltm/pool";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);
	$headers.Add("Content-Type", "application/json");
	$obj = @{
		name=$Name
		partition=$Partition
	};
	$body = $obj | ConvertTo-Json

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method POST -Uri $link -Headers $headers -Credential $mycreds -Body $body;

	Write-Host "Pool ${Name} created in partition ${Partition}"
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
       Pool       - The Name of the pool to create.
       Partition  - The Partition to place the pool in.
"@;
}

#============================================================================
# Main application logic
#============================================================================
if ( ($Bigip.Length -eq 0) -or ($User.Length -eq 0) -or ($Pass.Length -eq 0) ) {
  Show-Usage;
} else {
	if ( ($Pool.Length -eq 0) -or ($Partition.Length -eq 0) ) {
		Get-PoolList;
	} else {
		Create-Pool -Name $Pool -Partition $Partition;
	}	
}
