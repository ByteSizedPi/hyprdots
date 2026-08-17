# Homelab — hardware inventory, drive states & migration plan

Living record for the two-machine homelab: the existing **jjserver** (Fedora +
Docker) and the incoming **Dell PowerEdge R720xd** (to become the primary
Proxmox node). Keep the drive tables and the migration checklist current — this
is the "what do I actually have and what state is it in" reference.

Last surveyed: **2026-07-13** (drive SMART pulled live from jjserver's Scrutiny).

---

## 1. Roles (decided)

| Machine | Role | Why |
|---|---|---|
| **R720xd** | **Primary** — Proxmox host: all VMs/LXCs + primary storage (photos, configs, media) | 2× Xeon E5-2670 (16c/32t), 128 GB ECC — massively outclasses the i5 |
| **jjserver** (i5-2500) | **Backup / secondary node** — holds the aging RAID5 as an on-site backup target + cold spare | 3.5" drives can't move to the 2.5" R720xd; old array is perfect as a backup destination |

Decisions taken (2026-07-13):
- **Compute:** R720xd primary, keep i5 jjserver as backup. *Migrate service-by-
  service, keep jjserver live until the R720xd is proven, then demote it.*
- **Storage priority:** the only irreplaceable data is **photos** (Immich, one-
  time import + slow future growth) and **configs not already in git**. Movies/
  series are ephemeral (deleted after watching) — no redundancy needed for them.
- **Old drives:** keep the 6×500 GB RAID5 running on jjserver until drives
  physically fail; it becomes the backup array, not primary.
- **Transcoding:** CPU-only to start (16c/32t + existing Tdarr pre-transcode).
  GPU is a future option (E5-2670 has no Quick Sync).
- **No immediate hardware purchases** — build with what's on hand, expandable.

---

## 2. R720xd — the incoming primary

Claimed spec (verify on first boot with `~/verify_poweredger.sh` /
`~/poweredge_checks.sh`, already staged on jjserver):

| Item | Claimed | Notes |
|---|---|---|
| Model | Dell PowerEdge **R720xd** | 2.5" chassis: **24 front + 2 rear bays** |
| CPU | 2× Xeon **E5-2670** | 8c/16t each = **16c/32t**. Sandy Bridge-EP, **no iGPU / no Quick Sync** |
| RAM | **128 GB** ECC (4× 32 GB) | Registered DDR3 ECC; loads of headroom |
| RAID card | **PERC H710 / H710P Mini** | LSI SAS2208. **Hardware-RAID only — no JBOD/passthrough.** See §4 |
| Drives | 2× ~1.8 TB (2.5") | The two that came with it |
| Mgmt | iDRAC | Set an iDRAC IP early → remote console on a headless box |

> **Chassis constraint:** 2.5" bays. Large 2.5" HDDs top out ~2 TB (bigger ones
> are rare/SMR/slow). Bulk capacity growth = 2.5" SSDs (pricey/TB, ideal for
> photos) or 2 TB-class 2.5" HDDs. Don't plan on cheap 8 TB+ 3.5" drives here.

---

## 3. jjserver — current state (backup node)

- **CPU/RAM:** Intel i5-2500 (4c/4t, 2011), 26 GB RAM.
- **OS drive:** `sdg` ADATA SU650 480 GB SSD (2.5") → `/` + `/boot/efi`.
- **Array:** `md0`, **mdadm RAID5**, 6× 500 GB → **2.3 TB usable, 43 % used**
  (`/mnt/raid5`).
- **Services:** ~40 Docker containers — arr stack, Immich, Jellyfin, Plex,
  AdGuard, Authelia, Traefik, Firefly, Tdarr, Scrutiny, Uptime-Kuma, etc.
- **Data footprint (what must migrate):**
  - `/mnt/raid5/media` 630 G (ephemeral) · `photos` **174 G (keep!)** · `torrents`
    108 G (ephemeral) · `library` 10 G
  - `/home/jjserver/services` **310 G** — Docker appdata / DB volumes / configs
    (**keep the non-git parts!**)
  - Must-keep total ≈ **~500 G** (photos + configs); everything else is
    reacquirable.

### Drive states — surveyed 2026-07-13 (Scrutiny SMART)

RAID5 members: `sda sdb sdc sdd sdf sdh`. Seagate **attribute 195**
(Hardware_ECC_Recovered) reads alarmingly on ST drives but is *not* a reliable
failure predictor — discounted below. What matters: attr 5 (reallocated), 187
(reported-uncorrectable), 183 (runtime bad block), 197/198 (pending/offline).

| dev | model | GB | power-on | verdict | real issue |
|-----|-------|---:|---------:|---------|---|
| sda | Seagate ST3500418AS | 500 | 6,897 h | ⚠️ **degrading** | **69 reallocated sectors** (attr 5) — watch closely |
| sdb | WD WD5000AAKX | 500 | 20,463 h | ✅ healthy | clean |
| sdc | Seagate ST500DM002 | 500 | **44,817 h** | 🟡 old but ok | age + attr-195 noise; timeouts=0 |
| sdd | Seagate ST500DM002 | 500 | 11,953 h | ⚠️ **degrading** | 8 runtime bad blocks (attr 183) + 5 CRC (attr 199) |
| sdf | Seagate ST500DM009 | 500 | 13,806 h | ⚠️ **degrading** | **25 reported-uncorrectable** (attr 187) |
| sdh | Seagate ST500DM002 | 500 | 8,720 h | ✅ effectively fine | only attr-195 noise |
| sde | WD WD2500AAJS 250 GB | 250 | **68,250 h** (7.8 yr) | 🟡 ancient, unused | not in array; retire candidate |
| sdg | ADATA SU650 480 GB SSD | 480 | 26,197 h | ✅ healthy | current OS drive |

**Read:** RAID5 survives **one** disk failure. Three members (sda/sdd/sdf) show
genuine degradation, so a single-drive failure is plausible in the medium term —
fine for a *backup* array, but it means **the photos' only trustworthy home must
be the R720xd, with independent backups** (§5). If a member dies, replace it
with a healthy pulled drive or let the array run degraded until the next failure.

---

## 4. The H710 decision (gates everything on storage)

The PERC H710 Mini has **no passthrough mode**. ZFS wants raw disks. Options,
best-first:

**A. Add a cheap IT-mode HBA — recommended, ~$25-40.** Dell **HBA330**, or a
   crossflashed **H310** / **LSI 9211-8i**. Disks appear raw → clean ZFS with
   checksums, self-healing, snapshots, cheap replication. Build once, no rework.
   *This is the single highest-leverage purchase for the whole box.*

**B. Crossflash the H710 Mini itself to IT mode.** Possible (SAS2208) but fiddlier
   and riskier than an H310 — can brick the card. Only if you enjoy the yak-shave.

**C. Build now with zero purchases — H710 hardware RAID1 + ext4/LVM-thin.**
   Create a RAID1 across the 2×1.8 TB on the PERC; install Proxmox on the single
   virtual disk with the default ext4/LVM-thin. Robust, uses the BBU write cache,
   dead simple. **Trade-off:** no ZFS checksumming/self-heal/snapshots, so
   **backups do all the protecting** (§5). Easy to migrate to ZFS later once an
   HBA arrives.

> Avoid the "per-disk RAID0 + ZFS" hack: it works, but the RAID0 wrapper's
> metadata means the pool won't cleanly import when you later swap to a real HBA
> → forced rebuild. Either do ZFS properly (A/B) or ext4 on hardware RAID (C).

**Plan:** build on **C** now if buying nothing; switch to **A** (ZFS mirror) the
moment a $30 HBA lands. If willing to spend $30 up front, go **A** from day one.

---

## 5. Target storage & backup architecture

### Pools (ZFS path, after HBA / option A)
- **`rpool`** — ZFS **mirror** across the 2×1.8 TB (your original instinct was
  right: OS + data share the mirror, nothing "wasted" on a dedicated OS disk).
  - Proxmox root + VM/LXC disks
  - `rpool/data/photos` — Immich library (the crown jewels)
  - `rpool/data/configs` — Docker appdata / DB volumes
  - `rpool/data/media` — ephemeral movies/series (fine here; ~630 G today, and
    the 1.8 TB mirror comfortably holds photos+configs+media for now)
  - Enable **lz4 compression** (default; free win on DBs/configs), `ashift=12`.

### 3-2-1 backup (this is what actually protects the photos)
1. **Copy 1 — live:** R720xd `rpool` mirror (or PERC RAID1 under option C).
2. **Copy 2 — on-site:** replicate `photos` + `configs` to **jjserver's RAID5**.
   - ZFS path: `zfs send | ssh jjserver` (or Proxmox Backup Server on jjserver).
   - ext4 path: nightly `restic`/`rsync` to `/mnt/raid5/backups`.
3. **Copy 3 — off-site:** photos are irreplaceable → **one off-site copy**
   (Backblaze B2 / rclone-crypt, or a USB HDD kept elsewhere and rotated).
   *Cheapest, highest-impact item in the whole project — do this even before
   any drive purchase.*

RAID/mirror is **not** a backup — it only covers a drive dying, not deletion,
corruption, ransomware, or the box catching fire.

---

## 6-GitOps. Fresh-start service architecture (decided 2026-07-14)

Supersedes the "rsync the existing compose stack as-is" idea in §6.6. Decision:
**fresh build, GitOps-managed** — the source of truth is a git repo, the server
just runs what git says. Grounded in current homelab community consensus
(hybrid LXC-for-infra + Docker-in-VM; Komodo for git-backed compose deploys;
skip Kubernetes at single-node scale).

### Abstraction placement (what runs where, and why)
- **LXC — always-on infra with no storage coupling:** DNS/adblock (AdGuard),
  Tailscale subnet router. Tiny, must stay up independent of the app VM.
- **VM — the Docker application stack:** one Debian 13 VM running Docker +
  Komodo + all app compose stacks. Docker-in-VM (not Docker-in-LXC): Proxmox
  doesn't officially support nested Docker-in-LXC and it can break on major
  upgrades; the ~5-15% VM overhead is irrelevant on 16c/128 GB. Clean snapshots
  + upgrade path.
- **No Kubernetes.** Compose + Komodo gives the dev→prod promotion pipeline
  without etcd/ingress overhead. k3s only ever as a learning toy.
- **Dev/prod:** start with ONE prod VM + git as source of truth (nothing
  changes except through a git push). Add a snapshot-able dev VM later *only*
  if wanting a fearless test sandbox — cheap on the RAM budget.

### Jellyfin placement — revised
arr↔Jellyfin coupling is the **shared media filesystem**, NOT a Docker network
(arr apps file media into `/media`; Jellyfin reads it; only optional API calls
like Jellyseerr→Sonarr are network, and those cross hosts fine over IP).
→ **Start with Jellyfin INSIDE the app VM**, sharing the local `/media` volume
with the arr stack (simplest, mirrors jjserver). Split it into its own
GPU-accelerated LXC + NFS shared storage **only when** the transcode GPU is
bought and/or jjserver becomes an NFS NAS. With git+Komodo that's "edit a
volume path + make an LXC", not a rebuild — so no premature NFS tax now.

### Cross-stack Docker networking (Komodo = several small stacks, not one file)
- `docker network create proxy` once — one **external** network.
- Each stack keeps a private default net for internal-only services (DBs,
  download clients). Web-facing containers additionally join `proxy` so Traefik
  and cross-stack callers resolve them by name. Same model as the current
  single shared network, just made explicit per stack.

### Repo structure — new **private** repo `homelab-stacks` (NOT in dotfiles)
```
homelab-stacks/
├── stacks/
│   ├── proxy/      compose.yaml   # Traefik
│   ├── arr/        compose.yaml   # prowlarr sonarr radarr bazarr qbittorrent…
│   ├── media/      compose.yaml   # jellyfin jellyseerr tdarr
│   ├── immich/     compose.yaml   # immich + own postgres/redis
│   └── monitoring/ compose.yaml   # uptime-kuma scrutiny (later)
├── .env.example                   # documents required vars — NO real secrets
└── .gitignore                     # ignores real .env
```
Secrets live in **Komodo's variable/secret store** (`[[VAR]]` interpolation in
compose), never in git. Komodo watches the repo → deploy on push. Komodo itself
is the one hand-installed piece (its own compose: Core + Periphery + DB); it
then deploys everything else from the repo.

### Build order (each step unblocks the next)
- [x] 1. **DNS LXC** — AdGuard Home via `ct/adguard.sh` helper. Up, wizard done.
      (Blocklists/local-DNS-rewrites + jjserver config import deferred to cutover.)
- [x] 2. **App VM** — Debian 13 cloud image → **template VM 9000** (`debian13-tmpl`),
      full-cloned to **VM 110 `app-prod`** (8c/24 GB). Cloud-init planted user `jj`
      + laptop ed25519 SSH key; reachable key-only from the laptop. Docker CE +
      compose plugin (official repo) installed. *Dev VM later = clone 9000.*
- [x] 3. **Komodo** hand-installed on VM 110 (`~/komodo/`, Mongo variant:
      Mongo + Core + Periphery). UI on **:9120**, local admin auth. `compose.env`
      holds secrets → **stays on the VM, NOT in git**. Newer Komodo auto-negotiates
      Core↔Periphery keys (no manual passkey). Periphery root dir = `/etc/komodo`
      (where git-cloned stacks will live).
- [~] 4. **`proxy` net + Traefik** — `docker network create proxy` **done**;
      Traefik stack pending.
- [ ] 5. **arr** stack (local `/media` volume).
- [ ] 6. **media** stack (Jellyfin + Tdarr pre-transcode + Jellyseerr, same VM).
- [ ] 7. **immich** stack → migrate the 174 G photos from jjserver, verify.
- [ ] 8. **Backups (3-2-1)** — photos+appdata → jjserver RAID5 + one off-site
      (§5). Highest-value step; do not let it slip.
- [ ] 9. Later (no rework): GPU → Jellyfin LXC + NFS; jjserver → NAS.

> **Addressing — corrected 2026-08-16.** The `10.42.0.x` subnet is still in use,
> but it is **no longer the laptop Wi-Fi share**. A TP-Link AX1500 in the room
> is now `10.42.0.1` and serves it, uplinked by the roof cable to the Nokia on
> `10.0.0.0/24`. Verified live:
>
> | address | host |
> | --- | --- |
> | `10.42.0.1` | TP-Link AX1500 room router (SSID `jjlink`) |
> | `10.42.0.10` | pve host — Proxmox UI on `:8006` |
> | `10.42.0.11` | pve-prod |
> | `10.42.0.12` | DNS LXC (the address the router hands out as DNS) |
> | `10.42.0.13`, `10.42.0.100` | further guests, roles not re-verified |
>
> The earlier note here said AdGuard `…192`, app-prod `…205`, Komodo `…205:9120`
> and Proxmox `…50`. **All of those are stale** — the guests were renumbered.
> Nothing durable should hardcode any of them; internal wiring is name-based.
> Full topology and the fault history: `docs/problems.md` → "jjlink internet
> crawled".

---

## 6. Proxmox install decisions

1. **Resolve §4 first** — it decides the installer's disk step.
2. **ISO:** Proxmox VE 8.x. Boot via iDRAC virtual media or USB.
3. **Disk step:**
   - Option A (HBA/ZFS): choose **zfs (RAID1)** across the two 1.8 TB → `rpool`.
     Set `ashift=12`, compression `lz4`.
   - Option C (H710 RAID1): create the RAID1 in the PERC BIOS (Ctrl+R) first,
     then install onto the single virtual disk with **ext4 / LVM-thin** (default).
4. **Network:** static IP. During bootstrap it'll sit on the laptop-share subnet
   (§7); give it its real `10.0.0.x` address once it's on the main LAN.
5. **Post-install:**
   - Switch to the **no-subscription repo**, remove the enterprise repo, update.
   - Single node → ignore/disable HA & clustering nags.
   - Set up storage: ZFS datasets (A) or LVM-thin + a directory storage (C).
   - Join **Tailscale** on the host (jjserver already runs a tailnet —
     `100.68.211.32`; laptop `100.107.4.99`).
6. **Services migration — fastest path with least change:** stand up **one
   Docker-capable LXC (or a small VM)**, `rsync` `/home/jjserver/services` into
   it, and bring up the existing compose stack as-is. Cut over container groups
   one at a time; keep jjserver serving until each group is verified. Split into
   per-service LXCs later if wanted — not required to get running.
7. **Transcoding:** CPU. Jellyfin/Plex CPU transcode + keep Tdarr pre-
   transcoding the library to direct-play-friendly formats.

---

## 7. Network bootstrap — share laptop Wi-Fi to the R720xd

> **⚠️ SUPERSEDED 2026-08-16 — this is no longer how the R720xd is connected,
> and running it now BREAKS the LAN.** The R720xd sits behind a TP-Link AX1500
> at `10.42.0.1`. NetworkManager's `shared` mode also uses `10.42.0.1` and
> serves DHCP on `10.42.0.10–254`, so bringing `pe-share` up puts a **second
> gateway and a second DHCP server** on a live subnet. `pe-share` is therefore
> set `connection.autoconnect no` — see `SYSTEM.md` → NetworkManager profiles.
>
> Kept below because the recipe is still the right way to bootstrap a box that
> has **no other network at all**. Before using it, confirm nothing else owns
> `10.42.0.0/24`.

```bash
# On the laptop — find the wired interface name:
nmcli device status                     # e.g. enp0s31f6

# Create a shared (internet-sharing) connection on it:
nmcli connection add type ethernet ifname <ETH_IFACE> con-name pe-share \
      ipv4.method shared
nmcli connection up pe-share
```

- Laptop becomes `10.42.0.1`; the R720xd (NIC set to DHCP) gets `10.42.0.x` with
  internet via the laptop's Wi-Fi. Good enough for Proxmox install + updates.
- **iDRAC:** for remote console during setup, either use the R720xd's shared-LOM
  mode (iDRAC rides the same NIC) or temporarily move the cable to the iDRAC
  port. `nmap 10.42.0.0/24` or check `ip neigh` to find assigned addresses.
- If firewalld blocks forwarding, NM's shared profile normally adds the
  masquerade rule itself; if not, drop the iface into the `trusted`/ `external`
  zone.

**Long-term:** replace the laptop relay by plugging the R720xd straight into the
main `10.0.0.0/24` switch/router and give it a static `10.0.0.x`.

**Status 2026-08-16 — half done.** The laptop relay is gone; the AX1500 replaced
it. But the R720xd is still on `10.42.0.x` behind that router's NAT, not on the
main LAN. Consequence worth knowing: hosts on `10.0.0.0/24` (jjserver) cannot
open connections *into* the homelab — only Tailscale crosses that boundary.
Finishing the move means either renumbering the guests onto `10.0.0.x`, or
switching the AX1500 to Access Point mode. The Nokia is ISP-managed with no
DHCP/DNS control, which is the reason the private subnet was kept.

---

## 8. Hardware buying priorities (when budget allows)

Ordered by impact-per-dollar:

1. **Off-site backup for photos** — B2 bucket (~$6/TB/mo) or a USB HDD kept
   elsewhere. ~$0-40. *Protects the only irreplaceable data. Do first.*
2. **IT-mode HBA** (HBA330 / crossflashed H310 / LSI 9211-8i) — ~$25-40. Unlocks
   clean ZFS on the R720xd; build once instead of migrating later (§4A).
3. **UPS** — enterprise PSU + spinning disks + ZFS/BBU all hate dirty power.
   Cheap insurance against corruption on power loss.
4. **2.5" data drives** — only when photos outgrow the 1.8 TB mirror. Prefer
   2.5" **SSDs** for the photo/config pool (silent, reliable, checksummed under
   ZFS); 2 TB-class 2.5" HDDs if capacity/$ matters more. Add as **mirror pairs**.
