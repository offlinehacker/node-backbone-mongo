{
  # Name of our deployment
  network.description = "Todos";
  # Enable rolling back to previous versions of our infrastructure
  network.enableRollback = true;

  # It consists of a single server named 'server'
  server =
    # Every server gets passed a few arguments, including a reference
    # to nixpkgs (pkgs)
    { config, pkgs, ... }:
    {
      require = [ ../server.nix ];
    };
}
