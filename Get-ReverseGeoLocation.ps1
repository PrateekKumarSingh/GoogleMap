Function Get-ReverseGeoLocation
{
    Param(
            [Parameter(Mandatory=$true, Position=0)] $LatLng
    )

    If(!$env:GeoLoc_API_Key)
    {
        Throw "You need to register and get an API key and save it as environment variable `$env:GeoLoc_API_Key = `"XXXXXXXXXXXXXXXXX`" `nFollow this link and get the API Key - http://developers.google.com/maps/documentation/geocoding/get-api-key `n`n "
    }


    #$Latitude="26.7799710"
    #$Longitude = "82.1863182"


    $webpage = Invoke-WebRequest "https://maps.googleapis.com/maps/api/geocode/xml?latlng=$($LatLng.tostring())&key=$env:GeoLoc_API_Key" -UseBasicParsing -ErrorVariable +err
    
    # Capturing the content from the Webpage as XML
    $content = $webpage.Content
    $xml = New-Object XML
    $xml.loadXML($webpage.Content)

    $MostSpecificAddress = (Select-Xml -Xml $xml -xpath '//GeocodeResponse/result/formatted_address').node.InnerText[0]

    # Condition to Check 'Zero Results'
    If((Select-Xml -Xml $xml -xpath '//GeocodeResponse/status').Node.InnerText -eq 'ZERO_RESULTS')
    {
        Write-Host "Zero Results Found :  Try changing the parameters" -fore Yellow
    }
    Else
    {
        Return $MostSpecificAddress
    }

}
