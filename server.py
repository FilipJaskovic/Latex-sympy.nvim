from __future__ import annotations

import os
from typing import Any, Callable, Optional

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
from sympy.functions.combinatorial.numbers import nC, nP
from sympy.geometry import Circle, Ellipse, Line, Point, Polygon, Ray, Segment
from sympy.geometry.entity import GeometryEntity
from sympy.geometry.util import intersection
from sympy.physics import optics as sp_optics
from sympy.physics import paulialgebra as sp_pauli
from sympy.physics import quantum as sp_quantum
from sympy.physics.units import util as units_util
from sympy.utilities.iterables import subsets as iter_subsets
from sympy import MatrixBase, apart, expand, expand_trig, factor, powsimp, ratsimp, simplify, trigsimp
import sympy.physics.units as sp_units
import sympy.stats as sp_stats

app = Flask(__name__)

IS_REAL = False
ENABLE_PYTHON_EVAL = os.getenv("LATEX_SYMPY_ENABLE_PYTHON", "0") == "1"
SOLVESET_DOMAINS = {
    "C": sp.S.Complexes,
    "R": sp.S.Reals,
    "Z": sp.S.Integers,
    "N": sp.S.Naturals,
}
GROEBNER_ORDERS = {"lex", "grlex", "grevlex"}
LOGIC_FORMS = {"simplify", "cnf", "dnf"}
SYMBOL_ASSUMPTION_KEYS = {"commutative", "real", "integer", "positive", "nonnegative"}
DISTRIBUTION_KINDS = {"normal", "uniform", "bernoulli", "binomial", "hypergeometric"}
OPTICS_OPTION_KEYS = {"focal_length", "u", "v"}

REGISTERED_SYMBOLS: dict[str, sp.Symbol] = {}
REGISTERED_SYMBOL_ASSUMPTIONS: dict[str, dict[str, bool]] = {}
REGISTERED_RANDOM_VARIABLES: dict[str, Any] = {}

SYMPIFY_BASE_LOCALS: dict[str, Any] = {
    "Point": Point,
    "Line": Line,
    "Ray": Ray,
    "Segment": Segment,
    "Ellipse": Ellipse,
    "Circle": Circle,
    "Polygon": Polygon,
    "Pauli": sp_pauli.Pauli,
}
SYMPIFY_UNIT_LOCALS: dict[str, Any] = {
    name: value for name, value in vars(sp_units).items() if not name.startswith("_")
}


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


def _build_sympify_locals(*, include_units: bool = False) -> dict[str, Any]:
    locals_map: dict[str, Any] = dict(SYMPIFY_BASE_LOCALS)
    locals_map.update(REGISTERED_SYMBOLS)
    locals_map.update(REGISTERED_RANDOM_VARIABLES)
    if include_units:
        locals_map.update(SYMPIFY_UNIT_LOCALS)
    return locals_map


def _apply_registered_symbols(expression: Any):
    free_symbols = getattr(expression, "free_symbols", set())
    if not free_symbols:
        return expression
    replacements = {
        symbol: REGISTERED_SYMBOLS[symbol.name]
        for symbol in free_symbols
        if symbol.name in REGISTERED_SYMBOLS
    }
    if not replacements:
        return expression
    return expression.subs(replacements)


def _apply_registered_random_variables(expression: Any):
    free_symbols = getattr(expression, "free_symbols", set())
    if not free_symbols:
        return expression
    replacements = {
        symbol: REGISTERED_RANDOM_VARIABLES[symbol.name]
        for symbol in free_symbols
        if symbol.name in REGISTERED_RANDOM_VARIABLES
    }
    if not replacements:
        return expression
    return expression.subs(replacements)


def _sympify_with_locals(text: str, *, include_units: bool = False):
    return sp.sympify(text, locals=_build_sympify_locals(include_units=include_units))


def _parse_expression(text: str):
    expression = latex2sympy(text).subs(variances)
    expression = _apply_registered_symbols(expression)
    expression = _apply_registered_random_variables(expression)
    return expression


def _parse_expression_with_fallback(text: str):
    try:
        return _parse_expression(text)
    except Exception:
        try:
            expression = _sympify_with_locals(text)
            expression = _apply_registered_symbols(expression)
            expression = _apply_registered_random_variables(expression)
            return expression
        except Exception as exc:
            raise ValueError(f"Could not parse expression: {text}") from exc


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


def _parse_equation_or_zero_expression_with_fallback(text: str):
    if "=" in text:
        lhs_text, rhs_text = text.split("=", 1)
        if lhs_text.strip() == "" or rhs_text.strip() == "":
            raise ValueError("Equation must have both left and right sides")
        lhs_expr = _parse_expression_with_fallback(lhs_text)
        rhs_expr = _parse_expression_with_fallback(rhs_text)
        equation = sp.Eq(lhs_expr, rhs_expr)
        expression = lhs_expr - rhs_expr
        return equation, expression

    expression = _parse_expression_with_fallback(text)
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


