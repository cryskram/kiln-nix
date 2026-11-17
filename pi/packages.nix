# Third-party pi extensions. Lockfiles are not used because their `resolved` entries lack integrity hashes.
{ pkgs }:
let
  plain =
    {
      pname,
      version,
      src,
      patches ? [ ],
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit
        pname
        version
        src
        patches
        ;
      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r . $out/
        runHook postInstall
      '';
      meta.description = "pi extension: ${pname}";
    };

  nodeModules =
    {
      pname,
      version,
      src,
      hash,
      npmFlags ? [ ],
    }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "${pname}-node-modules";
      inherit version src;

      nativeBuildInputs = [ pkgs.nodejs ];
      NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;

      dontFixup = true;

      buildPhase = ''
        runHook preBuild
        export HOME="$TMPDIR"
        npm ci --ignore-scripts --no-audit --no-fund --loglevel=error \
          ${pkgs.lib.escapeShellArgs npmFlags}
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r node_modules $out/node_modules
        runHook postInstall
      '';
    };

  withDeps =
    {
      pname,
      version,
      src,
      npmHash,
      npmFlags ? [ ],
      subdir ? ".",
    }:
    pkgs.runCommand "${pname}-${version}"
      {
        meta.description = "pi extension: ${pname}";
        passthru.extensionPath = subdir;
      }
      ''
        mkdir -p $out
        cp -r ${src}/. $out/
        chmod -R u+w $out
        rm -rf $out/node_modules
        cp -r ${
          nodeModules {
            inherit
              pname
              version
              src
              npmFlags
              ;
            hash = npmHash;
          }
        }/node_modules $out/node_modules
      '';
  rpivExtension =
    {
      pname,
      npmHash,
      subdir,
    }:
    withDeps {
      inherit pname npmHash subdir;
      version = "2.15.0";
      src = pkgs.fetchFromGitHub {
        owner = "juicesharp";
        repo = "rpiv-mono";
        tag = "v2.15.0";
        hash = "sha256-L+c/p6yhTDznxszJ8kkAxxGEWfizf5rFbXmiIGClWKg=";
      };
      npmFlags = [
        "--omit=dev"
        "--legacy-peer-deps"
        "--include-workspace-root=false"
        "--workspace=@juicesharp/${pname}"
      ];
    };
in
{
  rpiv-ask-user-question = rpivExtension {
    pname = "rpiv-ask-user-question";
    npmHash = "sha256-nHuFs+It4nKmGx1GzXViitP5yQ+c8FCnarv0cZS7qug=";
    subdir = "packages/rpiv-ask-user-question";
  };

  rpiv-todo = rpivExtension {
    pname = "rpiv-todo";
    npmHash = "sha256-1uNyUxg2Jz4taMRSfxcormBCKEb1RkGoGrg4udXs9EA=";
    subdir = "packages/rpiv-todo";
  };

  pi-btw = plain {
    pname = "pi-btw";
    version = "0.8.1";
    src = pkgs.fetchFromGitHub {
      owner = "dbachelder";
      repo = "pi-btw";
      tag = "v0.8.1";
      hash = "sha256-9jRpvNJEshd+p9+KDVzoPPtnVTvca71qFKd8fvF1DbI=";
    };
    # /btw:summarize cannot route the virtual `auto` model without extensions; drop once upstream fixes it.
    patches = [ ../patches/pi-btw-summarize-router.patch ];
  };

  zentui = plain {
    pname = "pi-zentui";
    version = "0.34.0";
    src = pkgs.fetchFromGitHub {
      owner = "lmilojevicc";
      repo = "pi-zentui";
      tag = "v0.34.0";
      hash = "sha256-gnjmEAV32NLuH/R8IsC/Pxh5YfOD8nMhFVm98IKqP5Y=";
    };
  };

  pi-subagents = withDeps {
    pname = "pi-subagents";
    version = "0.88.1";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-subagents";
      tag = "v0.88.1";
      hash = "sha256-t/IAZHTbIG1iFF+jq9tBm2jptfIYO2mLvn7WPb1I2Qc=";
    };
    npmHash = "sha256-EvE0kLCB56S0SJV83krTsQwk7vrrlYuwsh4iaD9YGfI=";
    npmFlags = [
      "--omit=dev"
    ];
  };

  pi-web-access = withDeps {
    pname = "pi-web-access";
    version = "0.48.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-web-access";
      tag = "v0.48.0";
      hash = "sha256-kvxwqQzvUEvBU8URxTCe4hGbWiUa41TbsdtdiM6+GqE=";
    };
    npmHash = "sha256-aOpdUfjjZ6QJBGV9vCk7iduNI7nYPV01c3umcMLXcNE=";
    npmFlags = [
      "--omit=dev"
    ];
  };

  pi-guard = withDeps {
    pname = "pi-guard";
    version = "1.6.0";
    src = pkgs.fetchFromGitHub {
      owner = "jdiamond";
      repo = "pi-guard";
      tag = "v1.6.0";
      hash = "sha256-il/wRNdV2zLi07b6SBubuJX4R+HXIiV0Bsx0XrWSckE=";
    };
    npmHash = "sha256-nwer1uc8wiOV5v1IPbxN5gMRTP++ihffuFlSjcZb7cU=";
    npmFlags = [
      "--omit=dev"
    ];
  };

  mcp-adapter = withDeps {
    pname = "pi-mcp-adapter";
    version = "7.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-mcp-adapter";
      tag = "v7.0.1";
      hash = "sha256-OyHd9Se7HDjbu8K668Q8/Z+sq83apfqHoKn72N8PBqg=";
    };
    npmHash = "sha256-lVLycrcyVm2+rVrsBFKIackiAdScqweNGxyOdCorgKg=";
    npmFlags = [
      "--omit=dev"
    ];
  };
}
