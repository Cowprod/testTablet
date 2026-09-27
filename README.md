# testTablet

Repo de benchmark pour comparer des agents/LLM de développement sur une tâche réelle et reproductible.

## Sujet

Créer une application **Cordova Android** de diagnostic pour plusieurs tablettes connectées en permanence en ADB à un Mac.

Le benchmark doit obliger l'agent à :

- inspecter le repo ;
- faire de la recherche Web, en privilégiant la documentation officielle ;
- choisir des plugins Cordova maintenus et adaptés aux versions Android actuelles ;
- gérer correctement `deviceready` et les permissions runtime ;
- produire du code cohérent sur plusieurs fichiers ;
- utiliser ADB avec plusieurs appareils ;
- tester et documenter son travail.

## Principe

Le repo de départ ne contient volontairement **pas la solution**.

Chaque modèle doit partir du même commit et recevoir le même prompt : voir [PROMPT.md](PROMPT.md).

Le contrat du rapport JSON est défini dans [benchmark/report.schema.json](benchmark/report.schema.json).

Les critères de comparaison sont dans [SCORING.md](SCORING.md).

## Cibles à comparer

Le benchmark servira notamment à comparer :

- Qwen3 8B sur RTX/Ollama ;
- Jan-Code-4B ;
- Bonsai 2 27B si le runtime PrismML fonctionne sur la RX 6600 XT ;
- Swiftlet/Qwen sur Mac mini M4 ;
- les modèles gratuits proposés dans OpenCode, lorsqu'ils sont disponibles.

## Environnement cible

- Cordova Android ;
- 4 tablettes Android accessibles en ADB ;
- scripts hôte sur macOS ;
- aucun backend distant obligatoire ;
- rapport JSON exploitable automatiquement.

## Règle de benchmark

Pour chaque modèle :

1. repartir du commit de référence ;
2. créer une branche dédiée ;
3. envoyer le contenu de `PROMPT.md` sans l'adapter au modèle ;
4. laisser l'agent travailler sans assistance ;
5. conserver son rapport final, le diff Git et les commandes/tests exécutés ;
6. noter le résultat avec `SCORING.md`.

Exemples de branches :

```text
bench/qwen3-8b
bench/jan-code-4b
bench/bonsai2-27b
bench/swiftlet-qwen35b
bench/opencode-<modele>
```
