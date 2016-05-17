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