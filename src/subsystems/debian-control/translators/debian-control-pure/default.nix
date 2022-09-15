{
  dlib,
  lib,
  ...
}: let
  l = lib // builtins;
in {
  type = "pure";

  /*
  Automatically generate unit tests for this translator using project sources
  from the specified list.

  !!! Your first action should be adding a project here. This will simplify
  your work because you will be able to use `nix run .#tests-unit` to
  test your implementation for correctness.
  */
  generateUnitTestsForProjects = [
    (builtins.fetchTarball {
      url = "https://github.com/pop-os/launcher/tarball/6e2fa02e819435f0ce0693baeb5d7907c7fd9719";
      sha256 = "0rz48c92b11x0mn9ji55rlxb910mhky7jdlfnyr7ibqz4s6b9bd3";
    })
  ];

  /*
  Allow dream2nix to detect if a given directory contains a project
  which can be translated with this translator.
  Usually this can be done by checking for the existence of specific
  file names or file endings.

  Alternatively a fully featured discoverer can be implemented under
  `src/subsystems/{subsystem}/discoverers`.
  This is recommended if more complex project structures need to be
  discovered like, for example, workspace projects spanning over multiple
  sub-directories

  If a fully featured discoverer exists, do not define `discoverProject`.
  */
  discoverProject = tree:
  # Example
  # Returns true if given directory contains a file ending with .cabal
    l.any
    (filename: l.hasSuffix ".control" filename)
    (l.attrNames tree.files);

  # translate from a given source and a project specification to a dream-lock.
  translate = {translatorName, ...}: {
    /*
    A list of projects returned by `discoverProjects`
    Example:
    [
    {
    "dreamLockPath": "packages/optimism/dream-lock.json",
    "name": "optimism",
    "relPath": "",
    "subsystem": "nodejs",
    "subsystemInfo": {
    "workspaces": [
    "packages/common-ts",
    "packages/contracts",
    "packages/core-utils",
    ]
    },
    "translator": "yarn-lock",
    "translators": [
    "yarn-lock",
    "package-json"
    ]
    }
    ]
    */
    project,
    /*
    Entire source tree represented as deep attribute set.
    (produced by `prepareSourceTree`)

    This has the advantage that files will only be read once, even when
    accessed multiple times or by multiple translators.

    Example:
    {
    files = {
    "package.json" = {
    relPath = "package.json"
    fullPath = "${source}/package.json"
    content = ;
    jsonContent = ;
    tomlContent = ;
    }
    };

    directories = {
    "packages" = {
    relPath = "packages";
    fullPath = "${source}/packages";
    files = {

    };
    directories = {

    };
    };
    };

    # returns the tree object of the given sub-path
    getNodeFromPath = path: ...
    }
    */
    tree,
    # arguments defined in `extraArgs` (see below) specified by user
    extraInputs,
    excludedInputs,
    ...
  } @ args: let
    # get the root source and project source
    rootSource = tree.fullPath;
    projectSource = "${tree.fullPath}/${project.relPath}";
    projectTree = tree.getNodeFromPath project.relPath;

    controlFilePath = rootSource + "debian/control";
    controlFileText = l.readFile controlFilePath;

    parsedControlFile = import ./parse-control-file.nix {
      inherit lib;
      input = controlFileText;
    };

    debnixMap = builtins.fromJSON (builtins.readFile ./debnix.json);

    controlInputs =
      let excludedInputsList = l.splitString " " excludedInputs;
      in
      l.pipe parsedControlFile.allDependenciesWithTrimmedVersions [
        (l.filter (debianName: builtins.hasAttr debianName debnixMap))
        (l.map (debianName: builtins.getAttr debianName debnixMap))
        (l.filter (nixName: ! (builtins.elem nixName excludedInputsList)))
      ]
    ++ l.splitString " " extraInputs;
  in
    dlib.simpleTranslate2.translate
    ({objectsByKey, ...}: rec {
      inherit translatorName;

      # relative path of the project within the source tree.
      location = project.relPath;

      # the name of the subsystem
      subsystemName = "debian-control";

      # Extract subsystem specific attributes.
      # The structure of this should be defined in:
      #   ./src/specifications/{subsystem}
      subsystemAttrs = {
        control_inputs = controlInputs;
      };

      # name of the default package
      defaultPackage = parsedControlFile.packageName;

      /*
      List the package candidates which should be exposed to the user.
      Only top-level packages should be listed here.
      Users will not be interested in all individual dependencies.
      */
      exportedPackages = {
        "${defaultPackage}" = "1.1.0";
      };

      /*
      a list of raw package objects
      If the upstream format is a deep attrset, this list should contain
      a flattened representation of all entries.
      */
      serializedRawObjects = controlInputs;

      /*
      Define extractor functions which each extract one property from
      a given raw object.
      (Each rawObj comes from serializedRawObjects).

      Extractors can access the fields extracted by other extractors
      by accessing finalObj.
      */
      extractors = {
        name = rawObj: finalObj:
          rawObj;
        # example
        # "foo";

        version = rawObj: finalObj:
        # example
        "1.2.3";

        dependencies = rawObj: finalObj:
        # example
        [];

        sourceSpec = rawObj: finalObj:
        # example
        {
          type = "http";
          # url = "https://registry.npmjs.org/${finalObj.name}/-/${finalObj.name}-${finalObj.version}.tgz";
          url = "pkgs.''${finalObj.name}";
          # hash = "sha1-4h3xCtbCBTKVvLuNq0Cwnb6ofk0=";
        };
      };

      /*
      Optionally define extra extractors which will be used to key all
      final objects, so objects can be accessed via:
      `objectsByKey.${keyName}.${value}`
      */
      keys = {
        /*
        This is an example. Remove this completely or replace in case you
        need a key.
        */
        sanitizedName = rawObj: finalObj:
          l.strings.sanitizeDerivationName rawObj.name;
      };

      /*
      Optionally add extra objects (list of `finalObj`) to be added to
      the dream-lock.
      */
      #   extraObjects = [
      #     {
      #       name = "foo2";
      #       version = "1.0";
      #       dependencies = [
      #         {
      #           name = "bar2";
      #           version = "1.1";
      #         }
      #       ];
      #       sourceSpec = {
      #         type = "git";
      #         url = "https://...";
      #         rev = "...";
      #       };
      #     }
      #   ];
    });

  # If the translator requires additional arguments, specify them here.
  # Users will be able to set these arguments via `settings`.
  # There are only two types of arguments:
  #   - string argument (type = "argument")
  #   - boolean flag (type = "flag")
  # String arguments contain a default value and examples. Flags do not.
  # Flags are false by default.
  extraArgs = {
    extraInputs = {
      description = "A space-separated string of nixpkgs inputs.";
      type = "argument";
      examples = [
        "xorg.libx11 libadwaita"
      ];
    };

    excludedInputs = {
      description = "A space-separated string of nixpkgs inputs to exclude.";
      type = "argument";
      examples = [
        "xorg.libx11 libadwaita"
      ];
    };

    # Example: boolean option
    # Flags always default to 'false' if not specified by the user
    # noDev = {
    #   description = "Exclude dev dependencies";
    #   type = "flag";
    # };
    #
    # # Example: string option
    # theAnswer = {
    #   default = "42";
    #   description = "The Answer to the Ultimate Question of Life";
    #   examples = [
    #     "0"
    #     "1234"
    #   ];
    #   type = "argument";
    # };
  };
}
