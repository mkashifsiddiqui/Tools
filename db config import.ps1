#################################################### 
# 
# PowerShell CSV to SQL Import Script 
# 
#################################################### 
 
# Database variables 
param
(
	[String] $applicationConfigurationFilePath = "",
	[String] $sqlserver = "",
	[String] $database = "VidizmoDB_6_0",	
	[String] $user = "",
	[String] $password = "",
    [boolean] $forceImport = $false
)


# CSV variables 
$csvdelimiter = "," 
$FirstRowColumnNames = $true 
$Table = "ApplicationConfiguration"

#$applicationConfigurationFilePath  = "C:\TFS\VIDIZMODatabase\src\CommonResource\ApplicationConfiguration-beta.us.vidizmo.com.csv"
#$sqlserver ="sdfdsfds"
#$database = "VidizmoDB_6_0"
#$user = "dsfdsfd"
#$password = "sdfsdfsdf"

# check if the version of database is 5.x.x, if so import string resources, otherwise not.


################### No need to modify anything below ################### 
Write-Host "Script started..." 

# if config file is not found or is empty then don't process any further
$configFileFound = Test-Path -Path $applicationConfigurationFilePath -PathType Leaf

if ($configFileFound -eq $false) {
    
    Write-Host "$applicationConfigurationFilePath file not found"

    exit(1)
}


if ((Import-Csv $applicationConfigurationFilePath).Count -le 0) {
    
    Write-Host "$applicationConfigurationFilePath file is empty"

    exit(1)
}


$ApplicationVersion = 0;
$DatabaseVersion = 0;
$NotificationDatabaseVersion = 0;

function Truncate-ApplicationConfiguration($connectionstring) {

    # Deleting pre-existing string resources
    Write-Host "Deleting existing String Resources...."

    $Conn = New-Object System.Data.SQLClient.SQLConnection $connectionstring;
    $Conn.Open();
    $DataCmd = New-Object System.Data.SqlClient.SqlCommand;
    $DataCmd.Connection = $Conn;

    $DataCmd.CommandText = " truncate Table $Table ";
    $DAadapter = New-Object System.Data.SqlClient.SqlDataAdapter;
    $DAadapter.InsertCommand = $DataCmd;
    $DataCmd.ExecuteNonQuery();

    $Conn.Close();
    $Conn.Dispose();

}

function Read-Versions($connectionstring) {
    
    $Conn = New-Object System.Data.SQLClient.SQLConnection $connectionstring;
    $Conn.Open();
    $DataCmd = New-Object System.Data.SqlClient.SqlCommand;
    $DataCmd.Connection = $Conn;


    $DataCmd.CommandText = "select * from ApplicationConfiguration where [Key] in ('ApplicationVersion','DatabaseVersion','NotificationDatabaseVersion')";
    $Reader = $DataCmd.ExecuteReader();
        
    $Versions = [PSCustomObject]@{
        ApplicationVersion = '0'
        DatabaseVersion = '0'
        NotificationDatabaseVersion = '0'
    }
    
    #$Reader.Read();
    while($Reader.Read())
    {
        $keyName = $Reader["Key"]
        $keyValue = $Reader["Value"]

        if ($keyName -eq 'ApplicationVersion') {
        
            $Versions.ApplicationVersion = $keyValue
        }

        if ($keyName -eq 'DatabaseVersion') {
        
            $Versions.DatabaseVersion = $keyValue
        }

        if ($keyName -eq 'NotificationDatabaseVersion') {
        
            $Versions.NotificationDatabaseVersion = $keyValue
        }

        #$Versions = $Versions + $Reader.GetValue($1) + ",";
    }

    $Reader.Close();
    $Reader.Dispose();

    $DataCmd.Dispose();    

    $Conn.Close();
    $Conn.Dispose();

    return $Versions
}

function Insert-Versions($connectionstring, $ApplicationVersion, $DatabaseVersion, $NotificationDatabaseVersion)
{
    #In the end store application and databse verions
    $Conn=New-Object System.Data.SQLClient.SQLConnection $connectionstring;
    $Conn.Open();
    $DataCmd = New-Object System.Data.SqlClient.SqlCommand;
    $DataCmd.Connection = $Conn;

    if($ApplicationVersion -ne $null -and $ApplicationVersion -ne 0)
    {    
        $DataCmd.CommandText = "Insert into ApplicationConfiguration (Id,[Key],[Value],[Description],ConfigurationGroup,DataType) values (1001,'ApplicationVersion','$($ApplicationVersion)','Version number of Application','General','String')";
        $DataCmd.ExecuteNonQuery();
    }

    if($DatabaseVersion -ne $null -and $DatabaseVersion -ne 0)
    {
    
        $DataCmd.CommandText = "Insert into ApplicationConfiguration (Id,[Key],[Value],[Description],ConfigurationGroup,DataType) values (1002,'DatabaseVersion','$($DatabaseVersion)','Version number of database','General','String')";
        $DataCmd.ExecuteNonQuery();
    }

    if($NotificationDatabaseVersion -ne $null -and $NotificationDatabaseVersion -ne 0)
    {
        $DataCmd.CommandText = "Insert into ApplicationConfiguration (Id,[Key],[Value],[Description],ConfigurationGroup,DataType) values (1003,'NotificationDatabaseVersion','$($NotificationDatabaseVersion)','Version number of database','General','String')";
        $DataCmd.ExecuteNonQuery();
    }

    $Conn.Close();
    $Conn.Dispose();
}


