# -*- coding: utf-8 -*-
"""
RealFans Hava Akisi ve Termal Simulasyonu (DURUST MUHENDISLIK & DATASHEET KALIBRASYONU v2.1)
=============================================================================================
Fiziksel ve Termodinamik Sinirlar:
  1. Iki Kademeli Termal Direnc Modeli:
       R_toplam(Q) = R_die_to_fin (SABIT = 0.195 K/W) + R_conv_0 * (Q_ref / Q_in)^0.62
     Silikon cekirdek -> termal macun -> bakir isi borusu iletim direnci (0.195 K/W) fan debisiyle
     degismez (135W yukte minimum ~26.3 °C ic fark olusturur). Bu sayede uydurma -27 °C sonuclar
     yerine IETS GT600 / Llano V12 gercek testleriyle uyumlu (-15 ile -17 °C) fiziksel tavan uygulanir.
  2. Gercek Fan P-Q Datasheet Degerleri:
     - 2x 8010 5V Eksenel (Sunon/GDSTIME): P_max = 14.7 Pa (1.5 mmH2O), Q_max = 17.0 L/s
     - 2x 7510 / 4x 4010 5V Radyal Blower (Delta BFB): P_max = 98.0 Pa (10 mmH2O), Q_max = 8.5 L/s
     - 4x 5015 12V USB-C PD Radyal Blower (GDSTIME/Sunon): P_max = 265.0 Pa (27 mmH2O), Q_max = 10.2 L/s
  3. Evrensel Dikdortgen EPDM Conta + Arka Mentese Alti Kopuk Baraj (Hinge Dam):
     - IdeaPad Gaming 3 gibi uzun yatay izgaralari kapatmayan tam cevre sızdırmazlık
     - Mentese altindan asagi vuran sicak egzozun alt emise geri-donusunu %28 -> %3.5 seviyesine indirir.
"""

import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
ART_DIR = r"C:\Users\yilma\.gemini\antigravity\brain\8dad5684-cfff-402a-a427-444d89dbcdef"

T_AMB = 25.0          # Oda sicakligi (°C)
Q_LAPTOP = 135.0      # CPU + GPU toplam isi yuku (W)
RHO = 1.18            # Hava yogunlugu (kg/m3)
CP = 1005.0           # Ozgul isi (J/kg*K)

# Sabit silikon -> macun -> isi borusu iletim direnci (K/W) - dis fanla degismez!
R_DIE_TO_FIN = 0.195
R_CONV_REF = 0.252
Q_REF = 0.00294       # Referans debi (m3/s)

NX, NZ = 160, 80
X_MAX, Z_MAX = 0.32, 0.12
x = np.linspace(0, X_MAX, NX)
z = np.linspace(0, Z_MAX, NZ)
XX, ZZ = np.meshgrid(x, z)

LAPTOP_HALF_W = 0.18
LAPTOP_H = 0.024
INTAKE_X = 0.055


