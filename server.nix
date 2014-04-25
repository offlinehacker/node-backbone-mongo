{ config, pkgs, ... }:

with pkgs.lib;

let
  # We import our custom packages from ./default passing pkgs as argument
  packages = import ./default.nix { pkgs = pkgs; };

  # And this is the application we'd like to deploy
  app = packages.app;
in {
  # We'll be running our application on port 8080, because a regular
  # user cannot bind to port 80
  # Then, we will use nginx as http proxy
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 22 ];
  networking.firewall.allowPing = true;
  # Port forwarding using iptables
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
  '';

  # Enable mongodb
  services.mongodb.enable = true;

  # Enable logstash and configure it
  services.logstash.enable = true;
  services.logstash.inputConfig = ''
    # Sample input over TCP
    tcp { port => 28777 type=>"sample" }
  '';
  services.logstash.outputConfig = ''
    stdout { debug => true }
    elasticsearch { embedded => true }
  '';
  services.logstash.filterConfig = ''
    json { source => "message" }
  '';

  # Create service for our application
  systemd.services.app = {
    description = "TODO nodejs application";

    # Start the service after the network is available and mongodb is started
    after = [ "network.target" "mongodb.service" "logstash.service" ];
    wantedBy = [ "multi-user.target" ];

    # We're going to run it on port 8080 in production
    environment = { VCAP_APP_PORT = "8080"; };

    serviceConfig = {
      # The actual command to run
      ExecStart = "${app}/bin/todos";

      # For security reasons we'll run this process as a special 'nodejs' user
      User = "nodejs";
      Restart = "always";
     };
  };

  # And lastly we ensure the user we run our application as is created
  users.extraUsers = {
    nodejs = { uid = 12345; };
  };
}
