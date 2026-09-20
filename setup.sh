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
    echo "[1/3] Keeping Termux awake in background..."
    termux-wake-lock
fi

# 2. Install glibc-runner if not present
echo "[2/3] Checking Termux glibc runner..."
if ! command -v grun >/dev/null 2>&1; then
    pkg update -y -o Dpkg::Options::="--force-confold" || true
    pkg install -y glibc-repo || true
    pkg install -y glibc-runner || true
fi

# 3. Download the all-in-one pre-packaged server bundle (38 MB)
echo "[3/3] Downloading complete Durango Server bundle (38 MB)..."
mkdir -p "$HOME/durango-server"
if [ ! -f "$HOME/durango-server/DurangoServer.dll" ]; then
    URL="https://github.com/steingate777/durango-server-release/releases/download/v1.0.0/durango-server-arm64-complete.tar.gz"
    DEST="/tmp/durango-server.tar.gz"
    
    if curl -sSL -k -m 180 "$URL" -o "$DEST" 2>/dev/null; then
        echo "       Downloaded successfully via curl."
    elif wget --no-check-certificate -q -O "$DEST" "$URL" 2>/dev/null; then
        echo "       Downloaded successfully via wget."
    elif python3 -c "import urllib.request, ssl; ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE; urllib.request.urlretrieve('$URL', '$DEST')" 2>/dev/null; then
        echo "       Downloaded successfully via python."
    else
        echo "Error: Could not download server archive. Check internet connection."
        exit 1
    fi

    echo "       Extracting server files..."
    tar -xzf "$DEST" -C "$HOME/durango-server"
    rm -f "$DEST"
    chmod +x "$HOME/durango-server/run.sh" "$HOME/durango-server/dotnet"
fi

# 4. Create instant shortcut 'durango' in Termux
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
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
