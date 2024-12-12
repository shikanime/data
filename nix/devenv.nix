{
  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        enableDefaultExcludes = true;
        programs = {
          deadnix.enable = true;
          nixfmt.enable = true;
          prettier.enable = true;
          statix.enable = true;
          terraform.enable = true;
        };
        settings.global.excludes = [
          "*.terraform.lock.hcl"
          ".gitattributes"
          "LICENSE"
        ];
      };
      devenv.shells.default = {
        containers = pkgs.lib.mkForce { };
        languages = {
          javascript = {
            enable = true;
            npm.enable = true;
          };
          terraform = {
            enable = true;
            package = pkgs.opentofu;
          };
          nix.enable = true;
        };
        pre-commit.hooks.tflint.enable = true;
        packages = [
          pkgs.google-cloud-sdk
        ];
      };
    };
}
