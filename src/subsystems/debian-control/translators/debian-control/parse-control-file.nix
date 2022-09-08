{ input ? ""
, pkgs ? <nixpkgs>
, lib
}:
let
  controlFile = ./CONTROL.test;
  l = lib // builtins;
  lines = l.splitString "\n" controlFile;
  desiredHeaders = ["Source" "Build-Depends" "Depends" "Recommends" "Suggests"];
  # takeWhile = pred: list:
    # foldl' (accum: line:
    #   if pred line
    #   then [head list] ++ accum
    # else accum)

    # if list == []
    # then []
    # else if pred (head list)
    # then [head list] ++ takeWhile pred (tail list)

  # foldl' () lines
  in
  {

  }
