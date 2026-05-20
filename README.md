# ⏱️ Timer Challenges

Une application Flutter de gestion du temps avec défis personnalisés, statistiques et suivi de progression.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![Material 3](https://img.shields.io/badge/Material-3-6750A4)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Table des matières

- [Fonctionnalités](#fonctionnalités)
- [Architecture](#architecture)
- [Technologies](#technologies)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Design](#design)
- [Développement](#développement)
- [Build & Déploiement](#build--déploiement)
- [Problèmes connus](#problèmes-connus)
- [Roadmap](#roadmap)
- [Licence](#licence)

---

## Fonctionnalités

### ⏱️ Double mode timer

| Mode | Description |
|------|-------------|
| **Chronomètre** | Mesure de performances avec précision (mm:ss:ms) |
| **Compte à rebours** | Configuration H:M:S avec sélecteurs intuitifs et boutons rapides (30s, 1m, 5m, 10m) |

Contrôles disponibles : Démarrer · Pause · Reset · Enregistrer

### 🎯 Défis personnalisés

- Création de défis avec titre, durée cible et description
- Association de sessions de timer à un défi
- Marquage des défis comme complétés
- Validation automatique des données (titre obligatoire, durée > 0)

### 📊 Statistiques & Records

**Vue globale**
- Meilleur temps (plus longue session chronomètre)
- Streak de jours consécutifs (≥ 1 session/jour)
- Historique des 20 dernières sessions (date, durée, défi lié)

**Vue par défi**
- Meilleur temps individuel
- Nombre total de sessions
- Progression vers l'objectif

---

## Architecture

### Structure du projet

```
lib/
├── main.dart                    # Point d'entrée + thème Material 3
├── models/                      # Modèles de données immutables
│   ├── challenge.dart           # Défi (final class)
│   └── session.dart             # Session de timer (final class + enum)
├── services/                    # Logique métier pure
│   ├── timer_service.dart       # Gestion Stopwatch/Countdown
│   ├── challenge_service.dart   # CRUD défis + validation
│   └── records_service.dart     # Calculs statistiques + streak
├── providers/                   # Gestion d'état Riverpod
│   └── providers.dart           # StateNotifiers (Timer, Challenges, Records)
└── screens/                     # Interface utilisateur
    ├── timer_screen.dart        # Écran principal avec double mode
    ├── challenges_screen.dart   # Liste des défis
    ├── create_challenge_screen.dart  # Formulaire de création
    └── records_screen.dart      # Onglets Global / Par défi
```

### Flux de données

```
Action utilisateur
       │
       ▼
   Service          ← Logique métier + validation
       │
       ▼
StateNotifier       ← Mise à jour de l'état
       │
       ▼
ConsumerWidget      ← Reconstruction de l'UI
```

### Principes appliqués

- **Séparation des couches** : Models → Services → Providers → UI
- **Typage explicite** : pas de `var` ni `dynamic`
- **Immutabilité** : `final` par défaut, `const` à la compilation
- **Single Responsibility** : une responsabilité unique par classe
- **Widgets < 150 lignes** : extraction systématique en sous-widgets privés
- **Gestion d'erreur** : `try/catch` avec feedback utilisateur via SnackBar

---

## Technologies

| Catégorie | Package | Version | Usage |
|-----------|---------|---------|-------|
| Framework | flutter | SDK | UI cross-platform |
| État | flutter_riverpod | ^2.6.1 | StateNotifier + ConsumerWidget |
| Persistance | hive_flutter | ^1.1.0 | NoSQL local (sessions + défis) |
| Préférences | shared_preferences | ^2.5.5 | Streak uniquement |
| Navigation | go_router | ^13.2.5 | Routing déclaratif |
| Utilitaires | uuid | ^4.5.3 | Génération d'IDs uniques |

---

## Installation

### Prérequis

- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio ou Xcode (pour les émulateurs)

### Étapes

```bash
# 1. Cloner le repository
git clone https://github.com/ahmadu-ops/timer_challenges.git
cd timer_challenges

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run

# Mode release (performances optimisées)
flutter run --release
```

### Vérification de l'environnement

```bash
flutter doctor    # Vérifier l'environnement Flutter
flutter analyze   # Analyse statique du code
flutter test      # Lancer les tests
```

---

## Utilisation

### Chronomètre

1. Sélectionner l'onglet **Chronomètre**
2. Appuyer sur **Démarrer**
3. Utiliser **Pause** pour marquer une pause
4. Appuyer sur **Enregistrer** pour sauvegarder la session
5. **Reset** pour recommencer

### Compte à rebours

1. Sélectionner l'onglet **Compte à rebours**
2. Configurer la durée via les flèches ↑↓ ou les boutons rapides
3. Appuyer sur **Démarrer** — le timer décroît jusqu'à 0
4. À 0 : fond rouge + alerte visuelle
5. Appuyer sur **Enregistrer** pour sauvegarder

### Créer un défi

1. Appuyer sur l'icône 🏆
2. Cliquer sur **+** en haut à droite
3. Remplir le formulaire : titre (obligatoire), durée cible (5–120 min), description (optionnel)
4. Valider

### Lier un défi à une session

1. Sur l'écran Timer, utiliser le menu déroulant en bas
2. Sélectionner un défi actif
3. Démarrer le timer — la session sera automatiquement liée au défi à l'enregistrement

### Consulter les records

1. Appuyer sur l'icône 📊
2. **Onglet Global** : meilleur temps total, streak, historique des sessions
3. **Onglet Par défi** : stats détaillées, meilleur temps, nombre de sessions

---

## Design

L'application utilise **Material Design 3** avec mode clair/sombre automatique.

| Élément | Valeur |
|---------|--------|
| Couleur principale | `Colors.blue` |
| Typographie | Roboto (par défaut Flutter) |
| Bordures | 12–16 px arrondies |
| Cartes | Elevation 0 + bordures grises |

**Composants clés** : `SegmentedButton` pour la sélection de mode · `LinearProgressIndicator` pour le countdown · `FittedBox` pour l'affichage du timer · `DropdownButtonFormField` pour la sélection de défi

---

## Développement

### Ajouter une fonctionnalité

1. Créer le modèle dans `models/` (si nécessaire)
2. Ajouter la logique dans `services/`
3. Créer le StateNotifier dans `providers/`
4. Construire l'UI dans `screens/`
5. Tester manuellement

### Commandes utiles

```bash
flutter run          # Hot reload (appuyer sur r dans le terminal)
flutter analyze      # Analyse statique
dart format lib/     # Formater le code
```

---

## Build & Déploiement

### Android

```bash
flutter build apk --debug      # APK de debug
flutter build apk --release    # APK de release
flutter build appbundle        # App Bundle pour Google Play
```

### iOS

```bash
flutter build ios --release    # Build depuis le terminal
open ios/Runner.xcworkspace    # Ouvrir dans Xcode
```

---

## Problèmes connus

**Lost connection to device**
- Cause : problème de hot reload
- Impact : l'app continue de fonctionner dans l'émulateur
- Solution : relancer avec `flutter run` ou effectuer un "Cold Boot"

**Warning Kotlin Gradle Plugin**
- Cause : `shared_preferences_android` pas encore migré
- Impact : aucun, warning uniquement
- Solution : attendre la mise à jour du plugin

---

## Roadmap

- [ ] Tests unitaires pour les services
- [ ] Tests d'intégration pour les providers
- [ ] Export des données (CSV / JSON)
- [ ] Graphiques de progression
- [ ] Notifications pour countdown terminé
- [ ] Thèmes personnalisés
- [ ] Synchronisation cloud (Firebase)
- [ ] Backup / Restore local
- [ ] Widget homescreen
- [ ] Support tablette avec layout adaptatif

---

## Licence

[MIT License](LICENSE)

---

## Auteur

**Cheikhouna Modou Bamba FALL** — [@ahmadu-ops](https://github.com/ahmadu-ops) · cheikhounambfallsn@gmail.com

---