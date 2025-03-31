# Base image مع Python
FROM python:3.10-slim AS base

# تثبيت الأدوات الأساسية (Git + curl)
RUN apt-get update && apt-get install -y git curl

# تثبيت Dart
RUN apt-get install -y apt-transport-https && \
    sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' && \
    sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' && \
    apt-get update && apt-get install -y dart

# إعداد بيئة العمل
WORKDIR /app

# نسخ ملفات المشروع
COPY api.py requirements.txt release_manager.dart ./

# تثبيت Python dependencies
RUN pip install --upgrade pip && pip install -r requirements.txt

# تثبيت Dart dependencies
RUN dart pub get

# تعريف نقطة الدخول
# بنستخدم bash علشان نشغل الـ API في الخلفية ونرن الـ Dart script
CMD ["bash", "-c", "nohup python api.py & sleep 5 && dart run release_manager.dart $REPO_URL"]
