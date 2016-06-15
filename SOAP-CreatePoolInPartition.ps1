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
  $pool_list = $(Get-F5.iControl).LocalLBPool.get_list();
	Write-Host "POOL LIST";
	Write-Host "---------";
  foreach($pool in $pool_list)
  {
		Write-Host "  $pool";
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
#    MemberList - A string list of pool member addresses.
#    MemberPort - The port the pool members will be configured with.
#----------------------------------------------------------------------------
{
  param(
    [string]$Name,
    [string[]]$MemberList,
    [int]$MemberPort
  );
  
  $IPPortDefList = New-Object -TypeName iControl.CommonIPPortDefinition[] $MemberList.Length;
  for($i=0; $i-lt$MemberList.Length; $i++)
  {
    $IPPortDefList[$i] = New-Object -TypeName iControl.CommonIPPortDefinition;
    $IPPortDefList[$i].address = $MemberList[$i];
    $IPPortDefList[$i].port = $MemberPort;
  }
    
  Write-Host "Creating Pool $Name";
  $(Get-F5.iControl).LocalLBPool.create(
    (,$Name),
    (,"LB_METHOD_ROUND_ROBIN"),
    (,$IPPortDefList)
  );
  Write-Host "Pool '$Name' Successfully Created";
}

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
if ( ($Bigip.Length -eq 0) -or ($User.Length -eq 0) -or ($Pass.Length -eq 0) -or`
     ($Pool.Length -eq 0) -or ($Partition.Length -eq 0) )
{
  Show-Usage;
}
else
{
  if ( Do-Initialize )
  {
		$PoolName = "/${Partition}/${Pool}";
    
    # HTTP Objects
		$MemberList = (, "10.10.10.10");
		$MemberPort = 80;
    Create-Pool -Name $PoolName -MemberList $MemberList -MemberPort $HTTPPort;
    Write-Host "Pool $Pool created in paritition $Partition"
  }
  else
  {
    Write-Error "ERROR: iControl subsystem not initialized"
  }
}
