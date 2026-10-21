function results_table = sweep_parametric_matrix(params, do_plot)
%SWEEP_PARAMETRIC_MATRIX Fan boyutu, adedi, alt bölme ve yan L-kanat matris taraması.
%   results_table = SWEEP_PARAMETRIC_MATRIX(params, do_plot)
%   12 ana mühendislik kombinasyonunu hem L-kanatlar birebir yapışıkken (0 mm)
%   hem de kanatlar açıkken (35 mm) çözer; derece farklarını (-DeltaT °C),
%   birebir yapışma kazancını (FlushGain °C), ses seviyesini (dBA) ve
%   12V USB-C PD güç tüketimini (W) karşılaştırmalı MATLAB tablosu olarak üretir.

    if nargin < 1 || isempty(params)
        params = realfans_params();
    end
    if nargin < 2
        do_plot = true;
    end

    % {Etiket, FanKodu, FanAdedi, AltBolme, YanEgzozKanali}
    matrix_defs = {
        'A1: 2x5015 | 1 Bölme | Yan Yok',        '5015', 2, 1, 0;
        'A2: 4x5015 | 1 Bölme | Yan Yok',        '5015', 4, 1, 0;
        'A3: 4x5015 | 2 Bölme | 2 Yan L-Kanat',  '5015', 4, 2, 2;
        'A4: 4x5015 | 3 Bölme | 4 Yan L-Kanat',  '5015', 4, 3, 4;
        'B1: 6x4010 | 2 Bölme | 2 Yan L-Kanat',  '4010', 6, 2, 2;
        'B2: 8x4010 | 3 Bölme | 4 Yan L-Kanat',  '4010', 8, 3, 4;
        'C1: 6x5015 | 2 Bölme | 2 Yan L-Kanat',  '5015', 6, 2, 2;
        'C2: 6x5015 | 3 Bölme | 4 Yan L-Kanat',  '5015', 6, 3, 4;
        'D1: 2x6015 | 2 Bölme | 2 Yan L-Kanat',  '6015', 2, 2, 2;
        'D2: 4x6015 | 2 Bölme | 2 Yan L-Kanat',  '6015', 4, 2, 2;
        'D3: 4x6015 | 3 Bölme | 4 Yan L-Kanat',  '6015', 4, 3, 4;
        'E1: 2x7515 | 2 Bölme | 2 Yan L-Kanat',  '7515', 2, 2, 2
    };

    n_rows = size(matrix_defs, 1);
    ConfigName     = cell(n_rows, 1);
    FanModel       = cell(n_rows, 1);
    FanCount       = zeros(n_rows, 1);
    IntakeZones    = zeros(n_rows, 1);
    ExhaustPorts   = zeros(n_rows, 1);
    Flow_Ls        = zeros(n_rows, 1);
    NetPressure_Pa = zeros(n_rows, 1);
    T_CPU_Open_C   = zeros(n_rows, 1);
    T_CPU_Flush_C  = zeros(n_rows, 1);
    DeltaT_Base_C  = zeros(n_rows, 1);
    FlushGain_C    = zeros(n_rows, 1);
    Noise_dBA      = zeros(n_rows, 1);
    Power_W        = zeros(n_rows, 1);

    for i = 1:n_rows
        ConfigName{i}   = matrix_defs{i, 1};
        f_code          = matrix_defs{i, 2};
        n_f             = matrix_defs{i, 3};
        n_z             = matrix_defs{i, 4};
        n_ex            = matrix_defs{i, 5};

        FanModel{i}     = f_code;
        FanCount(i)     = n_f;
        IntakeZones(i)  = n_z;
        ExhaustPorts(i) = n_ex;

        r_open  = solve_pq_operating_point(f_code, n_f, n_z, n_ex, 35.0, params);
        r_flush = solve_pq_operating_point(f_code, n_f, n_z, n_ex, 0.0,  params);

        Flow_Ls(i)        = round(r_flush.Q_Ls, 2);
        NetPressure_Pa(i) = round(r_flush.dP_net_Pa, 1);
        T_CPU_Open_C(i)   = round(r_open.T_cpu_C, 1);
        T_CPU_Flush_C(i)  = round(r_flush.T_cpu_C, 1);
        DeltaT_Base_C(i)  = round(r_flush.deltaT_vs_base_C, 1);
        FlushGain_C(i)    = round(r_open.T_cpu_C - r_flush.T_cpu_C, 1);
        Noise_dBA(i)      = round(r_flush.noise_dBA, 1);
        Power_W(i)        = round(r_flush.power_W, 1);
    end

    results_table = table(ConfigName, FanModel, FanCount, IntakeZones, ExhaustPorts, ...
        Flow_Ls, NetPressure_Pa, T_CPU_Open_C, T_CPU_Flush_C, DeltaT_Base_C, ...
        FlushGain_C, Noise_dBA, Power_W);

    % CSV olarak dışa aktar
    out_csv = fullfile(fileparts(mfilename('fullpath')), 'RealFans_MATLAB_Sonuclar.csv');
    try
        writetable(results_table, out_csv);
    catch
    end

    if do_plot
        fig = figure('Name', 'RealFans Parametrik Matris & Pareto Analizi', ...
                     'Color', 'w', 'Position', [120, 120, 1220, 540]);

        % Sol Panel: Açık Kanat vs. Birebir Yapışık Kanat Derece Karşılaştırması
        subplot(1, 2, 1);
        b = barh(1:n_rows, [T_CPU_Open_C, T_CPU_Flush_C], 'grouped');
        b(1).FaceColor = [0.96 0.40 0.48];
        b(2).FaceColor = [0.06 0.73 0.51];
        set(gca, 'YTick', 1:n_rows, 'YTickLabel', ConfigName, 'YDir', 'reverse');
        xline(params.laptop.T_base_C, '--r', 'Baz 92.0 °C', 'LineWidth', 1.5);
        xlim([64, 95]);
        xlabel('CPU Denge Sıcaklığı T_{CPU} [°C]');
        title('Kanatlar Açık (35mm) vs. Birebir Yapışık (0mm) Sıcaklıklar');
        legend({'Kanatlar Açık (35 mm)', 'Birebir Yapışık (0 mm)'}, 'Location', 'southeast');
        grid on; box on;

        % Sağ Panel: Ses Seviyesi (dBA) vs. Net Derece Farkı (-DeltaT °C) Pareto Grafiği
        subplot(1, 2, 2);
        hold on; grid on; box on;
        scatter(Noise_dBA, abs(DeltaT_Base_C), Power_W * 12, T_CPU_Flush_C, 'filled', ...
                'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
        for i = 1:n_rows
            text(Noise_dBA(i) + 0.18, abs(DeltaT_Base_C(i)), ...
                 sprintf('%s (%.1f°C)', FanModel{i}, DeltaT_Base_C(i)), 'FontSize', 8.5);
        end
        xline(48.0, ':r', '48 dBA Konfor Sınırı', 'LineWidth', 1.4);
        xlabel('Toplam Akustik Gürültü [dBA]');
        ylabel('Masaya Göre Net Soğutma Kazancı |\DeltaT| [°C]');
        title('Pareto Cephesi: Ses [dBA] vs. Soğutma Kazancı [°C] (Balon Boyutu = Güç W)');
        xlim([41, 51]); ylim([9, 25]);
        colorbar;

        drawnow;
        try
            exportgraphics(fig, fullfile(fileparts(mfilename('fullpath')), 'RealFans_MATLAB_Pareto.png'), 'Resolution', 200);
        catch
        end
    end
end
