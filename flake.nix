{
  description = "Vandellòs";
  inputs = {
    utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";
  };
  outputs = { self, nixpkgs, utils, zig }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      zigpkgs = zig.packages.${system};
    in
    {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          # TODO: Add QEMU
          zigpkgs.master
          gdb
          gdbgui
          grub2
          xorriso
        ];
      };
    }
  );
}
