# Development script to generate a new list of stable diffusion requirements
# This is only needed when updating the flake, you don't need to install
# this when just using stable-diffusion.
{ pkgs
, lib
, python-flexseal

# Extra parameters
, webuiPkgs
}:
let
  # Use the raw python with a few custom packages
  basic-python = webuiPkgs.python.withPackages (pyPkgs: [
    pyPkgs.pip
    pyPkgs.virtualenv
    pyPkgs.wheel
  ]);

  # Transform the Nix objects into arguments that can be passed to pip
  requirementToPip = requirement:
    if requirement ? spec then
      if (lib.strings.hasPrefix "https://" requirement.spec) || (lib.strings.hasPrefix "http://" requirement.spec)
        then requirement.spec
      else let
        op = requirement.op or "==";
      in "${requirement.name}${op}${requirement.spec}"
    else
      requirement.name;

  additionalPipArgs = lib.strings.escapeShellArgs (
    (map requirementToPip (webuiPkgs.additionalRequirements or [])) ++
    webuiPkgs.additionalPipArgs
  );

  additionalBuildRequirements = lib.strings.escapeShellArgs (
    map requirementToPip (webuiPkgs.additionalBuildRequirements or [])
  );
in pkgs.writeShellApplication {
  name = "stable-diffusion-webui-update-requirements";
  runtimeInputs = (webuiPkgs.additionalBuildInputs or []);
  text = ''
    set -e

    if [[ $# -ne 1 ]]; then
      echo "Usage: $0 <install-instructions.json>" >&2
      exit 1
    fi

    export LD_LIBRARY_PATH=''${LD_LIBRARY_PATH:+LD_LIBRARY_PATH:}:${pkgs.lib.makeLibraryPath webuiPkgs.additionalBuildInputs}
    echo "Using library path $LD_LIBRARY_PATH"

    output="$(realpath "$1")"

    echo "Stable diffusion repository is at ${webuiPkgs.source}"

    temporary_dir="$(mktemp -d)"
    cd "$temporary_dir"

    cache_dir="$temporary_dir/cache"
    env_dir="$temporary_dir/venv"
    requirement_files=("${webuiPkgs.source}/${webuiPkgs.requirementsFileName}")

    echo "Creating virtual environment in $env_dir"
    ${basic-python}/bin/python -m venv "$env_dir"

    # shellcheck disable=1091
    source "$env_dir/bin/activate"

    ${pkgs.lib.optionalString (lib.length webuiPkgs.additionalBuildRequirements != 0)
      ''
        echo "Temporarily installing build requirements..."
        python -m pip install ${additionalBuildRequirements}
      ''
    }

    echo "Installing dependencies..."

    declare -a pip_requirement_files

    for f in "''${requirement_files[@]}"; do
      echo "  Adding requirement file $f"
      pip_requirement_files+=("-r" "$f")
    done

    # Install everything with one pip install invocation - this ensures the dependency resolver
    # works correctly
    python -m pip install \
      --dry-run \
      --ignore-installed \
      --report install-report.json \
      "''${pip_requirement_files[@]}" \
      --cache-dir "$cache_dir" \
      ${additionalPipArgs}

    ${pkgs.lib.optionalString (lib.length webuiPkgs.additionalBuildRequirements != 0)
      ''
        echo "Removing build requirements.."
        python -m pip uninstall -y ${additionalBuildRequirements}
      ''
    }

    deactivate

    echo "Sealing environment from install report"

    ${python-flexseal}/bin/python-flexseal -p install-report.json -o "$output"

    echo "Written json to $output"
    rm -rf "$temporary_dir"
  '';
}
