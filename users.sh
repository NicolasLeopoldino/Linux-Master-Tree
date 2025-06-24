#!/bin/bash

# Control de Usuarios - Script interactivo para gestión básica de usuarios
# Necesita ejecutarse con permisos root para modificar usuarios y grupos

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
ERROR_ICON="❌"

# Función para pedir confirmación (default No)
confirm() {
  read -r -p "$(echo -e "${ASK_ICON} $1 [s/N]: ")" response
  case "$response" in
    [sS]) true ;;
    *) false ;;
  esac
}

# Mostrar usuarios normales con estado sudo
list_users() {
  echo -e "${BOLD}${CYAN}Usuarios normales en el sistema:${RESET}"
  echo "--------------------------------------"
  awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd | while read -r user; do
    if id -nG "$user" | grep -qw "sudo"; then
      sudo_status="${GREEN}Sí${RESET}"
    else
      sudo_status="${RED}No${RESET}"
    fi
    echo -e "Usuario: ${YELLOW}$user${RESET} | Sudo: $sudo_status"
  done
  echo
}

# Crear nuevo usuario
create_user() {
  echo -e "${BOLD}${CYAN}Crear nuevo usuario${RESET}"
  while true; do
    read -rp "Ingresá nombre de usuario: " username
    if [[ -z "$username" ]]; then
      echo -e "${WARN_ICON} El nombre no puede estar vacío."
      continue
    fi
    if id "$username" &>/dev/null; then
      echo -e "${WARN_ICON} El usuario '$username' ya existe."
      continue
    fi
    break
  done

  read -rp "¿El usuario tendrá permisos sudo? [s/N]: " sudoresp
  sudoresp=${sudoresp,,} # lowercase
  if [[ "$sudoresp" == "s" ]]; then
    wantsudo=true
  else
    wantsudo=false
  fi

  echo "Creando usuario '$username'..."
  useradd -m -s /bin/bash "$username"
  if [[ $? -ne 0 ]]; then
    echo -e "${ERROR_ICON} Error al crear el usuario."
    return
  fi

  # Setear contraseña
  while true; do
    read -rsp "Ingresá contraseña para '$username': " pass1
    echo
    read -rsp "Repetí la contraseña: " pass2
    echo
    if [[ "$pass1" != "$pass2" ]]; then
      echo -e "${WARN_ICON} Las contraseñas no coinciden. Intentá de nuevo."
    elif [[ -z "$pass1" ]]; then
      echo -e "${WARN_ICON} La contraseña no puede estar vacía."
    else
      echo "$username:$pass1" | chpasswd
      break
    fi
  done

  # Agregar a sudo si pidió
  if $wantsudo; then
    usermod -aG sudo "$username"
    echo -e "${OK_ICON} Usuario '$username' creado y agregado a sudo."
  else
    echo -e "${OK_ICON} Usuario '$username' creado."
  fi
}

