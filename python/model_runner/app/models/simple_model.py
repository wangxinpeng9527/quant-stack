from __future__ import annotations
from dataclasses import dataclass
from time import time

@dataclass
class SimpleModel:
    name: str = "simple_v0"

    def score(self, event: dict) -> float:
        """
        最简单测试：如果带 confidence 就直接用，否则给个默认分。
        你后面可以替换成真实模型推理（sklearn/torch等）。
        """
        conf = event.get("confidence")
        try:
            if conf is None:
                return 0.5
            return max(0.0, min(1.0, float(conf)))
        except Exception:
            return 0.5

    def now_ts(self) -> int:
        return int(time())
