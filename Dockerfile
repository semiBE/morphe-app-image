# ============================================================
# Dockerfile for morphe-cli (Android app patching tool)
# Source:   https://github.com/MorpheApp/morphe-cli
# Releases: https://github.com/MorpheApp/morphe-cli/releases
# Always fetches the latest stable release at build time.
# ============================================================

# Use a slim JDK 17 image — morphe-cli is a JVM/Kotlin fat JAR
# Ref: https://hub.docker.com/_/eclipse-temurin
FROM eclipse-temurin:17-jre-jammy

# ── Metadata ────────────────────────────────────────────────
LABEL org.opencontainers.image.title="morphe-cli" \
      org.opencontainers.image.description="Morphe CLI Android app patching tool" \
      org.opencontainers.image.source="https://github.com/MorpheApp/morphe-cli" \
      org.opencontainers.image.licenses="GPL-3.0"

# ── System dependencies ──────────────────────────────────────
# curl  : download the JAR from GitHub releases
# jq    : parse the GitHub API response to extract the latest version tag
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        jq \
    && rm -rf /var/lib/apt/lists/*

# ── Working directory ────────────────────────────────────────
WORKDIR /morphe

# ── Download the latest morphe-cli fat JAR from GitHub releases ─
# Uses the GitHub API to resolve the latest tag, then downloads the
# corresponding -all.jar (shadow/fat jar with all deps bundled).
# API ref: https://docs.github.com/en/rest/releases/releases#get-the-latest-release
# Releases: https://github.com/MorpheApp/morphe-cli/releases
RUN MORPHE_VERSION=$(curl -fsSL \
        "https://api.github.com/repos/MorpheApp/morphe-cli/releases/latest" \
        | jq -r '.tag_name | ltrimstr("v")') && \
    echo "Downloading morphe-cli v${MORPHE_VERSION}" && \
    curl -fsSL \
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
