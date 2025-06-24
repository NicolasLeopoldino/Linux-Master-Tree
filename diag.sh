#!/bin/bash

# Colores
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'
NC='\e[0m' # Sin color

# Función para imprimir líneas con color y emoji
print_line() {
  echo -e "$1$2${NC}"
}

echo -e "${CYAN}🚀 ===== Diagnóstico rápido del sistema =====${NC}"

# Usuario
USER=$(whoami)
UID=$(id -u)
GROUPS=$(id -nG)
print_line "${BLUE}" "👤 Usuario: $USER (UID $UID), Grupos: $GROUPS"

# OS y kernel
OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
KERNEL=$(uname -r)
print_line "${GREEN}" "💻 OS: $OS | Kernel: $KERNEL"

# CPU y sistema
CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')
CPU_CORES=$(nproc)
ARCH=$(uname -m)
BOOT_TIME=$(uptime -s)
VIRTUAL=$(systemd-detect-virt)
HOSTNAME=$(hostname)
print_line "${YELLOW}" "🧠 CPU: $CPU_MODEL"
print_line "${YELLOW}" "🧬 Núcleos: $CPU_CORES | Arquitectura: $ARCH | Virtualización: $VIRTUAL"
print_line "${YELLOW}" "⏱️ Último arranque: $BOOT_TIME | Hostname: $HOSTNAME"

# Memoria y carga
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/Mem:/ {print $3}')
LOAD=$(uptime | awk -F 'load average:' '{ print $2 }' | sed 's/^ //')
print_line "${BLUE}" "💾 Memoria usada: $MEM_USED de $MEM_TOTAL"
print_line "${BLUE}" "📊 Carga promedio: $LOAD"

# Disco principal
print_line "${GREEN}" "💽 Uso disco (particiones):"
df -h | grep '^/dev/' | awk '{printf "   %-20s %5s usados de %5s (%3s) en %s\n", $1, $3, $2, $5, $6}'

# Usuarios con UID 0
ROOT_USERS=$(awk -F: '$3 == 0 { print $1 }' /etc/passwd)
print_line "${RED}" "👑 Usuarios con UID 0 (root):\n   $ROOT_USERS"

# Servicios comunes
SERVICES=("apache2" "nginx" "mysql" "ssh" "ufw" "firewalld")
print_line "${CYAN}" "⚙️ Servicios críticos:"
for SVC in "${SERVICES[@]}"; do
  if systemctl list-unit-files | grep -q "^$SVC"; then
    STATUS=$(systemctl is-active "$SVC" 2>/dev/null)
    print_line "${CYAN}" "   $SVC: $STATUS"
  else
    print_line "${CYAN}" "   $SVC: no instalado"
  fi
done

# Firewall (ufw)
if command -v ufw &> /dev/null; then
  UFW_STATUS=$(sudo ufw status 2>/dev/null | head -n 1)
  print_line "${YELLOW}" "🔥 Firewall (ufw): $UFW_STATUS"
fi

# Red
IP=$(ip -4 addr show scope global | grep inet | head -1 | awk '{print $2}' | cut -d/ -f1)
GATEWAY=$(ip route | grep default | awk '{print $3}')
DNS=$(grep '^nameserver' /etc/resolv.conf | grep -v 127 | head -1 | awk '{print $2}')
print_line "${GREEN}" "🌐 IP: $IP | Gateway: $GATEWAY | DNS: ${DNS:-127.0.0.53}"

# Interfaces
print_line "${GREEN}" "📡 Interfaces de red:"
ip link show | awk -F': ' '/^[0-9]+: / {print "   " $2}' | while read -r iface; do
  STATE=$(cat /sys/class/net/$iface/operstate 2>/dev/null)
  print_line "${GREEN}" "   $iface - ${STATE^^}"
done

# Puertos abiertos
PORTS=$(ss -tuln | awk 'NR>1 {split($5,a,":"); if(a[2]!="") print a[2]; else print a[1]}' | sort -un | paste -sd ", " -)
print_line "${BLUE}" "🔌 Puertos abiertos: $PORTS"

# Procesos principales
print_line "${YELLOW}" "⚡ Procesos top (CPU y RAM):"
ps -eo pid,comm,%mem,%cpu --sort=-%cpu | head -n 6 | awk '{printf "   %-6s %-25s %5s%% %5s%%\n", $1, $2, $3, $4}'

echo -e "${CYAN}🚀 ===== Fin del diagnóstico rápido =====${NC}"
