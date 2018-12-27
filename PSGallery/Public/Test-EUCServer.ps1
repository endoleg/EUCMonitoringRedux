function Test-EUCServer {
    [CmdletBinding()]
    param (
        # Specifies the name of the series to run against. 
        [Parameter(ValueFromPipeline, Mandatory = $true)]
        [string]$Series,

        # The names of the servers to run against. 
        [Parameter(ValueFromPipeline, Mandatory = $true)]
        [string[]]$ComputerName,
        
        # The ports you want to test against the Servers.
        [Parameter(ValueFromPipeline, Mandatory = $false)]
        [int[]]$Ports,

        # The services you want to make sure are running on the Servers
        [Parameter(ValueFromPipeline, Mandatory = $false)]
        [string[]]$Services,


        [string[]]$HTTPPath,
        [int]$HTTPPort = 80,
        [string[]]$HTTPSPath,
        [int]$HTTPSPort = 443,
        [int[]]$ValidCertPort,
      
        
        # Specifies the level of detail being returned.  Basic by default. 
        [switch]$Advanced,

        [Parameter(ValueFromPipeline, Mandatory = $false)]
        [pscredential]$Credential
    )
    
    Begin {
        Write-Verbose "[$(Get-Date) BEGIN  ] [$($myinvocation.mycommand)]"

    }
    
    Process {
        Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Series: $Series"
        $Results = @()
        #       $Errors = @()


        foreach ($Computer in $ComputerName) {
            $Result = [PSCustomObject]@{
                Series = $Series
                Status = "UP"
                State  = 2
                Host   = $Computer
            }

            try { 
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Testing connection to $Computer"
                $Connected = (Test-NetConnection -ComputerName $Computer -ErrorAction Stop)
                if (-Not ($Connected.PingSucceeded)) {
                    if ($null -eq $Connected.RemoteAddress) {
                        throw "Name resolution of $($Connected.ComputerName) failed"
                    }
                    $Result.Status = "DOWN"
                    $Result.State = 0
                    foreach ($Port in $Ports) {
                        $Result | Add-Member -MemberType NoteProperty -Name "Port$Port" -Value 0 # 
                    }
                    foreach ($Service in $Services) {
                        $Result | Add-Member -MemberType NoteProperty -Name "$Service" -Value 0 # 
                    }
                    foreach ($Path in $HTTPPath) {
                        $Result | Add-Member -MemberType NoteProperty -Name "HTTPPath_$($HTTPPort)$($HTTPPath -replace '\W', '_')" -Value 0 #
                    }
                    foreach ($Path in $HTTPSPath) {
                        $Result | Add-Member -MemberType NoteProperty -Name "HTTPSPATH_$($HTTPSPort)$($HTTPSPath -replace '\W', '_')" -Value 0 # 
                    }
                    foreach ($Port in $ValidCertPort) {
                        $Result | Add-Member -MemberType NoteProperty -Name "ValidCert_Port$($Port)" -Value 0 # 
                    }
                }
                
                else {
                    # Ports
                    foreach ($Port in $Ports) {
                        Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Testing $Computer Port $Port"
                        if (Test-NetConnection $Computer -Port $Port -InformationLevel Quiet) {
                            $Result | Add-Member -MemberType NoteProperty -Name "Port$($Port)" -Value 1 
                            Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Success"
                        }
                        else {
                            Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Failure"
                            $Result | Add-Member -MemberType NoteProperty -Name "Port$($Port)" -Value 0 
                            $Result.Status = "DEGRADED"
                            $Result.State = 1
                            $Errors += "Port $Port closed"
                        }
                    }

                    # Windows Services
                    foreach ($Service in $Services) {
                        Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Testing $Computer Service $Service"

                        $SvcStatus = (Get-Service -ErrorAction SilentlyContinue -ComputerName $Computer -Name $Service).Status
                        Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $SvcStatus"
                        if ("Running" -eq $SvcStatus) {
                            Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Success"
                            $Result | Add-Member -MemberType NoteProperty -Name "$Service" -Value 1 
                        }
                        else {
                            Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Failure"
                            $Result | Add-Member -MemberType NoteProperty -Name "$Service" -Value 0 
                            $Result.Status = "DEGRADED"
                            $Result.State = 1
                            $Errors += "$Service not running"
                        }
                    }

                    # URL Checking
                    foreach ($Path in $HTTPPath) {      
                        $Url = "http://$($Computer):$($HTTPPort)$($HTTPPath)"
                        Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] HTTP Test $url"
                    
                        if (Test-Url $Url) {
                            $Result | Add-Member -MemberType NoteProperty -Name "HTTPPath_$($HTTPPort)$($HTTPPath -replace '\W', '_')" -Value 1 
                        }
                        else {
                            $Result.Status = "DEGRADED"
                            $Result.State = 1
                            $Result | Add-Member -MemberType NoteProperty -Name "HTTPPath_$($HTTPPort)$($HTTPPath -replace '\W', '_')" -Value 0 
                        }
                    }

                    foreach ($Path in $HTTPSPath) {      
                        $Url = "https://$($Computer):$($HTTPSPort)$($Path)"
                        Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] HTTPS Test $Url"
                    
                        if (Test-Url $Url) {
                            $Result | Add-Member -MemberType NoteProperty -Name "HTTPSPath_$($HTTPSPort)$($HTTPSPath -replace '\W', '_')" -Value 1 
                        }
                        else {
                            $Result.Status = "DEGRADED"
                            $Result.State = 1
                            $Result | Add-Member -MemberType NoteProperty -Name "HTTPSPath_$($HTTPSPort)$($HTTPSPath -replace '\W', '_')" -Value 0 
                        }
                    }


                    foreach ($Port in $ValidCertPort) {
                        Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Valid Cert Port $Url"
                        if (Test-ValidCert -ComputerName $Computer -Port $Port) {
                            $Result | Add-Member -MemberType NoteProperty -Name "ValidCert_Port$($Port)" -Value 1 
                        }
                        else {
                            $Result.Status = "DEGRADED"
                            $Result.State = 1
                            $Result | Add-Member -MemberType NoteProperty -Name "ValidCert_Port$($Port)" -Value 0 
                        }
                    }  
                    
                }        

                $Results += $Result      
            }
            catch {
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] Problem occured testing $Series - $Computer"
                Write-Verbose "[$(Get-Date) PROCESS] [$($myinvocation.mycommand)] $_"
                
                $ErrorState = -1
                $ErrorResult = [PSCustomObject]@{
                    Series = $Series
                    Status = "Error"
                    State  = $ErrorState
                    Host   = $Computer
                }
             
                foreach ($Port in $Ports) {
                    $ErrorResult | Add-Member -MemberType NoteProperty -Name "Port$Port" -Value $ErrorState
                }
                foreach ($Service in $Services) {
                    $ErrorResult | Add-Member -MemberType NoteProperty -Name "$Service" -Value $ErrorState
                }
                foreach ($Path in $HTTPPath) {
                    $ErrorResult | Add-Member -MemberType NoteProperty -Name "HTTPPath_$($HTTPPort)$($HTTPPath -replace '\W', '_')" -Value $ErrorState
                }
                foreach ($Path in $HTTPSPath) {
                    $ErrorResult | Add-Member -MemberType NoteProperty -Name "HTTPSPath_$($HTTPSPort)$($HTTPSPath -replace '\W', '_')" -Value $ErrorState
                }
                foreach ($Port in $ValidCertPort) {
                    $ErrorResult | Add-Member -MemberType NoteProperty -Name "ValidCert_Port$($Port)" -Value $ErrorState
                }
                $Results += $ErrorResult
            }
            
        }


        if ($Results.Count -gt 0) {
            return , $Results
        }
    }
    
    End {
        Write-Verbose "[$(Get-Date) END    ] [$($myinvocation.mycommand)]"
    }
}