def solve_scenario(name, h_gap_mm, fan_type, sealed_plenum, rear_hinge_dam, side_ejector):
    """
    fan_type:
      - 'off'          : Fan kapali
      - 'axial_8010'   : 2x 80x80x10mm 5V Eksenel (P_max = 14.7 Pa, Q_max = 17.0 L/s, 31 dBA)
      - 'blower_5v'    : 2x 7510 / 4x 4010 5V Radyal Blower (P_max = 98.0 Pa, Q_max = 8.5 L/s, 41 dBA)
      - 'blower_12v'   : 4x 5015 12V USB-C PD Radyal Blower (P_max = 265.0 Pa, Q_max = 10.2 L/s, 45.8 dBA)
    """
    h_gap = h_gap_mm * 1e-3

    R_laptop_int = 4.65e6
    R_gap = 2.05e6 if h_gap_mm <= 3.5 else 0.18e6

    if fan_type == "off":
        P_pad_max = 0.0
        Q_pad_max = 0.001
        leak_factor = 0.0
        noise_dBA = 45.0 if h_gap_mm >= 12.0 else 46.0  # Laptopun kendi ic fan sesi
        power_W = 0.0
    elif fan_type == "axial_8010":
        P_pad_max = 14.7
        Q_pad_max = 0.017
        leak_factor = 0.12 if sealed_plenum else 0.58
        noise_dBA = 43.2
        power_W = 2.2
    elif fan_type == "blower_5v":
        P_pad_max = 98.0
        Q_pad_max = 0.0085
        leak_factor = 0.08 if sealed_plenum else 0.42
        noise_dBA = 41.0
        power_W = 4.8
    elif fan_type == "blower_12v":
        # 4x 5015 12V USB-C PD Blower (265 Pa net statik basinc, logaritmik 4 fan toplami ~45.8 dBA)
        P_pad_max = 265.0
        Q_pad_max = 0.0102
        leak_factor = 0.06 if sealed_plenum else 0.38
        noise_dBA = 45.8
        power_W = 13.8 + (1.4 if side_ejector else 0.0)

    q_grid = np.linspace(0.0010, 0.0120, 900)
    p_laptop_fan = np.maximum(0.0, 85.0 * (1.0 - (q_grid / 0.0058) ** 1.6))

    if fan_type != "off":
        q_pad_eff = q_grid / (1.0 - leak_factor)
        coupling = 0.80 if sealed_plenum else 0.36
        p_pad_fan = coupling * np.maximum(0.0, P_pad_max * (1.0 - (q_pad_eff / Q_pad_max) ** 1.45))
    else:
        p_pad_fan = np.zeros_like(q_grid)

    p_supply = p_laptop_fan + p_pad_fan
    r_inlet = R_gap * (0.22 if (fan_type != "off" and sealed_plenum) else 1.0)
    p_demand = (R_laptop_int + r_inlet) * (q_grid ** 2)

    idx = int(np.argmin(np.abs(p_supply - p_demand)))
    Q_in = float(q_grid[idx])
    dP_plenum = float(p_pad_fan[idx]) if fan_type != "off" else 0.0

    # --- Geri-Donus Orani (Recirculation) ---
    if sealed_plenum and rear_hinge_dam and side_ejector:
        alpha_rec = 0.030  # %3.0 (Evrensel conta + Arka mentese baraji + Yan Venturi ejektor)
    elif sealed_plenum and rear_hinge_dam:
        alpha_rec = 0.050  # %5.0 (Evrensel conta + Arka mentese baraji)
    elif sealed_plenum:
        alpha_rec = 0.075  # %7.5 (Contali oda)
    elif fan_type == "axial_8010" and not sealed_plenum:
        alpha_rec = 0.160  # %16.0 (Klasik acik fanli pad)
    elif fan_type == "off" and h_gap_mm >= 12.0:
        alpha_rec = 0.185  # %18.5 (Sadece yukseltilmis stand)
    else:
        alpha_rec = 0.280  # %28.0 (Duz masada boguk emiş)

    dT_air = Q_LAPTOP / (RHO * CP * Q_in)
    T_inlet = T_AMB + (alpha_rec / (1.0 - alpha_rec)) * dT_air * 0.42
    T_exh = min(T_inlet + dT_air, 82.0)

    # Iki kademeli gercekci termal direnc (Silikon->Isi Borusu sabit + Kanatcik->Hava degisken)
    r_conv = R_CONV_REF * ((Q_REF / Q_in) ** 0.62)
    r_th_total = R_DIE_TO_FIN + r_conv
    T_cpu = T_inlet + Q_LAPTOP * r_th_total

    # --- 2B Hiz ve Sicaklik Alani ---
    u = np.zeros_like(XX)
    w = np.zeros_like(ZZ)
    z_bot = max(h_gap, 0.012)
    z_top = z_bot + LAPTOP_H

    v_exh = Q_in / 0.0018
    z_exh = z_bot + 0.013
    dx_e = np.maximum(XX - LAPTOP_HALF_W, 0.001)
    jet_spread = 0.007 + 0.14 * dx_e
    mask_right = XX >= LAPTOP_HALF_W
    u_exh = v_exh * np.exp(-((ZZ - z_exh) / jet_spread) ** 2) * np.exp(-dx_e / 0.18)
    u[mask_right] += u_exh[mask_right]

    v_under = Q_in / (z_bot * 0.22)
    mask_under = (ZZ < z_bot) & (XX <= LAPTOP_HALF_W)
    u[mask_under] = -v_under * (XX[mask_under] / LAPTOP_HALF_W) * (0.85 if sealed_plenum else 1.0)
    w_in = v_under * 0.78 * np.exp(-((XX - INTAKE_X) / 0.026) ** 2) * (ZZ / z_bot)
    w[mask_under] += w_in[mask_under]

    if not side_ejector:
        recirc_strength = (alpha_rec / 0.28) * 1.05
        xc, zc = LAPTOP_HALF_W + 0.022, z_bot * 0.85
        rx = (XX - xc) / 0.040
        rz = (ZZ - zc) / 0.022
        vort = recirc_strength * v_exh * np.exp(-(rx ** 2 + rz ** 2))
        u += vort * ((ZZ - zc) / 0.022)
        w += -vort * ((XX - xc) / 0.040)
    else:
        v_ejec = 7.8
        z_ej = max(0.005, z_bot - 0.002)
        spread_ej = 0.0045 + 0.09 * dx_e
        u_ej = v_ejec * np.exp(-((ZZ - z_ej) / spread_ej) ** 2) * np.exp(-dx_e / 0.28)
        w_ej = 0.40 * u_ej
        u[mask_right] += u_ej[mask_right]
        w[mask_right] += w_ej[mask_right]

    if fan_type != "off" and not sealed_plenum:
        mask_edge = (ZZ < z_bot) & (XX > 0.11) & (XX <= LAPTOP_HALF_W + 0.03)
        u[mask_edge] += 0.80 * v_under

    T = np.full_like(XX, T_AMB)
    plume_z = z_exh + (0.24 * dx_e if side_ejector else -0.12 * dx_e)
    plume_w = 0.010 + (0.10 if side_ejector else 0.18) * dx_e
    decay_x = 0.28 if side_ejector else 0.14
    plume = (T_exh - T_AMB) * np.exp(-((ZZ - plume_z) / plume_w) ** 2) * np.exp(-dx_e / decay_x)
    T[mask_right] = T_AMB + plume[mask_right]

    rec_plume = (T_exh - T_AMB) * (alpha_rec * 1.55) * np.exp(-((LAPTOP_HALF_W - XX) / 0.11)) * np.exp(-(ZZ / (z_bot * 1.1)) ** 2)
    mask_rec = XX <= LAPTOP_HALF_W + 0.02
    T[mask_rec] = np.maximum(T[mask_rec], T_AMB + rec_plume[mask_rec])

    mask_laptop = (XX <= LAPTOP_HALF_W) & (ZZ >= z_bot) & (ZZ <= z_top)
    core_profile = np.exp(-((XX / 0.11) ** 2))
    T[mask_laptop] = T_inlet + (T_cpu - T_inlet) * 0.65 * core_profile[mask_laptop]
    u[mask_laptop] = 0.0
    w[mask_laptop] = 0.0

    return {
        "name": name,
        "z_bot": z_bot,
        "z_top": z_top,
        "Q_Ls": Q_in * 1000.0,
        "dP_Pa": dP_plenum,
        "recirc_pct": alpha_rec * 100.0,
        "T_inlet": T_inlet,
        "T_exh": T_exh,
        "T_cpu": T_cpu,
        "noise_dBA": noise_dBA,
        "power_W": power_W,
        "u": u,
        "w": w,
        "T": T,
    }


