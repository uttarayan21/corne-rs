{
  description = "A very basic clang devshell flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crates-nix = {
      url = "github:uttarayan21/crates.nix";
      inputs.crates-io-index.follows = "crates-io-index";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crates-io-index = {
      url = "git+https://github.com/rust-lang/crates.io-index?shallow=1";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    crates-nix,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [
        # (final: prev: {
        # })
        rust-overlay.overlays.default
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
      crates = crates-nix.mkLib {inherit pkgs;};
      stableToolchain = pkgs.rust-bin.stable.latest.default.override {
        targets = ["thumbv7em-none-eabihf"];
        extensions = ["rust-src" "llvm-tools"];
      };
      stableToolchainWithLLvmTools = pkgs.rust-bin.stable.latest.default.override {
        targets = ["thumbv7em-none-eabihf"];
        extensions = ["rust-src" "llvm-tools"];
      };
      stableToolchainWithRustAnalyzer = pkgs.rust-bin.stable.latest.default.override {
        targets = ["thumbv7em-none-eabihf"];
        extensions = ["rust-src" "llvm-tools" "rust-analyzer"];
      };
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [clang pkg-config];
        buildInputs = with pkgs; [libiconv];
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        packages = with pkgs; [
          (crates.buildCrate "rmkit" {})
          (crates.buildCrate "cargo-hex-to-uf2" {})
          (crates.buildCrate "elf2uf2-rs" {
            buildInputs = with pkgs; [libudev-zero];
            nativeBuildInputs = with pkgs; [pkg-config];
          })
          taplo
          flip-link
          cargo-make
          cargo-binutils
          stableToolchainWithRustAnalyzer
        ];
      };
    });
}
