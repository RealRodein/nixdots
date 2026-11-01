{ config, pkgs, ... }:

{
  # 1. Enable the Tailscale daemon service
  services.tailscale = {
    enable = true;

    # Allows Tailscale to manage DNS and routing natively
    useRoutingFeatures = "client";
  };

  # 2. Add Tailscale CLI to system-wide environment
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # 3. Prevent strict firewall rules from breaking Tailscale routing/exit nodes
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ 41641 ]; # Standard Tailscale UDP port (advertised via `tailscale status`)
    checkReversePath = "loose"; # Prevents connection drops over VPN mesh network
  };

  # 4. Allow the user to control Tailscale without sudo for GUI integration
  #    After first run, set the operator with:
  #    `sudo tailscale set --operator=$USER`
  #    This enables the tray client to manage Tailscale without sudo.
}