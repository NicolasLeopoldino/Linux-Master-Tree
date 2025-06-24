#!/bin/bash

# Colores
BOLD="\e[1m"
CYAN="\e[36m"
YELLOW="\e[33m"
GREEN="\e[32m"
MAGENTA="\e[35m"
RED="\e[31m"
RESET="\e[0m"

# Iconos
OK_ICON="✅"
INFO_ICON="ℹ️"
WARN_ICON="⚠️"
TOOL_ICON="🛠️"

# Detectar sistema operativo y gestor de paquetes
detect_os() {
  if [[ -f /etc/debian_version ]]; then
    OS="Debian/Ubuntu"
    PKG_MANAGER="apt"
  elif [[ -f /etc/redhat-release ]]; then
    OS="RedHat/CentOS"
    # Preferimos dnf si está disponible
    if command -v dnf &> /dev/null; then
      PKG_MANAGER="dnf"
    else
      PKG_MANAGER="yum"
    fi
  else
    echo -e "${RED}❌ Sistema operativo no soportado.${RESET}"
    exit 1
  fi
}

# Instalar paquetes básicos
install_basic_tools() {
  echo -e "${BOLD}${CYAN}Instalando herramientas básicas...${RESET}"
  PACKAGES=(htop curl git vim net-tools wget unzip)

  echo -e "${INFO_ICON} Usando gestor de paquetes: ${YELLOW}$PKG_MANAGER${RESET}"
  echo -e "${INFO_ICON} Paquetes a instalar: ${YELLOW}${PACKAGES[*]}${RESET}"

  read -p "¿Querés continuar? [s/N]: " CONF
  CONF=${CONF,,} # to lowercase

  if [[ "$CONF" != "s" ]]; then
    echo -e "${WARN_ICON} Instalación cancelada."
    return
  fi

  sudo $PKG_MANAGER update -y

  for pkg in "${PACKAGES[@]}"; do
    echo -e "${TOOL_ICON} Instalando $pkg..."
    sudo $PKG_MANAGER install -y "$pkg"
  done

  echo -e "${GREEN}${OK_ICON} Herramientas básicas instaladas con éxito.${RESET}"
}

# Menú principal
while true; do
  clear
  detect_os
  echo -e "${MAGENTA}==============================================${RESET}"
  echo -e "${MAGENTA}  ${BOLD}🛠️ Instalador de Servicios para Sysadmin Linux${RESET}"
  echo -e "${MAGENTA}==============================================${RESET}"
  echo -e "${CYAN}Sistema detectado:${YELLOW} $OS${RESET}"
  echo
  echo -e "${YELLOW}Seleccioná una categoría:${RESET}"
  echo -e " 1) 🧰 Herramientas básicas del sistema"
  echo -e " 2) 🌐 Servicios de red (DNS, NFS, SMTP, HTTP)"
  echo -e " 3) 🔍 Monitoreo (Nagios, Centreon)"
  echo -e " 4) ☁️ Backup y almacenamiento"
  echo -e " 5) 🔐 Seguridad y acceso (Firewall, Fail2ban, SSH)"
  echo -e " 6) 🧪 Virtualización (KVM, libvirt, bridge)"
  echo -e " 7) ❌ Salir"
  echo -ne "\nIngresá opción: "
  read -r OPTION

  case $OPTION in
    1)
      install_basic_tools
      ;;
    2|3|4|5|6)
      echo -e "${WARN_ICON} 🔧 Esta función será agregada próximamente..."
      ;;
    7)
      echo -e "${GREEN}Saliendo...${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ Opción inválida, intentá de nuevo.${RESET}"
      ;;
  esac

  echo -e "\nPresioná ENTER para continuar..."
  read -r
done

