%% MAIN SIMULATION : Radar Passif OneWeb (Visualisation Pédagogique)
clear; clc; close all;

fprintf('======================================================\n');
fprintf('   SIMULATION RADAR PASSIF - VISUALISATION AVANCEE    \n');
fprintf('======================================================\n');

%% 1. CHARGEMENT
if ~isfile('donnees_geometrie.mat') || ~isfile('donnees_scenario.mat')
    error('Données manquantes. Lancez trajectoire_export puis calcul_geometrie.');
end
load('donnees_geometrie.mat'); load('donnees_scenario.mat');

if isfield(env_data, 'dt'), dt_simu = env_data.dt; else, dt_simu = env_data.time(2)-env_data.time(1); end

params.Fs = 300e6; params.B_signal = 240e6; params.fc = 11.7e9;
params.N_snapshot = 60000; params.Noise_dBm = -100;

Tracks = cell(env_data.numSats, 1); 

%% 2. PRÉPARATION VISUALISATION (4 Graphes pour Sat 1)
fig_proc = figure('Name', 'Chaîne de Traitement (Sat 1)', 'Position', [50 100 1400 800]);
% On prépare la disposition plus tard dans la boucle

fig_track = figure('Name', 'Suivi des Pistes', 'Position', [1000 100 600 400]);

%% 3. BOUCLE DE SIMULATION
indices_temps = 1 : round(1.0/dt_simu) : length(env_data.time); % Pas de 1 seconde

for k = indices_temps
    t_actuel = env_data.time(k);
    fprintf('\n⏱️ T = %.2f s ... ', t_actuel);
    
    % A. SCÈNE
    [S_surv, S_refs] = generer_scene_complete(Geom, k, params);
    
    % B. TRAITEMENT
    for iSat = 1:env_data.numSats
        Sig_Ref = S_refs(:, iSat);
        Sig_Surv = S_surv.';
        
        T_CPI = params.N_snapshot / params.Fs;
        
        % Zone de recherche
        Max_Dist = 200e3; % 200 km max
        Max_Lag = ceil((Max_Dist/3e8) * params.Fs);
        Max_Dop = 10000; % +/- 10 kHz
        
        % --- DEMONSTRATION : ON FAIT LE CALCUL 2 FOIS POUR COMPARER ---
        
        if iSat == 1
            % 1. Calcul SANS ECA (Interférence présente)
            [CAF_Sale, tau_ax, fd_ax] = traitement_signal(Sig_Ref, Sig_Surv, params.Fs, T_CPI, ones(size(Sig_Ref)), 0, 0, Max_Lag, Max_Dop);
            
            % 2. Calcul AVEC ECA (Interférence annulée)
            % ECA_Taps = 10, Mu = 0.8 (Agressif)
            [CAF_Propre, ~, ~] = traitement_signal(Sig_Ref, Sig_Surv, params.Fs, T_CPI, ones(size(Sig_Ref)), 20, 0.5, Max_Lag, Max_Dop);
            
            % --- VISUALISATION 4 PANNEAUX (Votre demande) ---
            set(0, 'CurrentFigure', fig_proc);
            
            % Graphe 1 : CAF "Sale" (Dominée par le Direct)
            subplot(2,2,1);
            mesh(fd_ax/1000, tau_ax/params.Fs*3e8/1000, CAF_Sale);
            view(2); shading flat; colormap('jet'); colorbar;
            title('1. CAF Brute (Sans ECA)'); ylabel('Dist (km)');
            caxis([max(CAF_Sale(:))-50, max(CAF_Sale(:))]); % Dynamique haute
            
            % Graphe 2 : Coupe Doppler (Pour voir le masquage)
            subplot(2,2,2);
            plot(tau_ax/params.Fs*3e8/1000, max(CAF_Sale, [], 2), 'r'); hold on;
            plot(tau_ax/params.Fs*3e8/1000, max(CAF_Propre, [], 2), 'b'); hold off;
            title('2. Coupe Distance (Rouge=Brut, Bleu=Nettoyé)');
            legend('Brut (Sat)', 'Nettoyé (Cible?)'); grid on; xlim([0 150]);
            
            % Graphe 3 : CAF "Propre" (Après ECA)
            subplot(2,2,3);
            mesh(fd_ax/1000, tau_ax/params.Fs*3e8/1000, CAF_Propre);
            view(2); shading flat; colorbar;
            title('3. CAF Nettoyée (Avec ECA)'); ylabel('Dist (km)'); xlabel('Doppler (kHz)');
            
            % Graphe 4 : Zoom 3D sur la cible
            subplot(2,2,4);
            % On masque le zéro pour le zoom (suppression visuelle du résidu direct)
            CAF_Zoom = CAF_Propre;
            mask_zero = abs(tau_ax/params.Fs*3e8) < 2000; % Masque < 2km
            CAF_Zoom(mask_zero, :) = min(CAF_Zoom(:));
            
            surf(fd_ax/1000, tau_ax/params.Fs*3e8/1000, CAF_Zoom);
            shading interp; title('4. Zoom Cible (3D)'); 
            zlabel('Amplitude (dB)'); xlim([-10 10]); ylim([50 150]); % Zoom zone avion
            view(-45, 45); % Vue 3D sympa
            
            drawnow;
            
            % Pour la détection, on utilise le résultat propre
            CAF_Finale = CAF_Propre;
        else
            % Pour les autres sats, calcul standard unique (ECA activé)
            [CAF_Finale, tau_ax, fd_ax] = traitement_signal(Sig_Ref, Sig_Surv, params.Fs, T_CPI, ones(size(Sig_Ref)), 20, 0.5, Max_Lag, Max_Dop);
        end
        
        % --- DÉTECTION INTELLIGENTE ---
        % On masque physiquement la zone autour de 0 km (Résidu Direct)
        dist_vec = tau_ax/params.Fs*299792458;
        mask_direct = abs(dist_vec) < 3000; % On ignore tout ce qui est < 3km
        CAF_Finale(mask_direct, :) = -200; % On écrase le zéro
        
        [max_val, idx_max] = max(CAF_Finale(:));
        snr_est = max_val - mean(CAF_Finale(:));
        
        if snr_est > 10 % Seuil
            [idx_tau, idx_fd] = ind2sub(size(CAF_Finale), idx_max);
            z_range = dist_vec(idx_tau);
            z_doppler = fd_ax(idx_fd);
            
            fprintf('[Sat %d : DETECTÉ à %.1f km] ', iSat, z_range/1000);
            Tracks{iSat} = [Tracks{iSat}; [t_actuel, z_range, z_doppler]];
        end
    end
    
    % --- UPDATE TRACKING ---
    set(0, 'CurrentFigure', fig_track);
    clf; hold on; grid on;
    colors = lines(env_data.numSats);
    for i = 1:env_data.numSats
        % Vérité
        dist_vraie = Geom.Dist_Cible(:,i) - Geom.Dist_Directe(:,i);
        plot(env_data.time, dist_vraie/1000, '-', 'Color', [0.7 0.7 0.7]);
        % Mesures
        track = Tracks{i};
        if ~isempty(track)
            plot(track(:,1), track(:,2)/1000, 'x', 'Color', colors(i,:), 'LineWidth', 2);
        end
    end
    xlabel('Temps (s)'); ylabel('Distance Bistatique (km)');
    title(sprintf('Tracking (t=%.1f s)', t_actuel)); ylim([0 200]);
    drawnow;
end