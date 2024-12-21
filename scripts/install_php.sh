#!/bin/bash

if [ "$IS_SETUP_SH" != "$(echo 'secure_hash_value' | sha256sum | awk '{print $1}')" ]; then
  echo -e "\033[0;31m[ERROR] File ini hanya bisa dijalankan dari setup.sh.\033[0m"
  exit 1
fi

install_php() {
  print_status "${BLUE}Menginstal PHP 8.x...${NC}"
  check_internet || return
  sudo apt install php8.1 -y &> /dev/null
  if [ $? -eq 0 ]; then
    print_success "PHP 8.x berhasil diinstal."
  else
    print_status "${RED}Gagal menginstal PHP. Mencoba memperbaiki...${NC}"
    attempt_fix
    sudo apt install php8.1 -y &> /dev/null
    if [ $? -eq 0 ]; then
      print_success "PHP 8.x berhasil diinstal setelah perbaikan."
    else
      print_error "Instalasi PHP tetap gagal."
    fi
  fi
}
