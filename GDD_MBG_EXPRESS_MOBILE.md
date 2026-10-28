# GAME DESIGN DOCUMENT & TECHNICAL BLUEPRINT
# MBG EXPRESS MOBILE (GODOT 4 EDITION) — REVISED & BALANCED

*Dokumentasi Resmi Konsep Game, Balancing Desain & Blueprint Teknis Implementasi Engine Godot 4*  
*Mata Kuliah: Pemrograman Game — STT Terpadu Nurul Fikri (2026)*  
*Revisi Desain: Penyempurnaan Core Loop, Eliminasi Scope Creep, Penyeimbangan Risk-Reward & Sistem Ekonomi Progresi*

---

## 1. GAME OVERVIEW

### 1.1 Informasi Umum
* **Judul Game:** MBG EXPRESS MOBILE (MBG Driver)
* **Genre:** Top-Down Fast-Paced Arcade Driving / Delivery Time-Management (*Crazy Taxi* meets *Overcooked on Wheels* dengan Kearifan Lokal)
* **Game Engine:** Godot Engine 4.x (Renderer: *Compatibility / WebGL2 / OpenGL ES 3.0*)
* **Platform Rilis:** 
  1. Web Browser (HTML5 / WebAssembly — itch.io, Vercel, Netlify)
  2. Mobile (Android APK)
  3. Desktop Standalone (Windows / Linux)
* **Target Pemain:** Remaja & Mahasiswa (Usia 13–24 tahun)
* **Gaya Visual:** 3D Anime Cel-Shaded / Low-Poly Stylized
* **Perspektif Kamera:** Top-Down / High-Angle Isometric (sudut elevasi 50°–55°) mengikuti kendaraan dengan *smooth damping & dynamic framing*.

### 1.2 Ringkasan Konsep (High Concept)
Pemain bertindak sebagai pengemudi armada distribusi **Makanan Bergizi Gratis (MBG)**. Misi utama pemain adalah mengambil ransum makanan bergizi dari **SPPG (Satuan Pelayanan Pemenuhan Gizi / Dapur Sentral)** dan mendistribusikannya ke beberapa sekolah tujuan tepat sebelum bel istirahat makan siang berbunyi pada pukul **12:00 Siang**.

Tantangan utamanya bukan sekadar memacu kecepatan (*speedrun*), melainkan mengelola **Dual-Constraint Dynamic**: menyeimbangkan kecepatan hitung mundur waktu (*Time Limit*) dengan menjaga keutuhan ransum (*Food Condition meter*) agar makanan tidak hancur atau tumpah akibat guncangan jalan rusak dan benturan lalu lintas perkotaan.

---

## 2. CORE GAMEPLAY LOOP & DESAIN ALIRAN (PACING)

Game ini dirancang dengan prinsip **100% Focused Driving Arcade**: tidak ada fase turun dari mobil yang memperlambat tempo atau menimbulkan *friction scope creep*. Seluruh interaksi berbasis kemudi responsif dengan mekanisme *drive-in pit-stop*.

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. SPPG DRIVE-IN LOADING ZONE (Pit-Stop Ransum)            │
│    - Mobil masuk ke kotak muat SPPG Depot.                  │
│    - Quick Load otomatis (1.5 - 2 detik) ala F1 pit-stop.   │
│    - Food Condition di-reset 100%, kuota porsi terisi penuh.│
└──────────────────────────────┬──────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. TACTICAL TRANSIT & NAVIGATION (City Rush)                │
│    - Pilihan Rute: Jalan Protokol (Mulus tapi Macet) vs     │
│      Jalan Tikus (Cepat tapi Rusak & Banyak Polisi Tidur). │
│    - Gunakan Klakson Aktif untuk membelah kerumunan/angkot. │
│    - Kumpulkan Near-Miss Time Bonus saat menyalip tipis.    │
│    - Gunakan Nitro Boost secara taktis untuk mengejar waktu.│
└──────────────────────────────┬──────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. SCHOOL DROP-OFF ZONE (Serah Terima Presisi)              │
│    - Rem dan parkir presisi di zona kuning gerbang sekolah. │
│    - Serah terima instan (1 - 1.5 detik) / bunyikan klakson.│
│    - Sambutan ceria dari NPC Guru & Siswa.                  │
└──────────────────────────────┬──────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. SCORING & REWARD EVALUATION                              │
│    - Evaluasi Bintang 1 hingga 3 berdasarkan Sisa Waktu,    │
│      Kondisi Makanan, dan Near-Miss Bonus.                  │
│    - Hadiah Koin MBG & Reputasi Kurir.                      │
└──────────────────────────────┬──────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. METAGAME: TOKO KENDARAAN & GARASI UPGRADE                │
│    - Belanja Kendaraan Baru (Tossa Roda Tiga, Pick-Up, Truk)│
│    - Upgrade Part (Suspensi Empuk, Thermobox, Rem ABS, dsb) │
│    - Membuka Rute Baru & Mode Cuaca Hujan Ekstrem.          │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. BALANCING MEKANIK: MENYELESAIKAN DILEMA "TIME ATTACK VS FOOD HP"

