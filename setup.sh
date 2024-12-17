#!/bin/bash

# Skrip Instalasi Apache2, PHP8, dan Composer untuk Ubuntu Server
# Penulis: Indra Agustian
# Tanggal: $(date)

# Fungsi untuk menampilkan pesan
echo_message() {
    echo "============================================"
    echo "$1"
    echo "============================================"
}

# Fungsi untuk pemeriksaan awal
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

    echo "Pemeriksaan awal selesai. Melanjutkan proses instalasi..."
}

# Fungsi untuk instalasi Apache2
install_apache2() {
    echo_message "Menginstal Apache2..."
    apt update -y && apt install apache2 -y
    systemctl start apache2
    systemctl enable apache2
    echo "Apache2 berhasil diinstal dan dijalankan."
}

# Fungsi untuk instalasi PHP8 dan modul
install_php8() {
    echo_message "Menambahkan repositori PHP8..."
    apt install software-properties-common -y
    add-apt-repository ppa:ondrej/php -y
    apt update -y

    echo_message "Menginstal PHP8 dan modul tambahan..."
    apt install php8.2 libapache2-mod-php8.2 php8.2-cli php8.2-fpm \
        php8.2-mysql php8.2-xml php8.2-curl php8.2-gd \
        php8.2-mbstring php8.2-zip php8.2-bcmath php8.2-pgsql -y

    a2enmod php8.2
    systemctl restart apache2

    # Menampilkan versi PHP
    echo_message "PHP8 berhasil diinstal. Versi PHP:"
    php -v

    # Menampilkan ekstensi PHP yang aktif
    echo_message "Daftar ekstensi PHP yang aktif:"
    php -m
}

# Fungsi untuk instalasi Composer
install_composer() {
    echo_message "Menginstal Composer..."

    # Unduh installer Composer
    curl -sS https://getcomposer.org/installer | php8.2 --install-dir=/usr/local/bin --filename=composer

    # Verifikasi instalasi Composer
    if [ $? -eq 0 ]; then
        echo_message "Composer berhasil diinstal. Versi Composer:"
        composer --version
    else
        echo_message "Gagal menginstal Composer."
        exit 1
    fi
}

# Fungsi membuat file info.php
create_info_php() {
    echo_message "Membuat file info.php untuk pengujian PHP..."
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
    echo "File info.php telah dibuat di /var/www/html/info.php"
    echo "Akses melalui: http://<alamat-ip-server>/info.php"
}

# Fungsi utama untuk menu interaktif
main_menu() {
    echo_message "Selamat datang di Skrip Instalasi Apache2, PHP8, dan Composer Interaktif"

    # Pemeriksaan awal
    pre_check

    # Tanya instalasi Apache2
    read -p "Apakah Anda ingin menginstal Apache2? (y/n): " install_apache
    if [[ "$install_apache" == "y" || "$install_apache" == "Y" ]]; then
        install_apache2
    else
        echo "Lewati instalasi Apache2."
    fi

    # Tanya instalasi PHP8
    read -p "Apakah Anda ingin menginstal PHP8 beserta modulnya? (y/n): " install_php
    if [[ "$install_php" == "y" || "$install_php" == "Y" ]]; then
        install_php8
    else
        echo "Lewati instalasi PHP8."
    fi

    # Tanya instalasi Composer
    read -p "Apakah Anda ingin menginstal Composer? (y/n): " install_composer
    if [[ "$install_composer" == "y" || "$install_composer" == "Y" ]]; then
        install_composer
    else
        echo "Lewati instalasi Composer."
    fi

    # Tanya pembuatan file info.php
    read -p "Apakah Anda ingin membuat file info.php untuk pengujian PHP? (y/n): " create_info
    if [[ "$create_info" == "y" || "$create_info" == "Y" ]]; then
        create_info_php
    else
        echo "Lewati pembuatan file info.php."
    fi

    echo_message "Proses instalasi selesai!"
    echo "Jika Apache2, PHP8, dan Composer diinstal, silakan akses server melalui browser Anda."
}

# Menjalankan fungsi utama
main_menu
