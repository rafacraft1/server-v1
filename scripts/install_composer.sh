#!/bin/bash

# Proteksi agar hanya bisa dijalankan dari setup.sh
if [ "$IS_SETUP_SH" != "$(echo 'secure_hash_value' | sha256sum | awk '{print $1}')" ]; then
  echo -e "\033[0;31m[ERROR] File ini hanya bisa dijalankan dari setup.sh.\033[0m"
  exit 1
fi

install_composer() {
  print_status "${BLUE}Menginstal Composer...${NC}"

  # Memeriksa koneksi internet
  check_internet || return

  # Memastikan curl terinstal
  print_status "${BLUE}Memeriksa apakah 'curl' tersedia...${NC}"
  if ! command -v curl &> /dev/null; then
    sudo apt install curl -y &> /dev/null
    if [ $? -ne 0 ]; then
      print_error "Gagal menginstal 'curl'. Instalasi Composer dihentikan."
      return
    fi
  fi
  print_success "'curl' tersedia."

  # Mengunduh installer Composer
  print_status "${BLUE}Mengunduh installer Composer...${NC}"
  curl -sS https://getcomposer.org/installer -o composer-setup.php
  if [ $? -ne 0 ]; then
    print_error "Gagal mengunduh installer Composer. Periksa koneksi internet Anda."
    return
  fi

  # Memverifikasi hash installer
  print_status "${BLUE}Memverifikasi integritas installer...${NC}"
  HASH_EXPECTED=$(curl -sS https://composer.github.io/installer.sig)
  HASH_ACTUAL=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")
  if [ "$HASH_EXPECTED" != "$HASH_ACTUAL" ]; then
    print_error "Hash installer tidak cocok. Instalasi Composer dihentikan."
    rm -f composer-setup.php
    return
  fi
  print_success "Installer Composer tervalidasi."

  # Menjalankan installer Composer
  print_status "${BLUE}Menjalankan installer Composer...${NC}"
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer &> /dev/null
  if [ $? -eq 0 ]; then
    print_success "Composer berhasil diinstal."
  else
    print_error "Gagal menginstal Composer. Mencoba memperbaiki..."
    attempt_fix
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer &> /dev/null
    if [ $? -eq 0 ]; then
      print_success "Composer berhasil diinstal setelah perbaikan."
    else
      print_error "Instalasi Composer tetap gagal. Periksa error log untuk detail."
    fi
  fi

  # Membersihkan file installer
  rm -f composer-setup.php
}
