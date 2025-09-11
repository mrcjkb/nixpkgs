# NOTE: The rockspec URL has a git+ssh protocol, which luarocks-nix
# does not support. So this package has been added manually.
{
  lib,
  buildLuarocksPackage,
  fetchFromGitHub,
  fetchurl,
  lua,
  luaOlder,
  luaAtLeast,
}:
buildLuarocksPackage {
  pname = "lapis-eswidget";
  version = "1.4.0-1";
  knownRockspec =
    (fetchurl {
      url = "mirror://luarocks/lapis-eswidget-1.4.0-1.rockspec";
      hash = "sha256-Z1q+h+pm5f8rv2Uax4N24zGaisWQzR9l9oo4jjQycOQ=";
    }).outPath;
  src = fetchFromGitHub {
    owner = "leafo";
    repo = "lapis-eswidget";
    rev = "v1.4.0";
    hash = "sha256-6WbeoIWE2Ol7hZFbxK0SYWD+8MiPPGzXfvMZmmh3xbU=";
  };

  disabled = luaOlder "5.1" || luaAtLeast "5.5";
  propagatedBuildInputs = with lua.pkgs; [
    lapis
    tableshape
  ];

  meta = {
    homepage = "https://github.com/leafo/lapis-eswidget.git";
    description = "Widget base class designed for generating ES modules for bundling JavaScript & more";
    license.fullName = "MIT";
    maintainers = with lib.maintainers; [ mrcjkb ];
  };
}
