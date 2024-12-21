#!/bin/bash

if [ "$IS_SETUP_SH" != "$(echo 'secure_hash_value' | sha256sum | awk '{print $1}')" ]; then
  echo -e "\033[0;31m[ERROR] File ini hanya bisa dijalankan dari setup.sh.\033[0m"
  exit 1
fi

install_apache2() {
  print_status "${BLUE}Menginstal Apache2...${NC}"
  check_internet || return
  sudo apt install apache2 -y &> /dev/null
  if [ $? -eq 0 ]; then
    print_success "Apache2 berhasil diinstal."
  else
    print_status "${RED}Gagal menginstal Apache2. Mencoba memperbaiki...${NC}"
    attempt_fix
    sudo apt install apache2 -y &> /dev/null
    if [ $? -eq 0 ]; then
      print_success "Apache2 berhasil diinstal setelah perbaikan."
    else
      print_error "Instalasi Apache2 tetap gagal."
    fi
  fi
}