def _parse_symbol_list(values: Any, field_name: str) -> list[sp.Symbol]:
    if values is None:
        return []
    if not isinstance(values, list):
        raise ValueError(f"'{field_name}' must be an array")

    symbols: list[sp.Symbol] = []
    for value in values:
        symbol = _parse_symbol(value)
        if symbol is None:
            raise ValueError(f"Invalid symbol in '{field_name}'")
        symbols.append(symbol)
    return symbols


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


def _parse_function_target(value: Any):
    if value is None:
        return None

    text = str(value).strip()
    if text == "":
        return None

    try:
        return latex2sympy(text)
    except Exception:
        try:
            return sp.sympify(text)
        except Exception as exc:
            raise ValueError(f"Invalid function target: {text}") from exc


def _split_equation_inputs(text: str) -> list[str]:
    parts: list[str] = []
    normalized = text.replace("\r\n", "\n").replace("\r", "\n")
    for line in normalized.split("\n"):
        for segment in line.split(";"):
            candidate = segment.strip()
            if candidate:
                parts.append(candidate)
    return parts


def _parse_positive_int(value: Any, name: str) -> int:
    try:
        parsed = int(value)
    except Exception as exc:
        raise ValueError(f"{name} must be an integer") from exc
    if parsed <= 0:
        raise ValueError(f"{name} must be positive")
    return parsed


def _parse_int_value(value: Any, name: str) -> int:
    try:
        return int(value)
    except Exception as exc:
        raise ValueError(f"{name} must be an integer") from exc


def _parse_bool_value(value: Any, name: str) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        token = value.strip().lower()
        if token in {"true", "1", "yes"}:
            return True
        if token in {"false", "0", "no"}:
            return False
    raise ValueError(f"{name} must be a boolean")


def _ensure_allowed_params(params: dict[str, Any], op_name: str, allowed: set[str]):
    unexpected = [str(key) for key in params.keys() if str(key) not in allowed]
    if unexpected:
        suffix = ", ".join(sorted(unexpected))
        raise ValueError(f"{op_name} got unexpected params: {suffix}")


def _parse_symbol_param(value: Any, field_name: str) -> Optional[sp.Symbol]:
    if value is None:
        return None
    if isinstance(value, (dict, list)):
        raise ValueError(f"'{field_name}' must be a symbol string")

    symbol = _parse_symbol(value)
    if symbol is None:
        raise ValueError(f"Invalid symbol in '{field_name}'")
    return symbol


def _parse_required_symbol_param(params: dict[str, Any], field_name: str, op_name: str) -> sp.Symbol:
    symbol = _parse_symbol_param(params.get(field_name), field_name)
    if symbol is None:
        raise ValueError(f"{op_name} expects '{field_name}'")
    return symbol


def _parse_substitution_assignments(params: dict[str, Any]) -> dict[Any, Any]:
    assignments = params.get("assignments")
    if not isinstance(assignments, list) or len(assignments) == 0:
        raise ValueError("subs expects non-empty 'assignments' array")

    substitutions: dict[Any, Any] = {}
    for index, assignment in enumerate(assignments, start=1):
        if not isinstance(assignment, dict):
            raise ValueError(f"subs assignment #{index} must be an object")

        if "symbol" not in assignment or "value" not in assignment:
            raise ValueError(f"subs assignment #{index} must include 'symbol' and 'value'")

        symbol_text = str(assignment.get("symbol", "")).strip()
        value_text = str(assignment.get("value", "")).strip()
        if symbol_text == "" or value_text == "":
            raise ValueError(f"subs assignment #{index} must include non-empty 'symbol' and 'value'")

        symbol_expr = _parse_expression_with_fallback(symbol_text)
        value_expr = _parse_expression_with_fallback(value_text)
        substitutions[symbol_expr] = value_expr

    return substitutions


def _parse_solveset_domain(value: Any):
    if value is None:
        return SOLVESET_DOMAINS["C"]

    key = str(value).strip().upper()
    if key == "":
        return SOLVESET_DOMAINS["C"]

    domain = SOLVESET_DOMAINS.get(key)
    if domain is None:
        raise ValueError("solveset domain must be one of: C, R, Z, N")
    return domain


def _split_expression_inputs(text: str, op_name: str, *, min_count: int = 1, exact_count: Optional[int] = None) -> list[str]:
    items = _split_equation_inputs(text)
    if exact_count is not None and len(items) != exact_count:
        raise ValueError(f"{op_name} requires exactly {exact_count} expression(s)")
    if len(items) < min_count:
        raise ValueError(f"{op_name} requires at least {min_count} expression(s)")
    return items


def _parse_expression_list(text: str, op_name: str, *, fallback: bool = True) -> list[Any]:
    items = _split_expression_inputs(text, op_name, min_count=1)
    parser = _parse_expression_with_fallback if fallback else _parse_expression
    return [parser(item) for item in items]


def _parse_two_expressions(text: str, op_name: str, *, fallback: bool = True) -> tuple[Any, Any]:
    values = _parse_expression_list(text, op_name, fallback=fallback)
    if len(values) != 2:
        raise ValueError(f"{op_name} requires exactly two expressions in selection")
    return values[0], values[1]


