{ pkgs, machineName, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    profiles.default = {
      id = 0;
      name = "default";
      # Match the profile Firefox created on this machine so Home Manager's
      # generated profiles.ini points at the existing profile data.
      path = if machineName == "orbiter" then "26y8fenx.default" else "default";
      isDefault = true;

      settings = {
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        "browser.tabs.inTitlebar" = 1;
        "browser.compactmode.show" = true;
        "browser.startup.page" = 3;
        "browser.aboutConfig.showWarning" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "app.shield.optoutstudies.enabled" = false;
        "browser.discovery.enabled" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      };
    };

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };
  };

  # Firefox rewrites profiles.ini itself; keep the Home Manager copy
  # authoritative so activation doesn't fail on the existing file.
  home.file.".config/mozilla/firefox/profiles.ini".force = true;
}
