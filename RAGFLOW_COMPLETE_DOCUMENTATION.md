# 📚 RAGFLOW v0.24.0 - Documentação Completa com Passos Detalhados

**Autor**: Gilvan  

**Data**: 2026-04-01  

**Versão**: 1.0  

**Status**: ✅ Pronto para Execução

---

## 🔄 Atualizar o Sistema

Antes de instalar, atualize o sistema para evitar problemas de dependências:
```bash
sudo apt-get update
sudo apt-get upgrade -y
🚀 Instalação
Torne o script executável:
   chmod +x ./install_ragflow.sh
Execute a instalação:
   ./install_ragflow.sh
   ⚙️ Comandos de GerenciamentoTodos os comandos devem ser executados no diretório ~/ragflow. 
   Use o script start_ragflow.sh para simplicidade:
Ver status completo:
  cd ~/ragflow && ./start_ragflow.sh status
Ver todos os logs:
  cd ~/ragflow && ./start_ragflow.sh logs
Reiniciar tudo:
  cd ~/ragflow && ./start_ragflow.sh restart
Parar tudo:
  cd ~/ragflow && ./start_ragflow.sh stop
Ver ajuda:
  cd ~/ragflow && ./start_ragflow.sh 
  
help💡 Dicas Adicionais
Verificar instalação: Após instalar, acesse http://localhost:80 no navegador.
Problemas comuns: Se ports estiverem em uso, edite docker-compose.yml e ajuste as portas.
Dependências: Certifique-se de ter Docker e Docker Compose instalados (versão >= 2.20).