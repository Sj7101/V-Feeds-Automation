# Define the output path for the JSON
$jsonOutputPath = "C:\path\to\output.json"

# Create PSCustomObjects for each system
$systems = @()

# Create data for each system
$systems += [PSCustomObject]@{
    SystemName = "VantageTeams"
    Checks = @(
        [PSCustomObject]@{
            Check1 = "Value1"
            Check2 = "Value2"
        }
    )
}

$systems += [PSCustomObject]@{
    SystemName = "VantageSystems"
    Checks = @(
        [PSCustomObject]@{
            Check1 = "Value3"
            Check2 = "Value4"
        }
    )
}

$systems += [PSCustomObject]@{
    SystemName = "ICE"
    Checks = @(
        [PSCustomObject]@{
            Check1 = "Value5"
            Check2 = "Value6"
        }
    )
}

$systems += [PSCustomObject]@{
    SystemName = "BB"
    Checks = @(
        [PSCustomObject]@{
            Check1 = "Value7"
            Check2 = "Value8"
        }
    )
}

# Continue adding other systems here following the same pattern

# Convert to JSON
$jsonData = [PSCustomObject]@{
    Systems = $systems
}

# Convert the object to JSON format
$jsonData | ConvertTo-Json -Depth 3 | Out-File $jsonOutputPath

# Optionally, print the result to the console for review
$jsonData | ConvertTo-Json -Depth 3
