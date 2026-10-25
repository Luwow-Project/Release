#!/usr/bin/env python3
"""
Luwow's test suites: require resolution through runscript (--suite script), packages through compile and
runpackage (--suite package), and net.request against a local HTTP server (--suite net).

Runs every case in project/cases with runscript, and compiled into a package with compile and runpackage,
from several working directories: the project's own, an unrelated one, a decoy that mirrors the project with
other modules, one spelled in another case and one reached through a symlink.

Each case prints PASS/FAIL per check and DONE <failures> at its end. A run
passes when it exits with 0, prints DONE 0 and no FAIL, runs its config exactly once (or never, without
one) and never touches the decoy.

    python tests/run_tests.py [--bin <folder with runscript>] [--libraries <module DLL folder>]
"""

import argparse
import gzip
import hashlib
import http.server
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
FIXTURE = HERE / "project"
REPO = HERE.parent
EXE = ".exe" if os.name == "nt" else ""

# Cases run with the project's config
CONFIG_CASES = ["relative", "self", "init_semantics", "aliases", "native", "caching", "errors"]
# Cases that use aliases, run again with the config in a subfolder
NESTED_CONFIG_CASES = ["self", "aliases", "native", "caching"]
# Cases run without a config
NO_CONFIG_CASES = ["noconfig"]
# Cases run as packages only, with the project's config
PACKAGE_CASES = ["package_names"]
# Cases run against the local HTTP server, with runscript
NET_CASES = ["net"]
# Cases compiled again from paths given in other ways
COMPILE_STYLE_CASES = ["aliases", "init_semantics", "package_names"]

# How compile is given a package's paths, besides relative to the project's folder:
#   dotted     ./cases/main.luau ./src ...  from the project's folder
#   absolute   /full/path/cases/main.luau   from an unrelated folder
#   subfolder  ../cases/main.luau ../src    from the project's cases folder
COMPILE_STYLES = ["dotted", "absolute", "subfolder"]

# What's compiled into a package, after its main script
PACKAGE_SOURCES = ["cases", "src", "types", "shared", "top.luau"]

ROOT_CONFIG = ".config.luau"
NESTED_CONFIG = "configs/nested.config.luau"

# What the decoy's modules and config print or are named, which no run may show
DECOY_MARKER = "decoy:"

# The dlls a STATIC build's configs get, and what the engine prints when it reads or loads them anyway
STATIC_DLLS = "./no-such-libraries"
DLL_MESSAGES = ["could not list module directory", "Could not load module", "DLL modules are not supported"]

TIMEOUT = 60


class Run:
    def __init__(self, label, args, cwd, configured):
        self.label = label
        self.args = [str(arg) for arg in args]
        self.cwd = cwd
        self.configured = configured
        self.output = ""
        self.problems = []
        self.passes = 0
        self.check_failures = 0

    @property
    def suite(self):
        return self.label.split("/", 1)[0]

    @property
    def case(self):
        return self.label.rsplit("/", 1)[-1]


class Package:
    def __init__(self, case, output, configured, kind):
        self.case = case
        self.output = output
        self.configured = configured
        self.kind = kind


def find_bin(given):
    if given:
        folder = Path(given).resolve()
        for name in ["runscript", "compile", "runpackage"]:
            if not (folder / (name + EXE)).is_file():
                sys.exit(f"{name}{EXE} isn't in {folder}")
        return folder
    build = REPO / "build" / "bin"
    for folder in [build / "Release", build / "MinSizeRel", build / "RelWithDebInfo", build / "Debug", build]:
        if (folder / ("runscript" + EXE)).is_file():
            return folder
    sys.exit("Couldn't find runscript under build/bin, pass --bin")


def write_configs(project, libraries):
    # Absolute, so the DLLs are found from any working directory and next to any package.
    dlls = json.dumps(libraries.resolve().as_posix() if libraries else STATIC_DLLS)
    for template in project.rglob("*.config.luau.in"):
        text = template.read_text(encoding="utf-8").replace("@DLLS@", dlls)
        template.with_suffix("").write_text(text, encoding="utf-8", newline="\n")
        template.unlink()


