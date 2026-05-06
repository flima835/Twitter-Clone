<?php

require_once('conexao_banco.php');

$usuario = $_POST['usuario'];
$email = $_POST['email'];
$senha = md5($_POST['senha']);	


$objDB = new db();
$link = $objDB -> connect_mysql();

$banco = "INSERT INTO usuarios(usuario, email, senha) values('$usuario', '$email',   '$senha')";

// executar query
if (mysqli_query($link, $banco)) {
	include ('inscrevase.php');
	}else{
		echo "Usuario não incluido. ";
	}
?>

