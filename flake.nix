{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    let
      systemOutputs = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          craneLib = crane.mkLib pkgs;
        in
        {
          packages.default = craneLib.buildPackage {
            src = craneLib.cleanCargoSource ./.;

            nativeBuildInputs = with pkgs; [
              pkg-config
              wrapGAppsHook4
            ];

            buildInputs = with pkgs; [
              gtk4
              gtk4-layer-shell
            ];
          };
        });
    in
    systemOutputs // {
      homeModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.ave;
        in
        {
          options.programs.ave = {
            enable = lib.mkEnableOption "applicazione ave (Rust/GTK4)";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.system}.default;
              description = "Il pacchetto ave da installare.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
          };
        };

      homeManagerModules.default = self.homeModules.default;
    };
}
