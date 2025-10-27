import os, json
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS
from joblib import load

app = Flask(__name__)
CORS(app)  # dev only

# ---------- paths ----------
MODEL_PATH         = os.path.join("models", "svm.pkl")
SCHEMA_NAMES_PATH  = "feature_names.json"
SCHEMA_DTYPES_PATH = "feature_dtypes.json"

# ---------- load model & schema ----------
model = load(MODEL_PATH) if os.path.exists(MODEL_PATH) else None
feature_names = json.load(open(SCHEMA_NAMES_PATH)) if os.path.exists(SCHEMA_NAMES_PATH) else None
feature_dtypes = json.load(open(SCHEMA_DTYPES_PATH)) if os.path.exists(SCHEMA_DTYPES_PATH) else {}

# ---------- helpers ----------
def is_numeric_dtype_str(dt: str) -> bool:
    s = str(dt).lower()
    return ("int" in s) or ("float" in s) or ("number" in s)

# ---------- endpoints ----------
@app.get("/health")
def health():
    return {
        "status": "ok",
        "model_loaded": bool(model),
        "n_features": len(feature_names or [])
    }

@app.get("/schema")
def schema():
    return jsonify({
        "feature_names": feature_names,
        "feature_dtypes": feature_dtypes
    })

@app.get("/template")
def template():
    names = feature_names or []
    dtypes = feature_dtypes or {}
    row = {}
    for c in names:
        dt = dtypes.get(c, "object")
        row[c] = 0 if is_numeric_dtype_str(dt) else ""
    return jsonify({"rows": [row]})

@app.post("/predict")
def predict():
    if model is None:
        return jsonify({"error": "Model not loaded. Put models/svm.pkl and restart app."}), 500

    payload = request.get_json(silent=True) or {}
    rows = payload.get("rows")
    if not rows:
        return jsonify({"error": "Send JSON with key 'rows': [ {{...}}, {{...}} ]"}), 400

    df = pd.DataFrame(rows)

    # Validate / coerce using schema (if available)
    if feature_names:
        missing = [c for c in feature_names if c not in df.columns]
        extra   = [c for c in df.columns if c not in feature_names]
        if missing:
            return jsonify({"error": "Missing columns", "missing": missing, "extra": extra}), 400

        # order columns as during training
        df = df.reindex(columns=feature_names)

        # numeric coercion
        for c, dt in (feature_dtypes or {}).items():
            if c in df.columns and is_numeric_dtype_str(dt):
                df[c] = pd.to_numeric(df[c], errors="coerce")

    # predictions
    preds = model.predict(df)
    try:
        proba = model.predict_proba(df)[:, 1].tolist()
    except Exception:
        proba = [None] * len(df)

    preds = pd.Series(preds).astype(int).tolist()

    return jsonify({
        "predictions": [
            {
                "row_id": i,
                "model_name": "Support Vector Machine",
                "predicted_result": preds[i],
                "predicted_probability": (None if proba[i] is None else float(proba[i]))
            }
            for i in range(len(df))
        ]
    })

# ---------- minimal browser UI ----------
@app.get("/ui")
@app.get("/")
def ui():
    names = feature_names or []
    dtypes = feature_dtypes or {}

    def is_num(dt):
        s = str(dt).lower()
        return ("int" in s) or ("float" in s) or ("number" in s)

    rows_html = []
    for name in names:
        dt = dtypes.get(name, "")
        itype = "number" if is_num(dt) else "text"
        step  = "any" if itype == "number" else ""
        rows_html.append(
            f'<div class="row"><label>{name}</label>'
            f'<input id="f_{name}" type="{itype}" step="{step}" /></div>'
        )
    rows_html = "\n".join(rows_html)

    return f"""
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>SVM Predictor</title>
  <style>
    body {{ font-family: system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;
           max-width: 820px; margin: 40px auto; padding: 0 16px; }}
    .row {{ display:grid; grid-template-columns: 260px 1fr; gap:12px; align-items:center; margin:8px 0; }}
    input {{ padding:8px; font-size:16px }}
    button {{ padding:10px 14px; font-size:16px; cursor:pointer }}
    pre {{ background:#f6f8fa; padding:12px; border-radius:8px; white-space:pre-wrap; }}
  </style>
</head>
<body>
  <h1>SVM Predictor</h1>
  <p>Enter values and click Predict.</p>

  {rows_html}

  <button id="go">Predict</button>
  <h3>Response</h3>
  <pre id="out">—</pre>

  <script>
    const names  = {json.dumps(names)};
    const dtypes = {json.dumps(dtypes)};

    const isNum = dt => (String(dt).toLowerCase().includes("int") ||
                         String(dt).toLowerCase().includes("float") ||
                         String(dt).toLowerCase().includes("number"));

    document.getElementById('go').onclick = async () => {{
      const row = {{}};
      for (const name of names) {{
        const el = document.getElementById('f_'+name);
        const dt = dtypes[name] || '';
        if (isNum(dt)) {{
          const v = el.value.trim();
          row[name] = v === '' ? null : Number(v);
        }} else {{
          row[name] = el.value;
        }}
      }}
      const r = await fetch('/predict', {{
        method: 'POST',
        headers: {{ 'Content-Type': 'application/json' }},
        body: JSON.stringify({{ rows: [row] }})
      }});
      const data = await r.json();
      document.getElementById('out').textContent = JSON.stringify(data, null, 2);
    }};
  </script>
</body>
</html>
    """

# ---------- debug: print routes ----------
if __name__ == "__main__":
    print("ROUTES:")
    for r in app.url_map.iter_rules():
        print(r)
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
