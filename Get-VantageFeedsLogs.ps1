function Parse-LogFilesWithFilters {
    param (
        [string]$configFilePath  # Path to the config.json file
    )
    
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
                    $lineData = [PSCustomObject]@{
                        "System" = $systemName
                        "LogFile" = $logFilePath
                        "Message" = $line
                    }
                    
                    $matchesAllFilters = $true
                    $capturedValues = @{}

                    # Check if the line matches all filters for the current log file
                    foreach ($filter in $logFileFilters) {
                        $fieldValue = $lineData.$($filter.Field)

                        # If Regex matching is enabled
                        if ($filter.Regex) {
                            $matches = $fieldValue -match $filter.Pattern

                            if ($matches) {
                                # If a match is found, capture the specified capture group value
                                $capturedValue = $matches.Groups[$filter.CaptureGroup].Value
                                $capturedValues[$filter.Keyword] = $capturedValue
                            } else {
                                $matchesAllFilters = $false
                                break
                            }
                        } else {
                            # Keyword matching (non-regex)
                            if ($fieldValue -notcontains $filter.Keyword) {
                                $matchesAllFilters = $false
                                break
                            }
                        }
                    }

                    # If all filters match, add to the system's filtered data
                    if ($matchesAllFilters) {
                        # Add captured values to the PSCustomObject
                        $lineData | Add-Member -MemberType NoteProperty -Name "CapturedValues" -Value $capturedValues
                        $filteredData += $lineData
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
# Parse logs with filters defined in config.json
$configFilePath = "C:\path\to\config.json"
$filteredResults = Parse-LogFilesWithFilters -configFilePath $configFilePath

# Display results
$filteredResults
