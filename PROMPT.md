# Prompt de benchmark

Tu dois réaliser une petite application de diagnostic Android basée sur Cordova, accompagnée d'outils ADB côté macOS.

## Contexte

Quatre tablettes Android sont branchées en permanence à un Mac et accessibles avec ADB. On veut pouvoir connaître rapidement leur état et leurs capacités.

## Mission

Analyse ce repo puis implémente une solution fonctionnelle.

L'application Cordova doit afficher au minimum :

- fabricant et modèle de l'appareil ;
- version Android ;
- version de l'application et, si pertinent, version Cordova ;
- niveau de batterie et état de charge ;
- état/type de connexion réseau ;
- résolution de l'écran, pixel ratio et orientation ;
- stockage total et espace disponible lorsque c'est raisonnablement accessible ;
- état de permissions Android utiles, au minimum caméra, microphone et notifications lorsque la version Android les rend pertinentes ;
- possibilité de demander depuis l'application les permissions qui peuvent l'être ;
- un rapport JSON conforme à `benchmark/report.schema.json`, affichable et copiable.

Ajoute également côté macOS un ou plusieurs scripts dans `scripts/` permettant de :

- détecter tous les appareils retournés par `adb devices` ;
- distinguer proprement plusieurs appareils ;
- collecter des informations complémentaires pertinentes via ADB ;
- récupérer ou produire un rapport par appareil ;
- ne jamais supposer qu'un seul device est connecté.

## Recherche obligatoire

Avant de choisir les plugins, permissions ou commandes ADB :

1. utilise tes outils Web ;
2. vérifie les informations dans les documentations officielles ou les dépôts officiels/maintenus ;
3. vérifie notamment la situation actuelle des permissions Android et la compatibilité des plugins Cordova retenus ;
4. ne fabrique aucune API ou option de plugin de mémoire.

Documente les sources réellement consultées dans `docs/RESEARCH.md` avec :

- URL ;
- information vérifiée ;
- conséquence sur l'implémentation.

## Contraintes

- Cordova Android, pas Capacitor ;
- pas de framework front-end lourd nécessaire ;
- interface simple utilisable sur tablette ;
- aucun backend distant requis ;
- gestion correcte de `deviceready` ;
- erreurs visibles et non silencieuses ;
- le code doit rester lisible et modeste ;
- ne demande pas à l'utilisateur de faire manuellement ce que tes outils peuvent vérifier ;
- ne modifie pas le schéma JSON de benchmark sauf impossibilité réelle, à expliquer avant tout changement ;
- préserve impérativement le dépôt Git existant et son historique ;
- ne supprime, ne recrée, ne réinitialise et ne remplace jamais `.git` ;
- ne supprime pas `.gitignore`, `PROMPT.md`, `BENCHMARK.md`, `SCORING.md`, `RESULTS.md`, `benchmark/` ni `docs/RESEARCH.md` ;
- si un outil d'initialisation refuse de travailler dans le repo existant, adapte ta méthode de travail sans détruire ni déplacer les éléments de benchmark.

## Validation

Avant de terminer :

- exécute les contrôles ou tests que tu peux réellement lancer ;
- vérifie la syntaxe des fichiers générés ;
- vérifie les commandes ADB sans supposer un serial unique ;
- fais un `git diff` final ;
- résume ce qui fonctionne, ce qui n'a pas pu être validé matériellement et les recherches Web effectuées.

Ne te contente pas de proposer du code dans la conversation : modifie réellement le repo.
