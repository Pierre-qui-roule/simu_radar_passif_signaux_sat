function [CAF_dB, tau_axis, fD_axis] = traitement_signal(S_ref, S_surv, Fs, T_CPI, Compensation_Sig, ECA_Taps, mu, Max_Delay_Samples, Max_Doppler_Hz)
% TRAITEMENT_SIGNAL : Module DSP Radar Passif (ECA + CAF)
% Ce module traite un canal de surveillance bruité en utilisant une référence propre.

    % 1. Formatage et Robustesse
    S_ref = S_ref(:);   % Force en colonne
    S_surv = S_surv(:); % Force en colonne
    
    % Gestion de la compensation (si pas fournie, on met 1)
    if nargin < 5 || isempty(Compensation_Sig)
        Compensation_Sig = ones(size(S_ref));
    else
        Compensation_Sig = Compensation_Sig(:);
    end

    N_samples = length(S_ref);
    t_vec = (0:N_samples-1).' / Fs;

    %% A. COMPENSATION DOPPLER (Stabilisation)
    % On stabilise le satellite visé (S_ref) à 0 Hz.
    % Cela étale les 4 autres satellites (ce qui est bénéfique).
    S_ref_comp = S_ref .* Compensation_Sig; 
    S_surv_comp = S_surv .* Compensation_Sig;

    %% B. FILTRE ECA (Annulation Interférence Directe)
    % On utilise la référence pour nettoyer le signal direct du mélange.
    
    S_surv_cleaned = S_surv_comp; % Initialisation (Pas de nettoyage par défaut)
    
    if ECA_Taps > 0
        w = zeros(ECA_Taps, 1);
        S_surv_cleaned = zeros(size(S_surv_comp));
        
        % Boucle NLMS (Normalized Least Mean Squares)
        for n = ECA_Taps : N_samples
            % Vecteur de régression (les derniers échantillons de la réf)
            x_n = S_ref_comp(n : -1 : n - ECA_Taps + 1);
            
            % Estimation de l'interférence (Trajet Direct)
            y_hat = w' * x_n;
            
            % Erreur = Signal Total - Estimation
            % C'est cette erreur qui contient l'écho faible (la cible)
            e_n = S_surv_comp(n) - y_hat;
            S_surv_cleaned(n) = e_n;
            
            % Mise à jour des poids du filtre
            norm_x = (x_n' * x_n) + 1e-6; % Epsilon pour éviter division par zéro
            w = w + (mu / norm_x) * x_n * conj(e_n);
        end
    end

    %% C. CALCUL DE LA CAF (Corrélation Croisée)
    % On cherche la ressemblance entre le signal nettoyé et la référence
    
    % Création des axes de recherche
    tau_axis = -Max_Delay_Samples : Max_Delay_Samples;
    
    % Pas Doppler = Résolution fréquentielle (1 / Temps d'intégration)
    dop_step = max(10, 1/T_CPI); 
    fD_axis = -Max_Doppler_Hz : dop_step : Max_Doppler_Hz;
    
    % Initialisation de la matrice résultat
    CAF_abs = zeros(length(tau_axis), length(fD_axis));
    
    % Boucle sur les hypothèses Doppler
    for i = 1:length(fD_axis)
        fd = fD_axis(i);
        
        % Pour tester la vitesse 'fd', on applique une rotation inverse à la référence
        % (C'est équivalent à démoduler le signal de surveillance)
        test_signal = S_ref_comp .* exp(1j * 2 * pi * fd * t_vec);
        
        % Corrélation rapide (xcorr)
        [corr_val, ~] = xcorr(S_surv_cleaned, test_signal, Max_Delay_Samples);
        
        % On stocke la valeur absolue (l'énergie)
        CAF_abs(:, i) = abs(corr_val);
    end
    
    % Conversion en échelle Logarithmique (dB) pour l'affichage
    CAF_dB = 20 * log10(CAF_abs + 1e-12); % Ajout petit epsilon pour éviter log(0)

end