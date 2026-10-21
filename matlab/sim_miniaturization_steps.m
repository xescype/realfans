function step_table = sim_miniaturization_steps(params, do_plot)
%SIM_MINIATURIZATION_STEPS RealFans adım adım küçültme (minyatürleştirme) analizi.
%   step_table = SIM_MINIATURIZATION_STEPS(params, do_plot)
%   Adım 0 (v3.0 Tam Boy) -> Adım 1 (v3.1 Ön Boşluk & Port Kesimi) ->
%   Adım 2 (v3.2 Kompakt 5015 Bar) -> Adım 3 (v3.3 Cep Boyu 4010)
%   aşamalarında hacim (cm^3), ağırlık (g), kapalı boyut (mm) ve
%   CPU derece farklarını (°C / -DeltaT °C) hesaplar.

    if nargin < 1 || isempty(params)
        params = realfans_params();
    end
    if nargin < 2
        do_plot = true;
    end

    % {AdimAdi, KapaliGenislik_mm, Derinlik_mm, Kalinlik_mm, YanKanatBoy_mm, FanKodu, FanAdet, Bolme, YanKanal, PlenumKaybi_Pa, Agirlik_g}
    steps = {
        'Adım 0 (v3.0 Tam Boy Taban)',          250, 240, 22.0, 224, '6015', 4, 3, 4,  0.0, 680;
        'Adım 1 (v3.1 Ön Kesim & Port Açık)',   230, 128, 19.0,  92, '6015', 4, 3, 4,  8.5, 390;
        'Adım 2A (v3.2 Kompakt 4x5015 Bar)',    210, 112, 16.5,  82, '5015', 4, 3, 2, 12.0, 285;
        'Adım 2B (v3.2 Odaklı 3x5015 Bar)',     195, 108, 16.5,  78, '5015', 3, 3, 2, 14.0, 245;
        'Adım 3 (v3.3 Cep Boyu 6x4010 İnce)',   185,  96, 13.5,  72, '4010', 6, 3, 2, 16.0, 180
    };

    n_s = size(steps, 1);
    StepName      = cell(n_s, 1);
    Dimensions_mm = cell(n_s, 1);
    Volume_cm3    = zeros(n_s, 1);
    VolReduction  = zeros(n_s, 1);
    Mass_g        = zeros(n_s, 1);
    Flow_Ls       = zeros(n_s, 1);
    T_CPU_Flush_C = zeros(n_s, 1);
    DeltaT_Base_C = zeros(n_s, 1);
    Noise_dBA     = zeros(n_s, 1);

    vol0 = (steps{1,2} * steps{1,3} * steps{1,4}) / 1000.0;

    for i = 1:n_s
        StepName{i}   = steps{i, 1};
        w_mm          = steps{i, 2};
        d_mm          = steps{i, 3};
        h_mm          = steps{i, 4};
        f_code        = steps{i, 6};
        n_f           = steps{i, 7};
        n_z           = steps{i, 8};
        n_ex          = steps{i, 9};
        dp_penalty    = steps{i, 10};
        Mass_g(i)     = steps{i, 11};

        Dimensions_mm{i} = sprintf('%d x %d x %.1f mm', w_mm, d_mm, h_mm);
        Volume_cm3(i)    = round((w_mm * d_mm * h_mm) / 1000.0, 0);
        VolReduction(i)  = round((1.0 - Volume_cm3(i) / vol0) * 100.0, 1);

        % Küçülen iç hacim kaynaklı hafif basınç düşümünü hesaba kat
        p_mod = params;
        p_mod.wings.p_pull_4port_Pa = params.wings.p_pull_4port_Pa + dp_penalty;
        p_mod.wings.p_pull_2port_Pa = params.wings.p_pull_2port_Pa + dp_penalty * 0.7;

        r = solve_pq_operating_point(f_code, n_f, n_z, n_ex, 0.0, p_mod);
        Flow_Ls(i)       = round(r.Q_Ls, 2);
        T_CPU_Flush_C(i) = round(r.T_cpu_C, 1);
        DeltaT_Base_C(i) = round(r.deltaT_vs_base_C, 1);
        Noise_dBA(i)     = round(r.noise_dBA, 1);
    end

    step_table = table(StepName, Dimensions_mm, Volume_cm3, VolReduction, Mass_g, ...
                       Flow_Ls, T_CPU_Flush_C, DeltaT_Base_C, Noise_dBA);

    if do_plot
        fig = figure('Name', 'RealFans Adım Adım Küçültme (Hacim vs. Sıcaklık)', ...
                     'Color', 'w', 'Position', [120, 120, 1120, 480]);

        subplot(1, 2, 1);
        yyaxis left;
        b = bar(1:n_s, Volume_cm3, 0.52, 'FaceColor', [0.20 0.58 0.92]);
        ylabel('Kapalı Gövde Hacmi [cm^3]');
        ylim([0, 1500]);

        yyaxis right;
        plot(1:n_s, T_CPU_Flush_C, '-o', 'LineWidth', 2.6, 'MarkerSize', 8, ...
             'Color', [0.06 0.73 0.51], 'MarkerFaceColor', [0.06 0.73 0.51]);
        ylabel('Birebir Yapışık T_{CPU} [°C]');
        ylim([65, 92]);

        set(gca, 'XTick', 1:n_s, 'XTickLabel', {'Adım 0 (v3.0)', 'Adım 1 (v3.1)', 'Adım 2A (4x5015)', 'Adım 2B (3x5015)', 'Adım 3 (6x4010)'});
        title('Adım Adım Küçültme: Hacim [cm^3] vs. CPU Sıcaklığı [°C]');
        grid on; box on;

        subplot(1, 2, 2);
        hold on; grid on; box on;
        scatter(Volume_cm3, abs(DeltaT_Base_C), Mass_g * 0.4, 1:n_s, 'filled', 'MarkerEdgeColor', 'k');
        for i = 1:n_s
            text(Volume_cm3(i) + 20, abs(DeltaT_Base_C(i)), ...
                 sprintf('%s\n(%d cm^3, %.1f°C)', StepName{i}, Volume_cm3(i), DeltaT_Base_C(i)), 'FontSize', 8.5);
        end
        xlabel('Gövde Hacmi [cm^3] (Düşük = Daha Küçük)');
        ylabel('Masaya Göre Net Soğutma Kazancı |\DeltaT| [°C]');
        title('Hacim Küçültme vs. Derece Farkı Verimlilik Eğrisi');
        xlim([100, 1500]); ylim([15, 25]);
    end
end
