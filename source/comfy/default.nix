{ pkgs
, fetchFromGitHub
, mkWebuiDistrib
, stdenv
, ...
}:
let
  sourceDerivation = stdenv.mkDerivation {
    name = "ComfyUI";

    src = fetchFromGitHub {
      owner = "comfy-org";
      repo = "ComfyUI";
      rev = "v0.25.1";
      hash = "sha256-wCszvmDR7wrmM5Yhl3jFEnqLTkmXZuPC5fTgiqugBG4=";
    };

    patches = [];

    installPhase = ''
      cp -r . "$out"
    '';
  };

  createPackage = import ./package.nix;
in {
  cuda = mkWebuiDistrib {
    source = sourceDerivation;
    python = pkgs.python313;

    additionalRequirements = [
      # Required for most video extensions, common enough to be included
      # here
      { name = "diffusers"; op = ">="; spec = "0.32.0"; }
      { name = "accelerate"; op = ">="; spec = "1.2.1"; }
      { name = "transformers"; op = ">="; spec = "4.49.1"; }
      { name = "jax"; op = ">="; spec = "0.4.28"; }
      { name = "sentencepiece"; op = ">="; spec = "0.2.0"; }
      { name = "huggingface_hub"; }
      { name = "einops"; }
      { name = "peft"; }
      { name = "opencv-python"; }
      { name = "imageio-ffmpeg"; }
      { name = "bitsandbytes"; }
      { name = "matplotlib"; }
      { name = "mss"; }
      { name = "color-matcher"; }
      { name = "ftfy"; }
      { name = "protobuf"; }
      { name = "sageattention"; }
      { name = "timm"; }
    ];

    installInstructions = ./install-instructions-cuda.json;

    requirementsFileName = "requirements.txt";

    inherit createPackage;
  };
}
