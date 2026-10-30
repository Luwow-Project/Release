# Tests

Luwow's regression tests, in two suites:

- **script**: require resolution through `runscript`, as the [documentation](https://luwow-project.github.io/Documentation/tutorials/require/) describes it;
- **package**: the same cases compiled with `compile` and run with `runpackage`, plus the package-only ones.

```bash
python tests/run_tests.py
```

The runner finds `runscript`, `compile` and `runpackage` under `build/bin` (or pass `--bin <folder>`), and the test library in its `libraries` folder (or `--libraries <folder>`). It exits with 1 when any run fails. `--suite script` and `--suite package` run one suite; both run by default. `--filter <text>` picks runs by label, `--verbose` prints every run's output and `--keep` keeps the temporary workspace.

## The SDK test library

The `native` case loads `sdktest`, a library in `sdk/` built the way the library repository builds them, against an installed SDK, not this repository's sources. Its checks call into the executable's Luau, use a `Userdata.h` object and reach the host through `ILuauHost`, so they fail when the SDK and the executables disagree. Without the library the `native` case is skipped.

```bash
cmake --install build --config Release --prefix sdk --component sdk
cmake -S tests/sdk -B build-sdk -D CMAKE_BUILD_TYPE=Release -D LuwowSDK_DIR=<absolute path>/sdk/cmake
cmake --build build-sdk --config Release
python tests/run_tests.py --libraries build-sdk/libraries/Release   # build-sdk/libraries with single-config generators
```

A STATIC build binds it in instead, with `-D LUWOW_LIBRARY_MODE=STATIC -D LUWOW_LIBRARY_DIRS=<folder>` and a `CMakeLists.txt` there calling `luwow_add_library` on `tests/sdk/SdkTest.cpp`. Pass `--libraries` an empty folder then, so the `native` case runs.

## What runs

Each case in `project/cases` is run:

- with `runscript`, from the project's folder, from an unrelated folder, from a decoy folder, from the project's folder spelled in another case (where the file system ignores case) and through a symlink to it (where symlinks can be made);
- compiled into a package, with `runpackage`, from the package's folder, from an unrelated folder, from the decoy, and the same other spellings.

The decoy mirrors the project's layout, configs included, with other modules: a run that resolves anything from its working directory loads one of them, and fails. The alias cases run again with `configs/nested.config.luau`, a config in a subfolder, and `noconfig` runs without a config. Some cases are also compiled from paths given with `./`, as absolute paths and from the `cases` subfolder, which must make no difference to the package.

| Case | Covers |
|---|---|
| `relative` | `./` and `../` from the calling file, in required modules, normalized paths |
| `self` | `@self` in the main script, in regular modules, in modules found through an alias |
| `init_semantics` | folder modules: `init.luau` and `init.lua`, `@self` is the folder, `./` its parent, `../` up from there, requires inside an init's functions, nested folder modules, a folder without an init |
| `aliases` | config aliases to folders and folder modules, subfolders, relative requires inside aliased modules, aliases from nested modules, aliases worked out by the config's code |
| `native` | `@Luwow/sdktest` is the native module even though the config aliases `Luwow` to type stubs, the config's alias still finds `@Luwow/stubonly` |
| `caching` | every path to a module gets the same value, and the module runs once |
| `errors` | bare names, undefined aliases, missing modules and modules that raise are errors, and require works after them |
| `package_names` | packages only: modules, the main script included, are named from the project's folder and found by those names through aliases, relative paths and `@self` |
| `noconfig` | relative, `@self` and folder modules without a config, and config aliases are undefined |

Every run also checks the config ran exactly once (each config prints `CONFIG_RAN`), or never without one, and that nothing of the decoy was loaded.

## Adding a check

Add a `t.check(name, fn)` to a case, or a new case in `project/cases` and to the lists at the top of `run_tests.py`. Keep `require` calls in the case files: require resolves from the file that calls it.
