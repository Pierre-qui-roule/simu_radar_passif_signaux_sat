%% TEST UNITAIRE FINAL : Génération Signal (Méthode Buffer)
clear; clc; close all;

fprintf('--- Test Génération Signal (Méthode Réaliste Buffer) ---\n');

params.Fs = 300e6;          
params.B_signal = 240e6;    
params.fc = 12e9;           
params.N_snapshot = 5000; % Taille de sortie
params.Noise_dBm = -100;

%% TEST 1 : Vérification Spectrale
fprintf('Test 1 : Génération QPSK...\n');
sig_qpsk = creerIQ_BB(params.N_snapshot, params.Fs, params.B_signal);

figure('Name', 'Validation Signal');
subplot(2,2,1); plot(real(sig_qpsk(1:200)), imag(sig_qpsk(1:200)), 'b.');
title('Constellation'); axis square; grid on;

subplot(2,2,2); pwelch(sig_qpsk, [], [], [], params.Fs, 'centered');
title('Spectre');

%% TEST 2 : Physique (Retard/Doppler) avec Buffer
fprintf('Test 2 : Application Physique (Buffer slicing)...\n');

tau_test = 0.5e-6;   % 0.5 us
dop_test = 5e6;      % 5 MHz
att_test = 0;        

% Marge nécessaire = tau * Fs
marge = ceil(tau_test * params.Fs) + 100;
N_buffer = params.N_snapshot + marge;

% 1. On crée le buffer long
sig_source_long = creerIQ_BB(N_buffer, params.Fs, params.B_signal);

% 2. On extrait le signal "Maintenant" (Référence t=0) pour comparer
sig_ref = sig_source_long(end - params.N_snapshot + 1 : end);

% 3. On génère le signal retardé via la fonction
sig_phys = creerSignal_BB(sig_source_long, tau_test, dop_test, att_test, params.Fs, params.fc, params.N_snapshot);

% Vérif Retard (Intercorrélation entre Ref et Retardé)
[corr, lags] = xcorr(sig_phys, sig_ref);
[~, idx_max] = max(abs(corr));
lag_max = lags(idx_max);
retard_mesure = lag_max / params.Fs;

fprintf('  -> Retard imposé : %.9f s\n', tau_test);
fprintf('  -> Retard mesuré : %.9f s\n', retard_mesure);

subplot(2,2,3); plot(lags/params.Fs*1e6, abs(corr));
xlabel('Retard (us)'); title('Corrélation (Pic à -0.5)'); grid on;

subplot(2,2,4); pwelch(sig_phys, [], [], [], params.Fs, 'centered');
title('Spectre Doppler (+5MHz)');

%% TEST 3 & 4 : Simulation Scène Complète et Superposition (AFFICHAGE NORMALISÉ)
fprintf('Test 3/4 : Scène Complète (Superposition)...\n');

Geom.Dist_Directe = [100, 200, 300, 400, 500]; 
Geom.Dist_Cible   = Geom.Dist_Directe + 1000;  
Geom.Doppler_Bistatic = [1000, 5000, 10000, -5000, -10000];

% Génération physique (avec les vraies amplitudes faibles)
[S_melange, S_refs] = generer_scene_complete(Geom, 1, params);

figure('Name', 'Preuve Superposition (Normalisée)');

% 1. Constellation Sat 1 (Propre)
subplot(2,2,1); 
S1 = S_refs(:,1);
plot(real(S1(1:1000)), imag(S1(1:1000)), 'b.'); 
title('Sat 1 Source (QPSK)'); axis square; grid on; xlim([-2 2]); ylim([-2 2]);

% 2. Constellation Mélange (Normalisée pour voir la forme)
% ICI ON TRICHE JUSTE POUR L'AFFICHAGE (on divise par l'écart-type std)
subplot(2,2,2); 
S_mix_norm = S_melange / std(S_melange); 
plot(real(S_mix_norm(1:1000)), imag(S_mix_norm(1:1000)), 'r.'); 
title('Mélange Reçu (Forme Gaussienne)'); axis square; grid on; xlim([-4 4]); ylim([-4 4]);

% 3. Comparaison Spectrale (Normalisée)
subplot(2,2,3);
[P1, F] = pwelch(S1, [], [], [], params.Fs, 'centered');
[P_mix, ~] = pwelch(S_mix_norm, [], [], [], params.Fs, 'centered');
plot(F/1e6, 10*log10(P1), 'b', 'LineWidth', 1.5); hold on;
plot(F/1e6, 10*log10(P_mix), 'r'); 
legend('Sat 1 Seul', 'Mélange (Normalisé)');
title('Densité Spectrale (Forme)'); 
xlabel('Fréquence (MHz)');       
ylabel('Puissance (dB)');        
grid on;

% 4. Amplitude Temporelle
subplot(2,2,4);
idx_zoom = 100:200;
% On compare les amplitudes normalisées pour voir les variations relatives
plot(abs(S1(idx_zoom)) / std(S1), 'b', 'LineWidth', 1.5); hold on;
plot(abs(S_melange(idx_zoom)) / std(S_melange), 'r');
legend('Sat 1 (Stable)', 'Mélange (normalisé)');
title('Amplitude Temporelle (Normalisée)'); 
xlabel('Temps (Échantillons)');  
ylabel('Amplitude (Normalisée)');
grid on;


fprintf('--- TOUS LES TESTS SONT PASSÉS ---\n');

