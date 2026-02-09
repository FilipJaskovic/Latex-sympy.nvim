from __future__ import annotations

import os
from typing import Any, Optional

import latex2sympy2
import sympy as sp
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
from sympy import MatrixBase, apart, expand, expand_trig, factor, simplify

app = Flask(__name__)

IS_REAL = False
ENABLE_PYTHON_EVAL = os.getenv("LATEX_SYMPY_ENABLE_PYTHON", "0") == "1"


def _success(data: Any):
    return jsonify({"data": data, "error": ""})


def _error(message: str):
    return jsonify({"data": "", "error": str(message)})


def _get_request_payload() -> tuple[Optional[dict[str, Any]], Optional[str]]:
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return None, "Invalid JSON payload"
    return payload, None


def _coerce_data_value(payload: dict[str, Any]) -> tuple[Optional[str], Optional[str]]:
    if "data" not in payload:
        return None, "Missing 'data' field"

    value = payload["data"]
    if value is None:
        return "", None
    if not isinstance(value, str):
        value = str(value)

    return value, None


def _get_request_data() -> tuple[Optional[str], Optional[str]]:
    payload, err = _get_request_payload()
    if err:
        return None, err
    return _coerce_data_value(payload)


def _parse_expression(text: str):
    return latex2sympy(text).subs(variances)


def _parse_equation_or_zero_expression(text: str):
    if "=" in text:
        lhs_text, rhs_text = text.split("=", 1)
        if lhs_text.strip() == "" or rhs_text.strip() == "":
            raise ValueError("Equation must have both left and right sides")
        lhs_expr = _parse_expression(lhs_text)
        rhs_expr = _parse_expression(rhs_text)
        equation = sp.Eq(lhs_expr, rhs_expr)
        expression = lhs_expr - rhs_expr
        return equation, expression

    expression = _parse_expression(text)
    equation = sp.Eq(expression, 0)
    return equation, expression


def _parse_symbol(name: Any) -> Optional[sp.Symbol]:
    if name is None:
        return None

    text = str(name).strip()
    if text == "":
        return None

    try:
        parsed = latex2sympy(text)
        if isinstance(parsed, sp.Symbol):
            return parsed
    except Exception:
        pass

    return sp.Symbol(text)


def _default_symbol(free_symbols: set[sp.Symbol]) -> Optional[sp.Symbol]:
    if not free_symbols:
        return None
    return sorted(free_symbols, key=lambda symbol: symbol.name)[0]


def _symbol_from_params_or_default(params: dict[str, Any], free_symbols: set[sp.Symbol]) -> Optional[sp.Symbol]:
    explicit = _parse_symbol(params.get("var"))
    if explicit is not None:
        return explicit
    return _default_symbol(free_symbols)


def _parse_point(value: Any):
    text = str(value)
    try:
        return _parse_expression(text)
    except Exception:
        try:
            return sp.sympify(text)
        except Exception as exc:
            raise ValueError(f"Invalid point value: {text}") from exc


def _parse_positive_int(value: Any, name: str) -> int:
    try:
        parsed = int(value)
    except Exception as exc:
        raise ValueError(f"{name} must be an integer") from exc
    if parsed <= 0:
        raise ValueError(f"{name} must be positive")
    return parsed


def _as_matrix(expression):
    if isinstance(expression, MatrixBase):
        return expression
    if getattr(expression, "is_Matrix", False):
        try:
            return sp.Matrix(expression)
        except Exception as exc:
            raise ValueError("Operation requires an explicit matrix expression") from exc
    raise ValueError("Operation requires matrix input")


def _to_latex(value: Any) -> str:
    if isinstance(value, dict):
        parts = []
        for key in sorted(value.keys(), key=lambda item: _to_latex(item)):
            parts.append(f"{_to_latex(key)}: {_to_latex(value[key])}")
        return "{" + ", ".join(parts) + "}"

    if isinstance(value, (list, tuple)):
        return "[" + ", ".join(_to_latex(item) for item in value) + "]"

    if isinstance(value, set):
        items = sorted((_to_latex(item) for item in value))
        return "{" + ", ".join(items) + "}"

    try:
        return latex(value)
    except Exception:
        return str(value)


def _op_solve(data: str, params: dict[str, Any]) -> str:
    equation, expression = _parse_equation_or_zero_expression(data)
    symbol = _symbol_from_params_or_default(params, equation.free_symbols)
    if symbol is None:
        symbol = _default_symbol(expression.free_symbols)
    if symbol is None:
        raise ValueError("No variable found for solve")

    result = sp.solve(equation, symbol)
    return _to_latex(result)


def _op_diff(data: str, params: dict[str, Any]) -> str:
    expression = _parse_expression(data)
    order = _parse_positive_int(params.get("order", 1), "order")
    symbol = _symbol_from_params_or_default(params, expression.free_symbols)
    if symbol is None:
        raise ValueError("No variable found for differentiation")

    result = sp.diff(expression, symbol, order)
    return _to_latex(result)


