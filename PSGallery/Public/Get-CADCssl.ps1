function Get-CADCssl {
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
            $Results = Get-CADCNitroValue -ADCSession $ADCSession -Stat "ssl"

            foreach ($ssl in $Results) {
                $TotalSessions = [int64]$ssl.ssltotsessions
                $SessionsRate = $ssl.sslsessionsrate
                $TotalTransactions = [int64]$ssl.ssltottransactions
                $TransactionsRate = $ssl.ssltransactionsrate

                $TotalNewSessions = [int64]$ssl.ssltotnewsessions
                $NewSessionsRate = $ssl.sslnewsessionsrate
                $TotalSessionMiss = [int64]$ssl.ssltotsessionmiss
                $SessionsMissRate = $ssl.sslsessionmissrate
                $TotalSessionHits = [int64]$ssl.ssltotsessionhits
                $SessionsHitsRate = $ssl.sslsessionhitsrate

                $TotalBackendSessions = [int64]$ssl.sslbetotsessions
                $BackendSessionsRate = $ssl.sslbesessionsrate

                if ($ssl.sslenginestatus -eq 1) {
                    $EngineStatus = "UP"
                }
                else {
                    if ($ErrorLogPath) {
                        Write-EUCError -Message "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $ADC SSLEngineStatus DOWN" -Path $ErrorLogPath
                    }
                    else {
                        Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $ADC SSLEngineStatus DOWN"
                    }
                    $EngineStatus = "DOWN"
                }

                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalSessions: $TotalSessions, SessionRate: $SessionsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalTransactions: $TotalTransactions, TransactionRate: $TransactionsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalNewSessions: $TotalNewSessions, NewSessionRate: $NewSessionsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalSessionMiss: $TotalSessionMiss, SessionsMissRate: $SessionsMissRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalSessionHits: $TotalSessionHits, SessionsHitsRate: $SessionsHitsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] TotalBackendSessions: $TotalBackendSessions, BackendSessionsRate: $BackendSessionsRate"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] EngineStatus: $EngineStatus"

                [PSCustomObject]@{
                    #    Series                   = "CADCssl"
                    PSTypeName           = 'EUCMonitoring.CADCssl'
                    ADC                  = $ADC
                    TotalSessions        = $TotalSessions
                    SessionsRate         = $SessionsRate
                    TotalTransactions    = $TotalTransactions
                    TransactionsRate     = $TransactionsRate
                    TotalNewSessions     = $TotalNewSessions
                    NewSessionsRate      = $NewSessionsRate
                    TotalSessionMiss     = $TotalSessionMiss
                    SessionsMissRate     = $SessionsMissRate
                    TotalSessionHits     = $TotalSessionHits
                    SessionsHitsRate     = $SessionsHitsRate
                    TotalBackendSessions = $TotalBackendSessions
                    BackendSessionsRate  = $BackendSessionsRate
                    EngineStatus         = $EngineStatus
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
