# Git – Sammenlign lokal repo mod GitHub

## 1. Hent seneste info fra remote (uden at merge)
```bash
git fetch origin
```
Opdaterer din lokale viden om remote uden at ændre dine filer.

---

## 2. Se commits der er på GitHub men ikke lokalt
```bash
git log HEAD..origin/main --oneline
```

## 3. Se commits der er lokalt men ikke på GitHub
```bash
git log origin/main..HEAD --oneline
```

## 4. Se begge veje på én gang
```bash
git log --oneline --left-right HEAD...origin/main
```
- `<` = kun lokalt
- `>` = kun på GitHub

---

## 5. Se faktiske filforskelle (diff)
```bash
# Fuldt diff af filindhold
git diff origin/main

# Kun hvilke filer der er ændret (ikke hele diff)
git diff --stat origin/main
```

---

## 6. Hurtig status – er du foran/bagud?
```bash
git status
```
Eksempel output: `Your branch is ahead of 'origin/main' by 2 commits`

---

## Typisk workflow
```bash
git fetch origin                                    # Hent remote-info
git status                                          # Hurtig oversigt
git log HEAD...origin/main --oneline --left-right   # Detaljeret commit-forskel
git diff origin/main                                # Filindhold-forskel
```

---

## Nyttige flag
| Flag | Beskrivelse |
|------|-------------|
| `--oneline` | Kompakt visning – én linje pr. commit |
| `--left-right` | Viser `<` (lokal) og `>` (remote) retning |
| `--stat` | Viser kun filnavne og antal ændrede linjer |
| `--name-only` | Viser kun filnavne i diff |
| `--graph` | Tegner branch-graf i terminalen |

---

## Skift `main` ud hvis din branch hedder noget andet
```bash
git fetch origin
git log HEAD...origin/master --oneline --left-right   # ældre repos
git log HEAD...origin/dev --oneline --left-right      # feature-branch
```
