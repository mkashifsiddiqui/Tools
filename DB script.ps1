#PS Version 0.0.12 #VIDIZMODBConfig
Param(
    [String] $vMDNSName, #Parameter for Application URL like "vidizmo.eastus.cloudapp.azure.com"
    [String] $sqlAuthenticationLogin, #Parameter for Local SQL Username like "svradmin"
    [String] $sqlAuthenticationPassword, #Parameter for Local SQL Password
    [String] $appVirtualMachineName, #Parameter to Update the License
    [String] $vidizmoOfferType,              #Parameter to Update the License
    [String] $ASBConnectionString #Parameter to add the ASB connection string in the app config table     
)
### hard coded for testing
#$sqlAuthenticationPassword = 'Papercut1234$'
#$sqlAuthenticationLogin = 'sa'
#$vMDNSName = 'localhost'
#$appVirtualMachineName='localhost'
$vidizmoOfferType = 'videp'

#write to file
#$ASBConnectionString|Out-File -FilePath C:\ASBConnectionString.txt

### end of hard coded for testing

if ($Cloud -eq 'Avc') {
    $vMDNSName = Get-Content -Path c:\\cfn\\scripts\\appdns.txt
    $sqlAuthenticationLogin = Get-Content -Path c:\\cfn\\scripts\\sqlsa.txt
    $appVirtualMachineName = 'VidizmoAPP'
    $sqlAuthenticationPassword = $sqlAuthenticationPass
    $vidizmoOfferType = $vidizmoOfferType1
}
else { }

if ($Cloud -eq 'Avc') {
    Set-ExecutionPolicy Unrestricted -Force
    $dpass1 = "'" + $sqlAuthenticationPassword + "'"
    $sql1 = @"
ALTER LOGIN [sa] WITH PASSWORD=
"@
    $sql2 = @"
, CHECK_POLICY=OFF
GO
ALTER LOGIN [sa] ENABLE
GO
"@
    $sql123 = $sql1 + $dpass1 + $sql2

    try {

        Invoke-Sqlcmd -Query $sql123 -Verbose
    
    }
    catch {
    
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
    
    }
    Start-Sleep -Seconds 10
        
    $UpdateSqlauth = @"
        USE [master]
        GO
        EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
                                  N'Software\Microsoft\MSSQLServer\MSSQLServer',      
                                  N'LoginMode', REG_DWORD, 2
        GO
"@

    try {

        Invoke-Sqlcmd -Query $UpdateSqlauth -Verbose
    
    }
    catch {
    
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        
    } 
    Start-Sleep -Seconds 10
    
    C:\cfn\scripts\sqlperm.ps1
    Start-Sleep -Seconds 10

    $UpdateSqldir = @"
    USE [master]
    GO
    EXEC   xp_instance_regwrite
           N'HKEY_LOCAL_MACHINE',
           N'Software\Microsoft\MSSQLServer\MSSQLServer',
           N'DefaultData',
           REG_SZ,
           N'D:\Data'
    GO
    EXEC   xp_instance_regwrite
           N'HKEY_LOCAL_MACHINE',
           N'Software\Microsoft\MSSQLServer\MSSQLServer',
           N'DefaultLog',
           REG_SZ,
           N'D:\Logs'
    GO
    EXEC   xp_instance_regwrite
           N'HKEY_LOCAL_MACHINE',
           N'Software\Microsoft\MSSQLServer\MSSQLServer',
           N'BackupDirectory',
           REG_SZ,
           N'D:\Backups'
    GO
    
"@

    try {

        Invoke-Sqlcmd -Query $UpdateSqldir -Verbose
    
    }
    catch {
    
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
    
    } 
    Start-Sleep -Seconds 10
    C:\cfn\scripts\restartsql.ps1
}
else { 

}

#Variables
#============================================================
   
#Loging File
$VDBLogPath = 'C:\VAppLog'
$DBLogfile = "C:\VAppLog\VIDIZMODBPStranscript.txt"

#Artifacts Path
$VIDZMOArtifactPath = 'C:\VIDIZMOArtifacts'
$basefolder              = 'C:\cfn\scripts\'

#Source For Extracting Artifacts
$Source = 'C:\VIDIZMOArtifacts\DROP.zip'

#Restore VIDIZMO DB Backups
$ServerName = "localhost"
$MasterDB = "master"
    
