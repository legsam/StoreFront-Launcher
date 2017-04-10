<# 
.SYNOPSIS
    This script verify the URls in a CSV and launch the default browser with the first answering URl in parameter.
.DESCRIPTION
    This script is given to the community! I'm glad if it can be helpful! This script has been created with the help of one of colleague Y.PARIS
.NOTES
    Copyright (c) Samuel LEGRAND. All rights reserved.
#>


# Variable LaunchTrigger is used to know if we have already launch one URl
[bool]$global:LaunchTrigger = $false

#The Scripting Block used to verify the availability of the URls
[ScriptBlock]$SB = {
   param ([string]$URL)
   write-host "URL : $URL" -ForegroundColor Cyan
   $HTTP_Request = [System.Net.WebRequest]::Create($URL)
   $HTTP_Request.Timeout = 1000
   try{$HTTP_Response = $HTTP_Request.GetResponse()}
   catch{throw}
   }

#The script uses jobs to parallelize the tests
function Create-UrlTestJob($url){
   $job = start-job -scriptblock $SB -ArgumentList $url
   $job | Add-Member -NotePropertyName "URL" -NotePropertyValue $url
   $tmp = Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
       if(($sender.State -eq "Completed") -and (!$global:LaunchTrigger)){Open-WebUrl $sender}
       }
   }

#The launching URl function
function global:Open-WebUrl($job){
   if (!$LaunchTrigger){
       $global:LaunchTrigger=$true;
       Write-host "`r`Found!: " -ForegroundColor green -NoNewline; write-host $job.URL -f White
       start $job.URL
       }
   }

Write-host "Looking for an available web server..." -ForegroundColor Green

$URls = Import-Csv .\URls.csv

ForEach($URl in $URls){Create-UrlTestJob $URl.URl}

write-host "Waiting" -NoNewline

while((get-job -state running | ?{$_.location -eq "localhost"}) -and (!$global:LaunchTrigger)){
   write-host "." -NoNewline
   Start-Sleep -M 200
   }

if(!$global:LaunchTrigger){
   write-host "`r`nSorry, no available site found." -f Yellow
   Start-sleep 5
   }
else{
   Remove-Job * -Force
   Write-Host "Thanks for using my script !" -ForegroundColor Cyan
   }
