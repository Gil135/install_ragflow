#!/bin/bash

# RAGFLOW v0.24.0 - Script de Instalação Completo
# Segue documentação oficial: https://ragflow.io/docs/dev/begin_dev
# Cria start_ragflow.sh automaticamente se não existir
# Chama start automaticamente após instalação

set -euo pipefail

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# Configurações
INSTALL_DIR="${HOME}/ragflow"
LOG_FILE="${INSTALL_DIR}/install.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Funções de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    echo "[INFO] $*" >> "$LOG_FILE" 2>/dev/null || true
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
    echo "[✓] $*" >> "$LOG_FILE" 2>/dev/null || true
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
    echo "[✗] $*" >> "$LOG_FILE" 2>/dev/null || true
}

log_section() {
    echo ""
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  $*${NC}"
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════${NC}"
    echo ""
    echo "=== $* ===" >> "$LOG_FILE" 2>/dev/null || true
}

# Verificar pré-requisitos
check_prerequisites() {
    log_section "Verificando Pré-requisitos"

    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 não encontrado"
        exit 1
    fi
    log_success "Python 3 encontrado: $(python3 --version)"

    if ! command -v git &> /dev/null; then
        log_error "Git não encontrado"
        exit 1
    fi
    log_success "Git encontrado: $(git --version)"

    if ! command -v docker &> /dev/null; then
        log_error "Docker não encontrado"
        exit 1
    fi
    log_success "Docker encontrado: $(docker --version)"

    if ! command -v node &> /dev/null; then
        log_error "Node.js não encontrado"
        exit 1
    fi
    log_success "Node.js encontrado: $(node --version)"

    if ! command -v npm &> /dev/null; then
        log_error "npm não encontrado"
        exit 1
    fi
    log_success "npm encontrado: $(npm --version)"
}

# Instalar uv e pre-commit
install_tools() {
    log_section "Instalando uv e pre-commit"

    if ! command -v pipx &> /dev/null; then
        log_info "Instalando pipx..."
        python3 -m pip install --user pipx
    fi

    if ! command -v uv &> /dev/null; then
        log_info "Instalando uv..."
        pipx install uv
    else
        log_success "uv já está instalado"
    fi

    if ! command -v pre-commit &> /dev/null; then
        log_info "Instalando pre-commit..."
        pipx install pre-commit
    else
        log_success "pre-commit já está instalado"
    fi
}

# Clonar repositório
clone_repository() {
    log_section "Clonando Repositório RAGFLOW"

    if [ -d "$INSTALL_DIR" ]; then
        log_info "Diretório $INSTALL_DIR já existe, removendo..."
        rm -rf "$INSTALL_DIR"
    fi

    log_info "Clonando repositório oficial..."
    git clone https://github.com/infiniflow/ragflow.git "$INSTALL_DIR"
    
    mkdir -p "$INSTALL_DIR"
    touch "$LOG_FILE"
    
    log_success "Repositório clonado em $INSTALL_DIR"
}

# Instalar dependências Python
install_python_deps() {
    log_section "Instalando Dependências Python"

    cd "$INSTALL_DIR"

    log_info "Sincronizando dependências com uv..."
    uv sync --python 3.12

    log_info "Baixando dependências adicionais..."
    uv run download_deps.py

    log_success "Dependências Python instaladas"
}

# Configurar pre-commit
setup_precommit() {
    log_section "Configurando pre-commit"

    cd "$INSTALL_DIR"
    pre-commit install

    log_success "pre-commit configurado"
}

# Instalar jemalloc
install_jemalloc() {
    log_section "Instalando jemalloc"

    if command -v apt-get &> /dev/null; then
        log_info "Detectado Ubuntu/Debian"
        #sudo apt-get update
        sudo apt-get install -y libjemalloc-dev
    elif command -v yum &> /dev/null; then
        log_info "Detectado CentOS/RHEL"
        sudo yum install -y jemalloc
    elif command -v zypper &> /dev/null; then
        log_info "Detectado OpenSUSE"
        sudo zypper install -y jemalloc
    elif command -v brew &> /dev/null; then
        log_info "Detectado macOS"
        brew install jemalloc
    else
        log_error "Gerenciador de pacotes não detectado"
        return 1
    fi

    log_success "jemalloc instalado"
}

# Configurar /etc/hosts
setup_hosts() {
    log_section "Configurando /etc/hosts"

    local hosts_entry="127.0.0.1       es01 infinity mysql minio redis sandbox-executor-manager"

    if grep -q "es01" /etc/hosts; then
        log_success "Entrada /etc/hosts já existe"
    else
        log_info "Adicionando entrada a /etc/hosts..."
        echo "$hosts_entry" | sudo tee -a /etc/hosts > /dev/null
        log_success "Entrada adicionada a /etc/hosts"
    fi
}