def make_decoy(decoy):
    # The project's layout with other modules and configs, anything resolved from the working directory
    # rather than the package or the config would load these
    for file in decoy.rglob("*"):
        if file.is_file() and file.name.endswith((".luau", ".lua", ".luau.in")):
            text = file.read_text(encoding="utf-8")
            text = text.replace('name = "', f'name = "{DECOY_MARKER}').replace('"CONFIG_RAN"', f'"{DECOY_MARKER}CONFIG_RAN"')
            file.write_text(text, encoding="utf-8", newline="\n")


def case_insensitive_spelling(path):
    # The same folder spelled in another case, when the file system ignores case
    swapped = str(path).swapcase()
    if swapped != str(path) and os.path.isdir(swapped):
        return Path(swapped)
    return None


def short_spelling(path):
    if os.name != "nt":
        return None
    import ctypes

    buffer = ctypes.create_unicode_buffer(32768)
    if not ctypes.windll.kernel32.GetShortPathNameW(str(path), buffer, len(buffer)):
        return None
    short = buffer.value
    return Path(short) if short.lower() != str(path).lower() else None


def try_symlink(link, target):
    try:
        os.symlink(target, link, target_is_directory=True)
        return link
    except (OSError, NotImplementedError):
        return None


def execute(run):
    try:
        result = subprocess.run(
            run.args,
            cwd=run.cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=TIMEOUT,
        )
        run.output = result.stdout.decode("utf-8", errors="replace")
        code = result.returncode
    except subprocess.TimeoutExpired as e:
        run.output = (e.stdout or b"").decode("utf-8", errors="replace")
        run.problems.append(f"timed out after {TIMEOUT}s")
        return

    lines = run.output.splitlines()
    run.passes = sum(1 for line in lines if line.startswith("PASS "))
    fails = [line for line in lines if line.startswith("FAIL ")]
    run.check_failures = len(fails)
    done = [line for line in lines if re.fullmatch(r"DONE \d+", line.strip())]
    config_runs = sum(1 for line in lines if line.strip() == "CONFIG_RAN")

    if code != 0:
        run.problems.append(f"exited with {code}")
    run.problems.extend(fails)
    if not done:
        run.problems.append("didn't finish (no DONE line)")
    elif done[-1].strip() != "DONE 0":
        run.problems.append(f"reported {done[-1].strip()[5:]} failed checks")
    if run.passes == 0:
        run.problems.append("no check passed")
    if DECOY_MARKER in run.output:
        run.problems.append("loaded the decoy in the working directory")
    for message in DLL_MESSAGES:
        if message in run.output:
            run.problems.append(f"printed \"{message}\"")

    expected_config_runs = 1 if run.configured else 0
    if config_runs != expected_config_runs:
        run.problems.append(f"config ran {config_runs} times, expected {expected_config_runs}")


# The net case's server: what each path answers, a deterministic megabyte for saveTo, and a path slow
# enough to time out
BIG_BODY = bytes(i % 251 for i in range(1024 * 1024))


class TestHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        pass

    def answer(self, status, body=b"", headers=None, send_body=True):
        self.send_response(status)
        for name, value in (headers or {}).items():
            self.send_header(name, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if send_body:
            self.wfile.write(body)

    def route(self, send_body):
        path = self.path.split("?")[0]
        if path == "/hello":
            self.answer(200, b"hello", {"Content-Type": "text/plain", "X-Test": "yes"}, send_body)
        elif path == "/redirect":
            self.answer(302, b"", {"Location": "/hello"}, send_body)
        elif path == "/gzip":
            if "gzip" not in self.headers.get("Accept-Encoding", ""):
                self.answer(406, b"the client didn't accept gzip", None, send_body)
            else:
                self.answer(200, gzip.compress(b"compressed hello"), {"Content-Encoding": "gzip"}, send_body)
        elif path == "/big":
            self.answer(200, BIG_BODY, {"Content-Type": "application/octet-stream"}, send_body)
        elif path == "/empty":
            self.answer(200, b"", None, send_body)
        elif path == "/slow":
            # Longer than WinHTTP's shortest timeout: it times out a short one after about 4 seconds
            time.sleep(6)
            self.answer(200, b"late", None, send_body)
        else:
            self.answer(404, b"nope", None, send_body)

    def do_GET(self):
        self.route(True)

    def do_HEAD(self):
        self.route(False)

    # method|body|X-Custom|Content-Type
    def echo(self):
        length = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(length) if length else b""
        text = "|".join([self.command, body.decode("utf-8", "replace"), self.headers.get("X-Custom", ""),
                         self.headers.get("Content-Type", "")])
        self.answer(200, text.encode("utf-8"))

    def do_POST(self):
        self.echo()

    def do_PUT(self):
        self.echo()


def start_server():
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), TestHandler)
    server.daemon_threads = True
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server, f"http://127.0.0.1:{server.server_address[1]}"


