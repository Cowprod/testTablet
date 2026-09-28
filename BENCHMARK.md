# Procédure de benchmark

## Préparation

Chaque candidat part exactement du même commit de référence.

```bash
git switch main
git pull
git switch -c bench/<modele>
```

Ouvrir ensuite le repo dans l'agent et envoyer uniquement le contenu de `PROMPT.md`.

## Limite de temps

Chaque run dispose d'une **limite dure de 90 minutes** à compter de l'envoi du prompt.

- si le candidat termine avant 90 minutes, son résultat est pris tel quel ;
- aucune intervention humaine pendant le run, sauf confirmation de sécurité indispensable ;
- à 90 minutes, le run est arrêté, même si le candidat travaille encore ;
- ce qui existe effectivement dans le workspace au moment de l'arrêt constitue le résultat du candidat ;
- la durée réelle est consignée ;
- un candidat arrêté à 90 minutes est explicitement noté `timeout`.

La capacité à converger dans le temps imparti fait partie du benchmark, même si la vitesse brute n'est pas un critère prioritaire.

## Ce qu'on conserve après chaque run

- modèle et runtime utilisés ;
- modèle local, cloud ou gratuit OpenCode ;
- taille de contexte ;
- matériel utilisé ;
- durée approximative ;
- statut terminé ou `timeout` ;
- appels d'outils Web observés ;
- commandes exécutées ;
- rapport final de l'agent ;
- `git diff --stat` ;
- `git diff` ;
- résultat de la grille `SCORING.md`.

## Tests matériels

Quand les quatre tablettes sont disponibles :

```bash
adb devices -l
```

Le candidat doit gérer plusieurs serials sans intervention manuelle.

## Comparabilité

Ne pas :
- corriger le prompt entre deux modèles ;
- donner un indice à un modèle seulement ;
- préinstaller un plugin spécifique pour un candidat ;
- accepter un résultat uniquement parce qu'il compile.

La qualité recherchée est : compréhension, recherche, exactitude technique, patch minimal, robustesse et capacité à valider.
