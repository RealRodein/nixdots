{ pkgs, ... }:

# Same font set as orbiter. Kept as a separate host file so a change on one
# machine cannot silently change the other.
let
  weights = [ "Regular" "Bold" "Italic" "BoldItalic" "Medium" "SemiBold" ];
  copyFonts = name: src: prefix: destDir: pkgs.runCommand "${name}-filtered" {} ''
    mkdir -p $out/share/fonts/${destDir}
    ${builtins.concatStringsSep "\n" (map (w: "cp ${src}/${prefix}-${w}.ttf $out/share/fonts/${destDir}/") weights)}
  '';
in {
  fonts.packages = with pkgs; [
    fira-code
    (copyFonts "jetbrains-mono-nfm" "${nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono" "JetBrainsMonoNerdFontMono" "truetype/NerdFonts/JetBrainsMono")
    (copyFonts "maple-mono-nf" "${maple-mono.NF}/share/fonts/truetype" "MapleMono-NF" "truetype")
  ];
}
