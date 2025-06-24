#!/bin/bash

# Colores
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
BOLD="\e[1m"
RESET="\e[0m"

# Iconos
DIAG_ICON="🩺"
MAINT_ICON="🧹"
EXIT_ICON="🚪"
ERROR_ICON="❌"

while true; do
  clear
  echo -e "${BOLD}${CYAN}🚀 Menú de Scripts - Seleccioná una opción:${RESET}"
  echo -e " 1) ${DIAG_ICON} Diagnóstico básico"
  echo -e " 2) ${MAINT_ICON} Mantenimiento seguro"
  echo -e " 3) ${EXIT_ICON} Salir"
  echo -ne "\nIngresá opción: ${YELLOW}"
  read -r opcion
  echo -e "${RESET}"

  case $opcion in
    1)
      ./diag.sh
      echo -e "\nPresioná ENTER para volver al menú..."
      read
      ;;
    2)
      ./maintenance.sh
      echo -e "\nPresioná ENTER para volver al menú..."
      read
      ;;
    3)
      echo -e "${GREEN}Saliendo...${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}${ERROR_ICON} Opción inválida${RESET}"
      sleep 1
      ;;
  esac
done
