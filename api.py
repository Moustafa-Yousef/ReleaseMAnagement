from fastapi import FastAPI, HTTPException
from transformers import DistilBertTokenizer, DistilBertForSequenceClassification
import torch
from functools import lru_cache

app = FastAPI()

@lru_cache()
def load_model_and_tokenizer():
    tokenizer = DistilBertTokenizer.from_pretrained("distilbert-base-uncased")
    model = DistilBertForSequenceClassification.from_pretrained("distilbert-base-uncased", num_labels=3)
    return tokenizer, model

tokenizer, model = load_model_and_tokenizer()
LABELS = ["major", "minor", "patch"]

@app.post("/analyze")
async def analyze_commit(data: dict):
    commit_message = data.get("commit_message")

    if not commit_message:
        raise HTTPException(status_code=400, detail="commit_message is required.")
    
    if len(commit_message) > 1000:  # حد لحجم رسالة الكوميت
        raise HTTPException(status_code=400, detail="Commit message is too long.")

    # معالجة الرسالة باستخدام الموديل
    inputs = tokenizer(commit_message, return_tensors="pt", padding=True, truncation=True)
    
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
