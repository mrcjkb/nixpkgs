{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  makeWrapper,
  autoPatchelfHook,
  openjdk17,
  libX11,
  libXext,
  libXrender,
  libXtst,
  libXi,
  libXrandr,
  libXcursor,
  libXinerama,
  libXxf86vm,
  gtk2,
  gtk3,
  glib,
  alsa-lib,
  fontconfig,
  zlib,
  gcc,
  cairo,
  pango,
  gdk-pixbuf,
  cups,
  at-spi2-core,
  dbus,
  nspr,
  nss,
  expat,
  libdrm,
  gsettings-desktop-schemas,
}:

let
  installer-wrapped = stdenv.mkDerivation (finalAttrs: {
    pname = "polysun-installer-unwrapped";
    version = "2026.6";

    src = fetchurl {
      url = "https://www.velasolaris.com/download/polysun/${finalAttrs.version}/polysun.sh";
      hash = "sha256-LnLAPoaprcXkK/tyeb83VrZlyYLKhstb0tc8+z1qKsI=";
      curlOptsList = [
        "-H" "Referer: https://www.velasolaris.com/download/polysun/${finalAttrs.version}/"
        "-H" "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:153.0) Gecko/20100101 Firefox/153.0"
      ];
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp $src $out/bin/polysun-installer.sh
      chmod +x $out/bin/polysun-installer.sh

      runHook postInstall
    '';
  });

installer = buildFHSEnv {
  name = "polysun-installer";

  targetPkgs = pkgs: with pkgs; [
    installer-wrapped
    openjdk17
    libX11
    libXext
    libXrender
    libXtst
    libXi
    libXrandr
    libXcursor
    libXinerama
    libXxf86vm
    zlib
    gcc.cc.lib
    stdenv.cc.cc.lib
    alsa-lib
    fontconfig
    freetype
  ];

  multiPkgs = pkgs: [
    pkgs.zlib
    pkgs.gcc.cc.lib
  ];

  runScript = "polysun-installer.sh";

  profile = ''
    export JAVA_HOME="${openjdk17}"
    export INSTALL4J_JAVA_HOME_OVERRIDE="${openjdk17}"
    export PATH="${openjdk17}/bin:$PATH"

    # Ensure library paths are set
    export LD_LIBRARY_PATH="/usr/lib:/usr/lib64:$LD_LIBRARY_PATH"
  '';
};

in stdenv.mkDerivation (finalAttrs: {
  pname = "polysun";
  version = "2026.6";

  src = installer;

  dontUnpack = true;

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
    openjdk17
  ];

  buildInputs = [
    openjdk17
    nspr
    nss
    expat
    libdrm
    libX11
    libXext
    libXrender
    libXtst
    libXi
    libXrandr
    libXcursor
    libXinerama
    libXxf86vm
    gtk2
    gtk3
    gsettings-desktop-schemas
    glib
    alsa-lib
    fontconfig
    zlib
    gcc.cc.lib
    cairo
    pango
    gdk-pixbuf
    cups
    at-spi2-core
    dbus
  ];

  installPhase = ''
    runHook preInstall

    cat > $PWD/response.varfile <<EOF
# install4j response file for Polysun ${finalAttrs.version}
installationDirectoryType=0
sys.adminRights\$Boolean=false
sys.component.11352\$Boolean=true
sys.component.11353\$Boolean=false
sys.component.11354\$Boolean=false
sys.component.11355\$Boolean=false
sys.component.11356\$Boolean=false
sys.component.11357\$Boolean=false
sys.component.11358\$Boolean=false
sys.installationDir=$out/lib/polysun
sys.languageId=en
sys.symlinkDir=$out/bin
dataInstallDir=$out/share/polysun/data
executeLauncherAction\$Boolean=false
sys.programGroupDisabled=true
EOF

    export JAVA_HOME="${openjdk17}"
    export INSTALL4J_JAVA_HOME_OVERRIDE="${openjdk17}"
    export PATH="${openjdk17}/bin:$PATH"

    ${installer}/bin/polysun-installer -q -varfile $PWD/response.varfile

    mkdir -p $out/share/polysun/data
    mkdir -p $out/bin
    makeWrapper "$out/lib/polysun/Polysun" $out/bin/polysun \
      --run 'DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/polysun"' \
      --run 'mkdir -p "$DATA_DIR"' \
      --run 'if [ ! -d "$DATA_DIR/data" ] && [ -d '"$out"'/share/polysun/data ]; then
        cp -r --no-preserve=mode '"$out"'/share/polysun/data "$DATA_DIR/"
      fi' \
      --set INSTALL4J_JAVA_HOME "${openjdk17}" \
      --set JAVA_HOME "${openjdk17}" \
      --set FONTCONFIG_FILE "${fontconfig.out}/etc/fonts/fonts.conf" \
      --set _JAVA_OPTIONS "-Dawt.useSystemAAFontSettings=lcd -Dswing.aatext=true -Dsun.java2d.font.gasp=true" \
      --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
      --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}" \
      --prefix PATH : "${lib.makeBinPath [ openjdk17 ]}" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.buildInputs}

    runHook postInstall
  '';

  postInstall = ''
    substituteInPlace $out/lib/polysun/system.ini \
      --replace-fail \
        "Path.Data.Folder=$out/share/polysun/data/" \
        "Path.Data.Folder=/home/mrcjk/.local/share/polysun/data" # FIXME: hard-coded data directory
  '';

  meta = {
    description = "Solar thermal system simulation software";
    homepage = "https://www.velasolaris.com/";
    # license = lib.licenses.unfree;
    longDescription = ''
      Polysun is a simulation software for solar thermal and photovoltaic systems.

      On first run, Polysun will create a data directory at:
        ''${XDG_DATA_HOME:-$HOME/.local/share}/polysun/

      This directory contains user-specific configuration and data files.

      Note: Polysun uses Thales/Sentinel RMS licensing. You will need a valid
      license to use the software.
    '';
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
    ];
    maintainers = with lib.maintainers; [ mrcjkb ];
    mainProgram = "polysun";
  };
})
