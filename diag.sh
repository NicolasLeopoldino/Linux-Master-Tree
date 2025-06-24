#!/bin/bash

# Colores mejorados
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

print_line() {
  echo -e "$1$2${NC}"
}

echo -e "${MAGENTA}🚀 ===== Diagnóstico rápido del sistema =====${NC}"

# Usuario actual, evitando sobrescribir UID del shell
USER=$(whoami)
USER_UID=$(id -u)
GROUPS=$(id -nG)
print_line "${BLUE}" "👤 Usuario: ${GREEN}$USER${NC} (UID ${YELLOW}$USER_UID${NC}), Grupos: ${CYAN}$GROUPS"

# OS y kernel
OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
KERNEL=$(uname -r)
print_line "${GREEN}" "💻 OS: ${YELLOW}$OS${NC} | Kernel: ${CYAN}$KERNEL"

# CPU modelo y núcleos
CPU_MODEL=$(lscpu | grep 'Model name' | cut -d: -f2- | sed 's/^ *//')
CPU_CORES=$(lscpu | grep '^CPU(s):' | head -1 | awk '{print $2}')

# CPU MHz (con fallback)
CPU_FREQ=$(lscpu | grep 'CPU MHz' | awk '{print $3 " MHz"}')
if [ -z "$CPU_FREQ" ]; then
  CPU_FREQ=$(awk -F: '/cpu MHz/ {print $2; exit}' /proc/cpuinfo | sed 's/^ *//')
  CPU_FREQ="${CPU_FREQ} MHz"
fi
print_line "${YELLOW}" "🧠 CPU: ${GREEN}$CPU_MODEL${NC} | Núcleos: ${CYAN}$CPU_CORES${NC} | Frecuencia: ${MAGENTA}$CPU_FREQ"

# Memoria
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/Mem:/ {print $3}')
print_line "${BLUE}" "💾 Memoria usada: ${GREEN}$MEM_USED${NC} de ${YELLOW}$MEM_TOTAL"

# Carga promedio
LOAD=$(uptime | awk -F 'load average:' '{ print $2 }' | sed 's/^ //')
print_line "${MAGENTA}" "📊 Carga promedio: ${CYAN}$LOAD"

# Disco y particiones
print_line "${YELLOW}" "💽 Uso disco (particiones):"
df -h --output=source,size,used,avail,pcent,target | grep -v tmpfs | grep -v devtmpfs | while read -r line; do
  echo -e "   ${GREEN}$line${NC}"
done

# Usuarios con UID 0
print_line "${RED}" "👑 Usuarios con UID 0 (root):"
awk -F: '($3 == 0) {print "   " $1}' /etc/passwd

# Servicios críticos (probamos nombres alternativos para ssh)
SERVICIOS=("apache2" "nginx" "mysql" "ssh" "sshd" "ufw" "firewalld")
print_line "${GREEN}" "⚙️ Servicios críticos:"
for serv in "${SERVICIOS[@]}"; do
  if systemctl list-units --type=service --all | grep -q "^${serv}.service"; then
    status=$(systemctl is-active "$serv" 2>/dev/null)
    color="${YELLOW}"
    [ "$status" == "active" ] && color="${GREEN}"
    print_line "$color" "   $serv: $status"
  else
    print_line "${RED}" "   $serv: no instalado"
  fi
done

# Firewall status (sin root no mostrar error)
if command -v ufw &> /dev/null; then
  print_line "${GREEN}" "🔥 Firewall (ufw):"
  if ufw status | grep -q "Status: active"; then
    ufw status verbose | sed 's/^/   /'
  else
    echo "   Firewall ufw no activo"
  fi
elif command -v firewall-cmd &> /dev/null; then
  print_line "${GREEN}" "🔥 Firewall (firewalld):"
  if firewall-cmd --state &> /dev/null; then
    firewall-cmd --list-all | sed 's/^/   /'
  else
    echo "   firewall-cmd no activo"
  fi
else
  print_line "${YELLOW}" "⚠️ Firewall no detectado (ufw/firewalld)"
fi

# Red: IP, gateway, DNS
IP=$(ip -4 addr show scope global | grep inet | head -1 | awk '{print $2}' | cut -d/ -f1)
GATEWAY=$(ip route | grep default | awk '{print $3}')
DNS=$(grep '^nameserver' /etc/resolv.conf | head -1 | awk '{print $2}')
print_line "${CYAN}" "🌐 Red:"
echo -e "   IP: ${GREEN}$IP${NC}"
echo -e "   Gateway: ${YELLOW}$GATEWAY${NC}"
echo -e "   DNS: ${MAGENTA}$DNS${NC}"

# Interfaces de red
print_line "${CYAN}" "📡 Interfaces de red:"
ip -br link show | while read -r iface status _; do
  print_line "${GREEN}" "   $iface - $status"
done

# Puertos abiertos - corregido para mostrar sólo números y protocolo tcp/udp
PORTS=$(ss -tuln | tail -n +2 | awk '{print $1, $5}' | awk -F'[ :]' '{if($1=="tcp"||$1=="udp"){print $1"/"$NF}}' | sort -u | paste -sd ", " -)
print_line "${RED}" "🔌 Puertos abiertos:"
echo "   $PORTS"

# Procesos top CPU y RAM
print_line "${MAGENTA}" "⚡ Procesos top (CPU y RAM):"
ps -eo pid,cmd,%mem,%cpu --sort=-%cpu | head -6 | sed 's/^/   /'

echo -e "${MAGENTA}🚀 ===== Fin del diagnóstico rápido =====${NC}"
