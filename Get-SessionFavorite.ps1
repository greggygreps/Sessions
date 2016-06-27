function Get-SessionFavorite {
    <#
    .Synopsis
        A function to retrieve the Favorites created from the Set-SessionFavorite function.
    .Description
        The Get-SessionFavorite will return the list of favorites stored in the $env:APPDATA\Sessions\Favorites.json file.
        The dynamic parameter Name will validate the set of possible values. If no parameter is given, all favorites will be returned.
    .Inputs
        None. You cannot pipe objects to Get-SessionFavorite.
    .Outputs
        System.Object. Get-SessionFavorite returns the name of the favorite specified along with the computers stored in that name.
        If no Name is specified, all favorites are returned.
    .Parameter Name
        An optional dynamic parameter which set is validated on items stored in $env:APPDATA\Sessions\Favorites.json.
    .Example
        PS C:\>Get-SessionFavorite
            This example does not specify the name of any favorites and returns all favorites in a comma-delimited list.
    .Example
        PS C:\>Get-SessionFavorite -Name PiedPiper
            This example specifies a name of an existing favorite and returns the computernames as an array.
    .Notes
        Author   : Gregory Alfano
        Last Edit: 06-24-2016
        Version  : 1.0
    #>

     [CmdletBinding()]
     Param(

     )

    dynamicParam {

        #Set the dynamic parameter's name
        $computersParameterName = 'Name'
        
        #Create the dictionary
        $runtimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        #Create the collection of attributes
        $computersAttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        
        #Create and set the parameters' attributes
        $computersParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $computersParameterAttribute.Mandatory = $False
        $computersParameterAttribute.Position = 0
        
        #Add the attributes to the attributes collection
        $computersAttributeCollection.Add($computersParameterAttribute)
        
        #Generate and set the ValidateSet
        $favoritesPath = ($env:APPDATA)+'\Sessions\Favorites.json'
        if (!(Test-Path $favoritesPath)) {
        
            throw "$favoritesPath does not exist. Please create a favorite using the Set-SessionFavorite function."
        
        }
        $favoritesJson = Get-Content $favoritesPath -raw | ConvertFrom-Json
        $computersNames = $favoritesJson.favorites | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
        $computersValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($computersNames)
        
        #Add the ValidateSet to the attributes collection
        $computersAttributeCollection.Add($computersValidateSetAttribute)
        
        #Create and return the dynamic parameter
        $computersRuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($computersParameterName, [string],$computersAttributeCollection)
        $runtimeParameterDictionary.Add($computersParameterName, $computersRuntimeParameter)
        
        return $runtimeParameterDictionary
    }

    begin {

        #Bind the parameter to the Name variable
        $Name = $PsBoundParameters[$computersParameterName]

    }

    process {

        #If a Name is specified, return that specific favorite. Else, return all favorites.
        if($Name) {

            $arrayObject = @()

            $favoritesArray = ($favoritesJson.favorites | Select -ExpandProperty $Name) -split ","

            foreach ($favorite in $favoritesArray) {

                $object = New-Object System.Object

                $object | Add-Member -MemberType NoteProperty -Name $Name -Value $favorite

                $arrayObject += $object
            }

            return $arrayObject | Sort-Object $Name

        } else {

            return $favoritesJson.favorites

        }   
        
    }

}
