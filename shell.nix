{ pkgs ? import <nixpkgs> {}, zig }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      # TODO: Add QEMU
      zig
      gdb
      gdbgui
      grub2
      xorriso
    ];
}
