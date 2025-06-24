#!/bin/bash

# Colores
BOLD="\e[1m"
CYAN="\e[36m"
YELLOW="\e[33m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

while true; do
  clear
  echo -e "${BOLD}${CYAN}🌐 Menú Servicios de Red${RESET}"
  echo "1) DNS (bind9)"
  echo "2) NFS"
  echo "3) SMTP (Postfix)"
  echo "4) HTTP (Apache / Nginx)"
  echo "5) Volver"

  echo -n "Ingresá opción: "
  read -r option

  case $option in
    1)
      ./install/services_network/dns_bind9.sh
      ;;
    2)
      ./install/services_network/nfs.sh
      ;;
    3)
      ./install/services_network/postfix.sh
      ;;
    4)
      ./install/services_network/webserver.sh
      ;;
    5)
      break
      ;;
    *)
      echo -e "${RED}Opción inválida${RESET}"
      sleep 1
      ;;
  esac

  echo -e "\nPresioná ENTER para continuar..."
  read
done

