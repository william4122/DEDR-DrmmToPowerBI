# Get DrmmToPowerBI registry values
$Config = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\DEDRToPowerBI -ErrorAction SilentlyContinue
if (!$Config) {
	Write-Host 'Registry keys not found. Please import DEDRToPowerBI.reg first!'
	exit 1
}

if ( $null -ne $env:DEDRToPowerBICredentialKey ) {
	$EncryptionKeyBytes = ( [system.Text.Encoding]::UTF8 ).GetBytes( $env:DEDRToPowerBICredentialKey )
	$Config.SQLPassword = $Config.SQLPassword | ConvertTo-SecureString -Key $EncryptionKeyBytes |
	ForEach-Object { [Runtime.InteropServices.Marshal]::PtrToStringAuto( [Runtime.InteropServices.Marshal]::SecureStringToBSTR( $_ ) ) }
}

# Import Module
Remove-Module SQLPS -ErrorAction SilentlyContinue
Import-Module SQLServer -Force

# Create SQL Connection Parameters
$sqlParams = [ordered]@{
	Server     =  $Config.SQLServer
	Database   =  $Config.SQLDatabase
	User       =  $Config.SQLUser
	Password   =  $Config.SQLPassword
}

# Create SQL Connection String
$connString = 'Server={0};Database={1};User Id={2};Password={3};' -f [array]$sqlParams.Values

# Run SQL query to Create SQL Procedures
Invoke-Sqlcmd -ConnectionString $connString -InputFile 'CreateSQLProcedures.sql'