def _parse_collection_items(text: str) -> list[Any]:
    expression = _parse_expression_with_fallback(text)
    if isinstance(expression, (list, tuple, set)):
        return list(expression)
    if isinstance(expression, sp.Set):
        if expression.is_FiniteSet is not True:
            raise ValueError("subsets requires a finite set/list input")
        return list(expression)
    if isinstance(expression, sp.MatrixBase):
        return list(expression)

    # Fallback to line/semicolon separated items.
    parts = _split_equation_inputs(text)
    if len(parts) > 1:
        return [_parse_expression_with_fallback(item) for item in parts]
    raise ValueError("subsets requires finite set/list input")


def _parse_geometry_entities(data: str, op_name: str, *, exact_count: Optional[int] = None) -> list[Any]:
    parts = _split_expression_inputs(data, op_name, min_count=1, exact_count=exact_count)
    entities = []
    for part in parts:
        try:
            entity = _sympify_with_locals(part)
        except Exception as exc:
            raise ValueError(f"{op_name} could not parse geometry object: {part}") from exc
        if not isinstance(entity, GeometryEntity):
            raise ValueError(f"{op_name} expects geometry entities (Point/Line/Circle/...)")
        entities.append(entity)
    return entities


def _parse_symbol_assumptions(params: dict[str, Any]) -> dict[str, bool]:
    assumptions = params.get("assumptions", {})
    if assumptions is None:
        return {}
    if not isinstance(assumptions, dict):
        raise ValueError("'assumptions' must be an object")

    parsed: dict[str, bool] = {}
    for key, value in assumptions.items():
        assumption = str(key).strip().lower()
        if assumption not in SYMBOL_ASSUMPTION_KEYS:
            raise ValueError(f"Unknown symbol assumption: {assumption}")
        parsed[assumption] = _parse_bool_value(value, assumption)
    return parsed


def _parse_units_expression(text: str):
    try:
        return _sympify_with_locals(text, include_units=True)
    except Exception as exc:
        raise ValueError(f"Could not parse units expression: {text}") from exc


def _parse_distribution_args(params: dict[str, Any]) -> tuple[str, str, list[Any]]:
    kind = str(params.get("kind", "")).strip().lower()
    if kind not in DISTRIBUTION_KINDS:
        raise ValueError("dist kind must be one of: normal, uniform, bernoulli, binomial, hypergeometric")

    name = str(params.get("name", "")).strip()
    if name == "":
        raise ValueError("dist requires a non-empty random variable name")

    args = params.get("args", [])
    if not isinstance(args, list):
        raise ValueError("'args' must be an array")
    parsed_args = [_parse_expression_with_fallback(str(item)) for item in args]
    return kind, name, parsed_args


def _parse_equation_system(data: str, *, fallback: bool = False) -> tuple[list[Any], list[Any], set[sp.Symbol]]:
    equation_inputs = _split_equation_inputs(data)
    if len(equation_inputs) == 0:
        raise ValueError("Operation requires at least one equation")

    equations: list[Any] = []
    expressions: list[Any] = []
    all_symbols: set[sp.Symbol] = set()
    for item in equation_inputs:
        if fallback:
            equation, expression = _parse_equation_or_zero_expression_with_fallback(item)
        else:
            equation, expression = _parse_equation_or_zero_expression(item)
        equations.append(equation)
        expressions.append(expression)
        all_symbols.update(equation.free_symbols)
        all_symbols.update(expression.free_symbols)

    return equations, expressions, all_symbols


def _parse_integer_expression(data: str, op_name: str) -> int:
    expression = _parse_expression_with_fallback(data)
    free_symbols = getattr(expression, "free_symbols", set())
    if free_symbols:
        raise ValueError(f"{op_name} requires an integer expression without free symbols")

    normalized = expression
    try:
        normalized = sp.nsimplify(expression)
    except Exception:
        pass

    if getattr(normalized, "is_integer", False) is not True:
        raise ValueError(f"{op_name} requires an integer value")

    try:
        return int(normalized)
    except Exception as exc:
        raise ValueError(f"{op_name} requires an integer value") from exc


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


def _op_simplify(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "simplify", set())
    expression = _parse_expression(data)
    return _to_latex(simplify(expression))


def _op_trigsimp(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "trigsimp", set())
    expression = _parse_expression(data)
    return _to_latex(trigsimp(expression))


def _op_ratsimp(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "ratsimp", set())
    expression = _parse_expression(data)
    return _to_latex(ratsimp(expression))


def _op_powsimp(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "powsimp", set())
    expression = _parse_expression(data)
    return _to_latex(powsimp(expression))


def _op_apart(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "apart", {"var"})
    expression = _parse_expression(data)
    symbol = _parse_symbol_param(params.get("var"), "var")

    if symbol is None:
        result = apart(expression)
    else:
        result = apart(expression, symbol)

    return _to_latex(result)


