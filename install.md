 Preparar Ambiente

# 1.2 Verificar espaço em disco
df -h

# Deve ter pelo menos 50 GB livres


 
 Copiar Scripts de Instalação
 # Verificar se os scripts existem
ls -la /install_ragflow.sh

# Se não existir, criar script de instalação
# (Copie o conteúdo do install_ragflow.sh fornecido)

# Dar permissão de execução
chmod +x ./install_ragflow.sh

#  Verificar sintaxe
bash -n ./install_ragflow.sh

# Deve retornar sem erros

Executar Instalação
chmod +x ./install_ragflow.sh
./install_ragflow.sh


Verificar se RAGFLOW foi criado
ls -la ~/ragflow/

# Deve mostrar:
# install.log
# start_ragflow.sh
# logs/
# conf/
# docker/
# web/
# api/
# rag/
# .venv/

Iniciar RAGFLOW
# Opção 1: Iniciar normalmente
cd ~/ragflow
./start_ragflow.sh start

# Opção 2: Iniciar e acompanhar logs
cd ~/ragflow
./start_ragflow.sh start
./start_ragflow.sh logs

# Opção 3: Iniciar em background
cd ~/ragflow
nohup ./start_ragflow.sh start > startup.log 2>&1 &
# Parar todos os serviços
cd ~/ragflow
./start_ragflow.sh stop

# Verificar se parou
./start_ragflow.sh status

# Reiniciar (para + inicia)
cd ~/ragflow
./start_ragflow.sh restart

# Aguardar 3-5 minutos
sleep 300

# Verificar status
./start_ragflow.sh status

# Ver últimas 30 linhas
cd ~/ragflow
./start_ragflow.sh logs

# Ver logs em tempo real
tail -f ~/ragflow/logs/task_executor.log
tail -f ~/ragflow/logs/ragflow_server.log
tail -f ~/ragflow/logs/frontend.log

# Ver logs com filtro
grep "ERROR" ~/ragflow/logs/ragflow_server.log
grep "WARNING" ~/ragflow/logs/task_executor.log
# Status completo
cd ~/ragflow
./start_ragflow.sh status

# Verificar containers
docker ps

# Verificar processos Python
ps aux | grep -E "task_executor|ragflow_server|npm"

# Verificar portas
lsof -i :9222  # Frontend
lsof -i :9380  # Backend
lsof -i :5455  # MySQL

Documentação Oficial
RAGFLOW GitHub https://github.com/infiniflow/ragflow
RAGFLOW Docs https://ragflow.io/docs
API Swagger http://localhost:9380/docs



