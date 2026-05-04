# Ansible — Raspberry Pi opdateringsløsning

## Struktur
```
ansible-pi/
├── ansible.cfg
├── inventory.ini
└── playbooks/
    └── setup_and_update.yml
```

## Første gang (opsætning + opdatering)

```bash
# 1. Generer SSH-nøgle til updater-brugeren
ssh-keygen -t ed25519 -C "ansible-updater" -f ~/.ssh/id_ed25519_updater

# 2. Ret IP-adresser i inventory.ini til dine egne Pi'er

# 3. Kør playbooken med din normale pi-bruger
ansible-playbook playbooks/setup_and_update.yml -u pi --ask-become-pass
```

Playbooken opretter automatisk `updater`-brugeren og kører opdateringen bagefter.

## Fremtidige opdateringer

```bash
ansible-playbook playbooks/setup_and_update.yml
```

Fase 1 er idempotent — den springer roligt hen over brugeren hvis den allerede findes.

## Automatisk opdatering (valgfrit cron)

```bash
# Kør hver søndag kl. 03:00
0 3 * * 0 cd /sti/til/ansible-pi && ansible-playbook playbooks/setup_and_update.yml >> /var/log/ansible-update.log 2>&1
```
