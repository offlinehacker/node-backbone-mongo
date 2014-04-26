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

  services.nginx.enable = true;
  services.nginx.config = ''
events {
  worker_connections  4096;  ## Default: 1024
}
 
http {
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;
  include ${pkgs.nginx}/conf/mime.types;
  default_type application/octet-stream;
  gzip on;
  gzip_disable "msie6";

  server { # simple reverse-proxy
    listen       80; 
    location / {
      proxy_pass      http://127.0.0.1:8080;
    }
  }
}
  '';


  # And lastly we ensure the user we run our application as is created
  users.extraUsers = {
    nodejs = { uid = 12345; };
  };
}