### 3.1 Masalah Desain & Solusi Game Feel
Dalam desain awal, menggabungkan *Time Limit* ketat dengan *Food Damage* yang terlalu sensitif menciptakan dilema rasa frustrasi (*"Mau ngebut takut makanan rusak, mau pelan-pelan kehabisan waktu"*).

Untuk menciptakan pengalaman yang adil, menantang, dan adiktif, diterapkan 3 solusi balancing:

#### 1. Desain Dual-Path (Risk vs Reward yang Jelas)
Kota dirancang memiliki dua karakteristik jalur yang kontras:
* **Jalur Protokol (Low Risk Food, High Time Friction):**
  * Jalan raya beraspal mulus dengan marka jelas.
  * Makanan sangat aman dari guncangan jalan (kerusakan 0%).
  * Tantangan: Ramai mobil NPC, angkot berhenti mendadak, dan persimpangan padat. Menuntut pemain piawai bermanuver atau membunyikan klakson.
* **Jalur Gang Tikus / Shortcut (High Risk Food, Low Time Friction):**
  * Jalur pintas yang memotong bundaran dan rute memutar kota.
  * Tidak ada kemacetan mobil besar.
  * Tantangan: Jalanan paving berbatu, aspal berlubang (*potholes*), dan polisi tidur tajam. Kecepatan tinggi di sini akan mengikis Food Condition secara drastis kecuali mobil sudah di-upgrade suspensinya.

#### 2. Mekanik Hadiah: *Near-Miss Time Bonus*
* Ketika pemain melajukan kendaraan di atas 16 m/s dan menyalip kendaraan NPC, pembatas jalan, atau tiang dengan jarak sangat tipis (< 1.5 meter) tanpa menabrak:
  * Pemain mendapatkan notifikasi visual di layar: **"⚡ NEAR MISS! +1.5s"**.
  * Timer misi bertambah **+1.0 hingga +2.0 detik**.
  * Mekanik ini memberi kompensasi waktu nyata bagi pemain yang menyetir secara terampil dan berani mengambil risiko tanpa merusak makanan.

#### 3. Progresi Kompensasi Perlengkapan (Mitigation via Upgrades)
Kerusakan makanan akibat guncangan jalan dapat diredam secara proporsional melalui upgrade garasi:
* **Suspensi Hidrolik:** Meningkatkan ambang batas kecepatan aman saat melibas jalan berlubang dari 14 m/s menjadi 22 m/s.
* **Thermobox & Cargo Net:** Melindungi paket makanan dari tabrakan ringan pertama tanpa mengurangi Food Condition.

---

## 4. SISTEM & MEKANIK PERMAINAN

### 4.1 Mekanik Pengemudian Arcade (Arcade Vehicle Physics)
Menggunakan pendekatan *Kinematic Arcade Car* (`CharacterBody3D`):
* **Akselerasi & Pengereman:** Akselerasi bertahap hingga *Top Speed*, pengereman instan (*brake*) dan mundur (*reverse*).
* **Speed-Sensitive Steering:** Sensitivitas setir berinterpolasi secara dinamis berdasarkan kecepatan laju mobil—responsif di kecepatan rendah, stabil dan tidak tersentak saat melaju kencang.
* **Visual Body Roll & Suspension Bump:** Bodi mobil memiliki kemiringan suspensi saat berbelok tajam (*body roll*) serta pantulan vertikal (*bump impulse*) saat melibas lubang jalan atau terjadi benturan.
* **Partikel Visual Dinamis:** Knalpot mengepulkan asap kartun (`CPUParticles3D`) yang membesar saat akselerasi, serta partikel debu ban (`TireDust`) yang menyembur saat pengereman mendadak (*skidding*), *drifting*, atau keluar ke bahu jalan berpasir.

