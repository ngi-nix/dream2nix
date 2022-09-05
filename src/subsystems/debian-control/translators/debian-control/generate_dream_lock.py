import json
import os
import pathlib


def main():
    # TODO parse versions
    VERSION = "UNKNOWN"
    NAME=os.environ.get("NAME") + "-debian-control"

    dream_lock = dict(
        sources={},
        _generic={
            "subsystem": "debian-control",
            "defaultPackage": NAME,
            "packages": {
                NAME: VERSION,
            },
            "sourcesAggregatedHash": None,
            "location": "",
        },
        _subsystem={},
    )

    dream_lock["_subsystem"] = dict(control_inputs=json.loads(os.environ.get("deps")))

    # dump dream lock to $outputFile
    outputFile = os.environ.get("outputFile")
    dirPath = pathlib.Path(os.path.dirname(outputFile))
    dirPath.mkdir(parents=True, exist_ok=True)
    with open(outputFile, "w") as lock:
        json.dump(dream_lock, lock, indent=2)


if __name__ == "__main__":
    main()