#VIDIZMODbLicenseActivation
if ($Cloud -eq 'Avc') {
    $LicenseKey = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('aAB0AHQAcABzADoALwAvAHYAaQBkAGkAegBtAG8ALQBhAHIAdABpAGYAYQBjAHQAcwAuAHMAMwAuAGEAbQBhAHoAbwBuAGEAdwBzAC4AYwBvAG0ALwB0AGUAcwB0AGkAbgBnACsAYQByAHQAaQBmAGEAYwB0AHMALwBWAEkARABJAFoATQBPAEQAQgAuAHoAaQBwAA=='))
}
else {
    $LicenseKey = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('aAB0AHQAcABzADoALwAvAG0AYQByAGsAZQB0AGkAbQBhAGcAZQBzAHQAbwByAGEAZwBlAC4AYgBsAG8AYgAuAGMAbwByAGUALgB3AGkAbgBkAG8AdwBzAC4AbgBlAHQALwB2AGkAZABpAHoAbQBvAG0AYQByAGsAZQB0AHAAbABhAGMAZQBhAHIAdABpAGYAYQBjAHQAcwAvAFYASQBEAEkAWgBNAE8ARABCAC0AMgA0ADQALgB6AGkAcAA/AHMAcAA9AHIAJgBzAHQAPQAyADAAMgAyAC0AMAA2AC0AMgA3AFQAMQA0ADoANAA0ADoANAA5AFoAJgBzAGUAPQAyADAAMgA1AC0AMAA2AC0AMgA3AFQAMgAyADoANAA0ADoANAA5AFoAJgBzAHYAPQAyADAAMgAxAC0AMAA2AC0AMAA4ACYAcwByAD0AYwAmAHMAaQBnAD0ATwA3AGMAeABSAEsAegBmAEwAYgAwADQAcgBVAG8AbAAxADgAYQAyAHUASABIAHgARgB3AE0AYwBZAE0ATABlADgAdQBpAHUAbQBDAEoAWQBFAGIAMAAlADMARAA='))    
}
$KeyFile = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('RABSAE8AUAAuAHoAaQBwAA=='))
#AppURL and VidizmoDB
$vMDNSName = $vMDNSName.Trim().ToLower()
$VidizmoDBNewName = "VidizmoDB_6_0"

#UpdateWebAppPaths
$AppPath = "C:"

#Update Storage Provider
if ($Cloud -eq 'Avc') {
    $CDNDrive = "D:"
}
else {
    $CDNDrive = "F:"
}
    

#RecordingSession
#============================================================
try {

    New-Item -Path $VDBLogPath -ItemType Directory -Verbose -ErrorAction Stop

    Start-Transcript -Path $DBLogfile -Force -Verbose

}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

}

Write-Verbose -Message "Application Offer $vidizmoOfferType" -Verbose
#============================================================

#Creating Directory
#============================================================
try {
    New-Item -Path $VIDZMOArtifactPath -ItemType Directory -Verbose -ErrorAction Stop
}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

}
#============================================================


#VIDIZMODbLicenseActivation
#============================================================
function ActivateLicenseWithRetry([string] $ActivateKey, [string] $FileLocation, [int] $retries) {
    while ($true) {
        try {
            Invoke-WebRequest $ActivateKey -OutFile $FileLocation -TimeoutSec 15  
            break
        }
        catch {
            $exceptionMessage = $_.Exception.Message
            if ($retries -gt 0) {
                $retries--
                Start-Sleep -Seconds 10
            }
            else {
                $exception = $_.Exception
                throw $exception
            }
        }
    }
}
 
try {

    ActivateLicenseWithRetry -ActivateKey $LicenseKey -FileLocation "$VIDZMOArtifactPath\$KeyFile" -retries 20

}
catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
}
#============================================================




#ExtractingArtifacts
#============================================================

[Parameter(Position = 0)][System.String] $Source,
[Parameter(Position = 1)][System.String] $VIDZMOArtifactPath

try {

    # extracting source to destination
    Expand-Archive -Path "$($Source)" -DestinationPath "$($VIDZMOArtifactPath)" -Verbose
}
catch {
    # writing errors if any
    Write-Verbose $Error[0]
}
finally {

}
#============================================================




#Email Application Server Deployment Details
#============================================================
$smtpvars= $VIDZMOArtifactPath+"\VIDIZMODB\"+"smtpvar.txt"

