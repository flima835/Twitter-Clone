<!DOCTYPE HTML>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <title>Twitter Clone - Inscreva-se</title>
    
    <script src="https://code.jquery.com/jquery-2.2.4.min.js"></script>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">
    
    <style>
        body { background-color: #f5f8fa; font-family: "Helvetica Neue",Helvetica,Arial,sans-serif; }
        .navbar { background-color: #fff; border-bottom: 1px solid rgba(0,0,0,0.15); }
        
        /* Estilo para a Logo SVG no Navbar */
        .navbar-brand { display: flex; align-items: center; padding: 15px; }
        .twitter-logo { fill: #1da1f2; width: 25px; height: 25px; }

        .main-container { margin-top: 60px; display: flex; justify-content: center; }
        .signup-box { 
            background-color: #fff; 
            padding: 40px; 
            border-radius: 20px; 
            border: 1px solid #e1e8ed; 
            width: 100%; 
            max-width: 450px; 
            box-shadow: 0 10px 25px rgba(0,0,0,0.05); 
        }
        .signup-box h3 { font-weight: bold; color: #14171a; text-align: center; margin-bottom: 30px; }
        
        .form-control { border-radius: 20px; height: 45px; border: 1px solid #ccd6dd; font-size: 15px; }
        .form-control:focus { border-color: #1da1f2; box-shadow: none; }
        
        .btn-twitter { 
            background-color: #1da1f2; 
            color: #fff; 
            border-radius: 25px; 
            font-weight: bold; 
            border: none; 
            height: 45px; 
            width: 100%; 
            font-size: 16px; 
            margin-top: 15px; 
            transition: background-color 0.2s; 
        }
        .btn-twitter:hover { background-color: #1991db; color: #fff; }
    </style>
</head>

<body>
    <nav class="navbar navbar-default navbar-static-top">
      <div class="container">
        <div class="navbar-header">
          <a class="navbar-brand" href="index.php">
            <svg class="twitter-logo" viewBox="0 0 24 24"><g><path d="M23.643 4.937c-.835.37-1.732.62-2.675.733.962-.576 1.7-1.49 2.048-2.578-.9.534-1.897.922-2.958 1.13-.85-.904-2.06-1.47-3.4-1.47-2.572 0-4.658 2.086-4.658 4.66 0 .364.042.718.12 1.06-3.873-.195-7.304-2.05-9.602-4.868-.4.69-.63 1.49-.63 2.342 0 1.616.823 3.043 2.072 3.878-.764-.025-1.482-.234-2.11-.583v.06c0 2.257 1.605 4.14 3.737 4.568-.392.106-.803.162-1.227.162-.3 0-.593-.028-.877-.082.593 1.85 2.313 3.198 4.352 3.234-1.595 1.25-3.604 1.995-5.786 1.995-.376 0-.747-.022-1.112-.065 2.062 1.323 4.51 2.093 7.14 2.093 8.57 0 13.255-7.098 13.255-13.254 0-.2-.005-.402-.014-.602.91-.658 1.7-1.477 2.323-2.41z"></path></g></svg>
          </a>
        </div>
        <div id="navbar" class="navbar-collapse collapse">
          <ul class="nav navbar-nav navbar-right">
            <li><a href="index.php" style="font-weight: bold;">Voltar para o Login</a></li>
          </ul>
        </div>
      </div>
    </nav>

    <div class="container main-container">
        <div class="signup-box">
            <h3>Crie sua conta no Twitter Clone</h3>
            <form method="POST" action="processa.php" id="formCadastrarse">
                <div class="form-group">
                    <input type="text" class="form-control" id="usuario" name="usuario" placeholder="Nome de usuário" required="required">
                </div>
                <div class="form-group">
                    <input type="email" class="form-control" id="email" name="email" placeholder="Endereço de e-mail" required="required">
                </div>
                <div class="form-group">
                    <input type="password" class="form-control" id="senha" name="senha" placeholder="Crie uma senha" required="required">
                </div>
                <button type="submit" class="btn btn-twitter">Inscrever-se</button>
            </form>
            <div style="margin-top: 20px; text-align: center; font-size: 13px; color: #657786;">
                Já tem uma conta? <a href="index.php">Entrar</a>
            </div>
        </div>
    </div>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>
</body>
</html>