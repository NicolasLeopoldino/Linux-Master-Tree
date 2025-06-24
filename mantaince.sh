#!/bin/bash

set -e

# Colores
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# Iconos
OK_ICON="✅"
WARN_ICON="⚠️"
INFO_ICON="ℹ️"
ASK_ICON="❓"

function echo_info() {
  echo -e "${CYAN}${INFO_ICON} $1${RESET}"
}
function echo_ok() {
  echo -e "${GREEN}${OK_ICON} $1${RESET}"
}
function echo_warn() {
  echo -e "${YELLOW}${WARN_ICON} $1${RESET}"
}
function echo_error() {
  echo -e "${RED}${RED}✖ $1${RESET}"
}

function confirm() {
  read -r -p "$(echo -e ${ASK_ICON} "$1 [s/N]: ")" response
  case "$response" in
    [sS]) true ;;
    *) false ;;
  esac
}

echo -e "${BOLD}${CYAN}===== Mantenimiento seguro del sistema =====${RESET}\n"

echo_info "Acciones propuestas:"
echo_info "1. Limpiar cachés temporales (/tmp y cachés de paquetes)"
echo_info "2. Eliminar thumbnails y cachés de navegadores (opcional)"
echo_info "3. Detectar y listar paquetes huérfanos"
echo_info "4. Optimizar discos SSD (fstrim)"
echo_info "5. Mostrar actualizaciones pendientes (no instalar)"
echo_info "6. Rotar logs con journalctl"
echo

if ! confirm "¿Desea continuar?"; then
  echo_warn "Mantenimiento cancelado por el usuario."
  exit 1
fi

echo
echo_info "Limpiando /tmp (archivos temporales mayores a 7 días)..."
find /tmp -type f -mtime +7 -exec rm -f {} \; 2>/dev/null || true
echo_ok "Limpieza /tmp completada."
echo

function clean_pkg_cache() {
  if command -v apt >/dev/null 2>&1; then
    echo_info "Limpiando caché de APT..."
    sudo apt-get clean
    echo_ok "Caché de APT limpiada."
  elif command -v dnf >/dev/null 2>&1; then
    echo_info "Limpiando caché de DNF..."
    sudo dnf clean all
    echo_ok "Caché de DNF limpiada."
  elif command -v pacman >/dev/null 2>&1; then
    echo_info "Limpiando caché de Pacman..."
    sudo pacman -Scc --noconfirm
    echo_ok "Caché de Pacman limpiada."
  else
    echo_warn "No se detectó gestor de paquetes compatible para limpiar caché."
  fi
}

clean_pkg_cache
echo

if confirm "¿Desea eliminar cachés y thumbnails de navegadores (Chrome, Firefox) y sistema?"; then
  echo_info "Limpiando cachés de navegadores y thumbnails..."
  rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
  rm -rf ~/.cache/mozilla/firefox/*/cache2/* 2>/dev/null || true
  rm -rf ~/.cache/google-chrome/*/Cache/* 2>/dev/null || true
  rm -rf ~/.cache/chromium/*/Cache/* 2>/dev/null || true
  echo_ok "Cachés de navegadores limpiados."
else
  echo_warn "Se omitió limpieza de cachés de navegadores."
fi
echo

echo_info "Detectando paquetes huérfanos..."
orphans=""
if command -v apt >/dev/null 2>&1; then
  orphans=$(deborphan 2>/dev/null || echo "")
elif command -v dnf >/dev/null 2>&1; then
  orphans=$(dnf repoquery --unneeded 2>/dev/null || echo "")
elif command -v pacman >/dev/null 2>&1; then
  orphans=$(pacman -Qtdq 2>/dev/null || echo "")
else
  echo_warn "No se detectó gestor de paquetes compatible para detectar huérfanos."
fi

if [[ -z "$orphans" ]]; then
  echo_ok "No se encontraron paquetes huérfanos."
else
  echo_warn "Se encontraron los siguientes paquetes huérfanos:"
  echo "$orphans"
  if confirm "¿Desea eliminar estos paquetes huérfanos?"; then
    if command -v apt >/dev/null 2>&1; then
      sudo apt-get purge -y $orphans
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf remove -y $orphans
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Rns --noconfirm $orphans
    fi
    echo_ok "Paquetes huérfanos eliminados."
  else
    echo_warn "Se omitió eliminación de paquetes huérfanos."
  fi
fi
echo

echo_info "Ejecutando fstrim en discos montados (SSD)..."
if sudo fstrim -av; then
  echo_ok "fstrim completado."
else
  echo_warn "No se pudo ejecutar fstrim o no es compatible."
fi
echo

echo_info "Mostrando actualizaciones pendientes (no se instalan):"
if command -v apt >/dev/null 2>&1; then
  sudo apt-get update >/dev/null
  apt list --upgradable
elif command -v dnf >/dev/null 2>&1; then
  dnf check-update
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -Sy >/dev/null
  pacman -Qu
else
  echo_warn "No se detectó gestor de paquetes compatible."
fi
echo

echo_info "Rotando logs con journalctl (limitar a 100M)..."
if sudo journalctl --vacuum-size=100M; then
  echo_ok "Rotación de logs completada."
else
  echo_warn "No se pudo rotar logs o no se tiene acceso."
fi
echo

echo -e "${GREEN}${BOLD}Mantenimiento finalizado.${RESET}"
