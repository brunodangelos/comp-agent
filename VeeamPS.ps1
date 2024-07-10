$Instalacao = 'C:\compmon\conf' #Arquivo de configuração do zabbix agent
$Binario = 'C:\compmon\bin' #Binario de execução do zabbix sender
$HostnameServidor = 'SA316CLD' #Hostname do servidor que está cadastrado no zabbix

try {
    # Comando 1 
    $GetVBRJob = Get-VBRJob -WarningAction SilentlyContinue
    if ($GetVBRJob -ne $null){
        $GetVBRJob | Select @{Name = 'Name'; Expression = { $_.Name } } , @{Name = 'LatestRunLocal'; Expression = { $_.LatestRunLocal } }, @{Name = 'Description'; Expression = { $_.Description } }, @{Name = 'IsRunning'; Expression = { $_.IsRunning } }, @{Name = 'LatestStatus'; Expression = { $_.Info.LatestStatus } }, @{Name = 'TypeToString'; Expression = { $_.TypeToString } }, @{Name = 'IsScheduleEnabled'; Expression = { $_.IsScheduleEnabled } } | ConvertTo-json | Out-File -FilePath C:\compmon\scripts\VBRJob.json
    }

    #Comando 2 SQL Backup Transaction 
    $GetSQLJob = Get-VBRJob -WarningAction SilentlyContinue
    $SQLJob = $GetSQLJob.FindChildSqlLogBackupJob()
    $SQLResults = @()
    try {
        if ($SQLJob -ne $null){
                foreach ($SQLJobResult in $SQLJob.Id){
                        $SQLBackupSession = [Veeam.Backup.Core.CBackupSession]::GetByJob($SQLJobResult) | where { $_.IsCompleted -eq $True } | sort creationtime -Descending | select -Last 1
                        if ($SQLBackupSession -ne $null) {
                            $SQLResult = [PSCustomObject]@{
                                 Name = $SQLBackupSession.Name
                                 LatestRunLocal = $SQLBackupSession.Progress.StartTimeLocal
                                 Description = $SQLBackupSession.Description
                                 LatestStatus = $SQLBackupSession.Info.State
                                 Result = $SQLBackupSession.Info.Result
                                 TypeToString = $SQLBackupSession.JobTypeString
                            }
                                $SQLResults += $SQLResult
                }
             $SQLResults | ConvertTo-Json  | Out-File -FilePath "C:\compmon\scripts\sqlLog.json"
            }
        }
    }
    catch {
        echo "[Erro ao coletar SQL Transaction LOG]"
    }

    #Comando 3 Oracle Backup Trasaction 
    $GetOracleJob = Get-VBRJob -WarningAction SilentlyContinue
    $OracleJob = $GetOracleJob.FindChildOracleLogBackupJob()
    $OracleResults = @()
    try {
        if ($OracleJob -ne $null){
                foreach ($OracleJobResult in $OracleJob.Id){
                        $SQLBackupSession = [Veeam.Backup.Core.CBackupSession]::GetByJob($OracleJobResult) | where { $_.IsCompleted -eq $True } | sort creationtime -Descending | select -Last 1
                        if ($SQLBackupSession -ne $null) {
                            $OracleResult = [PSCustomObject]@{
                                 Name = $SQLBackupSession.Name
                                 LatestRunLocal = $SQLBackupSession.Progress.StartTimeLocal
                                 Description = $SQLBackupSession.Description
                                 LatestStatus = $SQLBackupSession.Info.State
                                 Result = $SQLBackupSession.Info.Result
                                 TypeToString = $SQLBackupSession.JobTypeString
                            }
                                $OracleResults += $OracleResult
                }
             $OracleResults | ConvertTo-Json  | Out-File -FilePath "C:\compmon\scripts\OracleLog.json"
            }
        }
    }
    catch {
        echo "[Erro ao coletar Oracle Transaction LOG]"
    }

    #Comando 4 Application Plugin
    $GetVBRAppPlugin = Get-VBRPluginJob -WarningAction SilentlyContinue | where { $_.IsEnabled -eq $True }
    if ($GetVBRAppPlugin -ne $null){
        $GetVBRAppPlugin | Select-Object -Property Id, Name, LastRun, LastResult, Description, Type, IsEnabled | ConvertTo-Json | Out-File -FilePath C:\compmon\scripts\VBRJobPlugin.json
    }

    # Comando 5 Repositorio
    $repos = Get-VBRBackupRepository
    if ($repos -ne $null)
    {
        $repoReport = @()
        foreach ($repo in $repos) {
            $container = $repo.GetContainer()
            $totalSpace += [Math]::Round($container.CachedTotalSpace.InBytes)
            $totalFreeSpace += [Math]::Round($container.CachedFreeSpace.InBytes)
            $repoReport += $repo | select Name, @{n = 'TotalSpace'; e = { $totalSpace } }, @{n = 'FreeSpace'; e = { $totalFreeSpace } }
        }
        $repoReport | ConvertTo-Json | Out-File -FilePath C:\compmon\scripts\Repository.json
    }

    #Comando 5 Scale-Out
    $sobrs = Get-VBRBackupRepository -Scaleout
    if ($sobrs -ne $null)
    {
        $sobrReport = @()
        foreach ($sobr in $sobrs) {
            $extents = $sobr.Extent
            $totalSpace = $null
            $totalFreeSpace = $null
            foreach ($extent in $extents) {
                $repo = $extent.Repository
                $container = $repo.GetContainer()
                $totalSpace += [Math]::Round($container.CachedTotalSpace.InBytes)
                $totalFreeSpace += [Math]::Round($container.CachedFreeSpace.InBytes)
            }
            $sobrReport += $sobr | select Name, @{n = 'TotalSpace'; e = { $totalSpace } }, @{n = 'FreeSpace'; e = { $totalFreeSpace } }
        }
        $sobrReport | ConvertTo-Json | Out-File -FilePath C:\compmon\scripts\RepositoryScaleOut.json
    }

    #Comando 6 TapeJob
    $tapejob = Get-VBRTapeJob -WarningAction SilentlyContinue | Select @{Name = 'Name'; Expression = { $_.Name } } , @{Name = 'LastResult'; Expression = { $_.LastResult } }, @{Name = 'Description'; Expression = { $_.Description } }, @{Name = 'NextRun'; Expression = { $_.NextRun } }, @{Name = 'Enabled'; Expression = { $_.Enabled } }
    if ($tapejob -ne $null)
    {
        $tapejob | Sort-Object Name | ConvertTo-Json | Out-File -FilePath C:\compmon\scripts\VBRTapeJob.json
    }

    # Comando 9 Sure-Backup
    $surebackup = Get-VBRSureBackupJob | Select @{Name = 'Name'; Expression = { $_.Name } } , @{Name = 'LastRun'; Expression = { $_.LastRun } }, @{Name = 'Description'; Expression = { $_.Description } }, @{Name = 'NextRun'; Expression = { $_.NextRun } }, @{Name = 'LastResult'; Expression = { $_.LastResult } }, @{Name = 'IsEnabled'; Expression = { $_.IsEnabled } }
    if ($surebackup -ne $null)
    {
        $surebackup  | ConvertTo-Json | Out-File -FilePath C:\compmon\scripts\VBRSureBackupJob.json
    }

    # Comando 10 Informações do Servidor
    $VBRServer = Get-VBRServer -WarningAction SilentlyContinue
    if ($VBRServer -ne $null)
    {
         $VBRServer | ConvertTo-json | Out-File -FilePath C:\compmon\scripts\VBRServer.json
    }
    
    #Print Resultado do Script
    & "$Binario\zabbix_sender.exe" -vv -c "$Instalacao\zabbix_agent2.conf" -s $HostnameServidor -k resultjob.veeam  -o 1

}
catch {
    & "$Binario\zabbix_sender.exe" -vv -c "$Instalacao\zabbix_agent2.conf" -s $HostnameServidor -k resultjob.veeam  -o 0
}

$license = Get-VBRInstalledLicense 
if ($license -ne $null){
    $license | Select-Object -Property Status,ExpirationDate,Type,Edition,SupportExpirationDate | ConvertTo-Json | Out-File -FilePath C:\compmon\scripts\VBRLicense.json
} 
