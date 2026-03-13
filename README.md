# Recon Automation Script
Recon Automation Script adalah script Bash sederhana untuk mengotomatisasi proses reconnaissance awal dalam web security testing.
Script ini melakukan enumerasi subdomain, mendeteksi host yang aktif, dan melakukan crawling endpoint secara otomatis menggunakan beberapa tools populer di dunia offensive security.

Pipeline recon yang digunakan:
domain → subdomain enumeration → live host detection → endpoint discovery

Script ini juga dilengkapi dengan logging, error handling, dan deduplikasi hasil, sehingga cocok digunakan sebagai dasar automation dalam workflow reconnaissance.

---

# Tools yang Digunakan

Script ini menggunakan beberapa tools dari ekosistem security reconnaissance.

### subfinder

Digunakan untuk melakukan subdomain enumeration secara pasif dari berbagai sumber OSINT.

Output:

```
sub.example.com
api.example.com
dev.example.com
```

---

### anew

Digunakan untuk deduplikasi data secara realtime.
Jika data yang sama muncul kembali, `anew` tidak akan menambahkannya ke file output.

Contoh:

```
subfinder | anew all-subdomains.txt
```

Jika subdomain sudah ada, maka tidak akan ditambahkan lagi.

---

### httpx

Digunakan untuk mendeteksi host yang aktif dari daftar subdomain.

Tool ini juga menampilkan informasi tambahan seperti:

* HTTP status code
* Page title
* IP address

Contoh output:

```
https://example.com [200] [Example Domain] [93.184.216.34]
```

---

### katana

Digunakan untuk melakukan crawling endpoint dari host yang aktif.

Tool ini akan mencari berbagai path seperti:

```
/login
/admin
/api
/dashboard
```

---

# Workflow Recon Script

Script bekerja dengan pipeline berikut:

```
domains.txt
     │
     ▼
 subfinder
     │
     ▼
anew (deduplicate)
     │
     ▼
all-subdomains.txt
     │
     ▼
   httpx
     │
     ▼
  live.txt
     │
     ▼
   katana
     │
     ▼
endpoints.txt
```

Penjelasan singkat:

1. Script membaca daftar domain dari `input/domains.txt`
2. `subfinder` mencari semua subdomain
3. `anew` memastikan tidak ada duplikasi
4. `httpx` mengecek host yang aktif
5. `katana` melakukan crawling endpoint
6. Script menampilkan total hasil di akhir eksekusi

---

# Struktur Repository

```
recon-automation-kevin
│
├── input
│   └── domains.txt
│
├── output
│   ├── all-subdomains.txt
│   ├── live.txt
│   └── endpoints.txt
│
├── logs
│   ├── progress.log
│   └── errors.log
│
├── scripts
│   └── recon-auto.sh
│
└── README.md
```

---

# Setup Environment

Script ini dirancang untuk dijalankan pada sistem berbasis Linux seperti:

* Kali Linux
* Ubuntu
* Debian

Pastikan `Go` sudah terinstall karena sebagian tools menggunakan Go.

---

# Install Tools

### Install subfinder

```
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
```

---

### Install httpx

```
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
```

---

### Install katana

```
go install github.com/projectdiscovery/katana/cmd/katana@latest
```

---

### Install anew

```
go install github.com/tomnomnom/anew@latest
```

Pastikan folder Go binary ada di PATH:

```
export PATH=$PATH:~/go/bin
```

---

# Cara Menjalankan Script

Pertama buat script menjadi executable:

```
chmod +x scripts/recon-auto.sh
```

Kemudian jalankan script:

```
./scripts/recon-auto.sh
```

Script akan otomatis:

* membaca domain
* melakukan enumeration
* mengecek host aktif
* melakukan crawling endpoint
* menyimpan hasil ke folder output

---

# Contoh Input

File `input/domains.txt`

```
picoctf.org
```

Script dapat menerima beberapa domain sekaligus, misalnya:

```
hackerone.com
hackthebox.com
tryhackme.com
```

