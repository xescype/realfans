function realfans_interactive_gui()
%REALFANS_INTERACTIVE_GUI MATLAB içinde sürgülü canlı L-kanat ve derece farkı arayüzü.
%   MATLAB'da:
%       >> realfans_interactive_gui
%   komutuyla açılır. Yan kanat boşluğunu (0-40 mm), laptop boyutunu
%   (310, 360, 395 mm) ve fan dizilimini değiştirdikçe derece farklarını
%   anlık günceller.

    params = realfans_params();

    fig = figure('Name', 'RealFans MATLAB İnteraktif L-Kanat Simülatörü', ...
                 'Color', [0.96 0.97 0.98], 'Position', [140, 110, 1050, 600], ...
                 'NumberTitle', 'off');

    ax1 = axes('Parent', fig, 'Position', [0.07, 0.30, 0.42, 0.60]);
    ax2 = axes('Parent', fig, 'Position', [0.55, 0.30, 0.40, 0.60]);

    % Alt Kontrol Paneli
    uicontrol('Parent', fig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.06, 0.14, 0.22, 0.04], 'String', 'Kanat Yan Boşluğu (0mm = Birebir Yapışık):', ...
        'FontWeight', 'bold', 'BackgroundColor', [0.96 0.97 0.98], 'HorizontalAlignment', 'left');

    sl_gap = uicontrol('Parent', fig, 'Style', 'slider', 'Units', 'normalized', ...
        'Position', [0.06, 0.09, 0.22, 0.04], 'Min', 0, 'Max', 40, 'Value', 0, ...
        'SliderStep', [1/40, 5/40], 'Callback', @(~,~) refresh_ui());

    uicontrol('Parent', fig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.32, 0.14, 0.18, 0.04], 'String', 'Fan Boyutu ve Adedi:', ...
        'FontWeight', 'bold', 'BackgroundColor', [0.96 0.97 0.98], 'HorizontalAlignment', 'left');

    dd_fan = uicontrol('Parent', fig, 'Style', 'popupmenu', 'Units', 'normalized', ...
        'Position', [0.32, 0.09, 0.18, 0.04], ...
        'String', {'4x 6015 Blower (-22.2°C)', '6x 5015 Blower (-21.4°C)', '4x 5015 Blower (-19.8°C)', '8x 4010 İnce (-18.4°C)'}, ...
        'Value', 1, 'Callback', @(~,~) refresh_ui());

    uicontrol('Parent', fig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.53, 0.14, 0.16, 0.04], 'String', 'Alt Kutu Bölme Sayısı:', ...
        'FontWeight', 'bold', 'BackgroundColor', [0.96 0.97 0.98], 'HorizontalAlignment', 'left');

    dd_zone = uicontrol('Parent', fig, 'Style', 'popupmenu', 'Units', 'normalized', ...
        'Position', [0.53, 0.09, 0.16, 0.04], ...
        'String', {'3 Bölme (CPU+VRM+GPU)', '2 Bölme (CPU+GPU)', '1 Bölme (Tek Havuz)'}, ...
        'Value', 1, 'Callback', @(~,~) refresh_ui());

    lbl_kpi = uicontrol('Parent', fig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.72, 0.06, 0.24, 0.12], 'String', '', ...
        'FontSize', 10.5, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.88 0.96 0.91], 'ForegroundColor', [0.04 0.38 0.22]);

    function refresh_ui()
        gap_mm = get(sl_gap, 'Value');
        fan_choice = get(dd_fan, 'Value');
        zone_choice = get(dd_zone, 'Value');

        fan_map = {'6015', 4; '5015', 6; '5015', 4; '4010', 8};
        f_code  = fan_map{fan_choice, 1};
        n_fans  = fan_map{fan_choice, 2};
        n_zones = 4 - zone_choice; % 3, 2, 1

        cur      = solve_pq_operating_point(f_code, n_fans, n_zones, 4, gap_mm, params);
        open_ref = solve_pq_operating_point(f_code, n_fans, n_zones, 4, 35.0, params);

        set(lbl_kpi, 'String', sprintf( ...
            'T_CPU: %.1f °C (Bazdan %.1f °C)\nYapışma Ek Kazancı: -%.1f °C\nDebi: %.2f L/s | Ses: %.1f dBA', ...
            cur.T_cpu_C, cur.deltaT_vs_base_C, open_ref.T_cpu_C - cur.T_cpu_C, cur.Q_Ls, cur.noise_dBA));

        % Sol Grafik: Boşluk eğrisi + anlık nokta
        gaps = linspace(0, 40, 41);
        t_vec = arrayfun(@(g) solve_pq_operating_point(f_code, n_fans, n_zones, 4, g, params).T_cpu_C, gaps);
        axes(ax1); cla(ax1); hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
        plot(ax1, gaps, t_vec, 'LineWidth', 2.4, 'Color', [0.05 0.55 0.88]);
        plot(ax1, gap_mm, cur.T_cpu_C, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.06 0.73 0.51], 'MarkerEdgeColor', 'k');
        yline(ax1, 92.0, '--r', 'Baz 92.0 °C');
        xlabel(ax1, 'L-Kanat Yan Boşluğu [mm]');
        ylabel(ax1, 'T_{CPU} [°C]');
        title(ax1, sprintf('Anlık Boşluk: %.0f mm -> %.1f °C (%.1f °C)', gap_mm, cur.T_cpu_C, cur.deltaT_vs_base_C));
        ylim(ax1, [66, 95]);

        % Sağ Grafik: Sıcaklık Bar Karşılaştırması
        axes(ax2); cla(ax2); hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
        vals = [92.0, open_ref.T_cpu_C, cur.T_cpu_C, cur.T_gpu_C];
        b = bar(ax2, vals, 0.55);
        b.FaceColor = 'flat';
        b.CData = [0.92 0.25 0.34; 0.96 0.62 0.04; 0.06 0.73 0.51; 0.15 0.60 0.88];
        set(ax2, 'XTick', 1:4, 'XTickLabel', {'Baz Masa', 'Kanat Açık (35mm)', 'Şu Anki CPU', 'Şu Anki GPU'});
        ylabel(ax2, 'Sıcaklık [°C]');
        title(ax2, 'Baz Masa vs. Açık Kanat vs. Şu Anki Durum');
        ylim(ax2, [50, 98]);
    end

    refresh_ui();
end
