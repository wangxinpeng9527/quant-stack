import os
import sys
import logging
from datetime import datetime

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

from app.collectors.dummy_collector import iter_url_changes
from app.publisher import publish_signal

# 你要求仍然用这些字段：symbol/side/signal_at/confidence
DEFAULT_SYMBOL = os.getenv("DEFAULT_SYMBOL", "BTCUSDT")
DEFAULT_SIDE = os.getenv("DEFAULT_SIDE", "long")
DEFAULT_CONFIDENCE = float(os.getenv("DEFAULT_CONFIDENCE", "0.799"))

# 日志
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG_DIR = os.path.join(BASE_DIR, "logs")
os.makedirs(LOG_DIR, exist_ok=True)

log_file = os.path.join(LOG_DIR, "collector.log")
logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format="%(asctime)s | %(name)s | %(levelname)s | %(message)s",
)

console = logging.getLogger("collector.console")
console.setLevel(logging.INFO)
console.addHandler(logging.StreamHandler())


def now_str() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def build_signal(event: dict) -> dict:
    """
    按你的要求：仍然使用原字段 + 追加 url/title
    后端 payload 会把整个 JSON 存进去
    """
    return {
        "symbol": DEFAULT_SYMBOL,
        "side": DEFAULT_SIDE,
        "signal_at": now_str(),          # 取到新URL的时刻
        "confidence": DEFAULT_CONFIDENCE,

        # 追加：当前 url/title（你要落库到 payload）
        "url": event.get("url", ""),
        "title": event.get("title", ""),

        # 额外给你留着：CDP target id/type（可选，方便排查）
        "target_id": event.get("id", ""),
        "target_type": event.get("type", ""),
    }


def main():
    console.info(f"[{now_str()}] Collector starting...")
    console.info(f"Log file: {log_file}")
    console.info(f"ENGINE_PUSH_URL: {os.getenv('ENGINE_PUSH_URL', 'http://localhost:8080/engine/push')}")
    console.info("Press Ctrl+C to stop.")

    try:
        for event in iter_url_changes():
            # event: {id,url,title,type,ts}
            msg = f"{event.get('id')} | {event.get('title')} | {event.get('url')}"
            logging.getLogger("collector.dummy").info(msg)
            console.info(f"[{now_str()}] NEW: {msg}")

            payload = build_signal(event)

            try:
                resp = publish_signal(payload)
                logging.getLogger("collector.publisher").info(f"pushed | resp={resp}")
                console.info(f"[{now_str()}] PUSH OK | resp={resp}")
            except Exception as e:
                logging.getLogger("collector.publisher").error(f"push error | {repr(e)}")
                console.info(f"[{now_str()}] PUSH ERROR | {repr(e)}")

    except KeyboardInterrupt:
        console.info(f"[{now_str()}] Stopped.")


if __name__ == "__main__":
    main()
