# https://github.com/NixOS/nixpkgs/tree/nixos-25.05/pkgs/by-name/bl/blockbench

{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  imagemagick,
  copyDesktopItems,
  makeDesktopItem,
  electron,
}:

buildNpmPackage rec {
  pname = "blockbench";
  version = "4.12.4";

  src = fetchFromGitHub {
    owner = "JannisX11";
    repo = "blockbench";
    tag = "v${version}";
    hash = "sha256-tg2ICxliTmahO3twKgC4LSVyiX9K2jfA7lCcSCkzcbQ=";
  };

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    imagemagick # for icon resizing
    copyDesktopItems
  ];

  npmDepsHash = "sha256-a5OjCVHPeaBEYTFIUOnc9We677oCGwAvwMv8f1QRk9Q=";

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = 1;

  # disable code signing on Darwin
  postConfigure = lib.optionalString stdenv.hostPlatform.isDarwin ''
    export CSC_IDENTITY_AUTO_DISCOVERY=false
    sed -i "/afterSign/d" package.json
  '';

  npmBuildScript = "bundle";

  postBuild = ''
    # electronDist needs to be modifiable on Darwin
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist

    npm exec electron-builder -- \
        --dir \
        -c.electronDist=electron-dist \
        -c.electronVersion=${electron.version}
  '';

  installPhase = ''
    runHook preInstall

    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      mkdir -p $out/Applications
      cp -r dist/mac*/Blockbench.app $out/Applications
      makeWrapper $out/Applications/Blockbench.app/Contents/MacOS/Blockbench $out/bin/blockbench4
    ''}

    ${lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
      mkdir -p $out/share/blockbench4
      cp -r dist/*-unpacked/{locales,resources{,.pak}} $out/share/blockbench4

      for size in 16 32 48 64 128 256 512; do
        mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
        magick icon.png -resize "$size"x"$size" $out/share/icons/hicolor/"$size"x"$size"/apps/blockbench4.png
      done

      makeWrapper ${lib.getExe electron} $out/bin/blockbench4 \
          --add-flags $out/share/blockbench4/resources/app.asar \
          --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
          --add-flags "--userData" \
          --add-flags "\$HOME/.config/Blockbench/${version}" \
    ''}

    echo \$HOME

    runHook postInstall
  '';

  # based on desktop file found in the published AppImage archive
  desktopItems = [
    (makeDesktopItem {
      name = "blockbench4";
      exec = "blockbench4 %U";
      icon = "blockbench";
      desktopName = "Blockbench 4.12.4";
      comment = meta.description;
      categories = [ "3DGraphics" ];
      startupWMClass = "Blockbench 4";
      terminal = false;
    })
  ];

  meta = {
    changelog = "https://github.com/JannisX11/blockbench/releases/tag/v${version}";
    description = "Low-poly 3D modeling and animation software (Version 4.12.4)";
    homepage = "https://blockbench.net/";
    license = lib.licenses.gpl3Only;
    mainProgram = "blockbench4";
    maintainers = with lib.maintainers; [ tomasajt ];
  };
}