def _op_integrate(data: str, params: dict[str, Any]) -> str:
    expression = _parse_expression(data)
    symbol = _symbol_from_params_or_default(params, expression.free_symbols)
    if symbol is None:
        raise ValueError("No variable found for integration")

    lower = params.get("lower")
    upper = params.get("upper")

    has_lower = lower is not None
    has_upper = upper is not None

    if has_lower or has_upper:
        if not (has_lower and has_upper):
            raise ValueError("Definite integration requires both lower and upper bounds")
        result = sp.integrate(expression, (symbol, _parse_point(lower), _parse_point(upper)))
    else:
        result = sp.integrate(expression, symbol)

    return _to_latex(result)


def _op_limit(data: str, params: dict[str, Any]) -> str:
    expression = _parse_expression(data)

    symbol = _parse_symbol(params.get("var"))
    if symbol is None:
        raise ValueError("limit expects a variable: limit <var> <point> [dir]")

    point_value = params.get("point")
    if point_value is None:
        raise ValueError("limit expects a point: limit <var> <point> [dir]")

    direction = str(params.get("dir", "+-")).strip()
    if direction not in {"+", "-", "+-"}:
        raise ValueError("limit direction must be one of '+', '-', '+-'")

    result = sp.limit(expression, symbol, _parse_point(point_value), dir=direction)
    return _to_latex(result)


def _op_series(data: str, params: dict[str, Any]) -> str:
    expression = _parse_expression(data)

    symbol = _parse_symbol(params.get("var"))
    if symbol is None:
        raise ValueError("series expects a variable: series <var> <point> <order>")

    point_value = params.get("point")
    if point_value is None:
        raise ValueError("series expects a point: series <var> <point> <order>")

    if "order" not in params:
        raise ValueError("series expects an order: series <var> <point> <order>")
    order = _parse_positive_int(params.get("order"), "order")

    result = sp.series(expression, symbol, _parse_point(point_value), order)
    if hasattr(result, "removeO"):
        result = result.removeO()
    return _to_latex(result)


def _op_det(data: str, _: dict[str, Any]) -> str:
    matrix = _as_matrix(_parse_expression(data))
    return _to_latex(matrix.det())


def _op_inv(data: str, _: dict[str, Any]) -> str:
    matrix = _as_matrix(_parse_expression(data))
    return _to_latex(matrix.inv())


def _op_transpose(data: str, _: dict[str, Any]) -> str:
    matrix = _as_matrix(_parse_expression(data))
    return _to_latex(matrix.T)


def _op_rank(data: str, _: dict[str, Any]) -> str:
    matrix = _as_matrix(_parse_expression(data))
    return _to_latex(matrix.rank())


def _op_eigenvals(data: str, _: dict[str, Any]) -> str:
    matrix = _as_matrix(_parse_expression(data))
    eigen_map = matrix.eigenvals()
    return _to_latex(eigen_map)


OP_HANDLERS = {
    "solve": _op_solve,
    "diff": _op_diff,
    "integrate": _op_integrate,
    "limit": _op_limit,
    "series": _op_series,
    "det": _op_det,
    "inv": _op_inv,
    "transpose": _op_transpose,
    "rank": _op_rank,
    "eigenvals": _op_eigenvals,
}


def _dispatch_operation(data: str, op_name: str, params: dict[str, Any]) -> str:
    op_key = str(op_name).strip().lower()
    if op_key == "":
        raise ValueError("Missing op")
    if op_key not in OP_HANDLERS:
        raise ValueError(f"Unsupported op: {op_key}")

    handler = OP_HANDLERS[op_key]
    return handler(data, params)


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
        result = latex(_parse_expression(data).rref()[0])
        return _success(result)
    except Exception as exc:  # pragma: no cover - defensive
        return _error(str(exc))


@app.route("/numerical", methods=["POST"])
def get_numerical():
    data, err = _get_request_data()
    if err:
        return _error(err)

    try:
        expression = _parse_expression(data)
        result = latex(simplify(expression.doit().doit()).evalf(subs=variances))
        return _success(result)
    except Exception as exc:  # pragma: no cover - defensive
        return _error(str(exc))


@app.route("/factor", methods=["POST"])
def get_factor():
    data, err = _get_request_data()
    if err:
        return _error(err)

    try:
        result = latex(factor(_parse_expression(data)))
        return _success(result)
    except Exception as exc:  # pragma: no cover - defensive
        return _error(str(exc))


@app.route("/expand", methods=["POST"])
def get_expand():
    data, err = _get_request_data()
    if err:
        return _error(err)

    try:
        result = latex(expand(apart(expand_trig(_parse_expression(data)))))
        return _success(result)
    except Exception:
        try:
            result = latex(expand(expand_trig(_parse_expression(data))))
            return _success(result)
        except Exception as exc:  # pragma: no cover - defensive
            return _error(str(exc))


@app.route("/op", methods=["POST"])
def run_operation():
    payload, err = _get_request_payload()
    if err:
        return _error(err)

    data, data_err = _coerce_data_value(payload)
    if data_err:
        return _error(data_err)

    op_name = payload.get("op")
    if not isinstance(op_name, str) or op_name.strip() == "":
        return _error("Missing 'op' field")

    params = payload.get("params", {})
    if params is None:
        params = {}
    elif isinstance(params, list):
        if len(params) == 0:
            params = {}
        else:
            return _error("'params' must be an object")
    elif not isinstance(params, dict):
        return _error("'params' must be an object")

    try:
        result = _dispatch_operation(data, op_name, params)
        return _success(result)
    except Exception as exc:
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
