for browser in qutebrowser google-chrome-unstable google-chrome-stable chromium firefox; do
    if command -v "$browser" >/dev/null 2>&1; then
        "$browser"
        exit 0
    fi
done
notify-send "Error" "No supported browser found"

