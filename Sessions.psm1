. $PSScriptRoot\New-ProxyPSSession.ps1
. $PSScriptRoot\New-ProxyCimSession.ps1
. $PSScriptRoot\Set-SessionFavorite.ps1
. $PSScriptRoot\Get-SessionFAvorite.ps1


New-Alias -Name npsn -Value New-ProxyPSSession -Description "Alias for New-ProxyPSSession"
New-Alias -Name npcms -Value New-ProxyCimSession -Description "Alias for New-ProxyCimSession"
New-Alias -Name gsf -Value Get-SessionFavorite -Description "Alias for Get-SessionFavorite"
New-Alias -Name ssf -Value Set-SessionFavorite -Description "Alias for Set-SessionFavorite"