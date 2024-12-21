#!/bin/bash

# Proteksi agar hanya bisa dijalankan dari setup.sh
if [ "$IS_SETUP_SH" != "$(echo 'secure_hash_value' | sha256sum | awk '{print $1}')" ]; then
  echo -e "\033[0;31m[ERROR] File ini hanya bisa dijalankan dari setup.sh.\033[0m"
  exit 1
fi

# Fungsi memperbarui sistem
update_system() {
  echo -e "${BLUE}Memperbarui indeks paket...${NC}"
  check_internet || return
  sudo apt update
  if [ $? -eq 0 ]; then
    print_success "Sistem diperbarui."
  else
    print_error "Gagal memperbarui sistem."
    attempt_fix
  fi
}