# The server's URL, the folder to save into and /big's digest are the script's arguments, after the config
def net_runs(bins, project, folder, url):
    runscript = bins / ("runscript" + EXE)
    arguments = [url, folder.as_posix(), hashlib.md5(BIG_BODY).hexdigest()]
    return [Run(f"net/project-cwd/{case}", [runscript, f"cases/{case}.luau", ROOT_CONFIG, *arguments], project, True) for case in NET_CASES]


def script_runs(bins, project, elsewhere, decoy, alternates, spellings):
    runscript = bins / ("runscript" + EXE)
    runs = []

    def add(variant, case, cwd, config, absolute, base=project):
        script = (base / "cases" / f"{case}.luau") if absolute else Path("cases") / f"{case}.luau"
        args = [runscript, script.as_posix()]
        if config:
            args.append((base / config).as_posix() if absolute else config)
        runs.append(Run(f"script/{variant}/{case}", args, cwd, config is not None))

    for case in CONFIG_CASES:
        add("project-cwd", case, project, ROOT_CONFIG, False)
        add("other-cwd", case, elsewhere, ROOT_CONFIG, True)
        add("decoy-cwd", case, decoy, ROOT_CONFIG, True)
        for variant, cwd in alternates:
            add(variant, case, cwd, ROOT_CONFIG, False)
        for variant, base in spellings:
            add(variant, case, elsewhere, ROOT_CONFIG, True, base)
    for case in NESTED_CONFIG_CASES:
        add("nested-config", case, project, NESTED_CONFIG, False)
        add("nested-config-other-cwd", case, elsewhere, NESTED_CONFIG, True)
    for case in NO_CONFIG_CASES:
        add("no-config", case, project, None, False)
        add("no-config-other-cwd", case, elsewhere, None, True)
        add("no-config-decoy-cwd", case, decoy, None, True)
    return runs


def compile_command(project, elsewhere, case, config, style):
    # The paths given to compile and where it runs from, in the given style
    paths = [f"cases/{case}.luau", *PACKAGE_SOURCES]
    if config:
        paths.append(config)

    if style == "dotted":
        given, cwd = [f"./{path}" for path in paths], project
    elif style == "absolute":
        given, cwd = [(project / path).as_posix() for path in paths], elsewhere
    elif style == "subfolder":
        given, cwd = [f"../{path}" for path in paths], project / "cases"
    else:
        given, cwd = paths, project

    args = []
    if config:
        args += ["-c", given.pop()]
    args += ["-s", *given]
    return args, cwd


def build_packages(bins, project, elsewhere, packages):
    compile_exe = bins / ("compile" + EXE)

    # (case, config, file name, kind)
    plans = [(case, ROOT_CONFIG, case, "") for case in CONFIG_CASES + PACKAGE_CASES]
    plans += [(case, NESTED_CONFIG, f"{case}.nested", "nested-config/") for case in NESTED_CONFIG_CASES]
    plans += [(case, None, case, "no-config/") for case in NO_CONFIG_CASES]
    for style in COMPILE_STYLES:
        plans += [(case, ROOT_CONFIG, f"{case}.{style}", f"compiled-{style}/") for case in COMPILE_STYLE_CASES]

    built = []
    failures = []
    for case, config, name, kind in plans:
        output = packages / f"{name}.pkg"
        args, cwd = compile_command(project, elsewhere, case, config, kind.removeprefix("compiled-").rstrip("/"))
        command = [str(compile_exe), *args, "-o", output.as_posix()]
        result = subprocess.run(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=TIMEOUT)
        if result.returncode != 0 or not output.is_file():
            output_text = result.stdout.decode("utf-8", errors="replace")
            failures.append((name, f"cwd: {cwd}\ncommand: {' '.join(command)}\n{output_text}"))
            continue
        built.append(Package(case, output, config is not None, kind))
    return built, failures


