{
  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    cosmic.url = "github:i3/i3";
    cosmic.flake = false;
  };

  outputs = {
    self,
    dream2nix,
    cosmic,
  } @ inp: (dream2nix.lib.makeFlakeOutputs {
    systems = ["x86_64-linux"];
    config.projectRoot = ./.;
    source = cosmic;
  });
}