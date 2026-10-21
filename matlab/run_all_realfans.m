%% RUN_ALL_REALFANS — RealFans Ana MATLAB Mühendislik Hesaplama ve Simülasyon Paketi
% Bu betik (script), MATLAB kurulduğunda tek tıkla (Run / F5) tüm aerodinamik,
% termodinamik, akustik ve 3B sağa-sola açılan L-kanat hesaplarını çalıştırır.
%
% Ekstra Toolbox GEREKTİRMEZ (Saf MATLAB + ode45 kullanır).
%
% Çalıştırmak için MATLAB Command Window'da:
%   >> cd('c:\Users\yilma\Desktop\ideas\realfans\matlab')
%   >> run_all_realfans

clear; clc; close all;

fprintf('=========================================================================\n');
fprintf('  REALFANS — MATLAB MÜHENDİSLİK HESABI VE L-KANAT SİMÜLASYONU (135W TDP)\n');
fprintf('=========================================================================\n\n');

%% 1. Parametre Kütüphanesini Yükle
params = realfans_params();

fprintf('[1/4] Fiziksel sabitler ve blower datasheet eğrileri yüklendi.\n');
fprintf('      - Baz (Düz Masada Laptop) T_CPU : %.1f °C\n', params.laptop.T_base_C);
fprintf('      - Zar -> Fin Sabit İletim Sınırı: %.3f K/W (Min. +%.1f °C fark)\n\n', ...
    params.laptop.R_die_to_fin, params.laptop.Q_total_W * params.laptop.R_die_to_fin);

%% 2. Sağa-Sola Açılıp Birebir Yapışan L-Kanat Derece Farkı Özeti
fprintf('[2/4] Sağa-Sola Açılıp Birebir Yapışan L-Kanat Derece Farkları (4x 6015, 3 Bölme):\n');
fprintf('-------------------------------------------------------------------------\n');
fprintf('  %-38s | %-8s | %-9s | %-11s\n', 'Senaryo / Kanat Konumu', 'Boşluk', 'T_CPU', 'Bazdan Fark');
fprintf('-------------------------------------------------------------------------\n');

r_open35 = solve_pq_operating_point('6015', 4, 3, 4, 35.0, params);
r_half10 = solve_pq_operating_point('6015', 4, 3, 4, 10.0, params);
r_flush0 = solve_pq_operating_point('6015', 4, 3, 4, 0.0,  params);

fprintf('  %-38s | %5.0f mm | %6.1f °C | %+7.1f °C\n', ...
    '0) Düz Masada Laptop (Referans Baz)', 0, params.laptop.T_base_C, 0.0);
fprintf('  %-38s | %5.0f mm | %6.1f °C | %+7.1f °C\n', ...
    '1) Kanatlar Açık / Uzakta (Sadece Alt)', 35, r_open35.T_cpu_C, r_open35.deltaT_vs_base_C);
fprintf('  %-38s | %5.0f mm | %6.1f °C | %+7.1f °C\n', ...
    '2) Kanatlar Yarı Yanaşık (Kaçaklı)', 10, r_half10.T_cpu_C, r_half10.deltaT_vs_base_C);
fprintf('  %-38s | %5.0f mm | %6.1f °C | %+7.1f °C\n', ...
    '3) BİREBİR YAPIŞIK (Tam Kilit Push-Pull)', 0, r_flush0.T_cpu_C, r_flush0.deltaT_vs_base_C);
fprintf('-------------------------------------------------------------------------\n');
fprintf('  >> Sadece L-kanatların laptopa birebir yapışmasından gelen EKSTRA kazanç: -%.1f °C!\n\n', ...
    r_open35.T_cpu_C - r_flush0.T_cpu_C);

%% 3. 12'li Parametrik Tasarım Matrisi ve Pareto Analizi
fprintf('[3/4] 12 kombinasyonlu fan boyutu, adedi ve bölme matrisi çözülüyor...\n');
results_table = sweep_parametric_matrix(params, true);
disp(results_table);

%% 4. Zamana Bağlı ODE (ode45) ve 3B Akış Alanı Görselleştirmesi
fprintf('[4/4] 600 sn zamana bağlı (ode45) termal geçiş ve 3B hız alanı çiziliyor...\n');
clamp_data = sim_side_wing_clamp(params, true);
plot_3d_flow_and_thermal(360.0, 0.0, params);

% Sonuçları .mat dosyasına kaydet
out_mat = fullfile(fileparts(mfilename('fullpath')), 'realfans_results.mat');
save(out_mat, 'params', 'results_table', 'clamp_data', 'r_open35', 'r_half10', 'r_flush0');
fprintf('\nTamamlandı! Tüm sonuçlar "%s" dosyasına ve PNG grafiklerine kaydedildi.\n', out_mat);
