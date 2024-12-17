#!/bin/bash

# Skrip Interaktif Instalasi Apache2, PHP8, Composer, dan Database untuk Ubuntu Server
# Penulis: Indra Agustian
# Tanggal: $(date)

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
    show_progress 3 "Proses instalasi Apache2 dimulai"
    apt update -y && apt install apache2 -y
    systemctl start apache2
    systemctl enable apache2
    echo "Apache2 berhasil diinstal dan dijalankan."
}

# Fungsi untuk instalasi PHP8 dan modul
install_php8() {
    echo_message "Menambahkan repositori PHP8..."
    show_progress 2 "Menambahkan repositori PHP8"
    apt install software-properties-common -y
    add-apt-repository ppa:ondrej/php -y
    apt update -y

    echo_message "Menginstal PHP8 dan modul tambahan..."
    show_progress 5 "Proses instalasi PHP8 dimulai"
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
    show_progress 3 "Proses instalasi Composer dimulai"

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

# Fungsi untuk instalasi MySQL
install_mysql() {
    echo_message "Menginstal MySQL..."
    show_progress 4 "Proses instalasi MySQL dimulai"

    # Instalasi MySQL Server
    apt update -y
    apt install mysql-server -y

    # Menjalankan dan mengaktifkan MySQL
    systemctl start mysql
    systemctl enable mysql

    # Mengamankan instalasi MySQL
    mysql_secure_installation

    echo "MySQL berhasil diinstal dan dijalankan."

    # Menginstal ekstensi MySQL untuk PHP8
    echo_message "Menginstal ekstensi MySQL untuk PHP8..."
    apt install php8.2-mysql -y

    # Restart Apache agar ekstensi PHP MySQL aktif
    systemctl restart apache2

    echo "Ekstensi MySQL untuk PHP8 berhasil diinstal."
}

# Fungsi untuk instalasi PostgreSQL
install_postgresql() {
    echo_message "Menginstal PostgreSQL..."
    show_progress 4 "Proses instalasi PostgreSQL dimulai"

    # Instalasi PostgreSQL Server
    apt update -y
    apt install postgresql postgresql-contrib -y

    # Menjalankan dan mengaktifkan PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql

    echo "PostgreSQL berhasil diinstal dan dijalankan."
}

# Fungsi membuat file info.php
create_info_php() {
    echo_message "Membuat file info.php untuk pengujian PHP..."
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
    echo "File info.php telah dibuat di /var/www/html/info.php"
    echo "Akses melalui: http://<alamat-ip-server>/info.php"
}

# Fungsi untuk menampilkan menu utama
main_menu() {
    echo_message "Selamat datang di Skrip Instalasi Apache2, PHP8, Composer, dan Database Interaktif"

    # Pemeriksaan awal
    pre_check

    while true; do
        # Menampilkan pilihan menu
        echo_message "Menu Instalasi:"
        echo "1) Instal Apache2"
        echo "2) Instal PHP8 dan Modul terkait"
        echo "3) Instal Composer"
        echo "4) Pilih dan Instal Database (MySQL/PostgreSQL)"
        echo "5) Buat file info.php untuk pengujian PHP"
        echo "6) Keluar"
        read -p "Pilih opsi (1-6): " option

        case $option in
            1)
                echo_message "Anda memilih untuk menginstal Apache2."
                install_apache2
                ;;
            2)
                echo_message "Anda memilih untuk menginstal PHP8 beserta modulnya."
                install_php8
                ;;
            3)
                echo_message "Anda memilih untuk menginstal Composer."
                install_composer
                ;;
            4)
                echo_message "Anda memilih untuk memilih dan menginstal database."
                # Pilih MySQL atau PostgreSQL
                read -p "Pilih database untuk diinstal (1) MySQL (2) PostgreSQL: " db_choice
                case $db_choice in
                    1)
                        install_mysql
                        ;;
                    2)
                        install_postgresql
                        ;;
                    *)
                        echo "Pilihan tidak valid. Kembali ke menu utama."
                        ;;
                esac
                ;;
            5)
                echo_message "Anda memilih untuk membuat file info.php."
                create_info_php
                ;;
            6)
                echo_message "Terima kasih telah menggunakan skrip ini. Keluar..."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid. Silakan pilih antara 1-6."
                ;;
        esac

        # Tanyakan apakah pengguna ingin melakukan lebih banyak instalasi
        read -p "Apakah Anda ingin melakukan instalasi lain? (y/n): " continue_choice
        if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
            echo_message "Terima kasih telah menggunakan skrip ini. Keluar..."
            exit 0
        fi
    done
}

# Menjalankan fungsi utama
main_menu
