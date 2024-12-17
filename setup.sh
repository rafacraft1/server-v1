#!/bin/bash
# Skrip Instalasi LAMP/LEMP untuk Ubuntu
# Menginstal Apache2, PHP, Composer, dan Database MySQL/PostgreSQL dengan konfigurasi aman
# Versi: 1.3
# Penulis: [Nama Anda]

# Konstanta Global
PHP_VERSION="8.2"
PHP_REPO="ppa:ondrej/php"
INFO_PHP_PATH="/var/www/html/info.php"
LOG_FILE="/var/log/setup_script.log"
INSTALLED_COMPONENTS=()

# Redirect output ke file log dengan timestamp
exec > >(while read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S') - $line"; done | tee -a $LOG_FILE) 2>&1

# Hentikan skrip jika terjadi error dan tambahkan trap untuk membersihkan jika diperlukan
set -e
trap "echo 'Error terjadi. Periksa log di $LOG_FILE'; exit 1" ERR

# Fungsi untuk menampilkan pesan
echo_message() {
    echo "============================================"
    echo "$1"
    echo "============================================"
}

# Fungsi untuk menampilkan progres
show_progress() {
    local duration=$1
    local message=$2
    echo -n "$message"
    for i in $(seq 1 $duration); do
        echo -n "."
        sleep 1
    done
    echo " Selesai!"
}

# Fungsi validasi input
read_input() {
    local prompt=$1
    local valid_input=$2
    local input
    while true; do
        read -p "$prompt" input
        if [[ "$input" =~ $valid_input ]]; then
            echo "$input"
            return
        else
            echo "Input tidak valid. Harap coba lagi."
        fi
    done
}

# Pemeriksaan koneksi internet
check_internet() {
    if ! command -v ping &> /dev/null || ! ping -c 1 google.com &> /dev/null; then
        echo "Koneksi internet tidak tersedia. Periksa koneksi Anda dan coba lagi."
        exit 1
    fi
}

# Pemeriksaan awal
pre_check() {
    echo_message "Melakukan pemeriksaan awal..."

    if [ "$(id -u)" -ne 0 ]; then
        echo "Harap jalankan skrip ini sebagai root (sudo)."
        exit 1
    fi

    if ! grep -iq "ubuntu" /etc/os-release; then
        echo "Sistem ini bukan Ubuntu. Skrip hanya mendukung Ubuntu Server."
        exit 1
    fi

    check_internet

    echo "Pemeriksaan awal selesai. Melanjutkan proses instalasi..."
}

# Fungsi instalasi Apache2 dengan hardening
install_apache2() {
    echo_message "Menginstal Apache2..."
    show_progress 3 "Proses instalasi Apache2 dimulai"

    if dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -q "install ok installed"; then
        echo "Apache2 sudah terinstal. Lewati instalasi."
    else
        apt-get update -y
        apt-get install apache2 -y
        systemctl start apache2
        systemctl enable apache2
        INSTALLED_COMPONENTS+=("Apache2")
    fi

    if ! grep -q "Options -Indexes" /etc/apache2/apache2.conf; then
        echo "Options -Indexes" >> /etc/apache2/apache2.conf
    fi
    systemctl restart apache2

    if systemctl is-active --quiet apache2; then
        echo "Apache berjalan dengan benar."
    else
        echo "Apache tidak berjalan. Periksa konfigurasi Anda."
    fi
}

# Fungsi instalasi PHP dan modul
install_php8() {
    echo_message "Menginstal PHP${PHP_VERSION} dan modul tambahan..."
    show_progress 5 "Proses instalasi PHP dimulai"

    if ! grep -q "^deb .*$PHP_REPO" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        add-apt-repository $PHP_REPO -y
    fi
    apt-get update -y
    apt-get install -y php${PHP_VERSION} libapache2-mod-php${PHP_VERSION} php${PHP_VERSION}-{cli,fpm,mysql,xml,curl,gd,mbstring,zip,bcmath,pgsql}

    a2enmod php${PHP_VERSION}
    systemctl restart apache2

    PHP_INI="/etc/php/${PHP_VERSION}/apache2/php.ini"
    if [ -f "$PHP_INI" ]; then
        sed -i 's/expose_php = On/expose_php = Off/' $PHP_INI
        sed -i "s/;disable_functions =/disable_functions = exec,system,shell_exec,passthru,eval,phpinfo/" $PHP_INI
    fi

    echo "PHP${PHP_VERSION} berhasil diinstal dan dikonfigurasi."
    php -v
    INSTALLED_COMPONENTS+=("PHP ${PHP_VERSION}")
}

# Fungsi instalasi Composer
install_composer() {
    echo_message "Menginstal Composer..."
    show_progress 3 "Proses instalasi Composer dimulai"

    # Cari pengguna non-root pertama yang ada di sistem
    NON_ROOT_USERS=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1}')
    echo "Pengguna non-root yang tersedia:"
    select NON_ROOT_USER in $NON_ROOT_USERS; do
        if [ -n "$NON_ROOT_USER" ]; then
            break
        fi
        echo "Pilihan tidak valid. Coba lagi."
    done

    if ! command -v curl >/dev/null 2>&1; then
        apt-get install curl -y
    fi

    # Pastikan direktori tujuan ada
    TARGET_DIR="/home/$NON_ROOT_USER/.local/bin"
    if [ ! -d "$TARGET_DIR" ]; then
        sudo -u "$NON_ROOT_USER" mkdir -p "$TARGET_DIR"
    fi

    # Instal Composer ke home directory pengguna non-root
    sudo -u "$NON_ROOT_USER" bash -c "curl -sS https://getcomposer.org/installer | php -- --install-dir=$TARGET_DIR --filename=composer"

    if [ $? -eq 0 ]; then
        echo_message "Composer berhasil diinstal untuk pengguna '$NON_ROOT_USER'. Versi Composer:"
        sudo -u "$NON_ROOT_USER" bash -c "$TARGET_DIR/composer --version"
        INSTALLED_COMPONENTS+=("Composer")
    else
        echo "Gagal menginstal Composer."
        exit 1
    fi
}

