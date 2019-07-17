

function Get-InfluxURI {
    <#   
.SYNOPSIS   
    Creates a URI for the EUCMonitoring instance from JSON data or passed Object
.DESCRIPTION 
    Creates a URI for the EUCMonitoring instance from JSON data or passed Object
.PARAMETER JSONFile
    Specify path to your config file to run checks against.  This would be your EUCMonitoring.json, or your
    test configs.  Specifying a JSONFile override any ConfigObject passed to it.  This is mainly 
    used in unit testing to validate the test suites before production. 
.PARAMETER ConfigObject
    Specifies the ports to run checks against.  This should already be in the target location.
.PARAMETER Services 
    Specifies the windows services to run checks against
.NOTES
    Current Version:        1.0
    Creation Date:          14/05/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Adam Yarborough         1.0             22/02/2018          Function Creation
    
.EXAMPLE
    Test-Template -JSONFile "C:\Monitoring\EUCMonitoring.json"
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline)]$ConfigObject
    )

    # XXX CHANGEME XXX
    Write-Verbose "Starting Get-InfluxURI."
    # Initialize Empty Results

    <#
    if ( $JSONFile ) {
        $ConfigObject = Get-Content -Raw -Path $JSONFile | ConvertFrom-Json
    }    

#>

    $DB = $ConfigObject.Global.Influx.InfluxDB
    $Server = $ConfigObject.Global.Influx.InfluxServer
    $Protocol = $ConfigObject.Global.Influx.Protocol
    $Port = $ConfigObject.Global.Influx.Port

    "$Protocol`://$Server`:$Port/write?db=$DB"
}