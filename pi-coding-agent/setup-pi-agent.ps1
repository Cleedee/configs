#Requires -Version 5.1

$IMAGE_NAME = "meu-pi-agent"
$ENV_FILE = "$HOME\.pi-env"
$PROFILE_PATH = $PROFILE.CurrentUserAllHosts
$VOLUME_NAME = "pi_config"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Info  { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Ok   { Write-Host "[OK]   $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err  { Write-Host "[ERRO] $args" -ForegroundColor Red; exit 1 }

# ── Verificação: Docker instalado ────────────────────────
Write-Info "Verificando se o Docker está instalado..."
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Err "Docker não encontrado. Instale primeiro: https://docs.docker.com/desktop/setup/install/windows-install/"
}
Write-Ok "Docker encontrado: $(docker --version)"

# ── Passo 1: Construir a imagem Docker ────────────────────
Write-Info "Construindo a imagem Docker '$IMAGE_NAME'..."
docker build -t $IMAGE_NAME $SCRIPT_DIR
if (-not $?) { Write-Err "Falha ao construir a imagem Docker." }
Write-Ok "Imagem '$IMAGE_NAME' construída com sucesso."

# ── Passo 2: Centralizar chaves de API ───────────────────
if (Test-Path $ENV_FILE) {
    Write-Warn "$ENV_FILE já existe. Pulando criação (não sobrescreve)."
}
else {
    Write-Info "Criando $ENV_FILE para suas chaves de API..."
    @"
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
DEEPSEEK_API_KEY=sk-...
"@ | Set-Content -Path $ENV_FILE -Encoding ASCII
    Write-Ok "$ENV_FILE criado. EDITE com suas chaves reais!"
}

Write-Host ""
Write-Info "Se ainda não fez, edite suas chaves de API:"
Write-Host "  notepad $ENV_FILE" -ForegroundColor Yellow
Write-Host ""

# ── Passo 3: Criar alias no PowerShell profile ──────────
$AliasCmd = "function pi-docker { docker run -it --rm -v `"`$(Get-Location)`":/workspace -v ${VOLUME_NAME}:/tmp/.config/pi -v `"$HOME\.gitconfig`":/root/.gitconfig:ro --env-file `"$ENV_FILE`" $IMAGE_NAME }"

if (Test-Path $PROFILE_PATH) {
    $ProfileContent = Get-Content $PROFILE_PATH -Raw -ErrorAction SilentlyContinue
}
else {
    $ProfileContent = ""
}

if ($ProfileContent -and $ProfileContent.Contains("pi-docker")) {
    Write-Warn "Alias 'pi-docker' já existe em '$PROFILE_PATH'. Pulando."
}
else {
    Write-Info "Adicionando alias 'pi-docker' ao PowerShell profile..."
    $Entry = @"

# ── Pi Agent Docker ──
# Criado por setup-pi-agent.ps1 em $(Get-Date -Format 'yyyy-MM-dd HH:mm')
$AliasCmd
"@
    Add-Content -Path $PROFILE_PATH -Value $Entry -Encoding UTF8
    Write-Ok "Alias 'pi-docker' adicionado ao PowerShell profile."
    Write-Warn "Recarregue o profile com: . `$PROFILE"
}

# ── Passo 4: Criar o volume, semear settings.json e ajustar permissões ─
Write-Info "Verificando volume Docker '$VOLUME_NAME'..."
if (docker volume inspect $VOLUME_NAME 2>$null | Out-String | Select-String -SimpleMatch "Name") {
    Write-Ok "Volume '$VOLUME_NAME' já existe."
}
else {
    docker volume create $VOLUME_NAME 2>$null
    Write-Ok "Volume '$VOLUME_NAME' criado."
}

# Semeia o volume com o settings.json padrão (declara as extensões do Pi)
# apenas se ainda não existir. O helper roda como root (a imagem não define USER)
# e monta o volume no mesmo caminho do agent dir (PI_CODING_AGENT_DIR).
Write-Info "Semeando settings.json padrão no volume (se necessário)..."
docker run --rm -v "${VOLUME_NAME}:/tmp/.config/pi" --entrypoint sh $IMAGE_NAME -c "[ -f /tmp/.config/pi/settings.json ] || cp /opt/pi-defaults/settings.json /tmp/.config/pi/settings.json" 2>$null
if ($?) { Write-Ok "settings.json padrão garantido no volume." } else { Write-Warn "Não foi possível semear o settings.json." }

# Garante que o container consiga ler/escrever o volume, evitando EACCES no agent dir.
Write-Info "Ajustando permissões do volume..."
docker run --rm -v "${VOLUME_NAME}:/tmp/.config/pi" --entrypoint sh $IMAGE_NAME -c "chmod -R a+rwX /tmp/.config/pi" 2>$null
Write-Ok "Permissões do volume ajustadas."

# ── Resumo ───────────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Configuração concluída!"                          -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  1. Edite suas chaves de API:"                    -ForegroundColor Cyan
Write-Host "     notepad $ENV_FILE"
Write-Host ""
Write-Host "  2. Recarregue o PowerShell profile:"             -ForegroundColor Cyan
Write-Host "     . `$PROFILE"
Write-Host ""
Write-Host "  3. Vá para qualquer projeto e use:"              -ForegroundColor Cyan
Write-Host "     cd C:\Projetos\meu-app"
Write-Host "     pi-docker"
Write-Host ""
Write-Host "  O que o alias faz:"                              -ForegroundColor Yellow
Write-Host "  • Abre o Pi interativamente no diretório atual"
Write-Host "  • Injeta suas chaves de API via ~\.pi-env"
Write-Host "  • Preserva config/histórico no volume $VOLUME_NAME (agent dir /tmp/.config/pi)"
Write-Host "  • Ativa as extensões do Pi via settings.json"
Write-Host "  • Python 3.12 gerenciado pelo uv"
Write-Host "  • Remove o contêiner ao sair (exit)"
Write-Host ""
