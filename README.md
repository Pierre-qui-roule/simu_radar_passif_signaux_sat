# simu_radar_passif_signaux_sat

Simulation de Radar Passif sur signaux satellitaires

L'objectif ici est de modéliser une chaîne complète de détection radar passive qui exploite les signaux d'opportunité émis par des constellations de satellites en orbite basse pour repérer une cible. C'est une simulation dont le but est notamment de visualiser comment on peut extraire un écho radar très faible noyé dans le bruit et les interférences directes des satellites.

Comprendre l'architecture :

Pour mieux saisir comment les différents scripts interagissent, voici le schéma global du fonctionnement de la simulation.

Comme illustré ci-dessus, le projet se divise en trois grandes phases logiques. Nous avons d'abord une phase de préparation où nous calculons toute la physique du scénario (la trajectoire de la cible et des satellites ainsi que que le calcul de la géométrie bistatique associée). Ces données sont sauvegardées et servent ensuite de base à la simulation principale.

La seconde phase est le cœur du système : c'est la boucle de simulation temporelle. À chaque instant, nous générons les signaux électromagnétiques bruts (mélange des signaux satellites, échos, bruit thermique), puis nous les passons dans notre module de traitement du signal. Ce module effectue la synchronisation, le nettoyage des interférences via l'algorithme ECA, et enfin le calcul de la corrélation croisée (CAF) pour détecter la cible.

Installation et configuration

Si vous récupérez ce projet depuis GitHub, la procédure pour le faire fonctionner sur votre machine est très simple. Il n'y a pas d'installation complexe requise, il vous faut juste MATLAB avec la Signal Processing Toolbox. Une fois que vous avez téléchargé le dossier (soit par clonage, soit via le bouton "Download ZIP"), décompressez-le à l'endroit de votre choix. Ouvrez ensuite MATLAB et naviguez jusqu'à ce dossier. La seule étape technique importante est de s'assurer que MATLAB "voit" bien tous les fichiers. Pour cela, faites un clic droit sur le dossier principal du projet dans l'explorateur de fichiers de MATLAB, et choisissez l'option pour ajouter le dossier et ses sous-dossiers au chemin (Add to Path > Selected Folders and Subfolders). Cela évitera les erreurs de fonctions introuvables.

Comment lancer la simulation

Pour que la simulation fonctionne, il est impératif de respecter un ordre précis d'exécution des programmes. En effet, chaque étape dépend des données calculées par la précédente.

Pour tout lancer d'un coup :

Si vous voulez tout lancer ou relancer de zéro sans vous soucier de l'ordre, vous pouvez aussi simplement exécuter le script TOUT_LANCER.m qui automatisera toute la séquence pour vous.

Pour lancer les programmes un à un et les voir fonctionner individuellement :

Vous devez commencer par lancer le script Trajectoire.m. Son rôle est de mettre en place le décor : il définit la position du récepteur au sol, simule le mouvement de la constellation de satellites et fait voler l'avion cible à travers la scène. Il va créer un fichier de données contenant toutes ces coordonnées. Si vous voulez visualiser spécifiquement les trajectoires générées vous pouvez lancer Trajectoire_visu.m.

Ensuite, exécutez calcul_geometrie.m. Ce programme reprend les positions générées juste avant pour calculer les retards de propagation et les décalages Doppler théoriques. C'est une étape intermédiaire essentielle pour préparer le travail du processeur radar. Si vous voulez, vous pouvez lancer après le test unitaire test_calcul_geometrie.m. Ce dernier se place dans une situation simple : 1 seul satellite au-dessus du radar et compare les résultats obtenu avec ce qu'on devrait obtenir. Néanmoins, ce test écrase les donnés du fichier donnees_scenario.mat, donc après son exécution il faut relancer les programmes du début pour avancer dans la simulation.

Une fois ces deux étapes de préparation terminées, il est possible de lancer test_generation_signal.m. C'est un script de validation qui permet de vérifier que la génération des signaux est réaliste avant de lancer la grosse simulation. Il va générer des graphiques comme celui ci-dessous :

Ce test visuel est rassurant : on y voit à gauche la constellation QPSK propre du satellite source (le carré bleu), et à droite le signal mélangé reçu par l'antenne (le nuage rouge), qui montre bien que le signal utile est totalement noyé dans le bruit et les interférences des autres satellites. C'est tout le défi du traitement qui va suivre.

Enfin, pour voir le radar en action, lancez main_simulation.m. C'est le chef d'orchestre qui va traiter le signal seconde par seconde, afficher les cartes de détection distance-Doppler et tracer la position de l'avion en temps réel.

Explication des programmes non-mentionnés ci-dessus :

`creerIQ_BB.m`
creerSignal_BB.m
generer_scene_complete.m
traitement_signal.m


