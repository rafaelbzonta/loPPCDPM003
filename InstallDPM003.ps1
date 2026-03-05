# ==============================================================================
# Script para instalar Direct Print Monitor do PaperCut MF
# Finalidade: Contabilizar impressões que estão fora do servidor de impressão principal.
# Desenvolvido por: Rafael Zonta
# ==============================================================================

$LogFile = "C:\Windows\Temp\InstallDPM003.log"
# Inicia a transcrição ignorando erros caso o arquivo esteja preso
Start-Transcript -Path $LogFile -Append -ErrorAction SilentlyContinue

Write-Host "--- Inicio do Deploy: $(Get-Date) ---" -ForegroundColor Cyan
Write-Host "Finalidade: Contabilizar impressões fora do servidor principal." -ForegroundColor Gray
Write-Host "Desenvolvido por: Rafael Zonta" -ForegroundColor Gray
Write-Host "--------------------------------------------------------------" -ForegroundColor Cyan

# 1. Configurações
$TargetDir  = "C:\Program Files\PaperCut Direct Print Monitor"
$SourcePath = "\\PS02\PCDirectPrintMonitor\win" # <--- Certifique-se que este caminho é acessível
$SourceExe  = Join-Path $SourcePath "pc-direct-print-monitor.exe"
$SourceConf = Join-Path $SourcePath "direct-print-monitor.conf"
$LocalExe   = Join-Path $TargetDir "pc-direct-print-monitor.exe"
$ServiceName = "PCPrintMonitor"

# 2. Validação de Acesso ao Servidor
if (!(Test-Path $SourceExe)) {
    Write-Host "ERRO: Arquivo de origem não encontrado em $SourceExe" -ForegroundColor Red
    Write-Host "Verifique a conexão de rede ou permissões da pasta compartilhada." -ForegroundColor Yellow
    Stop-Transcript -ErrorAction SilentlyContinue
    exit
}

# 3. Verificação de Versão (Hash SHA256) com Try/Catch
try {
    Write-Host "Verificando integridade e versão dos arquivos..." -ForegroundColor Gray
    $ServerHash = (Get-FileHash $SourceExe -Algorithm SHA256).Hash
    $LocalHash  = ""

    if (Test-Path $LocalExe) {
        $LocalHash = (Get-FileHash $LocalExe -Algorithm SHA256).Hash
    }

    if ($ServerHash -eq $LocalHash) {
        Write-Host "Status: Versão já atualizada ($ServerHash). Saindo..." -ForegroundColor Green
        Stop-Transcript -ErrorAction SilentlyContinue
        exit
    }
} catch {
    Write-Host "FALHA AO CALCULAR HASH: $($_.Exception.Message)" -ForegroundColor Red
    Stop-Transcript -ErrorAction SilentlyContinue
    exit
}

Write-Host "Status: Atualização necessária. Iniciando preparo..." -ForegroundColor Yellow

# 4. Preparação do Ambiente
if (!(Test-Path $TargetDir)) {
    Write-Host "Criando diretório de destino..." -ForegroundColor Gray
    New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
}

# Para o serviço e mata processos remanescentes para evitar erro de "Arquivo em Uso"
if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {
    Write-Host "Parando serviço $ServiceName..." -ForegroundColor Gray
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
}
Get-Process "pc-direct-print*" -ErrorAction SilentlyContinue | Stop-Process -Force

# 5. Cópia e Instalação
try {
    Write-Host "Copiando arquivos do servidor..." -ForegroundColor Gray
    Copy-Item $SourceExe  -Destination $TargetDir -Force
    Copy-Item $SourceConf -Destination $TargetDir -Force

    Write-Host "Iniciando instalação silenciosa..." -ForegroundColor Cyan
    $InstallArgs = "/TYPE=secondary_print /SILENT /SUPPRESSMSGBOXES /VERYSILENT /NORESTART"
    
    $Process = Start-Process -FilePath $LocalExe -ArgumentList $InstallArgs -Wait -PassThru

    if ($Process.ExitCode -eq 0) {
        Write-Host "Instalação concluida com sucesso (Exit Code 0)." -ForegroundColor Green
        
        # Garante que o .conf customizado seja o final (o instalador pode sobrescrever)
        Copy-Item $SourceConf -Destination $TargetDir -Force
        
        Write-Host "Iniciando serviço..." -ForegroundColor Gray
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
    } else {
        Write-Host "Aviso: O instalador retornou código: $($Process.ExitCode)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "FALHA CRITICA DURANTE O DEPLOY: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "--- Fim do Deploy: $(Get-Date) ---" -ForegroundColor Cyan
Stop-Transcript -ErrorAction SilentlyContinue
