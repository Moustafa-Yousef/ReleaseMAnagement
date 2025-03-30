# استخدم Ubuntu كأساس
FROM ubuntu:22.04

# ثبت Python و Dart
RUN apt update && apt install -y \
    python3 python3-pip dart \
    && apt clean

# حدد المسار الرئيسي في الكونتينر
WORKDIR /app

# انسخ ملف الـ dependencies
COPY requirements.txt .
COPY pubspec.yaml .

# ثبت الـ dependencies
RUN pip install -r requirements.txt
RUN dart pub get  # تأكد إن Dart dependencies مثبتة

# انسخ باقي الملفات
COPY . .

# شغل التحليل عند بدء الكونتينر
CMD ["bash", "-c", "python3 api.py && dart run release_analysis.dart"]
