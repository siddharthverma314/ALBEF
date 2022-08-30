{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        cuda = "/usr/local/cuda-11.6";
        opengl-libraries = pkgs.runCommandNoCCLocal "opengl-libraries"
          { baseLibraryPath = "/usr/lib/x86_64-linux-gnu"; }
          ''
            mkdir -p $out
            libs=($baseLibraryPath/libcuda.so* $baseLibraryPath/libnvidia*.so*)
            for lib in ''${libs[@]}; do
              ln -s $lib $out
            done
          '';
      in
      {
        devShell = with pkgs; mkShellNoCC {
          packages = [
            rnix-lsp
            nodePackages.pyright
            (python311.withPackages (ps: with ps; [ pip setuptools ]))
            cuda
            yaml-language-server
          ];
          LD_LIBRARY_PATH = lib.concatStringsSep ":" [
            "${cuda}/lib"
            "${cuda}/lib64"
            "${zlib}/lib"
            "${stdenv.cc.cc.lib}/lib"
            opengl-libraries
          ];
        };
      }
    );
}
