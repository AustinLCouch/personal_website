# Dockerfile for Raspberry Pi ARM64 deployment
# This creates a lightweight, secure container for your personal website

# Build stage - use Rust image with ARM64 support
FROM --platform=linux/arm64 rust:1.75-slim as builder

# Install system dependencies needed for building
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Create a new user for building (security best practice)
RUN useradd -m -u 1001 builder
USER builder
WORKDIR /home/builder

# Copy dependency manifests first (Docker layer caching)
COPY --chown=builder:builder Cargo.toml Cargo.lock ./

# Pre-build dependencies (this step is cached unless deps change)
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copy source code
COPY --chown=builder:builder src ./src
COPY --chown=builder:builder templates ./templates
COPY --chown=builder:builder static ./static
COPY --chown=builder:builder migrations ./migrations

# Build the application
# Force rebuild of our code (deps are cached from previous step)
RUN touch src/main.rs && \
    cargo build --release

# Runtime stage - minimal Debian image
FROM --platform=linux/arm64 debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r website && useradd -r -g website website

# Create necessary directories
RUN mkdir -p /app/data /app/static /app/templates && \
    chown -R website:website /app

# Copy the binary and assets from builder stage
COPY --from=builder --chown=website:website \
    /home/builder/target/release/personal_website /app/
COPY --from=builder --chown=website:website \
    /home/builder/static /app/static
COPY --from=builder --chown=website:website \
    /home/builder/templates /app/templates
COPY --from=builder --chown=website:website \
    /home/builder/migrations /app/migrations

# Switch to non-root user
USER website
WORKDIR /app

# Set environment variables
ENV DATABASE_URL=sqlite:/app/data/portfolio.db
ENV HOST=0.0.0.0
ENV PORT=8080
ENV RUST_LOG=info,personal_website=debug

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD sqlite3 $DATABASE_URL "SELECT 1;" || exit 1

# Run the application
CMD ["./personal_website"]