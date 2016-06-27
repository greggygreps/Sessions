# Sessions
This PowerShell module contains proxy functions for the New-PSSession &amp; New-CimSession cmdlets.
The proxy functions add features to the cmdlets in the form of two dynamic parameters: SearchBase and Favorite.
#### SearchBase
The dynamic parameter SearchBase will be a validated set on the output of this command:
```powershell
Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
```

#### Favorite
The dynamic parameter Favorite will be a validated set on the names of favorites stored in:
```powershell
$env:APPDATA\Sessions\Favorites.json
```

Favorites are created and retrieved with two additional functions:
##### `Get-SessionFavorite`
##### `Set-SessionFavorite`
