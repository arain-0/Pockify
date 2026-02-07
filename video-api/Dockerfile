# Python 3.11 slim image
FROM python:3.11-slim

# FFmpeg kurulumu (yt-dlp icin gerekli)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Calisma dizini
WORKDIR /app

# Requirements'i kopyala ve kur
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama kodunu kopyala
COPY main.py .

# Port (Cloud Run PORT env var kullanir)
ENV PORT=8080
EXPOSE 8080

# Uygulamayi baslat
CMD ["python", "main.py"]
