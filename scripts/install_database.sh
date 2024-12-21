#!/bin/bash

if [ "$IS_SETUP_SH" != "$(echo 'secure_hash_value' | sha256sum | awk '{print $1}')" ]; then
  echo -e "\033[0;31m[ERROR] File ini hanya bisa dijalankan dari setup.sh.\033[0m"
  exit 1
fi

install_database() {
  echo -e "\n${BLUE}Pilih jenis database yang ingin diinstal:${NC}"
  echo -e "1) MySQL"
  echo -e "2) PostgreSQL"
  echo -e "3) Kembali ke menu utama"
  read -t $DEFAULT_TIMEOUT -p "Masukkan pilihan Anda: " db_choice

  if [ $? -ne 0 ]; then
    echo -e "\n${RED}Waktu habis.${NC}"
    if prompt_extend_time; then
      install_database
    else
      return
    fi
  fi

  case $db_choice in
    1)
      install_mysql ;;
    2)
      install_postgresql ;;
    3)
      return ;;
    *)
      print_error "Pilihan tidak valid."
      install_database
      ;;
  esac
}

install_mysql() {
  print_status "${BLUE}Menginstal MySQL...${NC}"
  check_internet || return

  sudo apt install mysql-server -y &> /dev/null
  if [ $? -eq 0 ]; then
    print_success "MySQL berhasil diinstal."
    secure_mysql
  else
    print_error "Gagal menginstal MySQL. Mencoba memperbaiki..."
    attempt_fix
    sudo apt install mysql-server -y &> /dev/null
    if [ $? -eq 0 ]; then
      print_success "MySQL berhasil diinstal setelah perbaikan."
      secure_mysql
    else
      print_error "Instalasi MySQL tetap gagal."
    fi
  fi
}

install_postgresql() {
  print_status "${BLUE}Menginstal PostgreSQL...${NC}"
  check_internet || return

  sudo apt install postgresql postgresql-contrib -y &> /dev/null
  if [ $? -eq 0 ]; then
    print_success "PostgreSQL berhasil diinstal."
  else
    print_error "Gagal menginstal PostgreSQL. Mencoba memperbaiki..."
    attempt_fix
    sudo apt install postgresql postgresql-contrib -y &> /dev/null
    if [ $? -eq 0 ]; then
      print_success "PostgreSQL berhasil diinstal setelah perbaikan."
    else
      print_error "Instalasi PostgreSQL tetap gagal."
    fi
  fi
}

secure_mysql() {
  print_status "${BLUE}Mengamankan instalasi MySQL (mysql_secure_installation)...${NC}"
  sudo mysql_secure_installation &> /dev/null
  if [ $? -eq 0 ]; then
    print_success "MySQL berhasil diamankan."
  else
    print_error "Gagal mengamankan MySQL. Anda dapat menjalankan 'mysql_secure_installation' secara manual."
  fi
}
