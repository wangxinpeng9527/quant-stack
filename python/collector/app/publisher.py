import os
import json
import time
import logging
from typing import Any, Dict, Optional

import requests

ENGINE_PUSH_URL = os.getenv("ENGINE_PUSH_URL", "http://localhost:8080/engine/push")
PUBLISH_TIMEOUT = float(os.getenv("PUBLISH_TIMEOUT", "6"))
PUBLISH_RETRY = int(os.getenv("PUBLISH_RETRY", "2"))
PUBLISH_RETRY_SLEEP = float(os.getenv("PUBLISH_RETRY_SLEEP", "0.6"))

logger = logging.getLogger("collector.publisher")


def publish_signal(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    推送 JSON 到 ENGINE_PUSH_URL
    - 成功返回响应 json（若响应不是 json，则返回 {"raw": "..."}）
    - 失败会重试 PUBLISH_RETRY 次，最终抛异常
    """
    last_err: Optional[Exception] = None

    for attempt in range(PUBLISH_RETRY + 1):
        try:
            r = requests.post(
                ENGINE_PUSH_URL,
                headers={"Content-Type": "application/json"},
                data=json.dumps(payload, ensure_ascii=False),
                timeout=PUBLISH_TIMEOUT,
            )
            r.raise_for_status()

            try:
                return r.json()
            except Exception:
                return {"raw": r.text}

        except Exception as e:
            last_err = e
            logger.error(f"publish failed (attempt={attempt}) | {repr(e)}")
            if attempt < PUBLISH_RETRY:
                time.sleep(PUBLISH_RETRY_SLEEP)

    raise last_err  # type: ignore
