Function Get-Distance()
{

    Param(
            [Parameter(Mandatory=$true,Position=0)] $Origin,
            [Parameter(Mandatory=$true,Position=1)] $Destination,
            [Parameter(Mandatory=$true,Position=2)] [ValidateSet('driving','bicycling','walking')] $Mode,
            [Switch] $InMiles
    )
    
    $Units='metric' # Default set to Kilometers

    If($InMiles)
    {
        $Units = 'imperial'  # If Switch is selected, use 'Miles' as the Unit
    }

    
    #Invoking the web URL and fetching the page content
    $webpage = Invoke-WebRequest "https://maps.googleapis.com/maps/api/distancematrix/xml?origins=$origin&destinations=$destination&mode=$($mode.toLower())&units=$Units" -UseBasicParsing -ErrorVariable +err
    
    # Capturing the content from the Webpage as XML
    $content = $webpage.Content
    $xml = New-Object XML
    $xml.loadXML($webpage.Content)
    
    $Origin_Addr = (Select-Xml -Xml $xml -xpath '//origin_address').node.InnerText
    $Destination_Addr = (Select-Xml -Xml $xml -xpath '//destination_address').node.InnerText
    $Duration = (Select-Xml -Xml $xml -xpath '//row/element/duration/text').Node.InnerText
    $Distance = (Select-Xml -Xml $xml -xpath '//row/element/distance/text').Node.InnerText
        
    # Condition to Check 'Zero Results'
    If((Select-Xml -Xml $xml -xpath '//row/element/status').Node.InnerText -eq 'ZERO_RESULTS')
    {
        Write-Host "Zero Results Found :  Try changing the parameters" -fore Yellow
    }
    Else
    {
        Return [psobject] [ordered] @{ Origin=$Origin_Addr
                                                Destination=$Destination_Addr
                                                Time= $Duration
                                                Distance= $Distance
                                                Mode = $Mode
                                              }
    }

}