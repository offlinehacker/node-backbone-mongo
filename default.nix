{ projectName ? "todos", version ? "0.0.1"
, src ? { outPath = ./.; revCount = 0; shortRev = "abcdef"; rev = "HEAD"; }
, system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
}:

with pkgs;
with pkgs.lib;

rec {
  # Load node packages
  nodePackages =
    recurseIntoAttrs (import <nixpkgs/pkgs/top-level/node-packages.nix> {
      inherit pkgs;
      inherit stdenv nodejs fetchurl fetchgit;
      neededNatives = [python] ++ optional (elem system platforms.linux) utillinux;
      self = recursiveUpdate nodePackages {
        by-version."express"."3.5.2" = nodePackages.by-version."express"."3.5.2".override (p:{
          deps = p.deps ++ [ nodePackages.by-version."jade"."1.3.1" ];
        });
      };
      generated = ./package.nix;
    } // { nativeDeps = pkgs.nodePackages.nativeDeps;});

  # Create environment of node dependencies
  nodeDeps = buildEnv {
    name = "${projectName}-deps";
    paths = filter (v: nixType v == "derivation") (attrValues nodePackages);
    ignoreCollisions = true;
  };

  # Preload bower cache
  bowerCache = import ./bower.nix { inherit fetchbower buildEnv; };

  # Create tarball of the source
  tarball = pkgs.runCommand "${projectName}-${version}.tgz" { buildInputs = [ pkgs.nodejs ]; } ''
    mv `HOME=$PWD npm pack ${src}` $out
  '';

  # Build app
  app = nodePackages.buildNodePackage {
    name = "${projectName}-${version}";
    src = [ tarball ];
    deps = filter (v: nixType v == "derivation") (attrValues nodePackages);
    buildInputs = [];
    peerDependencies = [];
    passthru.names = [ "todos-backbone-node-mongo" ];
  };

  # Script for development environment
  dev = writeScript "${projectName}-dev" (let
    prefix = "/tmp/nodejs-${projectName}";
  in ''
    #!/bin/sh
    mkdir -p ${prefix}
    export PATH=${pkgs.nodejs}/bin:${nodeDeps}/bin:$PATH
    cp -RL ${bowerCache} ${prefix}/.bower_cache && chmod -R +w ${prefix}/.bower_cache
    export bower_storage__packages=${prefix}/.bower_cache/packages
    export bower_storage__registry=${prefix}/.bower_cache/registry
    npm_install_modules () {
      mkdir -p node_modules && cp -Rf ${nodeDeps}/lib/node_modules/* node_modules 2>/dev/null
    }
    export -f npm_install_modules
  '');

  # Create slides
  slides = pkgs.runCommand "${projectName}-${version}-slides" { buildInputs = []; } ''
    mkdir -p $out/nix-support
    cp -R ${src}/slides $out
    echo "doc manual $out/slides index.html" >> $out/nix-support/hydra-build-products
  '';

}