# Modificar permisos sudo
modify_sudo() {
  echo -e "${BOLD}${CYAN}Modificar permisos sudo${RESET}"

  echo -e "Usuarios con sudo:"
  mapfile -t sudo_users < <(awk -F: '$3 >= 1000 {print $1}' /etc/passwd | while read -r u; do id -nG "$u" | grep -qw sudo && echo "$u"; done)
  if [[ ${#sudo_users[@]} -eq 0 ]]; then
    echo "  Ninguno"
  else
    for u in "${sudo_users[@]}"; do echo "  - $u"; done
  fi

  echo -e "\nUsuarios sin sudo:"
  mapfile -t non_sudo_users < <(awk -F: '$3 >= 1000 {print $1}' /etc/passwd | while read -r u; do id -nG "$u" | grep -qw sudo || echo "$u"; done)
  if [[ ${#non_sudo_users[@]} -eq 0 ]]; then
    echo "  Ninguno"
  else
    for u in "${non_sudo_users[@]}"; do echo "  - $u"; done
  fi
  echo

  read -rp "Ingresá el nombre del usuario a modificar permisos sudo (vacío para cancelar): " usermod
  if [[ -z "$usermod" ]]; then
    echo "Operación cancelada."
    return
  fi
  if ! id "$usermod" &>/dev/null; then
    echo -e "${ERROR_ICON} Usuario no existe."
    return
  fi

  if id -nG "$usermod" | grep -qw sudo; then
    if confirm "El usuario tiene sudo. ¿Querés quitarle sudo?"; then
      deluser "$usermod" sudo && echo -e "${OK_ICON} sudo quitado a $usermod"
    else
      echo "No se hicieron cambios."
    fi
  else
    if confirm "El usuario NO tiene sudo. ¿Querés agregarle sudo?"; then
      usermod -aG sudo "$usermod" && echo -e "${OK_ICON} sudo agregado a $usermod"
    else
      echo "No se hicieron cambios."
    fi
  fi
}

# Cambiar contraseña
change_password() {
  echo -e "${BOLD}${CYAN}Cambiar contraseña de usuario${RESET}"
  read -rp "Ingresá nombre de usuario: " userpass
  if ! id "$userpass" &>/dev/null; then
    echo -e "${ERROR_ICON} Usuario no existe."
    return
  fi
  while true; do
    read -rsp "Nueva contraseña: " pass1
    echo
    read -rsp "Repetir contraseña: " pass2
    echo
    if [[ "$pass1" != "$pass2" ]]; then
      echo -e "${WARN_ICON} Las contraseñas no coinciden."
    elif [[ -z "$pass1" ]]; then
      echo -e "${WARN_ICON} La contraseña no puede estar vacía."
    else
      echo "$userpass:$pass1" | chpasswd
      echo -e "${OK_ICON} Contraseña cambiada."
      break
    fi
  done
}

# Eliminar usuario
delete_user() {
  echo -e "${BOLD}${CYAN}Eliminar usuario${RESET}"
  echo "Usuarios normales:"
  awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd
  echo
  read -rp "Ingresá usuario a eliminar (vacío para cancelar): " userdel
  if [[ -z "$userdel" ]]; then
    echo "Operación cancelada."
    return
  fi
  if ! id "$userdel" &>/dev/null; then
    echo -e "${ERROR_ICON} Usuario no existe."
    return
  fi
  if confirm "¿Querés eliminar al usuario '$userdel' y su home?"; then
    userdel -r "$userdel" && echo -e "${OK_ICON} Usuario eliminado."
  else
    echo "No se hicieron cambios."
  fi
}

# Mostrar usuarios conectados
show_logged_users() {
  echo -e "${BOLD}${CYAN}Usuarios conectados actualmente:${RESET}"
  who
  echo
}

# Menú principal
while true; do
  echo -e "${BOLD}${CYAN}👥 Control de Usuarios${RESET}"
  echo "---------------------------------------"
  echo -e "${YELLOW}1)${RESET} Ver usuarios del sistema"
  echo -e "${YELLOW}2)${RESET} Crear nuevo usuario"
  echo -e "${YELLOW}3)${RESET} Modificar permisos sudo"
  echo -e "${YELLOW}4)${RESET} Cambiar contraseña de usuario"
  echo -e "${YELLOW}5)${RESET} Eliminar usuario"
  echo -e "${YELLOW}6)${RESET} Mostrar usuarios conectados"
  echo -e "${YELLOW}7)${RESET} Salir"
  echo -ne "\nIngresá opción: "
  read -r option
  echo

  case $option in
    1) list_users ;;
    2) create_user ;;
    3) modify_sudo ;;
    4) change_password ;;
    5) delete_user ;;
    6) show_logged_users ;;
    7)
      echo -e "${GREEN}Saliendo...${RESET}"
      exit 0
      ;;
    *)
      echo -e "${ERROR_ICON} Opción inválida, intentá de nuevo."
      ;;
  esac
  echo -e "\nPresioná ENTER para continuar..."
  read -r
  clear
done