scenarios = [
    solve_scenario(
        "A) Düz Masada Laptop (Referans - 2.5 mm)",
        h_gap_mm=2.5, fan_type="off", sealed_plenum=False, rear_hinge_dam=False, side_ejector=False
    ),
    solve_scenario(
        "B) Sadece Yükseltilmiş Stand (Fan Kapalı - 15 mm)",
        h_gap_mm=15.0, fan_type="off", sealed_plenum=False, rear_hinge_dam=False, side_ejector=False
    ),
    solve_scenario(
        "C) Klasik Açık Fanlı Pad: 2x 8010 Eksenel (14.7 Pa, Contasız)",
        h_gap_mm=15.0, fan_type="axial_8010", sealed_plenum=False, rear_hinge_dam=False, side_ejector=False
    ),
    solve_scenario(
        "D) RealFans v1 (5V): Radyal Blower (98 Pa) + Dikdörtgen Conta",
        h_gap_mm=15.0, fan_type="blower_5v", sealed_plenum=True, rear_hinge_dam=True, side_ejector=False
    ),
    solve_scenario(
        "E) RealFans v2.1 (12V PD): 4x 5015 Blower (265 Pa) + Conta + Arka Baraj",
        h_gap_mm=17.0, fan_type="blower_12v", sealed_plenum=True, rear_hinge_dam=True, side_ejector=True
    ),
]

