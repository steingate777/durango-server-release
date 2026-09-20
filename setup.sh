#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
#  🦖 Durango: Wild Lands - 1-Click Native Offline Server (Complete Bundle)
# ==============================================================================
set -e

echo ""
echo "=================================================================="
echo "    🦖 DURANGO: WILD LANDS - 1-CLICK NATIVE OFFLINE SERVER       "
echo "=================================================================="
echo " Setting up native server... Please wait a few moments."
echo " (Pre-packaged with .NET 9 engine - zero extra downloads!)"
echo "=================================================================="
echo ""

# 1. Prevent Android from putting Termux to sleep
if command -v termux-wake-lock >/dev/null 2>&1; then
    echo "[1/4] Keeping Termux awake in background..."
    termux-wake-lock
fi

# 2. Fix Termux mirror and restore broken curl/openssl
echo "[2/4] Repairing Termux package repository and tools..."
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
if [ -d "$PREFIX_DIR/etc/apt" ]; then
    echo "deb https://packages.termux.dev/apt/termux-main stable main" > "$PREFIX_DIR/etc/apt/sources.list"
fi

apt update -y || true
apt install -y --reinstall libcurl openssl curl wget tar || true
pkg install -y glibc-repo || true
pkg install -y glibc-runner || true

# 3. Robust download helper with visible status
download_url() {
    URL="$1"
    DEST="$2"
    echo "       Downloading server archive..."
    if command -v curl >/dev/null 2>&1 && curl -sSL -k -m 240 --progress-bar "$URL" -o "$DEST"; then
        return 0
    elif command -v wget >/dev/null 2>&1 && wget --no-check-certificate -q --show-progress -O "$DEST" "$URL"; then
        return 0
    elif python3 -c "import urllib.request, ssl; ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE; urllib.request.urlretrieve('$URL', '$DEST')" 2>/dev/null; then
        return 0
    elif python -c "import urllib.request, ssl; ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE; urllib.request.urlretrieve('$URL', '$DEST')" 2>/dev/null; then
        return 0
    fi

    # Fallback to busybox wget if present
    if command -v busybox >/dev/null 2>&1; then
        busybox wget -q -O "$DEST" "$URL" && return 0
    fi

    echo "Error: Download failed. Please ensure you have internet connection."
    exit 1
}

# 4. Download complete Durango Server bundle (38 MB)
echo "[3/4] Fetching complete Durango Server bundle (38 MB)..."
mkdir -p "$HOME/durango-server"
if [ ! -f "$HOME/durango-server/DurangoServer.dll" ]; then
    SERVER_URL="https://github.com/steingate777/durango-server-release/releases/download/v1.0.0/durango-server-arm64-complete.tar.gz"
    TEMP_TAR="/tmp/durango-server.tar.gz"
    download_url "$SERVER_URL" "$TEMP_TAR"

    echo "       Extracting server files..."
    tar -xzf "$TEMP_TAR" -C "$HOME/durango-server"
    rm -f "$TEMP_TAR"
    chmod +x "$HOME/durango-server/run.sh" "$HOME/durango-server/dotnet"
fi

# 5. Create instant shortcut 'durango' in Termux
cat << 'EOF' > "$PREFIX_DIR/bin/durango"
#!/data/data/com.termux/files/usr/bin/bash
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
fi
clear
echo "=================================================================="
echo "    🦖 DURANGO: WILD LANDS - OFFLINE LOCAL SERVER (NO PROOT)      "
echo "=================================================================="
echo "  [✓] Server is STARTING on your phone!"
echo "  [✓] Gateway: http://127.0.0.1:28190"
echo "  [✓] Game Port: 28191"
echo ""
echo "  HOW TO PLAY:"
echo "  1. Open your Durango Offline APK."
echo "  2. Tap 'LAUNCH OFFLINE GAME'."
echo "  3. Enjoy surviving in the wilderness!"
echo ""
echo "  [!] To stop server later: Press Ctrl + C in Termux."
echo "=================================================================="
echo ""
exec "$HOME/durango-server/run.sh"
EOF
chmod +x "$PREFIX_DIR/bin/durango"

echo ""
echo "=================================================================="
echo "  🎉 SETUP COMPLETE!                                             "
echo "=================================================================="
echo "  Starting your offline server now..."
echo "  (Next time, just open Termux and type: durango)"
echo "=================================================================="
echo ""
sleep 2

# Launch the server!
"$PREFIX_DIR/bin/durango"
