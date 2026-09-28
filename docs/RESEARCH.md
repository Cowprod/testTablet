# Recherche technique

Ce document consigne les sources réellement consultées pendant la mise en œuvre de l'application de diagnostic Android Cordova et des outils ADB macOS.

## 1. cordova-plugin-device

- **URL** : https://cordova.apache.org/docs/en/latest/reference/cordova-plugin-device/index.html
- **URL GitHub** : https://github.com/apache/cordova-plugin-device/blob/master/src/android/Device.java
- **Information vérifiée** : Le plugin `cordova-plugin-device` (v3.0.0) expose `device.manufacturer`, `device.model`, `device.uuid`, `device.serial`, `device.cordova`, `device.sdkVersion`, `device.version`. Toutes ces propriétés sont disponibles après l'événement `deviceready`. Les propriétés `manufacturer`, `model`, `uuid`, `serial`, `sdkVersion` sont spécifiques à Android.
- **Conséquence sur l'implémentation** : Ce plugin est utilisé comme source principale pour le fabricant, le modèle, la version Android (`device.version`), le SDK (`device.sdkVersion`), le UUID, le numéro de série, et la version Cordova (`device.cordova`). Il est ajouté par `cordova plugin add cordova-plugin-device`.

## 2. cordova-plugin-battery-status

- **URL** : https://cordova.apache.org/docs/en/latest/reference/cordova-plugin-battery-status/index.html
- **URL GitHub** : https://github.com/apache/cordova-plugin-battery-status
- **Information vérifiée** : Le plugin `cordova-plugin-battery-status` fournit l'événement `batterystatus` avec les propriétés `level` (0-100) et `isPlugged` (boolean). Cet événement est déclenché après `deviceready`. Il n'y a pas de méthode directe pour obtenir le niveau actuel, il faut écouter l'événement.
- **Conséquence sur l'implémentation** : Le niveau de batterie et l'état de charge sont obtenus en écoutant l'événement `batterystatus`. Un timeout de secours est implémenté car l'événement peut ne pas se déclencher immédiatement. Le plugin est ajouté par `cordova plugin add cordova-plugin-battery-status`.

## 3. cordova-plugin-network-information

- **URL** : https://cordova.apache.org/docs/en/latest/reference/cordova-plugin-network-information/index.html
- **URL** : https://github.com/apache/cordova-plugin-network-information
- **Information vérifiée** : Le plugin `cordova-plugin-network-information` (v3.1.0) expose `navigator.connection.type` avec les constantes `Connection.UNKNOWN`, `Connection.ETHERNET`, `Connection.WIFI`, `Connection.CELL_2G`, `Connection.CELL_3G`, `Connection.CELL_4G`, `Connection.CELL_5G`, `Connection.CELL`, `Connection.NONE`. La propriété `navigator.onLine` indique la connectivité internet.
- **Conséquence sur l'implémentation** : Le type de connexion réseau est lu via `navigator.connection.type` et converti en nom lisible. La propriété `navigator.onLine` indique si l'appareil a accès à Internet. Le plugin est ajouté par `cordova plugin add cordova-plugin-network-information`.

## 4. cordova-plugin-screen-orientation

- **URL** : https://cordova.apache.org/docs/en/latest/reference/cordova-plugin-screen-orientation/index.html
- **URL** : https://github.com/apache/cordova-plugin-screen-orientation/blob/master/README.md
- **Information vérifiée** : Le plugin `cordova-plugin-screen-orientation` (v3.0.4) expose `screen.orientation.type` pour obtenir l'orientation actuelle et permet de la verrouiller/déverrouiller via `screen.orientation.lock()` et `screen.orientation.unlock()`.
- **Conséquence sur l'implémentation** : L'orientation est lue via `screen.orientation.type` si disponible, avec un fallback sur `window.orientation`. Le plugin est ajouté par `cordova plugin add cordova-plugin-screen-orientation`.

## 5. cordova-plugin-file

