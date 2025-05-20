FROM python:3.11.9-slim

# Add metadata labels
LABEL maintainer="Your Name"
LABEL description="RAF Score calculation service"
LABEL version="1.0"

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies and configure FreeTDS in one layer
RUN apt-get update && apt-get install -y \
    freetds-dev \
    freetds-bin \
    unixodbc-dev \
    tdsodbc \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/* \
    && echo "[MSSQL]\n\
host = 10.10.1.4\n\
port = 1433\n\
tds version = 7.4" > /etc/freetds.conf

# Create and switch to non-root user
RUN useradd -m -s /bin/bash appuser

WORKDIR /app

# Copy requirements first
COPY requirements.txt .

# Install Python packages
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set proper permissions
RUN chown -R appuser:appuser /app && \
    chmod +x startup.sh

# Switch to non-root user
USER appuser

EXPOSE 8000

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["./startup.sh"]
