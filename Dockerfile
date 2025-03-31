# صورة أساسية بـ Python
FROM python:3.11-slim

# تثبيت Git وأدوات أساسية
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# تثبيت Dart
RUN apt-get update && apt-get install -y apt-transport-https && \
    curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/dart.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" | tee /etc/apt/sources.list.d/dart.list && \
    apt-get update && apt-get install -y dart

# إعداد مسار العمل
WORKDIR /app

# نسخ ملفات Python وتثبيت الـ dependencies
COPY api.py .
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# نسخ ملفات Dart وتثبيت الـ dependencies
COPY release_manager.dart .
COPY pubspec.yaml .
RUN dart pub get

# فتح الـ port بتاع الـ API
EXPOSE 5000

# الأمر الافتراضي لتشغيل الـ API والـ Dart script
CMD ["bash", "-c", "python api.py & sleep 5 && dart run release_manager.dart"]
