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
