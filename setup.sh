#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
#  🦖 Durango: Wild Lands - 1-Click Termux Offline Server Installer
# ==============================================================================
set -e

echo ""
echo "=================================================================="
echo "    🦖 DURANGO: WILD LANDS - 1-CLICK TERMUX OFFLINE SERVER       "
echo "=================================================================="
echo " Setting up your private local server... Please wait a few moments."
echo " (No server knowledge required - everything is automated!)"
echo "=================================================================="
echo ""

# 1. Prevent Android from putting Termux to sleep
if command -v termux-wake-lock >/dev/null 2>&1; then
    echo "[1/4] Keeping Termux awake in background..."
    termux-wake-lock
fi

# 2. Install required Termux tools
echo "[2/4] Preparing Termux utilities..."
pkg update -y -o Dpkg::Options::="--force-confold" || true
pkg install -y proot-distro curl tar || true

# 3. Setup Ubuntu subsystem in Termux
echo "[3/4] Checking Ubuntu subsystem..."
if ! proot-distro list | grep -q "ubuntu.*installed"; then
    echo "       Installing lightweight Ubuntu container..."
    proot-distro install ubuntu
fi

# 4. Install .NET 9 and Durango Server files
echo "[4/4] Setting up Durango Server engine..."
proot-distro login ubuntu -- bash -c '
set -e
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y ca-certificates curl zlib1g libicu-dev || apt install -y ca-certificates curl zlib1g libicu74 || apt install -y ca-certificates curl zlib1g libicu70 || true

# Install .NET 9 Runtime
if [ ! -f /root/.dotnet/dotnet ]; then
    echo "       Installing .NET 9 runtime..."
    curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    bash /tmp/dotnet-install.sh --channel 9.0 --runtime dotnet --install-dir /root/.dotnet
fi

ln -sf /root/.dotnet/dotnet /usr/local/bin/dotnet

# Download pre-built server package
if [ ! -f /root/durango-server/DurangoServer.dll ]; then
    echo "       Downloading Durango Server files..."
    mkdir -p /root/durango-server
    curl -sSL https://github.com/steingate777/durango-server-release/releases/download/v1.0.0/durango-offline-server.tar.gz | tar -xz -C /root/durango-server
    chmod +x /root/durango-server/run.sh
fi
'

# 5. Create instant shortcut 'durango' in Termux
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
cat << 'EOF' > "$PREFIX_DIR/bin/durango"
#!/data/data/com.termux/files/usr/bin/bash
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
fi
clear
echo "=================================================================="
echo "    🦖 DURANGO: WILD LANDS - OFFLINE LOCAL SERVER                 "
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
proot-distro login ubuntu -- /root/durango-server/run.sh
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
