#!/bin/bash

# Hentikan eksekusi jika ada error
set -e

# Path tujuan public_html Anda di VPS
DEST_DIR="/home/app.portalsi.com/public_html"

echo "======================================"
echo "Memulai proses build dan deploy di VPS"
echo "======================================"

# Pastikan Anda berada di dalam folder project saat menjalankan script ini
echo "1. Memperbarui dependencies Flutter..."
flutter pub get

echo "2. Membangun aplikasi Flutter Web..."
flutter build web --release

echo "3. Menyalin file ke folder tujuan..."
# Menghapus file lama jika diperlukan (Hilangkan tanda pagar di bawah jika ingin menghapus file lama sebelum menimpa)
# rm -rf $DEST_DIR/*

# Menyalin hasil build ke public_html
cp -r build/web/* $DEST_DIR/

echo "======================================"
echo "Deployment Berhasil! Aplikasi Anda sudah live."
echo "======================================"
