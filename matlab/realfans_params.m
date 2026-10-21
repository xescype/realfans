function params = realfans_params()
%REALFANS_PARAMS RealFans soğutucu ve laptop termal/akışkan parametre kütüphanesi.
%   params = REALFANS_PARAMS() fonksiyonu; hava fiziksel sabitlerini,
%   Lenovo IdeaPad Gaming 3 (ve 13.3"-17.3" laptop ailesi) iç ısı borusu /
%   bakır fin geometrisini, radyal blower (4010, 5015, 6015, 7515)
%   datasheet eğrilerini ve sağa-sola açılıp laptopa birebir yapışan (0 mm)
%   L-kanat vakum/ejektör parametrelerini döndürür.
%
%   Kullanım:
%       p = realfans_params();

    %% 1. Hava ve Ortam Fiziksel Sabitleri (25 °C, 1 atm)
    params.air.T_amb_C   = 25.0;       % Ortam sıcaklığı [°C]
    params.air.rho       = 1.184;      % Yoğunluk [kg/m^3]
    params.air.cp        = 1005.0;     % Özgül ısı [J/(kg*K)]
    params.air.mu        = 1.849e-5;   % Dinamik viskozite [Pa*s]
    params.air.nu        = 1.562e-5;   % Kinematik viskozite [m^2/s]
    params.air.k         = 0.0262;     % Isıl iletkenlik [W/(m*K)]
    params.air.Pr        = 0.707;      % Prandtl sayısı [-]

    %% 2. Laptop Isıl ve Hidrolik Parametreleri (Referans: 135W Gaming Laptop)
    params.laptop.Q_cpu_W      = 45.0;   % CPU sürekli termal yük [W]
    params.laptop.Q_gpu_W      = 85.0;   % GPU sürekli termal yük [W]
    params.laptop.Q_vrm_W      = 5.0;    % Anakart / VRM / RAM yükü [W]
    params.laptop.Q_total_W    = 135.0;  % Toplam ısı yükü [W]

    % Silikon zar -> TIM -> Bakır ısı borusu -> Lehim -> Fin tabanı sabit direnci
    % (Hava debisi sonsuz olsa bile aşılamayacak iletim sınırı: 135W * 0.195 = 26.3 °C)
    params.laptop.R_die_to_fin = 0.195;  % [K/W]
    params.laptop.R_conv_ref   = 0.252;  % Düz masada referans taşınım direnci [K/W]
    params.laptop.Q_flow_ref   = 0.00294;% Düz masada referans hava debisi [m^3/s] (2.94 L/s)
    params.laptop.T_base_C     = 92.0;   % Düz masada baz CPU sıcaklığı [°C]

    % Isıl kapasitanslar (Zamana bağlı ODE çözümü için)
    params.laptop.C_die_JK     = 42.0;   % Zar + bakır blok + ısı borusu ısıl kütlesi [J/K]
    params.laptop.C_fin_JK     = 95.0;   % Bakır fin dizisi + kasa ısıl kütlesi [J/K]

    % Bakır fin kanalı geometrisi (Yan egzoz yüksekliği ~10 mm = 1 cm)
    params.laptop.fin_height_m = 0.010;  % 10 mm (1 cm) yan egzoz ağız yüksekliği
    params.laptop.fin_width_m  = 0.060;  % 60 mm egzoz ızgara genişliği (kanal başına)
    params.laptop.fin_pitch_m  = 0.0015; % 1.5 mm fin aralığı
    params.laptop.fin_thick_m  = 0.0003; % 0.3 mm bakır fin kalınlığı
    params.laptop.fin_length_m = 0.028;  % 28 mm akış yönü fin derinliği
    params.laptop.Dh_m         = 2 * (0.010 * 0.0012) / (0.010 + 0.0012); % Hidrolik çap [m]

    % Laptop iç fanları + iç hidrolik direnç
    params.laptop.P_int_max_Pa = 85.0;   % Laptop kendi fanlarının maks. statik basıncı [Pa]
    params.laptop.Q_int_max    = 0.0058; % Laptop kendi fanlarının serbest akış debisi [m^3/s]
    params.laptop.n_int_curve  = 1.60;   % İç fan P-Q eğri üssü [-]
    params.laptop.R_hyd_int    = 4.65e6; % İç fin + ızgara hidrolik direnci [Pa/(m^3/s)^2]
    params.laptop.R_hyd_inlet0 = 0.18e6; % Düz masada alt dar emiş direnci [Pa/(m^3/s)^2]

    %% 3. Desteklenen Laptop Genişlikleri (Sağa-Sola Açılan Teleskopik Kanat)
    params.chassis.closed_width_mm = 250.0; % Çanta modunda tam kapalı genişlik [mm]
    params.chassis.laptop_sizes_mm = [310.0, 360.0, 395.0]; % 13.3", 15.6", 17.3" [mm]
    params.chassis.laptop_labels   = { ...
        '13.3" / 14" Kompakt (310 mm)', ...
        '15.6" IdeaPad Gaming 3 (360 mm)', ...
        '17.3" Geniş Gaming (395 mm)' ...
    };

    %% 4. Alt Ana Radyal Blower Datasheet Kütüphanesi (12V USB-C PD)
    % Sıra: 4010, 5015, 6015, 7515
    params.fans(1).code         = '4010';
    params.fans(1).name         = '4010 Radyal Blower (40x40x10 mm)';
    params.fans(1).dia_mm       = 40;
    params.fans(1).thick_mm     = 10;
    params.fans(1).P_max_Pa     = 140.5;
    params.fans(1).Q_max_m3s    = 0.00142; % 1.42 L/s (3.0 CFM)
    params.fans(1).n_curve      = 1.38;
    params.fans(1).noise_dBA    = 34.5;
    params.fans(1).power_W      = 0.95;

    params.fans(2).code         = '5015';
    params.fans(2).name         = '5015 Radyal Blower (50x50x15 mm)';
    params.fans(2).dia_mm       = 50;
    params.fans(2).thick_mm     = 15;
    params.fans(2).P_max_Pa     = 265.0;
    params.fans(2).Q_max_m3s    = 0.00255; % 2.55 L/s (5.4 CFM)
    params.fans(2).n_curve      = 1.45;
    params.fans(2).noise_dBA    = 39.2;
    params.fans(2).power_W      = 3.10;

    params.fans(3).code         = '6015';
    params.fans(3).name         = '6015 Radyal Blower (60x60x15 mm)';
    params.fans(3).dia_mm       = 60;
    params.fans(3).thick_mm     = 15;
    params.fans(3).P_max_Pa     = 315.0;
    params.fans(3).Q_max_m3s    = 0.00375; % 3.75 L/s (7.95 CFM)
    params.fans(3).n_curve      = 1.48;
    params.fans(3).noise_dBA    = 41.0;
    params.fans(3).power_W      = 4.20;

    params.fans(4).code         = '7515';
    params.fans(4).name         = '7515 Radyal Blower (75x75x15 mm)';
    params.fans(4).dia_mm       = 75;
    params.fans(4).thick_mm     = 15;
    params.fans(4).P_max_Pa     = 380.0;
    params.fans(4).Q_max_m3s    = 0.00540; % 5.40 L/s (11.4 CFM)
    params.fans(4).n_curve      = 1.52;
    params.fans(4).noise_dBA    = 44.8;
    params.fans(4).power_W      = 6.40;

    %% 5. Alt Kutu Giriş Bölmeleme (Intake Plenum Zones: 1, 2, 3)
    % 1: Tek büyük ortak havuz
    % 2: Sol CPU + Sağ GPU bağımsız çift oda
    % 3: Sol CPU + Orta VRM/Isı Borusu Köprüsü + Sağ GPU (3 Bölme)
    params.zones(1).count       = 1;
    params.zones(1).label       = '1 Bölme (Tek Havuz)';
    params.zones(1).coupling    = 0.74;
    params.zones(1).leak_frac   = 0.080;
    params.zones(1).q_bypass_W  = 0.0;

    params.zones(2).count       = 2;
    params.zones(2).label       = '2 Bölme (Sol CPU + Sağ GPU)';
    params.zones(2).coupling    = 0.84;
    params.zones(2).leak_frac   = 0.055;
    params.zones(2).q_bypass_W  = 4.0;

    params.zones(3).count       = 3;
    params.zones(3).label       = '3 Bölme (CPU + Orta VRM + GPU)';
    params.zones(3).coupling    = 0.91;
    params.zones(3).leak_frac   = 0.040;
    params.zones(3).q_bypass_W  = 8.5;

    %% 6. Sağa-Sola Açılıp Laptopa Birebir Yapışan L-Kanat (Push-Pull) Parametreleri
    % Yan boşluk (side_gap_mm):
    %   0 mm -> Laptop yan duvarına birebir yapışık, 1cm egzoz ağzında tam vakum kilidi
    %   35-40 mm -> Kanatlar açık/uzakta, vakum etkisi kaybolur
    params.wings.decay_length_mm  = 11.5;  % Yapışma sızdırmazlık bozunum sabiti [mm]
    params.wings.vent_z_min_mm    = 22.0;  % Yan egzoz alt kotu [mm]
    params.wings.vent_z_max_mm    = 32.0;  % Yan egzoz üst kotu [mm] (10 mm = 1 cm açıklık)
    params.wings.p_back_open_Pa   = 12.0;  % Kanatlar açıkken egzoz karşı basıncı [Pa]
    params.wings.p_pull_2port_Pa  = -22.0; % 2 yan kanat yapışıkken vakum emişi [Pa]
    params.wings.p_pull_4port_Pa  = -38.0; % 2 yan + 2 arka-köşe yapışıkken vakum emişi [Pa]
    params.wings.recirc_open      = 0.095; % Kanatlar açıkken sıcak hava geri emiliş oranı (9.5%)
    params.wings.recirc_2port     = 0.018; % 2 yan kanat yapışıkken geri emiliş oranı (1.8%)
    params.wings.recirc_4port     = 0.008; % 4 kanal yapışıkken geri emiliş oranı (0.8%)
end
