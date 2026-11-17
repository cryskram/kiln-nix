# The npm tarball ships prebuilt dist/grammars; the tag's lockfile pins dependencies so the output hash is stable.
{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs,
  cacert,
}:
let
  version = "4.4.4";

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-lens/-/pi-lens-${version}.tgz";
    hash = "sha256-CW7PWQBzEnTCofetJSSeTvU6o6ys8SkUb3LZ6tsGVuo=";
  };

  lock = fetchurl {
    url = "https://raw.githubusercontent.com/apmantza/pi-lens/v${version}/package-lock.json";
    hash = "sha256-dPKzIpMiJ60N/14RQ28BHpQxRbpQuCn9sx5gKGpy5d8=";
  };

  nodeModules = stdenvNoCC.mkDerivation {
    pname = "pi-lens-node-modules";
    inherit version src;

    nativeBuildInputs = [ nodejs ];
    NIX_SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-xN7/QGnj1XgVruy67T8bCO6h+e806NaRizadmxAUjw4=";

    dontFixup = true;
    sourceRoot = "package";

    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR"
      cp ${lock} package-lock.json
      npm ci --omit=dev --omit=peer --ignore-scripts \
        --no-audit --no-fund --loglevel=error
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules/. $out/
      # npm stamps install-time mtimes, which would otherwise change the NAR hash on every build.
      find $out -exec touch -h -d @1 {} +
      runHook postInstall
    '';
  };
in
stdenvNoCC.mkDerivation {
  pname = "pi-lens";
  inherit version src;

  sourceRoot = "package";
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/pi-lens
    cp -r . $out/lib/node_modules/pi-lens/
    cp -r ${nodeModules} $out/lib/node_modules/pi-lens/node_modules
    runHook postInstall
  '';

  meta = {
    description = "pi-lens — real-time code feedback for pi (LSP, linters, formatters, structural analysis)";
    homepage = "https://github.com/apmantza/pi-lens";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
