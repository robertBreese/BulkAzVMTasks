
# BulkAzVMTasks
This is a PowerShell script designed to perform bulk operations on Azure Virtual Machines (VMs) across multiple subscriptions and resource groups. This script automates the execution of a specified PowerShell script on all running VMs within the defined resource groups and subscriptions.

I originally created this script to find which VM's a vulnerable piece of software was install on.

**This script does not support Linux VMs**

## **How It Works**

**CSV Input:** The script reads input from a CSV file where the headers are subscription IDs, and the rows contain the names of resource groups. Each cell in the CSV specifies which resource groups belong to which subscription.

**Authentication:** It authenticates to Azure using the provided tenant ID and switches contexts for each subscription specified in the CSV.

**Resource Group Processing:** For each subscription, the script processes all specified resource groups, identifying all running VMs.

**VM Command Execution:** It executes a predefined PowerShell script  on each running VM, capturing the output. This is done using Invoke-AzVMRunCommand as part of Az.Compute. 

**Results Logging:** The results of the script execution, including VM names and output messages, are saved to an output CSV file.

## Usage

 - Prepare a CSV file with subscription IDs as headers and resource
   groups as rows. These are the RG's with VM's you want this script to be ran on. You can export all resource groups in a subscription via Powershell or the Azure Portal.
   
 - Run the script with the appropriate parameters for the output CSV
   path, tenant ID, and input CSV path.

## Example Command

    .\BulkAzVMTasks.ps1 -OutputCsvPath 'C:\path\to\your\VMRunCommandResults.csv' -TenantId 'your-tenant-id' -InputCsvPath 'C:\path\to\your\input.csv'

## Dependencies

 - **Azure PowerShell Module:** The script requires the Az module for
   managing Azure resources (Install-Module -Name Az.Compute
   -AllowClobber).
   
 - **PowerShell Script to Execute:** The script you would like to execute on
   VM's should be available in the same directory or provide the correct
   path.
