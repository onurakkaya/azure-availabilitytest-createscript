# The MIT License (MIT)
# Copyright © 2020 Onur Akkaya

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), 
# to deal in the Software without restriction,  including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# data json file  (ping name,url,expected status code)
$data = Get-Content -Raw -Path "data.json" | ConvertFrom-Json

# azure template file for creating availability test.
$templateFile = "availabilityalert.json" 

# azure template file -> parameter File
$paramFile = Get-Content -Raw -Path "availabilityalert.parameters.json" | ConvertFrom-Json

$azureTenantId = "<AZURE-TENANT-ID>";
$azureSubscriptionId = "<AZURE-SUBSCRIPTION-ID>";

$appInsightsName = "<APPLICATON-INSIGHTS-NAME>";
$appInsightsResourceGroup = "<APP-INSIGHTS-HOLDER(RESOURCE-GROUP)>";

$appInsightsActionGroupResourceGroup = "<ACTION-GROUP-HOLDER(RESOURCE-GROUP)>";
$appInsightsActionGroupName = "<ACTION-GROUP-NAME>";

# This location must be match with your AppInsights location.
# In example; $location =  "WestEurope" / $location = "NorthEurope" / etc...
$location = "<APP-INSIGHTS-RESOURCE-LOCATION>"   

# Action Group Full Path 
$actionGroupId = "/subscriptions/"+ $azureSubscriptionId +"/resourceGroups/"+ $appInsightsActionGroupResourceGroup +"/providers/microsoft.insights/actiongroups/" + $appInsightsActionGroupName

# Temp parameter file full path (relative path with name)
$tmpParamFile = "temp-params.json"

# For use this command install "Az" module if isn't installed.
# You can install az module with typing "Install-Module az" command on PowerShell (P.S. you need to run PowerShell as Administrator)
Connect-AzAccount -Tenant $azureTenantId -Subscription $azureSubscriptionId

#Iterate all items in "data" json file and say item to each itemm.
foreach ($item in $data)
{
     # if status code is not 200  skip this iteration
     if ($item.'Expected Status Code' -ne 200)
     {
        Write-Host "Hop" $item.Name ->  $item.'Expected Status Code'
        continue;
     }
     else
     {
        # Assign values to parameters.json file.
        $paramFile.parameters.appName.value = $appInsightsName;
        $paramFile.parameters.pingURL.value = $item.Url;
        $paramFile.parameters.actionGroupId.value = $actionGroupId;
        $paramFile.parameters.location.value = $location;
        $paramFile.parameters.alertName.value = $item.Name;
        
        # Save modified parameter file to disk as temp.
        $paramFile | ConvertTo-Json | Out-File $tmpParamFile

        # Write content of parameter file to console.
        $paramFile | ConvertTo-Json

        # Deploy Availability Test with template & parameter file.
        New-AzResourceGroupDeployment -Name AvailabilityAlertDeployment -ResourceGroupName $appInsightsResourceGroup -TemplateFile $templateFile -TemplateParameterFile $tmpParamFile

        # Delete temp file.
        Remove-Item $tmpParamFile
        
        # Write "Done" message for iterated record.
        Write-Host $item.Name  -> "Done"
     }
}
