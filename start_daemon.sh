#!/bin/bash
#
# Objetivo: Script de inicialização do barramento ErlangMS msbus
# Autor: Everton de Vargas Agilar
# Data: 03/12/2015
#


# Documentação sobre o comando start.sh
#--------------------------------------------------------------------
# 1) Opções que podem ser utilizadas no comando start.sh
#     $1 -> opção do comando (start, start-daemon, stop e console)
#     $2 -> nome do node que quer instanciar ou conectar
#
#
# 2) Como instânciar um node ErlangMS com nome padrão "msbus": 
#    
#            ./start.sh start
#
#
# 3) Instanciar um node ErlangMS com um node específico): 
#
#            ./start.sh start nome_do_node
#
#         Exemplo 1: ./start.sh start node_01
#         Exemplo 2: ./start.sh start prod_esb
#
#
# 4) Conectar em uma instância de um node ErlangMS
#
#            ./start.sh start nome_do_node
#
#         Exemplo 1: ./start.sh console node_01
#


# Parâmetros
ems_cookie="erlangms"
ems_node="msbus"
ems_init="msbus:start()"
ems_stop="msbus:stop()"
ems_log_conf="./priv/conf/elog"

# Conectar a um node como shell
function console() {
	remote_node=$1
	hostname=`hostname`
	if [ "$remote_node" == "" ]; then
		remote_node="msbus@$hostname"
	fi
	echo "Conectando na instância ErlangMS $remote_node..."
	my_node="msbus_shell_`date +"%I%M%S"`"
	erl -sname $my_node -setcookie erlangms -remsh $remote_node
}

# Instanciar um node ErlangMS
function start() {
	./build.sh
	node_name=$1
	hostname=`hostname`
	if [ "$node_name" == "" ]; then
		node_name="msbus@$hostname"
	fi
	echo "Iniciando instância ErlangMS $node_name..."
	erl -pa ../msbus/ebin deps/jsx/ebin deps/poolboy/ebin -sname $node_name -setcookie $ems_cookie -eval $ems_init -boot start_sasl -config $ems_log_conf
}

# Instanciar um node ErlangMS como daemon
function start_daemon() {
	./build.sh
	node_name=$1
	hostname=`hostname`
	if [ "$node_name" == "" ]; then
		node_name="msbus@$hostname"
	fi
	echo "Iniciando instância ErlangMS $node_name como daemon..."
	erl -detached -pa ../msbus/ebin deps/jsx/ebin deps/poolboy/ebin -sname $node_name -setcookie $ems_cookie -eval $ems_init -boot start_sasl -config $ems_log_conf
	echo "ok."
}

# Parar uma instância de um node ErlangMS
function stop() {
	remote_node=$1
	hostname=`hostname`
	if [ "$remote_node" == "" ]; then
		remote_node="msbus@$hostname"
	fi
	echo "Parando instância ErlangMS $remote_node..."
	my_node="msbus_shell_`date +"%I%M%S"`"
	erl -sname $my_node -setcookie $ems_cookie -eval $ems_stop -remsh $remote_node
}


case "$1" in

	  'start')
			start $2
	  ;;

	  'start_daemon')
			start_daemon $2
	  ;;

	  'start-daemon')
			start_daemon $2
	  ;;

	  'console')
			console $2
	  ;;

	  'stop')
			stop $2
	  ;;

	  *)
			start $2
	  ;;

esac