### 4.2 Klakson Interaktif sebagai Alat Gameplay Utama (Active Driver Tool)
Klakson bukan sekadar efek audio kosmetik, melainkan **alat kendali lingkungan (Player Agency Tool)**:
* **Membuka Kemacetan Angkot / Mobil NPC:**
  * Menekan tombol `H` (atau tombol klakson di layar HP) membunyikan klakson *"Telolet / Horn"*.
  * Kendaraan NPC lambat di depan dalam radius 12 meter akan menyalakan lampu sein dan menepi perlahan ke bahu jalan, membuka celah untuk disalip.
* **Membelah Kerumunan Warga & Demonstran:**
  * Membunyikan klakson saat mendekati kerumunan massa atau warga yang menyeberang jalan akan memicu NPC bereaksi mundur 1.5 meter, membuka koridor sempit agar mobil MBG bisa melintas tanpa menabrak warga.

### 4.3 Sistem Bahan Bakar: Redesain Menjadi "Tactical Nitro / Boost Bar"
* **Kritik Desain Lama:** Mampir mengantre di SPBU di tengah misi berdurasi 90 detik merusak aliran keseruan dan memicu kekalahan yang tidak adil.
* **Desain Baru (Fuel as Tactical Nitro):**
  * Bahan bakar mobil berfungsi sebagai **Stamina / Nitro Bar**.
  * Dalam kondisi menyetir normal, bensin tidak akan habis selama durasi misi standar.
  * **Tombol Boost (Space / Pedal Nitro):** Pemain dapat menekan tombol Nitro untuk mendapatkan lonjakan kecepatan instan (*Top Speed* +35% selama 3 detik). Menggunakan Nitro akan menguras bar bahan bakar.
  * **Drive-Thru Refill (Jerry Can Pickups):** Pemain dapat mengisi ulang nitro bar secara instan dengan melindas jerigen bensin mengambang di dekat pom bensin pinggir jalan tanpa perlu berhenti total.

### 4.4 Sistem Kondisi Makanan (Food Condition System)
* Nilai awal: **100%**.
* Kondisi berkurang jika:
  * **Benturan Keras ke Dinding / Pembatas:** Kecepatan > 15 m/s mengurangi 5% s/d 15% (dapat diredam dengan upgrade Thermobox).
  * **Melindas Lubang Jalan (Pothole):** Kecepatan > 14 m/s mengurangi 3.5% per lubang jalan.
* Evaluasi Kualitas Makanan di Garis Finish:
  * **85% – 100% (Sempurna):** Makanan rapi, guru memberikan apresiasi maksimal, bonus koin +50%.
  * **50% – 84% (Layak Konsumsi):** Makanan sedikit berguncang, penerimaan normal.
  * **1% – 49% (Rusak / Berantakan):** Penalti skor berat, bintang dibatasi maksimal 1 bintang.
  * **0% (Hancur Total):** *Mission Failed* — Makanan tidak layak konsumsi untuk siswa.

### 4.5 Sistem Penilaian & Formula Skor
$$\text{Total Score} = (\text{Sisa Waktu} \times 50) + (\text{Food Condition \%} \times 100) + (\text{Jumlah Near-Miss} \times 250) + \text{Bonus Mulus}$$

* **Bintang 3 (★★★):** Sisa Waktu $\ge 25\%$ dan Food Condition $\ge 85\%$.
* **Bintang 2 (★★☆):** Misi selesai tepat waktu, Food Condition $50\% - 84\%$.
* **Bintang 1 (★☆☆):** Misi selesai dengan Food Condition $< 50\%$ atau sisa waktu $< 10$ detik.

---

## 5. ENVIRONMENT, RINTANGAN & NAVIGASI KOTA

