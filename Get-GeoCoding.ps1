<#
.SYNOPSIS
    Returns geographic coordinates (Latitide and Longitude) for an Address.
.DESCRIPTION
    This cmdlet utilizes Google Maps GeoCoding API, to convert addresses (like "1600 Amphitheatre Parkway, Mountain View, CA") into geographic coordinates (like latitude 37.423021 and longitude -122.083739)

    You need to register and get an API key from the below link. Once you've the key setup an Environment variable like $env:GoogleGeocode_API_Key = "YOUR API KEY" before hand to make this function work. You can save this $Env variable in your profile, so that it automatically loads when you open powershell console.

    API Key Link - https://developers.google.com/maps/documentation/geocoding/get-api-key
.PARAMETER Address
    The street address that you want to geocode, in the format used by the national postal service of the country concerned. Additional address elements such as business names and unit, suite or floor numbers should be avoided.
.EXAMPLE
    PS D:\> Get-GeoCoding -Address "eiffel tower"
    
    
    InputAddress      : eiffel tower
    IdentifiedAddress : Eiffel Tower, Champ de Mars, 5 Avenue Anatole France, 75007 Paris, France
    Country           : France
    State             : Île-de-France
    PostalCode        : 75007
    Latitude          : 48.8583701
    Longitude         : 2.2944813
    Coordinates       : 48.8583701,2.2944813                                                      

    In above example, Function Converts the adress of Eiffel tower into geographical cordinates (Latitude and Longitude) and also identifies Country, State, postal code and exact address.

.EXAMPLE
    PS D:\> (Get-GeoCoding "Eiffel tower").Coordinates | Get-TimeZone

    TimeZone                     TimeZoneID   LocalTime           
    --------                     ----------   ---------           
    Central European Summer Time Europe/Paris 5/13/2016 9:51:22 PM

    Latitude and Logitude obtained from this function can be passed to other cmdlets like one in the above example to get TimeZone \ Local time on the geographical coordinate.

.EXAMPLE
    PS D:\> "white house","Microsoft redmund" | Get-GeoCoding

    InputAddress      : white house
    IdentifiedAddress : The White House, 1600 Pennsylvania Ave NW, Washington, DC 20500, USA
    Country           : United States
    State             : District of Columbia
    PostalCode        : 20500
    Latitude          : 38.8976763
    Longitude         : -77.0365298
    Coordinates       : 38.8976763,-77.0365298
    
    InputAddress      : Microsoft redmund
    IdentifiedAddress : Microsoft Way, Redmond, WA 98052, USA
    Country           : United States
    State             : Washington
    PostalCode        : 98052
    Latitude          : 47.6419587
    Longitude         : -122.1305878
    Coordinates       : 47.6419587,-122.1305878

    You can also pass multiple Addressed through pipeline to the cmdlet, to get the corresponding Latitudes and longitudes.

.NOTES
    Author: Prateek Singh - @SinghPrateik
       
#>  
Function Get-GeoCoding
{
    Param(
            [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)] [String] $Address
    )

    Begin
    {
        If(!$env:GoogleGeocode_API_Key)
        {
            Throw "You need to register and get an API key and save it as environment variable `$env:GoogleGeocode_API_Key = `"YOUR API KEY`" `nFollow this link and get the API Key - http://developers.google.com/maps/documentation/geocoding/get-api-key `n`n "
        }
    }

    Process
    {

        Foreach($Item in $Address)
        {
            Try
            {
                $FormattedAddress = $Item.replace(" ","+")

                $webpage = Invoke-WebRequest "https://maps.googleapis.com/maps/api/geocode/json?address=$FormattedAddress&key=$env:GoogleGeocode_API_Key" -UseBasicParsing -ErrorVariable EV
                $Results = $webpage.Content | ConvertFrom-Json | select Results -ExpandProperty Results
                $Status = $webpage.Content | ConvertFrom-Json | select Status -ExpandProperty Status
                
                If($Status -eq "OK")
                {

                    ForEach($R in $Results)
                    {
                        $AddressComponents = $R.address_components

                        $R | Select @{n='InputAddress';e={$Item}},`
                                          @{n='Address';e={$_.Formatted_address}},`
                                          @{n='Country';e={($AddressComponents | ?{$_.types -like "*Country*"}).Long_name}},`
                                          @{n='State';e={($AddressComponents | ?{$_.types -like "*administrative_area_level_1*"}).Long_name}},`
                                          @{n='PostalCode';e={($AddressComponents | ?{$_.types -like "*postal_code*"}).Long_name}},`
                                          @{n='Latitude';e={"{0:N7}" -f $_.Geometry.Location.Lat}},`
                                          @{n='Longitude';e={"{0:N7}" -f $_.Geometry.Location.Lng}},`
                                          @{n='Coordinates';e={"$("{0:N7}" -f $_.Geometry.Location.Lat),$("{0:N7}" -f $_.Geometry.Location.Lng)"}}
                    }
                }
                Elseif($Status -eq 'ZERO_RESULTS')
                {
                    "Zero Results Found :  Try changing the parameters"                
                }    
            }
            Catch
            {
                "Something went wrong, please try running again."
                $ev.message
            }
        }
    }     
}
