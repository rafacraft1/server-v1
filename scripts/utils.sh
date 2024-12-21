#!/bin/bash

# Warna teks
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m" # No Color

# Waktu tunggu default
DEFAULT_TIMEOUT=10

# Fungsi mencetak status proses dalam satu baris
print_status() {
  echo -ne "\r$1"  # Menimpa baris yang sama
}

# Fungsi mencetak pesan sukses
print_success() {
  echo -e "\r${GREEN}[SUKSES] $1${NC}"  # Menimpa baris terakhir dengan pesan sukses
}

# Fungsi mencetak pesan error
print_error() {
  echo -e "\r${RED}[ERROR] $1${NC}"  # Menimpa baris terakhir dengan pesan error
}

# Fungsi memeriksa koneksi internet
check_internet() {
  local test_sites=("google.com" "ubuntu.com" "github.com")
  for site in "${test_sites[@]}"; do
    ping -c 1 "$site" &> /dev/null
    if [ $? -eq 0 ]; then
      return 0
    fi
  done
  print_error "Koneksi internet tidak tersedia. Pastikan Anda terhubung ke internet."
  return 1
}

# Fungsi memperbaiki masalah instalasi
attempt_fix() {
  print_status "${BLUE}Mencoba memperbaiki masalah instalasi...${NC}"
  sudo apt --fix-broken install -y &> /dev/null
  if [ $? -eq 0 ]; then
    print_success "Masalah berhasil diperbaiki dengan 'fix-broken'."
    return 0
  fi
  sudo dpkg --configure -a &> /dev/null
  if [ $? -eq 0 ]; then
    print_success "Masalah berhasil diperbaiki dengan 'dpkg --configure'."
    return 0
  fi
  print_error "Gagal memperbaiki masalah secara otomatis. Periksa error log untuk detail."
  return 1
}

# Fungsi meminta perpanjangan waktu tunggu
prompt_extend_time() {
  read -p "Apakah Anda ingin memperpanjang waktu tunggu? (y/n): " answer
  case $answer in
    [Yy]*) return 0 ;;
    *) return 1 ;;
  esac
}
