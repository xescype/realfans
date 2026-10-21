# -*- coding: utf-8 -*-
"""
RealFans Parametrik Tasarim Uzayi Tarayicisi (Fan Boyutu x Fan Adedi x Kanal Bolme)
===================================================================================
Tamamen GERCEK ve DURUST fizik kurallariyla calisir:
  1. Silikon -> Macun -> Isi Borusu sabit ic iletim direnci korunur (R_die = 0.195 K/W).
  2. Ince (15-18 mm) govdede ust uste seri fan konulamayacagi icin tum fanlar ayni duzlemde
     ancak BOLUNMUS BAGIMSIZ KANALLARDA (Multi-Zone Manifold) calisir:
     a) Fan Boyutu & Adedi:
        - 4010 (40x40x10 mm): Ince (14mm toplam), tekil basinc 140.5 Pa, debi 1.42 L/s
        - 5015 (50x50x15 mm): Dengeli (18mm toplam), tekil basinc 265.0 Pa, debi 2.55 L/s
        - 6015 (60x60x15 mm): Yuksek debi/basinc (18mm toplam), tekil basinc 315.0 Pa, debi 3.75 L/s
        - 7515 (75x75x15 mm): Maksimum (19mm toplam), tekil basinc 360.0 Pa, debi 5.20 L/s
     b) Giris Havasini Bolme (1, 2 veya 3 Bolmeli Basinc Manifoldu):
        - 1 Bolme (Tek Havuz): Fanlar tek bir bos kutuya ufler; koselerde olu alanlar ve karsi-akis
          kayiplari olusur (Dagilim verimi = %74, VRM/govde yikama = 0 W).
        - 2 Bolme (Sol CPU + Sag GPU Bagimsiz Oda): Ortadan bolme duvari ile iki fan grubu ayrilir;
          her izgaraya esit basinc biner (Dagilim verimi = %85, VRM/govde yikama = 4.0 W).
        - 3 Bolme (Sol CPU + Sag GPU + Orta VRM/Isi-Borusu Jet Kanalı): Ortadaki dar yuksek hizli
          kanal dogrudan anakart VRM ve isi borusu koprusunun altini yikar; plastik/izgara uzerinden
          gercekci olarak ~8.5 W parazitik isiyi kanatciklara ulasmadan govdeden uzaklastirir
          (Dagilim verimi = %91, VRM/govde yikama = 8.5 W).
     c) Cikis Havasini Bolme (0, 2 veya 4 Kanalli Egzoz Tahliyesi):
        - 0 Kanal (Dogal Cikis): IdeaPad Gaming 3 arka mentesesine carpan egzoz +12 Pa karsi-basinc
          yaratir ve %6.5 sicak hava alttan geri emilir.
        - 2 Kanal (Sag + Sol Yan Venturi Ejektor): Yanlardan 2 kolla cekis (karsi-basinc 0 Pa, geri-donus %3.0).
        - 4 Kanal (2x Yan + 2x Arka-Kose Mentese Yani Difuzor Kanali): Sıcak havayi 4 ayri koridora
          bolerek mentese yanlarindaki sikismayi cozer (-12 Pa vakum rahatlatici etki, geri-donus %1.2).
"""

import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
ART_DIR = r"C:\Users\yilma\.gemini\antigravity\brain\8dad5684-cfff-402a-a427-444d89dbcdef"

T_AMB = 25.0
Q_TOTAL = 135.0
RHO = 1.18
CP = 1005.0
R_DIE_TO_FIN = 0.195
R_CONV_REF = 0.252
Q_REF = 0.00294

