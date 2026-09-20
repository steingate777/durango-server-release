#!/bin/sh
set -e

unset LD_LIBRARY_PATH
unset LD_PRELOAD

echo ""
echo "=================================================================="
echo "    🦖 DURANGO: WILD LANDS - 1-CLICK NATIVE OFFLINE SERVER       "
echo "=================================================================="
echo " Setting up native server... Please wait a few moments."
echo "=================================================================="
echo ""

# 1. Prevent Android from putting Termux to sleep
if command -v termux-wake-lock >/dev/null 2>&1; then
    echo "[1/3] Keeping Termux awake in background..."
    termux-wake-lock || true
fi

# 2. Check and install Termux glibc runner (No PRoot)
echo "[2/3] Checking Termux glibc runner..."
if ! command -v grun >/dev/null 2>&1; then
    PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
    if [ -d "$PREFIX_DIR/etc/apt" ]; then
        echo "deb https://packages.termux.dev/apt/termux-main stable main" > "$PREFIX_DIR/etc/apt/sources.list"
    fi
    pkg update -y -o Dpkg::Options::="--force-confold" || true
    pkg install -y glibc-repo || true
    pkg install -y glibc-runner || true
fi

# 3. Stream and extract pre-packaged server bundle (38 MB) if missing
echo "[3/3] Preparing Durango Server engine..."
mkdir -p "$HOME/durango-server"

if [ ! -f "$HOME/durango-server/DurangoServer.dll" ] || [ ! -f "$HOME/durango-server/dotnet" ]; then
    SUCCESS=0
    for URL in "https://litter.catbox.moe/57qzx7.gz" "https://litter.catbox.moe/7r2cy4.gz"; do
        echo "       Trying mirror: $URL"
        if curl -sSL -k --http1.1 --retry 2 -m 300 "$URL" | tar -xz -C "$HOME/durango-server" 2>/dev/null; then
            if [ -f "$HOME/durango-server/DurangoServer.dll" ]; then
                SUCCESS=1
                echo "       [✓] Unpacked successfully!"
                break
            fi
        fi
    done

    if [ "$SUCCESS" -ne 1 ]; then
        echo "Error: Download failed across all mirrors. Please check connection."
        exit 1
    fi
fi

PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"

# Write clean runner script with isolated glibc parameters (NEVER touches Termux LD_LIBRARY_PATH)
cat << 'EOF' > "$HOME/durango-server/run.sh"
#!/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

unset LD_LIBRARY_PATH
unset LD_PRELOAD

export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
export DOTNET_EnableWriteXorExecute=0

PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
LD_SO="$PREFIX_DIR/glibc/lib/ld-linux-aarch64.so.1"
GLIBC_LIB="$PREFIX_DIR/glibc/lib"

echo "=================================================="
echo "  🦖 Starting Durango Offline Server..."
echo "  Gateway: http://127.0.0.1:28190"
echo "  Game TCP: 127.0.0.1:28191"
echo "=================================================="

if [ -x "$LD_SO" ]; then
    exec "$LD_SO" --library-path "$GLIBC_LIB" "$DIR/dotnet" "$DIR/DurangoServer.dll"       --name "Durango Offline"       --gateway-port 28190       --game-port 28191       --data "$DIR/data"       --terrains "$DIR/data/terrains"       --public-host 127.0.0.1       --cluster-mode Offline       --max-players 1       --tps 10
elif command -v grun >/dev/null 2>&1; then
    exec grun "$DIR/dotnet" "$DIR/DurangoServer.dll"       --name "Durango Offline"       --gateway-port 28190       --game-port 28191       --data "$DIR/data"       --terrains "$DIR/data/terrains"       --public-host 127.0.0.1       --cluster-mode Offline       --max-players 1       --tps 10
else
    exec "$DIR/dotnet" "$DIR/DurangoServer.dll"       --name "Durango Offline"       --gateway-port 28190       --game-port 28191       --data "$DIR/data"       --terrains "$DIR/data/terrains"       --public-host 127.0.0.1       --cluster-mode Offline       --max-players 1       --tps 10
fi
EOF

chmod +x "$HOME/durango-server/run.sh" "$HOME/durango-server/dotnet"

# 4. Create instant shortcut 'durango' in Termux
cat << 'EOF' > "$PREFIX_DIR/bin/durango"
#!/bin/sh
unset LD_LIBRARY_PATH
unset LD_PRELOAD
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock || true
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
sleep 1

# Launch the server!
"$PREFIX_DIR/bin/durango"
