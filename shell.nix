{ pkgs ? import <nixpkgs> {}, zig }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      zig
      gdb
      grub2
      xorriso
    ];
}
