 function Get-UnixTime {
     param($Date)
     $unixEpochStart = New-Object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
     [int]($Date.ToUniversalTime() - $unixEpochStart).TotalSeconds
 }