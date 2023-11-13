{
  inputs = {
    versions.url = "github:holochain/holochain?dir=versions/0_2";
    
    versions.inputs.holochain.url = "github:holochain/holochain/holochain-0.2.3-rc.0";
    versions.inputs.lair.url = "github:holochain/lair/lair_keystore-v0.3.0";

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
