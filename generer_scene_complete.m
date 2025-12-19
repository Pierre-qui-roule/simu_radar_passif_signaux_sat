function [S_surv_Total, S_ref_Sats] = generer_scene_complete(Geom, i_time, params)
% V2 : La référence de sortie est maintenant le TRAJET DIRECT (pas la source)
% Cela permet à l'ECA de fonctionner correctement.

    Fs = params.Fs;
    fc = params.fc;
    N_snap = params.N_snapshot;
    
    S_surv_Total = zeros(1, N_snap);
    numSats = size(Geom.Dist_Directe, 2);
    S_ref_Sats = zeros(N_snap, numSats);
    
    % Marge de sécurité pour le buffer (Retard Max)
    max_dist = max([max(Geom.Dist_Cible(i_time,:)), max(Geom.Dist_Directe(i_time,:))]);
    max_delay_samples = ceil(max_dist / 3e8 * Fs) + 2000;
    N_buffer_needed = N_snap + max_delay_samples;

    for i = 1:numSats
        % A. Buffer Source
        S_source_long = creerIQ_BB(N_buffer_needed, Fs, params.B_signal);
        
        % B. Trajet Direct (DPI)
        tau_dir = Geom.Dist_Directe(i_time, i) / 3e8;
        dop_dir = 0; % Supposé compensé par le récepteur
        Att_Dir = 100; % Atténuation trajet direct (Interférence forte)
        
        S_Direct = creerSignal_BB(S_source_long, tau_dir, dop_dir, Att_Dir, Fs, fc, N_snap);
        
        % C. Trajet Écho (Cible)
        tau_echo = Geom.Dist_Cible(i_time, i) / 3e8;
        dop_bist = Geom.Doppler_Bistatic(i_time, i);
        Att_Echo = 160; % Atténuation écho (Cible faible)
        
        S_Echo = creerSignal_BB(S_source_long, tau_echo, dop_bist, Att_Echo, Fs, fc, N_snap);
        
        % D. Signal de Référence (Canal Référence)
        % L'antenne de référence pointe le satellite : elle reçoit le signal Direct avec fort gain.
        % On le génère sans atténuation (0dB) pour avoir une référence propre.
        S_Ref_Antenne = creerSignal_BB(S_source_long, tau_dir, dop_dir, 0, Fs, fc, N_snap);
        S_ref_Sats(:, i) = S_Ref_Antenne; 

        % Somme Surveillance
        S_surv_Total = S_surv_Total + S_Direct + S_Echo;
    end
    
    % Bruit
    Bruit = (randn(1, N_snap) + 1j*randn(1, N_snap)) / sqrt(2);
    lvl_bruit = 10^(-110/20); 
    S_surv_Total = S_surv_Total + Bruit * lvl_bruit;
end