$smtpvar= Get-Content -Path $smtpvars 
$smtpvar.GetType() | Format-Table -AutoSize


$emailSmtpServer         = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($smtpvar[0]))
$emailSmtpServerPort     = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($smtpvar[1]))
$emailSmtpUser           = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($smtpvar[2]))
$emailSmtpPass           = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($smtpvar[3]))
$VEmailAddress           = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($smtpvar[4]))
$filenameAndPath         = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($smtpvar[5]))
#============================================================


#============================================================
#   create new folder for the azure service bus connection string
#============================================================
New-Item -Path "c:\" -Name "logfiles" -ItemType "directory"
$myvar=$azureServiceBusConnetion
Out-File -FilePath C:\logfiles\testWRite.txt -InputObject $myvar -Encoding ASCII -Width 50




#============================================================
#update sql authentication
#============================================================
$ServerName = 'localhost'
$MasterDB = 'master'

$sqlEnableSA = "ALTER LOGIN $sqlAuthenticationLogin ENABLE; ALTER LOGIN $sqlAuthenticationLogin WITH PASSWORD = '$sqlAuthenticationPassword'; "

Invoke-Sqlcmd -Query $sqlEnableSA -ServerInstance $ServerName -Database $MasterDB  -QueryTimeout 200 -Verbose


# Set variables to indicate value and key to set
$RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQLServer'
$Name         = 'LoginMode'
$Value        = '2'
# Create the key if it does not exist
If (-NOT (Test-Path $RegistryPath)) {
  New-Item -Path $RegistryPath -Force | Out-Null
}  
# Now set the value
New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force 


#RestartSQLService
#============================================================

try {

    Restart-Service -Name MSSQLSERVER -Force -Verbose

}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

}
#============================================================

#Restore VIDIZMO DB Backups
#============================================================
if ($Cloud -eq 'Avc') {
    $VidizmoDB6Restore = @"

USE [master]
RESTORE DATABASE [VidizmoDB_6_0] FROM  DISK = N'C:\VIDIZMOArtifacts\VIDIZMODB\VidizmoDB_6_0.bak' WITH  FILE = 1,  MOVE N'VidizmoDB' TO N'F:\Data\VidizmoDB_6_0.mdf',  MOVE N'ftrow_ContentSearchCatalog' TO N'D:\Data\VidizmoDB_6_0_ContentSearch.ndf',  MOVE N'ftrow_MashupSearch' TO N'D:\Data\VidizmoDB_6_0_MashupSearch.ndf',  MOVE N'ftrow_TenantSearch' TO N'D:\Data\VidizmoDB_6_0_TenantSearch.ndf',  MOVE N'VidizmoDB_log' TO N'D:\Log\VidizmoDB_6_0_log.ldf',  NOUNLOAD,  STATS = 5

GO
"@

    $VNotificationRestore = @"

USE [master]
RESTORE DATABASE [VidizmoNotificationSystem_6_0] FROM  DISK = N'C:\VIDIZMOArtifacts\VIDIZMODB\VidizmoNotificationSystem_6_0.bak' WITH  FILE = 1,  MOVE N'VidizmoNotificationSystem' TO N'D:\Data\VidizmoNotificationSystem_6_0.mdf',  MOVE N'VidizmoNotificationSystem_log' TO N'D:\Log\VidizmoNotificationSystem_6_0_log.ldf',  NOUNLOAD,  STATS = 5

GO
"@
}
else {
    $VidizmoDB6Restore = @"

USE [master]
RESTORE DATABASE [VidizmoDB_6_0] FROM  DISK = N'C:\VIDIZMOArtifacts\VIDIZMODB\VidizmoDB_6_0.bak' WITH  FILE = 1,  MOVE N'VidizmoDB' TO N'F:\Data\VidizmoDB_6_0.mdf',  MOVE N'ftrow_ContentSearchCatalog' TO N'F:\Data\VidizmoDB_6_0_ContentSearch.ndf',  MOVE N'ftrow_MashupSearch' TO N'F:\Data\VidizmoDB_6_0_MashupSearch.ndf',  MOVE N'ftrow_TenantSearch' TO N'F:\Data\VidizmoDB_6_0_TenantSearch.ndf',  MOVE N'VidizmoDB_log' TO N'F:\Log\VidizmoDB_6_0_log.ldf',  NOUNLOAD,  STATS = 5

GO
"@

    $VNotificationRestore = @"
USE [master]
RESTORE DATABASE [VidizmoNotificationSystem_6_0] FROM  DISK = N'C:\VIDIZMOArtifacts\VIDIZMODB\VidizmoNotificationSystem_6_0.bak' WITH  FILE = 1,  MOVE N'VidizmoNotificationSystem' TO N'F:\Data\VidizmoNotificationSystem_6_0.mdf',  MOVE N'VidizmoNotificationSystem_log' TO N'F:\Log\VidizmoNotificationSystem_6_0_log.ldf',  NOUNLOAD,  STATS = 5

GO
"@
}

