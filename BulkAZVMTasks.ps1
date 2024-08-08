param (
    [string]$OutputCsvPath = 'VMRunCommandResults.csv',
    [string]$TenantId,
    [string]$InputCsvPath
)

# Import the Az module
Import-Module Az.Compute

# Initialize an array to hold the results
$results = @()

# Define the path to your script
$scriptPath = '.\script.ps1'

# Read the CSV file
$csvData = Import-Csv -Path $InputCsvPath

# Process each subscription and its resource groups from the CSV
$subscriptions = @{}
foreach ($row in $csvData) {
    foreach ($column in $row.PSObject.Properties) {
        $subscriptionId = $column.Name
        $resourceGroup = $column.Value
        if ($resourceGroup) {
            if (-not $subscriptions[$subscriptionId]) {
                $subscriptions[$subscriptionId] = @()
            }
            $subscriptions[$subscriptionId] += $resourceGroup
        }
    }
}

# Loop through each subscription and its resource groups
foreach ($subscription in $subscriptions.GetEnumerator()) {
    $subscriptionId = $subscription.Key
    $resourceGroups = $subscription.Value
    
    # Authenticate to Azure and set the context for the current subscription
    Connect-AzAccount -TenantId $TenantId -SubscriptionId $subscriptionId
    Set-AzContext -SubscriptionId $subscriptionId -TenantId $TenantId
    Write-Output "Processing subscription: $subscriptionId in tenant: $TenantId"

    # Loop through each resource group in the current subscription
    foreach ($resourceGroup in $resourceGroups) {
        Write-Output "Processing resource group: $resourceGroup"
        
        # Get all VMs in the current resource group
        $vms = Get-AzVM -ResourceGroupName $resourceGroup
        
        if ($vms) {
            Write-Output "Found $($vms.Count) VMs in resource group: $resourceGroup"
            
            # Loop through each VM
            foreach ($vm in $vms) {
                # Get the status of the current VM
                $vmStatus = Get-AzVM -ResourceGroupName $resourceGroup -Name $vm.Name -Status

                # Check if the VM is running
                $powerState = $vmStatus.Statuses | Where-Object { $_.Code -eq 'PowerState/running' }
                if ($powerState) {
                    Write-Output "Running command on VM: $($vm.Name)"
                    
                    # Run the command on the current VM
                    $result = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -Name $vm.Name -CommandId 'RunPowerShellScript' -ScriptPath $scriptPath

                    # Extract the necessary information
                    $vmName = $vm.Name
                    $message = ($result.Value | Where-Object { $_.DisplayStatus -eq 'Provisioning succeeded' } | Select-Object -ExpandProperty Message) -join "`n"

                    # Add the result to the array
                    $results += [PSCustomObject]@{
                        Name    = $vmName
                        Output  = $message
                    }
                }
                else {
                    Write-Output "VM $($vm.Name) is not running. Skipping."
                }
            }
        }
        else {
            Write-Output "No VMs found in resource group: $resourceGroup"
        }
    }
}

if ($results.Count -gt 0) {
    # Export the results to a CSV file
    $results | Export-Csv -Path $OutputCsvPath -NoTypeInformation
    Write-Output "Script execution completed. Results are saved in $OutputCsvPath."
}
else {
    Write-Output "No results to save. No VMs were processed."
}
