
#Dependencies run "Install-Module -Name PsIni -RequiredVersion 3.1.2 -Scope CurrentUser"   to get PSIni gallery
#Assumes if using multiple ini files they all have the same value for FreqCalibration 
#In Variables section edit:
    # $SkimmerCallSign to your skimmer callsign
    # $AggregatorPath
    # $SkimSrvPath



#Set Variables
$SM7IUNWebPage = "https://sm7iun.se/rbn/analytics/"
$SkimmerCallsign = "MM0ZBH"
$AggregatorPath = 'C:\Users\paul\Aggregator v6.3\Aggregator v6.3'
$SkimSrvPath = 'C:\Program Files (x86)\Afreet\SkimSrv\SkimSrv.exe'


#infinite loop
for(;;)
{


#Start Timer   48 hours = 172800
#Assumes a calibration check and update every 48 hours based on the recommendation on the SM7IUN website 
$seconds = 2
1..$seconds | ForEach-Object {
    Write-Progress -Activity "Sleeping..." -Status "$_ seconds elapsed" -PercentComplete ($_/$seconds*100)
    Start-Sleep -Seconds 1
    }


#Open SM7IUN webpage - analytics
$web = Invoke-WebRequest $SM7IUNWebPage

#get line from SM7IUN webpage with skimmer callsign analysis
$ReadWebPageData = $web.tostring() -split "[`r`n]" | select-string $SkimmerCallsign

#query line to get correction value - only value required is #Adjustment
$Blank, $Skimmer, $ppm, $Spots, $Adjustment = $ReadWebPageData[0] -split '\s+'


###############################################################################################
#REPEATABLE CODE BLOCK
#Repeat this code block section for each Skimmer.ini file, ie if you are using different ini rotation in Aggregator

#Path to skimmer.ini file - amend for each skimmer.ini file you are using
$FilePathSkimmerIni = "C:\Users\paul\Downloads\SkimSrvLight.ini"

#Read skimmer.ini file and get current FreqCalibration value
$ini = Get-IniContent $FilePathSkimmerIni
$CurrentFreqCal = $ini["Skimmer"]["FreqCalibration"]

#Convert format of strings to decimal 
$CurrentFreqCal = [Decimal]$CurrentFreqCal
$Adjustment = [Decimal]$Adjustment

#Calculate updated Frequency Calibration
$UpdatedFreqCal = $CurrentFreqCal * $Adjustment

#Output updated Freqency Calibration to screen
$UpdatedFreqCal

#Write new FreqCalibration value to skimmer.ini file
$ini["Skimmer"]["FreqCalibration"] = $UpdatedFreqCal

#Save updated skimmer.ini file
$ini | Out-IniFile -FilePath $FilePathSkimmerIni -Force

#END OF REPEATABLE CODE BLOCK
###############################################################################################

#Stop processes
Stop-Process -Name 'Aggregator v6.3'
Stop-Process -Name SkimSrv


#Start processes to use updated skimmer.ini file, if using Rotation in Aggregrator it will restart SkimSrv again

Start-Process $AggregatorPath
Start-Process $SkimSrvPath

#Loop back to start
}