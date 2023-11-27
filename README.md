## check_oxidizedbackup

check oxydized backup status age and size this can be used on an linux pooler or on a windows using nrpe

##### Use case Nrpe

Update `nsclient.ini` , go to  `[/settings/external scripts/wrapped scripts]`, add folowing line in their subcategory :

```ini
[/settings/external scripts/wrappings]
ps1 = cmd /c echo scripts\%SCRIPT% %ARGS%; exit($lastexitcode) | powershell.exe -command -

[/settings/external scripts/wrapped scripts]
check_oxidizedbackup = check_oxyidizedbackup.ps1 "OxidizedUrl" -User $ARG1$ -Pass "$ARG2$" -Crit $ARG3$ -Warn $ARG4$ -Name $ARG5$  -Length $ARG6$
```

*Please Restart nrpe to apply modification

### Use case on a linux pooler

install powershell on your pooler


```
NAME
    check_oxidizedbackup.ps1

SYNOPSIS
    Check oxidized backup age and status


SYNTAX
    check_oxidizedbackup.ps1 [-User] <String> [-Pass] <String>
    [[-Name] <String>] [-Url] <String> [[-Warn] <Double>] [[-Crit] <Double>] [[-Length] <Int32>] [-ListNodes]
    [-ListNodesXml] [<CommonParameters>]


DESCRIPTION
    This script use one  web request to get backup age and status and an other web requet ton get file length


RELATED LINKS

REMARKS
    To see the examples, type: "Get-Help
    check_oxidizedbackup.ps1 -Examples"
    For more information, type: "Get-Help
    check_oxidizedbackup.ps1 -Detailed"
    For technical information, type: "Get-Help
    check_oxidizedbackup.ps1 -Full"


 get-help .\check_oxidizedbackup.ps1  -Detailed

NAME
    C:\Users\Julien\Documents\Scripts\check_oxidizedbackup\check_oxidizedbackup.ps1

SYNOPSIS
    Check oxidized backup age and status


SYNTAX
    check_oxidizedbackup.ps1 [-User] <String> [-Pass] <String>
    [[-Name] <String>] [-Url] <String> [[-Warn] <Double>] [[-Crit] <Double>] [[-Length] <Int32>] [-ListNodes]
    [-ListNodesXml] [<CommonParameters>]


DESCRIPTION
    This script use one  web request to get backup age and status and an other web requet ton get file length


PARAMETERS
    -User <String>
        <User> User account for authentication

    -Pass <String>
        <Pass> Password

    -Name <String>
        <Name> Name of the backuped network device

    -Url <String>
        <Url> Url of oxidized web interface

    -Warn <Double>
        <Warn> Warning threshold in days

    -Crit <Double>
        <Crit> critical  threshold in days

    -Length <Int32>
        <Length> minimun length for a backupfile

    -ListNodes [<SwitchParameter>]

    -ListNodesXml [<SwitchParameter>]

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

    -------------------------- EXAMPLE 1 --------------------------

    PS > .\check_oxydizedbackup.ps1 -user USERACCOUNT -Pass Password -Url OxidizedUrl -Name  "NetworkDeviceName"
    -Length 20 -Warn 2 -crit 3
    
```

#### Exemples

sample :

```
#linux powershell
pwsh ./check_oxidizedbackup.ps1 -user USERACCOUNT -Pass Password -Url "OxidizedUrl" -Name  "NetworkDeviceName" -Length 20 -Warn 2 -crit 3
#npe 
/var/lib/shinken/plugins$ ./check_nrpe -H IP_NRPE -t 30 -c check_oxidizedbackup -a USERACCOUNT 'Password' 3 2 "NetworkDeviceName" 20
```

Résultat :

```
OK Backup status : successBackup date is 2021-11-08 08:28:19 Backup Length 110 Row(s)
```


