from fastapi import FastAPI, HTTPException
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch
from functools import lru_cache

app = FastAPI()

@lru_cache()


def load_model_and_tokenizer():
    tokenizer = AutoTokenizer.from_pretrained("microsoft/graphcodebert-base")
    model = AutoModelForSequenceClassification.from_pretrained("microsoft/graphcodebert-base", num_labels=3)
    return tokenizer, model

tokenizer, model = load_model_and_tokenizer()
LABELS = ["major", "minor", "patch"]

@app.post("/analyze")
async def analyze_code(data: dict):
    old_code = data.get("old_code")
    new_code = data.get("new_code")

    if not old_code or not new_code:
        raise HTTPException(status_code=400, detail="Both old_code and new_code are required.")
    
    if len(old_code) > 10000 or len(new_code) > 10000:
        raise HTTPException(status_code=400, detail="Input code is too long.")

    input_text = f"old code: {old_code} [SEP] new code: {new_code}"
    inputs = tokenizer(input_text, return_tensors="pt", padding=True, truncation=True)

    try:
        with torch.no_grad():
            outputs = model(**inputs)
        predicted_label = torch.argmax(outputs.logits, dim=1).item()
        change_type = LABELS[predicted_label]
        return {"Predicted Change Type": change_type}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
