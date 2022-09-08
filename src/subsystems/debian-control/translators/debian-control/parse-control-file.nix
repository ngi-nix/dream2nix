{
  input ? "",
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}: let
  l = lib // builtins;

  controlFilePath = ./CONTROL.test;
  controlFileText = l.readFile controlFilePath;
  desiredHeaders = ["Source" "Build-Depends" "Depends" "Recommends" "Suggests"];
  inputHeaders = ["Build-Depends" "Depends" "Recommends" "Suggests"];

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
    (l.map trimSurroundingWhitespace)
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
    # XXX: deal with this better
    (l.map
      (strList:
        l.filter (s: (s != "")) strList))
  ];

  sectionNamesWithContents = l.listToAttrs (l.zipListsWith l.nameValuePair sectionNames sectionContents);

  packageName = l.head sectionNamesWithContents.Source;

  inputAttrsWithHeaders = l.filterAttrs (header: _: lib.any (inputHeader: header == inputHeader) inputHeaders) sectionNamesWithContents;

  allDependencies = l.unique (l.flatten (l.attrValues inputAttrsWithHeaders));

  # throw out ${...:...}
  allDependenciesWithoutLeadingDollar =
    l.filter
      (depName: (builtins.match ''\$.+'' depName) == null)
      allDependencies;

  allDependenciesWithoutVersions =
    l.map
      (depName:
        builtins.head (l.split " " depName)
        # builtins.head (builtins.match "([^ \t]+) .+" depName)
      )
      allDependenciesWithoutLeadingDollar;
in {
  inherit packageName sectionNamesAndContents sectionNames sectionContents sectionNamesWithContents inputAttrsWithHeaders allDependencies allDependenciesWithoutLeadingDollar allDependenciesWithoutVersions;
}
