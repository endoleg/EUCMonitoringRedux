function Get-CADCip {
    <#
    .SYNOPSIS
    Gets basic stats on Citrix ADC gateway ip from NITRO

    .DESCRIPTION
    Gets basic stats on Citrix ADC gateway ip from NITRO by polling
    $ADC/nitro/v1/stats/protocolip and returning useful values.

    .PARAMETER ADC
    Alias: NSIP
    IP or DNS name of Citrix ADC Gateway

    .PARAMETER Credential
    ADC Credentials

    .PARAMETER ErrorLog
    Alias: LogPath
    Path to a file where any errors can be appended to

    .EXAMPLE
    Get-CADCip -ADC 10.1.2.3 -Credential (Get-Credential) -ErrorLog "C:\Monitoring\ADC-Errors.txt"

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
            $Results = Get-CADCNitroValue -ADCSession $ADCSession -Stat "protocolip"

            foreach ($ip in $Results) {
                # Rx
                $TotalRxPackets = [int64]$ip.iptotrxpkts
                $RxPacketsRate = [int64]$ip.iprxpktsrate
                $TotalRxBytes = [int64]$ip.iptotrxbytes
                $RxBytesRate = [int64]$ip.iprxbytesrate
                $TotalRxMbits = [int64]$ip.iptotrxmbits
                $RxMbitsRate = [int64]$ip.iprxmbitsrate

                # Tx
                $TotalTxPackets = [int64]$ip.iptottxpkts
                $TxPacketsRate = [int64]$ip.iptxpktsrate
                $TotalTxBytes = [int64]$ip.iptottxbytes
                $TxBytesRate = [int64]$ip.iptxbytesrate
                $TotalTxMbits = [int64]$ip.iptottxmbits
                $TxMbitsRate = [int64]$ip.iptxmbitsrate

                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalRxPackets: $TotalRxPackets, RxPacketsRate: $RxPacketsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalRxBytes: $TotalRxBytes, RxBytesRate: $RxBytesRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalRxMbits: $TotalRxMbits, RxMbitsRate: $RxMbitsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalTxPackets: $TotalTxPackets, TxPacketsRate: $TxPacketsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalTxBytes: $TotalTxBytes, TxBytesRate: $TxBytesRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalTxMits: $TotalTxMbits, TxMbitsRate: $TxMbitsRate"

                [PSCustomObject]@{
                    Series         = "CADCip"
                    PSTypeName     = 'EUCMonitoring.CADCip'
                    ADC            = $ADC
                    TotalRxPackets = $TotalRxPackets
                    RxPacketsRate  = $RxPacketsRate
                    TotalRxBytes   = $TotalRxBytes
                    RxBytesRate    = $RxBytesRate
                    TotalRxMbits   = $TotalRxMbits
                    RxMbitsRate    = $RxMbitsRate
                    TotalTxPackets = $TotalTxPackets
                    TxPacketsRate  = $TxPacketsRate
                    TotalTxBytes   = $TotalTxBytes
                    TxBytesRate    = $TxBytesRate
                    TotalTxMits    = $TotalTxMbits
                    TxMbitsRate    = $TxMbitsRate
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

