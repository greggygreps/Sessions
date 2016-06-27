function Set-SessionFavorite {
    <#
    .Synopsis
        A function to create a new favorite that can be used with the Favorite parameter of the New-ProxyPSSession and New-ProxyCimSession proxy functions of the Sessions module.
        The Set-SessionFavorite will create a list of computers and store them in $env:APPDATA\Sessions\Favorites.json.
        The dynamic parameter SearchBase will validate the set of possible search bases. Alternatively, computer names can be piped to the function via Get-ADComputer.
        If a favorite already exists with the value of the Name parameter, the user will be prompted to append or overwrite the existing favorite.
    .Inputs
        Microsoft.ActiveDirectory.Management.ADAccount. You can pipe objects from Get-ADComputer to Set-SessionFavorite
        The DNSHostName property will be used from piped objects to build the list of computers to be added to ($env:APPDATA)+'\Sessions\Favorites.json'
    .Outputs
        System.Object. Set-SessionFavorite returns the name of the newly created favorite and the computers assigned to it.
    .Parameter Name
        Accepts a string which will be the identifier for the computers assigned to the favorite.
    .Parameter SearchBase
        An optional dynamic parameter which set is validated on the results of the following cmdlet:
        Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
    .Parameter DNSHostName
        An optional parameter that accepts its value by property name from the pipeline via Get-ADComputer.
    .Parameter AuthType
        An optional parameter for splatting the Get-ADComputer lookup within the function.
    .Parameter Credential
        An optional parameter for splatting the Get-ADComputer lookup within the function.
    .Parameter SearchScope
        An optional parameter for splatting the Get-ADComputer lookup within the function. 
    .Example
        Get-ADComputer -LDAPFilter "(name=*alfano*)" | Set-SessionFavorite -Name MyComputers
            This example pipes the DNSHostName property of results from the Get-ADComputer cmdlet to the Set-SessionFavorite function
    .Example
        Set-SessionFavorite -Name nucleus -SearchBase Hooli
            This example returns all computers from the specified SearchBase in GridVew and creates a favorite named nucleus from the selected computers.
    .Notes
        Author   : Gregory Alfano
        Last Edit: 06-24-2016
        Version  : 1.0
    #>

    [CmdletBinding()]
    Param(

        [Parameter(Mandatory=$True)]
        [string]$Name,

        #Optional parameter to be splatted to Get-ADComputer
        [Parameter(Mandatory=$False,ParameterSetName='SearchBase')]
        [ValidateSet('0','1')]
        [Int]$AuthType,

        #Optional parameter to be splatted to Get-ADComputer
        [Parameter(Mandatory=$False,ParameterSetName='SearchBase')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        #Optional parameter to be splatted to Get-ADComputer
        [Parameter(Mandatory=$False,ParameterSetName='SearchBase')]
        [ValidateRange(0,2)]
        [Int]$SearchScope,

        #Optional parameter that takes it's value from pipeline via Get-ADComputer
        [Parameter(Mandatory=$False,ParameterSetName='DNSHostName',ValueFromPipelineByPropertyName=$True)]
        [String[]]$DNSHostName

    )
    dynamicParam {

            #Set the dynamic parameter's name
            $searchBasesParameterName = 'SearchBase'

            #Create the dictionary
            $runtimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            #Create the collection of attributes
            $searchBasesAttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
            #Create and set the parameters' attributes
            $searchBasesParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $searchBasesParameterAttribute.Mandatory = $False
            $searchBasesParameterAttribute.ParameterSetName = 'SearchBase'
            $searchBasesParameterAttribute.Position = 0

            #Add the attributes to the attributes collection
            $searchBasesAttributeCollection.Add($searchBasesParameterAttribute)

            #Generate and set the ValidateSet
            $searchBasesNames = Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
            $searchBasesValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($searchBasesNames)

            #Add the ValidateSet to the attributes collection
            $searchBasesAttributeCollection.Add($searchBasesValidateSetAttribute)

            #Create and return the dynamic parameter
            $searchBasesRuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($searchBasesParameterName, [string],$searchBasesAttributeCollection)
            $runtimeParameterDictionary.Add($searchBasesParameterName, $searchBasesRuntimeParameter) 

            return $runtimeParameterDictionary
    }

    begin {

        #Bind the parameter to the SearchBase variable
        $SearchBase = $PsBoundParameters[$searchbasesParameterName]

        #Store the path of the favorites to a variable.
        $favoritesPath = ($env:APPDATA)+'\Sessions\Favorites.json'

        #If the Favorites.json file does not exist, create it.
        if (!(Test-Path $favoritesPath)) {

            Write-Error "$favoritesPath does not exist. Creating it..."

$createJson = @'
{
    "Favorites":{}
}
'@
            $createJson | Out-File $favoritesPath

        }

        #Grab the content of Favorites.json, convert it from json, and store it in a variable.
        $favoritesJson = Get-Content $favoritesPath -raw | ConvertFrom-Json

        #Store the names of the current favorites to a variable
        $currentNames = $favoritesJson.favorites | Get-Member -MemberType NoteProperty | select -expand name

        #If the SearchBase parameter was used, perform Get-ADComputer with the supplied SearchBase and optional splatted parameters.
        #Pipe the retrieved computers to GridView to be selected and sent down the pipe.
        if ($SearchBase) {
            $Null = $PsBoundParameters.Remove('Name')
            $Null = $PsBoundParameters.Remove('SearchBase')
            $distinguishedName = Get-ADOrganizationalUnit -LDAPFilter "(name=$searchbase)" | select -ExpandProperty distinguishedname
            $computerLookup = Get-ADComputer @PSBoundParameters -SearchBase $distinguishedName -Filter * | Select DnsHostName, DistinguishedName, Enabled, SID | Sort-Object DnsHostName
            [string]$computers = $computerLookup | Out-Gridview -PassThru | Select -ExpandProperty dnshostname

            #Throw an error if no computers were selected.
            if (!($computers)) {

                throw 'Please select one or more computers.'

            } else {
                #Make the computers comma-delimited.
                $commaDelimitedComputers = $computers -replace " ",","

            }

        }

    }

    process {

        #If Set-GASessionFavorites was piped from Get-ADComputer, take the DNSHostName property from each piped object and add it to the computers array.
        If ($DNSHostName) {

            $computers += $DNSHostName

        }

    }

    end {

        #If Set-GASessionFavorites was piped from Get-ADComputer, turn the array into a comma-delimited string.
        if ($DNSHostName) {

            $commaDelimitedComputers = $computers -join ","
        
        }

        #If the value of Name parameter matches a current name, prompt for append or overwrite. The default behavior is to append.
        if($Name -in $currentNames) {

            $currentValue = Get-SessionFavorite -Name $Name | Select -ExpandProperty $Name
            Write-Host "$Name is already set to:"
            $currentValue
            $prompt = Read-Host "Would you like to append? Y/n"
            

            if ($prompt -eq 'n') {
                #Overwrite the current value of Name
                $favoritesJson.Favorites | Add-Member -MemberType NoteProperty -Name $Name -Value $commaDelimitedComputers -Force

            } else {

                #Append the current value of Name with the new value
                $appendedComputers = $commaDelimitedComputers+','+($currentValue -join ",")

                #Turn the appended comptuers into an array by splitting commas
                #Once an array, delete duplicates and turn back into a comma-delmited string
                $uniqueComputers = ($appendedComputers.split(",") | Sort-Object -Unique) -join ","

                #Add the unique, appended string of computers the favoritesJson object
                $favoritesJson.favorites | Add-Member -MemberType NoteProperty -Name $Name -Value $uniqueComputers -Force

            }

        } else {
            #If value of Name parameter did not already exist in favorites, add the comma-delimited string to the favoritesJson object.
            $favoritesJson.favorites | Add-Member -MemberType NoteProperty -Name $Name -Value $commaDelimitedComputers

        }

        #Convert the favoritesJson object to a Json-formatted string, and send it to $env:APPDATA\Sessions\Favorites.json
        $favoritesJson | ConvertTo-Json | Out-File $favoritesPath -Force

        #Return the newly created favorite
        return $favoritesJson.favorites | select $Name  

    }
    
}
