#!/usr/bin/env bash
# requirements.sh - Instala JDK 25 (Amazon Corretto), Maven y Docker
# Soporta dnf (Amazon Linux/RHEL) y apt (Ubuntu/Debian)

set -e

# --- 1. Detectar gestor de paquetes ---
if command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
elif command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt"
else
    echo "Error: no se encontró dnf ni apt. Sistema no soportado."
    exit 1
fi

echo "Gestor de paquetes detectado: $PKG_MGR"

# --- 2. Instalar dependencias base ---
if [[ "$PKG_MGR" == "dnf" ]]; then
    sudo dnf update -y
    sudo dnf install -y wget gpg curl ca-certificates
elif [[ "$PKG_MGR" == "apt" ]]; then
    sudo apt-get update -y
    sudo apt-get install -y wget gpg curl ca-certificates
fi

# --- 3. Instalar JDK 25 (Amazon Corretto) ---
if [[ "$PKG_MGR" == "dnf" ]]; then
    # Repositorio de Corretto para RPM
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo dnf install -y java-25-amazon-corretto-devel
elif [[ "$PKG_MGR" == "apt" ]]; then
    # Repositorio de Corretto para Debian/Ubuntu
    # Usamos --yes para evitar el prompt de sobrescritura si el archivo existe
    wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor --yes -o /usr/share/keyrings/corretto-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
    sudo apt-get update -y
    sudo apt-get install -y java-25-amazon-corretto-jdk
fi

# --- 4. Instalar Maven ---
if [[ "$PKG_MGR" == "dnf" ]]; then
    sudo dnf install -y maven
elif [[ "$PKG_MGR" == "apt" ]]; then
    sudo apt-get install -y maven
fi

# --- 5. Instalar Docker (Método Oficial) ---
if [[ "$PKG_MGR" == "dnf" ]]; then
    # En Amazon Linux, el paquete docker suele estar en los repos por defecto
    sudo dnf install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER" || true
elif [[ "$PKG_MGR" == "apt" ]]; then
    # Instalación oficial de Docker para Ubuntu/Debian
    sudo install -m 0755 -d /etc/apt/keyrings
    # Descargar la clave como archivo .asc (evita problemas de gpg interactivo)
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Añadir el repositorio
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER" || true
fi

# --- 6. Configurar JAVA_HOME ---
# Detectar el directorio de Java instalado
JAVA_HOME_CANDIDATE=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")
if [[ -n "$JAVA_HOME_CANDIDATE" && -x "$JAVA_HOME_CANDIDATE/bin/javac" ]]; then
    # Evitar duplicados en ~/.bashrc
    if ! grep -q "JAVA_HOME=$JAVA_HOME_CANDIDATE" "$HOME/.bashrc" 2>/dev/null; then
        echo "export JAVA_HOME=$JAVA_HOME_CANDIDATE" >> "$HOME/.bashrc"
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> "$HOME/.bashrc"
        echo "JAVA_HOME configurado en ~/.bashrc: $JAVA_HOME_CANDIDATE"
    else
        echo "JAVA_HOME ya estaba configurado en ~/.bashrc."
    fi
else
    echo "Advertencia: no se pudo determinar JAVA_HOME automáticamente."
fi

# --- 7. Verificación final ---
echo ""
echo "=== Verificación ==="
java -version 2>&1 | head -1
javac -version 2>&1
mvn -v 2>&1 | head -1
docker --version 2>&1 || echo "Docker: Comando no disponible aún (requiere reinicio de sesión)"
echo ""
echo "Instalación completada."
echo "IMPORTANTE: Ejecuta 'source ~/.bashrc' o cierra y abre una nueva terminal para aplicar JAVA_HOME."
echo "Si instalaste Docker, cierra sesión y vuelve a entrar (o ejecuta 'newgrp docker') para usarlo sin sudo."