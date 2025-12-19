# Vibe Kanban - Local kanban board for AI agents
# https://www.vibekanban.com
{ lib
, stdenv
, makeWrapper
, nodejs
}:

stdenv.mkDerivation {
  pname = "vibe-kanban";
  version = "latest";

  # No source - we create a wrapper script
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # Main CLI wrapper
    makeWrapper ${nodejs}/bin/npx $out/bin/vibe-kanban \
      --prefix PATH : ${nodejs}/bin \
      --add-flags "-y" \
      --add-flags "vibe-kanban@latest"

    # MCP server wrapper (for AI assistants)
    makeWrapper ${nodejs}/bin/npx $out/bin/vibe-kanban-mcp \
      --prefix PATH : ${nodejs}/bin \
      --add-flags "-y" \
      --add-flags "vibe-kanban@latest" \
      --add-flags "--mcp"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Local kanban board for AI coding agents";
    homepage = "https://www.vibekanban.com";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