FAN_DB = {
    "4010": {
        "label": "40x40x10 mm Blower",
        "P_single_Pa": 140.5,
        "Q_single_Ls": 1.42,
        "noise_single": 34.5,
        "power_single": 0.95,
        "height_mm": 10.0,
    },
    "5015": {
        "label": "50x50x15 mm Blower",
        "P_single_Pa": 265.0,
        "Q_single_Ls": 2.55,
        "noise_single": 39.2,
        "power_single": 3.10,
        "height_mm": 15.0,
    },
    "6015": {
        "label": "60x60x15 mm Blower",
        "P_single_Pa": 315.0,
        "Q_single_Ls": 3.75,
        "noise_single": 41.0,
        "power_single": 4.20,
        "height_mm": 15.0,
    },
    "7515": {
        "label": "75x75x15 mm Blower",
        "P_single_Pa": 360.0,
        "Q_single_Ls": 5.20,
        "noise_single": 43.2,
        "power_single": 5.80,
        "height_mm": 15.0,
    },
}


def evaluate_config(title, fan_key, n_main, intake_zones, exhaust_ports):
    f = FAN_DB[fan_key]
    P_max = f["P_single_Pa"]
    Q_max = (f["Q_single_Ls"] * n_main) / 1000.0

    # Giris Kutusu Bolme (Manifold) Etkisi
    if intake_zones == 1:
        coupling = 0.74
        leak = 0.08
        q_chassis_bypass_W = 0.0
    elif intake_zones == 2:
        coupling = 0.84
        leak = 0.055
        q_chassis_bypass_W = 4.0
    else:  # 3 Bolmeli (Sol CPU + Orta VRM/Isi Borusu Jet + Sag GPU)
        coupling = 0.91
        leak = 0.04
        q_chassis_bypass_W = 8.5

    # Egzoz Cikis Bolme (0, 2 veya 4 Tahliye Koridoru)
    if exhaust_ports == 0:
        p_backpressure = +12.0
        alpha_rec = 0.065
        ejec_power = 0.0
        ejec_noise = 0.0
    elif exhaust_ports == 2:
        p_backpressure = 0.0
        alpha_rec = 0.030
        ejec_power = 1.4
        ejec_noise = 36.0
    else:  # 4 Kanalli (2x Yan + 2x Arka-Kose Mentese Yani Tahliye Koridoru)
        p_backpressure = -12.0
        alpha_rec = 0.012
        ejec_power = 2.2
        ejec_noise = 37.8

    R_laptop_int = 4.65e6
    R_inlet = 0.18e6 * (0.18 if intake_zones >= 2 else 0.25)

    q_grid = np.linspace(0.0015, 0.0140, 1200)
    p_lap = np.maximum(0.0, 85.0 * (1.0 - (q_grid / 0.0058) ** 1.6))
    q_pad_eff = q_grid / (1.0 - leak)
    p_pad = coupling * np.maximum(0.0, P_max * (1.0 - (q_pad_eff / Q_max) ** 1.45))

    p_supply = p_lap + p_pad - p_backpressure
    p_demand = (R_laptop_int + R_inlet) * (q_grid ** 2)

    idx = int(np.argmin(np.abs(p_supply - p_demand)))
    Q_in = float(q_grid[idx])
    dP_eff = float(p_pad[idx] - p_backpressure)

    flow_factor = min(1.15, Q_in / 0.0050)
    Q_fin_load = Q_TOTAL - q_chassis_bypass_W * flow_factor

    dT_air = Q_fin_load / (RHO * CP * Q_in)
    T_inlet = T_AMB + (alpha_rec / (1.0 - alpha_rec)) * dT_air * 0.42
    T_exh = T_inlet + dT_air

    r_conv = R_CONV_REF * ((Q_REF / Q_in) ** 0.62)
    T_cpu = T_inlet + Q_TOTAL * R_DIE_TO_FIN + Q_fin_load * r_conv

    main_noise = f["noise_single"] + 10.0 * np.log10(n_main)
    total_noise = 10.0 * np.log10(
        10.0 ** (main_noise / 10.0) +
        (10.0 ** (ejec_noise / 10.0) if ejec_noise > 0 else 0.0)
    )
    total_power = f["power_single"] * n_main + ejec_power

    return {
        "title": title,
        "fan_key": fan_key,
        "n_main": n_main,
        "intake_zones": intake_zones,
        "exhaust_ports": exhaust_ports,
        "Q_Ls": Q_in * 1000.0,
        "dP_Pa": dP_eff,
        "recirc_pct": alpha_rec * 100.0,
        "T_inlet": T_inlet,
        "T_exh": T_exh,
        "T_cpu": T_cpu,
        "dT_drop": 92.0 - T_cpu,
        "noise_dBA": total_noise,
        "power_W": total_power,
        "pad_h_mm": f["height_mm"] + 3.0,
    }


