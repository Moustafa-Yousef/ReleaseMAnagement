# استخدم صورة Python 3.10 slim كأساس (أخف من Ubuntu)
FROM python:3.10-slim

# تثبيت الأدوات الأساسية و Dart
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    gnupg \
    git \
    && wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/dart.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/dart.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" \
    | tee /etc/apt/sources.list.d/dart.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends dart \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ضبط متغير البيئة لـ Dart
ENV PATH="$PATH:/usr/lib/dart/bin"

# إنشاء مجلد العمل داخل الحاوية
WORKDIR /app

# نسخ الملفات المطلوبة من الريبو
COPY . .

# تثبيت المكتبات المطلوبة من requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# تثبيت Dart dependencies
RUN dart pub get

# تشغيل التحليل عند بدء الكونتينر
CMD ["bash", "-c", "nohup python3 api.py & while ! curl -s http://localhost:5000/analyze > /dev/null; do sleep 1; done && dart run release_manager.dart $REPO_URL"]

