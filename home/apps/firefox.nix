{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    profiles.default = {
      id = 0;
      name = "default";
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
}
