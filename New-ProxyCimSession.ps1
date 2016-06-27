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
