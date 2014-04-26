a @ {
  pkgs ? import <nixpkgs> {}
, rehash ? import <nix-rehash>
, projectName ? "todos"
, platforms ? [ "x86_64-linux" "i686-linux" ]
}:

with pkgs;
with pkgs.lib;
with rehash;

rec {
  # Build package for all the platforms
  build = genAttrs platforms (system:
    (import ./default.nix { inherit system; }).app
  );

  # User services
  services = system: reService {
    name = "${projectName}";
    inherit system;
    configuration = let servicePrefix = "/tmp/${projectName}/services"; in [
      ({ config, pkgs, ...}: {
        services.mongodb.enable = true;
        services.mongodb.user = "$(id --user)";
        services.mongodb.dbpath = servicePrefix + "/db/mongodb";
        services.mongodb.logpath = servicePrefix + "/mongod.log";
        services.logstash.enable = true;
        services.logstash.inputConfig = ''
          tcp { port => 28777 type=>"sample" }
        '';
        services.logstash.outputConfig = ''
          stdout { debug => true }
          elasticsearch { embedded => true }
        '';
        services.logstash.filterConfig = ''
          json { source => "message" }
        '';
      })
    ];
  };

  # Development environemnt
  dev = genAttrs platforms (system:
    with import <nixpkgs> { inherit system; };

    # We use myEnvFun for environment
    myEnvFun {
      name = "${projectName}";
      buildInputs = [(services system) git gitAndTools.gitflow];
      extraCmds = ''
        echo ${system}
        source ${(import ./default.nix { inherit system; }).dev}
      '';
    }
  );

  # Tests deployment
  tests.deployment = (import ./tests/deployment.nix {
    system = builtins.currentSystem;
  }).test;

  # Import build of slides
  slides = (import ./default.nix { inherit system; }).slides;
}