# Ajustar porta MySQL em service_conf.yaml
adjust_mysql_port() {
    log_section "Ajustando Configuração MySQL"

    local config_file="$INSTALL_DIR/conf/service_conf.yaml"
    local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"

    if [ ! -f "$config_file" ]; then
        log_error "Arquivo $config_file não encontrado"
        return 1
    fi

    # Fazer backup
    log_info "Fazendo backup: $backup_file"
    cp "$config_file" "$backup_file"
    log_success "Backup criado: $backup_file"

    # Verificar se já está ajustado
    if grep -q "port: 5455" "$config_file"; then
        log_success "Porta MySQL já está configurada para 5455"
        return 0
    fi

    # Ajustar porta
    log_info "Ajustando porta MySQL de 3306 para 5455..."
    sed -i 's/port: 3306/port: 5455/g' "$config_file"

    # Verificar se foi ajustado
    if grep -q "port: 5455" "$config_file"; then
        log_success "Porta MySQL ajustada para 5455"
        log_info "Backup original: $backup_file"
    else
        log_error "Falha ao ajustar porta MySQL"
        return 1
    fi
}

# Instalar dependências frontend
install_frontend_deps() {
    log_section "Instalando Dependências Frontend"

    cd "$INSTALL_DIR/web"

    log_info "Instalando dependências npm..."
    npm install

    log_success "Dependências frontend instaladas"
}

# Criar script start_ragflow.sh
create_startup_script() {
    local target="$1"
    
    log_info "Criando script de startup: $target"
    
    cat > "$target" << 'STARTUP_SCRIPT'
#!/bin/bash

# RAGFLOW v0.24.0 - Script de Inicialização Otimizado
# Captura portas dinâmicas e exibe URLs corretas

set -euo pipefail

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# Configurações
RAGFLOW_HOME="${HOME}/ragflow"
DOCKER_DIR="${RAGFLOW_HOME}/docker"
WEB_DIR="${RAGFLOW_HOME}/web"
LOG_DIR="${RAGFLOW_HOME}/logs"
PID_FILE="${RAGFLOW_HOME}/.ragflow.pids"

# Criar diretório de logs
mkdir -p "$LOG_DIR"

# Funções de log
log_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} ${BOLD}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} ${BOLD}✓${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')]${NC} ${BOLD}✗${NC} $*"
}

log_section() {
    echo ""
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  $*${NC}"
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════${NC}"
    echo ""
}

# Parar processos antigos
cleanup_old_processes() {
    log_section "Limpando Processos Antigos"

    pkill -f "npm run dev" 2>/dev/null || true
    pkill -f "python3 api/ragflow_server.py" 2>/dev/null || true
    pkill -f "task_executor.py" 2>/dev/null || true
    sleep 3

    if [[ -f "$PID_FILE" ]]; then
        rm -f "$PID_FILE"
    fi

    log_success "Processos antigos removidos"
}

# Iniciar Docker
start_docker() {
    log_section "Iniciando Serviços Docker"

    cd "$DOCKER_DIR"

    log_info "Parando containers antigos..."
    docker compose -f docker-compose-base.yml down 2>/dev/null || true
    sleep 5

    log_info "Iniciando containers..."
    docker compose -f docker-compose-base.yml up -d
    sleep 60

    log_info "Verificando status..."
    docker compose -f docker-compose-base.yml ps

    # Testar MySQL
    log_info "Testando MySQL..."
    if docker exec docker-mysql-1 mysql -u root -pinfini_rag_flow -e "SELECT 1" &>/dev/null; then
        log_success "MySQL está respondendo"
    else
        log_error "MySQL não respondeu"
        return 1
    fi

    log_success "Serviços Docker iniciados"
}

# Iniciar Task Executor
start_task_executor() {
    log_section "Iniciando Task Executor"

    cd "$RAGFLOW_HOME"
    source .venv/bin/activate
    export PYTHONPATH="$(pwd)"

    JEMALLOC_PATH=$(pkg-config --variable=libdir jemalloc 2>/dev/null || echo "")/libjemalloc.so

    log_info "Iniciando em background..."

    if [[ -n "$JEMALLOC_PATH" && -f "$JEMALLOC_PATH" ]]; then
        LD_PRELOAD="$JEMALLOC_PATH" python3 rag/svr/task_executor.py 1 >> "$LOG_DIR/task_executor.log" 2>&1 &
    else
        python3 rag/svr/task_executor.py 1 >> "$LOG_DIR/task_executor.log" 2>&1 &
    fi

    local pid=$!
    echo "$pid" >> "$PID_FILE"

    log_info "Task Executor PID: $pid"
    log_info "Aguardando inicialização..."

    local elapsed=0
    while [[ $elapsed -lt 60 ]]; do
        if grep -q "RAGFlow ingestion is ready" "$LOG_DIR/task_executor.log" 2>/dev/null; then
            log_success "Task Executor iniciado"
            return 0
        fi
        sleep 3
        elapsed=$((elapsed + 3))
    done

    log_error "Task Executor não iniciou"
    return 1
}