def package_runs(bins, packages, built, elsewhere, decoy, alternates, spellings):
    runpackage = bins / ("runpackage" + EXE)
    runs = []

    for package in built:
        prefix = f"package/{package.kind}"

        def add(variant, args, cwd):
            runs.append(Run(f"{prefix}{variant}/{package.case}", [runpackage, *args], cwd, package.configured))

        add("package-cwd", [package.output.name], packages)
        add("other-cwd", [package.output.as_posix()], elsewhere)
        add("decoy-cwd", [package.output.as_posix()], decoy)
        if not package.kind:
            for variant, cwd in alternates:
                add(variant, [package.output.name], cwd)
            for variant, base in spellings:
                add(variant, [(base / package.output.name).as_posix()], elsewhere)
    return runs


def report(runs, compile_failures, verbose, suites):
    failed = [run for run in runs if run.problems]

    for run in runs:
        status = "FAIL" if run.problems else "ok  "
        print(f"{status} {run.label} ({run.passes} checks)")
        for problem in run.problems:
            print(f"       {problem}")
        if run.problems or verbose:
            print(f"       cwd: {run.cwd}")
            print(f"       command: {' '.join(run.args)}")
            for line in run.output.splitlines():
                print(f"       | {line}")

    for name, output in compile_failures:
        print(f"FAIL compile/{name}")
        for line in output.splitlines():
            print(f"       | {line}")

    stats = suite_stats(runs, compile_failures, suites)
    print()
    for suite, counts in stats.items():
        print(
            f"{SUITE_TITLES[suite]}: {counts['runs_passed']} runs passed, {counts['runs_failed']} failed; "
            f"{counts['checks_passed']} checks passed, {counts['checks_failed']} failed"
        )

    if os.environ.get("GITHUB_ACTIONS") == "true":
        write_github_report(runs, failed, compile_failures, stats)

    return all(counts["runs_failed"] == 0 for counts in stats.values())


SUITE_TITLES = {"script": "Scripts (runscript)", "package": "Packages (compile + runpackage)", "net": "Net (net.request)"}
PLATFORM_NAMES = {"win32": "Windows", "darwin": "macOS", "linux": "Linux"}


def suite_stats(runs, compile_failures, suites):
    # Per suite: runs and the checks in them that passed and failed. A failed compile is a failed package run.
    stats = {suite: {"runs_passed": 0, "runs_failed": 0, "checks_passed": 0, "checks_failed": 0} for suite in suites}
    for run in runs:
        counts = stats[run.suite]
        counts["runs_failed" if run.problems else "runs_passed"] += 1
        counts["checks_passed"] += run.passes
        counts["checks_failed"] += run.check_failures
    if "package" in stats:
        stats["package"]["runs_failed"] += len(compile_failures)
    return stats


def write_github_report(runs, failed, compile_failures, stats):
    # An annotation per failure, counts as the step's outputs, and tables in the job's summary
    for run in failed:
        print(f"::error title=Require test failed::{run.label}: {'; '.join(run.problems)}")
    for name, _ in compile_failures:
        print(f"::error title=Require test failed::compile/{name} failed")

    outputs = os.environ.get("GITHUB_OUTPUT")
    if outputs:
        with open(outputs, "a", encoding="utf-8") as out:
            for key in ["runs_passed", "runs_failed", "checks_passed", "checks_failed"]:
                out.write(f"{key}={sum(counts[key] for counts in stats.values())}\n")

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary:
        return

    def cell(text):
        return str(text).replace("|", "\\|").replace("\n", " ")

    with open(summary, "a", encoding="utf-8") as out:
        platform = PLATFORM_NAMES.get(sys.platform, sys.platform)
        for suite, counts in stats.items():
            mark = "✅" if counts["runs_failed"] == 0 else "❌"
            out.write(f"### {mark} Tests: {SUITE_TITLES[suite]} on {platform}\n\n")
            out.write("| | Passed | Failed |\n|---|---|---|\n")
            out.write(f"| Runs | {counts['runs_passed']} | {counts['runs_failed']} |\n")
            out.write(f"| Checks | {counts['checks_passed']} | {counts['checks_failed']} |\n\n")

            # Each case's runs, across working directories, configs and compile styles
            cases = {}
            for run in runs:
                if run.suite == suite:
                    passed, failed_runs = cases.get(run.case, (0, 0))
                    cases[run.case] = (passed + (0 if run.problems else 1), failed_runs + (1 if run.problems else 0))
            out.write("<details><summary>Runs by case</summary>\n\n")
            out.write("| Case | Runs passed | Runs failed |\n|---|---|---|\n")
            for case, (passed, failed_runs) in sorted(cases.items()):
                out.write(f"| `{case}` | {passed} | {failed_runs} |\n")
            out.write("\n</details>\n\n")

            suite_failed = [run for run in failed if run.suite == suite]
            suite_compiles = compile_failures if suite == "package" else []
            if suite_failed or suite_compiles:
                out.write("| Failed run | Problems |\n|---|---|\n")
                for run in suite_failed:
                    out.write(f"| `{run.label}` | {'<br>'.join(cell(p) for p in run.problems)} |\n")
                for name, _ in suite_compiles:
                    out.write(f"| `compile/{name}` | compile failed |\n")
                out.write("\n")


