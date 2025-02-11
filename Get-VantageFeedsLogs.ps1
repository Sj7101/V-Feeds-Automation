function Parse-LogFilesWithFilters {
    # Read config file
    $config = Get-Content -Path "$PSScriptRoot\config.json" | ConvertFrom-Json
    
    # Initialize a hashtable to store system data
    $systemsData = @{}

    # Iterate over each system defined in the config
    foreach ($systemName in $config.Systems.PSObject.Properties.Name) {
        $systemConfig = $config.Systems.$systemName
        $logFiles = $systemConfig.LogFiles
        $filteredData = @()

        # Iterate over each log file for the current system
        foreach ($logFileConfig in $logFiles) {
            $logFilePath = $logFileConfig.FilePath
            $logFileFilters = $logFileConfig.Filters

            # Check if the log file exists
            if (Test-Path $logFilePath) {
                Write-Host "Parsing log file: $logFilePath"

                # Read the log file line by line
                $logLines = Get-Content -Path $logFilePath

                # Parse each line in the log file and apply the specific filters
                foreach ($line in $logLines) {
                    Write-Host "Processing line: $line"  # Debugging the log line

                    # Only process lines that match the expected format
                    if ($line -match "(\d{4}-\d{2}-\d{2})\|([A-Za-z0-9-]+)\s+\|\s+(\d+)") {
                        $capturedValues = @{}
                        $matches = $line -match "(\d{4}-\d{2}-\d{2})\|([A-Za-z0-9-]+)\s+\|\s+(\d+)"
                        
                        if ($matches) {
                            # Only assign values if the capture group exists
                            if ($matches.Groups[1]) {
                                $capturedValues["Date"] = $matches.Groups[1].Value
                            } else {
                                Write-Host "No Date captured"
                            }

                            if ($matches.Groups[2]) {
                                $capturedValues["Exporter"] = $matches.Groups[2].Value
                            } else {
                                Write-Host "No Exporter captured"
                            }

                            if ($matches.Groups[3]) {
                                $capturedValues["Count"] = $matches.Groups[3].Value
                            } else {
                                Write-Host "No Count captured"
                            }

                            # Assuming ExportState as "Exported" for this log
                            $capturedValues["ExportState"] = "Exported"

                            # Only add to filtered data if all values are present
                            if ($capturedValues["Date"] -and $capturedValues["Exporter"] -and $capturedValues["Count"]) {
                                $filteredData += [PSCustomObject]@{
                                    "Date"        = $capturedValues["Date"]
                                    "Exporter"    = $capturedValues["Exporter"]
                                    "ExportState" = $capturedValues["ExportState"]
                                    "Count"       = $capturedValues["Count"]
                                }
                            }
                        }
                    }
                }
            } else {
                Write-Host "Log file not found: $logFilePath"
            }
        }

        # Store the filtered data for this system if any matches were found
        if ($filteredData.Count -gt 0) {
            $systemsData[$systemName] = $filteredData
        }
    }

    # Return the filtered data for all systems
    return $systemsData
}

# Example usage:
# The config.json is automatically loaded from the script's directory
$filteredResults = Parse-LogFilesWithFilters

# Display results
$filteredResults.Symphony
