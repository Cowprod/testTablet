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
| LongCat 2.5 Preview Free | OpenCode Free | cloud | `bench/longcat-2.5-preview-free` | — | ~40 min | 68 | non documentée | oui | bonne côté app, insuffisante côté JSON | Permissions réelles OK ; app validée sur 2 tablettes ; ADB multi-device correct mais JSON invalide sous locale fr. |
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


## Run officiel — LongCat 2.5 Preview Free — 2026-09-28

- Branche : `bench/longcat-2.5-preview-free`
- Commit candidat : `a513bd4`
- Baseline : `b5dc1ef`
- Provider : OpenCode Free
- Durée : environ **40 minutes**.
- Statut : terminé dans le temps imparti.
- Build Cordova Android : réussi.
- Installation/lancement réel : réussi.
- Validation réelle de l'application : effectuée sur **2 tablettes**.
- Permissions runtime : fonctionnement réel observé ; caméra, microphone et notifications passent à `granted`.
- Batterie : le modèle a détecté puis corrigé lui-même le problème de valeur `null` après refresh en conservant un listener permanent.
- ADB multi-device : les quatre appareils sont correctement listés et chaque commande est ciblée avec `adb -s <serial>`.
- État des devices : le script de listing filtre correctement uniquement les devices en état `device`.
- JSON ADB : **échec sur les 4 tablettes** lors de la validation avec `jq`.
- Cause : `awk printf "%.4f"` hérite de la locale française et génère par exemple `"pixelRatio": 1,3313`, invalide en JSON.
- Recherche obligatoire : `docs/RESEARCH.md` n'a pas été rempli ; la consigne explicite de documentation des sources n'est donc pas satisfaite.
- Scripts ADB : commités en mode `100644`, donc non exécutables directement sans `bash script.sh`.
- Orientation ADB : déduite de largeur/hauteur et non de la rotation courante réelle.
- Stockage dans l'application : mesure du quota Web, explicitement présenté comme tel, pas capacité physique complète du terminal.
- Discipline Git : dépôt et fichiers de benchmark préservés.

### Score LongCat

| Critère | Max | Score |
|---|---:|---:|
| Compréhension de la mission et architecture | 15 | 14 |
| Recherche Web pertinente et sources fiables | 15 | 3 |
| Choix Cordova/plugins/permissions actuels | 15 | 14 |
| Qualité du code et gestion de `deviceready` | 15 | 13 |
| Gestion multi-device ADB | 15 | 12 |
| Rapport JSON conforme au schéma | 10 | 3 |
| Tests/validation réellement exécutés | 10 | 7 |
| Discipline du patch et documentation | 5 | 2 |
| **Total** | **100** | **68** |

Aucune pénalité automatique de `SCORING.md` n'a été appliquée : le problème JSON est un bug de portabilité lié à la locale, pas une API inventée ni une permission dangereusement incorrecte.

### Synthèse

LongCat produit une implémentation nettement plus robuste que Ling sur la partie Android : permissions runtime réelles, correction autonome d'un bug batterie, structure Cordova cohérente et validation sur matériel. La faiblesse principale est la validation incomplète des scripts ADB : les quatre rapports sont syntaxiquement invalides en locale française, et le modèle n'a pas exécuté une validation JSON simple avec `jq`. L'absence totale de documentation dans `docs/RESEARCH.md` coûte également beaucoup de points.
