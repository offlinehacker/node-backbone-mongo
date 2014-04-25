{ system }:

with import <nixpkgs/nixos/lib/testing.nix> { inherit system; };
with pkgs.lib;

makeTest ({
  nodes = {
    server = { config, pkgs, ... }: {
      require = [ ../server.nix ];
      virtualisation.diskSize = 5000;
    };
  };

  testScript = { nodes }: ''
    # Start all machines.
    startAll;

    $server->waitForJob("mongodb");
    $server->waitForJob("app");
    $server->waitUntilSucceeds("curl 127.0.0.1:8080 | grep -i todos");
  '';
})
