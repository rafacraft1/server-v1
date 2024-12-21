#!/bin/bash

# Menandai skrip dijalankan dari setup.sh
export IS_SETUP_SH=$(echo 'secure_hash_value' | sha256sum | awk '{print $1}')

# Direktori skrip lokal
SCRIPTS_DIR="./scripts"

# URL repository GitHub
GITHUB_REPO_RAW="https://github.com/rafacraft1/server-v1/main/scripts"

# Daftar file skrip yang diperlukan
REQUIRED_SCRIPTS=("utils.sh" "update_system.sh" "install_apache2.sh" "install_php.sh" "install_database.sh" "install_composer.sh")

# Fungsi untuk memeriksa kelengkapan file skrip
check_scripts() {
  echo -e "\n${BLUE}Memeriksa kelengkapan file skrip...${NC}"
  local missing_count=0
  for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "${SCRIPTS_DIR}/${script}" ]; then
      echo -e "${GREEN}[✓] ${script} ditemukan.${NC}"
    else
      echo -e "${RED}[✗] ${script} tidak ditemukan!${NC}"
      missing_count=$((missing_count + 1))
    fi
  done
  if [ $missing_count -eq 0 ]; then
    echo -e "${GREEN}Semua file skrip sudah lengkap.${NC}"
  else
    echo -e "${RED}Ada $missing_count file skrip yang hilang. Periksa kelengkapan sebelum melanjutkan.${NC}"
    exit 1
  fi
}

# Fungsi untuk membandingkan dan memperbarui file
sync_scripts() {
  echo -e "\n${BLUE}Memeriksa kesesuaian file skrip dengan repository GitHub...${NC}"
  local temp_dir=$(mktemp -d)
  local updates=0

  for script in "${REQUIRED_SCRIPTS[@]}"; do
    local remote_file="${GITHUB_REPO_RAW}/${script}"
    local local_file="${SCRIPTS_DIR}/${script}"

    # Download versi remote
    curl -sSL "$remote_file" -o "${temp_dir}/${script}"
    if [ $? -ne 0 ]; then
      echo -e "${RED}[✗] Gagal mengunduh ${script} dari GitHub.${NC}"
      continue
    fi

    # Bandingkan file lokal dengan remote
    if cmp -s "${temp_dir}/${script}" "$local_file"; then
      echo -e "${GREEN}[✓] ${script} sudah sesuai.${NC}"
    else
      echo -e "${YELLOW}[!] ${script} berbeda dengan versi di GitHub. Memperbarui...${NC}"
      mv "${temp_dir}/${script}" "$local_file"
      chmod +x "$local_file"
      echo -e "${GREEN}[✓] ${script} berhasil diperbarui.${NC}"
      updates=$((updates + 1))
    fi
  done

  # Bersihkan direktori sementara
  rm -rf "$temp_dir"

  if [ $updates -eq 0 ]; then
    echo -e "${GREEN}Semua file skrip sudah sesuai.${NC}"
  else
    echo -e "${BLUE}Total file yang diperbarui: $updates.${NC}"
  fi
}

# Fungsi untuk memuat semua file skrip
load_scripts() {
  source "${SCRIPTS_DIR}/utils.sh"
  source "${SCRIPTS_DIR}/update_system.sh"
  source "${SCRIPTS_DIR}/install_apache2.sh"
  source "${SCRIPTS_DIR}/install_php.sh"
  source "${SCRIPTS_DIR}/install_database.sh"
  source "${SCRIPTS_DIR}/install_composer.sh"
}

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

# Eksekusi awal: Periksa kelengkapan file skrip
check_scripts

# Sinkronisasi dengan GitHub
sync_scripts

# Memuat file skrip
load_scripts

# Menjalankan menu utama
main_menu
