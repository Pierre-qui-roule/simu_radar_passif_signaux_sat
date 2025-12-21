function [iq_sig] = creerIQ_BB(N_samples, Fs, B_signal)
    % Durée d'un symbole
    T_symb = 1 / B_signal;
    % Samples per Symbol
    SPS = ceil(Fs * T_symb); 
    
    % Nombre de symboles nécessaires
    N_symb = ceil(N_samples / SPS) + 20; % Marge pour le filtre
    
    % 1. Bits aléatoires et Mapping QPSK
    % QPSK : exp(j*(pi/4 + k*pi/2))
    data_idx = randi([0 3], N_symb, 1);
    symbs = exp(1j * (pi/4 + data_idx * pi/2));
    
    % 2. Filtrage de mise en forme (RRC)
    % Pour ressembler à un vrai signal sat
    filter_span = 6; 
    beta = 0.2; % Roll-off
    h = rcosdesign(beta, filter_span, SPS, 'sqrt');
    
    % Sur-échantillonnage
    sig_filtered = upfirdn(symbs, h, SPS);
    
    % 3. Troncature et Normalisation
    % On coupe pour avoir exactement N_samples
    cut_idx = filter_span * SPS;
    iq_sig = sig_filtered(cut_idx : cut_idx + N_samples - 1).';
    
    % Normalisation Puissance = 1 Watt (0 dBW)
    iq_sig = iq_sig / rms(iq_sig);

end
