#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────
# setup-pi-agent.sh
# Configura o ambiente do Pi Agent conforme o README.md
# ──────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERRO]${NC} $*"; exit 1; }

# ── Verificação: Docker instalado ────────────────────────
info "Verificando se o Docker está instalado..."
if ! command -v docker &>/dev/null; then
    error "Docker não encontrado. Instale primeiro: https://docs.docker.com/engine/install/"
fi
success "Docker encontrado: $(docker --version)"

# ── Passo 1: Construir a imagem Docker ────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="meu-pi-agent"

info "Construindo a imagem Docker '${IMAGE_NAME}'..."
docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"
success "Imagem '${IMAGE_NAME}' construída com sucesso."

# ── Passo 2: Centralizar chaves de API ───────────────────
ENV_FILE="${HOME}/.pi-env"

if [[ -f "${ENV_FILE}" ]]; then
    warn "~/.pi-env já existe. Pulando criação (não sobrescreve)."
else
    info "Criando ~/.pi-env para suas chaves de API..."
    cat > "${ENV_FILE}" <<'EOF'
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
DEEPSEEK_API_KEY=sk-...
EOF
    success "~/.pi-env criado. EDITE com suas chaves reais!"
fi

echo ""
info "Se ainda não fez, edite suas chaves de API:"
echo -e "  ${YELLOW}nano ~/.pi-env${NC}"
echo ""

# ── Passo 3: Criar alias no .bashrc ──────────────────────
ALIAS_CMD="alias pi-docker='docker run -it --rm -v \"\$(pwd)\":/workspace -v pi_config:/root/.pi/agent -v ~/.gitconfig:/root/.gitconfig:ro --env-file ~/.pi-env ${IMAGE_NAME}'"
BASHRC="${HOME}/.bashrc"

if grep -qF "pi-docker" "${BASHRC}" 2>/dev/null; then
    warn "Alias 'pi-docker' já existe em ~/.bashrc. Pulando."
else
    info "Adicionando alias 'pi-docker' ao ~/.bashrc..."
    {
        echo ""
        echo "# ── Pi Agent Docker ──"
        echo "# Criado por setup-pi-agent.sh em $(date '+%Y-%m-%d %H:%M')"
        echo "# Para recarregar: source ~/.bashrc"
        echo "${ALIAS_CMD}"
    } >> "${BASHRC}"
    success "Alias 'pi-docker' adicionado ao ~/.bashrc."
fi

# ── Passo 4: Criar o volume de config e semear settings.json ─
info "Verificando volume Docker 'pi_config'..."
if docker volume inspect pi_config &>/dev/null 2>&1; then
    success "Volume 'pi_config' já existe."
else
    docker volume create pi_config &>/dev/null
    success "Volume 'pi_config' criado."
fi

# Se o volume estiver vazio, copia o settings.json padrão da imagem
info "Verificando se o volume precisa ser semeado com settings.json..."
if ! docker run --rm -v pi_config:/data alpine ls /data/settings.json &>/dev/null 2>&1; then
    docker run --rm \
        -v pi_config:/data \
        "${IMAGE_NAME}" \
        sh -c "cp /root/.pi/agent/settings.json /data/settings.json" 2>/dev/null || \
    docker run --rm \
        -v pi_config:/data \
        alpine sh -c "echo '{\"packages\":[\"npm:pi-mcp-adapter\",\"npm:pi-web-access\"]}' > /data/settings.json"
    success "settings.json padrão copiado para o volume."
else
    info "settings.json já existe no volume. Mantido."
fi

# ── Resumo ───────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Configuração concluída!                          ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  1. ${CYAN}Edite suas chaves de API:${NC}"
echo -e "     nano ~/.pi-env"
echo ""
echo -e "  2. ${CYAN}Recarregue o .bashrc:${NC}"
echo -e "     source ~/.bashrc"
echo ""
echo -e "  3. ${CYAN}Vá para qualquer projeto e use:${NC}"
echo -e "     cd ~/Projetos/meu-app"
echo -e "     pi-docker"
echo ""
echo -e "  ${YELLOW}O que o alias faz:${NC}"
echo -e "  • Abre o Pi interativamente no diretório atual"
echo -e "  • Injeta suas chaves de API via ~/.pi-env"
echo -e "  • Preserva config/histórico no volume pi_config (montado em /root/.pi/agent)"
echo -e "  • Remove o contêiner ao sair (exit)"
echo ""
