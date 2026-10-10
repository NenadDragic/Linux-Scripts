#!/usr/bin/env python3
# Version:      1.1
# Date:         2026-10-09
# Test Run:
# Developper:  Nenad(a)dragic(.)com
#
# nas-dss-check: Sammenligner scripts i DSM's Opgavestyring (fra et .dss-udtræk)
# med scripts i git, og tjekker dem.
#
#   1. Synkronisering: Er hvert DSM-script identisk med et script i git?
#   2. Forskelle: kun de linjer, der afviger mellem git (-) og NAS'en (+).
#   3. Syntaks og lint: bash -n og shellcheck (hvis installeret) på alle DSM-scripts.
#   4. Hemmeligheder: API-nøgler, webcall-tokens, passwords og private nøgler
#      i både DSM-scripts og git. Værdierne skrives aldrig ud.
#
# v1.1 (2026-10-09): Viser forskellene som diff (slå fra med --no-diff, flere linjer omkring med --context N).
#
# Brug:
#   python3 nas-dss-check.py ~/Downloads/Dragic_20261009.dss ~/git/Devices/NAS/Synology
#   python3 nas-dss-check.py DSS GITDIR --scan ~/git/Devices         # søg hemmeligheder i hele repoet
#   python3 nas-dss-check.py DSS GITDIR --export /tmp/nas-export     # skriv DSM-scripts ud til git
#   python3 nas-dss-check.py DSS GITDIR --context 3                  # vis 3 uændrede linjer omkring hver forskel
#
# Exit 0: alt er i sync, og ingen hemmeligheder er fundet. Exit 1: noget skal ses på.
# .dss-filen pakkes kun ud i en midlertidig mappe, der slettes igen.

import argparse, base64, difflib, json, os, re, shutil, sqlite3, subprocess, sys, tarfile, tempfile

# shellcheck-fund, der er bevidste i disse scripts:
#   SC2209  MODE=find er en tekst, ikke en kommando
#   SC2054  find's komma-operator i size=(, \( -printf ... \))
SC_EXCLUDE = "SC2209,SC2054"

