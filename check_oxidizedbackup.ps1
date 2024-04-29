#!/usr/bin/pwsh



<#
.SYNOPSIS
    Check oxidized backup age and status
.NOTES
    Version: 1.2.0
    Name: check_oxidized
    Author: DESMAREST Julien (Start81)
    Modified By : -
    Last Modified : 03/01/2023
    Changelog
           1.0.0 08/11/2021 : Initial release.
	   1.1.0 15/12/2022 : Powershell 7.3 version for linux and windows.
	   1.2.0 03/01/2023 : add autodiscover.
.DESCRIPTION
    This script use one  web request to get backup age and status and an other web requet ton get file length
.PARAMETER User
    <User> User account for authentication
.PARAMETER Pass
    <Pass> Password
.PARAMETER Name
    <Name> Name of the backuped network device
.PARAMETER Url
    <Url> Url of oxidized web interface
.PARAMETER Warn
    <Warn> Warning threshold in days
.PARAMETER Crit
    <Crit> critical  threshold in days
.PARAMETER Length
    <Length> minimun length for a backupfile
.PARAMETER ListNodes
.PARAMETER ListNodesXml
.EXAMPLE
    .\check_oxydizedbackup.ps1 -user USERACCOUNT -Pass Password -Url "OxidizedUrl -Name  "NetworkDeviceName" -Length 20 -Warn 2 -crit 3

#>

Param(
    [Parameter(Mandatory = $True)]
    [System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
    [String] $User,
    [Parameter(Mandatory = $True)]
    [System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
    [String] $Pass,
    [Parameter(Mandatory = $False)]
    [System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
    [String] $Name,
    [Parameter(Mandatory = $True)]
    [System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
    [String] $Url,
    [Parameter(Mandatory = $False)]
    [System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
    [Double] $Warn,
    [Parameter(Mandatory = $False)]
    [System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
    [Double] $Crit,
    [Parameter(Mandatory = $False)]
    [System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
    [Int] $Length,
    [Switch]$ListNodes,
	[Switch]$ListNodesXml

)
$ErrorActionPreference = 'Stop'
$NagiosState="OK","WARNING","CRITICAL","UNKNOWN"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try{
    $Pair = "$($user):$($Pass)"
    $Pair = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Pair))
    $Header =  @{
        'Content-Type'='application/json; charset=utf-8'
        'Accept'= 'application/json'
        'Authorization' = "Basic $Pair"
    }
    if ($ListNodes -or $ListNodesXMl) {
        $MyUrl = $Url + "/nodes"
        $response = Invoke-Webrequest -Uri $MyUrl -Header $Header -Method get -UseBasicParsing -SkipCertificateCheck
        If ($response.StatusCode -ne "200") {
            Write-Output "UNKNOWN : HTTP status : $($response.StatusCode)"
            exit 3
        }
		if ($ListNodesXMl) {
		    $MyXMl = '<?xml version="1.0" encoding="utf-8"?><data>'
		}
        $Nodes=$response.content | select-string -Pattern '(?:href=./node\/show\/)([\w\d-]*)(?:.>)' -AllMatches 
        $Nodes.Matches | ForEach-Object{
			if ($ListNodesXMl) {
				$MyXMl = $MyXMl + '<element>' + $_.Groups[1].Value + '</element>'
			} else {
				$_.Groups[1].Value
			}
        }
		if ($ListNodesXMl) {
		    $MyXMl = $MyXMl + "</data>"
			$MyXMl
		}
    } else {
        If (($Crit) -and ($Warn)) { 
            If ($Crit -Lt $Warn) {
                Write-Output "UNKNOWN critical must be greater than warning"
                Exit 3
            }
        } else {
            Write-Output "UNKNOWN No threshold"
            Exit 3
        }
        if (!$Name) {
            Write-Output "UNKNOWN Empty node Name"
            Exit 3
        }
        $MyUrl = $Url + "/node/show/" + $Name
        $response = Invoke-Webrequest -Uri $MyUrl -Header $Header -Method get -UseBasicParsing -SkipCertificateCheck
        If ($response.StatusCode -ne "200") {
            Write-Output "UNKNOWN : HTTP status : $($response.StatusCode)"
            exit 3
        }
        $Temp = $response.content.split("`r`n") | where-object{ $_ -Like "*{*}*" }
        #$temp.innerText
        $BackupResuLt = $($Temp.replace('&#x000A;',"")).split(",")
        #$BackupResuLt
        foreach ($Row in $BackupResuLt){
            If ($Row -Like "*:end=>*"){
                $Date = $($($Row.replace(":end=>",""))).Trim()
            } Else {
                If ($Row -Like "*:full_name=>*"){
                    $FullName =  $($($($Row.replace(":full_name=>","")).replace('"',""))).Trim()
                } Else {
                    If ($Row -Like "*:status=>:*") {
                        $Status = $($($Row.replace(":status=>:",""))).Trim()
                    }
                }
            }
        }

        $DateRef = Get-date
        $DateRefCrit = $DateRef.AddDays(-$Crit)
        $DateRefWarn = $DateRef.AddDays(-$Warn)
        #$DATE
        #$Status
        #$FullName
        $Url = $Url+"/node/fetch/" + $FullName
        #$Url
        $BackupFile = Invoke-Webrequest -Uri $Url -Header $Header -Method get -UseBasicParsing  -SkipCertificateCheck:$IgnoreCertificateCheck
        If ($BackupFile.StatusCode -ne "200") {
            Write-Output "UNKNOWN : HTTP status : $($response.StatusCode)"
            Exit 3
        }
        $BackupFileLength = $($BackupFile.RawContent.split("`n")).count
        #$BackupFile
        #$MyDate = [Datetime]::ParseExact($Date.replace("UTC","Z") ,"yyyy-MM-dd HH:mm:ss Z",[System.Globalization.CuLtureInfo]::InvariantCuLture)
        if ($Date) {
            $MyDate = [Datetime]::Parse($Date.replace("UTC","Z"))
            $Msg = " Backup status : $Status"
            $State = 0
            If ($Status -Eq "success") {
                If ($MyDate -Lt $DateRefCrit) {
                    $Msg = "$Msg Backup too old"
                    $State = 2
                } Else {
                    If ($MyDate -Lt $DateRefWarn) {
                        $Msg = "$Msg Backup too old"
                        $State = 1
                    }
                }
                If ($BackupFileLength -Lt $Length ){
                    $Msg = " Backup Length to low "
                    $State = 2
                }
            } Else {
                $State=2
            }
        } else {
            Write-Output "UNKNOWN : $Name have no backup"
            Exit 3
        }
        $Msg = $NagiosState[$State] + $Msg + " Backup date is " + $Mydate.ToString("yyyy-MM-dd HH:mm:ss") + " Backup Length " + $BackupFileLength + " Row(s)"
        $Msg
        Exit $State
    }
} catch {
    $_.Exception.Message
    Exit 3
}
