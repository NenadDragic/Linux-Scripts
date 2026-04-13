# MoveDocToArchive.sh — Eksempler på brug

## Scenarie 1: Fotos fra 2008 → arkivmappe (samme disk)

**Situation:** Du har et rod af fotos i `~/Billeder` og vil flytte alle 2008-fotos til et arkiv.

Ret stier i scriptet:
```bash
fra_folder="/home/nenad/Billeder"
til_folder="/home/nenad/Billeder/Arkiv/2008"
```

Preview:
```bash
./MoveDocToArchive.sh find
```
```
Følgende filer matcher mønsteret:
/home/nenad/Billeder/foto_2008-07-14.jpg
/home/nenad/Billeder/ferie_2008-12-24.jpg
/home/nenad/Billeder/DSC_2008-03-01.jpg
```

Dryrun:
```bash
./MoveDocToArchive.sh dryrun
```
```
[DRYRUN] Samme filsystem — checksum ville blive sprunget over.

Følgende handlinger ville blive udført:
---
  → FLYTTES: foto_2008-07-14.jpg
       Fra: /home/nenad/Billeder/foto_2008-07-14.jpg
       Til: /home/nenad/Billeder/Arkiv/2008/foto_2008-07-14.jpg
  → FLYTTES: ferie_2008-12-24.jpg
       Fra: /home/nenad/Billeder/ferie_2008-12-24.jpg
       Til: /home/nenad/Billeder/Arkiv/2008/ferie_2008-12-24.jpg
  → FLYTTES: DSC_2008-03-01.jpg
       Fra: /home/nenad/Billeder/DSC_2008-03-01.jpg
       Til: /home/nenad/Billeder/Arkiv/2008/DSC_2008-03-01.jpg
---
Opsummering: 3 ville blive flyttet, 0 ville blive sprunget over.
[DRYRUN] Ingen filer blev rørt.
```

Udfør flytning:
```bash
./MoveDocToArchive.sh run
```
```
Flytning gennemført:
  ✔ Flyttet:          3
  ✘ mv-fejl:          0
  ✘ Checksum-fejl:    0
  ⊘ Sprunget over:    0

Log gemt i: /home/nenad/Billeder/Arkiv/2008/flyttede_filer_20260413_143022.log
```

Log-indhold (samme filsystem — ingen checksum):
```
Start flytning: Mon Apr 13 14:30:22 2026
Filsystem: kilde og mål er ens — checksum-validering sprunget over.
---
Flyttet: foto_2008-07-14.jpg
Flyttet: ferie_2008-12-24.jpg
Flyttet: DSC_2008-03-01.jpg
---
Resultat: 3 OK, 0 mv-fejl, 0 checksum-fejl, 0 sprunget over.
Færdig: Mon Apr 13 14:30:22 2026
```

---

## Scenarie 2: Dokumenter → NAS/ekstern disk (forskelligt filsystem)

**Situation:** Du vil flytte 2008-dokumenter fra din lokale disk til en NAS-mount.

Ret stier i scriptet:
```bash
fra_folder="/home/nenad/Dokumenter"
til_folder="/mnt/nas/Arkiv/2008"
```

Dryrun:
```bash
./MoveDocToArchive.sh dryrun
```
```
[DRYRUN] Forskellige filsystemer — checksum ville blive aktiveret.

Følgende handlinger ville blive udført:
---
  → FLYTTES: rapport_2008-03-01.pdf
       Fra: /home/nenad/Dokumenter/rapport_2008-03-01.pdf
       Til: /mnt/nas/Arkiv/2008/rapport_2008-03-01.pdf
  → FLYTTES: budget_2008-11-15.xlsx
       Fra: /home/nenad/Dokumenter/budget_2008-11-15.xlsx
       Til: /mnt/nas/Arkiv/2008/budget_2008-11-15.xlsx
---
Opsummering: 2 ville blive flyttet, 0 ville blive sprunget over.
[DRYRUN] Ingen filer blev rørt.
```

Udfør flytning:
```bash
./MoveDocToArchive.sh run
```
```
Flytning gennemført:
  ✔ Flyttet:          2
  ✘ mv-fejl:          0
  ✘ Checksum-fejl:    0
  ⊘ Sprunget over:    0

Log gemt i: /mnt/nas/Arkiv/2008/flyttede_filer_20260413_144500.log
```

Log-indhold (forskelligt filsystem — checksum aktiveret):
```
Start flytning: Mon Apr 13 14:45:00 2026
Filsystem: kilde og mål er forskellige — checksum-validering aktiveret.
---
OK:            rapport_2008-03-01.pdf  [a3f1c2d4e5b6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2]
OK:            budget_2008-11-15.xlsx  [9b8e7f6a5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8]
---
Resultat: 2 OK, 0 mv-fejl, 0 checksum-fejl, 0 sprunget over.
Færdig: Mon Apr 13 14:45:02 2026
```

---

## Scenarie 3: Fil findes allerede i målet

**Situation:** Du kører scriptet to gange — anden gang eksisterer filerne allerede.

Dryrun viser hvad der ville ske:
```bash
./MoveDocToArchive.sh dryrun
```
```
[DRYRUN] Forskellige filsystemer — checksum ville blive aktiveret.

Følgende handlinger ville blive udført:
---
  ⊘ SPRING OVER (findes allerede): foto_2008-07-14.jpg
  ⊘ SPRING OVER (findes allerede): ferie_2008-12-24.jpg
  ⊘ SPRING OVER (findes allerede): DSC_2008-03-01.jpg
---
Opsummering: 0 ville blive flyttet, 3 ville blive sprunget over.
[DRYRUN] Ingen filer blev rørt.
```

---

## Scenarie 4: Ingen filer matcher

**Situation:** Der er ingen filer med 2008-dato i kildemappen.

```bash
./MoveDocToArchive.sh find
```
```
Ingen filer matcher mønsteret.
```

```bash
./MoveDocToArchive.sh dryrun
```
```
Ingen filer matcher mønsteret.
```

---

## Scenarie 5: Kildemappen findes ikke

**Situation:** Stien er forkert eller disken er ikke mountet.

```bash
./MoveDocToArchive.sh run
```
```
Fejl: Kildemappen findes ikke: /home/nenad/Dokumenter
```

---

## Hurtig reference

| Kommando                    | Hvad sker der                                          |
|-----------------------------|--------------------------------------------------------|
| `./MoveDocToArchive.sh find`      | Vis matchende filer — intet flyttes                    |
| `./MoveDocToArchive.sh dryrun`    | Simuler hele forløbet — vis hvad der ville ske         |
| `./MoveDocToArchive.sh run`       | Flyt filer og gem log                                  |
| `./MoveDocToArchive.sh`           | Printer hjælpetekst og afslutter                       |

### Anbefalet arbejdsgang

```
find → dryrun → run
```

`find` giver et hurtigt overblik, `dryrun` bekræfter præcist hvad der sker inkl. spring-over og checksum-valg, og `run` udfører det.