### 5.1 Tata Letak Kota Terpadu (City Map Layout)
Peta dirancang dengan modularitas tinggi, memadukan nuansa perkotaan Indonesia yang hidup:
1. **Zona Dapur Sentral SPPG:** Terletak di sebelah barat (-50m). Dilengkapi area dermaga muat luas, gedung fasilitas gizi, koki dapur, staf pengecekan QC, dan bendera merah putih.
2. **Zona Bundaran Air Mancur (Central Roundabout):** Titik persimpangan utama di tengah kota (0m) yang menghubungkan jalan protokol barat-timur dan utara-selatan.
3. **Zona Komersial & Kuliner:** Warung makan tradisional, ruko UMKM, pohon kelapa, dan trotoar pejalan kaki.
4. **Zona Layanan Publik & Pemukiman:** Kantor Polisi, Pos Pemadam Kebakaran, perumahan warga asri dengan pepohonan pinus dan cypress.
5. **Zona Sekolah SDN 01:** Terletak di sebelah timur (+52m). Memiliki lapangan upacara, meja komite penerimaan guru, marka zebra cross penyeberangan siswa, dan gapura sekolah.

### 5.2 Rintangan Jalan Dinamis & Player Agency
| Rintangan | Tipe | Efek pada Permainan | Solusi Interaksi Pemain |
| :--- | :--- | :--- | :--- |
| **Lubang Aspal (Potholes)** | Statik | Merusak Food Condition jika diterabas kencang. | Hindari atau kurangi kecepatan / Upgrade suspensi. |
| **Kemacetan / Angkot Ngetem** | Dinamis | Menghalangi lajur utama jalan protokol. | Bunyikan Klakson (`H`) agar angkot menepi ke kiri. |
| **Kerumunan Massa / Aksi Damai**| Area | Menutup persimpangan jalan protokol selatan. | Cari rute jalan tikus alternatif atau klakson untuk celah sempit. |
| **Portal Gang / Palang Pos Ronda**| Barikade | Membatasi akses masuk ke gang pintas pemukiman. | Klakson sekali di pos ronda / bayar 5 koin untuk dibuka otomatis. |

### 5.3 Sistem Navigasi: 3D Waypoint Arrow & Waze-Style Live Minimap
* **3D Dynamic Waypoint Arrow:**
  * Panah 3D *cel-shaded* melayang cerdas di atas kendaraan pemain yang selalu berputar mengarah ke sasaran aktif di dunia 3D.
  * Berwarna hijau zamrud (`#00E676`) saat menuju SPPG, dan berubah kuning keemasan (`#FFB300`) saat mengantar ke SDN 01.
  * Dilengkapi label jarak dinamis *real-time* (misal: `[ 65m ]`) dan otomatis menukik ke bawah (*pitch-down*) ketika mendekati zona target parkir.
* **Minimap Interaktif (Waze-Style Traffic Overlay):**
  * Menampilkan radar top-down kota, posisi SPPG, sekolah, serta posisi dan arah hadap mobil pemain.
  * Ruas jalan yang mengalami kemacetan parah atau terdapat kerumunan aksi damai ditandai dengan **highlight garis merah / oranye**, memungkinkan pemain mengambil keputusan taktis memilih jalan tikus sebelum terjebak.

---

## 6. SISTEM CUACA SEBAGAI STAGE MODIFIER (CAMPAIGN PROGRESSION)

Sistem cuaca tidak diletakkan di Menu *Setting* melainkan diintegrasikan ke dalam **Level Campaign Progression**:

### 6.1 Tahapan Kampanye Cuaca
* **Stage 1 – 5: Musim Kemarau (Dry Season - Normal)**
  * Cuaca cerah berawan dengan pencahayaan hangat.
  * Aspal kering dengan cengkeraman ban maksimal (*grip* 100%).
  * Rintangan standar: angkot ngetem dan lubang jalan normal.
* **Stage 6 – 10: Musim Hujan Tropis (Rainy Season - Hard / High Reward)**
  * Efek visual partikel hujan lebat dan aspal basah berkilau (*wet asphalt reflection*).
  * Gesekan ban berkurang (*friction coefficient* turun 30%) $\rightarrow$ Mobil lebih mudah tergelincir saat bermanuver tajam.
  * Jarak pengereman bertambah panjang, menuntut pemain mengerem lebih awal atau meng-upgrade rem cakram ABS.
  * Muncul genangan air (*puddles*): melibas genangan kencang memicu efek selip ban (*aquaplaning*).
  * **Imbalan:** Semua perolehan Koin dan Skor dikalikan **1.5x lipat**.

