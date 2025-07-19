FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# ✅ Copy the real requirements.txt from the project root
COPY ../requirements.txt .

RUN pip install --upgrade pip && pip install -r requirements.txt

# ✅ Copy all your app code (adjust if needed)
COPY .. .

CMD ["gunicorn", "heartcare.wsgi:application", "--bind", "0.0.0.0:8000"]
