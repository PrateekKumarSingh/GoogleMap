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