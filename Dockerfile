# استخدم Python slim image كـ base image
FROM python:3.10-slim

# تثبيت الأدوات المطلوبة
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    gnupg \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# تثبيت مكتبات Python
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r /app/requirements.txt

# تثبيت Dart
RUN apt-get update && apt-get install -y dart

# نسخ ملفات المشروع
COPY . /app

WORKDIR /app

# expose the port for the API
EXPOSE 5000

# تشغيل FastAPI (تطبيق Python) في البداية
CMD ["bash", "-c", "nohup python3 api.py & dart run release_manager.dart $REPO_URL"]
