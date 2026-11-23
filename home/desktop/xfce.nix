{ pkgs, ... }:

{
  # Keep the useful app shortcuts, minus the old panel-app toggle. XFCE reads
  # application shortcuts from this xfconf channel.
  xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" = {
    force = true;
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-keyboard-shortcuts" version="1.0">
        <property name="commands" type="empty">
          <property name="custom" type="empty">
            <property name="&lt;Primary&gt;&lt;Shift&gt;e" type="string" value="${pkgs.ghostty}/bin/ghostty -e ${pkgs.yazi}/bin/yazi" />
            <property name="&lt;Primary&gt;&lt;Shift&gt;b" type="string" value="${pkgs.brave-origin}/bin/brave-origin" />
          </property>
        </property>
      </channel>
    '';
  };

  # Parity with Luciole's file-manager scripts on orbiter: Thunar gets the same
  # "Open Terminal Here" and "Open in Yazi" actions.
  xdg.configFile."Thunar/uca.xml" = {
    force = true;
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
        <action>
          <icon>utilities-terminal</icon>
          <name>Open Terminal Here</name>
          <unique-id>1</unique-id>
          <command>${pkgs.ghostty}/bin/ghostty --working-directory=%f</command>
          <description>Open Ghostty in this folder</description>
          <patterns>*</patterns>
          <directories />
        </action>
        <action>
          <icon>utilities-terminal</icon>
          <name>Open in Yazi</name>
          <unique-id>2</unique-id>
          <command>${pkgs.ghostty}/bin/ghostty --working-directory=%f -e ${pkgs.yazi}/bin/yazi</command>
          <description>Browse this folder with Yazi</description>
          <patterns>*</patterns>
          <directories />
        </action>
      </actions>
    '';
  };
}
