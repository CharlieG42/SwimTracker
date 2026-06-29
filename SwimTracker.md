# SwimTracker — Documentation complète
## Application Garmin Instinct 2X Solar — Connect IQ SDK 9.1.0

---

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Environnement de développement](#environnement-de-développement)
3. [Architecture du projet](#architecture-du-projet)
4. [Description détaillée de chaque fichier](#description-détaillée-de-chaque-fichier)
5. [Algorithme de détection des virages](#algorithme-de-détection-des-virages)
6. [Navigation et boutons](#navigation-et-boutons)
7. [Enregistrement FIT](#enregistrement-fit)
8. [Paramètres de détection réglables](#paramètres-de-détection-réglables)
9. [Règles critiques SDK 9.1.0](#règles-critiques-sdk-910)
10. [Historique des problèmes résolus](#historique-des-problèmes-résolus)
11. [Pistes d'amélioration](#pistes-damélioration)
12. [Repartir de zéro](#repartir-de-zéro)

---

## Vue d'ensemble

SwimTracker est une application de suivi de natation en piscine pour la **Garmin Instinct 2X Solar**, développée en **Monkey C** avec le **Connect IQ SDK 9.1.0**.

### Fonctionnalités principales
- Suivi d'une activité natation piscine **sans GPS**
- Détection automatique des virages via **accéléromètre 3 axes**
- Longueurs de piscine réglables : 8, 10, 15, 20, 25, 33, 50m
- Affichage en temps réel : durée, longueurs, allure, distance, mouvements
- Enregistrement FIT compatible Garmin Connect
- Paramètres de détection réglables **sans recompilation**
- Écran debug pour calibration des seuils en conditions réelles

### Champs affichés
| Champ | Description | Format |
|---|---|---|
| Durée | Temps actif (hors pauses) | mm:ss / hh:mm:ss |
| Longueurs | Nombre de longueurs détectées | entier |
| Allure | Moyenne glissante sur 3 longueurs | mm:ss/100m |
| Distance | Longueurs × taille piscine | m / km |
| Mouvements | Pics détectés / estimation temporelle | X / Y |

---

## Environnement de développement

### Outils requis
- **Garmin Connect IQ SDK 9.1.0** — [developer.garmin.com/connect-iq/sdk](https://developer.garmin.com/connect-iq/sdk/)
- **Visual Studio Code** + extension **Monkey C** (officielle Garmin)
- **Java** (requis par le compilateur Monkey C)
- **OpenSSL** (pour générer la clé développeur)

### Installation sur Mac
```bash
# 1. Installer le SDK via le gestionnaire Garmin
# Le SDK s'installe dans :
# ~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-XXXX/

# 2. Ajouter monkeyc au PATH dans ~/.zshrc
export PATH="$PATH:$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-XXXX/bin"

# 3. Générer la clé développeur (à faire une seule fois)
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER \
    -in developer_key.pem -out developer_key.der -nocrypt

# Conserver developer_key.der en lieu sûr — ne jamais la publier sur Git
```

### Compilation
```bash
cd /chemin/vers/SwimTracker

# Compiler
monkeyc -f monkey.jungle -o SwimTracker.prg -d instinct2x \
    -y ~/.garmin/developer_key.der

# Compiler et lancer dans le simulateur (ouvrir connectiq en parallèle)
connectiq &  # Terminal 1 — laisser ouvert
monkeyc -f monkey.jungle -o SwimTracker.prg -d instinct2x \
    -y ~/.garmin/developer_key.der && monkeydo SwimTracker.prg instinct2x
```

### Script de compilation rapide
Créer `run.sh` à la racine du projet :
```bash
#!/bin/bash
monkeyc -f monkey.jungle -o SwimTracker.prg -d instinct2x \
    -y ~/.garmin/developer_key.der && monkeydo SwimTracker.prg instinct2x
chmod +x run.sh
```

### Installation sur la montre
1. Brancher la montre en USB
2. Copier `SwimTracker.prg` dans `GARMIN/APPS/` sur la montre
3. L'app apparaît dans la liste des activités

### Simulateur — mapping des touches
| Touche clavier | Bouton Instinct 2X |
|---|---|
| Entrée | GPS (haut droit) — peu fiable dans les views |
| Echap | SET/BACK (bas droit) ← **bouton principal** |
| Flèche haut | MENU/UP (milieu gauche) |
| Flèche bas | ABC/DOWN (bas gauche) |
| F2 | CTRL/LIGHT (haut gauche) — non interceptable |

---

## Architecture du projet

```
SwimTracker/
├── manifest.xml                    ← Déclaration app Connect IQ
├── monkey.jungle                   ← Configuration de build
├── SwimTracker.md                  ← Ce document
├── source/
│   ├── SwimTrackerApp.mc           ← Point d'entrée
│   ├── SwimModel.mc                ← Modèle + détection + FIT
│   ├── PoolSetupView.mc            ← Écran config longueur piscine
│   ├── SwimView.mc                 ← Écran principal activité
│   ├── PauseMenuView.mc            ← Menu pause natif Menu2
│   ├── SummaryView.mc              ← Résumé post-activité (Menu2)
│   ├── SettingsView.mc             ← Réglages paramètres détection
│   └── DebugView.mc                ← Écran debug capteur
└── resources/
    ├── drawables/
    │   ├── drawables.xml           ← Référence l'icône
    │   └── launcher_icon.svg       ← Icône 62×62px
    └── strings/
        └── strings.xml             ← Chaînes de caractères
```

### manifest.xml — structure obligatoire
```xml
<?xml version="1.0"?>
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
  <iq:application
    entry="SwimTrackerApp"
    id="a3f5e2d1-b4c6-4e8a-9d0f-1a2b3c4d5e6f"
    minSdkVersion="3.4.0"
    name="@Strings.AppName"
    type="watch-app"
    launcherIcon="@Drawables.LauncherIcon"
    version="1.0.0">
    <iq:products>
      <iq:product id="instinct2x"/>
    </iq:products>
    <iq:permissions>
      <iq:uses-permission id="Sensor"/>
      <iq:uses-permission id="Fit"/>
      <iq:uses-permission id="FitContributor"/>
    </iq:permissions>
    <iq:languages>
      <iq:language>eng</iq:language>
      <iq:language>fre</iq:language>
    </iq:languages>
  </iq:application>
</iq:manifest>
```

**Points critiques manifest :**
- Namespace : `http://www.garmin.com/xml/connectiq` (pas `com.garmin.devices/...`)
- Pas de `launchType` (supprimé en SDK 9.x)
- `FitRecording` n'existe plus → utiliser `Fit` + `FitContributor`
- Le fichier ne doit contenir **aucun caractère avant `<?xml`**

### monkey.jungle
```
project.manifest = manifest.xml
base.sourcePath = source
base.resourcePath = resources
```

---

## Description détaillée de chaque fichier

### SwimTrackerApp.mc
Point d'entrée de l'application. Crée le `SwimModel` et retourne la vue initiale.

```monkeyc
function getInitialView() {  // SANS annotation de type de retour — obligatoire
    var view = new PoolSetupView(_swimModel);
    var delegate = new PoolSetupDelegate(_swimModel);
    return [view, delegate];
}
```

**Règle critique** : `getInitialView()` ne doit **jamais** avoir d'annotation de type de retour en SDK 9.x. Ni `as Array<...>` ni aucune autre annotation.

---

### SwimModel.mc
Le cœur de l'application. Contient :
- L'énumération des états (`STATE_SETUP`, `STATE_READY`, `STATE_ACTIVE`, `STATE_PAUSED`, `STATE_FINISHED`)
- Les constantes et valeurs par défaut des paramètres de détection
- Le chargement/sauvegarde des paramètres via `Application.Storage`
- Le contrôle de l'activité (`startActivity`, `pauseActivity`, `resumeActivity`, `finishActivity`, `discardActivity`)
- Le callback accéléromètre `onSensorData` et l'algorithme de détection
- L'enregistrement FIT via `ActivityRecording` et `FitContributor`
- Les getters formatés pour l'affichage (durée, distance, allure)
- Les champs debug exposés publiquement pour `DebugView`

**Paramètres de détection** (publics, persistants) :
```monkeyc
var swimThreshold  as Float  = 1.5f;   // g — seuil nage active
var turnThreshold  as Float  = 1.5f;   // g — seuil virage/repos
var minSwimTimeMs  as Number = 500;    // ms — confirmation nage
var minLapTimeMs   as Number = 1200;   // ms — anti-rebond entre longueurs
```

**Champs FIT créés** :
```monkeyc
// Session (résumé final)
"pool_distance_m"    — field 0 — FLOAT  — MESG_TYPE_SESSION
"lap_distance_m"     — field 4 — FLOAT  — MESG_TYPE_LAP

// Record (série temporelle, ~1x/s)
"debug_amp_max"      — field 1 — FLOAT  — MESG_TYPE_RECORD
"debug_ratio"        — field 2 — FLOAT  — MESG_TYPE_RECORD
"debug_turn_detected"— field 3 — UINT8  — MESG_TYPE_RECORD
```

---

### PoolSetupView.mc
Premier écran affiché au lancement. Permet de sélectionner la longueur de piscine parmi 7 valeurs prédéfinies. La valeur est sauvegardée automatiquement dans `Application.Storage`.

**Boutons** :
- `KEY_ESC` (SET) → valider et passer à `SwimView`
- `KEY_UP` (MENU) → ouvrir `SettingsView`
- `KEY_DOWN` (ABC) → diminuer la longueur
- `onBack()` long → `System.exit()` quitter l'app

**Point critique** : `fillPolygon` fonctionne sans cast de type.
```monkeyc
// Syntaxe correcte — SANS "as Array<Array<Number>>"
dc.fillPolygon([[cx, cy - 10], [cx - 12, cy + 4], [cx + 12, cy + 4]]);
```

---

### SwimView.mc
Écran principal affiché pendant toute l'activité. Rafraîchi toutes les secondes via un `Timer`. Affiche dynamiquement selon l'état courant.

**Layout (176×176px)** :
```
[ NATATION          10m ]  ← titre + taille piscine
[ ● ACTIF               ]  ← indicateur état
[─────────────────────── ]
[       DUREE            ]
[       00:43            ]  ← FONT_NUMBER_MEDIUM
[─────────────────────── ]
[ LONG. │ ALLURE         ]
[   4   │ 1:23           ]
[       │ /100m          ]
[─────────────────────── ]
[ DISTANCE │ MVTS        ]
[   40 m   │ 12/18       ]
[─────────────────────── ]
[ UP:reglages  SET:start ]  ← aide contextuelle
```

**Comportement contextuel de KEY_UP** :
- `STATE_READY` → ouvre `SettingsView`
- `STATE_ACTIVE` / `STATE_PAUSED` → ouvre `DebugView`

---

### PauseMenuView.mc
Menu pause utilisant `WatchUi.Menu2` natif Garmin. Affiché après `pauseActivity()`.

**Options** :
1. **Reprendre** → `resumeActivity()` + `popView`
2. **Sauvegarder** → `finishActivity()` + `popView` + `pushView(SummaryMenu)`
3. **Voir résumé** → `pushView(SummaryMenu)` (sans terminer)
4. **Quitter** → `discardActivity()` + `resetActivity()` + retour setup

**Règle critique** : depuis un `Menu2InputDelegate`, utiliser `popView` puis `pushView` plutôt que `switchToView` pour éviter que le menu reste affiché par-dessus la vue suivante.

---

### SummaryView.mc
Résumé post-activité implémenté comme un `WatchUi.Menu2` scrollable. Chaque statistique est un `MenuItem` avec label et sous-label.

**Éléments affichés** :
- Durée, Distance, Longueurs, Allure, Mouvements, Piscine
- Dernière entrée : "Quitter" (si activité terminée) ou "Retour" (si consultation depuis menu pause)

**Navigation sortie** :
- Si `STATE_FINISHED` → `resetActivity()` + `System.exit()`
- Sinon (consultation) → `popView` vers le menu pause

---

### SettingsView.mc
Écran de réglage des 4 paramètres de détection. Fonctionne en deux modes :
- **Mode navigation** (fond gris sur ligne sélectionnée) : UP/DOWN déplacent la sélection
- **Mode édition** (fond blanc) : UP/DOWN modifient la valeur, SET valide

La valeur est sauvegardée immédiatement à chaque modification dans `Application.Storage`.

**Bornes des paramètres** :
| Paramètre | Min | Max | Pas |
|---|---|---|---|
| Seuil nage | 0.5g | 3.0g | 0.1g |
| Seuil virage | 0.3g | 1.5g | 0.1g |
| Temps nage min | 500ms | 5000ms | 250ms |
| Temps entre long. | 1000ms | 10000ms | 250ms |

---

### DebugView.mc
Écran de calibration affiché pendant l'activité (sans l'interrompre). Rafraîchi 4×/seconde.

**Valeurs affichées** :
```
DEBUG CAPTEUR
─────────────────
X    │ 1.24
Y    │ 0.87
Z    │ 2.10
─────────────────
MAX  │ 2.10     ← valeur retenue pour la détection
FAST │ 1.89     ← moyenne rapide (smoothing 0.3)
BASE │ 1.45     ← baseline (smoothing 0.05)
RATIO│ 1.30     ← fast/baseline — comparé aux seuils
─────────────────
Min:0.12  Max:4.82  ← extrêmes observés depuis le début
```

**Utilisation** : lire MAX et RATIO pendant la nage normale et pendant un virage pour calibrer `swimThreshold` et `turnThreshold`.

---

## Algorithme de détection des virages

### Découverte clé (issue de l'analyse des fichiers FIT réels)

Pendant la nage crawl en piscine de 10m, le signal accéléromètre présente :
- **Pendant la nage** : amplitude pic-à-pic oscillant entre **1.0g et 5.7g**, moyenne ~2.2g
- **Pendant le virage** (repos au mur) : amplitude chutant à **~0.96g**

La signature d'un virage est donc un **creux d'amplitude**, pas un pic. Tous les algorithmes basés sur la détection d'un pic ont échoué car :
1. L'amplitude de nage normale est déjà très élevée
2. La baseline s'adaptait trop vite et neutralisait les pics relatifs

### Machine à états

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   REPOS ──────────────────────────────────────────────►      │
│     │   amp ≥ swimThreshold pendant minSwimTimeMs            │
│     │                                                        │
│     ▼                                                        │
│   NAGE ACTIVE                                                │
│     │                                                        │
│     │   amp < turnThreshold                                  │
│     │   ET timeSinceLastLap ≥ minLapTimeMs                  │
│     ▼                                                        │
│   VIRAGE DÉTECTÉ ──────────────────────────────────────────► │
│     │   lapCount += 1                                        │
│     │   session.addLap()                                     │
│     │   retour à REPOS                                       │
└──────────────────────────────────────────────────────────────┘
```

### Pipeline de traitement du signal

```
Capteur (25 Hz, axe X + Y + Z)
    │
    ▼
Amplitude pic-à-pic par axe = max(samples) - min(samples)
    │
    ▼
Amplitude retenue = max(ampX, ampY, ampZ) / 1000  [mg → g]
    │
    ├──► _fastAccel    = _fastAccel × 0.7 + amplitude × 0.3   (réagit en ~0.5s)
    └──► _baselineAccel = _baselineAccel × 0.95 + amplitude × 0.05 (très lente)
              │
              ▼
         Machine à états (swimThreshold, turnThreshold, minSwimTimeMs, minLapTimeMs)
```

### Choix d'utiliser l'amplitude max sur 3 axes
L'axe dominant varie selon le style de nage :
- **Crawl** : fort sur Z (rotation du poignet)
- **Brasse** : fort sur X/Y (poussée avant)
- Prendre le maximum garantit la couverture de tous les styles

### Calibration recommandée
1. Ouvrir l'écran Debug (UP pendant la nage)
2. Nager 2-3 longueurs normalement et noter le **MAX** observé
3. Effectuer un virage et noter la chute de **FAST**
4. Régler `swimThreshold` légèrement sous le MAX de nage
5. Régler `turnThreshold` légèrement au-dessus de la valeur au virage
6. Vérifier avec `MIN_LAP_TIME` que le délai est inférieur au temps d'une longueur

---

## Navigation et boutons

### Instinct 2X Solar — disposition physique
```
         ┌──────────┐
  CTRL   │          │ GPS
  LIGHT  │  ÉCRAN   │ (haut droit)
(haut    │ 176×176  │ — peu fiable
gauche)  │          │   dans les views
         │          │
  MENU   │          │ SET
  UP     │          │ BACK
(milieu  │          │ (bas droit)
gauche)  │          │ ← BOUTON PRINCIPAL
         │          │
  ABC    │          │
  DOWN   └──────────┘
(bas
gauche)
```

### Correspondance touches / constantes Monkey C
| Bouton physique | Constante Monkey C | Fiabilité dans les views |
|---|---|---|
| GPS (haut droit) | `KEY_START` | ⚠️ Parfois intercepté par le système |
| SET/BACK (bas droit) | `KEY_ESC` | ✅ Fiable — bouton principal de l'app |
| MENU/UP (milieu gauche) | `KEY_UP` | ✅ Fiable |
| ABC/DOWN (bas gauche) | `KEY_DOWN` | ✅ Fiable |
| CTRL/LIGHT (haut gauche) | `KEY_LIGHT` | ❌ Non interceptable par les apps |

### Flux de navigation complet
```
[Lancement] → PoolSetupView
                 │ SET → valider longueur
                 │ UP  → SettingsView
                 │ DN  → changer longueur
                 │ BACK long → quitter app
                 ▼
              SwimView (STATE_READY)
                 │ SET → démarrer (STATE_ACTIVE)
                 │ UP  → SettingsView
                 ▼
              SwimView (STATE_ACTIVE)
                 │ SET → PauseMenu
                 │ UP  → DebugView
                 │ DN  → +1 longueur manuelle
                 ▼
              PauseMenu
                 │ Reprendre → SwimView (STATE_ACTIVE)
                 │ Sauvegarder → SummaryMenu (STATE_FINISHED)
                 │ Voir résumé → SummaryMenu (STATE_PAUSED)
                 │ Quitter → PoolSetupView (STATE_READY)
                 ▼
              SummaryMenu
                 │ Quitter (si terminé) → System.exit()
                 │ Retour (si pause) → PauseMenu
```

---

## Enregistrement FIT

### Structure de la session FIT
L'app crée une session avec :
```monkeyc
var options = {
    :name     => "Natation Piscine",
    :sport    => Activity.SPORT_SWIMMING,
    :subSport => Activity.SUB_SPORT_LAP_SWIMMING
};
_session = ActivityRecording.createSession(options);
```

### Gestion des laps (critical pour la distance Garmin)
À chaque longueur détectée, l'app appelle `_session.addLap()`. C'est ce qui permet à Garmin Connect de calculer correctement la distance totale de la session.

```monkeyc
// Dans _recordLap() :
if (_lapDistanceField != null) {
    _lapDistanceField.setData(getPoolLength().toFloat());
}
if (_session != null) {
    _session.addLap();  // Déclenche l'écriture du message LAP dans le FIT
}
```

### Fin de session
```monkeyc
// Sauvegarder
_session.stop();
_session.save();   // → fichier FIT créé dans GARMIN/ACTIVITY/

// Abandonner sans sauvegarder
_session.stop();
_session.discard();  // → supprime les données, rien enregistré
```

### Analyse des fichiers FIT
Les fichiers FIT peuvent être analysés après la session :
```bash
# Via FitCSVTool (inclus dans le SDK Garmin)
java -jar ~/Library/Application Support/Garmin/ConnectIQ/Sdks/.../bin/FitCSVTool.jar \
    -b activite.fit activite.csv

# Les champs debug apparaissent dans les messages RECORD :
# - debug_amp_max   : amplitude capteur en g
# - debug_ratio     : ratio fast/baseline
# - debug_turn_detected : 1 = virage détecté à ce moment
```

---

## Paramètres de détection réglables

### Accès
- Depuis `PoolSetupView` : bouton **UP** (MENU)
- Depuis `SwimView` en état READY : bouton **UP** (MENU)

### Navigation dans SettingsView
- **UP / DOWN** : naviguer entre les 4 paramètres (mode navigation)
- **SET** : entrer en mode édition (ligne surlignée en blanc)
- **UP / DOWN** en mode édition : augmenter / diminuer la valeur
- **SET** : valider et revenir en mode navigation
- **BACK long** : quitter l'écran réglages

### Les 4 paramètres

#### swimThreshold (seuil nage) — défaut : 1.5g
Amplitude minimale pour que l'app reconnaisse une phase de nage active.
- Trop bas → faux positifs (glisse = nage)
- Trop haut → nage non reconnue → virages jamais détectés

#### turnThreshold (seuil virage) — défaut : 1.5g
Amplitude maximale pour déclencher la détection d'un virage. Se déclenche quand le signal **chute sous cette valeur** après une phase de nage.
- Trop bas → il faut s'arrêter complètement → virages ratés
- Trop haut → faux positifs en pleine nage

#### minSwimTimeMs (temps nage min) — défaut : 500ms
Durée pendant laquelle l'amplitude doit rester au-dessus de `swimThreshold` pour valider une phase de nage active.
- Trop court (< 200ms) → un rebond au mur peut déclencher immédiatement
- Trop long (> 2000ms) → irréaliste sur une piscine de 10m (~10s/longueur)

#### minLapTimeMs (temps entre longueurs) — défaut : 1200ms
Délai anti-rebond minimum entre deux détections de virage.
- Trop court → un virage peut déclencher plusieurs fois (rebonds signal)
- Trop long → bloque la détection du virage suivant

### Valeurs testées et résultats
| swimThreshold | turnThreshold | minSwimTimeMs | minLapTimeMs | Résultat |
|---|---|---|---|---|
| 2.5g | — | — | 8000ms | 4/14 longueurs détectées (trop restrictif) |
| 1.2g (3 axes) | — | — | 4000ms | Surcomptage massif (229m/100m) |
| ratio 1.6x baseline | — | — | 7000ms | Bloqué en `_peakDetected=true` — aucune détection |
| 1.5g | 0.9g | 1500ms | 5000ms | 4/10 longueurs (minSwimTimeMs trop long) |
| 1.5g | 1.5g | 500ms | 1200ms | **Résultats proches** — configuration actuelle |

---

## Règles critiques SDK 9.1.0

Ces règles ont été découvertes lors du développement et doivent être respectées scrupuleusement pour éviter des heures de débogage.

### 1. Typage des variables

```monkeyc
// ✅ CORRECT — pas de type sur les variables locales
var state = _model.state;
var x = 42;

// ❌ INTERDIT — le compilateur rejette les types sur les variables locales
var state as ActivityState = _model.state;
var x as Number = 42;

// ✅ OK — les types sont autorisés sur les propriétés de classe
private var _model as SwimModel;
var lapCount as Number = 0;

// ✅ OK — les types sont autorisés sur les paramètres de fonctions
function foo(model as SwimModel, count as Number) as Void { ... }
```

### 2. getInitialView()

```monkeyc
// ✅ CORRECT — sans annotation de type
function getInitialView() {
    return [new PoolSetupView(_model), new PoolSetupDelegate(_model)];
}

// ❌ INTERDIT — toute annotation de type provoque une erreur de compilation
function getInitialView() as Array<WatchUi.Views or WatchUi.InputDelegates>? { ... }
function getInitialView() as [WatchUi.Views] or Null { ... }
```

### 3. fillPolygon

```monkeyc
// ✅ CORRECT — sans cast de type
dc.fillPolygon([[cx, cy - 8], [cx - 10, cy + 4], [cx + 10, cy + 4]]);

// ❌ INTERDIT — le cast provoque une erreur de type
dc.fillPolygon([[cx, cy - 8], [cx - 10, cy + 4], [cx + 10, cy + 4]] as Array<Array<Number>>);
```

### 4. manifest.xml

```xml
<!-- ✅ CORRECT -->
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">

<!-- ❌ INTERDIT — ancien namespace -->
<iq:manifest xmlns:iq="com.garmin.devices/connectiq-core/manifest" version="3">

<!-- ❌ INTERDIT — supprimé en SDK 9.x -->
<iq:application launchType="Sport" ...>

<!-- ❌ INTERDIT — permission renommée -->
<iq:uses-permission id="FitRecording"/>
<!-- ✅ CORRECT -->
<iq:uses-permission id="Fit"/>
<iq:uses-permission id="FitContributor"/>
```

### 5. Boutons sur Instinct 2X

```monkeyc
// ✅ Bouton fiable — SET/BACK (bas droit)
if (key == WatchUi.KEY_ESC) { ... }

// ⚠️ GPS (haut droit) — peu fiable dans les BehaviorDelegate views
// À utiliser uniquement si testé et confirmé fonctionnel
if (key == WatchUi.KEY_START) { ... }

// ❌ CTRL/LIGHT (haut gauche) — non interceptable, réservé système
// N'utiliser ni KEY_LIGHT ni onMenu() pour ce bouton

// ✅ Pour le menu natif, utiliser onMenu() (appui long sur MENU/UP)
function onMenu() as Boolean { ... }
```

### 6. Navigation entre vues

```monkeyc
// ✅ Depuis un Menu2InputDelegate — pop puis push
WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
WatchUi.pushView(new MaView(), new MonDelegate(), WatchUi.SLIDE_LEFT);

// ❌ Éviter switchToView depuis Menu2InputDelegate
// → peut laisser le menu affiché par-dessus
WatchUi.switchToView(...);

// ✅ Quitter l'app proprement
System.exit();
```

### 7. Session FIT — sauvegarder vs abandonner

```monkeyc
// ✅ Sauvegarder
_session.stop();
_session.save();

// ✅ Abandonner sans sauvegarder
_session.stop();
_session.discard();  // OBLIGATOIRE — stop() seul peut créer un fichier incomplet

// ❌ stop() seul — comportement indéfini selon le firmware
_session.stop();
// (oubli de save() ou discard())
```

### 8. Icône launcher

```xml
<!-- Dimensions exactes requises : 62×62px (pas 70×70) -->
<svg xmlns="http://www.w3.org/2000/svg" width="62" height="62" viewBox="0 0 62 62">
```

---

## Historique des problèmes résolus

| # | Problème | Symptôme | Solution |
|---|---|---|---|
| 1 | Namespace manifest incorrect | `cvc-elt.1.a : Déclaration de l'élément 'iq:manifest' introuvable` | Changer `com.garmin.devices/...` → `http://www.garmin.com/xml/connectiq` |
| 2 | Doublon `<?xml` dans manifest | `L'instruction de traitement "[xX][mM][lL]" n'est pas autorisée` | Supprimer la ligne `<?xml` en double |
| 3 | Attribut `launchType` interdit | `L'attribut 'launchType' n'est pas autorisé` | Supprimer `launchType="Sport"` du manifest |
| 4 | Permission `FitRecording` invalide | `Invalid permission: FitRecording` | Remplacer par `Fit` + `FitContributor` |
| 5 | Icône manquante | `A launcher icon must be specified` | Créer `launcher_icon.svg` 62×62 + `drawables.xml` |
| 6 | String resource manquante | `A string resource matching the app name can't be found` | Créer `strings.xml` avec `<string id="AppName">` |
| 7 | Types sur variables locales | `Invalid explicit typing of a local variable` | Supprimer tous les types sur les variables locales |
| 8 | `getInitialView()` type de retour | `Cannot override getInitialView with a different return type` | Supprimer complètement l'annotation de type |
| 9 | `KEY_BACK` inexistant | `Undefined symbol ':KEY_BACK'` | Remplacer par `KEY_ESC` |
| 10 | `fillPolygon` type invalide | `Invalid Array<Array<Number>> passed as parameter 1` | Supprimer le cast `as Array<Array<Number>>` |
| 11 | FIT : permission manquante | `Permission 'Fit' required for ActivityRecording` | Ajouter `Fit` + `FitContributor` dans manifest |
| 12 | GPS ne démarre pas l'activité | Aucune réaction au bouton GPS | Utiliser `KEY_ESC` (SET/BACK) comme bouton principal |
| 13 | Menu pause laisse trace visuelle | Ancienne vue visible sous le résumé | `popView` puis `pushView` au lieu de `switchToView` |
| 14 | Distance erronée dans Garmin | 91m affichés pour 40m réels | Appeler `session.addLap()` + champ `lap_distance_m` |
| 15 | Quitter sauvegarde quand même | Activité enregistrée malgré "Quitter" | `session.discard()` obligatoire, `stop()` seul insuffisant |
| 16 | Surcomptage (229m/100m) | Seuil absolu trop bas → chaque coup de bras compte | Passage à la détection par chute d'amplitude |
| 17 | Sous-comptage (4/10 longueurs) | `_peakDetected` bloqué à `true` en nage active | Refonte algorithme : machine à états REPOS/NAGE/VIRAGE |
| 18 | CTRL/LIGHT non fonctionnel | Bouton haut-gauche inaccessible aux apps | Réservé système — utiliser MENU/UP à la place |
| 19 | Résumé vide après sauvegarde | Aucune valeur affichée (durée, distance...) | Corriger l'ordre des opérations dans PauseMenuDelegate |
| 20 | Sortie impossible sans sauvegarder | Bloqué sur PoolSetupView | `System.exit()` dans `onBack()` de PoolSetupDelegate |

---

## Pistes d'amélioration

### Amélioration de la détection

**Fusion accéléromètre + gyroscope**
Le gyroscope mesure la vitesse de rotation angulaire. Un virage produit une rotation rapide et ample (souvent 180°) très différente des rotations cycliques de la nage. Combiner les deux capteurs permettrait une détection plus discriminante.

```monkeyc
// Activation du gyroscope dans les options du listener
var options = {
    :period              => 1,
    :sampleRate          => 25,
    :enableAccelerometer => true,
    :enableGyroscope     => true  // À ajouter
};
```

**Calibration automatique**
Au lieu de seuils fixes, calculer automatiquement la baseline de nage sur les premières secondes :
- Mesurer l'amplitude moyenne sur 5-10s de nage
- Définir `swimThreshold` = 70% de cette moyenne
- Définir `turnThreshold` = 40% de cette moyenne

**Détection du motif décélération → accélération**
Chercher un creux suivi d'un pic dans la magnitude vectorielle `√(x²+y²+z²)` sur une fenêtre de 2 secondes. Plus spécifique qu'un simple seuil sur l'amplitude.

**Détection du style de nage**
Crawl, brasse, dos et papillon ont des signatures accéléromètre caractéristiques. La reconnaissance automatique du style permettrait d'adapter les seuils.

### Nouvelles fonctionnalités

**Fréquence cardiaque**
L'Instinct 2X a un capteur optique intégré. L'enregistrer dans le FIT et l'afficher pendant la nage enrichirait considérablement le suivi d'entraînement.

**Intervalles / séries**
Permettre de définir des séries (ex: 5×100m avec 30s de repos), afficher le compte à rebours de repos, compter les séries réalisées.

**Historique par longueur**
Afficher les temps des N dernières longueurs individuellement, pas uniquement la moyenne glissante.

**Mode production**
Supprimer les champs FIT debug (`debug_amp_max`, `debug_ratio`, `debug_turn_detected`) et l'écran debug pour la version finale. Cela allège les fichiers FIT et l'interface.

**Autres modes d'activité** (prévus dès l'origine du projet)
- Course à pied / Trail (GPS + cadence)
- Vélo / VTT (GPS + capteur puissance optionnel)
- Natation en eau libre (GPS)
- HIIT (intervalles + fréquence cardiaque)
- Randonnée / Marche (GPS + altimètre)

### Améliorations techniques

**Champs FIT natifs pour natation**
Utiliser les champs standardisés Garmin pour la natation (`swim_stroke`, `num_lengths`) plutôt que des champs custom, pour une meilleure intégration avec Garmin Connect et les apps tierces.

**Métriques avancées**
- SWOLF (temps + nombre de coups par longueur)
- Efficacité de nage
- Asymétrie droite/gauche (via la différence des axes X/Y)

---

## Repartir de zéro

Si tu dois recréer le projet depuis zéro avec le SDK 9.1.0, voici les étapes critiques dans l'ordre :

### Étape 1 — Créer la structure
```bash
mkdir -p SwimTracker/source
mkdir -p SwimTracker/resources/drawables
mkdir -p SwimTracker/resources/strings
```

### Étape 2 — manifest.xml
Utiliser exactement le namespace `http://www.garmin.com/xml/connectiq`. Vérifier :
- Pas de `launchType`
- Permissions : `Sensor` + `Fit` + `FitContributor`
- `launcherIcon="@Drawables.LauncherIcon"`
- `name="@Strings.AppName"`
- Pas de caractère avant `<?xml`

### Étape 3 — Resources
Créer `strings.xml` avec `AppName`, `drawables.xml` référençant l'icône, et `launcher_icon.svg` en **62×62px**.

### Étape 4 — SwimTrackerApp.mc
```monkeyc
// getInitialView SANS type de retour — règle absolue
function getInitialView() {
    return [new PremièreVue(), new PremierDelegate()];
}
```

### Étape 5 — Développer en respectant les règles
1. Jamais de type sur les variables locales
2. `KEY_ESC` comme bouton principal (pas `KEY_START`)
3. `fillPolygon` sans cast de type
4. `session.stop()` + `session.discard()` pour abandonner
5. `popView` + `pushView` depuis les `Menu2InputDelegate`
6. `System.exit()` pour quitter l'app depuis l'écran racine

### Étape 6 — Calibrer l'algorithme
1. Implémenter le mode debug (affichage valeurs brutes)
2. Enregistrer les champs FIT debug (`MESG_TYPE_RECORD`)
3. Analyser les fichiers FIT avec FitCSVTool
4. Ajuster les seuils basés sur les données réelles

---

*Document généré le 28 juin 2026 — SwimTracker v4*
*Développé avec Claude (Anthropic) — Projet Connect IQ SDK 9.1.0*
