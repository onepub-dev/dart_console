"""Prove the old ioctl signature fails on macOS ARM64 in an isolated copy."""
import pathlib
import platform
import re
import shutil
import subprocess
import tempfile

if platform.system() != "Darwin" or platform.machine() != "arm64":
    raise SystemExit("This control must run natively on macOS ARM64")

root = pathlib.Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="dart-console-old-ioctl-") as temporary:
    target = pathlib.Path(temporary)
    for name in ("lib", "test"):
        shutil.copytree(root / name, target / name)
    for name in ("pubspec.yaml", "pubspec.lock"):
        if (root / name).exists():
            shutil.copy2(root / name, target / name)
    binding = target / "lib/src/ffi/unix/termios.dart"
    source = binding.read_text()
    original = "VarArgs<(Pointer<WinSize>,)> winsize"
    if source.count(original) != 1:
        raise SystemExit("Expected exactly one reviewed variadic ioctl binding")
    binding.write_text(source.replace(original, "Pointer<WinSize> winsize"))
    subprocess.run(["dart", "pub", "get", "--offline"], cwd=target,
                   check=True, timeout=120)
    for mode in ("JIT", "AOT"):
        result = subprocess.run(
            ["dart", "test", "--concurrency=1", "--reporter=expanded",
             "test/window_size_test.dart", "--plain-name", f"{mode} 80x24 both"],
            cwd=target, capture_output=True, text=True, timeout=180,
        )
        output = result.stdout + result.stderr
        print(output, flush=True)
        # Accept an incorrect native result or a signal-killed helper, not an
        # unrelated build/setup failure or a timeout, as regression evidence.
        reproduced = ("Package ioctl returned incorrect dimensions" in output
                      or re.search(r"Actual: <-[0-9]+>", output))
        if result.returncode == 0 or not reproduced:
            raise SystemExit(f"Old {mode} signature did not reproduce the regression")
        print(f"Confirmed: old {mode} ioctl signature fails on macOS ARM64", flush=True)
