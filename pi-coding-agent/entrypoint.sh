#!/bin/bash
set -e

# ── Headroom: proxy de compressão de contexto ────────────

# Só faz sentido com OpenRouter (único provider com chave configurada)
if [ -z "$OPENROUTER_API_KEY" ]; then
  if [ -n "$OPENROUTER_KEY" ]; then
    echo "[headroom] OPENROUTER_KEY -> OPENROUTER_API_KEY"
    export OPENROUTER_API_KEY="$OPENROUTER_KEY"
  else
    echo "[headroom] AVISO: OPENROUTER_API_KEY não definida — headroom não será usado"
  fi
fi

if [ -n "$OPENROUTER_API_KEY" ]; then
  echo "[headroom] OPENROUTER_API_KEY detectada"
  export OPENROUTER_API_KEY="$OPENROUTER_API_KEY"
  export OPENAI_TARGET_API_URL="https://openrouter.ai/api/v1"

  # Headroom exige ANTHROPIC_API_KEY mesmo com backend openrouter
  if [ -z "$ANTHROPIC_API_KEY" ]; then
    export ANTHROPIC_API_KEY="sk-ant-dummy"
    echo "[headroom] ANTHROPIC_API_KEY=sk-ant-dummy (placeholder)"
  fi

  echo "[headroom] OPENAI_TARGET_API_URL=$OPENAI_TARGET_API_URL"

  echo "[headroom] Iniciando proxy na porta 8787 (backend: openrouter)..."
  headroom proxy \
    --host 0.0.0.0 --port 8787 \
    --backend openrouter \
    --openai-api-url "https://openrouter.ai/api/v1" &
  HEADROOM_PID=$!

  echo "[headroom] Aguardando proxy ficar pronto..."
  for i in $(seq 1 15); do
    if curl -sf http://localhost:8787/health > /dev/null 2>&1; then
      echo "[headroom] Proxy rodando em http://localhost:8787"
      break
    fi
    if [ "$i" -eq 15 ]; then
      echo "[headroom] Aviso: proxy não respondeu, continuando mesmo assim..."
    fi
    sleep 1
  done

  # ── Configura Pi Agent para rotear chamadas via proxy ────
  mkdir -p /root/.pi/agent

  cat > /root/.pi/agent/models.json << CONF
{
  "providers": {
    "openrouter": {
      "baseUrl": "http://localhost:8787/v1",
      "apiKey": "$OPENROUTER_API_KEY",
      "authHeader": true
    },
    "opencode": {
      "baseUrl": "http://localhost:8787/v1",
      "apiKey": "$OPENCODE_API_KEY",
      "authHeader": true
    },
    "opencode-go": {
      "baseUrl": "http://localhost:8787/v1",
      "apiKey": "$OPENCODE_API_KEY",
      "authHeader": true
    }
  }
}
CONF

  echo "[headroom] Provedores redirecionados para o proxy com apiKey explícita"
  echo "[headroom] Modelos disponíveis via Ctrl+P: owl-alpha, big-picke, deepseek-v4-flash-free"
  echo ""
else
  echo "[headroom] Proxy desabilitado — seguindo direto para o Pi Agent"
fi

# ── Executa Pi Agent com todos os argumentos recebidos ───
# Remove leading "pi" se o usuário passou (ex: "docker run ... pi --provider")
ARGS=()
for arg in "$@"; do
  if [ "$arg" != "pi" ] || [ ${#ARGS[@]} -gt 0 ]; then
    ARGS+=("$arg")
  fi
done

# --models antes de ARGS permite override: docker run ... --models "outros"
exec pi --models "owl-alpha,big-picke,deepseek-v4-flash-free" "${ARGS[@]}"
