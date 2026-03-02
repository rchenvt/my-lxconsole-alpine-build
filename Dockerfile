# --- Stage 1: Builder/Cloner ---
FROM alpine:latest AS builder

# Install git to clone the repo
RUN apk add --no-cache git

WORKDIR /src
# Clone the repository directly from the source
RUN git clone https://github.com/PenningLabs/lxconsole.git .

# --- Stage 2: Final Image ---
FROM python:3.10.19-alpine

WORKDIR /opt/lxconsole

# 1. Install runtime-only dependencies
RUN apk add --no-cache sqlite lz4

# 2. Install build dependencies temporarily
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev

# 3. Copy requirements.txt from the builder stage
COPY --from=builder /src/requirements.txt .

# 4. Install Python packages
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 5. Clean up build dependencies to minimize image size
RUN apk del .build-deps

# 6. Copy the application assets from the builder stage
# This copies the directory structure as it exists in the repo
COPY --from=builder /src/lxconsole ./lxconsole
COPY --from=builder /src/run.py .

# Optional: Ensure the sqlite database directory exists and has permissions
RUN mkdir -p /opt/lxconsole/db

ENTRYPOINT [ "python3" ]
CMD [ "run.py" ]
