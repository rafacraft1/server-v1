#!/bin/bash

if [ "$IS_SETUP_SH" != "$(echo 'secure_hash_value' | sha256sum | awk '{print $1}')" ]; then
  echo -e "\033[0;31m[ERROR] File ini hanya bisa dijalankan dari setup.sh.\033[0m"
  exit 1
fi

update_system() {
  print_status "${BLUE}Memperbarui indeks paket...${NC}"
  check_internet || return
  sudo apt update &> /dev/null
  if [ $? -eq 0 ]; then
    print_success "Indeks paket berhasil diperbarui."
  else
    print_error "Gagal memperbarui indeks paket."
    attempt_fix
  fi
}
