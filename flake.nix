{
  inputs = {
    versions.url = "github:holochain/holochain?dir=versions/0_3_rc";
    
    versions.inputs.holochain.url = "github:holochain/holochain/holochain-0.3.1-rc.0";
    versions.inputs.lair.url = "github:holochain/lair/lair_keystore-v0.4.4";

    holochain = {
      url = "github:holochain/holochain";
      inputs.versions.follows = "versions";
    };

    tryorama.url = "github:holochain/tryorama/main"; # currently at 0.3
  };

  outputs = { self, nixpkgs, versions, holochain, tryorama }: {
    nixosConfigurations.nuc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
      specialArgs = { 
        lair-keystore = holochain.packages.x86_64-linux.lair-keystore;
        holochain = holochain.packages.x86_64-linux.holochain;
        trycp-server = tryorama.packages.x86_64-linux.trycp-server;
      };
    };
  };
}