def _op_subs(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "subs", {"assignments"})
    expression = _parse_expression(data)
    substitutions = _parse_substitution_assignments(params)
    result = expression.subs(substitutions)
    return _to_latex(result)


def _op_solveset(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "solveset", {"var", "domain"})
    equation, expression = _parse_equation_or_zero_expression(data)
    symbol = _symbol_from_params_or_default(params, equation.free_symbols)
    if symbol is None:
        symbol = _default_symbol(expression.free_symbols)
    if symbol is None:
        raise ValueError("No variable found for solveset")

    domain = _parse_solveset_domain(params.get("domain"))
    result = sp.solveset(expression, symbol, domain=domain)
    return _to_latex(result)


def _op_linsolve(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "linsolve", {"vars"})
    if len(_split_equation_inputs(data)) == 0:
        raise ValueError("linsolve requires at least one equation")
    _, expressions, all_symbols = _parse_equation_system(data)
    symbols = _parse_symbol_list(params.get("vars"), "vars")
    if not symbols:
        symbols = sorted(all_symbols, key=lambda symbol: symbol.name)
    if not symbols:
        raise ValueError("linsolve could not infer variables; pass explicit vars")

    result = sp.linsolve(expressions, tuple(symbols))
    return _to_latex(result)


def _op_nonlinsolve(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "nonlinsolve", {"vars"})
    if len(_split_equation_inputs(data)) == 0:
        raise ValueError("nonlinsolve requires at least one equation")
    _, expressions, all_symbols = _parse_equation_system(data)
    symbols = _parse_symbol_list(params.get("vars"), "vars")
    if not symbols:
        symbols = sorted(all_symbols, key=lambda symbol: symbol.name)
    if not symbols:
        raise ValueError("nonlinsolve could not infer variables; pass explicit vars")

    result = sp.nonlinsolve(expressions, tuple(symbols))
    return _to_latex(result)


def _op_rsolve(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "rsolve", {"func"})
    if "=" in data:
        equation, _ = _parse_equation_or_zero_expression_with_fallback(data)
        recurrence = equation
    else:
        recurrence = _parse_expression_with_fallback(data)

    func = _parse_function_target(params.get("func"))
    if func is None:
        result = sp.rsolve(recurrence)
    else:
        result = sp.rsolve(recurrence, func)

    return _to_latex(result)


def _op_diophantine(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "diophantine", {"vars"})
    equation_inputs = _split_equation_inputs(data)
    if len(equation_inputs) != 1:
        raise ValueError("diophantine expects a single equation")

    _, expression = _parse_equation_or_zero_expression_with_fallback(equation_inputs[0])
    symbols = _parse_symbol_list(params.get("vars"), "vars")
    if symbols:
        try:
            result = sp.diophantine(expression, syms=tuple(symbols))
        except TypeError:
            result = sp.diophantine(expression)
    else:
        result = sp.diophantine(expression)
    return _to_latex(result)


def _op_solve(data: str, params: dict[str, Any]) -> str:
    equation, expression = _parse_equation_or_zero_expression(data)
    symbols = _parse_symbol_list(params.get("vars"), "vars")
    if not symbols:
        single = _parse_symbol(params.get("var"))
        if single is not None:
            symbols = [single]

    if not symbols:
        default = _symbol_from_params_or_default(params, equation.free_symbols)
        if default is None:
            default = _default_symbol(expression.free_symbols)
        if default is None:
            raise ValueError("No variable found for solve")
        symbols = [default]

    if len(symbols) == 1:
        result = sp.solve(equation, symbols[0])
    else:
        result = sp.solve(equation, symbols, dict=True)
    return _to_latex(result)


def _op_diff(data: str, params: dict[str, Any]) -> str:
    expression = _parse_expression(data)
    chain = params.get("chain")
    if chain is not None:
        if not isinstance(chain, list) or len(chain) == 0:
            raise ValueError("'chain' must be a non-empty array")

        result = expression
        for step in chain:
            if not isinstance(step, dict):
                raise ValueError("Each diff chain step must be an object")
            order = _parse_positive_int(step.get("order", 1), "order")
            symbol = _parse_symbol(step.get("var"))
            if symbol is None:
                symbol = _default_symbol(result.free_symbols)
            if symbol is None:
                raise ValueError("No variable found for differentiation")
            result = sp.diff(result, symbol, order)
        return _to_latex(result)

    order = _parse_positive_int(params.get("order", 1), "order")
    symbol = _symbol_from_params_or_default(params, expression.free_symbols)
    if symbol is None:
        raise ValueError("No variable found for differentiation")

    result = sp.diff(expression, symbol, order)
    return _to_latex(result)


