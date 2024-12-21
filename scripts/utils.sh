#!/bin/bash

# Warna teks
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m" # No Color

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
