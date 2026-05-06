<?php
    session_start();
    if(!isset($_SESSION['usuario'])){
        header('Location: index.php?erro=1');
    }
    require_once('conexao_banco.php'); // Certifique-se que este arquivo existe
?>

<!DOCTYPE HTML>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <title>Twitter Clone - Home</title>
    
    <script src="https://code.jquery.com/jquery-2.2.4.min.js"></script>
    <!-- <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css"> -->
     <a href="home.php">
       <img rel="stylesheet" src="https://upload.wikimedia.org/wikipedia/commons/6/6f/Logo_of_Twitter.svg" style="padding: 10px; width: 50px;" />
     </a>

    <style>
        body { background-color: #e6ecf0; }
        .navbar { background-color: #fff; border-bottom: 1px solid rgba(0,0,0,0.15); }
        .btn-twitter { background-color: #1da1f2; color: #fff; border-radius: 20px; font-weight: bold; }
        .btn-twitter:hover { background-color: #1991db; color: #fff; }
        .panel { border-radius: 0; border: 1px solid #e1e8ed; }
        .panel-body h4 { font-weight: bold; margin-bottom: 2px; }
        .perfil-link { color: #657786; font-size: 13px; }
        .timeline { background: #fff; border: 1px solid #e1e8ed; padding: 15px; }
        .tweet-box { border-bottom: 1px solid #e1e8ed; padding-bottom: 15px; margin-bottom: 15px; }
        textarea { resize: none; border-radius: 10px !important; }
    </style>
</head>

<body>
    <nav class="navbar navbar-default navbar-static-top">
        <div class="container">
            <div class="navbar-header">
                <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar">
                    <span class="sr-only">Toggle navigation</span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                <a href="home.php"><img src="imagens/icone_twitter.png" style="padding: 10px;" /></a>
            </div>
            
            <div id="navbar" class="navbar-collapse collapse">
                <ul class="nav navbar-nav navbar-right">
                    <li><a href="sair.php">Sair</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container">
        <div class="row">
            <div class="col-md-3">
                <div class="panel panel-default">
                    <div class="panel-body">
                        <h4><?= $_SESSION['usuario'] ?></h4>
                        <span class="perfil-link">@<?= strtolower(str_replace(' ', '', $_SESSION['usuario'])) ?></span>
                        <hr>
                        <div class="row">
                            <div class="col-xs-6">
                                <strong>TWEETS</strong><br><span style="color: #1da1f2;">0</span>
                            </div>
                            <div class="col-xs-6">
                                <strong>SEGUIDORES</strong><br><span style="color: #1da1f2;">0</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-6">
                <div class="timeline">
                    <div class="tweet-box">
                        <form id="form_tweet">
                            <div class="input-group">
                                <textarea class="form-control" placeholder="O que está acontecendo?" maxlength="140" rows="3"></textarea>
                                <span class="input-group-btn" style="vertical-align: bottom; padding-left: 10px;">
                                    <button class="btn btn-twitter" type="button">Tweet</button>
                                </span>
                            </div>
                        </form>
                    </div>

                    <div id="tweets" class="list-group">
                        <div class="list-group-item">
                            <h4 class="list-group-item-heading">Twitter Clone <small> - 1 min atrás</small></h4>
                            <p class="list-group-item-text">Bem-vindo ao seu clone do Twitter rodando no Google Cloud Kubernetes!</p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="panel panel-default">
                    <div class="panel-body">
                        <h4>Quem seguir</h4>
                        <hr>
                        <a href="#" style="font-size: 13px;">Procurar por pessoas</a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
</body>
</html>