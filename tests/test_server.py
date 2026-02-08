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
