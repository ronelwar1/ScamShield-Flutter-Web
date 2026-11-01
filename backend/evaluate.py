"""Grouped cross-validation for development.

Rows that came from the same template share a `group`, and GroupKFold keeps a whole group in one fold,
so near-duplicate template variants never appear in both train and test. Even so, the data is synthetic:
these numbers describe how well the pipeline fits THIS dataset, not real-world performance.
"""
import json
from pathlib import Path

import numpy as np
from sklearn.metrics import classification_report, confusion_matrix, precision_recall_fscore_support
from sklearn.model_selection import GroupKFold

import nlp

ROOT = Path(__file__).resolve().parent


def main() -> None:
    rows = nlp.load_dataset()
    texts = np.array([r["text"] for r in rows])
    y = np.array([1 if r["label"] == "scam" else 0 for r in rows])
    groups = np.array([r.get("group") or r["text"] for r in rows])

    oof_prob = np.zeros(len(rows))
    for train_idx, test_idx in GroupKFold(n_splits=5).split(texts, y, groups):
        model = nlp.build_pipeline()
        model.fit([nlp.normalize_for_model(t) for t in texts[train_idx]], [("scam" if v else "normal") for v in y[train_idx]])
        classes = list(model.classes_)
        probs = model.predict_proba([nlp.normalize_for_model(t) for t in texts[test_idx]])[:, classes.index("scam")]
        oof_prob[test_idx] = probs

    rule = np.array([nlp.rule_score(nlp.find_signals(t)[0]) for t in texts])
    blended = np.array([nlp.blend(p, r, False) for p, r in zip(oof_prob, rule)])

    def report(name: str, score: np.ndarray, threshold: float) -> dict:
        pred = (score >= threshold).astype(int)
        p, r, f, _ = precision_recall_fscore_support(y, pred, average="binary", zero_division=0)
        tn, fp, fn, tp = confusion_matrix(y, pred, labels=[0, 1]).ravel()
        print(f"{name:<22} thr={threshold:.2f}  precision={p:.3f} recall={r:.3f} F1={f:.3f}  TP={tp} FP={fp} FN={fn} TN={tn}")
        return {"threshold": threshold, "precision": round(p, 4), "recall": round(r, 4), "f1": round(f, 4),
                "tp": int(tp), "fp": int(fp), "fn": int(fn), "tn": int(tn)}

    print(f"Rows: {len(rows)}  scam={int(y.sum())}  normal={int((1 - y).sum())}  groups={len(set(groups))}\n")
    results = {
        "model_only": report("model only", oof_prob, 0.5),
        "rules_only": report("rules only", rule, nlp.SUSPICIOUS_THRESHOLD),
        "blended_suspicious+": report("blended (>= suspicious)", blended, nlp.SUSPICIOUS_THRESHOLD),
        "blended_likely": report("blended (>= likely)", blended, nlp.LIKELY_THRESHOLD),
    }
    print("\nPer-class report for blended >= suspicious threshold:")
    print(classification_report(y, (blended >= nlp.SUSPICIOUS_THRESHOLD).astype(int), target_names=["normal", "scam"], zero_division=0))

    print("Misclassified at the 'suspicious' threshold (inspect these!):")
    wrong = np.where((blended >= nlp.SUSPICIOUS_THRESHOLD).astype(int) != y)[0]
    for i in wrong[:25]:
        print(f"  [{'scam' if y[i] else 'normal'} score={blended[i]:.2f} model={oof_prob[i]:.2f} rules={rule[i]:.2f}] {texts[i][:110]}")
    if len(wrong) > 25:
        print(f"  ... and {len(wrong) - 25} more")

    (ROOT / "metrics.json").write_text(json.dumps({"rows": len(rows), "groups": len(set(groups)), "results": results,
        "note": "Grouped 5-fold CV on a synthetic, illustrative dataset. Not a real-world performance estimate."}, indent=2))
    print("\nWARNING: synthetic dataset. Do not present these as real-world accuracy. Saved to backend/metrics.json")


if __name__ == "__main__":
    main()
