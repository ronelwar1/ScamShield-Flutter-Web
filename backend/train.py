"""Train and save the ScamShield baseline NLP model (backend/model.joblib)."""
from nlp import MODEL_PATH, train_model

if __name__ == "__main__":
    model, count = train_model(save=True)
    print(f"Saved model trained on {count} examples to {MODEL_PATH}")
    print(f"Classes: {list(model.classes_)}")
    print("Note: the dataset is synthetic/illustrative. Run `python evaluate.py` for grouped cross-validation,")
    print("and evaluate on independent real-world data before making any research or deployment claims.")
