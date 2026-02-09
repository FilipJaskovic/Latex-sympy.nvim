import importlib
import os
import sys
import unittest


def load_server(enable_python_eval: bool):
    os.environ["LATEX_SYMPY_ENABLE_PYTHON"] = "1" if enable_python_eval else "0"
    if "server" in sys.modules:
        del sys.modules["server"]
    return importlib.import_module("server")


class ServerOperationTests(unittest.TestCase):
    def setUp(self):
        self.server = load_server(False)
        self.client = self.server.app.test_client()

    def post_json(self, path, payload):
        return self.client.post(path, json=payload)

    def test_op_validates_payload(self):
        response = self.client.post("/op", data="not-json", content_type="text/plain")
        body = response.get_json()
        self.assertNotEqual(body["error"], "")

        response = self.post_json("/op", {"data": "x"})
        body = response.get_json()
        self.assertIn("Missing 'op'", body["error"])

    def test_op_params_list_compatibility(self):
        matrix_text = "\\begin{bmatrix}1 & 2\\\\3 & 4\\end{bmatrix}"

        empty_list_body = self.post_json("/op", {
            "data": matrix_text,
            "op": "det",
            "params": [],
        }).get_json()
        self.assertEqual(empty_list_body["error"], "")
        self.assertEqual(empty_list_body["data"], "-2")

        invalid_list_body = self.post_json("/op", {
            "data": matrix_text,
            "op": "det",
            "params": [1],
        }).get_json()
        self.assertIn("object", invalid_list_body["error"].lower())

    def test_calculus_operations(self):
        solve_body = self.post_json("/op", {
            "data": "x^2-1=0",
            "op": "solve",
            "params": {"var": "x"},
        }).get_json()
        self.assertEqual(solve_body["error"], "")
        self.assertIn("-1", solve_body["data"])
        self.assertIn("1", solve_body["data"])

        diff_body = self.post_json("/op", {
            "data": "x^3",
            "op": "diff",
            "params": {"var": "x", "order": 2},
        }).get_json()
        self.assertEqual(diff_body["error"], "")
        self.assertIn("6", diff_body["data"])

        integrate_body = self.post_json("/op", {
            "data": "x",
            "op": "integrate",
            "params": {"var": "x"},
        }).get_json()
        self.assertEqual(integrate_body["error"], "")
        self.assertIn("x^{2}", integrate_body["data"])

        limit_body = self.post_json("/op", {
            "data": "x^2",
            "op": "limit",
            "params": {"var": "x", "point": "0"},
        }).get_json()
        self.assertEqual(limit_body["error"], "")
        self.assertEqual(limit_body["data"], "0")

        series_body = self.post_json("/op", {
            "data": "\\sin(x)",
            "op": "series",
            "params": {"var": "x", "point": "0", "order": 5},
        }).get_json()
        self.assertEqual(series_body["error"], "")
        self.assertIn("x", series_body["data"])
        self.assertNotIn("O", series_body["data"])

    def test_extended_op_argument_forms(self):
        solve_multi_body = self.post_json("/op", {
            "data": "x^2-1=0",
            "op": "solve",
            "params": {"vars": ["x"]},
        }).get_json()
        self.assertEqual(solve_multi_body["error"], "")
        self.assertIn("1", solve_multi_body["data"])

        diff_chain_body = self.post_json("/op", {
            "data": "x^2 y^3",
            "op": "diff",
            "params": {"chain": [{"var": "x", "order": 1}, {"var": "y", "order": 1}]},
        }).get_json()
        self.assertEqual(diff_chain_body["error"], "")
        self.assertIn("6", diff_chain_body["data"])

        integrate_bounds_body = self.post_json("/op", {
            "data": "x y",
            "op": "integrate",
            "params": {
                "bounds": [
                    {"var": "x", "lower": "0", "upper": "1"},
                    {"var": "y", "lower": "0", "upper": "2"},
                ],
            },
        }).get_json()
        self.assertEqual(integrate_bounds_body["error"], "")
        self.assertEqual(integrate_bounds_body["data"], "1")

    def test_new_solver_operations(self):
        nsolve_body = self.post_json("/op", {
            "data": "x^2-2=0",
            "op": "nsolve",
            "params": {"var": "x", "guess": "1"},
        }).get_json()
        self.assertEqual(nsolve_body["error"], "")
        self.assertIn("1.414", nsolve_body["data"])

        dsolve_body = self.post_json("/op", {
            "data": "Derivative(y(x), x) - y(x) = 0",
            "op": "dsolve",
            "params": {"func": "y(x)"},
        }).get_json()
        self.assertEqual(dsolve_body["error"], "")
        self.assertIn("y", dsolve_body["data"])

        solve_system_body = self.post_json("/op", {
            "data": "x+y=3\nx-y=1",
            "op": "solve_system",
            "params": {"vars": ["x", "y"]},
        }).get_json()
        self.assertEqual(solve_system_body["error"], "")
        self.assertIn("2", solve_system_body["data"])
        self.assertIn("1", solve_system_body["data"])

    def test_algebra_essentials_operations(self):
        simplify_body = self.post_json("/op", {
            "data": "(x+1)^2 - (x^2+2x+1)",
            "op": "simplify",
            "params": {},
        }).get_json()
        self.assertEqual(simplify_body["error"], "")
        self.assertEqual(simplify_body["data"], "0")

        trigsimp_body = self.post_json("/op", {
            "data": "\\sin(x)^2 + \\cos(x)^2",
            "op": "trigsimp",
            "params": {},
        }).get_json()
        self.assertEqual(trigsimp_body["error"], "")
        self.assertEqual(trigsimp_body["data"], "1")

        ratsimp_body = self.post_json("/op", {
            "data": "1/x + 1/y",
            "op": "ratsimp",
            "params": {},
        }).get_json()
        self.assertEqual(ratsimp_body["error"], "")
        self.assertIn("x + y", ratsimp_body["data"])

        powsimp_body = self.post_json("/op", {
            "data": "x^a * x^b",
            "op": "powsimp",
            "params": {},
        }).get_json()
        self.assertEqual(powsimp_body["error"], "")
        self.assertIn("a + b", powsimp_body["data"])

        apart_body = self.post_json("/op", {
            "data": "(x+1)/(x*(x+2))",
            "op": "apart",
            "params": {"var": "x"},
        }).get_json()
        self.assertEqual(apart_body["error"], "")
        self.assertIn("\\frac", apart_body["data"])

        subs_body = self.post_json("/op", {
            "data": "x + y",
            "op": "subs",
            "params": {
                "assignments": [
                    {"symbol": "x", "value": "2"},
                    {"symbol": "y", "value": "3"},
                ],
            },
        }).get_json()
        self.assertEqual(subs_body["error"], "")
        self.assertEqual(subs_body["data"], "5")

    def test_algebra_essentials_validation_errors(self):
        apart_invalid_body = self.post_json("/op", {
            "data": "1/x",
            "op": "apart",
            "params": {"var": {"bad": "x"}},
        }).get_json()
        self.assertIn("symbol", apart_invalid_body["error"].lower())

        subs_missing_assignments_body = self.post_json("/op", {
            "data": "x + y",
            "op": "subs",
            "params": {},
        }).get_json()
        self.assertIn("assignments", subs_missing_assignments_body["error"].lower())

        subs_empty_assignments_body = self.post_json("/op", {
            "data": "x + y",
            "op": "subs",
            "params": {"assignments": []},
        }).get_json()
        self.assertIn("assignments", subs_empty_assignments_body["error"].lower())

        subs_bad_entry_body = self.post_json("/op", {
            "data": "x + y",
            "op": "subs",
            "params": {"assignments": [1]},
        }).get_json()
        self.assertIn("assignment", subs_bad_entry_body["error"].lower())

    def test_equation_depth_operations(self):
        solveset_body = self.post_json("/op", {
            "data": "x^2-1=0",
            "op": "solveset",
            "params": {"var": "x", "domain": "R"},
        }).get_json()
        self.assertEqual(solveset_body["error"], "")
        self.assertIn("-1", solveset_body["data"])
        self.assertIn("1", solveset_body["data"])

        linsolve_body = self.post_json("/op", {
            "data": "x+y=3\nx-y=1",
            "op": "linsolve",
            "params": {"vars": ["x", "y"]},
        }).get_json()
        self.assertEqual(linsolve_body["error"], "")
        self.assertIn("2", linsolve_body["data"])
        self.assertIn("1", linsolve_body["data"])

        nonlinsolve_body = self.post_json("/op", {
            "data": "x^2-1=0\ny-2=0",
            "op": "nonlinsolve",
            "params": {"vars": ["x", "y"]},
        }).get_json()
        self.assertEqual(nonlinsolve_body["error"], "")
        self.assertIn("2", nonlinsolve_body["data"])

        rsolve_body = self.post_json("/op", {
            "data": "a(n+1)-a(n)=0",
            "op": "rsolve",
            "params": {"func": "a(n)"},
        }).get_json()
        self.assertEqual(rsolve_body["error"], "")
        self.assertNotEqual(rsolve_body["data"], "")

        diophantine_body = self.post_json("/op", {
            "data": "2x + 3y = 5",
            "op": "diophantine",
            "params": {"vars": ["x", "y"]},
        }).get_json()
        self.assertEqual(diophantine_body["error"], "")
        self.assertIn("t_", diophantine_body["data"])

    def test_matrix_depth_and_number_theory_operations(self):
        eigenvects_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}2 & 0\\\\0 & 3\\end{bmatrix}",
            "op": "eigenvects",
            "params": {},
        }).get_json()
        self.assertEqual(eigenvects_body["error"], "")
        self.assertIn("2", eigenvects_body["data"])
        self.assertIn("3", eigenvects_body["data"])

        nullspace_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}1 & 2\\\\2 & 4\\end{bmatrix}",
            "op": "nullspace",
            "params": {},
        }).get_json()
        self.assertEqual(nullspace_body["error"], "")
        self.assertIn("\\begin{bmatrix}", nullspace_body["data"])

        charpoly_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}1 & 0\\\\0 & 2\\end{bmatrix}",
            "op": "charpoly",
            "params": {"var": "t"},
        }).get_json()
        self.assertEqual(charpoly_body["error"], "")
        self.assertIn("t", charpoly_body["data"])

        lu_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}4 & 3\\\\6 & 3\\end{bmatrix}",
            "op": "lu",
            "params": {},
        }).get_json()
        self.assertEqual(lu_body["error"], "")
        self.assertIn("[", lu_body["data"])

        qr_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}1 & 1\\\\1 & -1\\end{bmatrix}",
            "op": "qr",
            "params": {},
        }).get_json()
        self.assertEqual(qr_body["error"], "")
        self.assertIn("[", qr_body["data"])

        mat_solve_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}2 & 1 & 5\\\\1 & -1 & 1\\end{bmatrix}",
            "op": "mat_solve",
            "params": {},
        }).get_json()
        self.assertEqual(mat_solve_body["error"], "")
        self.assertIn("\\begin{bmatrix}", mat_solve_body["data"])

        isprime_body = self.post_json("/op", {
            "data": "97",
            "op": "isprime",
            "params": {},
        }).get_json()
        self.assertEqual(isprime_body["error"], "")
        self.assertEqual(isprime_body["data"], "True")

        factorint_body = self.post_json("/op", {
            "data": "360",
            "op": "factorint",
            "params": {},
        }).get_json()
        self.assertEqual(factorint_body["error"], "")
        self.assertIn("2: 3", factorint_body["data"])
        self.assertIn("3: 2", factorint_body["data"])
        self.assertIn("5: 1", factorint_body["data"])

        primerange_body = self.post_json("/op", {
            "data": "ignored",
            "op": "primerange",
            "params": {"start": 10, "stop": 20},
        }).get_json()
        self.assertEqual(primerange_body["error"], "")
        self.assertEqual(primerange_body["data"], "[11, 13, 17, 19]")

    def test_new_operations_validation_errors(self):
        solveset_domain_body = self.post_json("/op", {
            "data": "x^2-1=0",
            "op": "solveset",
            "params": {"var": "x", "domain": "Q"},
        }).get_json()
        self.assertIn("domain", solveset_domain_body["error"].lower())

        linsolve_empty_body = self.post_json("/op", {
            "data": "",
            "op": "linsolve",
            "params": {"vars": ["x"]},
        }).get_json()
        self.assertIn("equation", linsolve_empty_body["error"].lower())

        diophantine_multi_body = self.post_json("/op", {
            "data": "x+y=1\nx-y=1",
            "op": "diophantine",
            "params": {"vars": ["x", "y"]},
        }).get_json()
        self.assertIn("single equation", diophantine_multi_body["error"].lower())

        mat_solve_bad_matrix_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}1\\\\2\\end{bmatrix}",
            "op": "mat_solve",
            "params": {},
        }).get_json()
        self.assertIn("augmented matrix", mat_solve_bad_matrix_body["error"].lower())

        isprime_non_integer_body = self.post_json("/op", {
            "data": "x+1",
            "op": "isprime",
            "params": {},
        }).get_json()
        self.assertIn("integer", isprime_non_integer_body["error"].lower())

        factorint_non_integer_body = self.post_json("/op", {
            "data": "3/2",
            "op": "factorint",
            "params": {},
        }).get_json()
        self.assertIn("integer", factorint_non_integer_body["error"].lower())

        primerange_bad_body = self.post_json("/op", {
            "data": "ignored",
            "op": "primerange",
            "params": {"start": "a", "stop": 10},
        }).get_json()
        self.assertIn("integer", primerange_bad_body["error"].lower())

    def test_new_operations_defaults_and_param_guards(self):
        solveset_default_body = self.post_json("/op", {
            "data": "x^2-1=0",
            "op": "solveset",
            "params": {},
        }).get_json()
        self.assertEqual(solveset_default_body["error"], "")
        self.assertIn("-1", solveset_default_body["data"])
        self.assertIn("1", solveset_default_body["data"])

        charpoly_default_symbol_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}1 & 0\\\\0 & 2\\end{bmatrix}",
            "op": "charpoly",
            "params": {},
        }).get_json()
        self.assertEqual(charpoly_default_symbol_body["error"], "")
        self.assertIn("lambda", charpoly_default_symbol_body["data"])

        primerange_missing_stop_body = self.post_json("/op", {
            "data": "ignored",
            "op": "primerange",
            "params": {"start": 10},
        }).get_json()
        self.assertIn("primerange expects", primerange_missing_stop_body["error"].lower())

        linsolve_unexpected_param_body = self.post_json("/op", {
            "data": "x+y=3\nx-y=1",
            "op": "linsolve",
            "params": {"vars": ["x", "y"], "bad": 1},
        }).get_json()
        self.assertIn("unexpected params", linsolve_unexpected_param_body["error"].lower())

        rsolve_unexpected_param_body = self.post_json("/op", {
            "data": "a(n+1)-a(n)=0",
            "op": "rsolve",
            "params": {"func": "a(n)", "bad": 1},
        }).get_json()
        self.assertIn("unexpected params", rsolve_unexpected_param_body["error"].lower())

        mat_solve_underdetermined_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}1 & 1 & 2\\end{bmatrix}",
            "op": "mat_solve",
            "params": {},
        }).get_json()
        self.assertEqual(mat_solve_underdetermined_body["error"], "")
        self.assertIn("solution", mat_solve_underdetermined_body["data"])
        self.assertIn("params", mat_solve_underdetermined_body["data"])

    def test_planned_ops_happy_paths(self):
        div_body = self.post_json("/op", {
            "data": "x^2-1\nx-1",
            "op": "div",
            "params": {"var": "x"},
        }).get_json()
        self.assertEqual(div_body["error"], "")
        self.assertIn("quotient", div_body["data"])
        self.assertIn("remainder", div_body["data"])

        gcd_body = self.post_json("/op", {
            "data": "x^2-1\nx-1",
            "op": "gcd",
            "params": {"var": "x"},
        }).get_json()
        self.assertEqual(gcd_body["error"], "")
        self.assertIn("x - 1", gcd_body["data"])

        sqf_body = self.post_json("/op", {
            "data": "(x-1)^2*(x+2)",
            "op": "sqf",
            "params": {"var": "x"},
        }).get_json()
        self.assertEqual(sqf_body["error"], "")
        self.assertIn("x + 2", sqf_body["data"])

        groebner_body = self.post_json("/op", {
            "data": "x^2+y\nx-y",
            "op": "groebner",
            "params": {"vars": ["x", "y"], "order": "lex"},
        }).get_json()
        self.assertEqual(groebner_body["error"], "")
        self.assertIn("[", groebner_body["data"])

        resultant_body = self.post_json("/op", {
            "data": "x^2+y\nx-y",
            "op": "resultant",
            "params": {"var": "x"},
        }).get_json()
        self.assertEqual(resultant_body["error"], "")
        self.assertNotEqual(resultant_body["data"], "")

        summation_body = self.post_json("/op", {
            "data": "k",
            "op": "summation",
            "params": {"var": "k", "lower": "1", "upper": "3"},
        }).get_json()
        self.assertEqual(summation_body["error"], "")
        self.assertEqual(summation_body["data"], "6")

        product_body = self.post_json("/op", {
            "data": "k",
            "op": "product",
            "params": {"var": "k", "lower": "1", "upper": "3"},
        }).get_json()
        self.assertEqual(product_body["error"], "")
        self.assertEqual(product_body["data"], "6")

        binomial_body = self.post_json("/op", {
            "data": "ignored",
            "op": "binomial",
            "params": {"n": "5", "k": "2"},
        }).get_json()
        self.assertEqual(binomial_body["error"], "")
        self.assertEqual(binomial_body["data"], "10")

        perm_body = self.post_json("/op", {
            "data": "ignored",
            "op": "perm",
            "params": {"n": "5", "k": "2"},
        }).get_json()
        self.assertEqual(perm_body["error"], "")
        self.assertEqual(perm_body["data"], "20")

        comb_body = self.post_json("/op", {
            "data": "ignored",
            "op": "comb",
            "params": {"n": "5", "k": "2"},
        }).get_json()
        self.assertEqual(comb_body["error"], "")
        self.assertEqual(comb_body["data"], "10")

        partition_body = self.post_json("/op", {
            "data": "ignored",
            "op": "partition",
            "params": {"n": "5"},
        }).get_json()
        self.assertEqual(partition_body["error"], "")
        self.assertEqual(partition_body["data"], "7")

        subsets_body = self.post_json("/op", {
            "data": "{1,2,3}",
            "op": "subsets",
            "params": {"k": 2},
        }).get_json()
        self.assertEqual(subsets_body["error"], "")
        self.assertIn("[", subsets_body["data"])

        totient_body = self.post_json("/op", {
            "data": "9",
            "op": "totient",
            "params": {},
        }).get_json()
        self.assertEqual(totient_body["error"], "")
        self.assertEqual(totient_body["data"], "6")

        mobius_body = self.post_json("/op", {
            "data": "6",
            "op": "mobius",
            "params": {},
        }).get_json()
        self.assertEqual(mobius_body["error"], "")
        self.assertEqual(mobius_body["data"], "1")

        divisors_body = self.post_json("/op", {
            "data": "12",
            "op": "divisors",
            "params": {"proper": True},
        }).get_json()
        self.assertEqual(divisors_body["error"], "")
        self.assertIn("6", divisors_body["data"])
        self.assertNotIn("12", divisors_body["data"])

        logic_body = self.post_json("/op", {
            "data": "(A & B) | (A & ~B)",
            "op": "logic_simplify",
            "params": {"form": "simplify"},
        }).get_json()
        self.assertEqual(logic_body["error"], "")
        self.assertIn("A", logic_body["data"])

        sat_body = self.post_json("/op", {
            "data": "A & ~A",
            "op": "sat",
            "params": {},
        }).get_json()
        self.assertEqual(sat_body["error"], "")
        self.assertIn("False", sat_body["data"])

        jordan_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}2 & 1\\\\0 & 2\\end{bmatrix}",
            "op": "jordan",
            "params": {},
        }).get_json()
        self.assertEqual(jordan_body["error"], "")
        self.assertIn("P", jordan_body["data"])
        self.assertIn("J", jordan_body["data"])

        svd_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}1 & 0\\\\0 & 2\\end{bmatrix}",
            "op": "svd",
            "params": {},
        }).get_json()
        self.assertEqual(svd_body["error"], "")
        self.assertIn("U", svd_body["data"])
        self.assertIn("V", svd_body["data"])

        cholesky_body = self.post_json("/op", {
            "data": "\\begin{bmatrix}4 & 2\\\\2 & 3\\end{bmatrix}",
            "op": "cholesky",
            "params": {},
        }).get_json()
        self.assertEqual(cholesky_body["error"], "")
        self.assertIn("\\begin{bmatrix}", cholesky_body["data"])

        symbol_body = self.post_json("/op", {
            "data": "ignored",
            "op": "symbol",
            "params": {"name": "x", "assumptions": {"real": True}},
        }).get_json()
        self.assertEqual(symbol_body["error"], "")
        self.assertIn("real", symbol_body["data"])

        symbols_body = self.post_json("/op", {
            "data": "ignored",
            "op": "symbols",
            "params": {},
        }).get_json()
        self.assertEqual(symbols_body["error"], "")
        self.assertIn("x", symbols_body["data"])

        symbols_reset_body = self.post_json("/op", {
            "data": "ignored",
            "op": "symbols_reset",
            "params": {},
        }).get_json()
        self.assertEqual(symbols_reset_body["error"], "")

        geometry_body = self.post_json("/op", {
            "data": "Point(0, 0)",
            "op": "geometry",
            "params": {},
        }).get_json()
        self.assertEqual(geometry_body["error"], "")
        self.assertIn("0", geometry_body["data"])

        intersect_body = self.post_json("/op", {
            "data": "Line(Point(0, 0), Point(1, 1)); Line(Point(0, 1), Point(1, 0))",
            "op": "intersect",
            "params": {},
        }).get_json()
        self.assertEqual(intersect_body["error"], "")
        self.assertIn("1", intersect_body["data"])

        tangent_body = self.post_json("/op", {
            "data": "Circle(Point(0, 0), 5); Line(Point(5, 0), Point(5, 1))",
            "op": "tangent",
            "params": {},
        }).get_json()
        self.assertEqual(tangent_body["error"], "")
        self.assertEqual(tangent_body["data"], "True")

        similar_body = self.post_json("/op", {
            "data": "Polygon(Point(0, 0), Point(1, 0), Point(0, 1)); Polygon(Point(0, 0), Point(2, 0), Point(0, 2))",
            "op": "similar",
            "params": {},
        }).get_json()
        self.assertEqual(similar_body["error"], "")
        self.assertEqual(similar_body["data"], "True")

        units_simplify_body = self.post_json("/op", {
            "data": "2*meter + 3*meter",
            "op": "units",
            "params": {"action": "simplify"},
        }).get_json()
        self.assertEqual(units_simplify_body["error"], "")
        self.assertIn("5", units_simplify_body["data"])
        self.assertIn("\\text{m}", units_simplify_body["data"])

        units_convert_body = self.post_json("/op", {
            "data": "10*meter/second",
            "op": "units",
            "params": {"action": "convert", "target": "kilometer/hour"},
        }).get_json()
        self.assertEqual(units_convert_body["error"], "")
        self.assertIn("\\text{km}", units_convert_body["data"])
        self.assertIn("\\text{hour}", units_convert_body["data"])

        mechanics_body = self.post_json("/op", {
            "data": "Derivative(q(t), t)^2/2 - q(t)^2/2",
            "op": "mechanics",
            "params": {"action": "euler_lagrange", "qs": ["q(t)"]},
        }).get_json()
        self.assertEqual(mechanics_body["error"], "")
        self.assertIn("q{(t)}", mechanics_body["data"])
        self.assertIn("= 0", mechanics_body["data"])

        quantum_dagger_body = self.post_json("/op", {
            "data": "A*B",
            "op": "quantum",
            "params": {"action": "dagger"},
        }).get_json()
        self.assertEqual(quantum_dagger_body["error"], "")
        self.assertNotEqual(quantum_dagger_body["data"], "")

        quantum_commutator_body = self.post_json("/op", {
            "data": "A",
            "op": "quantum",
            "params": {"action": "commutator", "expr2": "B"},
        }).get_json()
        self.assertEqual(quantum_commutator_body["error"], "")

        optics_lens_body = self.post_json("/op", {
            "data": "ignored",
            "op": "optics",
            "params": {"action": "lens", "options": {"focal_length": "2", "u": "3"}},
        }).get_json()
        self.assertEqual(optics_lens_body["error"], "")
        self.assertIn("6", optics_lens_body["data"])

        optics_mirror_body = self.post_json("/op", {
            "data": "ignored",
            "op": "optics",
            "params": {"action": "mirror", "options": {"focal_length": "2", "u": "3"}},
        }).get_json()
        self.assertEqual(optics_mirror_body["error"], "")
        self.assertIn("6", optics_mirror_body["data"])

        optics_refraction_body = self.post_json("/op", {
            "data": "ignored",
            "op": "optics",
            "params": {"action": "refraction", "incident": "1", "n1": "1", "n2": "2"},
        }).get_json()
        self.assertEqual(optics_refraction_body["error"], "")
        self.assertNotEqual(optics_refraction_body["data"], "")

        pauli_body = self.post_json("/op", {
            "data": "Pauli(1)*Pauli(1)",
            "op": "pauli",
            "params": {"action": "simplify"},
        }).get_json()
        self.assertEqual(pauli_body["error"], "")
        self.assertEqual(pauli_body["data"], "1")

        dist_body = self.post_json("/op", {
            "data": "ignored",
            "op": "dist",
            "params": {"kind": "normal", "name": "X", "args": ["0", "1"]},
        }).get_json()
        self.assertEqual(dist_body["error"], "")
        self.assertIn("X", dist_body["data"])

        prob_body = self.post_json("/op", {
            "data": "X > 0",
            "op": "p",
            "params": {},
        }).get_json()
        self.assertEqual(prob_body["error"], "")
        self.assertIn("1", prob_body["data"])

        expectation_body = self.post_json("/op", {
            "data": "X",
            "op": "e",
            "params": {},
        }).get_json()
        self.assertEqual(expectation_body["error"], "")
        self.assertEqual(expectation_body["data"], "0")

        variance_body = self.post_json("/op", {
            "data": "X",
            "op": "var",
            "params": {},
        }).get_json()
        self.assertEqual(variance_body["error"], "")
        self.assertEqual(variance_body["data"], "1")

        density_body = self.post_json("/op", {
            "data": "X",
            "op": "density",
            "params": {},
        }).get_json()
        self.assertEqual(density_body["error"], "")
        self.assertIn("NormalDistribution", density_body["data"])

    def test_planned_ops_validation_errors(self):
        div_bad_body = self.post_json("/op", {
            "data": "x^2-1",
            "op": "div",
            "params": {},
        }).get_json()
        self.assertIn("two expressions", div_bad_body["error"].lower())

        resultant_bad_body = self.post_json("/op", {
            "data": "x^2-1\nx-1",
            "op": "resultant",
            "params": {},
        }).get_json()
        self.assertIn("expects 'var'", resultant_bad_body["error"].lower())

        groebner_bad_order_body = self.post_json("/op", {
            "data": "x^2+y\nx-y",
            "op": "groebner",
            "params": {"vars": ["x"], "order": "bad"},
        }).get_json()
        self.assertIn("order", groebner_bad_order_body["error"].lower())

        divisors_bad_body = self.post_json("/op", {
            "data": "12",
            "op": "divisors",
            "params": {"proper": "maybe"},
        }).get_json()
        self.assertIn("boolean", divisors_bad_body["error"].lower())

        logic_bad_form_body = self.post_json("/op", {
            "data": "A & B",
            "op": "logic_simplify",
            "params": {"form": "xor"},
        }).get_json()
        self.assertIn("form", logic_bad_form_body["error"].lower())

        symbol_bad_assumption_body = self.post_json("/op", {
            "data": "ignored",
            "op": "symbol",
            "params": {"name": "x", "assumptions": {"bad": True}},
        }).get_json()
        self.assertIn("unknown symbol assumption", symbol_bad_assumption_body["error"].lower())

        geometry_bad_body = self.post_json("/op", {
            "data": "x^2 + 1",
            "op": "geometry",
            "params": {},
        }).get_json()
        self.assertIn("geometry entities", geometry_bad_body["error"].lower())

        units_bad_action_body = self.post_json("/op", {
            "data": "meter",
            "op": "units",
            "params": {"action": "bad"},
        }).get_json()
        self.assertIn("action", units_bad_action_body["error"].lower())

        optics_bad_body = self.post_json("/op", {
            "data": "ignored",
            "op": "optics",
            "params": {"action": "lens", "options": {"focal_length": "2"}},
        }).get_json()
        self.assertIn("two options", optics_bad_body["error"].lower())

        dist_bad_kind_body = self.post_json("/op", {
            "data": "ignored",
            "op": "dist",
            "params": {"kind": "bad", "name": "X", "args": []},
        }).get_json()
        self.assertIn("kind", dist_bad_kind_body["error"].lower())

        dist_bad_arity_body = self.post_json("/op", {
            "data": "ignored",
            "op": "dist",
            "params": {"kind": "normal", "name": "X", "args": ["0"]},
        }).get_json()
        self.assertIn("expects 2", dist_bad_arity_body["error"].lower())

    def test_combinatorics_structure_ops_happy_paths(self):
        perm_group_order_body = self.post_json("/op", {
            "data": "[1,2,0]\n[1,0,2]",
            "op": "perm_group",
            "params": {"action": "order"},
        }).get_json()
        self.assertEqual(perm_group_order_body["error"], "")
        self.assertEqual(perm_group_order_body["data"], "6")

        perm_group_orbits_body = self.post_json("/op", {
            "data": "[1,2,0]\n[1,0,2]",
            "op": "perm_group",
            "params": {"action": "orbits"},
        }).get_json()
        self.assertEqual(perm_group_orbits_body["error"], "")
        self.assertIn("[0, 1, 2]", perm_group_orbits_body["data"])

        perm_group_transitive_body = self.post_json("/op", {
            "data": "[1,2,0]\n[1,0,2]",
            "op": "perm_group",
            "params": {"action": "is_transitive"},
        }).get_json()
        self.assertEqual(perm_group_transitive_body["error"], "")
        self.assertEqual(perm_group_transitive_body["data"], "True")

        perm_group_stabilizer_body = self.post_json("/op", {
            "data": "[1,2,0]\n[1,0,2]",
            "op": "perm_group",
            "params": {"action": "stabilizer", "point": 0},
        }).get_json()
        self.assertEqual(perm_group_stabilizer_body["error"], "")
        self.assertIn("order", perm_group_stabilizer_body["data"])
        self.assertIn("2", perm_group_stabilizer_body["data"])

        prufer_encode_body = self.post_json("/op", {
            "data": "[0,1]\n[1,2]\n[1,3]",
            "op": "prufer",
            "params": {"action": "encode", "n": 4},
        }).get_json()
        self.assertEqual(prufer_encode_body["error"], "")
        self.assertEqual(prufer_encode_body["data"], "[1, 1]")

        prufer_decode_body = self.post_json("/op", {
            "data": "[1,1]",
            "op": "prufer",
            "params": {"action": "decode"},
        }).get_json()
        self.assertEqual(prufer_decode_body["error"], "")
        self.assertIn("[0, 1]", prufer_decode_body["data"])
        self.assertIn("[1, 3]", prufer_decode_body["data"])

        gray_sequence_body = self.post_json("/op", {
            "data": "ignored",
            "op": "gray",
            "params": {"action": "sequence", "value": 3},
        }).get_json()
        self.assertEqual(gray_sequence_body["error"], "")
        self.assertIn("000", gray_sequence_body["data"])
        self.assertIn("111", gray_sequence_body["data"])

        gray_bin_to_gray_body = self.post_json("/op", {
            "data": "ignored",
            "op": "gray",
            "params": {"action": "bin_to_gray", "value": "1011"},
        }).get_json()
        self.assertEqual(gray_bin_to_gray_body["error"], "")
        self.assertEqual(gray_bin_to_gray_body["data"], "1110")

        gray_gray_to_bin_body = self.post_json("/op", {
            "data": "ignored",
            "op": "gray",
            "params": {"action": "gray_to_bin", "value": "1110"},
        }).get_json()
        self.assertEqual(gray_gray_to_bin_body["error"], "")
        self.assertEqual(gray_gray_to_bin_body["data"], "1011")

    def test_combinatorics_structure_validation_errors(self):
        perm_group_bad_action_body = self.post_json("/op", {
            "data": "[1,2,0]\n[1,0,2]",
            "op": "perm_group",
            "params": {"action": "bad"},
        }).get_json()
        self.assertIn("action", perm_group_bad_action_body["error"].lower())

        perm_group_bad_generator_body = self.post_json("/op", {
            "data": "[1,2]\n[x,1]",
            "op": "perm_group",
            "params": {"action": "order"},
        }).get_json()
        self.assertIn("generator", perm_group_bad_generator_body["error"].lower())

        perm_group_stabilizer_missing_point_body = self.post_json("/op", {
            "data": "[1,2,0]\n[1,0,2]",
            "op": "perm_group",
            "params": {"action": "stabilizer"},
        }).get_json()
        self.assertIn("stabilizer", perm_group_stabilizer_missing_point_body["error"].lower())

        prufer_encode_missing_n_body = self.post_json("/op", {
            "data": "[0,1]\n[1,2]\n[1,3]",
            "op": "prufer",
            "params": {"action": "encode"},
        }).get_json()
        self.assertIn("encode", prufer_encode_missing_n_body["error"].lower())

        prufer_encode_bad_edge_body = self.post_json("/op", {
            "data": "[0,1,2]\n[1,3]",
            "op": "prufer",
            "params": {"action": "encode", "n": 4},
        }).get_json()
        self.assertIn("edges", prufer_encode_bad_edge_body["error"].lower())

        prufer_decode_bad_code_body = self.post_json("/op", {
            "data": "[1,a]",
            "op": "prufer",
            "params": {"action": "decode"},
        }).get_json()
        self.assertIn("integer", prufer_decode_bad_code_body["error"].lower())

        gray_bad_action_body = self.post_json("/op", {
            "data": "ignored",
            "op": "gray",
            "params": {"action": "bad", "value": "10"},
        }).get_json()
        self.assertIn("action", gray_bad_action_body["error"].lower())

        gray_bad_binary_body = self.post_json("/op", {
            "data": "ignored",
            "op": "gray",
            "params": {"action": "bin_to_gray", "value": "10a1"},
        }).get_json()
        self.assertIn("binary", gray_bad_binary_body["error"].lower())

        gray_bad_size_body = self.post_json("/op", {
            "data": "ignored",
            "op": "gray",
            "params": {"action": "sequence", "value": 0},
        }).get_json()
        self.assertIn("positive", gray_bad_size_body["error"].lower())

    def test_matrix_operations(self):
        matrix_text = "\\begin{bmatrix}1 & 2\\\\3 & 4\\end{bmatrix}"

        det_body = self.post_json("/op", {
            "data": matrix_text,
            "op": "det",
        }).get_json()
        self.assertEqual(det_body["error"], "")
        self.assertEqual(det_body["data"], "-2")

        inv_body = self.post_json("/op", {
            "data": matrix_text,
            "op": "inv",
        }).get_json()
        self.assertEqual(inv_body["error"], "")
        self.assertIn("\\begin{bmatrix}", inv_body["data"])

        rank_body = self.post_json("/op", {
            "data": matrix_text,
            "op": "rank",
        }).get_json()
        self.assertEqual(rank_body["error"], "")
        self.assertEqual(rank_body["data"], "2")

        eig_body = self.post_json("/op", {
            "data": matrix_text,
            "op": "eigenvals",
        }).get_json()
        self.assertEqual(eig_body["error"], "")
        self.assertIn(":", eig_body["data"])

    def test_matrix_errors(self):
        singular = "\\begin{bmatrix}1 & 2\\\\2 & 4\\end{bmatrix}"
        singular_body = self.post_json("/op", {
            "data": singular,
            "op": "inv",
        }).get_json()
        self.assertNotEqual(singular_body["error"], "")

        non_matrix_body = self.post_json("/op", {
            "data": "x^2",
            "op": "det",
        }).get_json()
        self.assertIn("matrix", non_matrix_body["error"].lower())

    def test_existing_endpoints_still_work(self):
        factor_body = self.post_json("/factor", {"data": "x^2+2x+1"}).get_json()
        self.assertEqual(factor_body["error"], "")
        self.assertNotEqual(factor_body["data"], "")

        latex_body = self.post_json("/latex", {"data": "x^2+2x+1"}).get_json()
        self.assertEqual(latex_body["error"], "")
        self.assertIn("x", latex_body["data"])


class PythonEvalGateTests(unittest.TestCase):
    def test_python_endpoint_disabled_by_default(self):
        server = load_server(False)
        client = server.app.test_client()

        body = client.post("/python", json={"data": "1+1"}).get_json()
        self.assertIn("disabled", body["error"].lower())

    def test_python_endpoint_enabled_with_env(self):
        server = load_server(True)
        client = server.app.test_client()

        body = client.post("/python", json={"data": "1+1"}).get_json()
        self.assertEqual(body["error"], "")
        self.assertEqual(body["data"], "2")


if __name__ == "__main__":
    unittest.main()
