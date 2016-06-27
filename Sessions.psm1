function New-ProxyPSSession {
    <#
    .Synopsis
        A proxy function for the New-PSSession cmdlet with added functionality.
        To view the help of the original New-PSSession cmdlet, see http://go.microsoft.com/fwlink/?LinkID=135237.
    .Inputs
        System.String, System.URI, System.Management.Automation.Runspaces.PSSession
        You can pipe a string, URI, or session object to this cmdlet.
    .Outputs
        System.Management.Automation.Runspaces.PSSession
    .Parameter Favorite
        An optional dynamic parameter which set is validated on items stored in $env:APPDATA\Sessions\Favorites.json.
    .Parameter SearchBase
        An optional dynamic parameter which set is validated on the results of the following cmdlet:
        Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
    .Example
        PS C:\>New-ProxyPSSession -SearchBase Hooli
            This example uses the dynamic parameter SearchBase to validate the set of possible search bases to look up computers from.
            The validated set is retrieved from the following command: Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
    .Example
        PS C:\>New-ProxyPSSession -Favorite PiedPiper
            This example uses the dynamic parameter Favorite to validate the name of favorites stored in $env:APPDATA\Sessions\Favorites.json created by the Set-SessionFavorite function.
    .Link
        http://go.microsoft.com/fwlink/?LinkID=135237
    .Notes
        Author   : Gregory Alfano
        Last Edit: 06-24-2016
        Version  : 1.0
    #>
    [CmdletBinding(DefaultParameterSetName='ComputerName', HelpUri='http://go.microsoft.com/fwlink/?LinkID=135237', RemotingCapability='OwnedByCommand')]
    param(
        [Parameter(ParameterSetName='ComputerName', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Cn')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ComputerName},

        [Parameter(ParameterSetName='ComputerName', ValueFromPipelineByPropertyName=$true)]
        [Parameter(ParameterSetName='Uri', ValueFromPipelineByPropertyName=$true)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName='Session', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession[]]
        ${Session},

        [string[]]
        ${Name},

        [switch]
        ${EnableNetworkAccess},

        [Parameter(ParameterSetName='ComputerName')]
        [ValidateRange(1, 65535)]
        [int]
        ${Port},

        [Parameter(ParameterSetName='ComputerName')]
        [switch]
        ${UseSSL},

        [Parameter(ParameterSetName='ComputerName', ValueFromPipelineByPropertyName=$true)]
        [Parameter(ParameterSetName='Uri', ValueFromPipelineByPropertyName=$true)]
        [string]
        ${ConfigurationName},

        [Parameter(ParameterSetName='ComputerName', ValueFromPipelineByPropertyName=$true)]
        [string]
        ${ApplicationName},

        [Parameter(ParameterSetName='Session')]
        [Parameter(ParameterSetName='Uri')]
        [Parameter(ParameterSetName='ComputerName')]
        [int]
        ${ThrottleLimit},

        [Parameter(ParameterSetName='Uri', Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [Alias('URI','CU')]
        [ValidateNotNullOrEmpty()]
        [uri[]]
        ${ConnectionUri},

        [Parameter(ParameterSetName='Uri')]
        [switch]
        ${AllowRedirection},

        [Parameter(ParameterSetName='Uri')]
        [Parameter(ParameterSetName='ComputerName')]
        [ValidateNotNull()]
        [System.Management.Automation.Remoting.PSSessionOption]
        ${SessionOption},

        [Parameter(ParameterSetName='ComputerName')]
        [Parameter(ParameterSetName='Uri')]
        [System.Management.Automation.Runspaces.AuthenticationMechanism]
        ${Authentication},

        [Parameter(ParameterSetName='Uri')]
        [Parameter(ParameterSetName='ComputerName')]
        [string]
        ${CertificateThumbprint})

    dynamicParam {

        #Create the dictionary
        $runtimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        #Set the dynamic parameter's name
        $searchBasesParameterName = 'SearchBase'
        #Create the collection of attributes
        $searchBasesAttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        #Create and set the parameters' attributes
        $searchBasesParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $searchBasesParameterAttribute.Mandatory = $True
        $searchBasesParameterAttribute.ParameterSetName = 'SearchBase'
        #Add the attributes to the attributes collection
        $searchBasesAttributeCollection.Add($searchBasesParameterAttribute)
        #Generate and set the ValidateSet
        $searchBasesNames = Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
        $searchBasesValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($searchBasesNames)
        #Add the ValidateSet to the attributes collection
        $searchBasesAttributeCollection.Add($searchBasesValidateSetAttribute)
        $searchBasesRuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($searchBasesParameterName, [string],$searchBasesAttributeCollection)
        
        #Set the dynamic parameter's name
        $computersParameterName = 'Favorite'
        #Create the collection of attributes          
        $computersAttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]            
        #Create and set the parameters' attributes
        $computersParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $computersParameterAttribute.Mandatory = $True
        $computersParameterAttribute.ParameterSetName = 'Favorite'
        #Add the attributes to the attributes collection
        $computersAttributeCollection.Add($computersParameterAttribute)
        #Generate and set the ValidateSet
        $favoritesPath = ($env:APPDATA)+'\Sessions\Favorites.json'
        $favoritesJson = Get-Content $favoritesPath -raw | ConvertFrom-Json
        $computersNames = $favoritesJson.favorites | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
        $computersValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($computersNames)
        #Add the ValidateSet to the attributes collection
        $computersAttributeCollection.Add($computersValidateSetAttribute)
        $computersRuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($computersParameterName, [string],$computersAttributeCollection)
        
        #Create and return the dynamic parameter
        $runtimeParameterDictionary.Add($searchBasesParameterName, $searchBasesRuntimeParameter) 
        $runtimeParameterDictionary.Add($computersParameterName, $computersRuntimeParameter)
        
        return $runtimeParameterDictionary
    }


    begin {

        $SearchBase = $PsBoundParameters[$searchbasesParameterName]
        $Favorite = $PsBoundParameters[$computersParameterName]
        try {

            $outBuffer = $null

            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {

                $PSBoundParameters['OutBuffer'] = 1

            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Core\New-PSSession', [System.Management.Automation.CommandTypes]::Cmdlet)

            if($PSBoundParameters['Favorite']) {

                $null = $PSBoundParameters.Remove('Favorite')

                $ComputerName = Get-GASessionFavorites -Name $Favorite | Select -ExpandProperty $Favorite
                
                $PsBoundParameters.Add('ComputerName',$ComputerName)

            }
            
            if($PSBoundParameters['SearchBase']) {

                $null = $PSBoundParameters.Remove('SearchBase')
                $distinguishedName = Get-ADOrganizationalUnit -LDAPFilter "(name=$searchbase)" | select -ExpandProperty distinguishedname
                $computerLookup = Get-ADComputer -SearchBase $distinguishedName -Filter * | Select DnsHostName, DistinguishedName, Enabled, SID | Sort-Object DnsHostName
                $ComputerName = $computerLookup | Out-Gridview -PassThru | Select -ExpandProperty dnshostname

                $scriptCmd = {& $wrappedCmd $ComputerName @PSBoundParameters }

            } else {

                $scriptCmd = {& $wrappedCmd @PSBoundParameters }

            }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)

        } catch {

            throw
        }
    }

    process {

        try {

            $steppablePipeline.Process($_)

        } catch {

            throw

        }
    }

    end {

        try {

            $steppablePipeline.End()

        } catch {

            throw

        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Core\New-PSSession
    .ForwardHelpCategory Cmdlet

    #>

}

function New-ProxyCimSession {
    <#
    .Synopsis
        A proxy function for the New-CimSession cmdlet with added functionality.
        To view the help of the original New-CimSession cmdlet, see http://go.microsoft.com/fwlink/?LinkId=227967
    .Inputs
        This function does not accept objects from the pipeline.
    .Outputs
        Microsoft.Management.Infrastructure.CimSession
    .Parameter Favorite
        An optional dynamic parameter which set is validated on items stored in $env:APPDATA\Sessions\Favorites.json.
    .Parameter SearchBase
        An optional dynamic parameter which set is validated on the results of the following cmdlet:
        Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
    .Example
        PS C:\>New-ProxyCimSession -SearchBase Hooli
            This example uses the dynamic parameter SearchBase to validate the set of possible search bases to look up computers from.
            The validated set is retrieved from the following command: Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
    .Example
        PS C:\>New-ProxyCimSession -Favorite PiedPiper
            This example uses the dynamic parameter Favorite to validate the name of favorites stored in $env:APPDATA\Sessions\Favorites.json created by the Set-SessionFavorite function.
    .Link
        http://go.microsoft.com/fwlink/?LinkId=227967
    .Notes
        Author   : Gregory Alfano
        Last Edit: 06-24-2016
        Version  : 1.0
    #>
    [CmdletBinding(DefaultParameterSetName='CredentialParameterSet',HelpUri='http://go.microsoft.com/fwlink/?LinkId=227967', RemotingCapability='SupportedByCommand')]
    param(
        [Parameter(Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, ParameterSetName='CredentialParameterSet')]
        [Alias('CN','ServerName','DNSHostName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        ${ComputerName},

        [Parameter(ParameterSetName='CredentialParameterSet')]
        [Microsoft.Management.Infrastructure.Options.PasswordAuthenticationMechanism]
        ${Authentication},

        [Parameter(ParameterSetName='CredentialParameterSet', Position=1)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [Parameter(ParameterSetName='CertificateParameterSet')]
        [string]
        ${CertificateThumbprint},

        [Parameter()]
        [string]
        ${Name},

        [Parameter()]
        [Alias('OT')]
        [uint32]
        ${OperationTimeoutSec},

        [Parameter()]
        [switch]
        ${SkipTestConnection},

        [Parameter()]
        [uint32]
        ${Port},

        [Parameter()]
        [Microsoft.Management.Infrastructure.Options.CimSessionOptions]
        ${SessionOption})

    dynamicParam {

        #Create the dictionary
        $runtimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        #Set the dynamic parameter's name
        $searchBasesParameterName = 'SearchBase'
        #Create the collection of attributes
        $searchBasesAttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        #Create and set the parameters' attributes
        $searchBasesParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $searchBasesParameterAttribute.Mandatory = $True
        $searchBasesParameterAttribute.ParameterSetName = 'SearchBase'
        #Add the attributes to the attributes collection
        $searchBasesAttributeCollection.Add($searchBasesParameterAttribute)
        #Generate and set the ValidateSet
        $searchBasesNames = Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchScope OneLevel | select -expand name
        $searchBasesValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($searchBasesNames)
        #Add the ValidateSet to the attributes collection
        $searchBasesAttributeCollection.Add($searchBasesValidateSetAttribute)
        $searchBasesRuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($searchBasesParameterName, [string],$searchBasesAttributeCollection)
        
        #Set the dynamic parameter's name
        $computersParameterName = 'Favorite'
        #Create the collection of attributes          
        $computersAttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]            
        #Create and set the parameters' attributes
        $computersParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $computersParameterAttribute.Mandatory = $True
        $computersParameterAttribute.ParameterSetName = 'Favorite'
        #Add the attributes to the attributes collection
        $computersAttributeCollection.Add($computersParameterAttribute)
        #Generate and set the ValidateSet
        $favoritesPath = ($env:APPDATA)+'\Sessions\Favorites.json'
        $favoritesJson = Get-Content $favoritesPath -raw | ConvertFrom-Json
        $computersNames = $favoritesJson.favorites | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
        $computersValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($computersNames)
        #Add the ValidateSet to the attributes collection
        $computersAttributeCollection.Add($computersValidateSetAttribute)
        $computersRuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($computersParameterName, [string],$computersAttributeCollection)
        
        #Create and return the dynamic parameter
        $runtimeParameterDictionary.Add($searchBasesParameterName, $searchBasesRuntimeParameter) 
        $runtimeParameterDictionary.Add($computersParameterName, $computersRuntimeParameter)
        
        return $runtimeParameterDictionary
    }

    begin {

        $SearchBase = $PsBoundParameters[$searchbasesParameterName]
        $Favorite = $PsBoundParameters[$computersParameterName]

        try {

            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))  {

                $PSBoundParameters['OutBuffer'] = 1

            }
            
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('CimCmdlets\New-CimSession', [System.Management.Automation.CommandTypes]::Cmdlet)
            
            if($PSBoundParameters['Favorite']) {

                $null = $PSBoundParameters.Remove('Favorite')

                $ComputerName = Get-SessionFavorite -Name $Favorite | Select -ExpandProperty $Favorite
                
                $PsBoundParameters.Add('ComputerName',$ComputerName)

            }
            
            if($PSBoundParameters['SearchBase']) {

                $null = $PSBoundParameters.Remove('SearchBase')
                $distinguishedName = Get-ADOrganizationalUnit -LDAPFilter "(name=$searchbase)" | select -ExpandProperty distinguishedname
                $computerLookup = Get-ADComputer -SearchBase $distinguishedName -Filter * | Select DnsHostName, DistinguishedName, Enabled, SID | Sort-Object DnsHostName
                $ComputerName = $computerLookup | Out-Gridview -PassThru | Select -ExpandProperty dnshostname

                $scriptCmd = {& $wrappedCmd $ComputerName @PSBoundParameters }

            } else {

                $scriptCmd = {& $wrappedCmd @PSBoundParameters }

            }        

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)

        } catch {

            throw
            
        }
    }

    process {

        try {

            $steppablePipeline.Process($_)

        } catch {
            
            throw
        }
    }

    end {

        try {

            $steppablePipeline.End()

        } catch {

            throw

        }
    }
    <#

    .ForwardHelpTargetName CimCmdlets\New-CimSession
    .ForwardHelpCategory Cmdlet

    #>

}

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

New-Alias -Name npsn -Value New-ProxyPSSession -Description "Alias for New-ProxyPSSession"
New-Alias -Name npcms -Value New-ProxyCimSession -Description "Alias for New-ProxyCimSession"
New-Alias -Name gsf -Value Get-SessionFavorite -Description "Alias for Get-SessionFavorite"
New-Alias -Name ssf -Value Set-SessionFavorite -Description "Alias for Set-SessionFavorite"