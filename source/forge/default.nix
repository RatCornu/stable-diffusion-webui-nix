{ pkgs
, mkWebuiDistrib
, ...
}:
let
  raw = pkgs.callPackage ./raw.nix {};

  createPackage = import ./package.nix;
in
{
  cuda = mkWebuiDistrib {
    source = raw;
    python = pkgs.python312;

    additionalRequirements = raw.additionalRequirements ++ [
      # Acceleration on CUDA
      { name = "xformers"; spec = "0.0.35"; }
    ];

    installInstructions = ./install-instructions-cuda.json;

    additionalPipArgs = ["--no-build-isolation"];
    additionalBuildRequirements = [
      { name = "setuptools"; }
      { name = "meson-python"; }
      { name = "Cython"; }
      { name = "Pythran"; }
    ];
    additionalBuildInputs = [
      pkgs.stdenv.cc
      pkgs.stdenv.cc.cc.lib
      pkgs.ninja
      pkgs.pkg-config
      pkgs.zlib
    ];
    requirementsFileName = "requirements_versions.txt";

    inherit createPackage;
  };

  rocm = mkWebuiDistrib {
    source = raw;
    python = pkgs.python311;
    additionalRequirements = raw.additionalRequirements ++ [
      { name = "torch"; spec = "https://download.pytorch.org/whl/nightly/rocm6.0/torch-2.5.0.dev20240802%2Brocm6.0-cp310-cp310-linux_x86_64.whl"; }
      { name = "torchvision"; spec = "https://download.pytorch.org/whl/nightly/rocm6.0/torchvision-0.20.0.dev20240822%2Brocm6.0-cp310-cp310-linux_x86_64.whl"; }
    ];
    additionalPipArgs = ["--extra-index-url" "https://download.pytorch.org/whl/nightly/rocm6.2/" "--no-build-isolation"];

    installInstructions = ./install-instructions-rocm.json;

    requirementsFileName = "requirements_versions.txt";

    createPackage = throw "ROCm is currently broken";
    # inherit createPackage; # Want to work on ROCm? Swap the line above with this
  };
}
