$string = ""
for ($i = 1; $i -le 24; $i++) {
    $string += "'WTL-ADC-CTC-{0:d2}.WTLDEV.NET', " -f $i
}
$string.Substring(0,($string.Length -2))

