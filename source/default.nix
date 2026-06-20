# A listing of stable diffusion packages that are to
# be made available
{ pkgs,
...
}:
let
  mkWebuiDistrib = {
      source
    , python
    , createPackage
    , additionalRequirements ? []
    , additionalBuildRequirements ? []
    , additionalBuildInputs ? []
    , additionalPipArgs ? []
    , installInstructions
    , requirementsFileName ? "requirements.txt"
  }@args: {
    type = "stable-diffusion-webui-derivation";

    # So the defaults propagate...
    inherit additionalPipArgs;
    inherit additionalRequirements;
    inherit additionalBuildRequirements;
    inherit additionalBuildInputs;
    inherit requirementsFileName;
  } // args;
in rec {
  # forge conflicts with some nixpkgs name, but this flake previously
  # used that name, so alias it.
  forge = forge-webui;
  forge-webui = pkgs.callPackage ./forge { inherit mkWebuiDistrib; };
  comfy = pkgs.callPackage ./comfy { inherit mkWebuiDistrib; };
}
