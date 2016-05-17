Set-Alias -Name WhereAmI -Value Get-GeoLocation
Set-Alias -Name Direction -Value Get-Direction
Set-Alias -Name Distance -Value Get-Distance
Set-Alias -Name Geocode -Value Get-GeoCoding
Set-Alias -Name rGeocode -Value Get-ReverseGeoCoding
Set-Alias -Name gtz -Value Get-TimeZone

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

<#
.SYNOPSIS
    Returns Address for geographic coordinates (Latitide and Longitude).
.DESCRIPTION
    This cmdlet utilizes Google Map Geocoding API's reverse geocoding service to convert geographic coordinates (Latitude and Longitude) into a human-readable address. 

    You need to register and get an API key from the below link. Once you've the key setup an Environment variable like $env:GoogleGeocode_API_Key = "YOUR API KEY" before hand to make this function work. You can save this $Env variable in your profile, so that it automatically loads when you open powershell console.

    API Key Link - https://developers.google.com/maps/documentation/geocoding/get-api-key
.PARAMETER Coordinates
    The latitude and longitude values specifying the location for which you wish to obtain the closest, human-readable address.
.EXAMPLE
    PS D:\> Get-ReverseGeoCoding "26.7799710,82.1863182"
    
    Coordinates           Address                                                   
    -----------           -------                                                
    26.7799710,82.1863182 Unnamed Road, Ranopali Village, Ayodhya, Uttar Pradesh 224123, India

    In above example, Function Converts the geographical cordinates (Latitude and Longitude) into a human readable address.

.EXAMPLE
    PS D:\> "38.8976763,-77.0365298","47.6419587,-122.1305878" | Get-ReverseGeoCoding

    Coordinates             Address                                                   
    -----------             -------
    38.8976763,-77.0365298  The White House, 1600 Pennsylvania Ave NW, Washington, DC 20500, USA
    47.6419587,-122.1305878 409 Microsoft Way, Redmond, WA 98052, USA                           

    You can also pass multiple latitude and longitude values through pipeline to the cmdlet, to get the corresponding addresses.

.NOTES
    Author: Prateek Singh - @SinghPrateik
       
