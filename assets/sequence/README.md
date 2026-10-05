# Séquence cinématographique (scroll = caméra)

Déposez ici les images de la scène « naissance du café » et un `manifest.json`.
Tant que `manifest.json` est absent, l'application utilise l'animation vectorielle de secours.

## Format
- Fichiers à plat dans ce dossier : `f_0001.webp`, `f_0002.webp`, … (numérotation continue, 4 chiffres).
- 16:9, 1280×720 (WebP qualité ~70 → ~30–60 Ko/image). 120 à 240 images suffisent (le lecteur fond entre images voisines).
- Une seule séquence continue couvre toute l'histoire de la plante (graine → données).

## manifest.json
```json
{
  "pattern": "assets/sequence/f_%04d.webp",
  "frames": 180,
  "aspect": 1.7778,
  "chapters": [0.00, 0.05, 0.12, 0.25, 0.34, 0.42, 0.48, 0.58, 0.68, 0.74, 0.80, 0.86, 0.94]
}
```
`chapters` = position (0..1 dans la séquence) du début de chacune des 13 étapes, pour synchroniser les légendes.
Pour que légendes et images coïncident, générez les clips dans l'ordre des 13 étapes et indiquez à quelle fraction commence chacune.

## Extraire des images depuis une vidéo (ffmpeg)
```
ffmpeg -i naissance.mp4 -vf "fps=24,scale=1280:-2" -c:v libwebp -quality 70 f_%04d.webp
```
Pour tenir 180 images : ajustez `fps` (ex. `fps=180/durée_en_secondes`).

## Plan de tournage / prompts (macro, lumière naturelle, profondeur de champ, 16:9)
1. Graine : gros plan extrême, terre humide sombre, graine de café texturée, particules, lumière rasante.
2. Germination : la graine se fissure, radicule organique qui s'allonge et se ramifie, gouttes, terre qui bouge.
3. Tige : la caméra remonte, la tige soulève la terre, lumière qui s'éclaircit.
4. Premières feuilles : feuilles qui se déplient, nervures, léger vent.
5. Croissance : la caméra recule, plante entière, arrière-plan flou, poussières en suspension.
6. Floraison : bourgeons qui s'ouvrent, fleurs blanches sur les branches.
7. Cerises : fleurs → cerises vertes puis jaune/orange puis rouge profond, travelling macro.
8. Ouverture : la peau de la cerise s'ouvre, pulpe, parchemin, grain.
9. Grain : rotation lente, relief, texture, puis plusieurs grains.
10. Torréfaction : vert → jaune → brun clair → brun profond, vapeur, lumière chaude.
11. Données : particules lumineuses émergeant du grain réel, qui forment des lignes élégantes (pas d'effet Matrix).
Terminez sur un grain sombre propre : l'interface prend le relais.
