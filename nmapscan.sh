#!/bin/bash

# Usage: sudo nmapscan <IP> [options]
# Options:
#   -o DIR      Output directory (default: ./Scan)
#   -r RATE     Min rate for phase 1 (default: 5000, use 0 to disable)
#   -p PORTS    Skip phase 1, scan these ports directly (e.g. 80,443,5985)
#   -s          Slow mode: no --min-rate, adds -T2 (bypasses rate-limiting firewalls)
#   -u          Also run UDP scan on top 200 ports (requires root)
#   -6          Scan IPv6 target
#   --no-syn    Use -sT (connect scan) instead of -sS (needs no root)

usage() {
    echo "Uso: sudo $0 <IP> [opciones]"
    echo ""
    echo "  -o DIR      Directorio de salida (default: ./Scan)"
    echo "  -r RATE     Min-rate fase 1 (default: 5000, 0 = desactivar)"
    echo "  -p PORTS    Saltar fase 1, escanear estos puertos (e.g. 80,443,5985)"
    echo "  -s          Modo lento: sin --min-rate, -T2 (evita drops de firewall)"
    echo "  -u          UDP scan top-200 puertos"
    echo "  --no-syn    Usar -sT en lugar de -sS (no necesita root)"
    exit 1
}

[ -z "$1" ] && usage

IP="$1"
shift

OUTDIR="./Scan"
MIN_RATE=5000
CUSTOM_PORTS=""
SLOW=false
UDP=false
IPV6=""
SYN_FLAG="-sS"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o) OUTDIR="$2"; shift 2 ;;
        -r) MIN_RATE="$2"; shift 2 ;;
        -p) CUSTOM_PORTS="$2"; shift 2 ;;
        -s) SLOW=true; shift ;;
        -u) UDP=true; shift ;;
        -6) IPV6="-6"; shift ;;
        --no-syn) SYN_FLAG="-sT"; shift ;;
        *) echo "Opción desconocida: $1"; usage ;;
    esac
done

mkdir -p "$OUTDIR"

ALLPORTS_FILE="$OUTDIR/allports_${IP}_${TIMESTAMP}.txt"
FULL_FILE="$OUTDIR/fullscan_${IP}_${TIMESTAMP}.txt"
UDP_FILE="$OUTDIR/udpscan_${IP}_${TIMESTAMP}.txt"

if [ -n "$CUSTOM_PORTS" ]; then
    PORTS="$CUSTOM_PORTS"
    echo "[*] Saltando fase 1. Puertos: $PORTS"
else
    echo "[*] Fase 1: Descubrimiento de puertos en $IP..."

    RATE_ARG=""
    TIMING_ARG=""
    if $SLOW; then
        TIMING_ARG="-T2"
        echo "[*] Modo lento activado (-T2, sin --min-rate)"
    elif [ "$MIN_RATE" -gt 0 ] 2>/dev/null; then
        RATE_ARG="--min-rate $MIN_RATE"
    fi

    nmap $IPV6 -vvv -p- --open $SYN_FLAG $RATE_ARG $TIMING_ARG -n -Pn "$IP" -oN "$ALLPORTS_FILE"

    PORTS=$(grep -oP '^\d+(?=/tcp\s+open)' "$ALLPORTS_FILE" | tr '\n' ',' | sed 's/,$//')

    if [ -z "$PORTS" ]; then
        echo "[-] No se encontraron puertos TCP abiertos."
        [ "$UDP" = false ] && exit 1
    else
        echo "[*] Puertos encontrados: $PORTS"
    fi
fi

if [ -n "$PORTS" ]; then
    echo "[*] Fase 2: Escaneo detallado (-sCV) en $IP:$PORTS..."
    nmap $IPV6 -p"$PORTS" "$IP" -sCV -Pn -oN "$FULL_FILE"
fi

if $UDP; then
    echo "[*] Fase UDP: Top 200 puertos UDP en $IP..."
    nmap $IPV6 -sU --top-ports 200 -Pn "$IP" -oN "$UDP_FILE"
    echo "    UDP scan:     $UDP_FILE"
fi

echo ""
echo "[+] Listo."
[ -f "$ALLPORTS_FILE" ] && echo "    Puertos:       $ALLPORTS_FILE"
[ -f "$FULL_FILE"     ] && echo "    Scan completo: $FULL_FILE"
[ -f "$UDP_FILE"      ] && echo "    UDP scan:      $UDP_FILE"
