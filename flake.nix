{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    d.url = "github:nix-community/disko";
    d.inputs.nixpkgs.follows = "nixpkgs";

    p.url = "github:nix-community/preservation";

    hm.url = "github:nix-community/home-manager";
    hm.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, ... } @ inputs : {
    nixosConfigurations.framezork = nixpkgs.lib.nixosSystem {
      specialArgs = inputs // { hostname = "framezork"; };
      modules = [ ./config.nix ];
    };
  };
}