---

## 7. SISTEM METAGAME, EKONOMI & PROGRESI ARMADA

Koin yang dikumpulkan pemain dari hasil pengantaran memiliki peran krusial dalam siklus retensi game (*Core Economy Loop*):

### 7.1 Toko Armada Kendaraan (Vehicle Fleet Shop)
Pemain dapat membuka dan membeli kendaraan baru dengan karakteristik berkendara yang unik:

| Kendaraan | Keunggulan Spesifik | Kelemahan | Kapasitas Kuota | Harga Koin |
| :--- | :--- | :--- | :--- | :--- |
| **Motor Roda Tiga (Tossa MBG)** | Bodi sangat ramping (lebar 1.2m), lincah bermanuver di gang tikus tersempit. | Top speed lebih rendah (18 m/s), bodi ringan mudah oleng. | 1 Sekolah (Kecil) | Gratis (Starter) |
| **Mobil Pick-Up Boks MBG** | Keseimbangan sempurna antara kecepatan (24 m/s) dan stabilitas kemudi. | Membutuhkan ruang sedikit lebih lebar saat berbelok patah. | 2 Sekolah (Sedang)| 1.500 Koin |
| **Truk Boks MBG Heavy Duty** | Sangat kencang di jalan lurus (28 m/s), bodi kokoh tahan benturan rintangan. | Bodi lebar (2.4m), mustahil masuk gang tikus kecil; wajib rute protokol. | 3 Sekolah (Multi-Drop) | 4.000 Koin |

### 7.2 Bengkel Modifikasi & Upgrade (Garage Tuning)
Setiap kendaraan dapat ditingkatkan statusnya hingga Level 3:
1. **Suspensi Peredam Guncangan (Shock Absorber):**
   * *Level 1 (+0%):* Ambang batas aman lubang 14 m/s.
   * *Level 2 (+25%):* Ambang batas aman lubang 18 m/s (Biaya: 400 Koin).
   * *Level 3 (+50%):* Ambang batas aman lubang 24 m/s — Melibas jalan rusak tanpa takut makanan rusak (Biaya: 900 Koin).
2. **Insulated Thermobox & Cargo Straps:**
   * Meredam benturan pertama dari dinding/trotoar hingga 100% kerusakan diserap.
3. **Rem Cakram Sport ABS:**
   * Meningkatkan daya pengereman sebesar 35%, mengeliminasi efek tergelincir saat cuaca musim hujan.
4. **Tangki Nitro Kapasitas Ganda:**
   * Memperpanjang durasi pemakaian dorongan Nitro Boost dari 3 detik menjadi 6 detik.

---

## 8. BLUEPRINT ARSITEKTUR TEKNIS (GODOT 4)

### 8.1 Struktur Direktori Proyek
```text
res://
├── assets/
│   ├── audio/
│   │   ├── sfx/             # engine.wav, crash.wav, horn.wav, bell.wav, cheer.wav, nitro.wav
│   │   └── music/           # bgm_gameplay.ogg, bgm_menu.ogg
│   ├── models/
│   │   ├── vehicles/        # car_mbg.glb, tossa.glb, truck.glb
│   │   ├── environment/     # road_tiles.glb, buildings.glb, props.glb
│   │   └── characters/      # guru.glb, petugas.glb, warga.glb
│   └── textures/
│       └── characters/      # guru_standing.png, player_driver_standing.png, etc.
├── scenes/
│   ├── characters/
│   │   ├── npc_guru.tscn
│   │   ├── npc_warga_group.tscn
│   │   ├── npc_demonstran_crowd.tscn
│   │   └── npc_sppg_kitchen.tscn
│   ├── entities/
│   │   ├── car_mbg_visual.tscn
│   │   └── waypoint_arrow.tscn
│   ├── environment/
│   │   ├── building_school.tscn
│   │   ├── building_sppg.tscn
│   │   ├── building_warung.tscn
│   │   ├── central_fountain.tscn
│   │   ├── pothole.tscn
│   │   └── street_lamp.tscn
│   └── main.tscn            # Scene utama perkotaan MBG
└── scripts/
    ├── arcade_car.gd        # Kontroler kendaraan arcade + nitro + klakson
    ├── camera_follow.gd     # Kamera orbit smooth follow & dynamic zoom
    ├── delivery_zone.gd     # Trigger zona muat SPPG & drop-off sekolah
    ├── game_manager.gd      # Mesin state misi, timer, evaluasi skor
    ├── hud.gd               # Antarmuka HUD, status ransum, timer
    ├── minimap.gd           # Radar kota 2D real-time dengan rute & waypoint
    ├── npc_character_sprite.gd # AI pejalan kaki otonom & balon dialog
    └── waypoint_arrow.gd    # Panah penunjuk arah 3D di atas mobil
```

