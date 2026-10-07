# OIAC / IACO — plateforme de données du café (démo interactive)

Maquette interactive d'une plateforme de Business Intelligence pour le secteur mondial du café (focus Afrique).
**Une seule base de code Flutter** : Web, Android (et iOS).
**Aucun backend** — toutes les données sont fictives et locales (`DONNÉES DE DÉMONSTRATION`).

## Lancer

```bash
flutter pub get
flutter run -d chrome        # Web
flutter run -d <appareil>    # Android
```

## Construire

```bash
flutter build web --release --base-href "/NOM_DU_DEPOT/"   # → build/web  (GitHub Pages)
flutter build apk --release                                 # → build/app/outputs/flutter-apk/app-release.apk
```

### Publier sur GitHub Pages
1. Poussez le code sur GitHub (branche `main`).
2. *Settings → Pages → Source : GitHub Actions*.
3. Le workflow `.github/workflows/deploy-web.yml` construit et publie automatiquement.

### Installer sur un téléphone Android
Copiez `app-release.apk` sur le téléphone et ouvrez-le (autoriser les sources inconnues).

## Parcours de démonstration (10–15 min)
1. **Introduction** : faire défiler — la plante pousse (graine → racines → tige → feuilles → fleurs → cerises → grain → torréfaction → données), puis chaîne, données, indicateurs, décision.
2. **Centre de décision** (Coffee Pulse, KPI, « à surveiller », radar des risques). Cliquer un KPI → *D'où vient ce chiffre ?*
3. **Marché**, **Production** (cliquer un pays sur la carte), **Revenus**, **Durabilité**.
4. **Chaîne du café**, **Carte** (filtres animés), **Anomalies** (zoom sur la période + carte), **Prévisions**.
5. **Simulateur « Et si… »**, **Sources de données**, **Rapports**, **Assistant**.
6. Bouton **FR | EN**, thème clair/sombre, puis la même chose sur téléphone.
7. **Mode présentation** : barre de navigation guidée (8 étapes, lecture automatique possible).

## Architecture

```
lib/
  app/            état global (thème, langue, navigation, alertes utilisateur)
  core/           thème (palette café), i18n (strings.dart FR/EN), formats, extensions
  models/         modèles de domaine (Country, Anomaly, Provenance, …)
  data/
    repository.dart      ← SEUL point d'accès aux données pour l'UI (interface CoffeeRepository)
    demo/                ← données fictives (marché, production, climat, sources, alertes, …)
  animations/     plante de café (CustomPainter piloté par le scroll), flux de la chaîne, convergence des données
  widgets/        cartes, graphiques personnalisés (ligne, barres, radar, jauge), carte de l'Afrique
  features/       une page par section + shell responsive (barre latérale / rail / navigation mobile)
```

### Brancher une vraie API plus tard
`lib/data/repository.dart` définit `CoffeeRepository`. Il suffit d'écrire une classe `ApiRepository implements CoffeeRepository`
(appels HTTP + cache) et de remplacer `const CoffeeRepository repo = DemoRepository();`. Les widgets ne changent pas.

### Traductions
Tous les textes sont dans `lib/core/i18n/strings.dart` (`clé: [fr, en]`). Utilisation : `context.tr('cle')`.

### Performance / accessibilité
- Option **Réduire les animations** (Profil & paramètres) : plus d'animation de boucle, transitions quasi instantanées.
- Aucune vidéo ni image lourde : tout est dessiné en vectoriel (CustomPainter).
- Détails réduits sur téléphone (moins de feuilles, grains de terre).

## Ce qui est réel / simulé
**Réel** : navigation, responsive, langue, thème, filtres, graphiques, carte, simulateur (calculs locaux), alertes, comparaisons, anomalies, sources, parcours du café.
**Simulé** : récupération des données externes, météo/marchés en direct, IA de l'assistant (réponses à partir des données de démo uniquement), génération PDF, notifications, authentification.

## Espace administrateur (démo front-end)
Taper **3 fois de suite sur le logo** (barre latérale, entête mobile ou accueil) ouvre la page de connexion.
Identifiants de démonstration : `admin` / `coffee2026` (vérifiés localement : aucune sécurité réelle, code visible dans le dépôt).
Pages : tableau de bord admin, toutes les données (tableaux, recherche, copie CSV), vente de données (mise en vente, prix, ventes simulées), ajout manuel et import CSV.
