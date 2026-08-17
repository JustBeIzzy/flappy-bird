This game is my work assignment, enjoy if u want to take my source code
This is the original source before modification :
https://github.com/Hernandez712/FlappyBird.git

# [Flappy Bird Extended] - 2D Game Project

> **Tugas/Proyek:** Pembuatan Game 2D  
> **Pengembang:** [Muh. Firzah Pratama Putra] (212068)  
> **Platform Target:** Windows / Android

---

📌 Ringkasan Game
Flappy Bird Extended adalah game 2D bergenre Endless Runner / Arcade yang dikembangkan menggunakan Godot Engine. Dalam game ini, pemain akan mengendalikan karakter seekor burung untuk terbang melewati celah rintangan pipa sebanyak-banyaknya, bertahan dari jebakan gelembung dan kejaran musuh tawon, serta mengumpulkan koin dan power-up tanpa membiarkan nyawa habis atau jatuh ke tanah.

🎮 Cara Bermain & Kontrol
Kontrol (Mouse / Input)
Terbang (Kepakkan Sayap) / Memecahkan Gelembung: Klik Kiri Mouse
Pause Menu (UI): Melalui tombol di layar (Pause / Unmute)
Mekanik Utama
Flap & Gravity - Karakter secara konstan jatuh karena gravitasi, dan pemain harus menekan layar/mouse untuk membuat burung mengepakkan sayap terbang ke atas.
Health System - Pemain memiliki 3 nyawa (Hati). Terkena pipa atau musuh akan mengurangi 1 nyawa dan memberikan status kebal (Invulnerable) selama 1,5 detik. Jatuh ke tanah akan langsung mengakibatkan Game Over.
Trap System (Bubble) - Jika menyentuh gelembung, burung akan terperangkap dan membeku di udara. Pemain harus men-tap layar 3 kali dengan cepat untuk memecahkannya.
✨ Fitur Utama & Perubahan (Fitur Baru)
Karena proyek ini dikembangkan dari mekanik dasar Flappy Bird original, berikut adalah perubahan dan fitur baru yang telah ditambahkan ke dalam source code:

 Sistem Progresi Level (Stages): Jarak antar pipa akan semakin menyempit dan laju permainan menjadi lebih cepat setiap melewati jumlah rintangan tertentu.
 Dynamic Environment: Perubahan latar belakang secara dinamis (Siklus Siang -> Senja -> Malam) setiap melewati 15 pipa.
 Musuh Homing (Wasp): Penambahan musuh tawon yang muncul di Stage 3 dan akan secara agresif mengejar posisi vertikal pemain.
 Power-Up Shrink & Collectibles: Penambahan koin untuk poin ekstra dan Power-Up Shrink yang berfungsi untuk memperkecil ukuran burung selama 15 detik agar lebih mudah bermanuver di celah sempit.
 Moving Obstacles: Pipa yang mulai bergerak secara vertikal (naik-turun) setelah pemain mencapai skor tertentu.