### 8.2 Logika Skrip Inti

#### A. Kendali Mobil Arcade & Nitro (`arcade_car.gd`)
```gdscript
extends CharacterBody3D

@export var max_speed: float = 24.0
@export var boost_speed: float = 32.0
@export var acceleration: float = 18.0
@export var brake_force: float = 30.0
@export var turn_speed: float = 3.2
@export var friction: float = 6.0
@export var steer_sensitivity: float = 1.0

var current_speed: float = 0.0
var current_steer_val: float = 0.0
var nitro_fuel: float = 100.0
var is_boosting: bool = false

func _physics_process(delta: float) -> void:
    # 1. Input Kemudi & Akselerasi
    var fwd = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
    var back = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
    var left = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
    var right = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
    var boost_pressed = Input.is_key_pressed(KEY_SPACE)

    # 2. Logika Nitro Boost
    is_boosting = boost_pressed and nitro_fuel > 0.0 and fwd
    var target_top_speed = boost_speed if is_boosting else max_speed
    if is_boosting:
        nitro_fuel = max(0.0, nitro_fuel - 25.0 * delta)

    # 3. Akselerasi / Deselerasi
    var throttle = (1.0 if fwd else 0.0) - (1.0 if back else 0.0)
    if throttle > 0.0:
        current_speed = move_toward(current_speed, target_top_speed, acceleration * delta)
    elif throttle < 0.0:
        current_speed = move_toward(current_speed, -max_speed * 0.45, brake_force * delta)
    else:
        current_speed = move_toward(current_speed, 0.0, friction * delta)

    # 4. Kemudi Sensitif Kecepatan
    var speed_ratio = clamp(abs(current_speed) / max_speed, 0.0, 1.0)
    var speed_factor = lerp(1.15, 0.65, speed_ratio)
    if abs(current_speed) > 0.2:
        var dir = 1.0 if current_speed >= 0.0 else -1.0
        rotate_y(current_steer_val * turn_speed * steer_sensitivity * speed_factor * delta * dir)

    # 5. Terapkan Gerak Fisika
    velocity = -transform.basis.z * current_speed
    velocity.y = -9.8 * delta if not is_on_floor() else 0.0
    move_and_slide()
```

#### B. Klakson Interaktif (`arcade_car.gd` - Klakson Gameplay Tool)
```gdscript
func trigger_horn() -> void:
    # Mainkan suara klakson telolet / horn SFX
    # Cari NPC / Angkot di depan dalam radius 12 meter
    var space_state = get_world_3d().direct_space_state
    var nearby_colliders = get_tree().get_nodes_in_group("pedestrian")
    for ped in nearby_colliders:
        if ped is Node3D and global_position.distance_to(ped.global_position) < 12.0:
            if ped.has_method("yield_to_horn"):
                ped.yield_to_horn(global_position)
```

---

## 9. USER INTERFACE & CONTROLS (HUD)

```text
┌─────────────────────────────────────────────────────────────┐
│ [🍱 MBG: 95%]   [⚡ NITRO: ■■■■□]   [⏱ 01:28]   [⚙️ 1.0x]   │
│                                                             │
│                      [ ▲ SDN 01: 65m ]                      │
│                                                             │
│                                           [🗺️ MINIMAP ]     │
│                                           [ (Waze-Style) ]  │
│                                                             │
│ [ ◀ ]  [ ▶ ]                     [ 📢 KLAKSON ]  [ 🚀 NITRO]│
│ (Virtual Steer)                  [ 🛑 REM     ]  [ ⚡ GAS   ]│
└─────────────────────────────────────────────────────────────┘
```

