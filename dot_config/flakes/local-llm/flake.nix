{
  description = "Local LLM flake with Ollama";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      for_all_systems = f:
        nixpkgs.lib.genAttrs systems (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          in
            f pkgs);
    in
    {
      devShells = for_all_systems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.ollama
            pkgs.llmfit
            pkgs.opencode
            pkgs.claude-code
          ];
        };
      });
    };
}
