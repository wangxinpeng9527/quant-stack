## Chrome CDP 模式采集

# WINDOWS:
https://www.python.org/downloads/windows/

# Install
cd /d D:\collector
python -m venv venv
venv\Scripts\pip install playwright
venv\Scripts\playwright install

# MAC:
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 \
  --user-data-dir="/tmp/chrome-cdp" \
  --no-first-run --no-default-browser-check

# Mac Start:
cd /Users/apple/code/quant-stack/python/collector
chmod +x bats/start_collector.sh
./bats/start_collector.sh