# InstallDPM003

>Este script de automação em PowerShell foi desenvolvido para realizar o deploy e atualização do PaperCut Direct Print Monitor.

# Finalidade:
>O script foi criado para facilitar a contabilização de impressões que ocorrem fora do servidor de impressão principal (impressão direta via IP ou filas locais), garantindo que todos os jobs de impressão sejam devidamente registrados pelo PaperCut MF.

# Funcionalidades:
>Instalação Silenciosa: Realiza o deploy sem intervenção do usuário.
>Verificação de Integridade (Hash SHA256): O script compara o binário local com o do servidor. Se forem idênticos, ele encerra a execução para poupar recursos.
>Gerenciamento de Configuração: Garante que o arquivo direct-print-monitor.conf seja aplicado corretamente após a instalação.
>Auto-Logging: Gera logs detalhados em C:\Windows\Temp\InstallDPM003.log para auditoria.
>Limpeza de Processos: Encerra processos travados antes da atualização para evitar erros de "Arquivo em Uso".

# Como Utilizar:

   >Pré-requisitos
      Acesso à Rede: As estações de trabalho devem ter acesso de leitura à pasta compartilhada definida na variável $SourcePath.
  
   >Permissões: O script deve ser executado com privilégios de Administrador.

   >Configuração
       No arquivo Deploy-PaperCut.ps1, ajuste as variáveis iniciais conforme seu ambiente:

   >PowerShell
         $SourcePath = "\\PS02\PCDirectPrintMonitor\win" # Caminho do instalador no servidor
   >Execução Manual
         PowerShell:
                Set-ExecutionPolicy Bypass -Scope Process
                .\InstallDPM003.ps1
