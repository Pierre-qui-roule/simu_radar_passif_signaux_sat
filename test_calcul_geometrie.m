%% TEST UNITAIRE : Validation de calcul_geometrie.m
%Scénario de Test : Le radar est fixe, le satellite est juste au-dessus, immobile (pour tester le retard pur)
% ou avec une vitesse simple. Et la cible est À une distance connue (ex: 300m), immobile.
% Le Warning c'est normal : le programme calcul_geometrie essaie d'afficher une légende pour 5 satellites, 
% mais dans le test, nous n'en avons créé qu'un seul. MATLAB prévient juste qu'il ignore les 4 autres légendes. 

clear; clc; close all;

fprintf('=== LANCEMENT DU TEST UNITAIRE : GÉOMÉTRIE ===\n');

%% 1. Création d'un Scénario Contrôlé
env_data.Re = 6371e3;
env_data.c = 299792458;
env_data.fc = 11.7e9;
env_data.time = [0 1]; 
env_data.numSats = 1;

% Paramètres du test (On les définit ici pour la création)
H_sat_test = 1000e3;     % Altitude
Dist_RT_test = 300e3;    % Distance Radar-Cible

% Positions
env_data.Pos_Rx = [env_data.Re; 0; 0];
Pos_Sat = [env_data.Re + H_sat_test; 0; 0]; 
env_data.Traj_Sats = repmat(Pos_Sat, 1, 2); % [3x2] (Sat fixe pour le test pos)

Pos_Tgt = [env_data.Re; Dist_RT_test; 0];
env_data.Traj_Tgt = repmat(Pos_Tgt, 1, 2);

% Vitesses
env_data.Vit_Tgt = zeros(3, 2);
Vel_Sat = [-1000; 0; 0]; 
env_data.Vit_Sats = repmat(Vel_Sat, 1, 2); % Correction dimension [3x2]

save('donnees_scenario.mat', 'env_data');
fprintf('1. Scénario de test généré.\n');

%% 2. Exécution du Programme à Tester
if isfile('calcul_geometrie.m')
    run('calcul_geometrie.m'); 
    % ATTENTION : calcul_geometrie contient un 'clear', donc H_sat_test est effacé ici !
else
    error('Fichier introuvable !');
end

%% 3. Vérification des Résultats
load('donnees_geometrie.mat'); % Charge les résultats 'Geom'
load('donnees_scenario.mat');  % Re-charge 'env_data' pour récupérer c, Re, etc.

% --- RE-DÉFINITION DES PARAMÈTRES DU TEST (Car 'clear' les a tués) ---
H_sat = 1000e3;
Dist_RT = 300e3;
D_direct = H_sat;

% --- A. TEST DU RETARD (TAU) ---
D_SC = sqrt(H_sat^2 + Dist_RT^2);
D_TR = Dist_RT;
D_bist = D_SC + D_TR;

Tau_Theorique = (D_bist - D_direct) / env_data.c;
Tau_Calcule = Geom.Tau_Bistatic(1,1);
Erreur_Tau = abs(Tau_Theorique - Tau_Calcule);

fprintf('\n--- RÉSULTATS DU TEST ---\n');
fprintf('Retard Théorique   : %.9f s\n', Tau_Theorique);
fprintf('Retard Calculé     : %.9f s\n', Tau_Calcule);

if Erreur_Tau < 1e-9
    fprintf('✅ TEST RETARD : SUCCÈS\n');
else
    fprintf('❌ TEST RETARD : ÉCHEC (Erreur = %e s)\n', Erreur_Tau);
end

% --- B. TEST DU DOPPLER ---
lambda = env_data.c / env_data.fc;
cos_alpha = H_sat / D_SC; 
V_rate_SC = -1000 * cos_alpha;
V_rate_SR = -1000;

Rate_Bist_Theorique = V_rate_SC + 0 - V_rate_SR; 
Dop_Theorique = -Rate_Bist_Theorique / lambda;
Dop_Calcule = Geom.Doppler_Bistatic(1,1);
Erreur_Dop = abs(Dop_Theorique - Dop_Calcule);

fprintf('\nDoppler Théorique : %.2f Hz\n', Dop_Theorique);
fprintf('Doppler Calculé   : %.2f Hz\n', Dop_Calcule);

if Erreur_Dop < 1e-3
    fprintf('✅ TEST DOPPLER : SUCCÈS\n');
else
    fprintf('❌ TEST DOPPLER : ÉCHEC\n');
end
fprintf('=========================================\n');