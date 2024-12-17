#!/bin/bash
# Konstanta Global
PHP_VERSION="8.2"
PHP_REPO="ppa:ondrej/php"
INFO_PHP_PATH="/var/www/html/info.php"
LOG_FILE="/var/log/setup_script.log"

# Redirect output ke file log dengan timestamp
exec > >(while read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S') - $line"; done | tee -a $LOG_FILE) 2>&1

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
    echo " Done!"
}

# Fungsi untuk validasi input
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

# Fungsi pemeriksaan koneksi internet
check_internet() {
    if ! ping -c 1 google.com &> /dev/null; then
        echo "Koneksi internet tidak tersedia. Periksa koneksi Anda dan coba lagi."
        exit 1
    fi
}

# Fungsi memeriksa dependency wajib
check_dependencies() {
    echo_message "Memeriksa dependency wajib..."
    local dependencies=("curl" "software-properties-common")
    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &>/dev/null; then
            echo "Menginstal $dep..."
            apt-get install -y $dep
        fi
    done
}

# Pemeriksaan awal
pre_check() {
    echo_message "Melakukan pemeriksaan awal..."

    # Cek apakah dijalankan sebagai root
    if [ "$(id -u)" -ne 0 ]; then
        echo "Harap jalankan skrip ini sebagai root (sudo)."
        exit 1
    fi

    # Cek apakah sistem menggunakan Ubuntu
    if ! grep -iq "ubuntu" /etc/os-release; then
        echo "Sistem ini bukan Ubuntu. Skrip hanya mendukung Ubuntu Server."
        exit 1
    fi

    # Cek koneksi internet
    check_internet

    # Cek dependency
    check_dependencies

    echo "Pemeriksaan awal selesai. Melanjutkan proses instalasi..."
}

# Fungsi untuk mengecek paket terinstal
is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# Fungsi menambahkan PPA jika belum ada
add_php_ppa() {
    if ! grep -q "^deb .*$PHP_REPO" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        echo "Menambahkan repositori PHP..."
        add-apt-repository $PHP_REPO -y
    else
        echo "Repositori PHP sudah ditambahkan. Lewati."
    fi
}

# Fungsi instalasi Apache2 dengan penanganan error dan hardening
install_apache2() {
    echo_message "Menginstal Apache2..."
    show_progress 3 "Proses instalasi Apache2 dimulai"

    if is_installed "apache2"; then
        echo "Apache2 sudah terinstal. Lewati instalasi."
    else
        if ! apt-get update -y || ! apt-get install apache2 -y; then
            echo "Gagal menginstal Apache2. Periksa koneksi internet dan coba lagi."
            exit 1
        fi

        systemctl start apache2
        systemctl enable apache2
    fi

    # Hardening Apache
    echo "Options -Indexes" >> /etc/apache2/apache2.conf
    systemctl restart apache2
    echo "Apache2 berhasil diinstal dan dikonfigurasi dengan hardening dasar."

    # Validasi Apache berjalan
    if systemctl is-active --quiet apache2; then
        echo "Apache berjalan dengan benar."
    else
        echo "Apache tidak berjalan. Periksa konfigurasi Anda."
    fi
}

# Fungsi instalasi PHP8 dan modul
install_php8() {
    echo_message "Menginstal PHP${PHP_VERSION} dan modul tambahan..."
    show_progress 5 "Proses instalasi PHP dimulai"

    # Tambah repositori PHP
    add_php_ppa
    apt-get update -y

    if ! apt-get install php${PHP_VERSION} libapache2-mod-php${PHP_VERSION} php${PHP_VERSION}-cli php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-mysql php${PHP_VERSION}-xml php${PHP_VERSION}-curl php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mbstring php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath php${PHP_VERSION}-pgsql -y; then
        echo "Gagal menginstal PHP."
        exit 1
    fi

    a2enmod php${PHP_VERSION}
    systemctl restart apache2

    # Hardening PHP
    sed -i 's/expose_php = On/expose_php = Off/' /etc/php/${PHP_VERSION}/apache2/php.ini
    sed -i "s/;disable_functions =/disable_functions = exec,system,shell_exec,passthru,eval,phpinfo/" /etc/php/${PHP_VERSION}/apache2/php.ini

    echo "PHP${PHP_VERSION} berhasil diinstal dan dikonfigurasi."
    php -v
}

# Fungsi instalasi Composer dengan pemeriksaan curl
install_composer() {
    echo_message "Menginstal Composer..."
    show_progress 3 "Proses instalasi Composer dimulai"

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl tidak ditemukan. Menginstal curl..."
        apt-get install curl -y
    fi

    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    if [ $? -eq 0 ]; then
        echo_message "Composer berhasil diinstal. Versi Composer:"
        composer --version
    else
        echo "Gagal menginstal Composer."
        exit 1
    fi
}

# Fungsi instalasi MySQL
install_mysql() {
    echo_message "Menginstal MySQL..."
    show_progress 4 "Proses instalasi MySQL dimulai"

    if systemctl is-active --quiet mysql; then
        echo "MySQL sudah berjalan. Lewati instalasi."
        return
    fi

    apt-get update -y && apt-get install mysql-server -y
    systemctl start mysql
    systemctl enable mysql

    # Amankan instalasi MySQL
    echo "Mengamankan instalasi MySQL..."
    mysql_secure_installation <<EOF
n
y
y
y
y
EOF

    echo "MySQL berhasil diinstal dan diamankan."
}

# Fungsi instalasi PostgreSQL
install_postgresql() {
    echo_message "Menginstal PostgreSQL..."
    show_progress 4 "Proses instalasi PostgreSQL dimulai"

    if systemctl is-active --quiet postgresql; then
        echo "PostgreSQL sudah berjalan. Lewati instalasi."
        return
    fi

    apt-get update -y && apt-get install postgresql postgresql-contrib -y
    systemctl start postgresql
    systemctl enable postgresql

    echo "PostgreSQL berhasil diinstal dan dijalankan."
}

# Fungsi membuat file info.php
create_info_php() {
    echo_message "Membuat file info.php untuk pengujian PHP..."
    echo "<?php phpinfo(); ?>" > $INFO_PHP_PATH
    echo "File info.php telah dibuat di $INFO_PHP_PATH"
    echo "Akses melalui: http://<alamat-ip-server>/info.php"
}

# Fungsi instal semua komponen
install_all() {
    install_apache2
    install_php8
    install_composer

    # Pilih database
    db_choice=$(read_input "Pilih database: 1) MySQL 2) PostgreSQL: " "^[12]$")
    case $db_choice in
        1) install_mysql ;;
        2) install_postgresql ;;
    esac

    create_info_php

    # Membersihkan cache apt
    apt-get clean
    apt-get autoremove -y

    echo_message "Proses instalasi selesai dengan sukses."
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
        echo "4) Instal Database (MySQL/PostgreSQL)"
        echo "5) Buat file info.php"
        echo "6) Instal Semua Komponen"
        echo "7) Keluar"
        option=$(read_input "Pilih opsi (1-7): " "^[1-7]$")

        case $option in
            1) install_apache2 ;;
            2) install_php8 ;;
            3) install_composer ;;
            4)
                db_choice=$(read_input "Pilih database: 1) MySQL 2) PostgreSQL: " "^[12]$")
                [[ $db_choice == "1" ]] && install_mysql || install_postgresql
                ;;
            5) create_info_php ;;
            6) install_all ;;
            7)
                echo_message "Terima kasih telah menggunakan skrip ini. Keluar..."
                exit 0
                ;;
        esac
    done
}

# Menjalankan menu utama
main_menu
