#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
#  🦖 Durango: Wild Lands - 1-Click Native Termux Offline Server (No PRoot)
# ==============================================================================
set -e

echo ""
echo "=================================================================="
echo "    🦖 DURANGO: WILD LANDS - NATIVE TERMUX OFFLINE SERVER         "
echo "=================================================================="
echo " Setting up native server (No PRoot, lightweight & fast)..."
echo " (Zero server knowledge required - fully automated!)"
echo "=================================================================="
echo ""

# 1. Prevent Android from putting Termux to sleep
if command -v termux-wake-lock >/dev/null 2>&1; then
    echo "[1/4] Keeping Termux awake in background..."
    termux-wake-lock
fi

# 2. Fix any Termux library/OpenSSL mismatches and install utilities
echo "[2/4] Syncing Termux packages and glibc environment..."
apt update -y || true
apt --fix-broken install -y -o Dpkg::Options::="--force-confold" || true
apt full-upgrade -y -o Dpkg::Options::="--force-confold" || pkg upgrade -y || true
pkg install -y openssl curl wget tar || true
pkg install -y glibc-repo || true
pkg install -y glibc-runner || true

# Robust download helper
download_url() {
    URL="$1"
    OUT="$2"
    if curl -sSL -m 120 "$URL" -o "$OUT" 2>/dev/null; then
        return 0
    elif wget -q -O "$OUT" "$URL" 2>/dev/null; then
        return 0
    elif python3 -c "import urllib.request; urllib.request.urlretrieve('$URL', '$OUT')" 2>/dev/null; then
        return 0
    elif python -c "import urllib.request; urllib.request.urlretrieve('$URL', '$OUT')" 2>/dev/null; then
        return 0
    else
        echo "Error: Unable to download $URL"
        exit 1
    fi
}

# 3. Detect architecture and install .NET 9 runtime
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    DOTNET_ARCH="arm64"
elif [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    DOTNET_ARCH="x64"
else
    DOTNET_ARCH="$ARCH"
fi

echo "[3/4] Installing .NET 9 runtime ($DOTNET_ARCH)..."
if [ ! -f "$HOME/.dotnet/dotnet" ]; then
    download_url "https://dot.net/v1/dotnet-install.sh" "/tmp/dotnet-install.sh"
    bash /tmp/dotnet-install.sh --channel 9.0 --runtime dotnet --architecture "$DOTNET_ARCH" --install-dir "$HOME/.dotnet"
fi

# 4. Download pre-built server package (7.5 MB)
echo "[4/4] Setting up Durango Server engine..."
if [ ! -f "$HOME/durango-server/DurangoServer.dll" ]; then
    mkdir -p "$HOME/durango-server"
    download_url "https://github.com/steingate777/durango-server-release/releases/download/v1.0.0/durango-offline-server.tar.gz" "/tmp/server.tar.gz"
    tar -xzf "/tmp/server.tar.gz" -C "$HOME/durango-server"
    rm -f "/tmp/server.tar.gz"
fi

# 5. Create instant shortcut 'durango' in Termux
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
cat << 'EOF' > "$PREFIX_DIR/bin/durango"
#!/data/data/com.termux/files/usr/bin/bash
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
fi

export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
export DOTNET_EnableWriteXorExecute=0

RUNNER=""
if command -v grun >/dev/null 2>&1; then
    RUNNER="grun"
fi

clear
echo "=================================================================="
echo "    🦖 DURANGO: WILD LANDS - NATIVE OFFLINE SERVER (NO PROOT)     "
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

cd "$HOME/durango-server"
exec $RUNNER "$HOME/.dotnet/dotnet" DurangoServer.dll   --name "Durango Offline"   --gateway-port 28190   --game-port 28191   --data ./data   --terrains ./data/terrains   --public-host 127.0.0.1   --cluster-mode Offline   --max-players 1   --tps 10
EOF
chmod +x "$PREFIX_DIR/bin/durango"

echo ""
echo "=================================================================="
echo "  🎉 SETUP COMPLETE! (Zero PRoot, 100% Native)                   "
echo "=================================================================="
echo "  Starting your offline server now..."
echo "  (Next time, just open Termux and type: durango)"
echo "=================================================================="
echo ""
sleep 2

# Launch the server!
"$PREFIX_DIR/bin/durango"
