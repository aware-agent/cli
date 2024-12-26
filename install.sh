#!/bin/bash

VERSION="7.7.7"

# Function to check if Go is installed
check_go() {
    if ! command -v go &> /dev/null; then
        echo "Go is not installed. Installing now..."
        install_go
    fi
}

# Function to build the binary
build_binary() {
    check_go
    echo "Building Supabase CLI v${VERSION}..."
    go build -buildvcs=false -ldflags "-X main.Version=${VERSION}" -o supabase
    if [ $? -eq 0 ]; then
        echo "Binary built successfully"
    else
        echo "Error: Failed to build binary"
        exit 1
    fi
}

# Function to install the binary
install_binary() {
    if [ -w "/usr/local/bin" ]; then
        mv ./supabase /usr/local/bin/
        chmod +x /usr/local/bin/supabase
        echo "Supabase CLI v${VERSION} installed to /usr/local/bin/supabase"
        echo "You can verify the installation by running: supabase --version"
    else
        echo "Error: No write permission to /usr/local/bin"
        echo "Please run with sudo:"
        echo "sudo ./install.sh --install"
        exit 1
    fi
}

# Function to install Go
install_go() {
    echo "Installing Go..."
    apt update
    apt install -y wget
    
    # Download and install the latest stable Go version (1.23.4)
    GO_VERSION="1.23.4"
    wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    export PATH=$PATH:/usr/local/go/bin
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    
    # Make Go available in the current session and permanently
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    
    if command -v go &> /dev/null; then
        echo "Go installed successfully. Version: $(go version)"
    else
        echo "Error: Failed to install Go"
        exit 1
    fi
}

# Function to create deb package
create_deb_package() {
    local PACKAGE_DIR="supabase-cli"
    
    # Create package directory structure
    mkdir -p "${PACKAGE_DIR}/usr/local/bin"
    cp ./supabase "${PACKAGE_DIR}/usr/local/bin/"
    chmod +x "${PACKAGE_DIR}/usr/local/bin/supabase"
    
    # Create DEBIAN control directory and file
    mkdir -p "${PACKAGE_DIR}/DEBIAN"
    cat > "${PACKAGE_DIR}/DEBIAN/control" << EOF
Package: supabase-cli
Version: ${VERSION}
Architecture: amd64
Maintainer: Supabase
Description: Supabase CLI tool
EOF

    # Build the package
    dpkg-deb --build "${PACKAGE_DIR}"
    
    # Cleanup
    rm -rf "${PACKAGE_DIR}"
    
    echo "Created package: ${PACKAGE_DIR}.deb"
}

# Parse command line arguments
case "$1" in
    --build)
        build_binary
        ;;
    --install)
        install_binary
        ;;
    --build-and-install)
        build_binary
        install_binary
        ;;
    --deb)
        build_binary
        create_deb_package
        ;;
    "")  # No arguments provided
        build_binary
        install_binary
        ;;
    *)
        echo "Usage: $0 [--build|--install|--build-and-install|--deb]"
        echo "  --build              : Build the binary only"
        echo "  --install            : Install the pre-built binary"
        echo "  --build-and-install  : Build and install the binary"
        echo "  --deb                : Create a .deb package"
        echo "  (no flags)           : Same as --build-and-install"
        exit 1
        ;;
esac