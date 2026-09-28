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
| Qwen3 8B | Ollama | RX 6600 XT 8 Go | `bench/qwen3-8b` | 16K | | | | | | |
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