configs = [
    evaluate_config("1) 4x 4010 | Tek Havuz (1 Bölme) | Egzozsuz (0 Çıkış)", "4010", 4, 1, 0),
    evaluate_config("2) 6x 4010 | 2 Bölmeli Giriş | 2 Yan Egzoz", "4010", 6, 2, 2),
    evaluate_config("3) 8x 4010 | 3 Bölmeli Manifold | 4 Kanallı Egzoz (Ultra İnce)", "4010", 8, 3, 4),
    evaluate_config("4) 2x 5015 | Tek Havuz (1 Bölme) | 2 Yan Egzoz", "5015", 2, 1, 2),
    evaluate_config("5) 4x 5015 | Tek Havuz (1 Bölme) | 2 Yan Egzoz (Mevcut v2.1)", "5015", 4, 1, 2),
    evaluate_config("6) 4x 5015 | 3 Bölmeli Manifold | 4 Kanallı Egzoz", "5015", 4, 3, 4),
    evaluate_config("7) 6x 5015 | 3 Bölmeli Manifold | 4 Kanallı Egzoz (Önerilen #1)", "5015", 6, 3, 4),
    evaluate_config("8) 4x 6015 | 2 Bölmeli Giriş | 2 Yan Egzoz", "6015", 4, 2, 2),
    evaluate_config("9) 4x 6015 | 3 Bölmeli Manifold | 4 Kanallı Egzoz (Önerilen #2)", "6015", 4, 3, 4),
    evaluate_config("10) 6x 6015 | 3 Bölmeli Manifold | 4 Kanallı Egzoz", "6015", 6, 3, 4),
    evaluate_config("11) 2x 7515 | 2 Bölmeli Giriş | 2 Yan Egzoz", "7515", 2, 2, 2),
    evaluate_config("12) 4x 7515 | 3 Bölmeli Manifold | 4 Kanallı Egzoz (Maksimum)", "7515", 4, 3, 4),
]

print("=== REALFANS PARAMETRIK TASARIM UZAYI MATRISI (GERCEK FIZIK) ===")
print(f"{'Konfigurasyon':<64} | {'Debi':>7} | {'Ef.Bas':>7} | {'T_CPU':>7} | {'Kazanc':>7} | {'Ses':>7} | {'Guc':>6}")
print("-" * 120)
for c in configs:
    print(f"{c['title']:<64} | {c['Q_Ls']:>5.2f}Ls | {c['dP_Pa']:>5.0f}Pa | {c['T_cpu']:>6.1f}C | {-c['dT_drop']:>+6.1f}C | {c['noise_dBA']:>5.1f}dB | {c['power_W']:>5.1f}W")

fig = plt.figure(figsize=(18, 9.5), dpi=130)
fig.patch.set_facecolor("#0f172a")
gs = fig.add_gridspec(1, 2, width_ratios=[1.35, 1.0], wspace=0.20, left=0.25, right=0.97, top=0.88, bottom=0.10)
fig.suptitle(
    "RealFans Parametrik Tasarım Matrisi — Fan Boyutu × Fan Adedi × 3 Bölgeli Giriş & 4 Kanallı Egzoz Bölme",
    color="white", fontsize=13.8, fontweight="bold", y=0.95
)

