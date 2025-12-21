"""
Calcul du SNR radar bistatique.
Formule issue de la ref [1].

Nous supposons pour ces calculs que les variations de distances liées aux mouvements orbitaux
sont négligeables pendant le temps d'intégration, ce qui est légitimé par notre étude.
"""

# === Importations ===
import numpy as np
import matplotlib.pyplot as plt
from math import pi

# === Constantes physiques ===
c = 299792458.0          # vitesse de la lumière (m/s)
k = 1.380649e-23         # constante de Boltzmann (J/K)
T0 = 270.0               # température de référence (K)

# === Définition des systèmes de paramètres ===
systemes_params = {
    1: {
        "nom": "OneWeb", # valeurs extraites de la ref [2]
        "EIRP_sd_dBW_per4kHz": -13.4,
        "f0": 11.7e9,
        "R_T": 1.2e6,
        "B_signal": 250e6,
        "T_int": 0.226
    },
    2: {
        "nom": "Starlink", # d'après la ref [1]
        "EIRP_dBW": 27.6, # d'après la fig.16 de la ref [3]
        "f0": 11.7e9, # d'après ESOG 120 – Issue 8 - Rev. 2
        "R_T": 550e3, # orbite GEO
        "B_signal": 250e6, # d'après la ref [3]
        "T_int": 0.1
    },
    3: {
        "nom": "GPS L1 C/A", # d'après la ref [4]
        "EIRP_dBW": 24,
        "f0": 1.575e9,
        "R_T": 2.2e7,
        "B_signal": 2.046e6,
        "T_int": 1.0
    },
    4: {
        "nom": "GPS L5", # d'après la ref [5]
        "EIRP_dBW": 22.07,
        "f0": 1.176e9,
        "R_T": 2.2e7,
        "B_signal": 20.46e6,
        "T_int": 1.0
    },
    5: {
        "nom": "INTELSAT 33e", # d'après la table II de la ref [1]
        "EIRP_dBW": 43.4,
        "f0": 11e9,      # moyenne entre 10.825 et 12.575
        "R_T": 35786e3,
        "B_signal": 225e6,
        "T_int": 1
    },
    6: {
        "nom": "Galileo E1", # d'après [6]
        "EIRP_dBW": 35, # sauf cette valeur, d'après [7]
        "f0": 1.575420e9,
        "R_T": 2.3222e7,
        "B_signal": 25e6,
        "T_int": 1
    },
    7: {
        "nom": "Galileo E5", # d'après [6]
        "EIRP_dBW": 32.6, # sauf cette valeur, d'après [7]
        "f0": 1.191795e9,
        "R_T": 2.3222e7,
        "B_signal": 51e6,
        "T_int": 1
    },
    8: {
        "nom": "Étude : GPS L1 C/A",
        "EIRP_dBW": 26.5,
        "f0": 1.575e9,
        "R_T": 2.02e7,
        "B_signal": 2e6,
        "T_int": 0.5
    },
    9: {
        "nom": "Étude : GPS L5", # d'après la table II de la ref [1]
        "EIRP_dBW": 25,
        "f0": 1.176e9,
        "R_T": 2.02e7,
        "B_signal": 24e6,
        "T_int": 0.5
    },
    10: {
        "nom": "Étude : Galileo E1", # d'après la table II de la ref [1]
        "EIRP_dBW": 35,
        "f0": 1.575e9,
        "R_T": 2.3222e7,
        "B_signal": 25e6,   
        "T_int": 0.5
    },
    11: {
        "nom": "Étude : Galileo E5", # d'après la table II de la ref [1]
        "EIRP_dBW": 33,
        "f0": 1.192e9,
        "R_T": 2.3222e7,
        "B_signal": 51e6,
        "T_int": 0.5
    },
    12: {
        "nom": "Étude : DVB-S2", # d'après la table II de la ref [1]
        "EIRP_dBW": 51.0,  # moyenne entre 51 et 53.7
        "f0": 11.2e9,      # moyenne entre 10.2 et 12.2
        "R_T": 3.5786e7,
        "B_signal": 36e6,
        "T_int": 0.5
    },
    13: {
        "nom": "Étude : Starlink", # d'après la ref [1]
        "EIRP_dBW": 27.6, # d'après la fig.16 de la ref [3]
        "f0": 11.7e9, # d'après ESOG 120 – Issue 8 - Rev. 2
        "R_T": 550e3, # orbite GEO
        "B_signal": 250e6, # d'après la ref [3]
        "T_int": 0.5
    },
    14: {
        "nom": "Étude ajustée : GPS L1 C/A",
        "EIRP_dBW": 26.5,
        "f0": 1.575e9,
        "R_T": 2.02e7,
        "B_signal": 2e6,
        "T_int": 1
    },
    15: {
        "nom": "Étude ajustée : GPS L5", # d'après la table II de la ref [1]
        "EIRP_dBW": 25,
        "f0": 1.176e9,
        "R_T": 2.02e7,
        "B_signal": 24e6,
        "T_int": 1
    },
    16: {
        "nom": "Étude ajustée : Galileo E1", # d'après la table II de la ref [1]
        "EIRP_dBW": 35,
        "f0": 1.575e9,
        "R_T": 2.3222e7,
        "B_signal": 25e6,   
        "T_int": 1
    },
    17: {
        "nom": "Étude ajustée : Galileo E5", # d'après la table II de la ref [1]
        "EIRP_dBW": 33,
        "f0": 1.192e9,
        "R_T": 2.3222e7,
        "B_signal": 51e6,
        "T_int": 1
    },
    18: {
        "nom": "DVB-S2", # d'après la table II de la ref [1]
        "EIRP_dBW": 53.0,  # moyenne entre 51 et 53.7
        "f0": 11.2e9,      # moyenne entre 10.2 et 12.2
        "R_T": 3.5786e7,
        "B_signal": 36e6,
        "T_int": 1
    },
    19: {
        "nom": "Étude ajustée : Starlink", # d'après la ref [1]
        "EIRP_dBW": 27.6, # d'après la fig.16 de la ref [3]
        "f0": 11.7e9, # d'après ESOG 120 – Issue 8 - Rev. 2
        "R_T": 550e3, # orbite GEO
        "B_signal": 250e6, # d'après la ref [3]
        "T_int": 0.1
    }
}

