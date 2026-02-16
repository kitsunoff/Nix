# ccusage - CLI tool for analyzing Claude Code usage
# Pre-built package from npm registry (no build step needed)
# https://github.com/ryoppippi/ccusage
{
  lib,
  stdenv,
  fetchurl,
  nodejs,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "ccusage";
  version = "18.0.5";

  src = fetchurl {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-Co9+jFDk4WmefrDnJvladjjYk+XHhYYEKNKb9MbrkU8=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs ];

  unpackPhase = ''
    mkdir -p source
    tar -xzf $src -C source --strip-components=1
  '';

  installPhase = ''
    mkdir -p $out/lib/node_modules/ccusage
    cp -r source/* $out/lib/node_modules/ccusage/

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/ccusage \
      --add-flags "$out/lib/node_modules/ccusage/dist/index.js"
  '';

  meta = {
    description = "CLI tool for analyzing Claude Code/Codex CLI usage from local JSONL files";
    homepage = "https://github.com/ryoppippi/ccusage";
    license = lib.licenses.mit;
    mainProgram = "ccusage";
  };
}