def _op_integrate(data: str, params: dict[str, Any]) -> str:
    expression = _parse_expression(data)
    bounds = params.get("bounds")
    if bounds is not None:
        if not isinstance(bounds, list) or len(bounds) == 0:
            raise ValueError("'bounds' must be a non-empty array")

        integration_args = []
        for bound in bounds:
            if not isinstance(bound, dict):
                raise ValueError("Each integration bound must be an object")

            symbol = _parse_symbol(bound.get("var"))
            if symbol is None:
                raise ValueError("Each integration bound requires 'var'")

            lower = bound.get("lower")
            upper = bound.get("upper")
            has_lower = lower is not None
            has_upper = upper is not None

            if has_lower != has_upper:
                raise ValueError("Each integration bound requires both lower and upper")

            if has_lower and has_upper:
                integration_args.append((symbol, _parse_point(lower), _parse_point(upper)))
            else:
                integration_args.append(symbol)

        result = sp.integrate(expression, *integration_args)
        return _to_latex(result)

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


def _op_nsolve(data: str, params: dict[str, Any]) -> str:
    _, expression = _parse_equation_or_zero_expression(data)

    symbol = _parse_symbol(params.get("var"))
    if symbol is None:
        raise ValueError("nsolve expects: nsolve <var> <guess> [guess2]")

    if "guess" not in params:
        raise ValueError("nsolve requires an initial guess")
    guess = _parse_point(params.get("guess"))

    guess2_value = params.get("guess2")
    if guess2_value is not None:
        guess2 = _parse_point(guess2_value)
        result = sp.nsolve(expression, symbol, (guess, guess2))
    else:
        result = sp.nsolve(expression, symbol, guess)

    return _to_latex(result)


def _op_dsolve(data: str, params: dict[str, Any]) -> str:
    equation, _ = _parse_equation_or_zero_expression_with_fallback(data)
    func = _parse_function_target(params.get("func"))

    if func is None:
        result = sp.dsolve(equation)
    else:
        result = sp.dsolve(equation, func=func)

    return _to_latex(result)


def _op_solve_system(data: str, params: dict[str, Any]) -> str:
    if len(_split_equation_inputs(data)) == 0:
        raise ValueError("solve_system requires at least one equation")
    equations, _, all_symbols = _parse_equation_system(data)

    symbols = _parse_symbol_list(params.get("vars"), "vars")
    if not symbols:
        symbols = sorted(all_symbols, key=lambda symbol: symbol.name)
    if not symbols:
        raise ValueError("solve_system could not infer variables; pass explicit vars")

    result = sp.solve(equations, symbols, dict=True)
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


def _op_eigenvects(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "eigenvects", set())
    matrix = _as_matrix(_parse_expression(data))
    return _to_latex(matrix.eigenvects())


def _op_nullspace(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "nullspace", set())
    matrix = _as_matrix(_parse_expression(data))
    return _to_latex(matrix.nullspace())


def _op_charpoly(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "charpoly", {"var"})
    matrix = _as_matrix(_parse_expression(data))
    symbol = _parse_symbol_param(params.get("var"), "var")
    if symbol is None:
        symbol = sp.Symbol("lambda")

    return _to_latex(matrix.charpoly(symbol).as_expr())


def _op_lu(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "lu", set())
    matrix = _as_matrix(_parse_expression(data))
    return _to_latex(matrix.LUdecomposition())


def _op_qr(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "qr", set())
    matrix = _as_matrix(_parse_expression(data))
    return _to_latex(matrix.QRdecomposition())


def _op_mat_solve(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "mat_solve", set())
    matrix = _as_matrix(_parse_expression(data))
    if matrix.cols < 2:
        raise ValueError("mat_solve expects an augmented matrix [A|b]")

    coefficients = matrix[:, :-1]
    rhs = matrix[:, -1]
    if coefficients.rows == 0 or coefficients.cols == 0:
        raise ValueError("mat_solve expects a non-empty augmented matrix [A|b]")

    try:
        solution, free_params = coefficients.gauss_jordan_solve(rhs)
    except Exception as exc:
        raise ValueError(f"mat_solve failed: {exc}") from exc

    if getattr(free_params, "rows", 0) > 0:
        return _to_latex({ "solution": solution, "params": free_params })
    return _to_latex(solution)


def _op_isprime(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "isprime", set())
    number = _parse_integer_expression(data, "isprime")
    return str(bool(sp.isprime(number)))


def _op_factorint(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "factorint", set())
    number = _parse_integer_expression(data, "factorint")
    return _to_latex(sp.factorint(number))


def _op_primerange(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "primerange", {"start", "stop"})
    if "start" not in params or "stop" not in params:
        raise ValueError("primerange expects: <start> <stop>")

    start = _parse_int_value(params.get("start"), "start")
    stop = _parse_int_value(params.get("stop"), "stop")
    return _to_latex(list(sp.primerange(start, stop)))


def _op_div(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "div", {"var"})
    left, right = _parse_two_expressions(data, "div")
    symbol = _parse_symbol_param(params.get("var"), "var")
    if symbol is None:
        candidates = sorted(left.free_symbols.union(right.free_symbols), key=lambda item: item.name)
        if candidates:
            symbol = candidates[0]

    if symbol is None:
        quotient, remainder = sp.div(left, right)
    else:
        quotient, remainder = sp.div(left, right, symbol)
    return _to_latex({"quotient": quotient, "remainder": remainder})


