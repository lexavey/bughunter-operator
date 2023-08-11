
## Bahasa Indonesia

# BugHunter Operator

## Persyaratan

Sebelum menggunakan BugHunter Operator, pastikan Anda telah menginstal paket-paket berikut: `curl`, `openssl`, `nmap`, `git`, `perl`, dan `python`.

Anda dapat menginstal paket-paket tersebut menggunakan perintah berikut:

```bash
apt update && apt upgrade
apt install curl nmap openssl git perl python -y
```

## Mulai Cepat

### Langkah 1 - Unduh
Klon repositori BugHunter Operator dan navigasikan ke direktori proyek:

```bash
git clone https://github.com/lexavey/bughunter-operator
cd bughunter-operator
chmod +x ./run.sh
```

### Langkah 2 - Dapatkan daftar
Buat direktori bernama `list` dan salin daftar URL ke dalamnya:

```bash
mkdir -p list
cp archive/random/urls_universal.txt list/
```

### Langkah 3 - Pindai
Untuk melakukan proses pemindaian, ikuti langkah-langkah berikut:

1. Putuskan sambungan WiFi Anda dan gunakan kartu SIM data untuk pemindaian yang lebih akurat.

2. Jalankan skrip pemindaian tanpa daftar domain kustom:

```bash
./run.sh scan sni go
```

Atau, jika Anda ingin menggunakan daftar domain kustom, buatlah file teks (misalnya, `domain.txt`) yang berisi daftar domain yang ingin Anda pindai, lalu gunakan perintah berikut:

```bash
./run.sh scan sni go domain.txt
```

Perintah-perintah ini akan memulai proses pemindaian dan menampilkan hasilnya.

## Kesalahan Umum

### Pesan Kesalahan

```
syntax error at ./bin/parallel line 2992, at EOF
Missing right curly or square bracket at ./bin/parallel line 2992, at end of line
Execution of ./bin/parallel aborted due to compilation errors.
```

### Solusi

Untuk mengatasi kesalahan ini, perbarui versi Perl Anda. Jika Anda menggunakan Termux, pertimbangkan untuk menggunakan aplikasi Linux Deploy dari Play Store: https://play.google.com/store/apps/details?id=ru.meefik.linuxdeploy (ROOT)

Ikuti langkah-langkah berikut:

1. Unduh aplikasi Linux Deploy.
2. Atur properti (Di bagian kanan bawah):
   - Distribusi: Ubuntu
   - Arsitektur: arm64
   - Kata Sandi: 123
   - SSH: Aktifkan
3. Kembali.
4. Pasang (Di bagian kanan atas).
5. Konfigurasi.
6. Mulai.
7. Sambungkan SSH dari Termux menggunakan perintah berikut: `ssh android@localhost -p 22`

### Memeriksa Versi Perl

Untuk memeriksa versi Perl Anda, jalankan perintah berikut:

```bash
perl -v
```

Anda akan melihat output yang mirip dengan ini:

```
This is perl 5, version 26, subversion 1 (v5.26.1) built for aarch64-linux-gnu-thread-multi
(with 62 registered patches, see perl -V for more detail)

Copyright 1987-2017, Larry Wall

Perl may be copied only under the terms of either the Artistic License or the
GNU General Public License, which may be found in the Perl 5 source kit.

Complete documentation for Perl, including FAQ lists, should be found on
this system using "man perl" or "perldoc perl". If you have access to the
Internet, point your browser at http://www.perl.org/, the Perl Home Page.
```

Jangan ragu untuk bertanya jika Anda membutuhkan bantuan lebih lanjut atau memiliki pertanyaan lebih lanjut!

