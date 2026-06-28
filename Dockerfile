# ============================================================
# Dockerfile for morphe-cli (Android app patching tool)
# Source: https://github.com/MorpheApp/morphe-cli
# Latest stable release: v1.9.0 (2026-05-29)
# Releases page: https://github.com/MorpheApp/morphe-cli/releases
# ============================================================

# Use a slim JDK 17 image — morphe-cli is a JVM/Kotlin fat JAR
# Ref: https://hub.docker.com/_/eclipse-temurin
FROM eclipse-temurin:17-jre-jammy

# ── Metadata ────────────────────────────────────────────────
LABEL org.opencontainers.image.title="morphe-cli" \
      org.opencontainers.image.description="Morphe CLI Android app patching tool" \
      org.opencontainers.image.source="https://github.com/MorpheApp/morphe-cli" \
      org.opencontainers.image.licenses="GPL-3.0"

# ── Version pin — update this when a new release drops ──────
# Check: https://github.com/MorpheApp/morphe-cli/releases
ARG MORPHE_VERSION=1.9.0

# ── System dependencies ──────────────────────────────────────
# curl  : download the JAR from GitHub releases
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ── Working directory ────────────────────────────────────────
WORKDIR /morphe

# ── Download morphe-cli fat JAR from GitHub releases ────────
# The "-all.jar" suffix is the shadow/fat jar that bundles all deps.
# Ref: https://github.com/MorpheApp/morphe-cli/releases/tag/v${MORPHE_VERSION}
RUN curl -fsSL \
    "https://github.com/MorpheApp/morphe-cli/releases/download/v${MORPHE_VERSION}/morphe-cli-${MORPHE_VERSION}-all.jar" \
    -o morphe-cli.jar

# ── Create a non-root user for security ─────────────────────
RUN useradd -m -u 1000 morphe
USER morphe

# ── Volumes for persistent data ──────────────────────────────
# /morphe/input   : place APKs to patch here
# /morphe/output  : patched APKs are written here
# /morphe/patches : optional local patch bundles (.mpp files)
#                   Ref: https://github.com/MorpheApp/morphe-patches
VOLUME ["/morphe/input", "/morphe/output", "/morphe/patches"]

# ── Default command: print help ──────────────────────────────
# Morphe CLI supports headless/server environments since v1.6.3
# Ref: https://github.com/MorpheApp/morphe-cli/releases/tag/v1.6.3
ENTRYPOINT ["java", "-jar", "/morphe/morphe-cli.jar"]
CMD ["--help"]
