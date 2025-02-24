{
  lib,
  fetchFromGitHub,
  rustPlatform,
  testers,
  rustowl,
}:
rustPlatform.buildRustPackage rec {
  pname = "rustowl";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "cordx56";
    repo = "rustowl";
    rev = "v${version}";
    sparseCheckout = [ "rustowl" ];
    hash = "sha256-va+og3rgmm1bbWPk3GQofQ8S6QKIGr39At8QyKTOA/A=";
  };

  sourceRoot = "${src.name}/rustowl";

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src sourceRoot;
    allowGitDependencies = false;
    hash = "sha256-Ovj3/CO2tkdVWELu2cPpb85+obO1CMv0A3AYL6PbvRw=";
  };

  passthru.tests.version = testers.testVersion {
    package = rustowl;
    command = "${meta.mainProgram} --version";
    version = version;
  };

  meta = with lib; {
    description = "Visualize ownership and lifetimes in Rust for debugging and optimization";
    longDescription = ''
      RustOwl visualizes ownership movement and lifetimes of variables.
      When you save Rust source code, it is analyzed, and the ownership and
      lifetimes of variables are visualized when you hover over a variable or function call.
    '';
    homepage = "https://github.com/cordx56/rustowl";
    license = licenses.mpl20;
    maintainers = [ lib.maintainers.mrcjkb ];
    platforms = platforms.all;
    mainProgram = "rustowlc";
  };
}
