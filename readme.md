# 强制重建
docker compose up -d --force-recreate model_runner

# 触发事件
curl -X POST http://localhost:8080/engine/push \
  -H "Content-Type: application/json" \
  -d '{
    "symbol":"BTCUSDT",
    "side":"long",
    "signal_at":"2026-01-02 18:00:00",
    "confidence":0.799
  }'

# 看 model_runner 是否响应
docker compose logs -f model_runner

# 看 signal.scored 是否写回
docker compose exec redis redis-cli XREVRANGE signal.scored + - COUNT 3

