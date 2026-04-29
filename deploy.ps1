$VPS_USER = "root" # Ganti dengan username VPS Anda (misal: root atau user lain)
$VPS_IP = "YOUR_VPS_IP_HERE" # Ganti dengan IP VPS Contabo Anda
$DEST_DIR = "/home/app.portalsi.com/public_html"

Write-Host "Membangun aplikasi Flutter Web..." -ForegroundColor Cyan
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build Flutter gagal. Menghentikan proses deployment." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Build berhasil. Memulai proses upload ke VPS..." -ForegroundColor Cyan
# Perhatikan bahwa kita meng-upload isi dari folder build/web/
scp -r build/web/* ${VPS_USER}@${VPS_IP}:${DEST_DIR}/

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment berhasil! Aplikasi Anda sudah di-upload ke $DEST_DIR di VPS." -ForegroundColor Green
} else {
    Write-Host "Gagal meng-upload file ke VPS. Pastikan SSH terkonfigurasi dengan benar." -ForegroundColor Red
}
