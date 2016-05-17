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