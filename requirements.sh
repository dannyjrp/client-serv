#!/usr/bin/env bash
# requirements.sh - Instala JDK 25 (Amazon Corretto), Maven y Docker
# Soporta dnf (Amazon Linux 2023) y apt (Ubuntu/Debian)

set -e

# --- Detectar gestor de paquetes ---
if command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
elif command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt"
else
    echo "Error: no se encontró dnf ni apt. Sistema no soportado."
    exit 1
fi

echo "Gestor de paquetes detectado: $PKG_MGR"

# --- Instalar dependencias base ---
if [[ "$PKG_MGR" == "dnf" ]]; then
    sudo dnf update -y
    sudo dnf install -y wget gpg curl
elif [[ "$PKG_MGR" == "apt" ]]; then
    sudo apt-get update -y
    sudo apt-get install -y wget gpg curl
fi

# --- Instalar JDK 25 (Amazon Corretto) ---
if [[ "$PKG_MGR" == "dnf" ]]; then
    # Repositorio de Corretto para RPM
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo dnf install -y java-25-amazon-corretto-devel
elif [[ "$PKG_MGR" == "apt" ]]; then
    # Repositorio de Corretto para Debian/Ubuntu
    wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
    sudo apt-get update -y
    sudo apt-get install -y java-25-amazon-corretto-jdk
fi

# --- Instalar Maven ---
if [[ "$PKG_MGR" == "dnf" ]]; then
    sudo dnf install -y maven
elif [[ "$PKG_MGR" == "apt" ]]; then
    sudo apt-get install -y maven
fi

# --- Instalar Docker ---
if [[ "$PKG_MGR" == "dnf" ]]; then
    sudo dnf install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER" || true
elif [[ "$PKG_MGR" == "apt" ]]; then
    # Instalación oficial de Docker para Ubuntu/Debian
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# --- Configurar JAVA_HOME ---
# Detectar el directorio de Java instalado
JAVA_HOME_CANDIDATE=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")
if [[ -n "$JAVA_HOME_CANDIDATE" && -x "$JAVA_HOME_CANDIDATE/bin/javac" ]]; then
    echo "export JAVA_HOME=$JAVA_HOME_CANDIDATE" >> "$HOME/.bashrc"
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> "$HOME/.bashrc"
    echo "JAVA_HOME configurado en ~/.bashrc: $JAVA_HOME_CANDIDATE"
else
    echo "Advertencia: no se pudo determinar JAVA_HOME automáticamente."
fi

# --- Verificación final ---
echo ""
echo "=== Verificación ==="
java -version 2>&1 | head -1
javac -version 2>&1
mvn -v 2>&1 | head -1
docker --version 2>&1
echo ""
echo "Instalación completada. Ejecuta 'source ~/.bashrc' o abre una nueva terminal para aplicar JAVA_HOME."