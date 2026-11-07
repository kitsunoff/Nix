# teamclaude - multi-account proxy for Claude Code and Codex
# Pre-built package from npm registry (no runtime dependencies, no build step)
# https://github.com/KarpelesLab/teamclaude
{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs,
  makeWrapper,
  versionCheckHook,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "teamclaude";
  version = "1.1.28";

  src = fetchurl {
    url = "https://registry.npmjs.org/@karpeleslab/teamclaude/-/teamclaude-${finalAttrs.version}.tgz";
    hash = "sha512-RmODad8qmFepDmVnTwk8sTyce2mtnwO56B1bOGUkC5reu9EQiJ+U29QEKVW9uih1yvW0/5aSbpVLoo7Gk98l6g==";
  };

  sourceRoot = "package";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/teamclaude
    cp -r . $out/lib/node_modules/teamclaude/

    for bin in teamclaude teamrouter; do
      makeWrapper ${lib.getExe nodejs} $out/bin/$bin \
        --add-flags "$out/lib/node_modules/teamclaude/src/index.js"
    done

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Multi-account proxy for Claude Code and Codex that rotates accounts on quota";
    homepage = "https://github.com/KarpelesLab/teamclaude";
    license = lib.licenses.mit;
    mainProgram = "teamclaude";
    platforms = lib.platforms.all;
  };
})
