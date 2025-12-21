%% MODULE GÉOMÉTRIE : Calcul des Retards et Dopplers Bistatiques
%  Entrée : donnees_scenario.mat (Positions & Vitesses)
%  Sortie : donnees_geometrie.mat (Tau & Doppler pour les signaux)
clear; clc; close all;

%% 1. Chargement
if isfile('donnees_scenario.mat')
    load('donnees_scenario.mat');
else
    error('Fichier donnees_scenario.mat introuvable.');
end

% Récupération des données
time = env_data.time;
N = length(time);
numSats = env_data.numSats;
Pos_Rx = env_data.Pos_Rx;       % [3x1]
Vel_Rx = [0;0;0];               % Radar fixe
Pos_Tgt = env_data.Traj_Tgt;    % [3xN]
Vel_Tgt = env_data.Vit_Tgt;     % [3xN]
lambda = env_data.c / env_data.fc;

fprintf('Calcul de la géométrie bistatique pour %d satellites...\n', numSats);

%% 2. Allocation Mémoire
% On stocke les résultats sous forme [N_samples x Num_Sats]
Geom.Tau_Bistatic    = zeros(N, numSats); % Retard (s)
Geom.Doppler_Bistatic= zeros(N, numSats); % Doppler (Hz)
Geom.Dist_Directe    = zeros(N, numSats); % Pour synchro (Sat->Radar)
Geom.Dist_Cible      = zeros(N, numSats); % Trajet Sat->Cible->Radar

%% 3. Boucle de Calcul
for iSat = 1:numSats
    % Récupération trajectoire de ce satellite
    Pos_Sat = env_data.Traj_Sats(:,:,iSat); % [3xN]
    Vel_Sat = env_data.Vit_Sats(:,:,iSat);  % [3xN]
    
    for k = 1:N
        % --- A. Vecteurs Positions ---
        r_S = Pos_Sat(:, k);
        v_S = Vel_Sat(:, k);
        
        r_T = Pos_Tgt(:, k);
        v_T = Vel_Tgt(:, k);
        
        r_R = Pos_Rx;
        v_R = Vel_Rx;
        
        % --- B. Distances (Normes) ---
        R_ST = norm(r_T - r_S); % Sat -> Cible
        R_TR = norm(r_R - r_T); % Cible -> Radar
        R_SR = norm(r_R - r_S); % Sat -> Radar (Trajet Direct)
        
        % --- C. Calcul Retards (Tau) ---
        % Le retard bistatique = différence de temps par rapport au trajet direct
        % (C'est ce que mesure un radar passif synchronisé sur le direct)
        % Distance bistatique = (Sat->Cible + Cible->Radar) - (Sat->Radar)
        Dist_Bistatic = (R_ST + R_TR) - R_SR;
        
        Geom.Tau_Bistatic(k, iSat) = Dist_Bistatic / env_data.c;
        
        % On sauvegarde aussi les distances brutes pour le debug/SNR
        Geom.Dist_Directe(k, iSat) = R_SR;
        Geom.Dist_Cible(k, iSat)   = R_ST + R_TR;

        % --- D. Calcul Doppler Bistatique ---
        % Formule vectorielle : fd = -(1/lambda) * d(Dist_Bistatique)/dt
        
        % Vecteurs unitaires
        u_ST = (r_T - r_S) / R_ST;
        u_TR = (r_R - r_T) / R_TR;
        u_SR = (r_R - r_S) / R_SR;
        
        % Vitesses relatives projetées (V_proj = V_rel . u)
        % Doppler Bistatique = Dop(Sat->Cible) + Dop(Cible->Radar) - Dop(Sat->Radar)
        
        % 1. Partie (Sat -> Cible) : Mouvement relatif S vs T
        v_rate_ST = dot(v_T - v_S, u_ST);
        
        % 2. Partie (Cible -> Radar) : Mouvement relatif T vs R
        v_rate_TR = dot(v_R - v_T, u_TR);
        
        % 3. Partie (Sat -> Radar - Direct) : Mouvement relatif S vs R
        v_rate_SR = dot(v_R - v_S, u_SR);
        
        % Somme des vitesses radiales (Vitesse Bistatique)
        v_bist = v_rate_ST + v_rate_TR - v_rate_SR;
        
        % Conversion en Hz
        Geom.Doppler_Bistatic(k, iSat) = -v_bist / lambda;
    end
end

%% 4. Export
save('donnees_geometrie.mat', 'Geom');
fprintf('Succès : Géométrie calculée et sauvegardée dans "donnees_geometrie.mat"\n');

%% 5. Visualisation Rapide
figure('Name', 'Analyse Géométrie Bistatique');
subplot(2,1,1);
plot(time, Geom.Tau_Bistatic * 1e6, 'LineWidth', 2);
title('Retard Bistatique (Retard écho vs direct)');
ylabel('Retard (\mus)'); xlabel('Temps (s)'); grid on;
legend('Sat 1', 'Sat 2', 'Sat 3', 'Sat 4', 'Sat 5');

subplot(2,1,2);
plot(time, Geom.Doppler_Bistatic, 'LineWidth', 2);
title('Fréquence Doppler Bistatique');

ylabel('Doppler (Hz)'); xlabel('Temps (s)'); grid on;
