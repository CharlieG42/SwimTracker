# SwimTracker — Application Garmin Instinct 2X Solar
## Module : Natation en Piscine

---

## 📁 Structure du projet

```
SwimTracker/
├── manifest.xml                    ← Déclaration app Connect IQ
├── source/
│   ├── SwimTrackerApp.mc           ← Point d'entrée de l'application
│   ├── SwimModel.mc                ← Modèle de données + détection longueurs
│   ├── PoolSetupView.mc            ← Écran config longueur piscine
│   ├── SwimView.mc                 ← Écran principal activité
│   └── SummaryView.mc              ← Écran résumé post-activité
└── resources/
    └── strings/strings.xml         ← Chaînes de caractères
```

---

## 🏊 Fonctionnalités

### Champs affichés
| Champ       | Description                        | Format          |
|-------------|------------------------------------|-----------------|
| **Durée**   | Temps actif (hors pauses)          | mm:ss / hh:mm:ss|
| **Allure**  | Moyenne glissante 3 longueurs      | mm:ss / 100m    |
| **Longueurs** | Nombre de longueurs effectuées   | entier          |
| **Distance**| Longueurs × taille piscine         | m / km          |

### Longueurs de piscine disponibles
`8m · 10m · 15m · 20m · 25m · 33m · 50m`  
_(réglable avant et pendant l'activité)_

---

## 🎮 Navigation — Boutons Instinct 2X

### Écran 1 : Configuration piscine
| Bouton  | Action                    |
|---------|---------------------------|
| UP ↑    | Augmenter longueur piscine |
| DOWN ↓  | Diminuer longueur piscine  |
| START   | Valider → Écran activité  |

### Écran 2 : Activité (PRÊT)
| Bouton  | Action                    |
|---------|---------------------------|
| START   | Démarrer le chrono        |
| BACK    | Retour config piscine     |

### Écran 2 : Activité (EN COURS)
| Bouton  | Action                         |
|---------|--------------------------------|
| START   | Mettre en pause                |
| DOWN ↓  | Ajouter une longueur manuelle  |

### Écran 2 : Activité (PAUSE)
| Bouton  | Action                    |
|---------|---------------------------|
| START   | Reprendre                 |
| BACK    | Terminer → Résumé         |

### Écran 3 : Résumé
| Bouton  | Action                    |
|---------|---------------------------|
| BACK    | Retour config (nouvelle session) |
| START   | Idem BACK                 |

---

## ⚙️ Algorithme de détection des virages

L'application **n'utilise pas le GPS**. La détection des changements de sens
repose sur l'**accéléromètre intégré** de la montre.

### Principe physique
Lors d'un virage en piscine (flip-turn ou virage simple), le poignet subit
une accélération caractéristique sur l'**axe Z** (perpendiculaire au plan du
bras) qui dépasse largement les valeurs de la nage régulière.

### Pipeline de traitement
```
Capteur (25 Hz)
    │
    ▼
Calcul amplitude pic-à-pic sur axe Z  (fenêtre 40ms)
    │
    ▼
Lissage IIR passe-bas  (α = 0.3)
    │
    ▼
Seuil adaptatif  (> 2.5g)
    │
    ▼
Détection flanc descendant (fin du pic)
    │
    ▼
Anti-rebond  (min 8s entre deux longueurs)
    │
    ▼
Incrément compteur + calcul allure
```

### Paramètres configurables (dans SwimModel.mc)
| Constante          | Valeur défaut | Description                      |
|--------------------|---------------|----------------------------------|
| `ACCEL_SAMPLE_RATE`| 25 Hz         | Fréquence d'échantillonnage      |
| `TURN_THRESHOLD`   | 2.5g          | Seuil de détection virage        |
| `MIN_LAP_TIME_MS`  | 8 000 ms      | Délai minimum entre longueurs    |
| `SMOOTHING_FACTOR` | 0.3           | Lissage (0=fort, 1=aucun)        |

### Ajustement si mauvaise détection
- **Trop de faux positifs** → Augmenter `TURN_THRESHOLD` (ex: 3.0)
- **Longueurs non comptées** → Diminuer `TURN_THRESHOLD` (ex: 2.0)
- **Délai trop court** → Augmenter `MIN_LAP_TIME_MS`

### Bouton de secours
En cas de non-détection, le bouton **DOWN** permet d'ajouter manuellement
une longueur sans interrompre le chrono.

---

## 📦 Installation

### Prérequis
- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) ≥ 6.x
- Visual Studio Code + extension **Monkey C**

### Compilation
```bash
# Compiler en .prg
monkeyc -f monkey.jungle -o SwimTracker.prg -d instinct2x

# Déployer sur la montre (via cable USB ou WiFi)
# Copier le .prg dans GARMIN/APPS/ sur la montre
```

### Fichier monkey.jungle à créer
```
project.manifest = manifest.xml
base.sourcePath = source
base.resourcePath = resources
```

---

## 🔄 Données enregistrées (FIT)

L'application enregistre une session FIT standard avec :
- **Sport** : Swimming (natation)
- **SubSport** : Lap Swimming (natation en couloir)
- **Champs** : durée, distance, fréquence de nage (via laps)

Le fichier est automatiquement synchronisé avec **Garmin Connect** et les
plateformes tierces (Strava, TrainingPeaks…) via l'application Connect.

---

## 🚧 Prochaines activités à implémenter

- [ ] Natation en eau libre (avec GPS)
- [ ] Course à pied / Trail (GPS + cadence)
- [ ] Vélo / VTT (GPS + puissance optionnelle)
- [ ] HIIT (intervalles + fréquence cardiaque)
- [ ] Randonnée / Marche (GPS + altimètre)

---

## 📝 Notes techniques

- Testé sur **Instinct 2X Solar** (écran 176×176, 64 couleurs)
- Compatible Connect IQ **3.4** minimum
- Consommation batterie optimisée : accéléromètre actif uniquement pendant
  la nage (désactivé en pause)
- Paramètre `poolLengthIdx` sauvegardé en mémoire persistante entre sessions