* **Keyboard Controls (PC Web / Desktop):**
  * `W` / `Panah Atas`: Gas Maju.
  * `S` / `Panah Bawah`: Rem / Mundur.
  * `A` / `D` / `Panah Kiri / Kanan`: Belok Kemudi.
  * `Spasi`: Nitro Boost / Tancap Gas Taktis.
  * `H`: Klakson (Membuka jalan macet & membubarkan kerumunan).
  * `[` / `]`: Menyesuaikan Sensitivitas Setir secara instan.
  * `C`: Reset Sudut Kamera ke Tampilan Default.
  * `R`: Mulai Ulang Misi (*Restart*).

---

## 10. RENCANA KERJA PENGEMBANGAN (ROADMAP SPRINT)

### Tahap 1: Minimum Viable Product (Selesai Dilaksanakan)
* [x] Inisialisasi arsitektur proyek Godot 4 (Renderer GL Compatibility).
* [x] Kontroler mobil arcade kinematik responsif dengan suspensi *body roll*.
* [x] Tata letak kota modular: SPPG Depot, SDN 01, Bundaran Air Mancur, Warung, Polisi, Pemadam, dan Perumahan.
* [x] Logika misi pengantaran, hitung mundur timer 90 detik, dan degradasi kondisi makanan.
* [x] Partikel VFX visual: Asap knalpot kartun, debu ban saat pengereman/drift, dan percikan benturan.
* [x] Sistem 3D Waypoint Arrow dinamis penunjuk arah tujuan dengan label jarak real-time.
* [x] Minimap 2D interaktif penunjuk haluan mobil, rute, SPPG, dan sekolah tujuan.
* [x] Ekosistem pejalan kaki hidup: Warga trotoar, siswa menyeberang di zebra cross, koki SPPG, demonstran berbaris, dan balon dialog komik interaktif.

### Tahap 2: Polish Gameplay & Balancing (Sprint Aktif)
* [ ] Integrasi mekanik Klakson Gameplay (`H`) untuk menggeser mobil lambat dan membelah kerumunan warga.
* [ ] Redesain Bensin menjadi bar Nitro Boost dan penempatan jerigen drive-thru di rute kota.
* [ ] Penerapan *Near-Miss Time Bonus* saat menyalip tipis kendaraan tanpa tabrakan.
* [ ] Overlay lalu lintas langsung (Waze Traffic merah/kuning) pada Minimap.
* [ ] Toko Garasi & Upgrade Part (Suspensi Anti-Guncang, Thermobox, dan Rem ABS).

### Tahap 3: Ekspansi Konten & Pasca-MVP
* [ ] Variasi Armada Baru: Motor Roda Tiga Tossa (Gang Tikus) dan Truk Boks Besar (Multi-Drop).
* [ ] Stage Modifier Musim Hujan: Efek jalan licin, partikel hujan lebat, dan genangan air berhadiah koin 1.5x.
* [ ] Integrasi Sistem Audio lengkap (SFX Mesin dinamis, Klakson Telolet, Benturan, Bel Sekolah, dan BGM Ceria).
* [ ] Ekspor rilis Web Browser HTML5 dan Android APK siap uji coba pengguna.

---

## 11. PANDUAN SETUP & EKSPOR GODOT ENGINE 4

1. **Persyaratan Engine:**
   * Godot Engine versi 4.2+ atau 4.3 LTS / 4.7 Stable.
2. **Konfigurasi Project Settings Penting:**
   * **Renderer:** `gl_compatibility` (OpenGL ES 3.0 / WebGL2) untuk performa optimal di browser HP dan perangkat spesifikasi rendah.
   * **Display > Window:** Ukuran viewport dasar `1280 x 720` (Landscape).
   * **Stretch Mode:** `canvas_items`, Aspect: `expand` agar antarmuka responsif di segala rasio layar ponsel pintar.
   * **Autoload:** `GameManager` terdaftar sebagai Global Singleton (`res://scripts/game_manager.gd`).
3. **Ekspor Proyek ke Web (HTML5):**
   * Masuk ke menu `Project > Export` $\rightarrow$ Tambahkan preset **Web**.
   * Pastikan ekstensi ekspor menghasilkan file `index.html` dengan header COOP/COEP aktif jika di-host di server cloud.

---
*Dokumen ini merupakan acuan resmi pengembangan game MBG Express Mobile yang telah diselaraskan dengan kaidah desain game modern untuk memastikan gameplay tetap adiktif, adil, menantang, dan menghibur.*