def _op_gcd(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "gcd", {"var"})
    left, right = _parse_two_expressions(data, "gcd")
    symbol = _parse_symbol_param(params.get("var"), "var")
    if symbol is None:
        result = sp.gcd(left, right)
    else:
        result = sp.gcd(left, right, symbol)
    return _to_latex(result)


def _op_sqf(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "sqf", {"var"})
    expression = _parse_expression(data)
    symbol = _parse_symbol_param(params.get("var"), "var")
    if symbol is None:
        result = sp.sqf(expression)
    else:
        result = sp.sqf(expression, symbol)
    return _to_latex(result)


def _op_groebner(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "groebner", {"vars", "order"})
    variables = _parse_symbol_list(params.get("vars"), "vars")
    if len(variables) == 0:
        raise ValueError("groebner expects at least one variable")

    order = str(params.get("order", "lex")).strip().lower()
    if order == "":
        order = "lex"
    if order not in GROEBNER_ORDERS:
        raise ValueError("groebner order must be one of: lex, grlex, grevlex")

    polynomials = _parse_expression_list(data, "groebner")
    basis = sp.groebner(polynomials, *variables, order=order)
    return _to_latex(list(basis.polys))


def _op_resultant(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "resultant", {"var"})
    symbol = _parse_required_symbol_param(params, "var", "resultant")
    left, right = _parse_two_expressions(data, "resultant")
    return _to_latex(sp.resultant(left, right, symbol))


def _op_summation(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "summation", {"var", "lower", "upper"})
    expression = _parse_expression(data)
    symbol = _parse_required_symbol_param(params, "var", "summation")
    if "lower" not in params or "upper" not in params:
        raise ValueError("summation expects: <var> <lower> <upper>")
    lower = _parse_point(params.get("lower"))
    upper = _parse_point(params.get("upper"))
    return _to_latex(sp.summation(expression, (symbol, lower, upper)))


def _op_product(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "product", {"var", "lower", "upper"})
    expression = _parse_expression(data)
    symbol = _parse_required_symbol_param(params, "var", "product")
    if "lower" not in params or "upper" not in params:
        raise ValueError("product expects: <var> <lower> <upper>")
    lower = _parse_point(params.get("lower"))
    upper = _parse_point(params.get("upper"))
    return _to_latex(sp.product(expression, (symbol, lower, upper)))


def _op_binomial(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "binomial", {"n", "k"})
    if "n" not in params or "k" not in params:
        raise ValueError("binomial expects: <n> <k>")
    n = _parse_int_value(params.get("n"), "n")
    k = _parse_int_value(params.get("k"), "k")
    return _to_latex(sp.binomial(n, k))


def _op_perm(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "perm", {"n", "k"})
    if "n" not in params:
        raise ValueError("perm expects: <n> [k]")
    n = _parse_int_value(params.get("n"), "n")
    if "k" in params and params.get("k") is not None:
        k = _parse_int_value(params.get("k"), "k")
        return _to_latex(nP(n, k))
    return _to_latex(sp.factorial(n))


def _op_comb(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "comb", {"n", "k"})
    if "n" not in params or "k" not in params:
        raise ValueError("comb expects: <n> <k>")
    n = _parse_int_value(params.get("n"), "n")
    k = _parse_int_value(params.get("k"), "k")
    return _to_latex(nC(n, k))


def _op_partition(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "partition", {"n"})
    if "n" not in params:
        raise ValueError("partition expects: <n>")
    n = _parse_int_value(params.get("n"), "n")
    return _to_latex(sp.partition(n))


def _op_subsets(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "subsets", {"k"})
    k = params.get("k")
    if k is not None:
        k = _parse_int_value(k, "k")
        if k < 0:
            raise ValueError("subsets expects non-negative k")
    values = _parse_collection_items(data)
    return _to_latex(list(iter_subsets(values, k=k)))


def _op_totient(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "totient", set())
    value = _parse_integer_expression(data, "totient")
    return _to_latex(sp.totient(value))


def _op_mobius(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "mobius", set())
    value = _parse_integer_expression(data, "mobius")
    return _to_latex(sp.mobius(value))


def _op_divisors(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "divisors", {"proper"})
    value = _parse_integer_expression(data, "divisors")
    proper = _parse_bool_value(params.get("proper", False), "proper")
    return _to_latex(sp.divisors(value, proper=proper))


def _op_logic_simplify(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "logic_simplify", {"form"})
    form = str(params.get("form", "simplify")).strip().lower()
    if form not in LOGIC_FORMS:
        raise ValueError("logic_simplify form must be one of: simplify, cnf, dnf")

    expression = _sympify_with_locals(data)
    if form == "cnf":
        return _to_latex(sp.to_cnf(expression, simplify=True))
    if form == "dnf":
        return _to_latex(sp.to_dnf(expression, simplify=True))
    return _to_latex(sp.simplify_logic(expression))


def _op_sat(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "sat", set())
    expression = _sympify_with_locals(data)
    return _to_latex(sp.satisfiable(expression, all_models=False))


