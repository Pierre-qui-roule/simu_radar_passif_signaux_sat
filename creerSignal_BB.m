function [sig_out] = creerSignal_BB(source_buffer, tau, doppler, attenuation_dB, Fs, fc, N_snap)
% VERSION BUFFER CIRCULAIRE
% source_buffer : Signal source (doit être PLUS LONG que N_snap + Retard Max)
% tau           : Retard à simuler (s)
% N_snap        : La taille de sortie désirée (nombre d'échantillons)

    % 1. Vérification et Calculs Index
    nb_total = length(source_buffer);
    
    % On prend la moyenne du retard sur le snapshot (hypothèse stationnaire locale)
    tau_val = mean(tau);
    dop_val = mean(doppler);
    
    shift_samples = round(tau_val * Fs);
    
    % Sécurité : Le buffer est-il assez grand pour remonter aussi loin dans le passé ?
    if (shift_samples + N_snap) > nb_total
        % Si ça plante ici, c'est que le buffer généré dans 'generer_scene' est trop court
        error('Erreur Buffer: Retard demandé (%.1f us) > Historique disponible.', tau_val*1e6);
    end
    
    % 2. DÉCOUPAGE TEMPOREL (Le "Slicing")
    % On veut simuler que le signal reçu maintenant a été émis il y a 'tau' secondes.
    % Dans le buffer, la fin (end) représente le temps "Maintenant".
    % Le début (1) représente le passé.
    
    % On recule de 'shift_samples' depuis la fin pour trouver la fenêtre
    idx_end   = nb_total - shift_samples;
    idx_start = idx_end - N_snap + 1;
    
    % Extraction du morceau de signal (toujours plein, pas de zéros)
    sig_cut = source_buffer(idx_start : idx_end);

    % 3. Application Physique (Doppler + Phase + Gain)
    t_vec = (0:N_snap-1) / Fs;
    
    % Retard de Phase (Précision fine)
    phase_rot = exp(-1j * 2 * pi * fc * tau_val);
    
    % Doppler (Rotation temporelle)
    dop_rot   = exp(1j * 2 * pi * dop_val * t_vec);
    
    % Gain
    gain      = 10^(-attenuation_dB / 20);
    
    % Résultat
    sig_out = sig_cut .* dop_rot * phase_rot * gain;
end