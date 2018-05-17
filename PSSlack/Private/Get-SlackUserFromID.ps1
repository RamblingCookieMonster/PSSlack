function Get-SlackUserFromID {
    [cmdletbinding()]
    param(
        [string[]]$Id,
        $UserMap
    )
    begin {
        if(-not $PSBoundParameters.ContainsKey('UserMap')){
            $UserMap = $Script:_PSSlackUserMap
            if($UserMap.Keys.Count -like 0) {
                Write-Verbose "No Slack User Map found.  Please run Get-SlackUserMap -Update"
            }
        }
        $Map = @{}
        foreach($Key in $UserMap.Keys) {
            $Map.add($UserMap[$Key], $Key)
        }
    }
    process {
        if(-not $Map.Keys.count) {
            return $Id
        }
        foreach($UserID in $Id) {
            if($Map.ContainsKey($UserID)) {
                $Map[$UserID]
            }
            else {
                $UserID
            }
        }
    }
}