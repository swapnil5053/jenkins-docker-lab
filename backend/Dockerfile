# Multi-stage Dockerfile for optimized backend image
# Stage 1: Builder - Compile the C++ application
FROM gcc:11 AS builder

WORKDIR /build

# Copy source code
COPY app.cpp .

# Compile with optimizations
RUN g++ -O2 -Wall -Wextra app.cpp -o app && \
    echo "Build complete: binary size $(stat -f%z app 2>/dev/null || stat -c%s app) bytes"

# ============================================================================
# Stage 2: Runtime - Minimal production image
FROM ubuntu:22.04

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl && \
    rm -rf /var/lib/apt/lists/* && \
    echo "Ubuntu $(grep VERSION_ID /etc/os-release | cut -d= -f2) runtime base ready"

WORKDIR /app

# Copy compiled binary from builder stage
COPY --from=builder /build/app .

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["./app"]
