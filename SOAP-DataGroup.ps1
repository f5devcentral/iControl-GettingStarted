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
  [string]$DataGroup = "",
  [string]$Action = ""
);


#-------------------------------------------------------------------------
function Do-Initialize()
#
#  Description:
#    This function will verify that the iControl PowerShell Snapin is loaded
#    in the current runspace.
#
#-------------------------------------------------------------------------
{
  if ( (Get-PSSnapin | Where-Object { $_.Name -eq "iControlSnapIn"}) -eq $null )
  {
    Add-PSSnapIn iControlSnapIn
  }
  $success = Initialize-F5.iControl -HostName $Bigip -Username $User -Password $Pass;
  
  return $success;
}

#-------------------------------------------------------------------------
function Get-DataGroupList()
#-------------------------------------------------------------------------
{
	Write-Host "POOL LIST";
	Write-Host "---------";
  $pool_list = $(Get-F5.iControl).LocalLBClass.get_address_class_list();
  foreach($pool in $pool_list)
  {
		Write-Host "  $pool - address";
	}
  $pool_list = $(Get-F5.iControl).LocalLBClass.get_string_class_list();
  foreach($pool in $pool_list)
  {
		Write-Host "  $pool - string";
	}
  $pool_list = $(Get-F5.iControl).LocalLBClass.get_value_class_list();
  foreach($pool in $pool_list)
  {
		Write-Host "  $pool - value";
	}
}

#-------------------------------------------------------------------------
function Get-DataGroup()
#-------------------------------------------------------------------------
{
  param(
    [string]$Name
	);

	$StringClassA = $(Get-F5.iControl).LocalLBClass.get_string_class(
		(, $Name)
	);

	$DataValuesAofA = $(Get-F5.iControl).LocalLBClass.get_string_class_member_data_value(
		$StringClassA
	);

	for($i=0; $i -lt $StringClassA.Length; $i++) {
		$StringClass = $StringClassA[$i];
		$DataValuesA = $DataValuesAofA[$i];

		$name = $StringClass.name;
		$members = $StringClass.members;

		Write-Host "Data Group ${Name} : [";
		for($j=0; $j -lt $members.Length; $j++) {
			$member = $members[$j];
			$value = $DataValuesA[$j];

			Write-Host "  { $member : $value }";
		}
		Write-Host "]";
	}

}

#-------------------------------------------------------------------------
function Delete-DataGroup()
#-------------------------------------------------------------------------
{
	param(
		[string]$Name
	);

	$(Get-F5.iControl).LocalLBClass.delete_class( (, $Name) );
	Write-Host "Data Group ${Name} deleted..."
}

#-------------------------------------------------------------------------
function Create-DataGroup()
#-------------------------------------------------------------------------
{
	param(
		[string]$Name
	);

	$StringClassA = New-Object -TypeName iControl.LocalLBClassStringClass[] 1;
	$StringClassA[0] = New-Object -TypeName iControl.LocalLBClassStringClass;
	$StringClassA[0].name = $Name;
	$StringClassA[0].members = ("a", "b", "c");

	$(Get-F5.iControl).LocalLBClass.create_string_class(
		$StringClassA
	);

	$DataValueA = ("data 1", "data 2", "data 3");
	$DataValuesAofA = 
	$(Get-F5.iControl).LocalLBClass.set_string_class_member_data_value(
		$StringClassA,
		(, $DataValueA)
	)
		
	Get-DataGroup -Name $Name;
}

#-------------------------------------------------------------------------
function RemoveFrom-DataGroup()
#-------------------------------------------------------------------------
{
	param(
		[string]$Name
	);

	$StringClassA = New-Object -TypeName iControl.LocalLBClassStringClass[] 1;
	$StringClassA[0] = New-Object -TypeName iControl.LocalLBClassStringClass;
	$StringClassA[0].name = $Name;
	$StringClassA[0].members = ("c");

	$(Get-F5.iControl).LocalLBClass.delete_string_class_member(
		$StringClassA
	);
		
	Get-DataGroup -Name $Name;
}

#-------------------------------------------------------------------------
function AddTo-DataGroup()
#-------------------------------------------------------------------------
{
	param(
		[string]$Name
	);

	$StringClassA = New-Object -TypeName iControl.LocalLBClassStringClass[] 1;
	$StringClassA[0] = New-Object -TypeName iControl.LocalLBClassStringClass;
	$StringClassA[0].name = $Name;
	$StringClassA[0].members = ("d", "e");

	$(Get-F5.iControl).LocalLBClass.add_string_class_member(
		$StringClassA
	);

	$DataValueA = ("data 4", "data 5");
	$DataValuesAofA = 
	$(Get-F5.iControl).LocalLBClass.set_string_class_member_data_value(
		$StringClassA,
		(, $DataValueA)
	)
		
	Get-DataGroup -Name $Name;
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
if ( ($Bigip.Length -eq 0) -or ($User.Length -eq 0) -or ($Pass.Length -eq 0) )
{
  Show-Usage;
} else {
	if ( Do-Initialize ) {
		if ( $DataGroup.Length -eq 0 ) {
			Get-DataGroupList;
		} elseif ( $Action -eq "create" ) {
			Create-DataGroup -Name $DataGroup;
		} elseif ( $Action -eq "remove_from" ) {
			RemoveFrom-DataGroup -Name $DataGroup;
		} elseif ( $Action -eq "add_to" ) {
			AddTo-DataGroup -Name $DataGroup;
		} elseif ( $Action -eq "delete" ) {
			Delete-DataGroup -Name $DataGroup;
		} else {
			Get-DataGroup -Name $DataGroup;
		}
	} else {
    Write-Error "ERROR: iControl subsystem not initialized"
	}
}
