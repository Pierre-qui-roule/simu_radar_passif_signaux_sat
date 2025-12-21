function [pos_estimee] = calcul_position_cible(Pos_Rx, Pos_Sats, Dist_Bistatiques_Mesurees)
% CALCUL_POSITION_CIBLE : Résout la multilatération bistatique (Intersection d'ellipsoïdes)
% Entrées :
%   - Pos_Rx : Position du radar [3x1] (x;y;z)
%   - Pos_Sats : Matrice des positions des satellites actifs [3 x N_sats]
%   - Dist_Bistatiques_Mesurees : Vecteur des distances mesurées [1 x N_sats]
% Sortie :
%   - pos_estimee : Position (x,y,z) trouvée

    % 1. Initialisation : On suppose que l'avion est quelque part au-dessus du radar
    % (Point de départ pour l'algorithme d'optimisation)
    pos_init = Pos_Rx + [1000; 1000; 10000]; 

    % 2. Définition de la fonction de coût (L'erreur à minimiser)
    % L'erreur est la différence entre la distance mesurée et la distance théorique
    fonction_cout = @(pos_test) somme_erreurs_carrees(pos_test, Pos_Rx, Pos_Sats, Dist_Bistatiques_Mesurees);

    % 3. Résolution (Optimisation)
    options = optimset('Display', 'off'); % On ne veut pas de blabla dans la console
    pos_estimee = fminsearch(fonction_cout, pos_init, options);

end

function err_totale = somme_erreurs_carrees(P_cible, P_Rx, P_Sats, D_mesurees)
    % P_cible est le point [x;y;z] que l'algorithme teste
    err_totale = 0;
    nb_sats = size(P_Sats, 2);
    
    for i = 1:nb_sats
        P_Sat = P_Sats(:, i);
        
        % Calcul des distances géométriques pour ce point testé
        D_Sat_Cible = norm(P_cible - P_Sat);
        D_Cible_Rx  = norm(P_Rx - P_cible);
        D_Sat_Rx    = norm(P_Rx - P_Sat); % Baseline (Trajet Direct)
        
        % Distance Bistatique Théorique = (Trajet Total) - (Trajet Direct)
        D_bist_theorique = (D_Sat_Cible + D_Cible_Rx) - D_Sat_Rx;
        
        % On compare avec la vraie mesure du radar
        residu = D_mesurees(i) - D_bist_theorique;
        err_totale = err_totale + residu^2;
    end
end
