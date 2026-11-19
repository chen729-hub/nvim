"""Run with python3 tests/utftex-compat.py; requires the installed utftex."""
import os
from pathlib import Path
import runpy
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / "scripts/utftex-compat"
NORMALIZE = runpy.run_path(str(WRAPPER))["normalize"]
UPSTREAM = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / os.environ.get("NVIM_APPNAME", "nvim") / "lazy/libtexprintf/src/utftex"


class Compatibility(unittest.TestCase):
    def test_nested_groups_and_exact_control_sequences(self):
        self.assertEqual(NORMALIZE(r"\mathbin{\frac{a}{b}}"), r"{\frac{a}{b}}")
        for literal in [r"\\mathbin{a}", r"\mathbinary{a}", r"\mathbin x", r"\frac{a}{b}"]:
            self.assertEqual(NORMALIZE(literal), literal)

    def run_converter(self, source):
        return subprocess.run([str(WRAPPER)], input=source, text=True, capture_output=True,
                              env={**os.environ, "NVIM_MATH_UTF_TEX": str(UPSTREAM)})

    def test_des_formula(self):
        result = self.run_converter(r"C = \mathrm{IP}^{-1}(R_{16} \mathbin{\|} L_{16})")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "C = IP⁻¹(R₁₆ ‖ L₁₆)")

    def test_gcd_formulas(self):
        for source, expected in [
            (r"\gcd(a,b)=1", "gcd(a,b)=1"),
            (r"\gcd(12, 8) = 4", "gcd(12, 8) = 4"),
            (r"\gcd(a, b) = \gcd(b, a \bmod b)", "gcd(a, b) = gcd(b, a mod b )"),
        ]:
            with self.subTest(source=source):
                result = self.run_converter(source)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), expected)
        for literal in [r"\\gcd(a,b)", r"\gcdextra(a,b)"]:
            self.assertEqual(NORMALIZE(literal), literal)

    def test_gcd_with_unknown_command_still_fails(self):
        self.assertNotEqual(self.run_converter(r"\gcd(a,\notARealCommand)").returncode, 0)

    def test_nested_fraction(self):
        result = self.run_converter(r"\mathbin{\frac{a}{b}}")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("─", result.stdout)

    def test_boxed_rsa_formulas(self):
        source = r"\boxed{c=m^e\bmod n}\qquad" + "\n" + r"\boxed{m=c^d\bmod n}"
        result = self.run_converter(source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count("┌"), 2)
        self.assertEqual(result.stdout.count("└"), 2)
        self.assertIn("c=mᵉmod n", result.stdout)
        self.assertIn("m=cᵈmod n", result.stdout)

    def test_boxed_nested_content(self):
        for source in [r"\boxed{\frac{a}{b}}", r"\boxed{\boxed{\gcd(a,b)}}",
                       r"\boxed{\{x\}}"]:
            with self.subTest(source=source):
                result = self.run_converter(source)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("┌", result.stdout)
                self.assertIn("└", result.stdout)

    def test_boxed_exact_commands_and_invalid_content(self):
        for literal in [r"\\boxed{x}", r"\boxedextra{x}", r"\boxed x", r"\boxed{x"]:
            self.assertEqual(NORMALIZE(literal), literal)
        self.assertNotEqual(self.run_converter(r"\boxed{\notARealCommand}").returncode, 0)

    def test_unrelated_errors_still_fail(self):
        result = self.run_converter(r"\mathbin{\notARealCommand}")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotEqual(self.run_converter(r"\notARealCommand").returncode, 0)


if __name__ == "__main__":
    unittest.main()
