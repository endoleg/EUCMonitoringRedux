function Get-CADCtcp {
    <#
    .SYNOPSIS
    Gets basic stats on Citrix ADC gateway tcp from NITRO

    .DESCRIPTION
    Gets basic stats on Citrix ADC gateway tcp from NITRO by polling
    $ADC/nitro/v1/stats/protocoltcp and returning useful values.

    .PARAMETER ADC
    Alias: NSIP
    IP or DNS name of Citrix ADC Gateway

    .PARAMETER Credential
    ADC Credentials

    .PARAMETER ErrorLog
    Alias: LogPath
    Path to a file where any errors can be appended to

    .EXAMPLE
    Get-CADCtcp -ADC 10.1.2.3 -Credential (Get-Credential) -ErrorLog "C:\Monitoring\ADC-Errors.txt"

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
            $Results = Get-CADCNitroValue -ADCSession $ADCSession -Stat "protocoltcp"

            foreach ($tcp in $Results) {
                # Rx
                $TotalRxPackets = [int64]$tcp.tcptotrxpkts
                $RxPacketsRate = [int64]$tcp.tcprxpktsrate
                $TotalRxBytes = [int64]$tcp.tcptotrxbytes
                $RxBytesRate = [int64]$tcp.tcprxbytesrate

                # Tx
                $TotalTxPackets = [int64]$tcp.tcptottxpkts
                $TxPacketsRate = [int64]$tcp.tcptxpktsrate
                $TotalTxBytes = [int64]$tcp.tcptottxbytes
                $TxBytesRate = [int64]$tcp.tcptxbytesrate

                $ActiveServerConnections = [int64]$tcp.activeserverconn
                $CurClientConnEstablished = [int64]$tcp.tcpcurclientconnestablished
                $CurServerConnEstablished = [int64]$tcp.tcpcurserverconnestablished
                $CurrentClientConnections = [int64]$tcp.tcpcurclientconn
                $CurrentServerConnections = [int64]$tcp.tcpcurserverconn

                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalRxPackets: $TotalRxPackets, RxPacketsRate: $RxPacketsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalRxBytes: $TotalRxBytes, RxBytesRate: $RxBytesRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalTxPackets: $TotalTxPackets, TxPacketsRate: $TxPacketsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalTxBytes: $TotalTxBytes, TxBytesRate: $TxBytesRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] ActiveServerConnections: $ActiveServerConnections"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] CurClientConnEstablished: $CurClientConnEstablished, CurServerConnEstablished: $CurServerConnEstablished"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] CurClientConnections: $CurrentClientConnections, CurServerConnections: $CurrentServerConnections"

                [PSCustomObject]@{
                    Series                   = "CADCtcp"
                    PSTypeName               = 'EUCMonitoring.CADCtcp'
                    ADC                      = $ADC
                    TotalRxPackets           = $TotalRxPackets
                    RxPacketsRate            = $RxPacketsRate
                    TotalRxBytes             = $TotalRxBytes
                    RxBytesRate              = $RxBytesRate
                    TotalTxPackets           = $TotalTxPackets
                    TxPacketsRate            = $TxPacketsRate
                    TotalTxBytes             = $TotalTxBytes
                    TxBytesRate              = $TxBytesRate
                    ActiveServerConnections  = $ActiveServerConnections
                    CurClientConnEstablished = $CurClientConnEstablished
                    CurServerConnEstablished = $CurServerConnEstablished
                    CurClientConnections     = $CurrentClientConnections
                    CurServerConnections     = $CurrentServerConnections
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

