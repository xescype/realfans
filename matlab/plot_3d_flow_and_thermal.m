function plot_3d_flow_and_thermal(laptop_width_mm, side_gap_mm, params)
%PLOT_3D_FLOW_AND_THERMAL 3B L-kanat geometrisi, hız vektörleri (quiver3) ve 2B sıcaklık alanı.
%   PLOT_3D_FLOW_AND_THERMAL(laptop_width_mm, side_gap_mm, params)
%   sağa-sola açılıp laptopa birebir yapışan (0 mm) L-kanatların 3 boyutlu
%   düzlemini, alttan basılan + yandan vakumlanan (Push-Pull) hava akış
%   vektörlerini ve XZ kesitindeki sıcaklık dağılımını (°C) çizer.

    if nargin < 1 || isempty(laptop_width_mm)
        laptop_width_mm = 360.0; % 15.6" IdeaPad Gaming 3
    end
    if nargin < 2 || isempty(side_gap_mm)
        side_gap_mm = 0.0; % 0 mm = Birebir Yapışık!
    end
    if nargin < 3 || isempty(params)
        params = realfans_params();
    end

    res_flush = solve_pq_operating_point('6015', 4, 3, 4, side_gap_mm, params);
    res_open  = solve_pq_operating_point('6015', 4, 3, 4, 35.0, params);

    fig = figure('Name', 'RealFans 3B L-Kanat Akış Alanı & Kesit Sıcaklık Haritası', ...
                 'Color', 'w', 'Position', [80, 80, 1260, 560]);

    %% Sol Panel: 3B Çok Düzlemli L-Kanat + Quiver3 Hız Vektörleri
    subplot(1, 2, 1);
    hold on; grid on; box on;
    view(-38, 26);

    lap_half = laptop_width_mm / 2.0;
    wing_x   = lap_half + side_gap_mm;

    % Alt Orta Gövde (-125..125 mm, Z=4..18 mm)
    draw_box_patch([-125, -115, 4], [250, 230, 14], [0.20 0.28 0.38], 0.35);

    % 3 Bölmeli Alt EPDM Conta (Z=18..21 mm)
    draw_box_patch([-110, -45, 18], [76, 135, 3], [0.13 0.77 0.37], 0.45);
    draw_box_patch([-26,  -35, 18], [52, 120, 3], [0.22 0.74 0.97], 0.45);
    draw_box_patch([34,   -45, 18], [76, 135, 3], [0.13 0.77 0.37], 0.45);

    % Sağ ve Sol Kızaklı L-Kanatlar (Z=4..40 mm dikey yan duvar + 1cm vakum kanalı)
    wing_col = [0.06 0.73 0.51];
    if side_gap_mm > 2
        wing_col = [0.96 0.25 0.37];
    end
    draw_box_patch([wing_x, -115, 4],       [26, 230, 36], wing_col, 0.45);
    draw_box_patch([-(wing_x+26), -115, 4], [26, 230, 36], wing_col, 0.45);

    % 1 cm'lik (Z=22..32 mm) Yan Vakum/Ejektör Yuvaları
    draw_box_patch([wing_x+1, 15, 22],       [24, 60, 10], [0.96 0.62 0.04], 0.85);
    draw_box_patch([-(wing_x+25), 15, 22],   [24, 60, 10], [0.96 0.62 0.04], 0.85);

    % Yarı Şeffaf Laptop Gövdesi (Z=21..41 mm)
    draw_box_patch([-lap_half, -115, 21], [laptop_width_mm, 230, 20], [0.55 0.65 0.78], 0.22);

    % 3B Akış Vektörleri (Alttan Mavi Emiş + Yandan Kırmızı/Sarı 1cm Egzoz Tahliyesi)
    [Xi, Yi] = meshgrid([-75, 0, 75], [-20, 25, 70]);
    Zi = 6 * ones(size(Xi));
    Ui = zeros(size(Xi)); Vi = zeros(size(Xi)); Wi = 14 * ones(size(Xi));
    quiver3(Xi, Yi, Zi, Ui, Vi, Wi, 0, 'Color', [0.02 0.55 0.90], 'LineWidth', 2.0, 'MaxHeadSize', 0.8);

    % Yan 1cm Egzoz Vektörleri (Z = 27 mm düzlemi)
    Ye = [20, 40, 60, 85];
    Xe_R = (lap_half + 2) * ones(size(Ye));
    Xe_L = -(lap_half + 2) * ones(size(Ye));
    Ze = 27 * ones(size(Ye));
    Ue_R = 38 * ones(size(Ye));
    Ue_L = -38 * ones(size(Ye));
    Ve = zeros(size(Ye));
    We = (side_gap_mm <= 2) * 8 * ones(size(Ye)) - (side_gap_mm > 2) * 12 * ones(size(Ye));

    quiver3(Xe_R, Ye, Ze, Ue_R, Ve, We, 0, 'Color', [0.92 0.18 0.32], 'LineWidth', 2.2, 'MaxHeadSize', 0.8);
    quiver3(Xe_L, Ye, Ze, Ue_L, Ve, We, 0, 'Color', [0.92 0.18 0.32], 'LineWidth', 2.2, 'MaxHeadSize', 0.8);

    xlabel('X Genişlik [mm]'); ylabel('Y Derinlik [mm]'); zlabel('Z Yükseklik [mm]');
    title(sprintf('3B Açılır-Kapanır L-Kanat (Boşluk: %.0f mm | T_{CPU}: %.1f °C | %.1f °C)', ...
          side_gap_mm, res_flush.T_cpu_C, res_flush.deltaT_vs_base_C));
    xlim([-245, 245]); ylim([-135, 135]); zlim([0, 60]);

    %% Sağ Panel: XZ Kesiti Sıcaklık Alanı (Açık Kanat vs Birebir Yapışık Farkı)
    subplot(1, 2, 2);
    [X2, Z2] = meshgrid(linspace(0, 240, 140), linspace(0, 55, 90));
    % Sıcaklık alanı modeli (°C)
    T_field = params.air.T_amb_C + ...
              (res_flush.T_cpu_C - params.air.T_amb_C) .* exp(-((X2 - 55).^2) / 2200 - ((Z2 - 28).^2) / 55) + ...
              (res_flush.T_exhaust_C - params.air.T_amb_C) .* exp(-((X2 - lap_half).^2) / 1400 - ((Z2 - 27).^2) / 42);

    contourf(X2, Z2, T_field, 24, 'LineStyle', 'none');
    hold on;
    colorbar;
    colormap(gca, 'turbo');
    caxis([25, 80]);

    % Laptop ve L-kanat sınırlarını çiz
    rectangle('Position', [0, 21, lap_half, 20], 'EdgeColor', 'w', 'LineWidth', 2.0);
    rectangle('Position', [wing_x, 4, 24, 36], 'EdgeColor', 'g', 'LineWidth', 2.2);
    text(12, 31, sprintf('CPU: %.1f °C (Bazdan %.1f °C)', res_flush.T_cpu_C, res_flush.deltaT_vs_base_C), ...
         'Color', 'w', 'FontWeight', 'bold', 'FontSize', 10);
    text(12, 10, sprintf('Açık Kanata Göre Ek Kazanç: -%.1f °C', res_open.T_cpu_C - res_flush.T_cpu_C), ...
         'Color', 'y', 'FontWeight', 'bold', 'FontSize', 9.5);

    xlabel('Merkezden Sağ Kanata Mesafe X [mm]');
    ylabel('Masadan Yükseklik Z [mm]');
    title('XZ Kesiti Sıcaklık Dağılımı [°C] ve 1 cm Yan Vakum Kilidi');

    drawnow;
    try
        exportgraphics(fig, fullfile(fileparts(mfilename('fullpath')), 'RealFans_MATLAB_3B_Akis.png'), 'Resolution', 200);
    catch
    end
end

function draw_box_patch(origin, sz, col, alpha_val)
    x0 = origin(1); y0 = origin(2); z0 = origin(3);
    dx = sz(1);     dy = sz(2);     dz = sz(3);
    V = [
        x0,    y0,    z0;
        x0+dx, y0,    z0;
        x0+dx, y0+dy, z0;
        x0,    y0+dy, z0;
        x0,    y0,    z0+dz;
        x0+dx, y0,    z0+dz;
        x0+dx, y0+dy, z0+dz;
        x0,    y0+dy, z0+dz
    ];
    F = [
        1 2 3 4;
        5 6 7 8;
        1 2 6 5;
        2 3 7 6;
        3 4 8 7;
        4 1 5 8
    ];
    patch('Vertices', V, 'Faces', F, 'FaceColor', col, 'FaceAlpha', alpha_val, ...
          'EdgeColor', col * 0.7, 'LineWidth', 1.0);
end
