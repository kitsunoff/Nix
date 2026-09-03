# OpenSpec - AI-native system for spec-driven development
# https://github.com/Fission-AI/OpenSpec
#
# Local package pinned ahead of nixpkgs (nixpkgs currently ships 1.2.0).
# Remove this file once the nixpkgs bump lands.
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nodejs_20,
  pnpm_9,
  fetchPnpmDeps,
  pnpmConfigHook,
  makeWrapper,
  installShellFiles,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "openspec";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "Fission-AI";
    repo = "OpenSpec";
    tag = "v${finalAttrs.version}";
    hash = "sha256-efy/YUkr95S44N26FCRQ2/F+ciaaMRvzh/cI1Z0huzU=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_9;
    fetcherVersion = 3;
    hash = "sha256-+qGFLSVLJ9faZOmfO6ZVBP525i5LRgwhsJat2vT7Aw8=";
  };

  nativeBuildInputs = [
    nodejs_20
    pnpmConfigHook
    pnpm_9
    makeWrapper
    installShellFiles
  ];

  buildPhase = ''
    runHook preBuild

    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/openspec

    substituteInPlace bin/openspec.js \
      --replace '#!/usr/bin/env node' '#!${nodejs_20}/bin/node' \
      --replace "../dist" "$out/lib/openspec/dist"
    install -Dm755 bin/openspec.js $out/bin/openspec

    cp -r dist $out/lib/openspec/
    cp -r schemas $out/lib/openspec/
    cp package.json $out/lib/openspec/
    cp -r node_modules $out/lib/openspec/

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    installShellCompletion --cmd openspec \
      --bash <($out/bin/openspec completion generate bash) \
      --fish <($out/bin/openspec completion generate fish) \
      --zsh <($out/bin/openspec completion generate zsh)
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "AI-native system for spec-driven development";
    homepage = "https://github.com/Fission-AI/OpenSpec";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.all;
    mainProgram = "openspec";
  };
})
