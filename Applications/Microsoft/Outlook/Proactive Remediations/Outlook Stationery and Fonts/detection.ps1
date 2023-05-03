try{
    # Font Settings Outlook
    $ComposeFontComplex = ""
    $ComposeFontSimple = ""
    $ReplyFontComplex = ""
    $ReplyFontSimple = ""
    $TextFontComplex = ""
    $TextFontSimple = ""

    $Path = "HKCU:\Software\Microsoft\Office\16.0\Common\MailSettings" 

    if(($(Get-ItemPropertyValue -Path $Path -Name ComposeFontComplex) -eq ([byte[]]$($ComposeFontComplex.Split(',') | % { "$_"}))) `
    -and ($(Get-ItemPropertyValue -Path $Path -Name ComposeFontSimple) -eq ([byte[]]$($ComposeFontSimple.Split(',') | % { "$_"}))) `
    -and ($(Get-ItemPropertyValue -Path $Path -Name MarkCommentsWith) -eq ([byte[]]$($MarkCommentsWith.Split(',') | % { "$_"}))) `
    -and ($(Get-ItemPropertyValue -Path $Path -Name ReplyFontComplex) -eq ([byte[]]$($ReplyFontComplex.Split(',') | % { "$_"}))) `
    -and ($(Get-ItemPropertyValue -Path $Path -Name ReplyFontSimple) -eq ([byte[]]$($ReplyFontSimple.Split(',') | % { "$_"}))) `
    -and ($(Get-ItemPropertyValue -Path $Path -Name TextFontComplex) -eq ([byte[]]$($TextFontComplex.Split(',') | % { "$_"}))) `
    -and ($(Get-ItemPropertyValue -Path $Path -Name TextFontSimple) -eq ([byte[]]$($TextFontSimple.Split(',') | % { "$_"})))
    ){exit 1}else{exit 0} # exit 0 = detectet, 1 = remediation needed

}catch{
    Write-Output $_
    exit 1
}

