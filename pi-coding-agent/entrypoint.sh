#!/bin/bash
set -e

# ── Headroom: proxy de compressão de contexto ────────────

# Configura upstream para OpenRouter via variáveis de ambiente
# (mecanismo oficial do proxy para /v1/chat/completions)
if [ -n "$OPENROUTER_API_KEY" ]; then
  echo "[headroom] OPENROUTER_API_KEY detectada — upstream: OpenRouter"
  export OPENAI_API_KEY="$OPENROUTER_API_KEY"
  export OPENAI_TARGET_API_URL="https://openrouter.ai/api/v1"
elif [ -n "$OPENROUTER_KEY" ]; then
  echo "[headroom] OPENROUTER_KEY -> OPENROUTER_API_KEY"
  export OPENROUTER_API_KEY="$OPENROUTER_KEY"
  export OPENAI_API_KEY="$OPENROUTER_KEY"
  export OPENAI_TARGET_API_URL="https://openrouter.ai/api/v1"
fi

echo "[headroom] OPENAI_TARGET_API_URL=$OPENAI_TARGET_API_URL"
echo "[headroom] OPENAI_API_KEY=${OPENAI_API_KEY:0:15}..."

echo "[headroom] Iniciando proxy na porta 8787..."
headroom proxy --host 0.0.0.0 --port 8787 &
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

cat > /root/.pi/agent/models.json << 'CONF'
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
echo "[headroom] Use 'pi --provider openrouter' ou 'pi --provider opencode' como antes"
echo ""

# ── Executa Pi Agent com todos os argumentos recebidos ───
exec pi "$@"
