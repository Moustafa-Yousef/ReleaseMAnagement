# 1️⃣ استخدم Python لتشغيل API
FROM python:3.9 AS api

WORKDIR /app

COPY api/requirements.txt .
RUN pip install -r requirements.txt

COPY api /app
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "5000"]

# 2️⃣ استخدم Dart لتشغيل CLI
FROM dart:stable AS cli

WORKDIR /app

COPY cli/pubspec.yaml .
COPY cli/pubspec.lock .
RUN dart pub get

COPY cli /app

# 3️⃣ شغل الـ API الأول وبعدين CLI
CMD ["sh", "-c", "python3 -m uvicorn server:app --host
