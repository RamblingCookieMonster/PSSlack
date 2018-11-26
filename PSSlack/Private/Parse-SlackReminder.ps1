# Parse output from reminders.list
Function Parse-SlackReminder {
    [cmdletbinding()]
    param(
        $InputObject
    )
    $Reminders = $InputObject.reminders
    $pstypename = 'PSSlack.Reminder'
    foreach($Reminder in $Reminders)
    {
        $UserName = $null
        $CreatorName = $null
        $CompleteTime = $null
        $Map = @{}
        foreach($Key in $Script:_PSSlackUserMap.Keys) {
            $Map.add($Script:_PSSlackUserMap[$Key], $Key)
        }
        if($Map.ContainsKey($Reminder.user))
        {
            $UserName = $Map[$Reminder.user]
        }
        if($Map.ContainsKey($Reminder.creator))
        {
            $CreatorName = $Map[$Reminder.creator]
        }
        if($Reminder.complete_ts -ne 0){
            $CompleteTime = ConvertFrom-UnixTime $Reminder.complete_ts
        }
        if($Script:_PSSlackUserMap.Keys.Count -like 0) {
            Write-Verbose "No Slack User Map found.  Please run Get-SlackUserMap -Update"
        }
        [pscustomobject]@{
            PSTypeName = $pstypename
            ID = $Reminder.id
            Creator = $Reminder.creator
            CreatorName = $CreatorName
            User = $Reminder.user
            UserName = $UserName
            Text = $Reminder.text
            Recurring = $Reminder.recurring
            Timestamp = $Reminder.time
            Date = ConvertFrom-UnixTime $Reminder.time
            CompleteTS = $Reminder.complete_ts
            DateComplete = $CompleteTime
            Raw = $Reminder
        }
    }
}