# Fungsi instalasi MySQL
install_mysql() {
    echo_message "Menginstal MySQL..."
    show_progress 4 "Proses instalasi MySQL dimulai"

    if ! dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -q "install ok installed"; then
        apt-get update -y && apt-get install mysql-server -y
        systemctl start mysql
        systemctl enable mysql
        INSTALLED_COMPONENTS+=("MySQL")
    fi

    echo "Mengamankan instalasi MySQL..."
    mysql_secure_installation

    echo "MySQL berhasil diinstal dan diamankan."
}

# Fungsi membuat file info.php
create_info_php() {
    echo_message "Membuat file info.php untuk pengujian PHP..."

    if [ -d "$(dirname $INFO_PHP_PATH)" ]; then
        echo "<?php phpinfo(); ?>" > $INFO_PHP_PATH
        echo "File info.php telah dibuat di $INFO_PHP_PATH"
        echo "Akses melalui: http://<alamat-ip-server>/info.php"
        echo "CATATAN: Hapus file info.php setelah pengujian selesai untuk keamanan."
        INSTALLED_COMPONENTS+=("File info.php")
    else
        echo "Direktori tujuan tidak ditemukan. Pastikan Apache telah terinstal."
    fi
}

# Fungsi instal semua komponen
install_all() {
    install_apache2
    install_php8
    install_composer
    install_mysql
    create_info_php

    apt-get clean
    apt-get autoremove -y

    echo_message "Proses instalasi selesai dengan sukses."
}

# Fungsi untuk menampilkan laporan akhir
show_report() {
    echo_message "Laporan Instalasi Akhir"
    echo "Komponen yang telah diinstal:"
    for component in "${INSTALLED_COMPONENTS[@]}"; do
        echo "- $component"
    done
    echo "Versi komponen:"
    apache2 -v | grep "Server version"
    php -v | head -n 1
    mysql --version
    echo "Terima kasih telah menggunakan skrip ini."

    # Periksa dan hapus file info.php jika ada
    if [ -f "$INFO_PHP_PATH" ]; then
        echo "Menghapus file info.php untuk keamanan..."
        rm -f "$INFO_PHP_PATH"
        echo "File info.php berhasil dihapus."
    fi
}

# Menu utama
main_menu() {
    echo_message "Selamat datang di Skrip Instalasi Apache2, PHP${PHP_VERSION}, Composer, dan Database"
    pre_check

    while true; do
        echo_message "Menu Instalasi:"
        echo "1) Instal Apache2"
        echo "2) Instal PHP${PHP_VERSION}"
        echo "3) Instal Composer"
        echo "4) Instal MySQL"
        echo "5) Buat file info.php"
        echo "6) Instal Semua Komponen"
        echo "7) Tampilkan Laporan Instalasi"
        echo "8) Keluar"
        option=$(read_input "Pilih opsi (1-8): " "^[1-8]$")

        case $option in
            1) install_apache2 ;;
            2) install_php8 ;;
            3) install_composer ;;
            4) install_mysql ;;
            5) create_info_php ;;
            6) install_all ;;
            7) show_report ;;
            8)
                show_report
                echo_message "Terima kasih telah menggunakan skrip ini. Keluar..."
                exit 0
                ;;
        esac
    done
}

# Menjalankan menu utama
main_menu
