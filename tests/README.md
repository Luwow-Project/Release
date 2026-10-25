# Tests

Luwow's regression tests, in three suites:

- **script**: require resolution through `runscript`, as the [documentation](https://luwow-project.github.io/Documentation/tutorials/require/) describes it;
- **package**: the same cases compiled with `compile` and run with `runpackage`, plus the package-only ones;
- **net**: `net.request` against an HTTP server the runner starts on `127.0.0.1`, through each platform's client (WinHTTP, NSURLSession, libcurl): methods, bodies and headers, redirects, gzip, error statuses, `saveTo`, timeouts and invalid URLs.

```bash
python tests/run_tests.py
```

The runner finds `runscript`, `compile` and `runpackage` under `build/bin` (or pass `--bin <folder>`), and the module DLLs in its `libraries` folder (or `--libraries <folder>`). Without a `libraries` folder, the libraries are expected to be bound into the executables (a STATIC build). It exits with 1 when any run fails. `--suite script`, `--suite package` and `--suite net` run one suite; all three run by default. The net suite needs the `net` library. `--filter <text>` picks runs by label, `--verbose` prints every run's output and `--keep` keeps the temporary workspace.

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
| `native` | `@Luwow/fs` is the native module even though the config aliases `Luwow` to type stubs, and the config's alias still finds `@Luwow/stubonly` |
| `caching` | every path to a module gets the same value, and the module runs once |
| `errors` | bare names, undefined aliases, missing modules and modules that raise are errors, and require works after them |
| `package_names` | packages only: modules, the main script included, are named from the project's folder and found by those names through aliases, relative paths and `@self` |
| `net` | net suite only: `net.request` through the platform's HTTP client, against the runner's local server |
| `noconfig` | relative, `@self` and folder modules without a config, and config aliases are undefined |

Every run also checks the config ran exactly once (each config prints `CONFIG_RAN`), or never without one, and that nothing of the decoy was loaded.

## Adding a check

Add a `t.check(name, fn)` to a case, or a new case in `project/cases` and to the lists at the top of `run_tests.py`. Keep `require` calls in the case files: require resolves from the file that calls it.
