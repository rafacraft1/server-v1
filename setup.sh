#!/bin/bash

# Menandai skrip dijalankan dari setup.sh
export IS_SETUP_SH=$(echo 'secure_hash_value' | sha256sum | awk '{print $1}')

# Menyertakan semua utilitas dan modul
source ./scripts/utils.sh
source ./scripts/update_system.sh
source ./scripts/install_apache2.sh
source ./scripts/install_php.sh
source ./scripts/install_database.sh
source ./scripts/install_composer.sh

# Menu utama
main_menu() {
  update_system
  while true; do
    echo -e "\n${BLUE}=== Menu Utama ===${NC}"
    echo -e "1) Instal Apache2"
    echo -e "2) Instal PHP 8.x"
    echo -e "3) Instal Database (MySQL/PostgreSQL)"
    echo -e "4) Instal Composer"
    echo -e "5) Keluar"
    read -t $DEFAULT_TIMEOUT -p "Masukkan pilihan Anda: " choice
    if [ $? -ne 0 ]; then
      echo -e "\n${RED}Waktu habis.${NC}"
      if prompt_extend_time; then
        continue
      else
        echo -e "${GREEN}Keluar dari skrip. Terima kasih!${NC}"
        exit 0
      fi
    fi
    case $choice in
      1)
        install_apache2 ;;
      2)
        install_php ;;
      3)
        install_database ;;
      4)
        install_composer ;;
      5)
        echo -e "${GREEN}Keluar dari skrip. Terima kasih!${NC}"
        exit 0 ;;
      *)
        print_error "Pilihan tidak valid."
        ;;
    esac
  done
}

# Menjalankan menu utama
main_menu
