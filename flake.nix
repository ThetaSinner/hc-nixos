{
  inputs = {
    versions.url = "github:holochain/holochain?dir=versions/0_2_rc";
    
    versions.inputs.holochain.url = "github:holochain/holochain/holochain-0.2.5-rc.1";
    versions.inputs.lair.url = "github:holochain/lair/lair_keystore-v0.4.1";

    holochain = {
      url = "github:holochain/holochain";
      inputs.versions.follows = "versions";
    };    
  };

  outputs = { self, nixpkgs, versions, holochain }: {
    nixosConfigurations.nuc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
      specialArgs = { 
        lair-keystore = holochain.packages.x86_64-linux.lair-keystore;
        holochain = holochain.packages.x86_64-linux.holochain;
      };
    };
  };
}
