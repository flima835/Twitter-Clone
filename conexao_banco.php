<?php

class db
{
	private $host = 'localhost';
	private	$usuario = 'root';
	private $senha = '';
	private $bd = 'twitter_clone';

	function connect_mysql()
	{
		// ciar conexão
	$connect = mysqli_connect($this->host, $this->usuario, $this->senha, $this->bd);

            //ajustar o charset de comunicação entre a aplicação e o banco de dados
            mysqli_set_charset($connect,'utf8');   

		// verificação de erro de conexão
		if(mysqli_connect_errno()) {
			echo "Erro de conexão com banco de dados:	(".$connect->connect_errno().")".$connect->connect_error; 
		}
		return $connect;
	}
}

?>