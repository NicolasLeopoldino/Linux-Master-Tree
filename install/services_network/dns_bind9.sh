#!/bin/bash

# Colores
BOLD="\e[1m"
CYAN="\e[36m"
YELLOW="\e[33m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

OK_ICON="✅"
WARN_ICON="⚠️"
INFO_ICON="ℹ️"

detect_os() {
  if [[ -f /etc/debian_version ]]; then
    OS="Debian/Ubuntu"
    PKG_MANAGER="apt"
    SERVICE_NAME="bind9"
  elif [[ -f /etc/redhat-release ]]; then
    OS="RedHat/CentOS"
    if command -v dnf &> /dev/null; then
      PKG_MANAGER="dnf"
    else
      PKG_MANAGER="yum"
    fi
    SERVICE_NAME="named"
  else
    echo -e "${RED}❌ Sistema operativo no soportado.${RESET}"
    exit 1
  fi
}

install_bind9() {
  echo -e "${INFO_ICON} Instalando bind9 y dependencias..."
  sudo $PKG_MANAGER update -y
  sudo $PKG_MANAGER install -y bind9 bind9utils bind9-doc dnsutils || {
    echo -e "${RED}Error instalando paquetes.${RESET}"
    return 1
  }
  echo -e "${GREEN}${OK_ICON} bind9 instalado correctamente.${RESET}"
}

configure_bind9() {
  echo -e "${INFO_ICON} Configuración básica del DNS interno"

  ZONE_DIR="/etc/bind/zones"
  ZONE_FILE="$ZONE_DIR/db.empresa.local"
  NAMED_CONF_LOCAL="/etc/bind/named.conf.local"

  sudo mkdir -p "$ZONE_DIR"

  echo -e "${WARN_ICON} Se creará la zona 'empresa.local' con registros básicos."

  read -p "¿Querés continuar con la configuración básica? [s/N]: " CONF
  CONF=${CONF,,}
  if [[ "$CONF" != "s" ]]; then
    echo -e "${WARN_ICON} Configuración cancelada."
    return
  fi

  # Backup de archivos originales (si existen)
  [ -f "$ZONE_FILE" ] && sudo cp "$ZONE_FILE" "${ZONE_FILE}.bak_$(date +%F_%T)"
  [ -f "$NAMED_CONF_LOCAL" ] && sudo cp "$NAMED_CONF_LOCAL" "${NAMED_CONF_LOCAL}.bak_$(date +%F_%T)"

  # Crear archivo de zona
  sudo tee "$ZONE_FILE" > /dev/null << EOF
\$TTL 86400
@   IN  SOA ns1.empresa.local. admin.empresa.local. (
        $(date +%Y%m%d01) ; Serial
        3600       ; Refresh
        1800       ; Retry
        604800     ; Expire
        86400      ; Negative Cache TTL
)
; Nameservers
@       IN  NS      ns1.empresa.local.

; Servidor DNS
ns1     IN  A       192.168.1.10

; Hosts internos
servidor-archivos    IN  A   192.168.1.20
servidor-web         IN  A   192.168.1.30
servidor-mail        IN  A   192.168.1.40
EOF

  # Añadir configuración a named.conf.local si no está
  if ! sudo grep -q "zone \"empresa.local\"" "$NAMED_CONF_LOCAL"; then
    echo "zone \"empresa.local\" {" | sudo tee -a "$NAMED_CONF_LOCAL" > /dev/null
    echo "    type master;" | sudo tee -a "$NAMED_CONF_LOCAL" > /dev/null
    echo "    file \"$ZONE_FILE\";" | sudo tee -a "$NAMED_CONF_LOCAL" > /dev/null
    echo "};" | sudo tee -a "$NAMED_CONF_LOCAL" > /dev/null
  fi

  # Validar configuración antes de reiniciar
  if ! sudo named-checkconf; then
    echo -e "${RED}Error en la configuración de named.conf. No se reiniciará el servicio.${RESET}"
    return 1
  fi
  if ! sudo named-checkzone empresa.local "$ZONE_FILE"; then
    echo -e "${RED}Error en el archivo de zona. No se reiniciará el servicio.${RESET}"
    return 1
  fi

  # Reiniciar servicio
  sudo systemctl restart "$SERVICE_NAME" && \
    echo -e "${GREEN}${OK_ICON} Configuración aplicada y servicio reiniciado.${RESET}" || \
    echo -e "${RED}No se pudo reiniciar el servicio.${RESET}"
}

uninstall_bind9() {
  echo -e "${WARN_ICON} Esto eliminará bind9 y toda su configuración. ¿Querés continuar? [s/N]: "
  read -r CONF
  CONF=${CONF,,}
  if [[ "$CONF" != "s" ]]; then
    echo -e "${INFO_ICON} Desinstalación cancelada."
    return
  fi

  sudo systemctl stop "$SERVICE_NAME"
  sudo $PKG_MANAGER remove -y bind9 bind9utils bind9-doc dnsutils

  # En Debian a veces queda bind9 en autoremove
  sudo $PKG_MANAGER autoremove -y

  # Borrar configuraciones (ajustar según OS)
  echo -e "${INFO_ICON} Eliminando archivos de configuración..."
  if [[ "$OS" == "Debian/Ubuntu" ]]; then
    sudo rm -rf /etc/bind
  else
    sudo rm -rf /etc/named*
  fi

  echo -e "${GREEN}${OK_ICON} bind9 desinstalado completamente.${RESET}"
}

show_menu() {
  detect_os

  while true; do
    clear
    echo -e "${BOLD}${CYAN}🌐 Configuración y administración de DNS (bind9)${RESET}"
    echo "1) Instalar bind9"
    echo "2) Configurar DNS interno básico"
    echo "3) Desinstalar bind9 completamente"
    echo "4) Volver"
    echo -n "Ingresá opción: "
    read -r option

    case $option in
      1) install_bind9 ;;
      2) configure_bind9 ;;
      3) uninstall_bind9 ;;
      4) break ;;
      *) echo -e "${RED}Opción inválida${RESET}"; sleep 1 ;;
    esac

    echo -e "\nPresioná ENTER para continuar..."
    read
  done
}

show_menu
