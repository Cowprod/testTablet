# Procédure de benchmark

## Préparation

Chaque candidat part exactement du même commit de référence.

```bash
git switch main
git pull
git switch -c bench/<modele>
```

Ouvrir ensuite le repo dans l'agent et envoyer uniquement le contenu de `PROMPT.md`.

## Ce qu'on conserve après chaque run

- modèle et runtime utilisés ;
- modèle local, cloud ou gratuit OpenCode ;
- taille de contexte ;
- matériel utilisé ;
- durée approximative ;
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
