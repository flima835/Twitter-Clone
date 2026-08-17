<?php
class db {
    private $host = 'mysql-service'; 
    private $usuario = 'root';
    private $senha = '';
    private $bd = 'twitter_clone';

    public function connect_mysql() {
        try {
            // Tenta estabelecer a conexão
            $con = mysqli_connect($this->host, $this->usuario, $this->senha, $this->bd);
            
            // Define o charset
            mysqli_set_charset($con, 'utf8');
            
            return $con;
            
        } catch (mysqli_sql_exception $e) {
            // 1. Força o Status Code 500 (O Apache e o Datadog vão capturar isso)
            http_response_code(500);
            
            // 2. Registra o erro real silenciosamente nos logs do servidor
            error_log("Falha crítica de Banco de Dados: " . $e->getMessage());
            
            // 3. Exibe uma mensagem amigável para o cliente e interrompe a página
            die("Ops! Nosso sistema está temporariamente indisponível. Tente novamente mais tarde.");
        }
    }
}
?>