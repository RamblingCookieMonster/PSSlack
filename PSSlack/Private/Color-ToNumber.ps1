Function Color-ToNumber {
    param(
        [System.Drawing.Color]$Color
    )
    '#{0:X2}{1:X2}{2:X2}' -f $Color.R,
                             $Color.G,
                             $Color.B
}