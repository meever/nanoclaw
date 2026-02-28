$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$learnDir = Join-Path $root 'learn'
$chaptersDir = Join-Path $learnDir 'chapters'
$outFile = Join-Path $learnDir 'book.html'

if (-not (Test-Path $chaptersDir)) {
  throw "Missing chapters directory: $chaptersDir"
}

function Escape-Html([string]$text) {
  if ($null -eq $text) { return '' }
  return $text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
}

function Convert-Inline([string]$line) {
  $line = Escape-Html $line
  $line = [regex]::Replace($line, '`([^`]+)`', '<code>$1</code>')
  $line = [regex]::Replace($line, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
  $line = [regex]::Replace($line, '\*([^*]+)\*', '<em>$1</em>')
  $line = [regex]::Replace($line, '\[([^\]]+)\]\(([^\)]+)\)', '<a href="$2">$1</a>')
  return $line
}

function Convert-Markdown([string]$content) {
  $lines = $content -split "`r?`n"
  $html = New-Object System.Collections.Generic.List[string]
  $inCode = $false
  $inUl = $false
  $inOl = $false

  foreach ($raw in $lines) {
    $line = $raw.TrimEnd()

    if ($line -match '^```') {
      if (-not $inCode) {
        if ($inUl) { $html.Add('</ul>'); $inUl = $false }
        if ($inOl) { $html.Add('</ol>'); $inOl = $false }
        $html.Add('<pre><code>')
        $inCode = $true
      } else {
        $html.Add('</code></pre>')
        $inCode = $false
      }
      continue
    }

    if ($inCode) {
      $html.Add((Escape-Html $raw))
      continue
    }

    if ([string]::IsNullOrWhiteSpace($line)) {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      continue
    }

    if ($line -match '^###\s+(.+)$') {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      $html.Add("<h3>$(Convert-Inline $matches[1])</h3>")
      continue
    }

    if ($line -match '^##\s+(.+)$') {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      $html.Add("<h2>$(Convert-Inline $matches[1])</h2>")
      continue
    }

    if ($line -match '^#\s+(.+)$') {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      $html.Add("<h1>$(Convert-Inline $matches[1])</h1>")
      continue
    }

    if ($line -match '^\d+\.\s+(.+)$') {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if (-not $inOl) { $html.Add('<ol>'); $inOl = $true }
      $html.Add("<li>$(Convert-Inline $matches[1])</li>")
      continue
    }

    if ($line -match '^[-*]\s+(.+)$') {
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      if (-not $inUl) { $html.Add('<ul>'); $inUl = $true }
      $html.Add("<li>$(Convert-Inline $matches[1])</li>")
      continue
    }

    if ($inUl) { $html.Add('</ul>'); $inUl = $false }
    if ($inOl) { $html.Add('</ol>'); $inOl = $false }
    $html.Add("<p>$(Convert-Inline $line)</p>")
  }

  if ($inUl) { $html.Add('</ul>') }
  if ($inOl) { $html.Add('</ol>') }
  if ($inCode) { $html.Add('</code></pre>') }

  return ($html -join "`n")
}

$chapterFiles = Get-ChildItem -Path $chaptersDir -Filter '*.md' | Sort-Object Name
if ($chapterFiles.Count -eq 0) {
  throw "No chapter files found in $chaptersDir"
}

$sections = New-Object System.Collections.Generic.List[string]
foreach ($file in $chapterFiles) {
  $md = Get-Content -Path $file.FullName -Raw -Encoding UTF8
  $body = Convert-Markdown $md
  $sections.Add("<section class='chapter' id='$($file.BaseName)'>$body</section>")
}

$tocItems = $chapterFiles | ForEach-Object {
  "<li><a href='#$($_.BaseName)'>$($_.BaseName)</a></li>"
}

$book = @"
<!doctype html>
<html lang='en'>
<head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <title>NanoClaw Learning Book</title>
  <style>
    :root { color-scheme: light dark; }
    body { font-family: Segoe UI, Arial, sans-serif; margin: 0; padding: 0; line-height: 1.55; }
    main { max-width: 980px; margin: 0 auto; padding: 24px; }
    h1, h2, h3 { line-height: 1.2; }
    nav { padding: 16px; border: 1px solid #7f7f7f55; border-radius: 8px; margin-bottom: 24px; }
    nav ul { margin: 0; padding-left: 20px; }
    .chapter { margin-bottom: 40px; padding-bottom: 24px; border-bottom: 1px solid #7f7f7f33; }
    pre { overflow: auto; padding: 12px; border-radius: 8px; background: #00000018; }
    code { font-family: Consolas, Menlo, monospace; }
    a { text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <main>
    <h1>NanoClaw Learning Book</h1>
    <p>Generated from markdown chapters in <code>learn/chapters</code>.</p>
    <nav>
      <h2>Table of Contents</h2>
      <ul>
        $($tocItems -join "`n        ")
      </ul>
    </nav>
    $($sections -join "`n    ")
  </main>
</body>
</html>
"@

Set-Content -Path $outFile -Value $book -Encoding UTF8
Write-Host "Built learning book: $outFile"