#>  
Function Get-ReverseGeoCoding
{
    [CmdletBinding()]
    Param(
            [Parameter(Mandatory=$true, Position=0, ValueFromPipeline =$True)] [STring] $Coordinates
    )
    
    Begin
    { 
         If(!$env:GoogleGeocode_API_Key)
         {
             Throw "You need to register and get an API key and save it as environment variable `$env:GoogleGeoCode_API_Key = `"YOUR API KEY`" `nFollow this link and get the API Key - http://developers.google.com/maps/documentation/geocoding/get-api-key `n`n "
         }
    }

    Process
    {

        Foreach($Item in $Coordinates)
        {
            Try
            {
                $webpage = Invoke-WebRequest "https://maps.googleapis.com/maps/api/geocode/json?latlng=$($item.tostring())&key=$env:GoogleGeocode_API_Key" -UseBasicParsing -ErrorVariable EV
                
                # Capturing the content from the Webpage as JSON
                $content = $webpage.Content| ConvertFrom-Json
                $Results = $content.results
                $Status = $content.status

                $MostSpecificAddress = ($Results.Formatted_address)[0]
        
                # Condition to Check 'Zero Results'
                If($status -eq 'OK')
                {
                    ''|select @{n='Coordinates';e={$Item.tostring()}}, @{n='Address';e={$MostSpecificAddress}}
                }
                Elseif($status -eq 'ZERO_RESULTS')
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

<#
.SYNOPSIS
    Calculates and display directions from a source to destination.
.DESCRIPTION
    This cmdlet utilizes Google Maps Directions API as a service to calculate directions between locations using an HTTP request.

    You need to register and get an API key from the below link. Once you've the key setup an Environment variable like $env:GoogleDirection_API_Key = "YOUR API KEY" before hand to make this function work. You can save this $Env variable in your profile, so that it automatically loads when you open powershell console.

    API Key Link - https://developers.google.com/maps/documentation/directions/get-api-key
.PARAMETER From
    The address from which you wish to calculate directions.
.PARAMETER To
    The address to which you wish to calculate directions.
.PARAMETER Mode
    Specifies the mode of transport to use when calculating directions. Valid values are Driving, Bicycling, Walking.
.PARAMETER InMiles
    Use 'InMiles' switch to get the distance in Miles, instead of Kilometers
.EXAMPLE
    PS D:\> Get-Direction -From "U block, Dlf Phase 3" -To "Royal bank of scotland, gurgaon"| ft -AutoSize
    
    Instructions                                                                          Duration Distance Mode       Maneuver       
    ------------                                                                          -------- -------- ----       --------       
    Head northwest                                                                        1 min    58 m     Driving                   
    Turn left toward U-42 Rd                                                              1 min    69 m     Driving    Turn-Left      
    Turn right onto U-42 Rd                                                               1 min    0.1 km   Driving    Turn-Right     
    Turn left toward Gali Number 1                                                        2 mins   0.3 km   Driving    Turn-Left      
    Turn right onto Gali Number 1Pass by DLF Cyber Terraces (on the left)                 1 min    0.3 km   Driving    Turn-Right     
    Turn left after Royal Bank of Scotland (on the right)                                 2 mins   0.9 km   Driving    Turn-Left      
    Continue straight                                                                     1 min    0.2 km   Driving    Straight       
    Turn left toward NH8                                                                  1 min    0.3 km   Driving    Turn-Left      
    Take the ramp on the right onto NH8Pass by IBM India Silokhera (on the left in 4.8km) 6 mins   6.0 km   Driving                   
    Take the exit                                                                         1 min    0.3 km   Driving    Ramp-Left      
    Continue straight                                                                     1 min    73 m     Driving    Straight       
    Turn right at Jharsa Chowk onto Jharsa RdPass by Spencer's (on the left in 750m)      5 mins   1.3 km   Driving    Turn-Right     
    At Mor Chowk, continue straight onto Jail Rd                                          2 mins   0.4 km   Driving    Roundabout-Left
    Turn right onto Jail Rd/Railway Rd                                                    2 mins   0.4 km   Driving    Turn-Right     
    Turn right onto Basai Rd                                                              1 min    33 m     Driving    Turn-Right     
    
    In above example, Function calculates the direction from Origin to Destination and provides informations like- duration, distance, maneuvers and instructions

.EXAMPLE
    PS D:\> Get-Direction -From "U block, Dlf Phase 3" -To "Royal bank of scotland, gurgaon" -InMiles| ft -AutoSize

    Instructions                                                                          Duration Distance Mode       Maneuver       
    ------------                                                                          -------- -------- ----       --------       
    Head northwest                                                                        1 min    190 ft   Driving                   
    Turn left toward U-42 Rd                                                              1 min    226 ft   Driving    Turn-Left      
    Turn right onto U-42 Rd                                                               1 min    469 ft   Driving    Turn-Right     
    Turn left toward Gali Number 1                                                        2 mins   0.2 mi   Driving    Turn-Left      
    Turn right onto Gali Number 1Pass by DLF Cyber Terraces (on the left)                 1 min    0.2 mi   Driving    Turn-Right     
    Turn left after Royal Bank of Scotland (on the right)                                 2 mins   0.6 mi   Driving    Turn-Left      
    Continue straight                                                                     1 min    0.1 mi   Driving    Straight       
    Turn left toward NH8                                                                  1 min    0.2 mi   Driving    Turn-Left      
    Take the ramp on the right onto NH8Pass by IBM India Silokhera (on the left in 3.0mi) 6 mins   3.8 mi   Driving                   
    Take the exit                                                                         1 min    0.2 mi   Driving    Ramp-Left      
    Continue straight                                                                     1 min    240 ft   Driving    Straight       
    Turn right at Jharsa Chowk onto Jharsa RdPass by Spencer's (on the left in 0.5mi)     5 mins   0.8 mi   Driving    Turn-Right     
    At Mor Chowk, continue straight onto Jail Rd                                          2 mins   0.3 mi   Driving    Roundabout-Left
    Turn right onto Jail Rd/Railway Rd                                                    2 mins   0.2 mi   Driving    Turn-Right     
    Turn right onto Basai Rd                                                              1 min    108 ft   Driving    Turn-Right 

    Use 'InMiles' switch to convert Distance into Feets and Miles, instead of Meters and Kilometers.
.EXAMPLE
    PS D:\> Direction -From "U block, Dlf Phase 3" -To "dlf phase 3 metro" -Mode walking | ft -Auto

    Instructions                                                                 Duration Distance Mode       Maneuver  
    ------------                                                                 -------- -------- ----       --------  
    Head northwest                                                               1 min    58 m     Walking              
    Turn left toward U-44 Rd                                                     1 min    0.1 km   Walking    Turn-Left 
    Turn right onto U-44 Rd                                                      2 mins   0.1 km   Walking    Turn-Right
    Turn left toward Gali Number 1                                               3 mins   0.2 km   Walking    Turn-Left 
    Turn right onto Gali Number 1Pass by DLF Cyber Terraces (on the left in 51m) 3 mins   0.3 km   Walking    Turn-Right
    Turn right after Royal Bank of Scotland (on the right)                       1 min    46 m     Walking    Turn-Right
    Turn right toward Phase III Metro Path                                       4 mins   0.3 km   Walking    Turn-Right
    Turn right onto Phase III Metro Path                                         1 min    88 m     Walking    Turn-Right

    You can also change Mode of travel using the 'Mode' parameter, like in above example function returned directions using the 'waliking' mode.
.NOTES
    Author: Prateek Singh - @SinghPrateik
       
#>        
Function Get-Direction
{
    [cmdletbinding()]
    Param(
            [Parameter(Mandatory=$true,Position=0)] [String] $From,
            [Parameter(Mandatory=$true,Position=1)] [String] $To,
            [Parameter(Position=2)] [ValidateSet('driving','bicycling','walking')] [String] $Mode ="driving",
            [Switch] $InMiles
    )
    
    $Units='metric' # Default set to Kilometers
    
    # If Switch is selected, use 'Miles' as the Unit
    If($InMiles){$Units = 'imperial'}

     If(!$env:GoogleDirection_API_Key)
     {
         Throw "You need to register and get an API key from below link and have to setup an Environment variable like `$env:GoogleDirection_API_Key = `"YOUR API KEY`" to make this function work. You can save this `$Env variable in your profile, so that it automatically loads when you open powershell console.`n`nAPI Key Link - https://developers.google.com/maps/documentation/directions/get-api-key`n"
     }
    
    #Requesting Web Page
    Try
    {
        $WebPage = Invoke-WebRequest "https://maps.googleapis.com/maps/api/directions/json?origin=$From&destination=$To&mode=$($mode.toLower())&units=$Units&key=$env:GoogleDirection_API_Key" -UseBasicParsing -ErrorVariable EV
        $Content=$WebPage.Content|ConvertFrom-Json
        
        $status = $Content.Status #Status of API response
        $Routes = $Content.Routes.Legs.Steps #Routes from API response
        
        #To Clear unwanted data from the String
        Function Remove-UnwantedString($Str)
        {
            $str = $Str.replace('<div style="font-size:0.9em">','')
            $str = $str.replace('</div>','')
            $str = $str.replace('<b>','')
            $str = $str.replace('</b>','')
            $str = $str.replace('&nbsp;','')
            Return $str
        }
        
        If($status -eq 'OK')
        {
            $Routes| Select @{n='Instructions';e={Remove-UnwantedString($_.html_instructions)}},`
                            #@{n='Duration(In Sec)';e={$_.duration.value}},`
                            @{n='Duration';e={$_.duration.text}},`
                            #@{n='Distance(Meters/Feets)';e={$_.distance.value}},`
                            @{n='Distance';e={$_.distance.text}},`
                            @{n='Mode';e={((Get-Culture).TextInfo).totitlecase($_.Travel_mode.tolower())}}, `
                            @{n='Maneuver';e={((Get-Culture).TextInfo).totitlecase($_.maneuver)}}`
        
        }
        elseif($Status -eq 'ZERO_RESULTS')
        {
            # In case the no data is recived due to incorrect parameters
            "Zero Results Found :  Try changing the parameters"
        }
    }
    Catch
    {
        "Something went wrong, please try running again."
        $EV.message
    }
}

<#
.SYNOPSIS
    Returns Duration, Distance and Fare for a Origin and destination pair.
.DESCRIPTION
    This Cmdlet employs Google Maps Distance Matrix API to provide travel distance and time for a origins and destinations pair. The information returned is based on the recommended route between start and end points.
    
    You need to register and get an API key from the below link. Once you've the key setup an Environment variable like $env:GoogleDistance_API_Key = "YOUR API KEY" before hand to make this function work. You can save this $Env variable in your profile, so that it automatically loads when you open powershell console.

    API Key Link - https://developers.google.com/maps/documentation/distance-matrix/get-api-key
.PARAMETER From
    The starting point for calculating travel distance and time.
.PARAMETER To
    Finishing point for calculating travel distance and time.
.PARAMETER Mode
    For the calculation of distances, you may specify the transportation mode to use. By default, distances are calculated for driving mode. 
    
    The following travel modes are supported:
    1. driving   : Indicates distance calculation using the road network (default) .
    2. walking   : Requests distance calculation for walking via pedestrian paths & sidewalks (where available).
    3. bicycling : Requests distance calculation for bicycling via bicycle paths & preferred streets (where available).
    4. transit   : Requests distance calculation via public transit routes (where available). Function also provides total Fares during travel using public transports.
.PARAMETER InMiles
    Use 'InMiles' switch to convert distance in Feets and Miles instead of Meters and Kilometers.
.EXAMPLE
    PS D:\> Get-Distance -From "Dlf phase 3" -To "akshardham temple, delhi" -Mode transit
    
    From     : DLF Phase 3, Sector 24, Gurgaon, Haryana 122002, India
    To       : Akshardham, Noida Link Rd, Ganesh Nagar, New Delhi, Delhi 110092, India
    Time     : 1 hour 17 mins
    Distance : 34.2 km
    Mode     : Transit
    Fare     : 47 INR

    Function calulates and returns the distance, duration and fares from source to destination.
.NOTES
    Author : Prateek Singh - @SinghPrateik
    Blog   : geekeefy.wordpress.com
       
#>
Function Get-Distance
{

    Param(
            [Parameter(Mandatory=$true,Position=0)] [String] $From,
            [Parameter(Mandatory=$true,Position=1)] [String] $To,
            [Parameter(Position=2)] [ValidateSet('driving','bicycling','walking','transit')] [string] $Mode = 'driving',
            [Switch] $InMiles
    )
    
    $Units='metric' # Default set to Kilometers

    If($InMiles)
    {
        $Units = 'imperial'  # If Switch is selected, use 'Miles' as the Unit
    }

    If(!$env:GoogleDistance_API_Key)
    {
        Throw "You need to register and get an API key and save it as environment variable `$env:GoogleDistance_API_Key = `"YOU API KEY`" `nFollow this link and get the API Key - https://developers.google.com/maps/documentation/distance-matrix/get-api-key `n`n "
    }
 
    Try
    {

        #Invoking the web URL and fetching the page content
        $webpage = Invoke-WebRequest "https://maps.googleapis.com/maps/api/distancematrix/json?origins=$From&destinations=$To&mode=$($Mode.toLower())&units=$Units&key=$env:GoogleDistance_API_Key" -UseBasicParsing -ErrorVariable EV
        
        # Capturing the content from the Webpage
        $content = $webpage.Content | ConvertFrom-Json
        $Results = $content.rows
        $Status = $content.status
        $OriginAddress = $content.origin_addresses
        $DestinationAddress = $content.destination_addresses

        If($status -eq 'OK')
        {


            If(!$Results.elements.fare.value)
            {   
                $Results| select @{n='From';e={$OriginAddress}},` 
                                 @{n='To';e={$DestinationAddress}},`
                                 @{n='Time';e={$Results.elements.duration.text}},`
                                 @{n='Distance';e={$Results.elements.distance.text}},`
                                 @{n='Mode';e={(Get-Culture).TextInfo.ToTitleCase($mode)}}
            }
            Else
            {
                $Results| select @{n='From';e={$OriginAddress}},` 
                                 @{n='To';e={$DestinationAddress}},`
                                 @{n='Time';e={$Results.elements.duration.text}},`
                                 @{n='Distance';e={$Results.elements.distance.text}},`
                                 @{n='Mode';e={(Get-Culture).TextInfo.ToTitleCase($mode)}},`
                                 @{n='Fare';e={"$($Results.elements.fare.value) $($Results.elements.fare.currency)"}}
            }
        }
        Elseif($status -eq 'ZERO_RESULTS')
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

<#
.SYNOPSIS
    Returns TimeZone information for geographic coordinates (Latitide and Longitude).
.DESCRIPTION
    This cmdlet utilizes Requesting the time zone information for a specific Latitude/Longitude pair and  will return the name of that time zone, ID and Local time of the place.

    You need to register and get an API key from the below link. Once you've the key setup an Environment variable like $env:GoogleTimezone_API_Key = "YOUR API KEY" before hand to make this function work. You can save this $Env variable in your profile, so that it automatically loads when you open powershell console.

    API Key Link - https://developers.google.com/maps/documentation/timezone/get-api-key
.PARAMETER Coordinates
    The latitude and longitude values specifying the location for which you wish to obtain the Timezone information
.EXAMPLE
    PS D:\> Get-TimeZone -Coordinates "38.8976763,-77.0365298"

    TimeZone              TimeZoneID       LocalTime           
    --------              ----------       ---------           
    Eastern Daylight Time America/New_York 5/13/2016 5:14:42 PM
    
    
    
    PS D:\> "white house","Microsoft redmund" | Get-GeoCoding | select Coordinates -ExpandProperty Coordinates | Get-TimeZone
    
    TimeZone              TimeZoneID          LocalTime           
    --------              ----------          ---------           
    Eastern Daylight Time America/New_York    5/13/2016 5:15:14 PM
    Pacific Daylight Time America/Los_Angeles 5/13/2016 2:15:14 PM
        
    In above example, Function returns Timezone information like TimeZone Name and Local time for the geographical cordinates (Latitude and Longitude).
    You can also pass multiple latitude and longitude values through pipeline to the cmdlet, to get the corresponding Timezones\Local Times.

.NOTES
    Author: Prateek Singh - @SinghPrateik
       
#>  
Function Get-TimeZone
{
    [cmdletbinding()]
    Param(
            [Parameter(Mandatory=$True,ValueFromPipeline=$True, HelpMessage="Enter Latitude and Longitude")] [String] $Coordinates
    )

    Begin
    {
        If(!$env:GoogleTimezone_API_Key)
        {
            Throw "You need to register and get an API key and save it as environment variable `$env:GoogleTimezone_API_Key = `"YOUR API KEY`" `nFollow this link and get the API Key - https://developers.google.com/maps/documentation/timezone/get-api-key `n`n "
        }

        $SourceDateTime =  Get-Date "January 1, 1970"
        $CurrentDateTime = Get-Date
        $TimeStamp = [int]($CurrentDateTime - $SourceDateTime).totalseconds
    }
    Process
    {
        ForEach($Item in $Coordinates)
        {
            Try
            {
                $Webpage = Invoke-WebRequest -Uri "https://maps.googleapis.com/maps/api/timezone/json?location=$Item&timestamp=$TimeStamp&key=$env:GoogleTimezone_API_Key" -UseBasicParsing -ErrorVariable EV                           
                $Webpage.Content | ConvertFrom-Json|`
                Select-Object @{n='TimeZone';e={$_.timezonename}}, @{n='TimeZoneID';e={$_.timezoneID}}, @{n='LocalTime';e={($SourceDateTime.ToUniversalTime()).AddSeconds($_.dstOffset+$_.rawoffset+$TimeStamp)}}
            }
            Catch
            {
                "Something went wrong, please try running again."
                $ev.message              
            }
        }
    }
}

<#
.SYNOPSIS
    Returns Nearby places depending upon a keyword for a geographic coordinates (Latitide and Longitude).
.DESCRIPTION
    This Cmdlet employs Google Places API to query nearby places on a variety of categories, such as: establishments, prominent points of interest, geographic locations, and more for a coordinate. 
    
    You need to register and get an API key from the below link. Once you've the key setup an Environment variable like $env:GooglePlaces_API_Key = "YOUR API KEY" before hand to make this function work. You can save this $Env variable in your profile, so that it automatically loads when you open powershell console.

    API Key Link - https://developers.google.com/places/web-service/get-api-key
.PARAMETER LatLng
    The latitude/longitude around which to retrieve place information. This must be specified as latitude,longitude
.PARAMETER Radius
    Defines the distance (in meters) within which to bias place results. The maximum allowed radius is 50 000 meters. Results inside of this region will be ranked higher than results outside of the search circle; however, prominent results from outside of the search radius may be included.
.PARAMETER Type
    Restricts the results to places matching the specified types, like - Restaurant, Store, Scool or Establishment
.PARAMETER Keyword
    Keywords are one or more terms to be matched against the names of places. Results will be restricted to those containing the passed keyword values.
.EXAMPLE
    PS D:\> Get-GeoCoding "eiffel tower"| select latlng -ExpandProperty latlng -OutVariable latlng
    48.8583701,2.2944813
    
    PS D:\> Get-NearbyPlace -LatLng $latlng -Radius 500 -Type dance -Keyword music | ft -AutoSize
    
    Name                          Address                                       TypeOfPlace   Coordinates                        OpenNow
    ----                          -------                                       -----------   -----------                        -------
    Eiffel Tower                  Champ de Mars, 5 Avenue Anatole France, Paris Premise       48.8583701,2.2944813               True
    Bateaux Parisiens             Port de la Bourdonnais, Paris                 Travel Agency 48.8603850,2.2935650               True
    International School of Paris 6 Rue Beethoven, Paris                        School        48.8585750,2.2873589 Info not available
    
   In above example, First we calculated the Latitude and Logitude of "Eiffel Tower" then we passed this info to Get-Nearbyplace function to search for places within radius of 500 meter, with "dance" type and keyword "Music" 

.EXAMPLE
    PS D:\> "eiffel tower","white house"|Get-GeoCoding| select latlng -ExpandProperty latlng | Get-NearbyPlace -Radius 500 -Type food -Keyword indian | ft -AutoSize
    
    Name            Address                                        TypeOfPlace Coordinates                         OpenNow
    ----            -------                                        ----------- -----------                         -------
    New Jawad       12 Avenue Rapp, Paris                          Restaurant  48.8602626,2.3007111                False
    Restaurant Goa  19 Rue Augereau, Paris                         Restaurant  48.8569876,2.3024105                False
    Yogis Bar       63 Avenue de la Bourdonnais, Paris             Store       48.8571656,2.3014317                False
    The Bombay Club 815 Connecticut Avenue Northwest, Washington   Restaurant  38.9009502,-77.0379728              False
    Heritage India  1901 Pennsylvania Avenue Northwest, Washington Restaurant  38.9006366,-77.0437235 Info not available

    You can also pass multiple latitude and longitude values through pipeline to the cmdlet, to find the nearby places as the function accepts Latitude and Longitude from pipeline

.NOTES
    Author : Prateek Singh - @SinghPrateik
    Blog   : geekeefy.wordpress.com
       
#>  
Function Get-NearbyPlace
{
    [CmdletBinding()]
    Param(
            [Parameter(Mandatory=$true, Position=0, ValueFromPipeline =$True)] [String] $Coordinates,
            [Parameter()] [String]$Radius=500,
            [Parameter()] [String] $TypeOfPlace='Food',
            [Parameter()] [String[]] $Keyword
    )
    
    Begin
    { 
         If(!$env:GooglePlaces_API_Key)
         {
             Throw "You need to register and get an API key and save it as environment variable `$env:GooglePlaces_API_Key = `"YOUR API KEY`" `nFollow this link and get the API Key - https://developers.google.com/places/web-service/get-api-key `n`n "
         }
    }

    Process
    {

        Foreach($Item in $Coordinates)
        {
            Try
            {
                $webpage = Invoke-WebRequest "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$($Item.tostring())&radius=$Radius&types=$Type&name=$(([string]$Keyword).replace(' ','|'))&key=$env:GooglePlaces_API_Key" -UseBasicParsing -ErrorVariable ev
                
                # Capturing the content from the Webpage as XML
                $content = $webpage.Content|ConvertFrom-Json
                $Results = $content.results
                $Status = $content.status
 
                # Condition to Check 'Zero Results'
                If($status -eq 'OK')
                {
                $Results| select @{n='Name';e={$_.name}},`
                                 @{n='Address';e={$_.Vicinity}},` 
                                 @{n='TypeOfPlace';e={(Get-Culture).TextInfo.ToTitleCase((($_.Types)[0]).replace('_',' '))}},`
                                 @{n='Coordinates';e={"$("{0:N7}" -f $_.geometry.location.lat),$("{0:N7}" -f $_.geometry.location.lng)"}},`
                                 @{n='OpenNow';e={if($_.opening_hours){($_.opening_hours).open_now}else{"Info not available"}}}
                }
                Elseif($status -eq 'ZERO_RESULTS')
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

<#
.SYNOPSIS
    This Cmdlet returns location based on information using nearby WiFi access points.
.DESCRIPTION
    The Cmdlet captures information of nearby WiFi nodes and send it to Google Maps Geolocation API to return location and Geographical coordinates.

    NOTE : Incase there are no Wireless acceses point (WiFi) available, API won't be able to return the location information.

.PARAMETER WithCoordinates
    To return the geographical coordinates with the human readable address.
.EXAMPLE
    PS D:\> WhereAmI
    U-15 Road, U Block, DLF Phase 3, Sector 24, Gurgaon, Haryana 122010, India

    Run the cmdlet and it will return your Location address using your Wifi Nodes.
.EXAMPLE
    PS D:\> WhereAmI -WithCoordinates | fl
    
    Address     : U-15 Road, U Block, DLF Phase 3, Sector 24, Gurgaon, Haryana 122010, India
    Coordinates : 28.494853,77.095529

    Use '-WithCoordinates' switch to return the geographical coordinates with the address.
.NOTES
    Author: Prateek Singh - @SinghPrateik
       
#> 
Function Get-GeoLocation
{
    Param(
            [Switch] $WithCoordinates
    )
    
    $WiFiAccessPointMACAdddress = netsh wlan show networks mode=Bssid | Where-Object{$_ -like "*BSSID*"} | %{($_.split(" ")[-1]).toupper()}

    If(!$WiFiAccessPointMACAdddress)
    {
        "No Wifi Access point found! Please make sure your WiFi is ON."
    }
    Else
    {

        $body = @{wifiAccessPoints = @{macAddress = $($WiFiAccessPointMACAdddress[0])},@{macAddress = $($WiFiAccessPointMACAdddress[1])}}|ConvertTo-Json

        Try
        {
            $webpage = Invoke-WebRequest -Uri "https://www.googleapis.com/geolocation/v1/geolocate?key=$env:GoogleGeoloc_API_Key" `
                                         -ContentType "application/json" `
                                         -Body $Body `
                                         -UseBasicParsing `
                                         -Method Post `
                                         -ErrorVariable EV
        }
        Catch
        {
            "Something went wrong, please try running again."
            $ev.message 
        }
  
        $YourCoordinates = ($webpage.Content | ConvertFrom-Json).location

        #Converting your corridnates to "Latitude,Longitude" string in order to reverse geocode it to obtain your address
        $LatLang = ($YourCoordinates | Select @{n='LatLng';e={"$("{0:N7}" -f $_.lat),$("{0:N7}" -f $_.lng)"}}).LatLng 
        
        #Your address
        $Address = ($LatLang| Get-ReverseGeoCoding).Address

        If($WithCoordinates)
        {
            ''|Select @{n='Address';e={$Address}}, @{n='Coordinates';e={$LatLang}}
        }
        else
        {
            $Address
        }
    }
}