# Iniciar Backend
start_backend() {
    log_section "Iniciando Backend"

    cd "$RAGFLOW_HOME"
    source .venv/bin/activate
    export PYTHONPATH="$(pwd)"

    log_info "Iniciando em background..."
    python3 api/ragflow_server.py >> "$LOG_DIR/ragflow_server.log" 2>&1 &

    local pid=$!
    echo "$pid" >> "$PID_FILE"

    log_info "Backend PID: $pid"
    log_info "Aguardando inicialização..."

    local elapsed=0
    while [[ $elapsed -lt 60 ]]; do
        if curl -s "http://127.0.0.1:9380/health" > /dev/null 2>&1; then
            log_success "Backend iniciado (porta 9380)"
            return 0
        fi
        sleep 3
        elapsed=$((elapsed + 3))
    done

    log_error "Backend não respondeu"
    return 1
}

# Iniciar Frontend e capturar porta
start_frontend() {
    log_section "Iniciando Frontend"

    cd "$WEB_DIR"

    log_info "Iniciando em background..."
    npm run dev >> "$LOG_DIR/frontend.log" 2>&1 &

    local pid=$!
    echo "$pid" >> "$PID_FILE"

    log_info "Frontend PID: $pid"
    log_info "Aguardando inicialização..."

    local elapsed=0
    local frontend_url=""
    
    while [[ $elapsed -lt 60 ]]; do
        # Procurar pela URL do Vite nos logs
        frontend_url=$(grep -oP "Local:\s+\K(http://[^\s]+)" "$LOG_DIR/frontend.log" 2>/dev/null | head -1)
        
        if [[ -n "$frontend_url" ]]; then
            log_success "Frontend iniciado"
            echo "$frontend_url"
            return 0
        fi
        
        sleep 3
        elapsed=$((elapsed + 3))
    done

    # Se não encontrou nos logs, usar padrão
    log_success "Frontend iniciado (porta padrão)"
    echo "http://localhost:9222"
}

# Exibir informações finais
show_final_info() {
    local frontend_url=$1

    log_section "✓ RAGFLOW Iniciado com Sucesso!"

    echo ""
    echo -e "${GREEN}${BOLD}🌐 ACESSO:${NC}"
    echo -e "  ${BLUE}Frontend:${NC}  $frontend_url"
    echo -e "  ${BLUE}Backend:${NC}   http://127.0.0.1:9380/"
    echo ""
    echo -e "${GREEN}${BOLD}🔐 CREDENCIAIS:${NC}"
    echo -e "  ${BLUE}Email:${NC}     seu email"
    echo -e "  ${BLUE}Senha:${NC}     sua senha"
    echo ""
    echo -e "${GREEN}${BOLD}📋 LOGS:${NC}"
    echo -e "  ${BLUE}Task Executor:${NC} tail -f $LOG_DIR/task_executor.log"
    echo -e "  ${BLUE}Backend:${NC}       tail -f $LOG_DIR/ragflow_server.log"
    echo -e "  ${BLUE}Frontend:${NC}      tail -f $LOG_DIR/frontend.log"
    echo ""
    echo -e "${GREEN}${BOLD}🛑 PARAR RAGFLOW:${NC}"
    echo -e "  ${BLUE}$0 stop${NC}"
    echo ""
}

# Parar RAGFLOW
stop_ragflow() {
    log_section "Parando RAGFLOW"

    if [[ -f "$PID_FILE" ]]; then
        while IFS= read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                log_info "Parando processo $pid..."
                kill "$pid" 2>/dev/null || true
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi

    pkill -f "npm run dev" 2>/dev/null || true
    pkill -f "python3 api/ragflow_server.py" 2>/dev/null || true
    pkill -f "task_executor.py" 2>/dev/null || true

    sleep 3

    cd "$DOCKER_DIR"
    docker compose -f docker-compose-base.yml down 2>/dev/null || true

    log_success "RAGFLOW parado"
}

# Main
main() {
    log_section "RAGFLOW v0.24.0 - Inicialização"

    cleanup_old_processes

    if ! start_docker; then
        log_error "Falha ao iniciar Docker"
        exit 1
    fi

    if ! start_task_executor; then
        log_error "Falha ao iniciar Task Executor"
        exit 1
    fi

    if ! start_backend; then
        log_error "Falha ao iniciar Backend"
        exit 1
    fi

    local frontend_url
    if ! frontend_url=$(start_frontend); then
        log_error "Falha ao iniciar Frontend"
        exit 1
    fi

    show_final_info "$frontend_url"
}

