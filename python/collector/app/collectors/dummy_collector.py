import os
import time
import logging
from datetime import datetime
from typing import Dict, Iterator, Tuple, List

import requests

CDP_JSON = os.getenv("CDP_JSON", "http://127.0.0.1:9222/json")
POLL_SECONDS = float(os.getenv("POLL_SECONDS", "1.0"))

logger = logging.getLogger("collector.dummy")


def now_str() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def fetch_targets() -> List[dict]:
    """
    Fetch Chrome DevTools Protocol targets list from CDP_JSON endpoint.
    """
    r = requests.get(CDP_JSON, timeout=3)
    r.raise_for_status()
    return r.json()


def iter_url_changes(poll_seconds: float = POLL_SECONDS) -> Iterator[Dict]:
    """
    Watch CDP targets. Yield an event when a new page appears or URL/title changes.

    Yield dict:
      {
        "id": "...",
        "type": "page"|"webview",
        "url": "...",
        "title": "...",
        "ts": "YYYY-mm-dd HH:MM:SS"
      }
    """
    last: Dict[str, Tuple[str, str]] = {}  # tid -> (url, title)

    while True:
        try:
            targets = fetch_targets()
        except Exception as e:
            # CDP not ready / connection refused / transient network issue
            logger.error(f"CDP fetch failed | {repr(e)}")
            time.sleep(poll_seconds)
            continue

        for t in targets:
            t_type = (t.get("type") or "").lower()
            if t_type not in ("page", "webview"):
                continue

            tid = t.get("id") or ""
            url = t.get("url") or ""
            title = t.get("title") or ""

            if not tid or not url:
                continue

            cur = (url, title)
            prev = last.get(tid)

            if prev != cur:
                last[tid] = cur
                yield {
                    "id": tid,
                    "type": t_type,
                    "url": url,
                    "title": title,
                    "ts": now_str(),
                }

        time.sleep(poll_seconds)
