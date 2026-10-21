function res = solve_pq_operating_point(fan_code, n_fans, n_zones, n_exhaust_ports, side_gap_mm, params)
%SOLVE_PQ_OPERATING_POINT RealFans P-Q çalışma noktası ve termal denge çözücüsü.
%   res = SOLVE_PQ_OPERATING_POINT(fan_code, n_fans, n_zones, n_exhaust_ports, side_gap_mm, params)
%   alt radyal blower dizisi, 3 bölmeli plenum sızdırmazlığı ve sağa-sola
%   açılıp laptopun 1 cm'lik yan egzozuna birebir yapışan (0 mm) L-kanat
%   vakum/ejektör sisteminin ortak çalışma noktasını (Q*, dP*) ve
%   CPU/GPU/VRM sıcaklıklarını (°C ve -DeltaT °C) hesaplar.
%
%   Girdiler:
%       fan_code        : '4010', '5015', '6015' veya '7515'
%       n_fans          : Alt ana blower adedi (2, 4, 6, 8)
%       n_zones         : Alt kutu giriş bölme sayısı (1, 2 veya 3)
%       n_exhaust_ports : Yan L-kanat aktif vakum kanal sayısı (0, 2 veya 4)
%       side_gap_mm     : L-kanat ile laptop yan duvarı arasındaki boşluk [mm]
%                         (0 mm = Birebir Yapışık / Tam Kilit, 35 mm = Açık)
%       params          : realfans_params() çıktısı (opsiyonel)

    if nargin < 6 || isempty(params)
        params = realfans_params();
    end

    %% 1. Fan ve Bölme Parametrelerini Seç
    fan_idx = find(strcmpi({params.fans.code}, fan_code), 1);
    if isempty(fan_idx)
        error('Geçersiz fan kodu: %s. (4010, 5015, 6015, 7515 kullanın)', fan_code);
    end
    fan = params.fans(fan_idx);

    zone_idx = min(max(round(n_zones), 1), 3);
    zone = params.zones(zone_idx);

    P_pad_max = fan.P_max_Pa;
    Q_pad_max = fan.Q_max_m3s * n_fans;
    n_exp     = fan.n_curve;

    %% 2. Yan L-Kanat Birebir Yapışma (Flush Clamp) ve Vakum Etkisi
    % side_gap_mm = 0 mm olduğunda flush_factor = 1.0 (Tam Yapışık Push-Pull)
    flush_factor = exp(-max(0, side_gap_mm) / params.wings.decay_length_mm);

    if n_exhaust_ports == 0
        p_pull_target = 6.0;
        recirc_target = 0.065;
        ejec_noise    = 0.0;
        ejec_power    = 0.0;
    elseif n_exhaust_ports == 2
        p_pull_target = params.wings.p_pull_2port_Pa; % -22 Pa vakum
        recirc_target = params.wings.recirc_2port;    % %1.8 geri emiliş
        ejec_noise    = 35.8;
        ejec_power    = 1.40;
    else
        p_pull_target = params.wings.p_pull_4port_Pa; % -38 Pa vakum (2 yan + 2 arka-köşe)
        recirc_target = params.wings.recirc_4port;    % %0.8 geri emiliş
        ejec_noise    = 37.5;
        ejec_power    = 2.20;
    end

    % Kanat yan boşluğuna göre efektif egzoz karşı basıncı [Pa] ve geri emiliş [-]
    p_back_Pa  = params.wings.p_back_open_Pa * (1.0 - flush_factor) + p_pull_target * flush_factor;
    alpha_rec  = params.wings.recirc_open * (1.0 - flush_factor) + recirc_target * flush_factor;

    %% 3. Hidrolik Direnç ve P-Q Çalışma Noktası Çözümü
    R_int   = params.laptop.R_hyd_int;
    if n_zones >= 2
        R_inlet = params.laptop.R_hyd_inlet0 * 0.18;
    else
        R_inlet = params.laptop.R_hyd_inlet0 * 0.25;
    end
    R_total_hyd = R_int + R_inlet;

    % Yüksek yoğunluklu ızgara araması + yerel kök bulma (fzero)
    q_grid = linspace(0.0010, 0.0150, 2000);
    p_lap_vec = max(0, params.laptop.P_int_max_Pa .* ...
        (1.0 - (q_grid ./ params.laptop.Q_int_max).^params.laptop.n_int_curve));

    q_pad_eff = q_grid ./ (1.0 - zone.leak_frac);
    p_pad_vec = zone.coupling .* max(0, P_pad_max .* ...
        (1.0 - (q_pad_eff ./ max(1e-4, Q_pad_max)).^n_exp));

    p_supply_vec = p_lap_vec + p_pad_vec - p_back_Pa;
    p_demand_vec = R_total_hyd .* (q_grid.^2);

    [~, idx_best] = min(abs(p_supply_vec - p_demand_vec));
    Q_star = q_grid(idx_best);
    dP_pad_star = p_pad_vec(idx_best);

    %% 4. Bakır Fin Kanallarında Reynolds, Nusselt ve Taşınım Direnci
    % Toplam egzoz kesit alanı (sol + sağ kanat ızgaraları)
    A_free_flow = 2 * params.laptop.fin_height_m * params.laptop.fin_width_m * ...
        ((params.laptop.fin_pitch_m - params.laptop.fin_thick_m) / params.laptop.fin_pitch_m);
    v_channel   = Q_star / A_free_flow;
    Re_Dh       = (v_channel * params.laptop.Dh_m) / params.air.nu;

    % Gelişmekte olan laminer/geçiş akışı Nusselt korelasyonu (Sieder-Tate)
    Gz_num      = Re_Dh * params.air.Pr * (params.laptop.Dh_m / params.laptop.fin_length_m);
    Nu_Dh       = max(3.66, 1.86 * (Gz_num^(1/3)));
    h_conv      = (Nu_Dh * params.air.k) / params.laptop.Dh_m;

    % Kalibre edilmiş taşınım direnci (R_conv ~ Q^-0.62)
    R_conv_KW   = params.laptop.R_conv_ref * ((params.laptop.Q_flow_ref / Q_star)^0.62);

    %% 5. Çok Bölmeli Alt Kutu Bypass Soğutması ve Sıcaklık Düğümü Çözümü
    flow_factor = min(1.18, Q_star / 0.0050);
    Q_bypass_W  = zone.q_bypass_W * flow_factor * (0.55 + 0.45 * flush_factor);
    Q_fin_load  = params.laptop.Q_total_W - Q_bypass_W;

    % Hava sıcaklık artışı ve geri emiliş kaynaklı giriş sıcaklığı
    dT_air_C    = Q_fin_load / (params.air.rho * params.air.cp * Q_star);
    T_inlet_C   = params.air.T_amb_C + (alpha_rec / (1.0 - alpha_rec)) * dT_air_C * 0.42;
    T_exhaust_C = min(82.0, T_inlet_C + dT_air_C);

    % Fin tabanı ve CPU/GPU/VRM sıcaklıkları [°C]
    T_fin_C     = T_inlet_C + Q_fin_load * R_conv_KW;
    T_cpu_C     = T_fin_C + params.laptop.Q_total_W * params.laptop.R_die_to_fin;
    T_gpu_C     = T_cpu_C - 3.8; % GPU zar alanı daha geniş olduğu için ~3.8 °C daha serin
    T_vrm_C     = T_inlet_C + 28.5 - 1.15 * Q_bypass_W;

    %% 6. Akustik (dBA) ve Elektriksel Güç (12V USB-C PD) Hesabı
    L_main_dBA  = fan.noise_dBA + 10.0 * log10(n_fans);
    if ejec_noise > 0
        noise_dBA = 10.0 * log10(10^(L_main_dBA / 10.0) + 10^(ejec_noise / 10.0));
    else
        noise_dBA = L_main_dBA;
    end
    power_W = n_fans * fan.power_W + ejec_power;

    %% 7. Çıktı Yapısını Doldur
    res.fan_code          = fan.code;
    res.n_fans            = n_fans;
    res.n_zones           = n_zones;
    res.n_exhaust_ports   = n_exhaust_ports;
    res.side_gap_mm       = side_gap_mm;
    res.flush_factor      = flush_factor;

    res.Q_m3s             = Q_star;
    res.Q_Ls              = Q_star * 1000.0;
    res.Q_CFM             = Q_star * 2118.88;
    res.v_channel_ms      = v_channel;
    res.Re_Dh             = Re_Dh;
    res.Nu_Dh             = Nu_Dh;
    res.h_conv_Wm2K       = h_conv;

    res.dP_pad_Pa         = dP_pad_star;
    res.dP_back_Pa        = p_back_Pa;
    res.dP_net_Pa         = dP_pad_star - p_back_Pa;
    res.recirc_pct        = alpha_rec * 100.0;

    res.R_conv_KW         = R_conv_KW;
    res.R_die_to_fin_KW   = params.laptop.R_die_to_fin;
    res.R_total_KW        = params.laptop.R_die_to_fin + R_conv_KW;

    res.T_inlet_C         = T_inlet_C;
    res.T_exhaust_C       = T_exhaust_C;
    res.T_fin_C           = T_fin_C;
    res.T_cpu_C           = T_cpu_C;
    res.T_gpu_C           = T_gpu_C;
    res.T_vrm_C           = T_vrm_C;
    res.deltaT_vs_base_C  = T_cpu_C - params.laptop.T_base_C; % Negatif değer = soğutma kazancı (-°C)

    res.noise_dBA         = noise_dBA;
    res.power_W           = power_W;
    res.current_12V_A     = power_W / 12.0;
end
