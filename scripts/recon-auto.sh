#!/bin/bash

# Memastikan jika ada eror ditengah proses, script akan benar2 berhenti
set -Eeuo pipefail

# Agar script dapat dijalankan dari direktori lain
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

#Variabel untuk setiap direktori
INPUT="$BASE_DIR/input"
OUTPUT="$BASE_DIR/output"
LOGS="$BASE_DIR/logs"

# Membuat ketiga direktori tsb jika blm ada
mkdir -p "$INPUT" "$OUTPUT" "$LOGS"

# Membuat direktori log eror
exec 2>> "$LOGS/errors.log"

echo "=====================================================" | tee -a "$LOGS/progress.log"
echo "[$(date)] Memulai script..." | tee -a "$LOGS/progress.log"

# Membaca target setiap baris dan dimasukan ke dalam variabel domain
while IFS= read -r domain; do

	echo "[$(date)] Proses target: $domain" | tee -a "$LOGS/progress.log"
	echo "[$(date)] Mencari subdomain $domain..." | tee -a "$LOGS/progress.log"
	subfinder -d "$domain" -silent | anew "$OUTPUT/all-subdomains.txt" > /dev/null

done < "$INPUT/domains.txt"
sort -u "$OUTPUT/all-subdomains.txt" -o "$OUTPUT/all-subdomains.txt"

# Mencari host yang aktif dari semua subdomain menggunakan httpx
echo "[$(date)] Mencari host aktif..." | tee -a "$LOGS/progress.log"
	httpx -l "$OUTPUT/all-subdomains.txt" -silent -status-code -title -ip \
		| anew "$OUTPUT/live.txt" > /dev/null
	sort -u "$OUTPUT/live.txt" -o "$OUTPUT/live.txt"

# Mencari endpoint dari setiap subdomain menggunakan katana
echo "[$(date)] Mencari endpoint..." | tee -a "$LOGS/progress.log"
	cut -d ' ' -f1 "$OUTPUT/live.txt" \
		| katana -silent -depth 3 \
		| anew "$OUTPUT/endpoints.txt" > /dev/null
	sort -u "$OUTPUT/endpoints.txt" -o "$OUTPUT/endpoints.txt"
echo "=====================================================" | tee -a "$LOGS/progress.log"

total_sub=$(wc -l < "$OUTPUT/all-subdomains.txt")
total_live=$(wc -l < "$OUTPUT/live.txt")
total_errors=$(wc -l < "$LOGS/errors.log")

echo "[+] Total subdomain ditemukan: $total_sub" | tee -a "$LOGS/progress.log"
echo "[+] Total live hosts ditemukan: $total_live" | tee -a "$LOGS/progress.log"
echo "[+] Total error: $total_errors" | tee -a "$LOGS/progress.log"
