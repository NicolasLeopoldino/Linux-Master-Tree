#!/bin/bash

while true; do
  clear
  echo "🚀 Menú de Scripts - Seleccioná una opción:"
  echo "1) Diagnóstico básico"
  echo "2) Otro script (poner nombre)"
  echo "3) Salir"
  echo -n "Ingresá opción: "
  read opcion

  case $opcion in
    1)
      ./diag.sh
      echo -e "\nPresioná ENTER para volver al menú..."
      read
      ;;
    2)
      echo "Opción 2 - Aún no implementada"
      echo -e "\nPresioná ENTER para volver al menú..."
      read
      ;;
    3)
      echo "Saliendo..."
      exit 0
      ;;
    *)
      echo "Opción inválida"
      sleep 1
      ;;
  esac
done