try {

    Invoke-Sqlcmd -Query $VidizmoDB6Restore -ServerInstance $ServerName -Database $MasterDB -Username $sqlAuthenticationLogin -Password $sqlAuthenticationPassword -QueryTimeout 200 -Verbose


}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
}

try {

    Invoke-Sqlcmd -Query $VNotificationRestore -ServerInstance $ServerName -Database $MasterDB -Username $sqlAuthenticationLogin -Password $sqlAuthenticationPassword -QueryTimeout 200 -Verbose


}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
}
#============================================================


#SettoAutoSQL
#============================================================
try {


    Set-Service SQLSERVERAGENT -startuptype "Automatic" -Verbose


}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

}
#============================================================



#RestartSQLService
#============================================================

try {

    sRestart-Service -Name MSSQLSERVER -Force -Verbose

}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

}
#============================================================


#Update DB for Application URL
#============================================================
try {

    Invoke-Sqlcmd -Query "UPDATE Tenant SET SubDomainUrl ='$vMDNSName/public' where Id = 1" -ServerInstance $ServerName -Database $VidizmoDBNewName -Username $sqlAuthenticationLogin -Password $sqlAuthenticationPassword -Verbose

    Invoke-Sqlcmd -Query "UPDATE Tenant SET SubDomainUrl ='$vMDNSName' where Id = 2" -ServerInstance $ServerName -Database $VidizmoDBNewName -Username $sqlAuthenticationLogin -Password $sqlAuthenticationPassword -Verbose

}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

}
#============================================================


#UpdateWebAppPaths
#============================================================
$AzureServiceBusDefault = '{"WebApp":{"EventSystem":"AzureServiceBus","ConnectionString":"XXXXXXXXXX","MaxMessageSizeInKilobytes":0,"MaxMessageSizeToCompress":262144},"WorkflowService":{"EventSystem":"AzureServiceBus","ConnectionString":"XXXXXXXXXX","MaxMessageSizeInKilobytes":0,"MaxMessageSizeToCompress":262144},"NotificationService":{"EventSystem":"AzureServiceBus","ConnectionString":"XXXXXXXXXX","MaxMessageSizeInKilobytes":0,"MaxMessageSizeToCompress":262144},"EventService":{"EventSystem":"AzureServiceBus","ConnectionString":"XXXXXXXXXX","MaxMessageSizeInKilobytes":0,"MaxMessageSizeToCompress":262144},"TelemetryService":{"EventSystem":"AzureServiceBus","ConnectionString":"XXXXXXXXXX","MaxMessageSizeInKilobytes":0,"MaxMessageSizeToCompress":262144},"TrackingService":{"EventSystem":"AzureServiceBus","ConnectionString":"XXXXXXXXXX","MaxMessageSizeInKilobytes":0,"MaxMessageSizeToCompress":262144},"IndexingService":{"EventSystem":"AzureServiceBus","ConnectionString":"XXXXXXXXXX","MaxMessageSizeInKilobytes":0,"MaxMessageSizeToCompress":262144},"SchedulerService":{"EventSystem":"AzureServiceBus","ConnectionString":"XXXXXXXXXX","MaxMessageSizeInKilobytes":0,"MaxMessageSizeToCompress":262144},"WebhookService":{"EventSystem":"AzureServiceBus","ConnectionString":"XXXXXXXXXX","MaxMessageSizeInKilobytes":0,"MaxMessageSizeToCompress":262144 }}'
$NewAzureServiceBusConnectionString = $AzureServiceBusDefault.replace('XXXXXXXXXX',$ASBConnectionString)
#$NewAzureServiceBusConnectionString | Add-Content  C:\ASBConnectionString.txt

