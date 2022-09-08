{ input ? ""
, pkgs ? <nixpkgs>
, lib
}:
let
  controlFile = ./CONTROL.test;
  l = lib // builtins;
  lines = l.splitString "\n" controlFile;
  foldl' () lines
  in
  {

  }
