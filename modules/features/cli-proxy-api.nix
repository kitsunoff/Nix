# CLIProxyAPI - local OpenAI/Claude compatible proxy over CLI subscriptions
# Credentials are created out of band with `cli-proxy-api -claude-login` / `-codex-login`
# and stored in authDir; this module only manages the server config.
{ ... }:
{
  flake.homeModules.cli-proxy-api =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.cliProxyApi;

      configFile = (pkgs.formats.yaml { }).generate "cli-proxy-api-config.yaml" {
        config-version = 8;
        server = {
          inherit (cfg) host port;
        };
        # Empty secret-key disables the management API entirely
        management = {
          secret-key = "";
          # Panel assets would be written next to the config, i.e. into the read-only store
          disable-control-panel = true;
        };
        access.api-keys = cfg.apiKeys;
        oauth.auth-dir = cfg.authDir;
      };

      wrapped = pkgs.symlinkJoin {
        name = "cli-proxy-api-wrapped";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/cli-proxy-api --add-flags "-config ${configFile}"
        '';
      };
    in
    {
      options.programs.cliProxyApi = {
        enable = lib.mkEnableOption "CLIProxyAPI with a generated config";

        package = lib.mkPackageOption pkgs "cli-proxy-api" { };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Interface to bind to. Empty string binds all interfaces.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8317;
          description = "Listen port.";
        };

        apiKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "sk-local-cli-proxy-api" ];
          description = ''
            Client keys accepted by the proxy (not upstream provider keys).
            They end up in the world-readable Nix store, so keep host bound to localhost.
          '';
        };

        authDir = lib.mkOption {
          type = lib.types.str;
          default = "~/.cli-proxy-api";
          description = "Directory with OAuth credential files.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ wrapped ];
      };
    };
}
