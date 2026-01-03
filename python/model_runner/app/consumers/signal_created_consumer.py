from __future__ import annotations
import os
from app.redis_stream import get_redis, ensure_group, xreadgroup, xack, xadd
from app.models.simple_model import SimpleModel

def run():
    r = get_redis()

    stream_in  = os.getenv("STREAM_IN", "signal.created")
    stream_out = os.getenv("STREAM_OUT", "signal.scored")

    group = os.getenv("GROUP", "ml-group")
    consumer = os.getenv("CONSUMER", "ml-1")

    block_ms = int(os.getenv("BLOCK_MS", "5000"))
    count = int(os.getenv("COUNT", "10"))

    ensure_group(r, stream_in, group, start_id="0")

    model = SimpleModel()

    print(f"[model_runner] listening: {stream_in} (group={group}, consumer={consumer}) -> {stream_out}")

    while True:
        msgs = xreadgroup(r, stream_in, group, consumer, count=count, block_ms=block_ms)
        if not msgs:
            continue

        # msgs: [(stream, [(id, {k:v}), ...])]
        for _stream, entries in msgs:
            for msg_id, fields in entries:
                try:
                    # fields 已经是 dict[str,str]（decode_responses=True）
                    # 你可以按需转型
                    signal_id = fields.get("signal_id")
                    symbol = fields.get("symbol")
                    side = fields.get("side")

                    score = model.score(fields)

                    print(f"[model_runner] got {msg_id} signal_id={signal_id} {symbol} {side} -> score={score}")

                    xadd(r, stream_out, {
                        "signal_id": signal_id or "",
                        "symbol": symbol or "",
                        "side": side or "",
                        "score": str(score),
                        "model": model.name,
                        "ts": str(model.now_ts()),
                    })

                    xack(r, stream_in, group, msg_id)

                except Exception as e:
                    # 不 ACK：留在 pending 方便后面重试/排查
                    print(f"[model_runner] ERROR msg_id={msg_id}: {e}")

if __name__ == "__main__":
    run()
