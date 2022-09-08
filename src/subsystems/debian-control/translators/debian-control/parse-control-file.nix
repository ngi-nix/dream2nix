{ input ? ""
, pkgs ? import <nixpkgs> {}
, lib ? pkgs.lib
}:
let
  l = lib // builtins;

  controlFilePath = ./CONTROL.test;
  controlFileText = l.readFile controlFilePath;
  desiredHeaders = ["Source" "Build-Depends" "Depends" "Recommends" "Suggests"];

  trimSurroundingWhitespace = str:
    l.pipe str [
      (l.split "^[ \t\n]*")
      l.flatten
      l.concatStrings
      (l.split "[ \t\n]*$")
      l.flatten
      l.concatStrings
    ];

  sectionNamesAndContents = l.tail (l.split "\n([^ \t:]+):" (
    "\n" + (trimSurroundingWhitespace controlFileText)
  ));

  sectionNames = l.pipe sectionNamesAndContents [
    (l.filter l.isList)
    (l.map l.head)
  ];

  sectionContents = l.pipe sectionNamesAndContents [
    (l.filter l.isString)
    (l.map
      (str:
        l.pipe str [
          (l.splitString "\n")
          l.concatStrings
          (l.splitString ",")
          (l.map trimSurroundingWhitespace)
        ]))
  ];
  in
  {
    inherit sectionNamesAndContents sectionNames sectionContents;
  }