---

# Contoh Output

### Live Hosts

File: `output/live.txt`

```
https://game-cdn.picoctf.org [403] [65.8.76.79]
https://kepler.picoctf.org [200] [Vite + React + TS] [3.133.123.161]
https://play.picoctf.org [403] [Just a moment...] [172.66.157.191]
https://primer.picoctf.org [200] [The CTF Primer] [3.20.60.32]
https://rsac.picoctf.org [200] [RSAC PicoCTF - Learn Cybersecurity Through Challenges] [3.18.131.20]
https://status.picoctf.org [403] [Just a moment...] [104.20.26.123]
https://webshell.picoctf.org [200] [ttyd - Terminal] [172.66.157.191]
https://www.picoctf.org [200] [picoCTF - CMU Cybersecurity Competition] [108.157.254.23]
```

---

### Crawled Endpoints

File: `output/endpoints.txt`

```
https://www.picoctf.org
https://www.picoctf.org/
https://www.picoctf.org/about.html
https://www.picoctf.org/competitions/2026-spring.html
https://www.picoctf.org/competitions/2026-spring-rules.html
https://www.picoctf.org/css/bs-stepper.min.css
https://www.picoctf.org/css/font-awesome.min.css
https://www.picoctf.org/css/main.css
https://www.picoctf.org/get_started.html
```

---

# Penjelasan Script

Berikut penjelasan bagian utama dari script `recon-auto.sh`.

---

## 1. Error Handling dan Base Directory

```
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

Bagian ini berfungsi untuk meningkatkan stabilitas script.

`set -Eeuo pipefail` memastikan script akan berhenti jika terjadi error agar proses tidak berjalan dalam kondisi tidak valid.

`BASE_DIR` digunakan untuk menentukan direktori utama repository sehingga script tetap dapat dijalankan dari lokasi manapun.

---

## 2. Variabel Direktori

```
INPUT="$BASE_DIR/input"
OUTPUT="$BASE_DIR/output"
LOGS="$BASE_DIR/logs"

mkdir -p "$INPUT" "$OUTPUT" "$LOGS"
```

Bagian ini mendefinisikan lokasi folder utama yang digunakan script.

Jika folder belum ada, maka `mkdir -p` akan membuatnya secara otomatis.

---

## 3. Error Logging

```
exec 2>> "$LOGS/errors.log"
```

Semua pesan error (`stderr`) dari tools akan otomatis disimpan ke file:

```
logs/errors.log
```

Hal ini memudahkan proses debugging tanpa mengganggu output utama di terminal.

---

## 4. Subdomain Enumeration

```
subfinder -d "$domain" -silent | anew "$OUTPUT/all-subdomains.txt"
```

Script menggunakan `subfinder` untuk mencari subdomain dari domain target.

Output kemudian diproses oleh `anew` untuk memastikan hanya subdomain unik yang disimpan.

---

## 5. Live Host Detection

```
httpx -l "$OUTPUT/all-subdomains.txt" -silent -status-code -title -ip
```

`httpx` digunakan untuk memeriksa apakah subdomain dapat diakses.

Tool ini juga menampilkan informasi tambahan seperti:

* HTTP status code
* page title
* IP address

Hasilnya disimpan di:

```
output/live.txt
```

---

## 6. Endpoint Crawling

```
katana -silent -depth 3
```

`katana` melakukan crawling pada host yang aktif untuk menemukan endpoint baru.

Contohnya:

```
/login
/admin
/api
```

Semua endpoint yang ditemukan akan disimpan di:

```
output/endpoints.txt
```

---

## 7. Statistik Hasil

```
total_sub=$(wc -l < "$OUTPUT/all-subdomains.txt")
total_live=$(wc -l < "$OUTPUT/live.txt")
total_errors=$(wc -l < "$LOGS/errors.log")
```

Di akhir eksekusi script akan menampilkan ringkasan hasil:

* jumlah subdomain unik
* jumlah host aktif
* jumlah error yang terjadi

---

# Screenshot


---
