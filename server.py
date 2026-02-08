from __future__ import annotations

import os
from typing import Any, Optional

import latex2sympy2
from flask import Flask, jsonify, request
from latex2sympy2 import (
    latex,
    latex2latex,
    latex2sympy,
    set_real,
    set_variances,
    var,
    variances,
)
from sympy import apart, expand, expand_trig, factor, simplify

app = Flask(__name__)

IS_REAL = False
ENABLE_PYTHON_EVAL = os.getenv("LATEX_SYMPY_ENABLE_PYTHON", "0") == "1"


def _success(data: Any):
    return jsonify({"data": data, "error": ""})


def _error(message: str):
    return jsonify({"data": "", "error": str(message)})


def _get_request_data() -> tuple[Optional[str], Optional[str]]:
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return None, "Invalid JSON payload"
    if "data" not in payload:
        return None, "Missing 'data' field"

    value = payload["data"]
    if value is None:
        return "", None
    if not isinstance(value, str):
        value = str(value)

    return value, None


@app.route("/")
def main():
    return "Latex Sympy Calculator Server"


@app.route("/health", methods=["GET"])
def health():
    return _success("ok")


@app.route("/latex", methods=["POST"])
def get_latex():
    data, err = _get_request_data()
    if err:
        return _error(err)

    try:
        return _success(latex2latex(data))
    except Exception as exc:  # pragma: no cover - defensive
        return _error(str(exc))


@app.route("/matrix-raw-echelon-form", methods=["POST"])
def get_matrix_raw_echelon_form():
    data, err = _get_request_data()
    if err:
        return _error(err)

    try:
        result = latex(latex2sympy(data).subs(variances).rref()[0])
        return _success(result)
    except Exception as exc:  # pragma: no cover - defensive
        return _error(str(exc))


@app.route("/numerical", methods=["POST"])
def get_numerical():
    data, err = _get_request_data()
    if err:
        return _error(err)

    try:
        result = latex(simplify(latex2sympy(data).subs(variances).doit().doit()).evalf(subs=variances))
        return _success(result)
    except Exception as exc:  # pragma: no cover - defensive
        return _error(str(exc))


@app.route("/factor", methods=["POST"])
def get_factor():
    data, err = _get_request_data()
    if err:
        return _error(err)

    try:
        result = latex(factor(latex2sympy(data).subs(variances)))
        return _success(result)
    except Exception as exc:  # pragma: no cover - defensive
        return _error(str(exc))


@app.route("/expand", methods=["POST"])
def get_expand():
    data, err = _get_request_data()
    if err:
        return _error(err)

    try:
        result = latex(expand(apart(expand_trig(latex2sympy(data).subs(variances)))))
        return _success(result)
    except Exception:
        try:
            result = latex(expand(expand_trig(latex2sympy(data).subs(variances))))
            return _success(result)
        except Exception as exc:  # pragma: no cover - defensive
            return _error(str(exc))


@app.route("/variances", methods=["GET"])
def get_variances():
    result = {}
    for key in var:
        result[str(key)] = str(var[key])
    return _success(result)


@app.route("/reset", methods=["GET"])
def reset():
    set_variances({})
    global var
    var = latex2sympy2.var
    return _success({"success": True})


@app.route("/complex", methods=["GET"])
def complex_numbers_toggle():
    global IS_REAL
    IS_REAL = not IS_REAL
    set_real(True if IS_REAL else None)
    return _success({"success": True, "value": IS_REAL})


@app.route("/python", methods=["POST"])
def run_python():
    if not ENABLE_PYTHON_EVAL:
        return _error("Python eval is disabled. Enable with LATEX_SYMPY_ENABLE_PYTHON=1")

    data, err = _get_request_data()
    if err:
        return _error(err)

    try:
        rv = eval(data)
        return _success(str(rv))
    except Exception as exc:  # pragma: no cover - defensive
        return _error(str(exc))


if __name__ == "__main__":
    port = int(os.getenv("LATEX_SYMPY_PORT", "7395"))
    app.run(host="127.0.0.1", port=port)
