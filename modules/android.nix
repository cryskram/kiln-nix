{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  androidSdk = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [
      "35"
      "36"
    ];
    includeSources = true;
  };
  storeSdk = "${androidSdk.androidsdk}/libexec/android-sdk";

  # Studio writes into the SDK while creating projects, so it gets a writable overlay of symlinks into the store SDK.
  sdkOverlay = "${config.users.users.${user}.home}/Android/Sdk";

  # There is no XWayland session here, so Studio's JBR must use its Wayland AWT toolkit.
  androidStudio = pkgs.symlinkJoin {
    name = "android-studio-wayland";
    paths = [ pkgs.android-studio ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/android-studio \
        --set STUDIO_VM_OPTIONS ${pkgs.writeText "studio64.vmoptions" "-Dawt.toolkit.name=WLToolkit\n"} \
        --set ANDROID_HOME ${sdkOverlay} \
        --set ANDROID_SDK_ROOT ${sdkOverlay}
    '';
  };
in
{
  nixpkgs.config.android_sdk.accept_license = true;

  environment.systemPackages = [
    androidSdk.androidsdk
    pkgs.android-tools
    androidStudio
    pkgs.xwayland-satellite
  ];

  environment.sessionVariables = {
    ANDROID_HOME = sdkOverlay;
    ANDROID_SDK_ROOT = sdkOverlay;
  };

  home-manager.users.${user}.home.activation.androidSdkOverlay = lib.mkAfter ''
    sdk="${sdkOverlay}"
    base="${storeSdk}"
    mkdir -p "$sdk"

    if [ ! -d "$sdk/licenses" ]; then
      cp -r "$base/licenses" "$sdk/licenses"
      chmod -R u+w "$sdk/licenses"
    fi

    for pkg in build-tools cmake cmdline-tools platforms platform-tools sources tools; do
      [ -d "$base/$pkg" ] || continue
      mkdir -p "$sdk/$pkg"
      for pkgdir in "$base/$pkg"/*; do
        [ -e "$pkgdir" ] || continue
        target="$sdk/$pkg/$(basename "$pkgdir")"
        if [ -d "$target" ] && [ ! -L "$target" ]; then
          continue
        fi
        ln -sfn "$pkgdir" "$target"
      done
    done
  '';
}
