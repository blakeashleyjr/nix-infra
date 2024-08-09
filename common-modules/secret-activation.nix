# common-modules/secret-activation.nix
{ lib, pkgs, ... }:

{
  options = {
    secretActivationScript = lib.mkOption {
      type = lib.types.functionTo (lib.types.functionTo (lib.types.functionTo (lib.types.functionTo (lib.types.functionTo lib.types.str))));
      description = "Function to generate secret activation scripts";
    };
  };

  config = {
    secretActivationScript = name: secretPath: configPath: owner: group: ''
      secret=$(cat ${secretPath})
      configDir=$(dirname ${configPath})
      mkdir -p "$configDir"
      ${pkgs.gnused}/bin/sed "s#@secret@#$secret#g" "${configPath}.template" > "$configPath"
      chown -R ${owner}:${group} "$configDir"
      chmod 700 "$configDir"
      chmod 600 "$configPath"
    '';
  };
}
