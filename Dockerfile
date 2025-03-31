# استخدم Ubuntu كأساس
FROM ubuntu:22.04

# تثبيت الأدوات الأساسية مثل curl، wget، git، Python
RUN apt update && apt install -y \
    curl wget unzip python3 python3-pip git \
    && apt clean

# إضافة مستودع Dart الرسمي وتثبيته
RUN curl -fsSL https://storage.googleapis.com/download.dartlang.org/linux/debian/stable/gpg | gpg --dearmor -o /usr/share/keyrings/dart-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/dart-archive-keyring.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" > /etc/apt/sources.list.d/dart_stable.list \
    && apt update \
    && apt install -y dart \
    && apt clean

# ضبط متغير البيئة لـ Dart
ENV PATH="$PATH:/usr/lib/dart/bin"

# إنشاء مجلد العمل داخل الحاوية
WORKDIR /app

# نسخ الملفات المطلوبة من الريبو
COPY . . 

# تثبيت المكتبات المطلوبة من requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# إضافة الكود Dart (لو هو موجود في الريبو)
COPY release_manager.dart /app/release_manager.dart

# تشغيل التطبيق (هنا لو عندك سكربت معين في الـ Dart أو بايثون)
CMD ["bash", "-c", "python3 api.py && dart run release_manager.dart"]
