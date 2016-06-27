# Sessions
This PowerShell module contains proxy functions for the New-PSSession &amp; New-CimSession cmdlets.
The proxy functions add features to the cmdlets in the form of two dynamic parameters: SearchBase and Favorite.

These additional parameters allow users to easily select multiple computers to start a PS or Cim session with and also bookmark frequently used sessions as a favorite.
#### SearchBase
The dynamic parameter SearchBase will be a validated set on the output of this command:
```powershell
Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
```
The Organizational Unit selected will be used as the SearchBase for this command:
```powershell
Get-ADComputer -SearchBase $distinguishedName -Filter * | Select DnsHostName, DistinguishedName, Enabled, SID
```
whose output will be sent to Out-GridView so that one or more computers can be selected to start a session with.

#### Favorite
The dynamic parameter Favorite will be a validated set on the names of favorites stored in:
```powershell
$env:APPDATA\Sessions\Favorites.json
```

Favorites are created and retrieved with two additional functions:
##### `Get-SessionFavorite`
##### `Set-SessionFavorite`

## Set-SessionFavorite
A function to create a favorite to be used with the New-ProxyPSSession and New-ProxyCimSession proxy functions.

Sessions are saved to:
```powershell
$env:APPDATA\Sessions\Favorites.json
```

##### SearchBase
Like in the New-ProxyPSSession and New-ProxyCimSession functions, this dynamic parameter will be a validated set on the output of this command: 
```powershell
Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
```
which will be used to send a list of computers to Out-GridView to be selected.

##### DNSHostName
This parameter takes it's value by property name from the pipeline.
```powershell
Get-ADComputer -Identity Test5 | Set-SessionFavorite -Name TestMachines
```

Once one or more computers are selected, the favorite will be created with the parameter Name as the identifier.
If a favorite already exists with the Name provided, you will prompted to overwrite or append the existing one.

## Get-SessionFavorite
A function to retrieve the favorites created from the Set-SessionFavorite function.

##### Name
The dynamic parameter Name will be a validated set on the names stored in:
```powershell
$env:APPDATA\Sessions\Favorites.json
```
If no Name is provided, all stored favorites will be returned.