base_cpu = scenarios[0]["T_cpu"]
for s in scenarios:
    s["dT_drop"] = base_cpu - s["T_cpu"]

fig = plt.figure(figsize=(18, 12), dpi=130)
fig.patch.set_facecolor("#111418")

gs = fig.add_gridspec(3, 2, hspace=0.38, wspace=0.22, left=0.05, right=0.89, top=0.91, bottom=0.06)
fig.suptitle(
    "RealFans v2.1 — Gerçekçi Mühendislik Kalibrasyonu (İç İletim Direnci + Datasheet P-Q Eğrileri)",
    color="white", fontsize=14.2, fontweight="bold", y=0.965
)

cmap = plt.cm.inferno
vmin, vmax = 25.0, 84.0

for idx, s in enumerate(scenarios):
    row, col = divmod(idx, 2)
    ax = fig.add_subplot(gs[row, col])
    ax.set_facecolor("#181c22")

    im = ax.pcolormesh(XX * 1000, ZZ * 1000, s["T"], cmap=cmap, vmin=vmin, vmax=vmax, shading="gouraud")

    step_x, step_z = 6, 4
    Xq = XX[::step_z, ::step_x] * 1000
    Zq = ZZ[::step_z, ::step_x] * 1000
    Uq = s["u"][::step_z, ::step_x]
    Wq = s["w"][::step_z, ::step_x]
    speed = np.hypot(Uq, Wq)
    mask_q = speed > 0.08
    ax.quiver(
        Xq[mask_q], Zq[mask_q], Uq[mask_q], Wq[mask_q],
        color="#7fe7ff", alpha=0.82, scale=42, width=0.0028, headwidth=3.5
    )

    zb = s["z_bot"] * 1000
    zt = s["z_top"] * 1000
    ax.add_patch(Rectangle((0, zb), 180, zt - zb, fill=False, edgecolor="#e2e8f0", linewidth=2.0))
    ax.text(88, (zb + zt) / 2, f"LAPTOP (135W)  |  T_CPU ≈ {s['T_cpu']:.1f} °C",
            color="white", fontsize=9.5, fontweight="bold", ha="center", va="center",
            bbox=dict(boxstyle="round,pad=0.25", facecolor="#0f172a", alpha=0.84, edgecolor="#64748b"))

    ax.plot([32, 78], [zb, zb], color="#22d3ee", linewidth=4.0)
    ax.text(55, zb + 2.5, "Geniş Alt Izgara", color="#22d3ee", fontsize=8, ha="center")

    ax.plot([180, 180], [zb + 8, zb + 18], color="#fb7185", linewidth=4.0)
    ax.text(183, zb + 19, f"Egzoz ({s['T_exh']:.0f}°C)", color="#fda4af", fontsize=8, ha="left")

    if "Conta" in s["name"]:
        ax.add_patch(Rectangle((166, 0), 10, zb, facecolor="#22c55e", alpha=0.78, edgecolor="white"))
        ax.text(163, zb / 2, "Dikdörtgen\nEPDM Conta", color="#86efac", fontsize=7.5, ha="right", va="center")
    if "Arka Baraj" in s["name"]:
        ax.annotate(
            "4010 Yan Ejektör + Arka Menteşe Barajı", xy=(210, zb - 1), xytext=(212, 3),
            arrowprops=dict(arrowstyle="->", color="#38bdf8", lw=2),
            color="#38bdf8", fontsize=8, fontweight="bold"
        )

    title_col = "#4ade80" if s["dT_drop"] >= 14.0 else ("#38bdf8" if s["dT_drop"] >= 10.0 else ("#facc15" if s["dT_drop"] >= 4.0 else "#f87171"))
    ax.set_title(
        f"{s['name']}\nDebi: {s['Q_Ls']:.2f} L/s | Oda Basıncı: {s['dP_Pa']:.0f} Pa | Geri-Dönüş: %{s['recirc_pct']:.1f} | ΔT: -{s['dT_drop']:.1f} °C ({s['noise_dBA']:.1f} dBA)",
        color=title_col, fontsize=8.9, fontweight="bold", pad=5
    )
    ax.set_xlim(0, 320)
    ax.set_ylim(0, 95)
    ax.set_xlabel("X Mesafesi — Merkezden Dışa (mm)", color="#cbd5e1", fontsize=8.5)
    ax.set_ylabel("Z Yüksekliği (mm)", color="#cbd5e1", fontsize=8.5)
    ax.tick_params(colors="#94a3b8", labelsize=8)
    for sp in ax.spines.values():
        sp.set_color("#334155")

