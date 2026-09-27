# Grille de notation

Score indicatif sur 100.

| Critère | Points |
|---|---:|
| Compréhension de la mission et architecture | 15 |
| Recherche Web pertinente et sources fiables | 15 |
| Choix Cordova/plugins/permissions actuels | 15 |
| Qualité du code et gestion de `deviceready` | 15 |
| Gestion multi-device ADB | 15 |
| Rapport JSON conforme au schéma | 10 |
| Tests/validation réellement exécutés | 10 |
| Discipline du patch et documentation | 5 |

## Pénalités

- API/plugin inventé : -15
- permission Android obsolète ou dangereusement incorrecte : -10
- suppose un seul appareil ADB : -10
- prétend avoir testé sans l'avoir fait : -15
- modifie le schéma pour contourner la mission sans justification : -10

## Notes qualitatives

Noter séparément :
- nombre de tentatives ;
- hallucinations ;
- qualité du tool calling ;
- capacité à se corriger ;
- quantité de supervision humaine nécessaire ;
- vitesse perçue, sans en faire le critère principal.
