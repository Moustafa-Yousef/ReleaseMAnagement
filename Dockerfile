# استخدم Ubuntu 22.04 كأساس
FROM ubuntu:22.04

# تثبيت الأدوات الأساسية
RUN apt update && apt install -y \
    curl wget unzip python3 python3-pip \
    git \
    && apt clean

# إضافة مستودع Dart الرسمي وتثبيته
RUN wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/dart.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/dart.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" \
    | tee /etc/apt/sources.list.d/dart.list > /dev/null \
    && apt update \
    && apt install -y dart

# ضبط متغير البيئة لـ Dart
ENV PATH="$PATH:/usr/lib/dart/bin"

# تحديد الإصدارات القديمة والجديدة باستخدام Git
RUN git describe --tags --abbrev=0 > old_version.txt || echo "0.0.0" > old_version.txt \
    && git rev-parse --short HEAD > new_version.txt

# إنشاء مجلد العمل داخل الحاوية
WORKDIR /app

# نسخ الملفات المطلوبة من الريبو
COPY . .

# تثبيت المكتبات المطلوبة من requirements.txt (إذا كان لديك)
RUN pip install --no-cache-dir -r requirements.txt

# تنزيل Dart سكربت النسخة
COPY release_manager.dart /app/release_manager.dart

# تشغيل سكربت Dart لتحديد الإصدار
RUN dart run release_manager.dart $(cat old_version.txt) $(cat new_version.txt)

# تشغيل API أو سكربت آخر بعد تحديد الإصدار
CMD ["python3", "api.py"]
