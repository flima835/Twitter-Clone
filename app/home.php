<?php
session_start();
if(!isset($_SESSION['usuario'])){
    header('Location: index.php?erro=1');
    exit;
}

$con = null;
if (file_exists('conexao_banco.php')) {
    include_once('conexao_banco.php');
}

// ── Infraestrutura GKE ──────────────────────────────────────────
$pod_name      = getenv('HOSTNAME')              ?: gethostname() ?: 'desconhecido';
$namespace     = getenv('POD_NAMESPACE')         ?: 'default';
$node_name     = getenv('NODE_NAME')             ?: 'n/d';
$pod_ip        = getenv('POD_IP')                ?: $_SERVER['SERVER_ADDR'] ?? 'n/d';
$app_version   = getenv('APP_VERSION')           ?: 'v1';
$replica_count = getenv('REPLICA_COUNT')         ?: '1';

// ── Status do Banco ─────────────────────────────────────────────
$db_status = 'Online';
$db_class  = 'badge-success';
if (!$con || (is_object($con) && $con->connect_error)) {
    $db_status = 'Offline';
    $db_class  = 'badge-danger';
}

// ── Usuário da sessão ───────────────────────────────────────────
$usuario  = htmlspecialchars($_SESSION['usuario'] ?? 'Usuário');
$handle   = strtolower(str_replace(' ', '', $usuario));
$iniciais = strtoupper(substr($usuario, 0, 2));

