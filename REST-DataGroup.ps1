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
  [string]$Datagroup = "",
  [string]$Action = ""
);

#----------------------------------------------------------------------------
function Get-DataGroupList()
#
#  Description:
#    This function lists out all existing internal data groups
#
#  Parameters:
#    None
#----------------------------------------------------------------------------
{
	$uri = "/mgmt/tm/ltm/data-group/internal";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method GET -Headers $headers -Uri $link -Credential $mycreds
	$items = $obj.items;
	Write-Host "DATA GROUPS";
	Write-Host "----------";
	for($i=0; $i -lt $items.length; $i++) {
		$name = $items[$i].fullPath;
		Write-Host "  $name";
	}
}

#----------------------------------------------------------------------------
function Get-DataGroup()
#
#  Description:
#    This function lists the contents of a given data group
#
#  Parameters:
#    Name    - The name of the data group.
#----------------------------------------------------------------------------
{
	$uri = "/mgmt/tm/ltm/data-group/internal/${Name}";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method GET -Headers $headers -Uri $link -Credential $mycreds
	$obj | Format-List
}


#----------------------------------------------------------------------------
function Delete-DataGroup()
#
#  Description:
#    This function lists the contents of the given data group
#
#  Parameters:
#    Name        - The name of the data group
#----------------------------------------------------------------------------
{
  param(
    [string]$Name
  );

	$uri = "/mgmt/tm/ltm/data-group/internal/${Name}";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method DELETE -Headers $headers -Uri $link -Credential $mycreds
	Write-Host "Data Group ${Name} has been deleted..."
}


#----------------------------------------------------------------------------
function Create-DataGroup()
#
#  Description:
#    This function creates a new internal data group
#
#  Parameters:
#    Name       - The Name of the data group
#----------------------------------------------------------------------------
{
  param(
    [string]$Name
  );

	$uri = "/mgmt/tm/ltm/data-group/internal";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);
	$headers.Add("Content-Type", "application/json");
	$obj = @{
		name=$Name
		type="string"
		records= (
			@{ name="a"
				data="data 1"
			},
			@{ name="b"
				data="data 2"
			},
			@{ name="c"
				data="data 3"
			}
		)
	};
	$body = $obj | ConvertTo-Json

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method POST -Uri $link -Headers $headers -Credential $mycreds -Body $body;

	Write-Host "Pool ${Name} created in partition ${Partition}"
}

#----------------------------------------------------------------------------
function RemoveFrom-DataGroup()
#
#  Description:
#    This function removes an entry from a data group
#
#  Parameters:
#    Name       - The Name of the data group
#----------------------------------------------------------------------------
{
  param(
    [string]$Name
  );

	$uri = "/mgmt/tm/ltm/data-group/internal/${Name}";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);
	$headers.Add("Content-Type", "application/json");
	$obj = @{
		name=$Name
		records= (
			@{ name="a"
				data="data 1"
			},
			@{ name="b"
				data="data 2"
			}
		)
	};
	$body = $obj | ConvertTo-Json

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method PATCH -Uri $link -Headers $headers -Credential $mycreds -Body $body;

	$obj | Format-List
}

#----------------------------------------------------------------------------
function AddTo-DataGroup()
#
#  Description:
#    This function adds records to an existing data group
#
#  Parameters:
#    Name       - The Name of the data group
#----------------------------------------------------------------------------
{
  param(
    [string]$Name
  );

	$uri = "/mgmt/tm/ltm/data-group/internal/${Name}";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);
	$headers.Add("Content-Type", "application/json");
	$obj = @{
		name=$Name
		records= (
			@{ name="a"
				data="data 1"
			},
			@{ name="b"
				data="data 2"
			},
			@{ name="d"
				data="data 4"
			},
			@{ name="e"
				data="data 5"
			}
		)
	};
	$body = $obj | ConvertTo-Json

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method PATCH -Uri $link -Headers $headers -Credential $mycreds -Body $body;

	$obj | Format-List
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
Usage: DataGroup.ps1 Arguments
       Argument   - Description
       ----------   -----------
       Bigip      - The ip/hostname of your BIG-IP.
       User       - The Managmenet username for your BIG-IP.
       Pass       - The Management password for your BIG-IP.
       Datagroup  - The name of the data group.
       Action     - The action to complete [create|remove_from|add_to|delete].
"@;
}

#============================================================================
# Main application logic
#============================================================================
if ( ($Bigip.Length -eq 0) -or ($User.Length -eq 0) -or ($Pass.Length -eq 0) ) {
  Show-Usage;
} else {
	if ( $Datagroup.Length -eq 0 ) {
		Get-DataGroupList;
	} else {
		if ( $Action -eq "create" ) {
			Create-DataGroup -Name $Datagroup;
		} elseif ( $Action -eq "remove_from" ) {
			RemoveFrom-DataGroup -Name $Datagroup;
		} elseif ( $Action -eq "add_to" ) { 
			AddTo-DataGroup -Name $Datagroup;
		} elseif ( $Action -eq "delete" ) {
			Delete-DataGroup -Name $Datagroup;
		} else {
			Get-DataGroup -Name $Datagroup;
		}
	}
}
