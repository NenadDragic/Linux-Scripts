# tmux-rotate.sh

Roterer en tilknyttet tmux-klient mellem udvalgte sessioner med et fast interval. Det er tænkt til en passiv dashboard- eller monitoreringsskærm.

tmux har ingen indbygget timer til at skifte session. Scriptet kalder derfor `tmux switch-client` i en løkke.

## Krav

- bash 4+ (bruger `mapfile`)
- tmux (testet med 3.4)
- Dependency-tjek: scriptet starter med at source den delte `lib/require_tools.sh` (findes ved at gå op fra scriptets egen mappe) og stopper med et `apt install`-forslag, hvis `tmux` mangler
- Mindst én klient tilknyttet tmux, dvs. en terminal hvor `tmux attach` kører

## Installation

```bash
sudo install -m 755 tmux-rotate.sh /usr/local/bin/tmux-rotate
# eller kun for din bruger:
install -m 755 tmux-rotate.sh ~/.local/bin/tmux-rotate
```

## Brug

### Interaktivt

```bash
tmux-rotate.sh
```

Scriptet:

1. Viser alle aktive sessioner nummereret, med antal vinduer, og om de er tilknyttet.
2. Spørger hvilke der skal indgå. Gyldige svar:
   - `1 3 4` eller `1,3,4`: enkelte numre
   - `1-3`: et interval
   - `1-2 5`: blandet
   - `a` eller `alle`: alle sessioner
   
   Rækkefølgen du angiver, er rækkefølgen der roteres i. Dubletter ignoreres.
3. Spørger om antal sekunder mellem skift (heltal ≥ 1, standard 10).
4. Er flere klienter tilknyttet, spørger det hvilken skærm der skal rotere. Er der kun én, vælges den automatisk.

Eksempel:

```
Aktive tmux-sessioner:
   1) logs  (2 vinduer)
   2) monitor  (1 vinduer)
   3) prod  (3 vinduer, tilknyttet)

Vælg sessioner (fx '1 3 4', '1-3' eller 'a' for alle): 3 2
Sekunder mellem skift [10]: 15

Roterer klient /dev/pts/3 mellem: prod monitor
Interval: 15s. Stop med Ctrl-C.
```

### Ikke-interaktivt

Til systemd, cron, autostart eller SSH-oneliners:

```bash
tmux-rotate.sh -s prod,monitor,logs -i 15
tmux-rotate.sh -s prod,monitor -i 30 -c /dev/pts/3
```

Flag kan blandes med menuen. Angiver du fx kun `-i 20`, spørges der stadig om sessioner og klient.

| Flag | Betydning |
| --- | --- |
| `-s` | Kommasepareret liste af sessionsnavne. Springer menuen over |
| `-i` | Sekunder mellem skift |
| `-c` | Klient der skal rotere (fx `/dev/pts/3`) |
| `-l` | Vis sessioner og klienter, og afslut |
| `-h` | Hjælp |

### Stop

Tryk `Ctrl-C` i den terminal, hvor scriptet kører. Fra et andet sted:

```bash
pkill -f tmux-rotate
```

Scriptet stopper også af sig selv, når:

- klienten detacher, eller
- ingen af de valgte sessioner findes længere.

En valgt session, der lukkes undervejs, springes over i resten af rotationen.

## Hvor skal scriptet køre?

**Anbefalet:** i en anden terminal eller via SSH, ikke i den klient, der roteres. Så kan du stoppe det med Ctrl-C, uanset hvilken session skærmen viser.

Kører du det i en pane i én af de roterede sessioner, virker det, men når skærmen skifter væk, kan du ikke nå Ctrl-C. Scriptet advarer om det og foreslår `pkill`.

## Vigtigt: detach-on-destroy

tmux står som standard på `detach-on-destroy on`. Lukker du den session, klienten viser lige nu, bliver klienten detached, og rotationen stopper. Scriptet viser et tip om dette ved start.

Hvis sessioner kan blive lukket, mens rotationen kører, så sæt:

```bash
tmux set -g detach-on-destroy off        # gælder nu
echo 'set -g detach-on-destroy off' >> ~/.tmux.conf   # permanent
```

Så skifter tmux klienten til en anden session i stedet for at detache, og scriptet fortsætter med de resterende.

## Begrænsninger og risici

- **Ikke til interaktivt arbejde.** Skiftet sker også midt i det, du taster. Brug en separat klient (terminal) til dashboardet.
- **Klientnavne er ikke stabile.** `/dev/pts/3` kan få et andet nummer efter genstart eller reattach. I automatisering er det mere robust at udelade `-c`, når der kun er én klient.
- **Sessioner, ikke vinduer.** Har du én session med flere vinduer, er `tmux next-window -t <session>` i en løkke ofte enklere. Det kræver ikke valg af klient.
- **Nye sessioner opdages ikke.** Listen ligger fast ved start. Genstart scriptet for at medtage nye.
- **Timing.** `sleep` er ikke præcis. Over lang tid driver rotationen et par sekunder, hvilket er uden betydning for et dashboard.

## Eksempel: start automatisk som systemd-brugertjeneste

`~/.config/systemd/user/tmux-rotate.service`:

```ini
[Unit]
Description=Roter tmux-dashboard

[Service]
ExecStart=%h/.local/bin/tmux-rotate -s prod,monitor,logs -i 20
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now tmux-rotate
```

Tjenesten fejler og genstartes, indtil en klient er tilknyttet. `Restart=on-failure` håndterer det. Bemærk at scriptet afslutter med kode 0, når klienten detacher, så tjenesten genstarter ikke i det tilfælde. Brug `Restart=always`, hvis den skal.
