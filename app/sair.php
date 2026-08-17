<?php
    session_start();

    // 1. Limpa as variáveis de sessão
    unset($_SESSION['usuario']);
    unset($_SESSION['email']);

    // 2. Destrói a sessão completamente
    session_destroy();

    // 3. Redireciona para a home (index.php)
    header('Location: index.php');
    exit;
?>