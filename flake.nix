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
            libs=($baseLibraryPath/libcuda.so* $baseLibraryPath/libnvidia*.so* $baseLibraryPath/libGL*)
            for lib in ''${libs[@]}; do
              ln -s $lib $out
            done
          '';
        haskell = pkgs.ghc.withPackages (ps: with ps; [
          aeson
          parallel
          monad-parallel
          JuicyPixels
          terminal-progress-bar
        ]);
        python = pkgs.python39.withPackages (ps: with ps; [ pip setuptools ]);
      in
      {
        devShell = with pkgs; mkShellNoCC {
          packages = [
            cuda
            haskell
            haskell-language-server
            pyright
            python
            rnix-lsp
            yaml-language-server
          ];
          LD_LIBRARY_PATH = "${cuda}/lib64:${opengl-libraries}:" +
            lib.makeLibraryPath [
              cuda
              zlib
              stdenv.cc.cc.lib
              glib.out
              xorg.libX11
              xorg.libXext
              xorg.libxcb
              xorg.libXau
              xorg.libXdmcp
            ];
        };
      }
    );
}
