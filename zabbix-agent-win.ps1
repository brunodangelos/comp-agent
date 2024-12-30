param (
    [string]$Server = "127.0.0.1",               # Endereço do servidor ou proxy Zabbix
    [string]$InstallDir = "C:\dir",        # Diretório de instalação
    [int]$Port = 10050                           # Porta padrão
)

# URL para baixar o binário do Zabbix Agent 2
$zabbixAgentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/latest/zabbix_agent2-7.0.0-windows-amd64.zip"

# Nome do arquivo zip
$zipFile = "$InstallDir\zabbix_agent2.zip"

# Criar o diretório de instalação, se não existir
if (-Not (Test-Path -Path $InstallDir)) {
    Write-Host "Criando diretório: $InstallDir"
    New-Item -ItemType Directory -Path $InstallDir -Force
}

# Baixar o binário do Zabbix Agent 2
Write-Host "Baixando o binário do Zabbix Agent 2..."
Invoke-WebRequest -Uri $zabbixAgentUrl -OutFile $zipFile

# Extrair o conteúdo do arquivo zip
Write-Host "Extraindo o binário do Zabbix Agent 2..."
Expand-Archive -Path $zipFile -DestinationPath $InstallDir -Force

# Caminho para os binários
$agentExecutable = "$InstallDir\zabbix_agent2.exe"
$getExecutable = "$InstallDir\zabbix_get.exe"
$senderExecutable = "$InstallDir\zabbix_sender.exe"

# Verificar se os binários foram extraídos corretamente
if (-Not (Test-Path -Path $agentExecutable) -or -Not (Test-Path -Path $getExecutable) -or -Not (Test-Path -Path $senderExecutable)) {
    Write-Error "Falha ao extrair os binários do Zabbix Agent 2."
    exit 1
}

# Configuração do zabbix_agent2.conf
$configFile = "$InstallDir\zabbix_agent2.conf"

# Criar o arquivo de configuração
Write-Host "Criando arquivo de configuração do Zabbix Agent 2..."
@"
Server=$Server
ServerActive=$Server
LogFile=$InstallDir\zabbix_agent2.log
PidFile=$InstallDir\zabbix_agent2.pid
Hostname=$(hostname)
ListenPort=$Port
"@ | Set-Content -Path $configFile -Force

# Adicionar o Zabbix Agent 2 como um serviço do Windows
Write-Host "Registrando o Zabbix Agent 2 como um serviço do Windows..."
Start-Process -FilePath $agentExecutable -ArgumentList "--install", "--config", $configFile -NoNewWindow -Wait

# Iniciar o serviço do Zabbix Agent 2
Write-Host "Iniciando o serviço do Zabbix Agent 2..."
Start-Service -Name "Zabbix Agent 2"

# Configuração de Firewall
Write-Host "Configurando a regra de Firewall para a porta $Port e o IP $Server..."
New-NetFirewallRule -DisplayName "Zabbix Agent 2" -Direction Inbound -Protocol TCP -LocalPort $Port -RemoteAddress $Server -Action Allow

# Confirmar status do serviço
if ((Get-Service -Name "Zabbix Agent 2").Status -eq "Running") {
    Write-Host "Zabbix Agent 2 configurado e em execução com sucesso."
} else {
    Write-Error "Falha ao iniciar o serviço do Zabbix Agent 2."
}

Write-Host "Binários do Zabbix Agent 2, zabbix_get e zabbix_sender disponíveis em: $InstallDir"