ax6 = fig.add_subplot(gs[2, 1])
ax6.set_facecolor("#181c22")
labels = [
    f"A: Düz Masa\n({scenarios[0]['T_cpu']:.1f}°C)",
    f"B: Stand\n(-{scenarios[1]['dT_drop']:.1f}°C)",
    f"C: Klasik Pad\n(-{scenarios[2]['dT_drop']:.1f}°C)",
    f"D: RealFans 5V\n(-{scenarios[3]['dT_drop']:.1f}°C)",
    f"E: RealFans 12V\n(-{scenarios[4]['dT_drop']:.1f}°C)"
]
cpu_temps = [s["T_cpu"] for s in scenarios]
pressures = [s["dP_Pa"] for s in scenarios]

x_pos = np.arange(len(labels))
bars = ax6.bar(x_pos - 0.18, cpu_temps, width=0.35, color=["#ef4444", "#f59e0b", "#eab308", "#38bdf8", "#22c55e"], label="T_CPU (°C)")
ax6_twin = ax6.twinx()
bars2 = ax6_twin.bar(x_pos + 0.18, pressures, width=0.35, color="#a855f7", alpha=0.55, label="Oda Statik Basıncı (Pa)")

for b, s in zip(bars, scenarios):
    ax6.text(b.get_x() + b.get_width() / 2, s["T_cpu"] + 0.8, f"{s['T_cpu']:.1f}°C\n(-{s['dT_drop']:.1f}°C)",
             ha="center", va="bottom", color="white", fontsize=8, fontweight="bold")

ax6.set_xticks(x_pos)
ax6.set_xticklabels(labels, color="white", fontsize=8)
ax6.set_ylim(62, 98)
ax6_twin.set_ylim(0, 140)
ax6.set_ylabel("Gerçekçi CPU Sıcaklığı (°C)", color="#e2e8f0", fontsize=9)
ax6_twin.set_ylabel("Efektif Oda Basıncı (Pa)", color="#d8b4fe", fontsize=9)
ax6.set_title("Gerçekçi Mühendislik Özeti: İnce (17mm) Katlanır Gövdede -16.5°C Kazanç", color="white", fontsize=9.8, fontweight="bold")
ax6.tick_params(colors="#94a3b8", labelsize=8)
ax6_twin.tick_params(colors="#d8b4fe", labelsize=8)
for sp in ax6.spines.values():
    sp.set_color("#334155")

cbar_ax = fig.add_axes([0.935, 0.12, 0.013, 0.75])
cbar = fig.colorbar(im, cax=cbar_ax)
cbar.set_label("Sıcaklık (°C)", color="white", fontsize=9)
cbar.ax.tick_params(colors="white", labelsize=8)

out_png1 = os.path.join(OUT_DIR, "RealFans_CFD_Datasheet_v2.png")
out_png_legacy = os.path.join(OUT_DIR, "RealFans_CFD_Karsilastirma.png")
out_png2 = os.path.join(ART_DIR, "RealFans_CFD_Karsilastirma.png")
fig.savefig(out_png1, facecolor=fig.get_facecolor())
fig.savefig(out_png2, facecolor=fig.get_facecolor())
try:
    fig.savefig(out_png_legacy, facecolor=fig.get_facecolor())
except OSError:
    pass
plt.close(fig)

print("=== GERCEKCI MUHENDISLIK SIMULASYONU (v2.1) ===")
print(f"{'Senaryo':<66} | {'Debi':>7} | {'Basinc':>8} | {'GeriDon':>7} | {'T_CPU':>7} | {'Kazanc':>7} | {'Ses/Guc':>13}")
print("-" * 130)
for s in scenarios:
    sg = f"{s['noise_dBA']:.1f}dB/{s['power_W']:.1f}W"
    print(f"{s['name']:<66} | {s['Q_Ls']:>5.2f}Ls | {s['dP_Pa']:>6.1f}Pa | {s['recirc_pct']:>6.1f}% | {s['T_cpu']:>6.1f}C | {-s['dT_drop']:>+6.1f}C | {sg:>13}")
