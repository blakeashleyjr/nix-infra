#common-modules/secret-activation.nix
{ lib, pkgs, ... }:
{
  secretActivationScript = name: secretPath: configPath: owner: group: ''
    secret=$(cat ${secretPath})
    configDir=$(dirname ${configPath})
    mkdir -p "$configDir"
    ${pkgs.gnused}/bin/sed "s#@secret@#$secret#" "${configPath}.template" > "$configPath"
    chown -R ${owner}:${group} "$configDir"
    chmod 700 "$configDir"
    chmod 600 "$configPath"
  '';
}