def _op_jordan(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "jordan", set())
    matrix = _as_matrix(_parse_expression(data))
    p_matrix, j_matrix = matrix.jordan_form()
    return _to_latex({"P": p_matrix, "J": j_matrix})


def _op_svd(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "svd", set())
    matrix = _as_matrix(_parse_expression(data))
    u_matrix, s_matrix, v_matrix = matrix.singular_value_decomposition()
    return _to_latex({"U": u_matrix, "S": s_matrix, "V": v_matrix})


def _op_cholesky(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "cholesky", set())
    matrix = _as_matrix(_parse_expression(data))
    return _to_latex(matrix.cholesky())


def _op_symbol(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "symbol", {"name", "assumptions"})
    name = str(params.get("name", "")).strip()
    if name == "":
        raise ValueError("symbol expects: <name> [assumption=bool ...]")
    assumptions = _parse_symbol_assumptions(params)
    symbol = sp.Symbol(name, **assumptions)
    REGISTERED_SYMBOLS[name] = symbol
    REGISTERED_SYMBOL_ASSUMPTIONS[name] = assumptions
    return _to_latex({"name": name, "assumptions": assumptions})


def _op_symbols(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "symbols", set())
    return _to_latex(REGISTERED_SYMBOL_ASSUMPTIONS)


def _op_symbols_reset(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "symbols_reset", set())
    REGISTERED_SYMBOLS.clear()
    REGISTERED_SYMBOL_ASSUMPTIONS.clear()
    return _to_latex({"success": True})


def _op_geometry(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "geometry", set())
    entities = _parse_geometry_entities(data, "geometry")
    if len(entities) == 1:
        return _to_latex(entities[0])
    return _to_latex(entities)


def _op_intersect(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "intersect", set())
    left, right = _parse_geometry_entities(data, "intersect", exact_count=2)
    return _to_latex(intersection(left, right))


def _op_tangent(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "tangent", set())
    left, right = _parse_geometry_entities(data, "tangent", exact_count=2)
    if hasattr(left, "is_tangent"):
        return str(bool(left.is_tangent(right)))
    if hasattr(right, "is_tangent"):
        return str(bool(right.is_tangent(left)))
    raise ValueError("tangent is not supported for the provided geometry objects")


def _op_similar(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "similar", set())
    left, right = _parse_geometry_entities(data, "similar", exact_count=2)
    if hasattr(left, "is_similar"):
        return str(bool(left.is_similar(right)))
    if hasattr(right, "is_similar"):
        return str(bool(right.is_similar(left)))
    raise ValueError("similar is not supported for the provided geometry objects")


def _parse_optics_options(params: dict[str, Any]) -> dict[str, Any]:
    options = params.get("options")
    if not isinstance(options, dict):
        raise ValueError("optics lens/mirror expects an options object")
    if len(options) != 2:
        raise ValueError("optics lens/mirror expects exactly two options")
    parsed: dict[str, Any] = {}
    for raw_key, raw_value in options.items():
        key = str(raw_key).strip()
        if key not in OPTICS_OPTION_KEYS:
            raise ValueError(f"Invalid optics option key: {key}")
        parsed[key] = _parse_expression_with_fallback(str(raw_value))
    return parsed


def _op_units(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "units", {"action", "target"})
    action = str(params.get("action", "")).strip().lower()
    expression = _parse_units_expression(data)
    if action == "simplify":
        return _to_latex(units_util.quantity_simplify(expression))
    if action == "convert":
        target = params.get("target")
        if target is None:
            raise ValueError("units convert expects target units")
        return _to_latex(sp_units.convert_to(expression, _parse_units_expression(str(target))))
    raise ValueError("units expects action: simplify|convert")


def _op_mechanics(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "mechanics", {"action", "qs"})
    action = str(params.get("action", "")).strip().lower()
    if action != "euler_lagrange":
        raise ValueError("mechanics supports only: euler_lagrange")
    qs = params.get("qs")
    if not isinstance(qs, list) or len(qs) == 0:
        raise ValueError("mechanics euler_lagrange expects at least one coordinate function")

    lagrangian = _parse_expression_with_fallback(data)
    funcs = [_parse_expression_with_fallback(str(item)) for item in qs]
    return _to_latex(sp.euler_equations(lagrangian, tuple(funcs)))


def _op_quantum(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "quantum", {"action", "expr2"})
    action = str(params.get("action", "")).strip().lower()
    expression = _parse_expression_with_fallback(data)
    if action == "dagger":
        return _to_latex(sp_quantum.Dagger(expression))
    if action == "commutator":
        expr2 = params.get("expr2")
        if expr2 is None:
            raise ValueError("quantum commutator expects expr2")
        right = _parse_expression_with_fallback(str(expr2))
        return _to_latex(sp_quantum.Commutator(expression, right).doit())
    raise ValueError("quantum expects action: dagger|commutator")