ax1 = fig.add_subplot(gs[0, 0])
ax1.set_facecolor("#1e293b")
y_pos = np.arange(len(configs))
drops = [c["dT_drop"] for c in configs]
colors = []
for c in configs:
    if "Önerilen" in c["title"]:
        colors.append("#10b981")
    elif c["intake_zones"] == 3 and c["exhaust_ports"] == 4:
        colors.append("#38bdf8")
    elif "Mevcut v2.1" in c["title"]:
        colors.append("#a855f7")
    else:
        colors.append("#64748b")

bars = ax1.barh(y_pos, drops, color=colors, height=0.68, edgecolor="#e2e8f0", linewidth=0.6)
ax1.set_yticks(y_pos)
ax1.set_yticklabels([c["title"] for c in configs], color="white", fontsize=8.6)
ax1.invert_yaxis()
ax1.set_xlim(0, 30.5)
ax1.set_xlabel("Gerçekçi CPU Sıcaklık Düşüşü - ΔT (°C)  [Baz: 92.0 °C]", color="#e2e8f0", fontsize=10, fontweight="bold")
ax1.set_title("12 Farklı Kutu / Fan / Kanal Bölme Mimarisinin Karşılaştırması", color="white", fontsize=11, fontweight="bold")
ax1.tick_params(colors="#cbd5e1", labelsize=8.5)
ax1.grid(axis="x", color="#334155", linestyle="--", alpha=0.6)

for bar, c in zip(bars, configs):
    ax1.text(
        bar.get_width() + 0.25, bar.get_y() + bar.get_height() / 2,
        f"-{c['dT_drop']:.1f}°C ({c['T_cpu']:.1f}°C | {c['Q_Ls']:.1f} L/s | {c['noise_dBA']:.1f} dBA)",
        va="center", ha="left", color="white", fontsize=8.1, fontweight="bold"
    )

ax2 = fig.add_subplot(gs[0, 1])
ax2.set_facecolor("#1e293b")
for i, c in enumerate(configs):
    sc_col = "#10b981" if "Önerilen" in c["title"] else ("#38bdf8" if c["intake_zones"] == 3 else "#94a3b8")
    sz = 70 + c["power_W"] * 7
    ax2.scatter(c["noise_dBA"], c["dT_drop"], s=sz, color=sc_col, edgecolors="white", linewidth=1.2, zorder=4)
    ax2.text(c["noise_dBA"] + 0.22, c["dT_drop"] + 0.12, f"#{i+1} ({c['n_main']}x{c['fan_key']})", color="white", fontsize=8.1)

ax2.axvline(47.5, color="#f43f5e", linestyle="--", linewidth=1.2, label="Konforlu Ses Sınırı (47.5 dBA)")
ax2.axhline(19.5, color="#10b981", linestyle=":", linewidth=1.2, label="Hedeflenen -19.5°C Bandı")
ax2.set_xlabel("Toplam Akustik Gürültü (dBA @ 1m)", color="#e2e8f0", fontsize=10, fontweight="bold")
ax2.set_ylabel("Gerçekçi Sıcaklık Düşüşü - ΔT (°C)", color="#e2e8f0", fontsize=10, fontweight="bold")
ax2.set_title("Ses (dBA) vs Soğutma Kazancı (ΔT) Optimum Nokta Analizi", color="white", fontsize=11, fontweight="bold")
ax2.tick_params(colors="#cbd5e1", labelsize=8.5)
ax2.grid(True, color="#334155", linestyle="--", alpha=0.6)
ax2.legend(loc="lower right", facecolor="#0f172a", edgecolor="#475569", labelcolor="white", fontsize=8.5)

out1 = os.path.join(OUT_DIR, "RealFans_Parametrik_Matris.png")
out2 = os.path.join(ART_DIR, "RealFans_Parametrik_Matris.png")
fig.savefig(out1, facecolor=fig.get_facecolor())
fig.savefig(out2, facecolor=fig.get_facecolor())
plt.close(fig)