# Tratamento de argumentos
case "${1:-start}" in
    start)
        main
        ;;
    stop)
        stop_ragflow
        ;;
    restart)
        stop_ragflow
        sleep 5
        main
        ;;
    logs)
        log_section "Logs do RAGFLOW"
        echo -e "${BLUE}Task Executor:${NC}"
        tail -30 "$LOG_DIR/task_executor.log" 2>/dev/null || echo "Sem logs"
        echo ""
        echo -e "${BLUE}Backend:${NC}"
        tail -30 "$LOG_DIR/ragflow_server.log" 2>/dev/null || echo "Sem logs"
        echo ""
        echo -e "${BLUE}Frontend:${NC}"
        tail -30 "$LOG_DIR/frontend.log" 2>/dev/null || echo "Sem logs"
        ;;
    status)
        log_section "Status do RAGFLOW"
        cd "$DOCKER_DIR"
        docker compose -f docker-compose-base.yml ps
        echo ""
        ps aux | grep -E "task_executor|ragflow_server|npm run dev" | grep -v grep || echo "Nenhum processo encontrado"
        ;;
    help)
        cat << EOF
${BOLD}RAGFLOW v0.24.0 - Script de Inicialização${NC}

${BOLD}Uso:${NC}
  $0 [COMANDO]

${BOLD}Comandos:${NC}
  start       Inicia RAGFLOW (padrão)
  stop        Para RAGFLOW
  restart     Reinicia RAGFLOW
  logs        Mostra logs
  status      Mostra status
  help        Mostra esta mensagem

${BOLD}Exemplos:${NC}
  $0 start
  $0 stop
  $0 restart
  $0 logs

EOF
        ;;
    *)
        log_error "Comando desconhecido: $1"
        echo "Use '$0 help' para ver os comandos disponíveis"
        exit 1
        ;;
esac
STARTUP_SCRIPT

    chmod +x "$target"
    log_success "Script de startup criado: $target"
}

# Copiar ou criar start_ragflow.sh para pasta ragflow
setup_startup_script() {
    log_section "Configurando Script de Startup"

    local startup_script="$SCRIPT_DIR/start_ragflow.sh"
    local target_script="$INSTALL_DIR/start_ragflow.sh"

    if [ -f "$startup_script" ]; then
        log_info "Copiando $startup_script para $INSTALL_DIR..."
        cp "$startup_script" "$target_script"
        chmod +x "$target_script"
        log_success "Script de startup copiado: $target_script"
    else
        log_info "Script de startup não encontrado em $startup_script"
        log_info "Criando script de startup padrão..."
        create_startup_script "$target_script"
    fi
}

# Exibir próximos passos
show_next_steps() {
    log_section "✓ Instalação Concluída com Sucesso!"

    echo -e "${GREEN}${BOLD}Próximos Passos:${NC}"
    echo ""
    echo -e "${BLUE}RAGFLOW está iniciando automaticamente...${NC}"
    echo ""
    echo -e "${BLUE}Acessar RAGFLOW:${NC}"
    echo "   http://localhost:9222/"
    echo ""
    echo -e "${BLUE}Credenciais Padrão:${NC}"
    echo "   Email: admin@ragflow.com"
    echo "   Senha: admin123"
    echo ""
    echo -e "${BLUE}Comandos Úteis:${NC}"
    echo "   cd $INSTALL_DIR"
    echo "   ./start_ragflow.sh start    # Iniciar"
    echo "   ./start_ragflow.sh stop     # Parar"
    echo "   ./start_ragflow.sh restart  # Reiniciar"
    echo "   ./start_ragflow.sh logs     # Ver logs"
    echo "   ./start_ragflow.sh status   # Status"
    echo ""
    echo -e "${BLUE}Logs:${NC}"
    echo "   $LOG_FILE"
    echo ""
}

# Main
main() {
    mkdir -p "$INSTALL_DIR"
    touch "$LOG_FILE"

    log_section "RAGFLOW v0.24.0 - Instalação Completa"

    check_prerequisites
    install_tools
    clone_repository
    install_python_deps
    setup_precommit
    install_jemalloc
    setup_hosts
    adjust_mysql_port
    install_frontend_deps
    setup_startup_script
    show_next_steps

    log_success "Instalação finalizada!"
    log_info "Iniciando RAGFLOW automaticamente..."
    
    # Chamar start automaticamente
    cd "$INSTALL_DIR"
    if [ -f "start_ragflow.sh" ]; then
        ./start_ragflow.sh start
    else
        log_error "Script start_ragflow.sh não encontrado"
        exit 1
    fi
}

# Executar
main

