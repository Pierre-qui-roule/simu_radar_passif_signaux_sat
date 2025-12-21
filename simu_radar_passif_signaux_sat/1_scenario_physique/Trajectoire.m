%% Trajectoire théorique de l'avion et des satellites (Multi-Sats)
%  + Export des données pour la simulation
clear; clc; close all;

%% 1. Configuration Physique
env_data.Re = 6371e3;                % Rayon Terre (m)
env_data.mu = 3.986e14;              % Constante gravitationnelle
env_data.fc = 11.7e9;                % Fréquence porteuse (pour info)
env_data.c  = 299792458;             % Vitesse lumière

T_total = 10;                        % Durée simulation (s)
dt = 0.01;                           % Pas de temps précis (10ms) pour une bonne résolution
time = 0:dt:T_total;
N = length(time);

env_data.time = time;
env_data.dt = dt;

%% 2. Initialisation

% --- Rx Sol (Radar Fixe) ---
% Position ECEF approximative (sur l'équateur pour simplifier)
Pos_Rx = [env_data.Re; 0; 0];
env_data.Pos_Rx = Pos_Rx; 

% --- Avion (Cible) ---
% Départ décalé pour traverser le faisceau
Pos_Tgt_Init = [env_data.Re + 10000; -90000; 0]; 
Vel_Tgt = [0; 300; 0]; % 300 m/s vers Y positif

%si on prend un bateau comme cible
% Pos_Tgt_Init = [env_data.Re + 0; -90000; 0]; 
% Vel_Tgt = [0; 4; 0]; % 4 m/s vers Y positif

% Stockage Cible
Traj_Tgt = zeros(3, N);
Vit_Tgt  = zeros(3, N); % On stocke aussi la vitesse (constante ici)

% --- Satellites (Constellation) ---
numSats = 5; % Nombre de satellites
Alt_Sat = 1200e3; % Altitude OneWeb (~1200km)
R_Sat = env_data.Re + Alt_Sat;
V_Sat_Scalar = sqrt(env_data.mu / R_Sat); % Vitesse orbitale (m/s)

% Répartition angulaire (ex: espacés de 10 degrés)
angles_depart = linspace(deg2rad(-20), deg2rad(20), numSats);

% Stockage Satellites (3 dimensions : [Coords x Temps x NumSat])
Traj_Sats = zeros(3, N, numSats);
Vit_Sats  = zeros(3, N, numSats); % INDISPENSABLE POUR LE DOPPLER

%% 3. Boucle de Calcul (Génération)
fprintf('Génération des trajectoires pour %d satellites...\n', numSats);

for k = 1:N
    t = time(k);
    
    % --- A. Calcul Avion ---
    Pos_Tgt_Current = Pos_Tgt_Init + Vel_Tgt * t;
    Traj_Tgt(:, k) = Pos_Tgt_Current;
    Vit_Tgt(:, k)  = Vel_Tgt; % Vitesse constante
    
    % --- B. Calcul Satellites ---
    for i = 1:numSats
        % Angle actuel (Mouvement circulaire uniforme)
        omega = V_Sat_Scalar / R_Sat; % Vitesse angulaire (rad/s)
        theta = angles_depart(i) + omega * t;
        
        % 1. Position (Cercle dans le plan X-Z pour passer au zénith)
        % Note: On adapte le plan pour qu'il coupe le radar
        pSat = [R_Sat * cos(theta); 0; R_Sat * sin(theta)];
        
        % 2. Vitesse (Vecteur tangent au cercle)
        % Dérivée de la position par rapport au temps
        vSat = [-R_Sat * sin(theta) * omega; 0; R_Sat * cos(theta) * omega];
        
        % Stockage
        Traj_Sats(:, k, i) = pSat;
        Vit_Sats(:, k, i)  = vSat;
    end
end

% Enregistrement dans la structure de données
env_data.Traj_Tgt = Traj_Tgt;
env_data.Vit_Tgt  = Vit_Tgt;
env_data.Traj_Sats = Traj_Sats;
env_data.Vit_Sats  = Vit_Sats;
env_data.numSats   = numSats;

%% 4. Export des Données
filename = 'donnees_scenario.mat';
save(filename, 'env_data');
fprintf('Succès : Données sauvegardées dans "%s"\n', filename);

