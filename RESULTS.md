# Résultats du benchmark

Ce document centralise les résultats de tous les modèles testés à partir du même état initial.

## Principe

- `main` reste la référence : protocole, prompt, scoring et résultats.
- chaque run est réalisé dans une branche dédiée `bench/<modele>`;
- chaque branche part du même commit de référence ;
- après le run, la branche est conservée telle quelle ;
- le score et les observations sont ensuite reportés ici.

## Résultats

| Modèle | Runtime / provider | Matériel | Branche | Contexte | Durée | Score /100 | Recherche Web | Tool calling | Validation réelle | Notes |
|---|---|---|---|---:|---:|---:|---|---|---|---|
| Qwen3 8B | Ollama | RX 6600 XT 8 Go | `bench/qwen3-8b` | 16K | ~1 h | non scoré (pilote) | non relevé | oui, avec échecs | non aboutie | Run pilote arrêté manuellement ; suppression destructive de `.git` et `.gitignore` via `rm -rf .git .gitignore`, plusieurs échecs `edit`, absence de convergence. |
| Jan-Code 4B | à préciser | RX 6600 XT 8 Go | `bench/jan-code-4b` | | | | | | | |
| Bonsai 2 27B | PrismML si validé | RX 6600 XT 8 Go | `bench/bonsai2-27b` | | | | | | | |
| Swiftlet / Qwen | Swiftlet | Mac mini M4 16 Go | `bench/swiftlet-qwen` | | | | | | | |
| OpenCode gratuit | OpenCode | cloud | `bench/opencode-<modele>` | | | | | | | |

## Fiche détaillée d'un run

- Modèle exact :
- Version / quantification :
- Runtime / provider :
- Matériel :
- Branche :
- Commit de départ :
- Contexte :
- Date :
- Durée approximative :
- Recherche Web réellement utilisée :
- Outils correctement appelés :
- Commandes/tests réellement exécutés :
- Build Cordova :
- Test ADB multi-device :
- Test sur tablette réelle :
- Score selon `SCORING.md` :
- Hallucinations :
- Erreurs techniques :
- Capacité à se corriger :
- Supervision humaine nécessaire :
- Commit final :
- Diff/stat :
- Rapport final de l'agent :


## Run pilote — Qwen3 8B — 2026-09-28

Ce run a servi à valider le protocole avant gel de la baseline officielle.

- Début : 10:35 (heure locale).
- Arrêt : manuel, après environ une heure.
- Statut : échec / non convergé ; non scoré comme run officiel.
- Runtime : Ollama, Qwen3 8B, contexte 16K, RX 6600 XT 8 Go.
- Incident critique : l'agent a exécuté `rm -rf .git .gitignore` avant `cordova create . --force`.
- Conséquence : destruction du dépôt Git local, de la branche de benchmark et du lien avec le commit de référence.
- Comportement observé ensuite : plusieurs opérations `edit` en échec et poursuite du raisonnement sans convergence vers une livraison validée.
- Validation réelle : le run n'a pas atteint une validation complète sur les quatre tablettes.
- Décision : conserver ce résultat comme **run pilote**, puis renforcer le protocole avant les runs comparatifs officiels.
- Enseignement protocolaire : une limite dure de 90 minutes a été ajoutée à `BENCHMARK.md`. La protection explicite du dépôt Git doit être intégrée au prompt avant gel de la baseline officielle.