// ── Tweets de exemplo (substituir por query real) ───────────────
$tweets = [
    [
        'nome'    => 'Maria Alves',
        'handle'  => 'mariaalves',
        'ini'     => 'MA',
        'cor'     => '#1da1f2',
        'tempo'   => '2min',
        'texto'   => 'Deploy no GKE feito com sucesso 🚀 Nova versão ' . $app_version . ' rodando em produção!',
        'replies' => 3, 'rts' => 7, 'likes' => 42,
    ],
    [
        'nome'    => 'Carlos SRE',
        'handle'  => 'carlossre',
        'ini'     => 'CS',
        'cor'     => '#17bf63',
        'tempo'   => '15min',
        'texto'   => 'kubectl scale deployment twitter-app --replicas=' . $replica_count . ' — Load balancer distribuindo entre os pods. SRE life! 🔄',
        'replies' => 1, 'rts' => 12, 'likes' => 28,
    ],
    [
        'nome'    => 'Larissa Dev',
        'handle'  => 'larissadev',
        'ini'     => 'LD',
        'cor'     => '#794bc4',
        'tempo'   => '1h',
        'texto'   => 'Alerta no Datadog disparado — banco MySQL ' . $db_status . ' no cluster. Node: ' . $node_name . ' 🔴',
        'replies' => 8, 'rts' => 5, 'likes' => 11,
    ],
];
?>
<!DOCTYPE HTML>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Twitter Clone – <?= $usuario ?></title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
    <script src="https://code.jquery.com/jquery-2.2.4.min.js"></script>
    <style>
        /* ── Reset & base ──────────────────────────────────────── */
        * { box-sizing: border-box; }
        body {
            background-color: #e6ecf0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            font-size: 14px;
            color: #14171a;
        }

        /* ── Navbar ────────────────────────────────────────────── */
        .navbar {
            background: #fff;
            border-bottom: 1px solid rgba(0,0,0,0.12);
            height: 55px;
            margin-bottom: 0;
            border-radius: 0;
        }
        .navbar-brand { padding: 10px 15px; }
        .navbar-brand img { width: 28px; margin-top: -2px; transition: transform .3s; }
        .navbar-brand img:hover { transform: scale(1.12); }
        .nav-sair { font-weight: 700; color: #657786 !important; }
        .nav-sair:hover { color: #1da1f2 !important; }

        /* ── Layout ────────────────────────────────────────────── */
        .page-wrap { padding: 18px 0 30px; }
        .col-left  { width: 240px; }
        .col-mid   { }
        .col-right { width: 210px; }

        /* ── Painel genérico ───────────────────────────────────── */
        .panel {
            border-radius: 10px;
            border: 1px solid #e1e8ed;
            background: #fff;
            margin-bottom: 14px;
            overflow: hidden;
        }
        .panel-heading {
            background: #f5f8fa;
            padding: 10px 14px;
            font-size: 13px;
            font-weight: 700;
            color: #14171a;
            border-bottom: 1px solid #e1e8ed;
        }
        .panel-body { padding: 14px; }

        /* ── Avatar / Perfil ───────────────────────────────────── */
        .img-perfil {
            width: 62px; height: 62px;
            border-radius: 50%;
            border: 2px solid #fff;
            box-shadow: 0 1px 4px rgba(0,0,0,.2);
            background: #1da1f2;
            color: #fff;
            font-weight: 700; font-size: 22px;
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 10px;
        }
        .profile-name   { text-align:center; font-weight:700; font-size:14px; }
        .profile-handle { text-align:center; font-size:12px; color:#657786; margin-top:2px; }
        .profile-stats  {
            display:flex; justify-content:space-around;
            margin-top:12px; padding-top:10px;
            border-top:1px solid #e1e8ed;
        }
        .stat-num   { font-weight:700; font-size:14px; text-align:center; }
        .stat-label { font-size:11px; color:#657786; text-align:center; }

        /* ── Bloco de status infra ─────────────────────────────── */
        .infra-box {
            font-size: 11px;
            margin-top: 12px;
            padding: 9px 10px;
            background: #f5f8fa;
            border-radius: 6px;
            border: 1px solid #e1e8ed;
        }
        .infra-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 5px;
            gap: 6px;
        }
        .infra-row:last-child { margin-bottom: 0; }
        .infra-key { color: #657786; white-space: nowrap; }
        .infra-val {
            font-family: 'Courier New', monospace;
            font-size: 10px;
            color: #1da1f2;
            text-align: right;
            word-break: break-all;
        }
        .badge-success { background:#17bf63; color:#fff; padding:1px 6px; border-radius:3px; font-size:10px; font-weight:700; }
        .badge-danger  { background:#e0245e; color:#fff; padding:1px 6px; border-radius:3px; font-size:10px; font-weight:700; }

        /* ── Compose box ───────────────────────────────────────── */
        .compose-box {
            background:#fff; border-radius:10px;
            border:1px solid #e1e8ed; padding:14px;
            margin-bottom:14px;
        }
        .compose-inner { display:flex; gap:10px; }
        .compose-avatar {
            width:42px; height:42px; border-radius:50%;
            background:#1da1f2; color:#fff;
            font-weight:700; font-size:14px;
            display:flex; align-items:center; justify-content:center;
            flex-shrink:0;
        }
        .compose-input {
            flex:1; border:none; outline:none; resize:none;
            font-size:15px; font-family:inherit;
            color:#14171a; background:transparent;
            padding-top:4px;
        }
        .compose-input::placeholder { color:#aab8c2; }
        .compose-footer {
            display:flex; justify-content:flex-end;
            margin-top:10px; padding-top:10px;
            border-top:1px solid #e1e8ed;
        }
        .btn-tweet {
            background:#1da1f2; color:#fff; border:none;
            border-radius:20px; padding:7px 18px;
            font-size:13px; font-weight:700; cursor:pointer;
            transition: background .2s;
        }
        .btn-tweet:hover { background:#1a91da; }

        /* ── Tweet card ────────────────────────────────────────── */
        .tweet {
            background:#fff; border-radius:10px;
            border:1px solid #e1e8ed; padding:14px;
            margin-bottom:10px;
            transition: background .15s;
        }
        .tweet:hover { background:#f5f8fa; }
        .tweet-header { display:flex; gap:10px; margin-bottom:8px; }
        .tweet-avatar {
            width:40px; height:40px; border-radius:50%;
            color:#fff; font-weight:700; font-size:13px;
            display:flex; align-items:center; justify-content:center;
            flex-shrink:0;
        }
        .tweet-name   { font-weight:700; font-size:13px; }
        .tweet-handle { font-size:12px; color:#657786; }
        .tweet-time   { font-size:12px; color:#aab8c2; margin-left:auto; white-space:nowrap; }
        .tweet-body   { font-size:14px; line-height:1.55; color:#14171a; }
        .tweet-actions { display:flex; gap:24px; margin-top:10px; }
        .t-action {
            display:flex; align-items:center; gap:5px;
            font-size:12px; color:#657786; cursor:pointer;
            transition: color .15s;
        }
        .t-action:hover { color:#1da1f2; }
        .t-action svg { width:16px; height:16px; fill:currentColor; }

        /* ── Tendências ────────────────────────────────────────── */
        .trend-item  { padding:8px 0; border-bottom:1px solid #f0f0f0; }
        .trend-item:last-child { border-bottom:none; }
        .trend-cat   { font-size:11px; color:#657786; }
        .trend-name  { font-size:13px; font-weight:700; }
        .trend-count { font-size:11px; color:#aab8c2; }

        /* ── Quem seguir ───────────────────────────────────────── */
        .follow-item { display:flex; align-items:center; gap:10px; margin-bottom:10px; }
        .follow-item:last-child { margin-bottom:0; }
        .follow-avatar {
            width:34px; height:34px; border-radius:50%;
            color:#fff; font-size:11px; font-weight:700;
            display:flex; align-items:center; justify-content:center;
            flex-shrink:0;
        }
        .follow-btn {
            margin-left:auto; border:1px solid #1da1f2;
            color:#1da1f2; background:transparent;
            border-radius:14px; padding:3px 12px;
            font-size:12px; font-weight:700; cursor:pointer;
            transition: all .2s;
        }
        .follow-btn:hover { background:#1da1f2; color:#fff; }

        /* ── Footer ────────────────────────────────────────────── */
        .page-footer {
            text-align:center; font-size:11px;
            color:#aab8c2; margin-top:8px;
        }
    </style>
</head>
<body>

<!-- ── Navbar ───────────────────────────────────────────────────── -->
<nav class="navbar navbar-default navbar-static-top">
    <div class="container">
        <div class="navbar-header">
            <a class="navbar-brand" href="home.php">
                <img src="https://upload.wikimedia.org/wikipedia/commons/6/6f/Logo_of_Twitter.svg" alt="Twitter">
            </a>
        </div>
        <div class="collapse navbar-collapse">
            <ul class="nav navbar-nav navbar-right">
                <li><a href="sair.php" class="nav-sair" style="margin-top:15px;display:block;">Sair</a></li>
            </ul>
        </div>
    </div>
</nav>

<!-- ── Conteúdo ─────────────────────────────────────────────────── -->
<div class="container page-wrap">
    <div class="row">

        <!-- Coluna Esquerda -->
        <div class="col-md-3">

            <!-- Perfil -->
            <div class="panel">
                <div class="panel-heading">Meu Perfil</div>
                <div class="panel-body" style="text-align:center;">
                    <div class="img-perfil"><?= $iniciais ?></div>
                    <div class="profile-name"><?= $usuario ?></div>
                    <div class="profile-handle">@<?= $handle ?></div>
                    <div class="profile-stats">
                        <div><div class="stat-num">0</div><div class="stat-label">tweets</div></div>
                        <div><div class="stat-num">0</div><div class="stat-label">seguindo</div></div>
                        <div><div class="stat-num">0</div><div class="stat-label">seguidores</div></div>
                    </div>

                    <!-- Status Infraestrutura -->
                    <div class="infra-box">
                        <div class="infra-row">
                            <span class="infra-key">Banco:</span>
                            <span class="<?= $db_class ?>"><?= $db_status ?></span>
                        </div>
                        <div class="infra-row">
                            <span class="infra-key">Pod:</span>
                            <span class="infra-val" title="<?= htmlspecialchars($pod_name) ?>">
                                <?= htmlspecialchars(substr($pod_name, 0, 22)) ?>…
                            </span>
                        </div>
                        <div class="infra-row">
                            <span class="infra-key">Namespace:</span>
                            <span class="infra-val"><?= htmlspecialchars($namespace) ?></span>
                        </div>
                        <div class="infra-row">
                            <span class="infra-key">Node:</span>
                            <span class="infra-val"><?= htmlspecialchars($node_name) ?></span>
                        </div>
                        <div class="infra-row">
                            <span class="infra-key">Pod IP:</span>
                            <span class="infra-val"><?= htmlspecialchars($pod_ip) ?></span>
                        </div>
                        <div class="infra-row">
                            <span class="infra-key">Versão:</span>
                            <span class="infra-val"><?= htmlspecialchars($app_version) ?></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Coluna Central -->
        <div class="col-md-6">

            <!-- Compose -->
            <div class="compose-box">
                <div class="compose-inner">
                    <div class="compose-avatar"><?= $iniciais ?></div>
                    <textarea class="compose-input" rows="2" placeholder="O que está acontecendo?"></textarea>
                </div>
                <div class="compose-footer">
                    <button class="btn-tweet">Tweetar</button>
                </div>
            </div>

            <!-- Timeline -->
            <?php foreach ($tweets as $t): ?>
            <div class="tweet">
                <div class="tweet-header">
                    <div class="tweet-avatar" style="background:<?= $t['cor'] ?>;"><?= $t['ini'] ?></div>
                    <div style="flex:1;">
                        <div class="tweet-name"><?= htmlspecialchars($t['nome']) ?></div>
                        <div class="tweet-handle">@<?= htmlspecialchars($t['handle']) ?></div>
                    </div>
                    <div class="tweet-time"><?= $t['tempo'] ?></div>
                </div>
                <div class="tweet-body"><?= htmlspecialchars($t['texto']) ?></div>
                <div class="tweet-actions">
                    <span class="t-action">
                        <!-- ícone reply -->
                        <svg viewBox="0 0 24 24"><path d="M14.046 2.242l-4.148-.01h-.002c-4.374 0-7.8 3.427-7.8 7.802 0 4.098 3.186 7.206 7.465 7.37v3.828a.85.85 0 00.518.787.83.83 0 00.868-.16l1.305-1.168c.891-.7 8.04-6.271 8.04-10.657 0-4.375-3.426-7.8-7.8-7.8l.002.008zm3.817 12.069c-.886.893-2.851 2.391-5.837 4.573V17.49a.75.75 0 00-.75-.75h-.396c-3.66 0-6.318-2.476-6.318-5.886 0-3.534 2.768-6.302 6.3-6.302l4.147.01h.002c3.532 0 6.3 2.766 6.3 6.296 0 2.23-2.088 4.116-3.448 5.452z"/></svg>
                        <?= $t['replies'] ?>
                    </span>
                    <span class="t-action">
                        <!-- ícone retweet -->
                        <svg viewBox="0 0 24 24"><path d="M23.615 15.477c-.47-.47-1.23-.47-1.697 0l-1.326 1.326V7.4c0-2.178-1.772-3.95-3.95-3.95h-5.2a1.2 1.2 0 000 2.4h5.2c.854 0 1.55.695 1.55 1.55v9.401l-1.326-1.325c-.47-.47-1.23-.47-1.697 0s-.47 1.23 0 1.697l3.374 3.375a1.2 1.2 0 001.698 0l3.375-3.375c.468-.467.468-1.228-.001-1.696zM12.562 18.15h-5.2c-.854 0-1.55-.695-1.55-1.55V7.199l1.326 1.326c.47.47 1.23.47 1.697 0s.47-1.23 0-1.697L5.46 3.453a1.2 1.2 0 00-1.698 0L.388 6.828c-.467.47-.467 1.23 0 1.697s1.23.47 1.697 0L3.41 7.2v9.4c0 2.178 1.772 3.95 3.95 3.95h5.2a1.2 1.2 0 000-2.4z"/></svg>
                        <?= $t['rts'] ?>
                    </span>
                    <span class="t-action">
                        <!-- ícone like -->
                        <svg viewBox="0 0 24 24"><path d="M12 21.638h-.014C9.403 21.59 1.95 14.856 1.95 8.478c0-3.064 2.525-5.754 5.403-5.754 2.29 0 3.83 1.58 4.646 2.73.814-1.148 2.354-2.73 4.645-2.73 2.88 0 5.404 2.69 5.404 5.755 0 6.376-7.454 13.11-10.037 13.157H12z"/></svg>
                        <?= $t['likes'] ?>
                    </span>
                </div>
            </div>
            <?php endforeach; ?>

        </div>

        <!-- Coluna Direita -->
        <div class="col-md-3">

            <!-- Tendências -->
            <div class="panel" style="margin-bottom:14px;">
                <div class="panel-heading">Tendências</div>
                <div class="panel-body">
                    <?php
                    $trends = [
                        ['cat'=>'Tecnologia', 'tag'=>'#GKE',        'count'=>'8,4k tweets'],
                        ['cat'=>'DevOps',     'tag'=>'#Kubernetes',  'count'=>'15k tweets'],
                        ['cat'=>'SRE',        'tag'=>'#Datadog',     'count'=>'3,2k tweets'],
                        ['cat'=>'Cloud',      'tag'=>'#GCP',         'count'=>'22k tweets'],
                    ];
                    foreach ($trends as $tr): ?>
                    <div class="trend-item">
                        <div class="trend-cat"><?= $tr['cat'] ?></div>
                        <div class="trend-name"><?= $tr['tag'] ?></div>
                        <div class="trend-count"><?= $tr['count'] ?></div>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>

            <!-- Quem seguir -->
            <div class="panel">
                <div class="panel-heading">Quem seguir</div>
                <div class="panel-body">
                    <?php
                    $sugestoes = [
                        ['ini'=>'TK','cor'=>'#e0245e','nome'=>'TechKid', 'handle'=>'techkid'],
                        ['ini'=>'DP','cor'=>'#ffad1f','nome'=>'DevPro',  'handle'=>'devpro'],
                    ];
                    foreach ($sugestoes as $s): ?>
                    <div class="follow-item">
                        <div class="follow-avatar" style="background:<?= $s['cor'] ?>;"><?= $s['ini'] ?></div>
                        <div>
                            <div style="font-weight:700;font-size:13px;"><?= $s['nome'] ?></div>
                            <div style="font-size:12px;color:#657786;">@<?= $s['handle'] ?></div>
                        </div>
                        <button class="follow-btn">Seguir</button>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>

        </div>
    </div><!-- /.row -->

    <div class="page-footer">
        Twitter Clone · Pod: <?= htmlspecialchars($pod_name) ?> · Versão <?= htmlspecialchars($app_version) ?>
    </div>
</div><!-- /.container -->

</body>
</html>