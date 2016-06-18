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
  [string]$SysFunction = ""
);

#----------------------------------------------------------------------------
function Get-systemDNS()
#
# Description 
#   This function retrieves the system DNS configuration
#
#----------------------------------------------------------------------------
{
	$uri = "/mgmt/tm/sys/dns";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method GET -Headers $headers -Uri $link -Credential $mycreds

    Write-Host "`nName Servers";
    Write-Host "------------";
    $items = $obj.nameServers;
    for($i=0; $i -lt $items.length; $i++) {
        $name = $items[$i];
        Write-Host "`t$name";
    }

    Write-Host "`nSearch Domains";
    $items = $obj.search;
    for($i=0; $i -lt $items.length; $i++) {
        $name = $items[$i];
        Write-Host "`t$name";
    }
    Write-Host "`n"

}

#----------------------------------------------------------------------------
function Set-systemDNS()
#
# Description 
#   This function sets the system DNS configuration
#
#----------------------------------------------------------------------------
{
    param(
        [array]$Servers,
        [array]$SearchDomains
    );
    $uri = "/mgmt/tm/sys/dns";
    $link = "https://$Bigip$uri";
    $headers = @{};
    $headers.Add("ServerHost", $Bigip);
    $headers.Add("Content-Type", "application/json");

    $obj = @{
        nameServers = $Servers
        search = $SearchDomains
    };
    $body = $obj | ConvertTo-Json
	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method PUT -Uri $link -Headers $headers -Credential $mycreds -Body $body;
    Get-systemDNS;

}

#----------------------------------------------------------------------------
function Get-systemNTP()
#
# Description 
#   This function retrieves the system NTP configuration
#
#----------------------------------------------------------------------------
{
	$uri = "/mgmt/tm/sys/ntp";
	$link = "https://$Bigip$uri";
	$headers = @{};
	$headers.Add("ServerHost", $Bigip);

	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method GET -Headers $headers -Uri $link -Credential $mycreds

    Write-Host "`nNTP Servers";
    Write-Host "------------";
    $items = $obj.servers;
    for($i=0; $i -lt $items.length; $i++) {
        $name = $items[$i];
        Write-Host "`t$name";
    }

    Write-Host "`nTimezone";
    $item = $obj.timezone;
    Write-Host "`t$item`n";

}

#----------------------------------------------------------------------------
function Set-systemNTP()
#
# Description 
#   This function sets the system NTP configuration
#
#----------------------------------------------------------------------------
{
    param(
        [array]$Servers,
        [string]$TimeZone
    );
    $uri = "/mgmt/tm/sys/ntp";
    $link = "https://$Bigip$uri";
    $headers = @{};
    $headers.Add("ServerHost", $Bigip);
    $headers.Add("Content-Type", "application/json");

    $obj = @{
        servers = $Servers
        timezone = $TimeZone
    };
    $body = $obj | ConvertTo-Json
	$secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

	$obj = Invoke-RestMethod -Method PUT -Uri $link -Headers $headers -Credential $mycreds -Body $body;
    Get-systemNTP;

}

#----------------------------------------------------------------------------
function Gen-QKView()
#
# Description 
#   This function generates a qkview on the system
#
#----------------------------------------------------------------------------
{
    $uri = "/mgmt/tm/util/qkview";
    $link = "https://$Bigip$uri";
    $headers = @{};
    $headers.Add("serverHost", $Bigip);
    $headers.Add("Content-Type", "application/json");
    $secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd)

    $obj = @{
        command='run'
    };
    $body = $obj | ConvertTo-Json
    Write-Host ("Running qkview...standby")
    $obj = Invoke-RestMethod -Method POST -Uri $link -Headers $headers -Credential $mycreds -Body $body;
    Write-Host ("qkview is complete and is available in /var/tmp.")
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
       Argument    - Description
       -----------   -----------
       Bigip       - The ip/hostname of your BIG-IP.
       User        - The Managmenet username for your BIG-IP.
       Pass        - The Management password for your BIG-IP.
       SysFunction - The system function to manage [dns|ntp|qkview].
"@;
}

#============================================================================
# Main application logic
#============================================================================
if ( ($Bigip.Length -eq 0) -or ($User.Length -eq 0) -or ($Pass.Length -eq 0) -or ($SysFunction.Length -eq 0) ) {
  Show-Usage;
} elseif ( $SysFunction -eq "dns" ) {
    $answer = Read-Host "

  1) Get current system dns configuration
  2) Set system dns configuration

  Selection"
    if ( $answer -eq 1) {
        Get-SystemDNS;
    } elseif ( $answer -eq 2 ) {
        $nameservers = Read-Host "Enter nameservers (comma-separated)"
        $nameservers = @($nameservers.Split(","));
        $searchdomains = Read-Host "Enter search domains (comma-separated)"
        $searchdomains = @($searchdomains.Split(","));
        Set-SystemDNS -Servers $nameservers -SearchDomains $searchdomains;
    }
} elseif ( $SysFunction -eq "ntp" ) {
    $answer = Read-Host "

  1) Get current system ntp configuration
  2) Set system ntp configuration

  Selection"
    if ( $answer -eq 1) {
        Get-SystemNTP;
    } elseif ( $answer -eq 2 ) {
        $servers = Read-Host "Enter ntp servers (comma-separated)"
        $servers = @($servers.Split(","))
        $timezone = Read-Host "Enter the timezone (ie..America/Los_Angeles)"
        Set-SystemNTP -Servers $servers -TimeZone $timezone;
    }
} elseif ( $SysFunction -eq "qkview") {
    Gen-QKView;
}