SECRET_PATTERNS = [
    (re.compile(r"apikey=([A-Za-z0-9]{8,})", re.I), "API-nøgle i URL"),
    (re.compile(r"cpanelwebcall/([A-Za-z0-9]{6,})"), "cPanel webcall-token"),
    (re.compile(r"sshpass\s+-p\s*(\S+)"), "password givet til sshpass med -p"),
    (re.compile(r"(?:password|passwd|pwd)\s*=\s*['\"]?([^'\"\s]{4,})", re.I), "password i klartekst"),
    (re.compile(r"(?:token|secret)\s*=\s*['\"]?([A-Za-z0-9._-]{12,})", re.I), "token/secret"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----()"), "privat nøgle"),
]


def norm(t):
    t = t.replace("\r\n", "\n").replace("\r", "\n")
    return "\n".join(l.rstrip() for l in t.strip("\n").split("\n"))


def code_only(t):
    return "\n".join(l for l in norm(t).split("\n") if l.strip() and not l.lstrip().startswith("#"))


def version(t):
    m = re.search(r"^#\s*Version:?\s*([0-9.]+)", t, re.M)
    return tuple(int(x) for x in m.group(1).split(".")) if m else (0,)


def mask_line(line):
    for rx, _ in SECRET_PATTERNS:
        line = rx.sub(lambda m: m.group(0).replace(m.group(1), m.group(1)[:3] + "…[skjult]") if m.group(1) else m.group(0), line)
    return line.strip()[:140]


def mask_text(line):
    for rx, _ in SECRET_PATTERNS:
        line = rx.sub(lambda m: m.group(0).replace(m.group(1), m.group(1)[:3] + "…[skjult]") if m.group(1) else m.group(0), line)
    return line


def show_diff(old, new, oldname, newname, context, color):
    lines = list(difflib.unified_diff(norm(old).split("\n"), norm(new).split("\n"),
                                      fromfile=oldname, tofile=newname, n=context, lineterm=""))
    for l in lines:
        l = mask_text(l)
        if color:
            if l.startswith(("---", "+++")):
                l = f"\033[1m{l}\033[0m"
            elif l.startswith("@@"):
                l = f"\033[36m{l}\033[0m"
            elif l.startswith("-"):
                l = f"\033[31m{l}\033[0m"
            elif l.startswith("+"):
                l = f"\033[32m{l}\033[0m"
        print("   " + l)


def scan_secrets(label, text):
    hits = []
    for n, line in enumerate(text.splitlines(), 1):
        # Udkommenterede linjer tælles med: en værdi i en kommentar er lige så synlig i git.
        for rx, what in SECRET_PATTERNS:
            if rx.search(line):
                hits.append(f"  {label}:{n}: {what}: {mask_line(line)}")
                break
    return hits


def read_tasks(dss, tmp):
    with tarfile.open(dss, "r:*") as tar:
        member = next((m for m in tar.getmembers() if m.name.endswith("_Syno_ConfBkp.db")), None)
        if member is None:
            sys.exit("FEJL: _Syno_ConfBkp.db findes ikke i udtrækket")
        dbpath = os.path.join(tmp, "conf.db")
        with tar.extractfile(member) as src, open(dbpath, "wb") as dst:
            shutil.copyfileobj(src, dst)
    con = sqlite3.connect(dbpath)
    users = {str(uid): name for name, uid in con.execute("select name, uid from confbkp_user_tb")}
    users["0"] = "root"

    def dv(v):
        try:
            return json.loads(v)
        except Exception:
            return v

    tasks = []
    for tid, js in con.execute("select id, json_config from confbkp_scheduler_table"):
        d = {k: dv(v) for k, v in json.loads(js).items()}
        cmd = d.get("cmd", "") or ""
        try:
            cmd = base64.b64decode(cmd, validate=True).decode("utf-8")
        except Exception:
            pass
        owner = str(d.get("owner", ""))
        tasks.append({
            "id": int(tid), "name": str(d.get("name", "")).strip(), "state": d.get("state"),
            "owner": users.get(owner, owner), "type": d.get("type"), "week": d.get("week"),
            "time": f"{int(d.get('run hour', 0)):02d}:{int(d.get('run min', 0)):02d}",
            "builtin": d.get("app") != "SYNO.SDS.TaskScheduler.Script", "script": cmd,
        })
    con.close()
    return sorted(tasks, key=lambda t: t["id"])


def when(t):
    days = "søn man tir ons tor fre lør".split()
    w = t["week"] or ""
    if t["type"] == "weekly" and w.count("1") == 1:
        return f"{days[w.index('1')]} {t['time']}"
    return {"daily": f"dagligt {t['time']}", "once": "én gang"}.get(t["type"], f"{t['type']} {t['time']}")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("dss")
    ap.add_argument("gitdir")
    ap.add_argument("--export", metavar="DIR", help="skriv DSM-scripts ud som '<opgavenavn>.sh'")
    ap.add_argument("--no-shellcheck", action="store_true")
    ap.add_argument("--no-diff", action="store_true", help="vis ikke forskellene")
    ap.add_argument("--context", metavar="N", type=int, default=0,
                    help="antal uændrede linjer omkring hver forskel (standard 0)")
    ap.add_argument("--scan", metavar="DIR", action="append", default=[],
                    help="søg også efter hemmeligheder i DIR (fx hele repoet ~/git/Devices); kan gentages")
    a = ap.parse_args()
    problems = 0

    git = {}
    for root, _, files in os.walk(a.gitdir):
        if "/.git" in root:
            continue
        for f in files:
            p = os.path.join(root, f)
            if f.endswith((".sh", ".md", ".txt")):
                git[os.path.relpath(p, a.gitdir)] = open(p, encoding="utf-8", errors="replace").read()
    gitsh = {k: v for k, v in git.items() if k.endswith(".sh")}

    with tempfile.TemporaryDirectory() as tmp:
        tasks = read_tasks(a.dss, tmp)

        print(f"== 1. DSM-opgaver ({len(tasks)}) mod git ({len(gitsh)} scripts i {a.gitdir})")
        used = set()
        pairs = []   # (opgave, git-fil) for alle, der ikke er identiske
        for t in tasks:
            head = f"{t['id']:>3} {t['name'][:34]:34} {('aktiv' if t['state'] == 'enabled' else 'fra'):5} {t['owner'][:13]:13} {when(t):13}"
            if t["builtin"]:
                print(f"{head} indbygget DSM-opgave, intet script")
                continue
            exact = [k for k, v in gitsh.items() if norm(v) == norm(t["script"])]
            if exact:
                used.update(exact)
                print(f"{head} IDENTISK med {exact[0]}")
                continue
            same_code = [k for k, v in gitsh.items() if code_only(v) == code_only(t["script"])]
            if same_code:
                used.update(same_code)
                pairs.append((t, same_code[0]))
                print(f"{head} samme kode som {same_code[0]} (kun kommentarer afviger)")
                continue
            named = [k for k in gitsh if os.path.splitext(os.path.basename(k))[0] == t["name"] and not k.startswith("Old/")]
            best = sorted(((difflib.SequenceMatcher(None, norm(t["script"]), norm(v)).ratio(), k) for k, v in gitsh.items()), reverse=True)
            cand = named[0] if named else (best[0][1] if best and best[0][0] >= 0.6 else None)
            problems += 1
            if cand:
                used.add(cand)
                pairs.append((t, cand))
                r = difflib.SequenceMatcher(None, norm(t["script"]), norm(gitsh[cand])).ratio()
                vt, vg = version(t["script"]), version(gitsh[cand])
                newer = "DSM er nyere" if vt > vg else ("git er nyere" if vg > vt else "samme version")
                print(f"{head} AFVIGER fra {cand} ({r:.0%} ens, v{'.'.join(map(str, vt))} mod v{'.'.join(map(str, vg))}, {newer})")
            else:
                print(f"{head} MANGLER i git")
        rest = sorted(k for k in set(gitsh) - used if not k.startswith("Old/"))
        if rest:
            print("\n   I git, men ikke i nogen DSM-opgave (flyt til Old/?):")
            for k in rest:
                print(f"     {k}")

        if not a.no_diff:
            color = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
            print("\n== 2. Forskelle (- kun i git, + kun på NAS'en)")
            if not pairs:
                print("   Ingen.")
            for t, k in pairs:
                print(f"\n   Opgave {t['id']} {t['name']}  <->  git {k}")
                show_diff(gitsh[k], t["script"], f"git/{k}", f"NAS/opgave {t['id']}", a.context, color)

        print("\n== 3. Syntaks (bash -n) og shellcheck")
        has_sc = shutil.which("shellcheck") and not a.no_shellcheck
        for t in tasks:
            if t["builtin"]:
                continue
            p = os.path.join(tmp, f"{t['id']}.sh")
            open(p, "w").write(t["script"])
            r = subprocess.run(["bash", "-n", p], capture_output=True, text=True)
            syn = "OK" if r.returncode == 0 else "FEJL: " + r.stderr.strip().replace(p, "")
            sc = ""
            if has_sc:
                s = subprocess.run(["shellcheck", "-s", "bash", "-S", "warning", "-e", SC_EXCLUDE, "-f", "gcc", p],
                                   capture_output=True, text=True)
                lines = [l.replace(p + ":", "linje ") for l in s.stdout.splitlines()]
                sc = "shellcheck OK" if not lines else f"shellcheck {len(lines)} fund: " + "; ".join(lines[:3])
                problems += bool(lines)
            problems += r.returncode != 0
            print(f"{t['id']:>3} {t['name'][:34]:34} bash -n {syn}  {sc}")
        if not has_sc:
            print("   (shellcheck er ikke installeret: sudo apt install shellcheck)")

        print("\n== 4. Hemmeligheder (værdier er skjult)")
        hits = []
        for t in tasks:
            hits += scan_secrets(f"DSM opgave {t['id']} {t['name']}", t["script"])
        seen = set()
        for base in [a.gitdir] + a.scan:
            for root, dirs, files in os.walk(base):
                dirs[:] = [d for d in dirs if d != ".git"]
                for f in files:
                    p = os.path.realpath(os.path.join(root, f))
                    if p in seen or not f.endswith((".sh", ".md", ".txt", ".conf", ".py", ".yml", ".yaml", ".json")):
                        continue
                    seen.add(p)
                    v = open(p, encoding="utf-8", errors="replace").read()
                    hits += scan_secrets(f"git {os.path.relpath(p, os.path.realpath(base))}", v)
        print("\n".join(hits) if hits else "   Ingen fundet.")
        problems += len(hits)

        if a.export:
            os.makedirs(a.export, exist_ok=True)
            pick = {}
            for t in tasks:
                if t["builtin"]:
                    continue
                key = (version(t["script"]), t["state"] == "enabled", t["id"])
                if t["name"] not in pick or key > pick[t["name"]][0]:
                    pick[t["name"]] = (key, t)
            print(f"\n== Eksport til {a.export}")
            for name, (_, t) in sorted(pick.items()):
                if scan_secrets("", t["script"]):
                    print(f"   SPRUNGET OVER (indeholder en hemmelighed): {name}")
                    continue
                fn = os.path.join(a.export, re.sub(r"[/\\]", "-", name) + ".sh")
                s = t["script"] if t["script"].endswith("\n") else t["script"] + "\n"
                open(fn, "w", newline="\n").write(s)
                print(f"   {os.path.basename(fn)}  (opgave {t['id']}, v{'.'.join(map(str, version(s)))})")
            skipped = [t for t in tasks if not t["builtin"] and pick[t["name"]][1] is not t]
            for t in skipped:
                print(f"   ikke eksporteret: opgave {t['id']} {t['name']} (ældre udgave af samme navn)")

    print(f"\nResultat: {'alt i orden' if problems == 0 else f'{problems} punkt(er) skal ses på'}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
