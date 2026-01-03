from __future__ import annotations
import os
from redis import Redis

def get_redis() -> Redis:
    host = os.getenv("REDIS_HOST", "redis")
    port = int(os.getenv("REDIS_PORT", "6379"))
    return Redis(host=host, port=port, decode_responses=True)

def ensure_group(r: Redis, stream: str, group: str, start_id: str = "0") -> None:
    try:
        r.xgroup_create(stream, group, id=start_id, mkstream=True)
    except Exception as e:
        # BUSYGROUP means group already exists
        if "BUSYGROUP" not in str(e):
            raise

def xreadgroup(r: Redis, stream: str, group: str, consumer: str, count: int, block_ms: int):
    return r.xreadgroup(group, consumer, {stream: ">"}, count=count, block=block_ms)

def xack(r: Redis, stream: str, group: str, msg_id: str) -> None:
    r.xack(stream, group, msg_id)

def xadd(r: Redis, stream: str, data: dict) -> str:
    return r.xadd(stream, data)