5. **Low-profile GPU** (Nvidia P400/P1000/Quadro) — only if CPU transcode proves
   insufficient for your concurrent-stream load.

---

## 9. Migration checklist

- [ ] Boot R720xd on SystemRescue; run `verify_poweredger.sh` — confirm CPU/RAM/
      drives/iDRAC and pull SMART on the 2×1.8 TB.
- [ ] Note the exact PERC model & firmware; decide §4 path (A/B/C).
- [ ] Set an iDRAC IP + password.
- [ ] Laptop Wi-Fi relay up (§7); R720xd reaches the internet.
- [ ] Install Proxmox per §6; update; join Tailscale.
- [ ] Create pools/datasets; enable compression.
- [ ] Stand up Docker LXC/VM; `rsync` `services/` + `photos/` from jjserver.
- [ ] Bring up compose stack; verify group-by-group against jjserver.
- [ ] Wire the 3 backup copies (§5); test a **restore** of the photos.
- [ ] Cut DNS/Traefik/Tailscale over to the R720xd.
- [ ] Demote jjserver: stop migrated services, keep it as backup target + spare.
- [ ] Re-survey drive SMART; update §3 table.

---

## 10. Change log

- **2026-07-13** — Initial survey + plan. jjserver drive states captured from
  Scrutiny; R720xd specs from staged verify scripts (not yet run on the box);
  roles & storage strategy decided. Nothing built yet.
- **2026-07-14** — Proxmox VE 9 installed on the R720xd (PERC H710 RAID1 mirror
  ~1.64 TiB, ext4/LVM-thin — option C), reachable at `https://10.42.0.50:8006`,
  no-subscription repo, updated. Fresh-start GitOps architecture decided (new
  §6-GitOps): supersedes rsync-migration. Build order set; starting with the
  DNS (AdGuard) LXC.
- **2026-07-14 (cont.)** — Platform stood up on the R720xd (all guests still on
  the `10.42.0.x` laptop relay): (1) AdGuard LXC; (2) Debian 13 cloud-init
  **template 9000** + **app-prod VM 110** (Docker CE + compose, `proxy` network
  created); (3) **Komodo** (Mongo + Core + Periphery) live on `:9120`, admin
  logged in, all containers healthy. Build-order §6-GitOps items 1–3 done, 4
  half (proxy net up, Traefik pending). Working style: **coach the user through
  steps, he runs them** ([[feedback-coach-dont-do]]). Next: `homelab-stacks`
  git repo + first Komodo-deployed stack (Traefik).