# checks if ApplicationConfiguration Key with its value exists 
# in the database or not. If Key-Value matches, returns 'Yes'
# If Key found but value not matches, then returns 'Value_Mismatch'
# If key is not found then returns 'No'
function ApplicationConfiguration-Exists ($DataCmd, $AppConfigKey, $AppConfigValue) {

    $keyExists = 'No'
    
    $DataCmd.CommandText = "select * from ApplicationConfiguration where [Key] = '$AppConfigKey'";
    $Reader = $DataCmd.ExecuteReader();
        
    while($Reader.Read())
    {
        $keyName = $Reader["Key"]
        $keyValue = $Reader["Value"]

        $keyExists = 'Yes'

        if ($keyValue -ne $AppConfigValue) {
        
            $keyExists = 'Value_Mismatch'
        }
    }

    $Reader.Close();
    $Reader.Dispose();
       

    return $keyExists
}


$elapsed = [System.Diagnostics.Stopwatch]::StartNew()  
[void][Reflection.Assembly]::LoadWithPartialName("System.Data") 
[void][Reflection.Assembly]::LoadWithPartialName("System.Data.SqlClient") 
  
  
# Build the sqlbulkcopy connection, and set the timeout to infinite 
$connectionstring = "Data Source=$sqlserver;Initial Catalog=$database;User ID=$user;Password=$password" 


if ($forceImport -eq $true) {

    $Versions = Read-Versions $connectionstring

    $ApplicationVersion = $Versions.ApplicationVersion;
    $DatabaseVersion = $Versions.DatabaseVersion;
    $NotificationDatabaseVersion = $Versions.NotificationDatabaseVersion;

    Truncate-ApplicationConfiguration $connectionstring
}

$log = "##[error] Exception in $csvfile in following record..."
$recordsWithError = New-Object System.Collections.ArrayList
$errorsEncountered = New-Object System.Collections.ArrayList

$counter = 0

# set up connection string and open connection
$Conn=New-Object System.Data.SQLClient.SQLConnection $connectionstring;
$Conn.Open();
$DataCmd = New-Object System.Data.SqlClient.SqlCommand;
$DataCmd.Connection = $Conn;

Import-CSV $applicationConfigurationFilePath | ForEach-Object {

    $counter++        

    $_.Id = $counter

    $record = $_;
    
 try
    {
        
        $AppConfigMatch = ApplicationConfiguration-Exists $DataCmd $_.Key $_.Value
        
        $_.Value = $_.Value.Replace("'","''")
        $_.Description = $_.Description.Replace("'","''")

        # insert record
        if ($AppConfigMatch -eq 'No') {

            $DataCmd.CommandText = "Insert into ApplicationConfiguration (Id,[Key],[Value],[Description],ConfigurationGroup,DataType) values ({0},'{1}','{2}','{3}','{4}','{5}')" -f $($_.Id), $($_.Key), $($_.Value), $($_.Description), $($_.ConfigurationGroup), $($_.DataType)

            $DataCmd.ExecuteNonQuery();

        }
        
        # do update 
        if ($AppConfigMatch -eq 'Value_Mismatch') {

            $DataCmd.CommandText = "Update ApplicationConfiguration set [Value] = '$($_.Value)' where [Key] = '$($_.Key)'";
            $DataCmd.ExecuteNonQuery();
        }

    }  
    catch
    {
        $recordsWithError.Add($record)
        $errorsEncountered.Add($_)
    }
}

# close n dispose open connections

$DataCmd.Dispose();    
$Conn.Close();
$Conn.Dispose();

if ($recordsWithError.Count -gt 0)
{
    Write-Host $log
    $index = 0

    $recordsWithError | ForEach-Object {

        Write-Host $_
        Write-Host $errorsEncountered[$index]
        $index++
    }
}

$appVersionKey = (Invoke-Sqlcmd -Query "Select top 1 [Value] from ApplicationConfiguration where [Key] = 'ApplicationMajorVersion'" -ServerInstance $sqlserver -Database $database -Username $user -Password $password).Value

if ($appVersionKey.Length -ne 0) {

    if ($ApplicationVersion -ne 0) {

        $AppMinorVersion = $ApplicationVersion.ToString().Split('.')[-1]
        $ApplicationVersion = $appVersionKey + "." + $AppMinorVersion
    }
    if ($DatabaseVersion -ne 0) {
      
        $DatabaseMinorVersion = $DatabaseVersion.ToString().Split('.')[-1]
        $DatabaseVersion = $appVersionKey + "." + $DatabaseMinorVersion
    }
    if ($NotificationDatabaseVersion -ne 0) {

        $NotificationMinorVersion = $NotificationDatabaseVersion.ToString().Split('.')[-1]
        $NotificationDatabaseVersion = $appVersionKey + "." + $NotificationMinorVersion
    }
    
}

# since it was forceImport, add Versions back
if ($forceImport -eq $true) {

    Insert-Versions $connectionstring $ApplicationVersion $DatabaseVersion $NotificationDatabaseVersion
} 

Write-Host "Script complete. $i rows have been inserted into the database." 
Write-Host "Total Elapsed Time: $($elapsed.Elapsed.ToString())" 
# Sometimes the Garbage Collector takes too long to clear the huge datatable. 
[System.GC]::Collect()
