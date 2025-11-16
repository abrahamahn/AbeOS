#!/bin/bash
# =============================================================================
# Install-Java-DevTools.sh
# Java/JVM Development Stack Installation Script
# =============================================================================

set -e  # Exit on error

echo "=================================================="
echo "Java/JVM Development Stack Installation"
echo "=================================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install SDKMAN! for Java version management
log_info "Installing SDKMAN!..."
if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash

    # Source SDKMAN
    source "$HOME/.sdkman/bin/sdkman-init.sh"

    log_success "SDKMAN! installed"
else
    log_info "SDKMAN! already installed"
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Install Java (Temurin/Eclipse Adoptium)
log_info "Installing Java 21 (Temurin)..."
sdk install java 21.0.1-tem || log_info "Java 21 already installed"
sdk default java 21.0.1-tem
log_success "Java 21 set as default"

# Install additional Java versions if needed
log_info "Installing Java 17 (LTS)..."
sdk install java 17.0.9-tem || log_info "Java 17 already installed"

log_info "Installing Java 11 (LTS)..."
sdk install java 11.0.21-tem || log_info "Java 11 already installed"

# Install Gradle
log_info "Installing Gradle..."
sdk install gradle || log_info "Gradle already installed"
sdk default gradle current
log_success "Gradle installed"

# Install Maven
log_info "Installing Maven..."
sdk install maven || log_info "Maven already installed"
sdk default maven current
log_success "Maven installed"

# Install Kotlin
log_info "Installing Kotlin..."
sdk install kotlin || log_info "Kotlin already installed"
log_success "Kotlin installed"

# Install Scala (optional)
log_info "Installing Scala..."
sdk install scala || log_info "Scala already installed"
log_success "Scala installed"

# Install sbt (Scala Build Tool)
log_info "Installing sbt..."
sdk install sbt || log_info "sbt already installed"
log_success "sbt installed"

# Display installed versions
echo ""
log_info "Installed Java versions:"
sdk list java | grep "installed" || true

echo ""
log_info "Current versions:"
java -version
echo ""
gradle --version | head -3
echo ""
mvn --version | head -1

echo ""
echo "=================================================="
log_success "Java/JVM stack installation complete!"
echo "=================================================="
echo ""
echo "Installed components:"
echo "  ✓ SDKMAN! (Java version manager)"
echo "  ✓ Java 21 (Temurin) - default"
echo "  ✓ Java 17, 11 (LTS versions)"
echo "  ✓ Gradle (build tool)"
echo "  ✓ Maven (build tool)"
echo "  ✓ Kotlin"
echo "  ✓ Scala + sbt"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Test with: java -version && gradle --version"
echo "  3. Switch Java version: sdk use java <version>"
echo "  4. List installed: sdk list java"
echo ""