# === Configuration des systèmes et RCS à afficher ===
# Format: {num_systeme: [liste_des_RCS_m2]}
# Exemple: configurations = {1: [10, 50], 5: [20, 100]}
configurations = {
    1: [40],
    2: [40],
    3: [40],
    4: [40],
    5: [40],
    6: [40],
    7: [40],
    18:[40],
}


# === Fonction pour calculer les paramètres dérivés ===
def calculer_parametres_systeme(params):
    """
    Calcule les paramètres dérivés selon le mode choisi.
    Retourne un dictionnaire complet des paramètres utilisables.
    """
    if "EIRP_dBW" in params:
        # Mode direct (comme le mode 1)
        return params.copy()
    else:
        # Mode avec calcul (comme le mode 2)
        # Calcul de l'EIRP spectral
        EIRP_dBW = params["EIRP_sd_dBW_per4kHz"] + 10.0 * np.log10(params["B_signal"] / 4000.0)
        
        return {
            "EIRP_dBW": EIRP_dBW,
            "f0": params["f0"],
            "R_T": params["R_T"],
            "B_signal": params["B_signal"],
            "T_int": params["T_int"]
        }

# === Utilisation et tracé ===
R_R_vals_km = np.logspace(0, 3.3, 200)       # 1 km → 2000 km
R_R_vals_m = R_R_vals_km * 1000.0

plt.figure(figsize=(8,5))

# === Fonction de calcul du SNR ===
def SNR(distance_m, sigma_m2, params):
    """
    Calcule le SNR (linéaire et dB) pour une distance récepteur→cible donnée (m)
    et une section efficace radar sigma (m²).
    """
    EIRP_W = 10**(params["EIRP_dBW"] / 10)
    lam = c / params["f0"]
    
    numerator = EIRP_W * G_rx_lin * sigma_m2 * (lam**2) * params["B_signal"] * params["T_int"]
    denominator = (4*pi)**3 * (params["R_T"]**2) * (distance_m**2) * L_s * k * T0 * params["B_signal"]
    SNR_lin = numerator / denominator
    SNR_dB = 10 * np.log10(SNR_lin)
    return SNR_lin, SNR_dB

# === Hypothèses ===
#B_noise = B_signal           # Bande de bruit équivalente                # hypothèse, bonne si filtre adapté, d'où la formule du SNR adaptée
L_s = 1.0                     # Pertes système (linéaire, 0 dB)           # hypothèse
G_rx_dBi = 35                 # Gain de l'antenne réceptrice (dBi)        # hypothèse
G_rx_lin = 10**(G_rx_dBi / 10)



# === Recherche de la distance où SNR = 16.5 dB ===
seuil_dB = 16.5
print(f"\n--- Distance pour laquelle SNR = {seuil_dB} dB ---")