def main():
    parser = argparse.ArgumentParser(description="Luwow's test suites")
    parser.add_argument("--bin", help="folder with runscript, compile and runpackage (default: found under build/bin)")
    parser.add_argument("--libraries", help="module DLL folder (default: <bin>/libraries, if it exists)")
    parser.add_argument(
        "--suite",
        choices=["all", "script", "package", "net"],
        default="all",
        help="script: runscript, package: compile and runpackage, net: net.request (default: all three)",
    )
    parser.add_argument("--filter", help="only runs whose label contains this")
    parser.add_argument("--keep", action="store_true", help="keep the temporary workspace")
    parser.add_argument("--verbose", action="store_true", help="print every run's output")
    args = parser.parse_args()

    suites = ["script", "package", "net"] if args.suite == "all" else [args.suite]
    bins = find_bin(args.bin)
    libraries = Path(args.libraries) if args.libraries else (bins / "libraries")
    if not libraries.is_dir():
        libraries = None  # A STATIC build has its libraries bound in

    print(f"Binaries:  {bins}")
    print(f"Libraries: {libraries or 'none (bound into the executables)'}")

    workspace = Path(tempfile.mkdtemp(prefix="luwow-require-"))
    print(f"Workspace: {workspace}")
    print()

    try:
        project = workspace / "project"
        packages = workspace / "packages"
        elsewhere = workspace / "elsewhere"
        decoy = workspace / "decoy"
        shutil.copytree(FIXTURE, project)
        shutil.copytree(FIXTURE, decoy)
        packages.mkdir()
        elsewhere.mkdir()
        write_configs(project, libraries)
        make_decoy(decoy)
        write_configs(decoy, libraries)

        # The project's folder reached in other ways
        def other_spellings(folder, name):
            alternates = []
            spellings = []
            spelled = case_insensitive_spelling(folder)
            if spelled:
                alternates.append(("case-cwd", spelled))
                spellings.append(("case-path", spelled))
            link = try_symlink(workspace / f"{name}-link", folder)
            if link:
                alternates.append(("symlink-cwd", link))
                spellings.append(("symlink-path", link))
            short = short_spelling(folder)
            if short:
                alternates.append(("short-cwd", short))
                spellings.append(("short-path", short))
            return alternates, spellings

        runs = []
        compile_failures = []
        if "script" in suites:
            runs += script_runs(bins, project, elsewhere, decoy, *other_spellings(project, "project"))
        # Before the packages, which move the project's sources away
        server = None
        if "net" in suites:
            downloads = workspace / "downloads"
            downloads.mkdir()
            server, url = start_server()
            runs += net_runs(bins, project, downloads, url)
        if "package" in suites:
            built, compile_failures = build_packages(bins, project, elsewhere, packages)
            runs += package_runs(bins, packages, built, elsewhere, decoy, *other_spellings(packages, "packages"))

        if args.filter:
            runs = [run for run in runs if args.filter in run.label]

        # Script runs first, then packages with the project's sources moved away
        hidden = workspace / "project-hidden"
        for run in runs:
            if run.label.startswith("package/") and project.exists():
                project.rename(hidden)
            execute(run)

        if server:
            server.shutdown()
        ok = report(runs, compile_failures, args.verbose, suites)
    finally:
        if args.keep:
            print(f"Kept {workspace}")
        else:
            shutil.rmtree(workspace, ignore_errors=True)

    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