def _op_optics(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "optics", {"action", "options", "incident", "n1", "n2"})
    action = str(params.get("action", "")).strip().lower()
    if action == "lens":
        return _to_latex(sp_optics.lens_formula(**_parse_optics_options(params)))
    if action == "mirror":
        return _to_latex(sp_optics.mirror_formula(**_parse_optics_options(params)))
    if action == "refraction":
        if params.get("incident") is None or params.get("n1") is None or params.get("n2") is None:
            raise ValueError("optics refraction expects incident, n1, n2")
        incident = _parse_expression_with_fallback(str(params.get("incident")))
        n1 = _parse_expression_with_fallback(str(params.get("n1")))
        n2 = _parse_expression_with_fallback(str(params.get("n2")))
        return _to_latex(sp_optics.refraction_angle(incident, n1, n2))
    raise ValueError("optics expects action: lens|mirror|refraction")


def _op_pauli(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "pauli", {"action"})
    action = str(params.get("action", "")).strip().lower()
    if action != "simplify":
        raise ValueError("pauli expects action: simplify")
    expression = _sympify_with_locals(data)
    return _to_latex(sp_pauli.evaluate_pauli_product(expression))


def _op_dist(_: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "dist", {"kind", "name", "args"})
    kind, name, parsed_args = _parse_distribution_args(params)

    constructors: dict[str, tuple[int, Callable[..., Any]]] = {
        "normal": (2, sp_stats.Normal),
        "uniform": (2, sp_stats.Uniform),
        "bernoulli": (1, sp_stats.Bernoulli),
        "binomial": (2, sp_stats.Binomial),
        "hypergeometric": (3, sp_stats.Hypergeometric),
    }
    expected_arity, constructor = constructors[kind]
    if len(parsed_args) != expected_arity:
        raise ValueError(f"dist {kind} expects {expected_arity} parameter(s)")

    random_var = constructor(name, *parsed_args)
    REGISTERED_RANDOM_VARIABLES[name] = random_var
    return _to_latex({"name": name, "kind": kind, "rv": random_var})


def _op_p(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "p", set())
    expression = _parse_expression_with_fallback(data)
    return _to_latex(sp_stats.P(expression))


def _op_e(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "e", set())
    expression = _parse_expression_with_fallback(data)
    return _to_latex(sp_stats.E(expression))


def _op_var(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "var", set())
    expression = _parse_expression_with_fallback(data)
    return _to_latex(sp_stats.variance(expression))


def _op_density(data: str, params: dict[str, Any]) -> str:
    _ensure_allowed_params(params, "density", set())
    expression = _parse_expression_with_fallback(data)
    return _to_latex(sp_stats.density(expression))


OP_HANDLERS = {
    "div": _op_div,
    "gcd": _op_gcd,
    "sqf": _op_sqf,
    "groebner": _op_groebner,
    "resultant": _op_resultant,
    "summation": _op_summation,
    "product": _op_product,
    "binomial": _op_binomial,
    "perm": _op_perm,
    "comb": _op_comb,
    "partition": _op_partition,
    "subsets": _op_subsets,
    "totient": _op_totient,
    "mobius": _op_mobius,
    "divisors": _op_divisors,
    "logic_simplify": _op_logic_simplify,
    "sat": _op_sat,
    "jordan": _op_jordan,
    "svd": _op_svd,
    "cholesky": _op_cholesky,
    "symbol": _op_symbol,
    "symbols": _op_symbols,
    "symbols_reset": _op_symbols_reset,
    "geometry": _op_geometry,
    "intersect": _op_intersect,
    "tangent": _op_tangent,
    "similar": _op_similar,
    "units": _op_units,
    "mechanics": _op_mechanics,
    "quantum": _op_quantum,
    "optics": _op_optics,
    "pauli": _op_pauli,
    "dist": _op_dist,
    "p": _op_p,
    "e": _op_e,
    "var": _op_var,
    "density": _op_density,
    "simplify": _op_simplify,
    "trigsimp": _op_trigsimp,
    "ratsimp": _op_ratsimp,
    "powsimp": _op_powsimp,
    "apart": _op_apart,
    "subs": _op_subs,
    "solveset": _op_solveset,
    "linsolve": _op_linsolve,
    "nonlinsolve": _op_nonlinsolve,
    "rsolve": _op_rsolve,
    "diophantine": _op_diophantine,
    "solve": _op_solve,
    "diff": _op_diff,
    "integrate": _op_integrate,
    "limit": _op_limit,
    "series": _op_series,
    "nsolve": _op_nsolve,
    "dsolve": _op_dsolve,
    "solve_system": _op_solve_system,
    "det": _op_det,
    "inv": _op_inv,
    "transpose": _op_transpose,
    "rank": _op_rank,
    "eigenvals": _op_eigenvals,
    "eigenvects": _op_eigenvects,
    "nullspace": _op_nullspace,
    "charpoly": _op_charpoly,
    "lu": _op_lu,
    "qr": _op_qr,
    "mat_solve": _op_mat_solve,
    "isprime": _op_isprime,
    "factorint": _op_factorint,
    "primerange": _op_primerange,
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
    REGISTERED_SYMBOLS.clear()
    REGISTERED_SYMBOL_ASSUMPTIONS.clear()
    REGISTERED_RANDOM_VARIABLES.clear()
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
