{
  input,
  lib,
}: let
  l = lib // builtins;

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
    "\n" + (trimSurroundingWhitespace input)
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

  inputAttrsWithHeaders = l.filterAttrs (header: _: builtins.elem header inputHeaders) sectionNamesWithContents;

  allDependencies = l.unique (l.flatten (l.attrValues inputAttrsWithHeaders));

  # Throw out ${...:...}
  # XXX: There is probably a better way to do this
  allDependenciesWithoutLeadingDollar =
    l.filter
    (depName: (builtins.match ''\$.+'' depName) == null)
    allDependencies;

  allDependenciesWithTrimmedVersions =
    l.map
    (depName:
      builtins.head (l.split " " depName))
    allDependenciesWithoutLeadingDollar;
in {
  inherit packageName sectionNamesAndContents sectionNames sectionContents sectionNamesWithContents inputAttrsWithHeaders allDependencies allDependenciesWithoutLeadingDollar allDependenciesWithTrimmedVersions;
}
