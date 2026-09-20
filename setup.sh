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

# 2. Check and install Termux glibc runner (No PRoot)
echo "[2/3] Checking Termux glibc runner..."
if ! command -v grun >/dev/null 2>&1; then
    pkg update -y -o Dpkg::Options::="--force-confold" || true
    pkg install -y glibc-repo || true
    pkg install -y glibc-runner || true
fi

# 3. Stream and extract pre-packaged server bundle (38 MB) directly into $HOME
echo "[3/3] Downloading & unpacking Durango Server bundle (38 MB)..."
mkdir -p "$HOME/durango-server"

if [ ! -f "$HOME/durango-server/DurangoServer.dll" ]; then
    URL="https://github.com/steingate777/durango-server-release/releases/download/v1.0.0/durango-server-arm64-complete.tar.gz"
    
    # Direct stream into tar - zero temp files, 100% Android compatible
    echo "       Streaming archive into $HOME/durango-server..."
    if command -v curl >/dev/null 2>&1; then
        curl -sSL -k -m 300 "$URL" | tar -xz -C "$HOME/durango-server"
    elif command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate -qO- "$URL" | tar -xz -C "$HOME/durango-server"
    elif command -v busybox >/dev/null 2>&1; then
        busybox wget -qO- "$URL" | tar -xz -C "$HOME/durango-server"
    fi

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
