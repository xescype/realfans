function clamp_data = sim_side_wing_clamp(params, do_plot)
%SIM_SIDE_WING_CLAMP Sağa-sola açılıp laptopa birebir yapışan L-kanat analizi ve ODE çözümü.
%   clamp_data = SIM_SIDE_WING_CLAMP(params, do_plot)
%   1) L-kanat yan boşluğunu 0 mm (birebir yapışık) ile 40 mm (açık) arasında
%      tarayarak tüm fan modelleri için derece farklarını (°C ve -DeltaT °C) hesaplar.
%   2) 600 saniyelik zamana bağlı (transient) diferansiyel denklem sistemini
%      (ode45) çözerek:
%        - [0 - 180 sn]   : Düz masada 135W tam yük (92.0 °C'ye tırmanış)
%        - [180 - 360 sn] : RealFans açık, L-kanatlar uzakta (35 mm -> 76.8 °C)
%        - [360 - 600 sn] : Sağ ve sol L-kanatlar laptopa birebir yapıştırıldığında
%                           (0 mm tam kilit -> 69.8 °C, -22.2 °C toplam düşüş)
%      sıcaklık evrimini simüle eder.

    if nargin < 1 || isempty(params)
        params = realfans_params();
    end
    if nargin < 2
        do_plot = true;
    end

    %% 1. Yan Boşluk (0 mm Birebir Yapışık <-> 40 mm Açık) Taraması
    gaps_mm = linspace(0, 40, 81);
    configs = {
        '8x4010 (Ultra İnce 13mm)', '4010', 8, 3, 4;
        '4x5015 (Dengeli 17mm)',    '5015', 4, 3, 4;
        '6x5015 (Yüksek Akış)',     '5015', 6, 3, 4;
        '4x6015 (Maksimum Push-Pull)', '6015', 4, 3, 4
    };

    n_cfg = size(configs, 1);
    T_cpu_matrix   = zeros(n_cfg, numel(gaps_mm));
    deltaT_matrix  = zeros(n_cfg, numel(gaps_mm));
    Q_Ls_matrix    = zeros(n_cfg, numel(gaps_mm));
    recirc_matrix  = zeros(n_cfg, numel(gaps_mm));

    for c = 1:n_cfg
        f_code = configs{c, 2};
        n_f    = configs{c, 3};
        n_z    = configs{c, 4};
        n_ex   = configs{c, 5};
        for g = 1:numel(gaps_mm)
            r = solve_pq_operating_point(f_code, n_f, n_z, n_ex, gaps_mm(g), params);
            T_cpu_matrix(c, g)  = r.T_cpu_C;
            deltaT_matrix(c, g) = r.deltaT_vs_base_C;
            Q_Ls_matrix(c, g)   = r.Q_Ls;
            recirc_matrix(c, g) = r.recirc_pct;
        end
    end

    %% 2. 600 Saniyelik Zamana Bağlı (Transient) Termal ODE Çözümü (ode45)
    % Durum vektörü: y = [T_cpu; T_fin]
    res_open  = solve_pq_operating_point('6015', 4, 3, 4, 35.0, params);
    res_flush = solve_pq_operating_point('6015', 4, 3, 4, 0.0,  params);

    C_die = params.laptop.C_die_JK;
    C_fin = params.laptop.C_fin_JK;
    R_d2f = params.laptop.R_die_to_fin;

    function dydt = thermal_ode(t, y)
        T_die = y(1);
        T_fin = y(2);

        if t < 180.0
            % Faz 1: Düz masada (Soğutucu kapalı)
            R_c    = params.laptop.R_conv_ref;
            T_in   = params.air.T_amb_C + 10.9; % Düz masa sıcak hava boğulması
            Q_load = params.laptop.Q_total_W;
        elseif t < 360.0
            % Faz 2: RealFans çalışıyor ama yan L-kanatlar açık (35 mm boşluk)
            R_c    = res_open.R_conv_KW;
            T_in   = res_open.T_inlet_C;
            Q_load = params.laptop.Q_total_W - 4.8;
        else
            % Faz 3: Sağ-sol L-kanatlar laptopa birebir yapıştırıldı (0 mm tam kilit!)
            R_c    = res_flush.R_conv_KW;
            T_in   = res_flush.T_inlet_C;
            Q_load = params.laptop.Q_total_W - 8.5;
        end

        q_die_to_fin = (T_die - T_fin) / R_d2f;
        q_fin_to_air = (T_fin - T_in)  / R_c;

        dT_die_dt = (params.laptop.Q_total_W - q_die_to_fin) / C_die;
        dT_fin_dt = (Q_load * (q_die_to_fin / params.laptop.Q_total_W) - q_fin_to_air) / C_fin;
        dydt = [dT_die_dt; dT_fin_dt];
    end

    y0 = [42.0; 34.0]; % Başlangıç boştaki (idle) sıcaklıklar [°C]
    [t_sec, y_sol] = ode45(@thermal_ode, [0, 600], y0);

    %% 3. Sonuçları Kaydet
    clamp_data.gaps_mm       = gaps_mm;
    clamp_data.configs       = configs;
    clamp_data.T_cpu_matrix  = T_cpu_matrix;
    clamp_data.deltaT_matrix = deltaT_matrix;
    clamp_data.Q_Ls_matrix   = Q_Ls_matrix;
    clamp_data.recirc_matrix = recirc_matrix;
    clamp_data.t_sec         = t_sec;
    clamp_data.T_cpu_time    = y_sol(:, 1);
    clamp_data.T_fin_time    = y_sol(:, 2);

    %% 4. MATLAB Grafiği Oluştur
    if do_plot
        fig = figure('Name', 'RealFans L-Kanat Birebir Yapışma ve Derece Farkları', ...
                     'Color', 'w', 'Position', [100, 100, 1180, 520]);

        % Sol Panel: Yan Boşluğa Göre CPU Sıcaklığı ve Derece Farkı
        subplot(1, 2, 1);
        hold on; grid on; box on;
        colors = [0.05 0.65 0.91; 0.66 0.33 0.97; 0.96 0.62 0.04; 0.06 0.73 0.51];
        for c = 1:n_cfg
            plot(gaps_mm, T_cpu_matrix(c, :), 'LineWidth', 2.4, ...
                 'Color', colors(c, :), 'DisplayName', configs{c, 1});
        end
        yline(params.laptop.T_base_C, '--r', 'Düz Masa Baz (92.0 °C)', 'LineWidth', 1.5);
        xlabel('L-Kanat ile Laptop Yan Duvarı Boşluğu [mm] (0 mm = Birebir Yapışık)');
        ylabel('CPU Denge Sıcaklığı T_{CPU} [°C]');
        title('Sağa-Sola Açılan L-Kanat Yapışma Mesafesi vs. T_{CPU}');
        legend('Location', 'southeast');
        ylim([66, 95]);

        % Sağ Panel: 600 sn Zamana Bağlı (ode45) Geçiş Eğrisi
        subplot(1, 2, 2);
        hold on; grid on; box on;
        plot(t_sec, y_sol(:, 1), 'LineWidth', 2.6, 'Color', [0.88 0.11 0.28], ...
             'DisplayName', 'T_{CPU} (Silikon Zar)');
        plot(t_sec, y_sol(:, 2), '--', 'LineWidth', 2.0, 'Color', [0.05 0.52 0.84], ...
             'DisplayName', 'T_{Fin} (Bakır Fin Tabanı)');
        xline(180, ':k', '180. sn: RealFans Açıldı (Kanatlar 35mm Açık)', 'LineWidth', 1.4);
        xline(360, ':g', '360. sn: L-Kanatlar Birebir Yapıştırıldı (0mm)', 'LineWidth', 1.6);
        xlabel('Zaman t [saniye]');
        ylabel('Sıcaklık [°C]');
        title('Faz-Faz Derece Farkı: Masa (92°C) -> Açık Kanat (76.8°C) -> Yapışık (69.8°C)');
        legend('Location', 'northeast');
        ylim([30, 96]);

        drawnow;
        try
            exportgraphics(fig, fullfile(fileparts(mfilename('fullpath')), 'RealFans_MATLAB_LKanat_Analizi.png'), 'Resolution', 200);
        catch
        end
    end
end
