# resnap bridge (obsidian, until it moves to NixOS)

Peter's `resnap` (in `../resnap`, unmodified) does the backups. This adds the
two things it lacks: a schedule and an alarm. Install with `./install.sh` as
brett; it does not need spark.

| Piece | What it does |
|---|---|
| `resnap@<drive>.timer` / `.service` | nightly 01:30 (catches up after sleep); runs `resnap default <drive>` only when that drive is plugged in (`resnap-present`), skipping otherwise; on success touches `/var/lib/resnap/<drive>.ok` |
| `resnap-alert@<drive>.service` | `OnFailure` of a backup: fleet ntfy topic (phone) + critical desktop notification |
| `resnap-stale.timer` | daily 10:00: alerts if any configured drive's last good backup is >= 3 days old (or never) |
| `excludes` | resnap's defaults + `/nix/store`, caches, and every annex's `.git/annex/objects` |

Unchanged from resnap: per-drive restic repo at `<drive>/restic`, retention
14d/8w/12m/3y, rotating `--read-data-subset=n/20` check (`check.subset`), and
the `recover/` kit (restic binary + `resnap-restore`) copied to each drive.

Drives must be plain ext4: resnap mounts `/dev/disk/by-uuid/<fs-uuid>` at
`/mnt/<fs-uuid>` and does not unlock LUKS.

On NixOS, a `services.restic.backups.<drive>` module should take over the SAME
repos, password, excludes, `check.subset` and `recover/` layout, so the
snapshot history carries over and nothing on the drives changes.