$UpdatePathQuery = @"
Update ApplicationConfiguration set Value = '$AppPath\VIDIZMO\Cache\ContentFiles\'					   							     where [key] = 'ContentProcessingPath'
Update ApplicationConfiguration set Value = '$AppPath\VIDIZMO\Application\Win\WorkflowService\Configuration\'                        where [key] = 'ProcessingEnginesPath'
Update ApplicationConfiguration set Value = '$AppPath\VIDIZMO\Application\Scripts\CreateAzureAMSAccounts.ps1'						 where [key] = 'PSScriptToCreateAzureStorageAndAMSPath'
Update ApplicationConfiguration set Value = '$AppPath\TrainedData\'				                                                     where [key] = 'TrainedModelsPath'
Update ApplicationConfiguration set Value = '$AppPath\VIDIZMO\Application\Config\routes.json'										 where [key] = 'RoutesConfigurationFile'

insert into ApplicationConfiguration (id,[key],value,description,configurationgroup,datatype) values (82,'FeaturesAvailability','[{"FeatureName":"AzureMetric","IsEnable":false}]','Keep availability of features here','General','String')
insert into ApplicationConfiguration (id,[key],value,description,configurationgroup,datatype) values (83,'AITranscodingProfiles','[{"Signatures":[{"AudioSampleRate":"8000","AudioCodec":"pcm_s16le","MimeType":"audio/wav","AudioChannels":"2","EncodingProfileName":"AIAmsTranscoding"}],"Provider":"AzureVideoIndexer","TenantId":"1"}]','Signatures to handle specific transcoding cases','Transcoding','String')
insert into ApplicationConfiguration (id,[key],value,description,configurationgroup,datatype) values (84,'ElasticSearchSettings','{"Endpoints":["http://localhost:9200"],"AnalyzerSettingsPath":"C:\\VIDIZMO\\Application\\Win\\Config\\elastic-search\\search-analyzer-settings.json","IsEnable":"false","Credentials":{"UserName":"","Password":""},"IndexBuilderTimerInterval":5256000,"SecureProperties":["Credentials.UserName","Credentials.Password"]}','ElasticSearch Configurations to setup on environment','Elastic Search','Secure')
insert into ApplicationConfiguration (id,[key],value,description,configurationgroup,datatype) values (85,'DistributedRunTimeConfig','$NewAzureServiceBusConnectionString','Vidizmo Runtime Application Configuration','Vidizmo Runtime Configuration','String')
insert into ApplicationConfiguration (id,[key],value,description,configurationgroup,datatype) values (86,'MashupArchive_TimerIntervalMinutes','1440','"Time interval in minutes,Archive Mashups."','Scheduled Tasks','String')
insert into ApplicationConfiguration (id,[key],value,description,configurationgroup,datatype) values (87,'OnBoardingGuideConfigurationUrl','','Vidizmo Onboarding Guide Configuration File','General','String')
insert into ApplicationConfiguration (id,[key],value,description,configurationgroup,datatype) values (88,'ApplicationMajorVersion','8.0','Major Version Of Application','General','String')
insert into ApplicationConfiguration (id,[key],value,description,configurationgroup,datatype) values (89,'MaximumWebhookSubscriptionPerService','100','Maximum number of webhook subscription a notification service can host','General','String')
insert into ApplicationConfiguration (id,[key],value,description,configurationgroup,datatype) values (90,'PossibleTransientHttpCodes','{ 404, 408, 409, 423, 429, 500, 502, 503, 504 }','Possible Transient Http Codes using in webhooks','General','String')
update ApplicationConfiguration set value = 'c:\AIModels' where id = 68 
update ApplicationConfiguration set value='8.0.65005' where [key]='ApplicationVersion'
"@


try {

    Invoke-Sqlcmd -Query $UpdatePathQuery -ServerInstance $ServerName -Database $VidizmoDBNewName -Username $sqlAuthenticationLogin -Password $sqlAuthenticationPassword -Verbose

}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

}
#============================================================



#Update Storage Provider
#============================================================
$UpdateStorageProviderQuery = @"
Update ContentStorage set ContentStorageDetail = '{"FTPUploadURL":"ftp://$vMDNSName/","FTPPort":"","FTPPassive":false,"FTPAccount":"ftpuser","FTPPassword":"","AccountId":"","APIKey":"","StoragePath":"$CDNDrive\\CDN\\","ContentUploadURL":"http://$vMDNSName/cdn/","ContentTypes":["Audio","Image","Document","Misc","Video","Form","Caption","SCORM"],"ProviderUrl":"http://$vMDNSName/cdn/","ContainerName":"et-000002"}' where Id = 1
"@


