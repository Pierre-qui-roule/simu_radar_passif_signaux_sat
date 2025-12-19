%% SCRIPT DE VALIDATION
% Ce script charge les données générées et prouve que le système fonctionne.
clear; clc; close all;

%% 1. Chargement des données
filename = 'donnees_scenario.mat';

if isfile(filename)
    fprintf('Chargement du fichier "%s"...\n', filename);
    load(filename); % Charge la structure 'env_data'
else
    error('ERREUR : Le fichier %s n''existe pas. Lancez d''abord "trajectoire_export.m" !', filename);
end

% Récupération des variables pour simplifier la lecture
Re = env_data.Re;
R_pos = env_data.Pos_Rx;
Traj_Tgt = env_data.Traj_Tgt;
Traj_Sats = env_data.Traj_Sats;
Vit_Sats = env_data.Vit_Sats;
numSats = env_data.numSats;

fprintf('Données chargées avec succès.\n');
fprintf('  - Durée : %.1f sec\n', env_data.time(end));
fprintf('  - Satellites : %d\n', numSats);

%% 2. Visualisation 3D "Preuve de la Terre Ronde"

figure('Name', 'Validation : Terre Sphérique et Trajectoires', 'Color', 'w');

% --- A. Dessiner la Terre (Sphère fil de fer) ---
% On dessine une sphère de rayon Re
[xEarth, yEarth, zEarth] = sphere(50); 
surf(xEarth*Re, yEarth*Re, zEarth*Re, 'FaceColor', [0.9 0.9 1.0], 'EdgeColor', [0.8 0.8 0.9], 'FaceAlpha', 0.3);
hold on;

% --- B. Dessiner le Radar ---
plot3(R_pos(1), R_pos(2), R_pos(3), 'k^', 'MarkerSize', 12, 'LineWidth', 2, 'MarkerFaceColor', 'y');
text(R_pos(1)*1.05, R_pos(2), R_pos(3), ' RADAR (Sol)', 'FontSize', 10, 'FontWeight', 'bold');

% --- C. Dessiner l'Avion (Cible) ---
plot3(Traj_Tgt(1,:), Traj_Tgt(2,:), Traj_Tgt(3,:), 'r-', 'LineWidth', 2);
plot3(Traj_Tgt(1,end), Traj_Tgt(2,end), Traj_Tgt(3,end), 'ro', 'MarkerFaceColor', 'r');
text(Traj_Tgt(1,end), Traj_Tgt(2,end), Traj_Tgt(3,end), '  CIBLE (10km alt)', 'Color', 'r');

% --- D. Dessiner les Satellites ---
colors = lines(numSats); % Couleurs différentes pour chaque sat
for i = 1:numSats
    % Trajectoire complète
    plot3(Traj_Sats(1,:,i), Traj_Sats(2,:,i), Traj_Sats(3,:,i), '--', 'Color', colors(i,:), 'LineWidth', 1);
    
    % Position finale
    pos_fin = Traj_Sats(:,end,i);
    plot3(pos_fin(1), pos_fin(2), pos_fin(3), 'o', 'Color', colors(i,:), 'MarkerFaceColor', colors(i,:), 'MarkerSize', 6);
    
    % Vecteur Vitesse (Quiver) - Pour prouver qu'on a bien calculé la vitesse
    vit_fin = Vit_Sats(:,end,i);
    % On normalise la flèche pour qu'elle soit visible à l'échelle planétaire
    scale = 500; 
    quiver3(pos_fin(1), pos_fin(2), pos_fin(3), ...
            vit_fin(1), vit_fin(2), vit_fin(3), scale, 'Color', 'k', 'LineWidth', 1.5);
        
    text(pos_fin(1), pos_fin(2), pos_fin(3)+200e3, sprintf(' Sat %d', i), 'Color', colors(i,:));
end

% --- E. Réglages de la vue ---
axis equal; 
grid on;
xlabel('X (m) - ECEF'); ylabel('Y (m) - ECEF'); zlabel('Z (m) - ECEF');
title('Preuve : Modèle Terre Sphérique & Constellation');
view(3); % Vue 3D par défaut

% Ajout d'un zoom automatique pour bien voir la scène
% On ne zoome pas trop pour voir la courbure de la Terre
xlim([0, Re + 2000e3]); 
zlim([-2000e3, 2000e3]);

fprintf('Visualisation terminée.\n');