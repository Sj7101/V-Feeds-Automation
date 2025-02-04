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


<#[][][][][]#>
# Function to send JSON data (from file or variable) to SQL Server, parsing by system name
function Send-JsonToSqlBySystem {
    param (
        [Parameter(Mandatory=$true)]
        [string]$jsonInput,  # Can be file path or JSON string/variable
        [string]$sqlServer,     # SQL Server name or IP address
        [string]$databaseName,  # Database name
        [string]$username,      # SQL Server username (if required)
        [string]$password       # SQL Server password (if required)
    )

    # Check if the input is a file path or JSON string/variable
    if (Test-Path $jsonInput) {
        # Read JSON from the file
        $jsonContent = Get-Content -Path $jsonInput -Raw
    } else {
        # Treat as a direct JSON string/variable
        $jsonContent = $jsonInput
    }

    # Parse the JSON content
    $jsonData = $jsonContent | ConvertFrom-Json

    # Connection string for SQL Server
    $connectionString = "Server=$sqlServer;Database=$databaseName;Integrated Security=True;"

    # If using SQL Server Authentication
    if ($username -and $password) {
        $connectionString = "Server=$sqlServer;Database=$databaseName;User Id=$username;Password=$password;"
    }

    # Create SQL connection
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    # Iterate over each system in the JSON data
    foreach ($systemName in $jsonData.Systems.PSObject.Properties.Name) {
        $tableName = $systemName
        $systemData = $jsonData.Systems.$systemName

        # Ensure the system's table exists in the database
        $createTableQuery = @"
        IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$tableName')
        BEGIN
            CREATE TABLE $tableName (
                Id INT IDENTITY(1,1) PRIMARY KEY,
                Check1 NVARCHAR(MAX),
                Check2 NVARCHAR(MAX),
                CreatedAt DATETIME DEFAULT GETDATE()
            )
        END
"@

        # Create the table if it does not exist
        $command = $connection.CreateCommand()
        $command.CommandText = $createTableQuery
        $command.ExecuteNonQuery()

        # Insert data into the system's table
        foreach ($entry in $systemData) {
            $check1 = $entry.Check1
            $check2 = $entry.Check2

            # Insert query for the system's table
            $insertQuery = @"
            INSERT INTO $tableName (Check1, Check2)
            VALUES (@Check1, @Check2)
"@

            # Prepare the SQL command for insertion
            $command = $connection.CreateCommand()
            $command.CommandText = $insertQuery
            $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Check1", [Data.SqlDbType]::NVarChar, -1))).Value = $check1
            $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Check2", [Data.SqlDbType]::NVarChar, -1))).Value = $check2

            # Execute the insert query
            try {
                $command.ExecuteNonQuery()
                Write-Host "Data successfully inserted into $tableName."
            } catch {
                Write-Error "An error occurred while inserting data into $tableName: $_"
            }
        }
    }

    # Close the SQL connection
    $connection.Close()
}

# Example usage:
# Case 1: Pass JSON file path
Send-JsonToSqlBySystem -jsonInput "C:\path\to\output.json" -sqlServer "localhost" -databaseName "YourDatabase" -username "sa" -password "your_password"

# Case 2: Pass JSON string/variable
$jsonData = '{
  "Systems": {
    "GreenTeams": [
      {"Check1": "Value1", "Check2": "Value2"}
    ],
    "BlueSystems": [
      {"Check1": "Value3", "Check2": "Value4"}
    ]
  }
}'
Send-JsonToSqlBySystem -jsonInput $jsonData -sqlServer "localhost" -databaseName "YourDatabase" -username "sa" -password "your_password"



<#

CREATE TABLE JsonData (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    JsonContent NVARCHAR(MAX),
    CreatedAt DATETIME DEFAULT GETDATE()
);


#>