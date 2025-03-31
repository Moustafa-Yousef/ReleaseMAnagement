# استخدم Ubuntu 22.04 كأساس
FROM node:alpine

# تثبيت الأدوات الأساسية و Python
RUN apt update && apt install -y curl wget unzip python3 python3-pip \
    && apt clean

# إضافة مستودع Dart الرسمي وتثبيته
RUN wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/dart.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/dart.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" \
    | tee /etc/apt/sources.list.d/dart.list > /dev/null \
    && apt update \
    && apt install -y dart

# ضبط متغير البيئة لـ Dart
ENV PATH="$PATH:/usr/lib/dart/bin"

# إنشاء مجلد العمل داخل الحاوية
WORKDIR /app

# نسخ الملفات المطلوبة من الريبو
COPY . .

# تثبيت المكتبات المطلوبة من requirements.txt
#RUN pip install --no-cache-dir -r requirements.txt

# تشغيل سكريبت Dart (إذا كان لديك سكريبت Dart رئيسي)

# شغل التحليل عند بدء الكونتينر
CMD ["bash", "-c", "python3 api.py && dart run release_analysis.dart"]