try {

    Invoke-Sqlcmd -Query $UpdateStorageProviderQuery -ServerInstance $ServerName -Database $VidizmoDBNewName -Username $sqlAuthenticationLogin -Password $sqlAuthenticationPassword -Verbose

}
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

}
#============================================================

#Set Offer Package
#============================================================   
#Offer Package videp = Enterprise Premium
#Offer Package vides = Enterprise Standard
#Offer Package viddem = Digital Evidence Management
#Offer Package vidva = Virtual Acedemy 

#Offer Package vidept = Enterprise Premium Transactable
#Offer Package videst = Enterprise Standard Transactable
#Offer Package viddemt = Digital Evidence Management Transactable
#Offer Package vidvat = Virtual Acedemy Transactable

if ($vidizmoOfferType -eq 'videp' -or $vidizmoOfferType -eq 'vides' -or $vidizmoOfferType -eq 'viddem' -or $vidizmoOfferType -eq 'vidva' -or $vidizmoOfferType -eq 'vidept' -or $vidizmoOfferType -eq 'videst' -or $vidizmoOfferType -eq 'viddemt' -or $vidizmoOfferType -eq 'vidvat' ) {
$LicenseObjectPath = $VIDZMOArtifactPath + "\VIDIZMODB\" + $vidizmoOfferType + "obj.txt"
$licenseObja = Get-Content -Path $LicenseObjectPath
$licenseObj = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($licenseObja))

$LicenseKeyPath = $VIDZMOArtifactPath + "\VIDIZMODB\" + $vidizmoOfferType + ".txt"
$VidKeya = Get-Content -Path $LicenseKeyPath 
$VidKey = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($VidKeya)) 
}
else {
$LicenseKeyPath = $VIDZMOArtifactPath + "\VIDIZMODB\" + "videp.txt"
$VidKeya = Get-Content -Path $LicenseKeyPath 
$VidKey = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($VidKeya)) 

$LicenseObjectPath = $VIDZMOArtifactPath + "\VIDIZMODB\" + "videpobj.txt"
$licenseObja = Get-Content -Path $LicenseObjectPath
$licenseObj = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($licenseObja))
$vidizmoOfferType = "videp"
}


#============================================================
#Remove Artifcats
#============================================================
# try {
# 
#     Remove-Item -Path $VIDZMOArtifactPath -Recurse -Verbose
# 
# }
# catch {
# 
#     $ErrorMessage = $_.Exception.Message
#     $FailedItem = $_.Exception.ItemName
# 
# }
# if ($Cloud -eq 'Avc') {
#     try {
# 
#         Remove-Item -Path $basefolder -Recurse -Verbose
#         
#     }
#     catch {
#         
#         $ErrorMessage = $_.Exception.Message
#         $FailedItem = $_.Exception.ItemName
#     }
# }
# else { }
# #============================================================
#SessionStop
#============================================================
Stop-Transcript


#============================================================
#Email Application Server Deployment Details
#============================================================
try{

    #Send Application Deployment Details to VIDIZMO
    $emailMessage = New-Object System.Net.Mail.MailMessage
    $attachment = New-Object System.Net.Mail.Attachment($filenameAndPath)
    $emailMessage.From = "VIDIZMO <no_reply@vidizmo.com>"
    $emailMessage.To.Add( $VEmailAddress )

if($Cloud -eq 'Avc') {
    $emailMessage.Subject = "VIDIZMO AWS Deployment DB Server Details"+" with selected Offer Package "+$vidizmoOfferType
} else {
    $emailMessage.Subject = "VIDIZMO AZURE Deployment DB Server Details"+" with selected Offer Package "+$vidizmoOfferType
}
    
    $emailMessage.IsBodyHtml = $true
    $emailMessage.Attachments.Add($attachment)

    $emailMessage.Body = @"
<p>Please find the attachment of VIDIZMO Database Deployment Details</p>
"@
 
    $SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
    $SMTPClient.EnableSsl = $true
    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $emailSmtpUser , $emailSmtpPass )
    $SMTPClient.Send( $emailMessage )

}catch{

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

}
#============================================================



#============================================================
#END
#============================================================
