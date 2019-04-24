function Get-RDSLicense {
    <#
    .SYNOPSIS
    Returns RDS Licensing info

    .DESCRIPTION
    Returns

    .PARAMETER ComputerName
    Gets the TSLicenseKeyPack on the specified computers.

    Type the NetBIOS name, an IP Address, or a fully qualified domain name (FQDN) of a remote computer.

    .PARAMETER LicenseType
    The 'TypeAndModel' of the license pack.  If specified, will return only the licenses of that TypeAndModel.
    If unspecified, includes all but "Built-in TS Per Device Cal"

    .PARAMETER IgnoreBuiltIn


    .OUTPUTS
    System.Management.Automation.PSCustomObject

    .EXAMPLE
    Get-RDSLicenseStat -ComputerName "rdslic1", "rdslic2"

    .EXAMPLE
    Get-RDSLicenseStat -ComputerName "rdslic1.domain.org" -LicenseType "RDS Per User CAL"

    #>

    [cmdletbinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(ValueFromPipeline, Mandatory = $false)]
        [string[]]$LicenseType = "",

        [Parameter(ValueFromPipeline)]
        [switch]$IgnoreBuiltIn,

        [Parameter(ValueFromPipeline)]
        [switch]$ErrorObj,

        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [Alias("LogPath")]
        [string]$ErrorLogPath
    )

    Begin {
        Write-Verbose "[$(Get-Date) BEGIN  ] [$($myinvocation.mycommand)] Setting ErrorActionPreference"
        $PrevError = $ErrorActionPreference
        $ErrorActionPreference = "STOP"
    } #BEGIN

    Process {
        $Results = @()

        foreach ($Computer in $ComputerName) {
            try {
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Getting all available RDS licenses from $Computer"

                [regex]$rx = "\d\.\d$"
                $data = test-wsman $Computer -ErrorAction STOP
                if ($rx.match($data.ProductVersion).value -eq '3.0') {
                    $NeedCimOpts = $true
                    $opt = New-CimSessionOption -Protocol Dcom
                    $Session = New-CimSession -ComputerName $Computer -SessionOption $opt
                }

                if (($null -eq $LicenseType) -or ("" -eq $LicenseType)) {
                    Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Querying available licenses"
                    if ($NeedCimOpts) {
                        $LicenseType = $Session | Get-CimInstance -ClassName Win32_TSLicenseKeyPack -ErrorAction STOP | `
                            Where-Object TypeAndModel -NotLike "Built-in TS Per Device Cal" | `
                            Select-Object -ExpandProperty TypeAndModel -Unique -ErrorAction Stop
                    }
                    else {
                        $LicenseType = Get-CimInstance -ClassName  Win32_TSLicenseKeyPack -ComputerName $Computer -ErrorAction Stop | `
                            Where-Object TypeAndModel -NotLike "Built-in TS Per Device Cal" | `
                            Select-Object -ExpandProperty TypeAndModel -Unique -ErrorAction Stop
                    }
                }

                foreach ($Type in $LicenseType) {
                    $TotalAvailable = 0
                    $TotalIssued = 0
                    $TotalLicenses = 0

                    Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Getting license type $Type"
                    if ($NeedCimOpts) {
                        $LicResults = $Session | Get-CimInstance -ClassName Win32_TSLicenseKeyPack -ErrorAction Stop | `
                            Where-Object TypeAndModel -eq $Type | `
                            Select-Object TypeAndModel, IssuedLicenses, AvailableLicenses, TotalLicenses -ErrorAction Stop
                    }
                    else {
                        $LicResults = Get-CimInstance -ClassName Win32_TSLicenseKeyPack -ComputerName $Computer -ErrorAction Stop | `
                            Where-Object TypeAndModel -eq $Type | `
                            Select-Object TypeAndModel, IssuedLicenses, AvailableLicenses, TotalLicenses -ErrorAction Stop
                    }
                    foreach ($License in $LicResults) {
                        $TotalIssued += $License.IssuedLicenses
                        $TotalAvailable += $License.AvailableLicenses
                        $TotalLicenses += $License.TotalLicenses
                    }

                    if ($TotalIssued -gt $TotalLicenses) {
                        if ($ErrorLogPath) {
                            Write-EUCError -Message "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] License Overcommit of Type: $Type" -Path $ErrorLogPath
                        }
                        else {
                            Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] License Overcommit of Type: $Type"
                        }
                    }

                    Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $Type, Available: $TotalAvailable, Issued: $TotalIssued, Total: $TotalLicenses"

                    $Results += [PSCustomObject]@{
                        PSTypeName        = 'EUCMonitoring.RDSLicense'
                        #    Series            = "RdsLicense"
                        Server            = $Computer
                        Type              = $Type
                        AvailableLicenses = $TotalAvailable
                        IssuedLicenses    = $TotalIssued
                        TotalLicenses     = $TotalLicenses
                    }
                }
            }
            catch {
                $ErrorActionPreference = $PrevError
                if ($ErrorLogPath) {
                    Write-EUCError -Message "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] [$($_.Exception.GetType().FullName)] $($_.Exception.Message)" -Path $ErrorLogPath
                }
                else {
                    Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] [$($_.Exception.GetType().FullName)] $($_.Exception.Message)"
                }
                throw $_
            }
        }

        if ($Results.Count -gt 0) {
            return $Results
        }
    } #PROCESS

    End {
        Write-Verbose "[$(Get-Date) END    ] [$($myinvocation.mycommand)] Returned $($Results.Count) value(s)"
    }
}
