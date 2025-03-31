# استخدم Ubuntu 22.04 كأساس
FROM ubuntu:22.04

# تثبيت الأدوات الأساسية و Git و Python و Dart
RUN apt update && apt install -y \
    curl wget unzip python3 python3-pip \
    git \
    dart \
    && apt clean

# ضبط متغير البيئة لـ Dart
ENV PATH="$PATH:/usr/lib/dart/bin"

# نسخ ملفات المشروع إلى الحاوية
WORKDIR /app
COPY . .

# تحديد الإصدارات القديمة والجديدة باستخدام Git داخل الريبو
RUN git describe --tags --abbrev=0 > old_version.txt || echo "0.0.0" > old_version.txt \
    && git rev-parse --short HEAD > new_version.txt

# تثبيت المكتبات المطلوبة من requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# تشغيل سكربت Dart لتحديد الإصدار
COPY release_manager.dart /app/release_manager.dart
RUN dart run release_manager.dart $(cat /app/old_version.txt) $(cat /app/new_version.txt)

# شغل API أو سكربت آخر بعد تحديد الإصدار
CMD ["python3", "api.py"]