- **URL** : https://cordova.apache.org/docs/en/latest/reference/cordova-plugin-file/index.html
- **URL GitHub** : https://github.com/apache/cordova-plugin-file
- **Information vérifiée** : Le plugin `cordova-plugin-file` (v8.1.3) fournit `cordova.file.dataDirectory` et `resolveLocalFileSystemURL()` avec `getMetadata()` qui retourne `size` et `freeSize`. Attention : Android 11+ (API 30) impose le Scoped Storage, ce qui rend l'accès au stockage externe limité.
- **Conséquence sur l'implémentation** : Le stockage est mesuré via `resolveLocalFileSystemURL(cordova.file.dataDirectory)` puis `getMetadata()`. En cas d'échec, le stockage est affiché comme `null`. Le plugin est ajouté par `cordova plugin add cordova-plugin-file`. La préférence `AndroidPersistentFileLocation` est configurée dans `config.xml`.

## 6. Android runtime permissions (caméra, microphone, notifications)

- **URL** : https://developer.android.com/training/permissions/requesting
- **URL** : https://developer.android.com/about/versions/13/behavior-changes-all
- **URL** : https://developer.android.com/guide/topics/permissions/overview
- **Information vérifiée** :
  - `CAMERA` et `RECORD_AUDIO` sont des permissions dangereuses (runtime) depuis Android 6.0 (API 23).
  - `POST_NOTIFICATIONS` est une permission dangereuse depuis Android 13 (API 33).
  - Sur Android 12+, il y a des indicateurs de confidentialité pour l'accès caméra/microphone.
  - Sur Android 11+, permission "Only this time" pour les permissions sensibles.
  - `navigator.permissions.query()` peut être utilisé dans le WebView pour vérifier l'état des permissions.
- **Conséquence sur l'implémentation** : Les permissions `CAMERA`, `RECORD_AUDIO`, et `POST_NOTIFICATIONS` sont déclarées dans `AndroidManifest.xml` via `config.xml`. L'état des permissions est vérifié via `navigator.permissions.query()`. Un bouton "Request Permissions" permet de les demander via `navigator.permissions.request()`. Le plugin `cordova-plugin-dialogs` est ajouté pour les alertes natives.

## 7. Cordova Android version et setup

- **URL** : https://www.npmjs.com/package/cordova-android
- **Information vérifiée** : `cordova-android@15.0.0` est la dernière version disponible (2026). Elle cible Android SDK 36. Cordova 13.0.0 est la version CLI installée localement.
- **Conséquence sur l'implémentation** : Le projet est créé avec `cordova create` puis la plateforme `android@15.0.0` est ajoutée. Les plugins sont installés via `cordova plugin add`.

## 8. ADB multi-device

- **URL** : https://android.googlesource.com/platform/packages/modules/adb/%2B/refs/heads/main/docs/user/adb.1.md
- **URL** : https://codemia.io/knowledge-hub/path/how_to_use_adb_shell_when_multiple_devices_are_connected_fails_with_error_more_than_one_device_and_emulator
- **Information vérifiée** :
  - `adb devices -l` liste tous les appareils connectés avec détails.
  - `adb -s <serial> <command>` cible un appareil spécifique.
  - `adb get-serialno` retourne le serial du seul appareil connecté.
  - Il ne faut jamais supposer qu'un seul appareil est connecté.
  - `adb shell getprop ro.product.manufacturer`, `ro.product.model`, `ro.build.version.release` pour les infos appareil.
  - `adb shell dumpsys battery` pour la batterie.
  - `adb shell wm size` et `adb shell wm density` pour l'écran.
  - `adb shell df /data` pour le stockage.
  - `adb shell pm check-permission <perm>` pour les permissions.
- **Conséquence sur l'implémentation** : Les scripts macOS utilisent `adb devices -l` pour découvrir tous les appareils, puis itèrent sur chacun avec `adb -s <serial>`. Aucune commande n'est exécutée sans spécifier de serial lorsqu'il y a plusieurs appareils. Les rapports sont générés par appareil avec le serial dans le nom de fichier.

## 9. JSON Schema validation

- **URL** : `benchmark/report.schema.json` (local)
- **Information vérifiée** : Le schéma exige les champs `generatedAt`, `device` (avec `manufacturer`, `model`), `android` (avec `version`), `battery` (avec `level`, `plugged`), `permissions` (avec `camera`, `microphone`, `notifications`). Les permissions doivent être l'une des valeurs `"granted"`, `"denied"`, `"not-applicable"`, `"unknown"`.
- **Conséquence sur l'implémentation** : Le rapport JSON généré par l'application et par les scripts ADB respecte ce schéma. Le champ `adb` est optionnel (`"type": ["object", "null"]`).
