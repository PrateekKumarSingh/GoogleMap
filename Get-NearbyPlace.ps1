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