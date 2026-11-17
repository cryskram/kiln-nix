# nixpkgs only packages OpenCode 1.x and npm's @opencode/cli is a postinstall shim, so fetch the platform binary.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = "2.1.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${finalAttrs.version}.tgz";
    hash = "sha256-ZFkQV+pZPpoRN01GMMIkmTDY8zWYrws+AhN0k4YKsXs=";
  };

  sourceRoot = "package";

  nativeBuildInputs = [ autoPatchelfHook ];

  dontBuild = true;
  # Stripping a bun-compiled binary turns it back into the bun CLI.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/opencode $out/bin/opencode
    runHook postInstall
  '';

  meta = {
    description = "OpenCode 2 — open source AI coding agent (daemon-based rewrite)";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode";
  };
})
