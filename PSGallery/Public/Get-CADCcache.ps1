function Get-CADCcache {
    <#
    .SYNOPSIS
    Gets basic stats on Citrix ADC gateway integrated caching from NITRO

    .DESCRIPTION
    Gets basic stats on Citrix ADC gateway integrated caching from NITRO by polling
    $ADC/nitro/v1/stats/cache and returning useful values.

    .PARAMETER ADC
    Alias: NSIP
    IP or DNS name of Citrix ADC Gateway

    .PARAMETER Credential
    ADC Credentials

    .PARAMETER ErrorLog
    Alias: LogPath
    Path to a file where any errors can be appended to

    .EXAMPLE
    Get-CADCcache -ADC 10.1.2.3 -Credential (Get-Credential) -ErrorLog "C:\Monitoring\ADC-Errors.txt"

    .NOTES

    #>

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
        [string]$ErrorLog
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
            $Results = Get-CADCNitroValue -ADCSession $ADCSession -Stat "cache"

            foreach ($cache in $Results) {
                $RecentHitPcnt = [int64]$cache.cacherecentpercenthit
                $RecentMissPcnt = 100 - $RecentHitPcnt

                $CurrentHits = [int64]$cache.cachecurhits
                $CurrentMiss = [int64]$cache.cachecurmisses

                $HitsPcnt = [int64]$cache.cachepercenthit
                $MissPcnt = 100 - $HitsPcnt

                $HitsRate = [int64]$cache.cachehitsrate
                $RequestsRate = [int64]$cache.cacherequestsrate
                $MissRate = [int64]$cache.cachemissesrate

                $TotalHits = [int64]$cache.cachetothits
                $TotalMisses = [int64]$cache.cachetotmisses

                # Verbose values for testings
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $ADC - cache"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] RecentHitPcnt: $RecentHitPcnt, RecentMissPcnt: $RecentMissPcnt"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] HitsPcnt: $HitsPcnt, MissPcnt: $MissPcnt"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] CurrentHits: $CurrentHits, CurrentMiss: $CurrentMiss"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] HitsRate: $HitsRate, RequestsRate: $RequestsRate, MissRate: $MissRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalHits: $TotalHits, TotalMisses: $TotalMisses"

                [PSCustomObject]@{
                    Series         = "CADCcache"
                    PSTypeName     = 'EUCMonitoring.CADCcache'
                    ADC            = $ADC
                    RecentHitPcnt  = $RecentHitPcnt
                    RecentMissPcnt = $RecentMissPcnt
                    CurrentHits    = $CurrentHits
                    CurrentMiss    = $CurrentMiss
                    HitsPcnt       = $HitsPcnt
                    MissPcnt       = $MissPcnt
                    HitsRate       = $HitsRate
                    RequestRate    = $RequestsRate
                    MissRate       = $MissRate
                    TotalHits      = $TotalHits
                    TotalMisses    = $TotalMisses
                }
            }
        }
        catch {
            if ($ErrorLog) {
               Write-EUCError -Message "[$($myinvocation.mycommand)] [$($_.Exception.GetType().FullName)] $($_.Exception.Message)" -Path $ErrorLog
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

