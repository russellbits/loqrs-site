<?php
// public/api/subscribe.php
header('Content-Type: text/html; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo '<p class="msg-error">Invalid request method.</p>';
    exit;
}

// 1. Honeypot check: if filled, pretend it worked and exit without touching MySQL
if (!empty($_POST['website'])) {
    echo '<p class="msg-success">Coupon reserved! We’ll send your free web locker code at launch.</p>';
    exit;
}

// 2. Validate email
$rawEmail = trim($_POST['email'] ?? '');
$email = filter_var($rawEmail, FILTER_VALIDATE_EMAIL);

if (!$email) {
    echo '<p class="msg-error">Please enter a valid email address.</p>';
    exit;
}

// Sanitize idPrefix for safe HTML attribute output (alphanumeric, dashes, underscores only)
$rawPrefix = $_POST['idPrefix'] ?? 'signup';
$idPrefix = preg_replace('/[^a-zA-Z0-9_-]/', '', $rawPrefix) ?: 'signup';
$inputId = htmlspecialchars($idPrefix . '-email', ENT_QUOTES, 'UTF-8');

// 3. Load external DB config (one directory above public root)
$configPath = __DIR__ . '/../../../db-config.php';
if (!file_exists($configPath)) {
    echo '<p class="msg-error">Server configuration error. Please try again later.</p>';
    exit;
}

$db = require $configPath;

try {
    $port = $db['port'] ?? 3306;
    $dsn = "mysql:host={$db['host']};port={$port};dbname={$db['name']};charset=utf8mb4";
    $pdo = new PDO($dsn, $db['user'], $db['pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);

    $stmt = $pdo->prepare('INSERT IGNORE INTO beta_waitlist (email) VALUES (:email)');
    $stmt->execute(['email' => strtolower($email)]);

    echo '<p class="msg-success">Coupon reserved! We’ll send your free web locker code at launch.</p>';
    echo "<input id=\"{$inputId}\" name=\"email\" type=\"email\" placeholder=\"myemail@onetime.use\" autocomplete=\"email\" aria-label=\"Email address\" required value=\"\" hx-swap-oob=\"true\" />";
} catch (PDOException $e) {
    error_log('Waitlist DB Error: ' . $e->getMessage());
    echo '<p class="msg-error">Something went wrong on our end. Please try again in a moment.</p>';
}
