$Global:refType = @{
    [byte]32 = 'BR'
    [byte]33 = 'sSYN'
    [byte]128 = 'sAV'
    [byte]129 = 'SECAUDIOEVENT'
    [byte]130 = 'SECVIDEOEVENT'
    [byte]131 = 'sKEY'
    [byte]132 = 'sTKY'
    [byte]133 = 'bAV'
    [byte]134 = 'SECAVEVENTWITHKEY' 
    [byte]136 = 'bGPI'
    [byte]137 = 'sGPI'
    [byte]144 = 'sTAO'
    [byte]145 = 'sAOV'
    [byte]146 = 'SECAVEVENTWITHAUDIOOVER'
    [byte]160 = 'sDAT'
    [byte]164 = 'sSYS'
    [byte]165 = 'bSYS'
    [byte]176 = 'sRSW'
    [byte]177 = 'sXP'
    [byte]178 = 'sAXP'
    [byte]181 = 'sREC'
    [byte]224 = '****'
    [byte]225 = 'cmID'
    [byte]226 = 'SECAPPFLAG'
    [byte]227 = 'sBAR'
}
$Global:refTypeBuffer = @{
    [byte]128 = 'vDT'
    [byte]160 = 'sDAT'
}
$Global:refEventControl = @{
    15 = 'P' #'autoplay'
    14 = 'T' #'autothread'
    13 = 'S' #'autoswitch'
    12 = 'R' #'autorecord'
    11 = 'O' #'autotimed'
    10 = 'X' #'autoexception'
    9 = 'U' #'autoupcount'
    8 = 'M' #'manualstart'
    7 = 'C' #'autocontactstart'
    6 = 'N' #'automarktime'
    5 = 'D' #'autodeadroll'
    4 = 'V' #'switchvideoonly'
    3 = 'I' #'switchaudioonly'
    2 = 'J' #'switchrejoin'
    1 = '?' #'userbitonly'
    0 = 'E' #'switchAudioVideoIndependent'
}
$Global:refExtEventControl = @{
    5 = 'Q' #tAudibleAutoMarktime
    4 = '?' #tFrameDropped
    3 = '?' #tCountedRoundDF
    2 = '>' #tStartEventEndTimed
    1 = '<' #tStartEventBacktimed
    0 = '=' #tMatchPrimaryDuration
}