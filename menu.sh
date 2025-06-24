#!/bin/bash

# Colores
BOLD="\e[1m"
CYAN="\e[36m"
MAGENTA="\e[35m"
YELLOW="\e[33m"
RESET="\e[0m"
RED="\e[31m"

while true; do
  clear
  echo -e "${MAGENTA}╔══════════════════════════════╗${RESET}"
  echo -e "${MAGENTA}║${CYAN} 🚀 Menú de Scripts            ${MAGENTA}║${RESET}"
  echo -e "${MAGENTA}╠══════════════════════════════╣${RESET}"
  echo -e "${MAGENTA}║${YELLOW} 1) Diagnóstico básico      🩺 ${MAGENTA}║${RESET}"
  echo -e "${MAGENTA}║${YELLOW} 2) Mantenimiento seguro   🧹 ${MAGENTA}║${RESET}"
  echo -e "${MAGENTA}║${YELLOW} 3) Salir                  🚪 ${MAGENTA}║${RESET}"
  echo -e "${MAGENTA}╚══════════════════════════════╝${RESET}"
  echo -ne "\nIngresá opción: ${BOLD}${CYAN}"
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
      echo -e "${RED}Saliendo...${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ Opción inválida${RESET}"
      sleep 1
      ;;
  esac
done
