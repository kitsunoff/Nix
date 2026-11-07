# CLIProxyAPI - OpenAI/Gemini/Claude compatible API proxy for CLI subscriptions
# https://github.com/router-for-me/CLIProxyAPI
# Prebuilt release binaries; bump `version` and `hashes` from the release checksums.txt
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "8.0.59";

  platforms = {
    aarch64-darwin = {
      suffix = "darwin_aarch64";
      hash = "sha256-cK268hDY5XbEgak3gjrMfcv3oeN7iV8HDAu4HIIx/zg=";
    };
    x86_64-darwin = {
      suffix = "darwin_amd64";
      hash = "sha256-TW+IYD7EmJCp+Q5Q6HyZ7eynbsBK4nMYOWbh+bSVCSI=";
    };
    aarch64-linux = {
      suffix = "linux_aarch64";
      hash = "sha256-nMVKUvIxmpqrS5AhF/zUz9Wcu4dI2FhzJwBvTIwZ79w=";
    };
    x86_64-linux = {
      suffix = "linux_amd64";
      hash = "sha256-VCfkE0So1XUZFWrhKwFlTCrvNs7Tn0k+MnNi4VYn40w=";
    };
  };

  platform =
    platforms.${stdenvNoCC.hostPlatform.system}
      or (throw "cli-proxy-api: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "cli-proxy-api";
  inherit version;

  src = fetchurl {
    url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_${platform.suffix}.tar.gz";
    inherit (platform) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D --mode=0755 cli-proxy-api $out/bin/cli-proxy-api
    install -D --mode=0644 config.example.yaml $out/share/cli-proxy-api/config.example.yaml
    runHook postInstall
  '';

  meta = {
    description = "Proxy exposing OpenAI/Gemini/Claude compatible APIs for CLI subscriptions";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    changelog = "https://github.com/router-for-me/CLIProxyAPI/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "cli-proxy-api";
    platforms = builtins.attrNames platforms;
  };
}
