# NixDOTs

This flake is organized by host entrypoints under `hosts/<hostname>/`, with reusable system modules under `modules/nixos/`.

## Structure

- `flake.nix` - flake inputs/outputs
- `lib/mkHost.nix` - shared `nixosSystem` constructor used by all hosts
- `hosts/<hostname>/` - host-local wiring and hardware-specific config
- `modules/nixos/base/common.nix` - shared system defaults across hosts
- `modules/nixos/packages/common.nix` - shared package-layer settings (AppImage, overlays, nixpkgs flags)
- `modules/nixos/users/rodein-base.nix` - shared base user definition
- `modules/nixos/desktop/noctalia.nix` - orbiter desktop + Noctalia live-edit entrypoint

## Rebuild current host

The existing workflow is unchanged:

```bash
sudo nixos-rebuild switch --flake ~/nixdots#orbiter
```

## Live-edit Noctalia

For quick iterative edits, keep editing Noctalia config directly in:

- `~/nixdots/home/orbiter/dotfiles/noctalia/`

Then rebuild with `#orbiter`.

## Add a new host

1. Create `hosts/<new-host>/` with `default.nix` and `hardware.nix`.
2. Import shared modules from `modules/nixos/...` plus host-local modules.
3. Add a flake output in `flake.nix`:

```nix
nixosConfigurations.<new-host> = mkHost { inherit system; hostPath = ./hosts/<new-host>; };
```
