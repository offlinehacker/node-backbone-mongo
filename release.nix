a @ {
  pkgs ? import <nixpkgs> {}
, nix-rehash ? import <nix-rehash>
, projectName ? "todos"
, platforms ? [ "x86_64-linux" "i686-linux" ]
}:

with pkgs;
with pkgs.lib;
with nix-rehash;

rec {
  build = genAttrs platforms (system:
    (import ./default.nix { inherit system; }).app
  );

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

  dev = genAttrs platforms (system:
    with import <nixpkgs> { inherit system; };

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
}