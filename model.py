from fastapi import FastAPI
from transformers import DistilBertTokenizer, DistilBertForSequenceClassification
import torch

app = FastAPI()

# تحميل DistilBERT والـ Tokenizer
tokenizer = DistilBertTokenizer.from_pretrained("distilbert-base-uncased")
model = DistilBertForSequenceClassification.from_pretrained("distilbert-base-uncased", num_labels=3)

# الفئات المتوقعة
LABELS = ["major", "minor", "patch"]

@app.post("/analyze")
async def analyze_code(data: dict):
    old_code = data.get("old_code")
    new_code = data.get("new_code")

    if not old_code or not new_code:
        return {"error": "Both old_code and new_code are required."}

    # تجهيز البيانات للموديل
    input_text = f"old code: {old_code} [SEP] new code: {new_code}"
    inputs = tokenizer(input_text, return_tensors="pt", padding=True, truncation=True)

    # تمرير البيانات للموديل
    with torch.no_grad():
        outputs = model(**inputs)

    # استخراج التوقع
    predicted_label = torch.argmax(outputs.logits, dim=1).item()
    change_type = LABELS[predicted_label]

    return {"Predicted Change Type": change_type}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