# Parcours de toutes les configurations
for mode, rcs_list in configurations.items():
    params_systeme = systemes_params[mode]
    nom_systeme = params_systeme["nom"]
    params = calculer_parametres_systeme(params_systeme)
    
    print(f"\nSystème {mode}: {nom_systeme} (T_int = {params['T_int']} s)")
    
    for sigma in rcs_list:
        snr_dB = np.array([SNR(R_R, sigma, params)[1] for R_R in R_R_vals_m])
        
        # Tracé
        plt.semilogx(R_R_vals_km, snr_dB, label=f"{nom_systeme[:15]}, T_int={params['T_int']}s")
        
        # Recherche du seuil
        snr_relative = snr_dB - seuil_dB
        indices = np.where(np.diff(np.sign(snr_relative)))[0]
        
        if len(indices) > 0:
            i = indices[0]
            # interpolation linéaire sur échelle log-distance
            x1, x2 = np.log10(R_R_vals_km[i]), np.log10(R_R_vals_km[i+1])
            y1, y2 = snr_relative[i], snr_relative[i+1]  # Note: on utilise snr_relative ici
            x0 = x1 + (0 - y1) * (x2 - x1) / (y2 - y1)   # On cherche où snr_relative = 0
            R0_km = 10**x0
            print(f"  σ = {sigma:6.2f} m²  →  SNR={seuil_dB} dB vers {R0_km:8.1f} km")
        else:
            # Vérifier si le SNR est toujours au-dessus ou toujours en-dessous du seuil
            if snr_dB[0] < seuil_dB:
                print(f"  σ = {sigma:6.2f} m²  →  SNR < {seuil_dB} dB sur toute la plage")
            else:
                print(f"  σ = {sigma:6.2f} m²  →  SNR > {seuil_dB} dB sur toute la plage")

plt.axhline(y=seuil_dB, color='red', linestyle='--', linewidth=1, label=f'Seuil {seuil_dB} dB')
plt.xlabel("Distance récepteur → cible (km)")
plt.ylabel("SNR (dB)")
plt.title(f"SNR radar bistatique - Comparaison multi-systèmes")
plt.grid(True, which="both", ls="--", lw=0.5)
plt.legend()
plt.tight_layout()
plt.show()

'''
[1] P. Gomez-del-Hoyo, K. Gronowski et P. Samczynski, "The STARLINK-based passive radar: preliminary
    study and first illuminator signal measurements," dans _2022 23rd International Radar Symposium
    (IRS)_, Gdansk, Poland, 2022, pp. 258-263. doi: 10.23919/IRS54158.2022.9905046.
    Disponible: https://ieeexplore.ieee.org/document/9905046

[2] Federal Communications Commission, "Application for OneWeb Non-Geostationary Satellite System,"
    SAT-MPL-20200526-00062, Annex B, 2020. [En ligne].
    Disponible: https://fcc.report/IBFS/SAT-MPL-20200526-00062/2379706.pdf

[3] F. G. Ortiz-Gomez et al., "Optimization in VHTS Satellite System Design with Irregular Beam Coverage
    for Non-Uniform Traffic Distribution," _Remote Sensing_, vol. 13, no. 13, p. 2642, juill. 2021.
    doi: 10.3390/rs13132642.
    Disponible: https://www.mdpi.com/2072-4292/13/13/2642

[4] U.S. Space Force. (2023). IS-GPS-200N: Navstar GPS Space Segment / Navigation User Interfaces. Department
    of Defense, United States Government.
    Disponible : https://www.navcen.uscg.gov/sites/default/files/pdf/gps/IS-GPS-200N.pdf

[5] U.S. Space Force. (2020). IS-GPS-705J: Navstar GPS Space Segment / Navigation User Interfaces for
    L5. Department of Defense, United States Government.
    Disponible : https://www.gps.gov/sites/default/files/2025-07/IS-GPS-705J.pdf

[6] European Union Agency for the Space Programme (EUSPA). (2025). Galileo Open Service – Signal-In-Space Interface
    Control Document (OS SIS ICD), Issue 2.2, November 2025.
Disponible : https://www.gsc-europa.eu/sites/default/files/sites/all/files/Galileo_OS_SIS_ICD_v2.2.pdf

[7] OHB System AG. (2016). GALILEO – The European Satellite Navigation System (Space Segment) (FOC Satellite Datasheet).
Disponible : https://www.ohb-system.de/fileadmin/user_upload/galileo_foc_space_segment_datasheet.pdf
'''
