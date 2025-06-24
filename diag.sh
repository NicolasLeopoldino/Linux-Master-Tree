#!/bin/bash
# diag.sh - Diagnóstico básico con formato limpio y emojis

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # Sin color

OUT="diagnostico_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"

# Función para imprimir línea con color y emoji
print_line() {
  echo -e "$1$2$NC"
}

{
# Usuario
USER=$(whoami)
UID=$(id -u)
GROUPS=$(id -nG)
print_line "${BLUE}" "🧑 Usuario: $USER (UID $UID), Grupos: $GROUPS"

# OS y kernel
OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
KERNEL=$(uname -r)
print_line "${GREEN}" "💻 OS: $OS | Kernel: $KERNEL"

# Disco principal (primera partición montada en /)
DISCO_INFO=$(df -h / | tail -1 | awk '{print $1, $3, $2, $5, $6}')
# Separar info
read -r DISCO TOTAL USED PERC MOUNT <<<"$DISCO_INFO"
print_line "${YELLOW}" "💾 Disco: $DISCO $USED usados de $TOTAL ($PERC) en $MOUNT"

# Memoria y carga
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/Mem:/ {print $3}')
LOAD=$(uptime | awk -F 'load average:' '{ print $2 }' | sed 's/^ //')
print_line "${BLUE}" "🧠 Memoria: $MEM_USED usada de $MEM_TOTAL | Carga: $LOAD"

# IP, gateway y DNS
IP=$(ip -4 addr show scope global | grep inet | head -1 | awk '{print $2}' | cut -d/ -f1)
GATEWAY=$(ip route | grep default | awk '{print $3}')
DNS=$(grep '^nameserver' /etc/resolv.conf | head -1 | awk '{print $2}')
print_line "${GREEN}" "🌐 IP: $IP | Gateway: $GATEWAY | DNS: $DNS"

# Servicios activos (solo nombres)
SERVS=$(systemctl list-units --type=service --state=running --no-legend | awk '{print $1}' | sed 's/.service//' | head -10 | paste -sd ", " -)
print_line "${YELLOW}" "⚙️ Servicios: $SERVS"

# Puertos abiertos (tcp y udp)
PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2 | sort -u | paste -sd ", " -)
print_line "${BLUE}" "🔌 Puertos: $PORTS"

} 2>&1 | tee "$OUT"

echo -e "${GREEN}\nInforme generado y mostrado en pantalla: $OUT${NC}"
