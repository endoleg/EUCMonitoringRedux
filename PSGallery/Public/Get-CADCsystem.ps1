function Get-CADCsystem {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("NSIP")]
        [string]$ADC,

        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]$Credential,

        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [Alias("LogPath")]
        [string]$ErrorLogPath
    )

    Begin {
        # Write-Verbose "[$(Get-Date) BEGIN  ] [$($myinvocation.mycommand)] Starting session to $ADC"
        try {
            $ADCSession = Connect-CitrixADC -ADC $ADC -Credential $Credential
            Write-Verbose "[$(Get-Date) BEGIN  ] [$($myinvocation.mycommand)] Connection to $ADC established"
        }
        catch {
            Write-Verbose "[$(Get-Date) BEGIN  ] [$($myinvocation.mycommand)] Connection to $ADC failed"
            throw $_
        }
    }

    Process {
        try {
            $Results = Get-CADCNitroValue -ADCSession $ADCSession -Stat "system"

            foreach ($System in $Results) {
                # Requests
                $NumCpus = $System.numcpus
                $MgmtCpuUsagePcnt = $System.Mgmtcpuusagepcnt
                $CpuUsagePcnt = $System.cpuusagepcnt
                $MemUsagePcnt = $System.memusagepcnt
                $PktCpuUsagePcnt = $System.pktcpuusagepcnt
                $ResCpuUsagePcnt = $System.rescpuusagepcnt

                $Errors = @()
                if ($CpuUsagePcnt -gt 90) {
                    $Errors += "HighCPU"
                }
                if ($MemUsagePct -gt 90) {
                    $Errors += "HighMEM"
                }
                if ($Errors -ne "$ADC -") {
                    if ($ErrorLogPath) {
                        Write-EUCError -Message "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $ADC - $($Errors -join ' ')" -Path $ErrorLogPath
                    }
                    else {
                        Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $ADC - $($Errors -join ' ')"
                    }
                }

                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $ADC - NumCpus: $NumCpus Cpu: $CpuUsagePcnt Mgmt: $MgmtCpuUsagePcnt "
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $ADC - Pkt: $PktCpuUsagePcnt Mem: $MemUsagePcnt Res: $ResCpuUsagePcnt"

                [PSCustomObject]@{
                    #    Series                   = "CADCsystem"
                    PSTypeName       = 'EUCMonitoring.CADCsystem'
                    ADC              = $ADC
                    MgmtCpuUsagePcnt = $MgmtCpuUsagePcnt
                    CpuUsagePcnt     = $CpuUsagePcnt
                    MemUsagePcnt     = $MemUsagePcnt
                    PktCpuUsagePcnt  = $PktCpuUsagePcnt
                    ResCpuUsagePcnt  = $ResCpuUsagePcnt
                    NumCpus          = $NumCpus
                }
            }
        }
        catch {
            if ($ErrorLogPath) {
                Write-EUCError -Message "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] [$($_.Exception.GetType().FullName)] $($_.Exception.Message)" -Path $ErrorLogPath
            }
            else {
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] [$($_.Exception.GetType().FullName)] $($_.Exception.Message)"
            }
            throw $_
        }
    }

    End {
        Write-Verbose "[$(Get-Date) END    ] [$($myinvocation.mycommand)] Returned $($Results.Count) value(s)"
        Disconnect-CitrixADC -ADCSession $ADCSession
        Write-Verbose "[$(Get-Date) END    ] [$($myinvocation.mycommand)] Disconnected"
    }
}
