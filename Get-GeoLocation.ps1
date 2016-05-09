Function Get-LatitudeAndLongitude ($Address)
{
    $APIKey = "AIzaSyC5AUGpKns1WlfLULvk8E0ukAslcUJhxfk"
    
    #$FormattedAddress = "U block, DLF phase 3, gurgaon".replace(" ","+")
    $FormattedAddress = $Address.replace(" ","+")

    $webpage = Invoke-WebRequest "https://maps.googleapis.com/maps/api/geocode/xml?address=$FormattedAddress&key=$APIKey" -UseBasicParsing -ErrorVariable +err
    
    # Capturing the content from the Webpage as XML
    $content = $webpage.Content
    $xml = New-Object XML
    $xml.loadXML($webpage.Content)

    $Latitude = (Select-Xml -Xml $xml -xpath '//GeocodeResponse/result/geometry/location/lat').node.InnerText
    $Longitude = (Select-Xml -Xml $xml -xpath '//GeocodeResponse/result/geometry/location/lng').node.InnerText
    $AddressComponents =  Select-Xml -Xml $xml -xpath '//GeocodeResponse/result/address_component'| %{$_.Node}
    $Country = ($AddressComponents | ?{$_.type -like "*Country*"}).Long_name
    $State =  ($AddressComponents | ?{$_.type -like "*administrative_area_level_1*"}).Long_name


    # Condition to Check 'Zero Results'
    If((Select-Xml -Xml $xml -xpath '//GeocodeResponse/status').Node.InnerText -eq 'ZERO_RESULTS')
    {
        Write-Host "Zero Results Found :  Try changing the parameters" -fore Yellow
    }
    Else
    {
        Return [psobject] [ordered] @{ 
                                        InputAddress = $Address
                                        Country = $Country
                                        State = $State
                                        Latitude= $Latitude
                                        Longitude= $Longitude
                                     }
    }

}

Get-LatitudeAndLongitude "U block, DLF phase 3, gurgaon"