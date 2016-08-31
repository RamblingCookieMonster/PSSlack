Function Color-ToNumber {
    [cmdletbinding()]
    param(
        [object]$Color
    )
    if(-not $IsCoreCLR)
    {
        [System.Drawing.Color] $Color = $Color
        '#{0:X2}{1:X2}{2:X2}' -f $Color.R,
                                 $Color.G,
                                 $Color.B
    }
}