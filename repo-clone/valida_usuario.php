<?php
session_start();
require_once('conexao_banco.php');

$usuario = $_POST['usuario'];
$senha = md5($_POST['senha']);

$sql = "SELECT usuario, email FROM usuarios WHERE usuario = '$usuario' AND senha = '$senha'";

$objDB = new db();
$link = $objDB->connect_mysql();

$resultado_id = mysqli_query($link, $sql);

if ($resultado_id) {
    $dados_usuario = mysqli_fetch_array($resultado_id);

    if (isset($dados_usuario['usuario'])) {
        $_SESSION['usuario'] = $dados_usuario['usuario'];
        $_SESSION['email'] = $dados_usuario['email'];
        header('Location: home.php');
        exit;
    } else {
        header('Location: index.php?erro=1');
        exit;
    }
} else {
    echo "Erro na execução da consulta.";
}