<?php
/**
 * AI gateway for IDAT Academy. Route the paths in AI_FEATURES_API.md here.
 * Keep GROQ_API_KEY_1..3 and GEMINI_API_KEY_1..3 in the web-server environment.
 */
require __DIR__ . '/init.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonError('Method not allowed', 405);

// AI must always use a real sign-in token. Do not accept the public app key as
// identity: it is shipped with the mobile app and cannot identify a student.
if (empty($_SERVER['HTTP_AUTHORIZATION'])) jsonError('Authentication required.', 401);
$user = authenticate();
$path = rtrim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');
$body = jsonBody();

if (!preg_match('#^/api/ai/lessons/(\d+)/chat$#', $path, $match)) {
    jsonError('Unknown AI endpoint.', 404);
}
$question = trim((string)($body['question'] ?? ''));
if ($question === '' || mb_strlen($question) > 2000) jsonError('A question of up to 2,000 characters is required.');

// Replace this query with your lesson-chunk table. Never accept lesson text from
// the device: it would let a user bypass the course/enrolment content boundary.
$lessonId = (int)$match[1];
$db = getDB();
$access = $db->prepare('SELECT 1 FROM enrollments e JOIN lessons l ON l.course_id=e.course_id WHERE e.student_id=? AND l.id=? LIMIT 1');
$access->execute([$user['id'], $lessonId]);
if (!$access->fetchColumn()) jsonError('You are not enrolled in this lesson.', 403);
$chunks = $db->prepare('SELECT content, heading FROM lesson_chunks WHERE lesson_id=? ORDER BY position LIMIT 6');
$chunks->execute([$lessonId]);
$context = $chunks->fetchAll();
if (!$context) jsonError('This lesson is still being prepared for AI study support.', 409);
$material = implode("\n\n", array_map(fn($c) => ($c['heading'] ?? 'Lesson') . ":\n" . $c['content'], $context));

$system = 'You are IDAT Academy Study Companion. Answer only using the supplied lesson material. If it does not contain the answer, say so. Be concise and do not invent citations.';
$answer = callAi($system, "Lesson material:\n$material\n\nStudent question: $question");
echo json_encode(['answer' => $answer, 'sources' => array_map(fn($c) => ['heading' => $c['heading'] ?? 'Lesson'], $context)]);

function callAi(string $system, string $prompt): string {
    $providers = [];
    foreach (['GROQ', 'GEMINI'] as $provider) for ($i=1; $i<=3; $i++) {
        $key = getenv("{$provider}_API_KEY_$i");
        if ($key) $providers[] = [$provider, $key];
    }
    if (!$providers) jsonError('AI service is not configured.', 503);
    shuffle($providers);
    foreach ($providers as [$provider, $key]) {
        $result = $provider === 'GROQ' ? groq($key, $system, $prompt) : gemini($key, $system, $prompt);
        if ($result !== null) return $result;
    }
    jsonError('The AI service is temporarily busy. Please try again.', 503);
}
function groq(string $key, string $system, string $prompt): ?string {
    $payload = ['model' => getenv('GROQ_MODEL') ?: 'llama-3.3-70b-versatile', 'messages' => [['role'=>'system','content'=>$system],['role'=>'user','content'=>$prompt]], 'temperature'=>0.2, 'max_tokens'=>700];
    $data = json_decode(postJson('https://api.groq.com/openai/v1/chat/completions', $payload, ['Authorization: Bearer '.$key]), true);
    return $data['choices'][0]['message']['content'] ?? null;
}
function gemini(string $key, string $system, string $prompt): ?string {
    $model = getenv('GEMINI_MODEL') ?: 'gemini-2.5-flash';
    $url = 'https://generativelanguage.googleapis.com/v1beta/models/'.rawurlencode($model).':generateContent?key='.rawurlencode($key);
    $payload = ['system_instruction'=>['parts'=>[['text'=>$system]]], 'contents'=>[['role'=>'user','parts'=>[['text'=>$prompt]]]], 'generationConfig'=>['temperature'=>0.2,'maxOutputTokens'=>700]];
    $data = json_decode(postJson($url, $payload), true);
    return $data['candidates'][0]['content']['parts'][0]['text'] ?? null;
}
function postJson(string $url, array $payload, array $headers=[]): string {
    $ch = curl_init($url);
    curl_setopt_array($ch, [CURLOPT_POST=>true, CURLOPT_POSTFIELDS=>json_encode($payload), CURLOPT_HTTPHEADER=>array_merge(['Content-Type: application/json'], $headers), CURLOPT_RETURNTRANSFER=>true, CURLOPT_CONNECTTIMEOUT=>5, CURLOPT_TIMEOUT=>25]);
    $out = curl_exec($ch); $status = curl_getinfo($ch, CURLINFO_RESPONSE_CODE); curl_close($ch);
    return ($out !== false && $status >= 200 && $status < 300) ? $out : '{}';
}
