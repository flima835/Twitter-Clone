<?php
class db {
    private $host = 'mysql-service'; 
    private $usuario = 'root';
    private $senha = '';
    private $bd = 'twitter_clone';

    public function connect_mysql() {
        $con = mysqli_connect($this->host, $this->usuario, $this->senha, $this->bd);

        mysqli_set_charset($con, 'utf8');

        if (mysqli_connect_errno()) {
            echo "Erro de conexão: " . mysqli_connect_error();
        }

        return $con;
    }
}