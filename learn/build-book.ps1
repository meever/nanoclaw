$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$learnDir = Join-Path $root 'learn'
$chaptersDir = Join-Path $learnDir 'chapters'
$outFile = Join-Path $learnDir 'book.html'

if (-not (Test-Path $chaptersDir)) {
  throw "Missing chapters directory: $chaptersDir"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Escape-Html([string]$text) {
  if ($null -eq $text) { return '' }
  return $text.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

function Convert-Inline([string]$line) {
  $line = Escape-Html $line
  $line = [regex]::Replace($line, '`([^`]+)`', '<code>$1</code>')
  $line = [regex]::Replace($line, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
  $line = [regex]::Replace($line, '\*([^*]+)\*', '<em>$1</em>')
  $line = [regex]::Replace($line, '\[([^\]]+)\]\(([^\)]+)\)', '<a href="$2">$1</a>')
  return $line
}

# ---------------------------------------------------------------------------
# Markdown -> HTML converter (with math-block and exercise support)
# ---------------------------------------------------------------------------

function Convert-Markdown([string]$content) {
  $lines = $content -split "`r?`n"
  $html = [System.Collections.Generic.List[string]]::new()

  $inCode  = $false; $codeLang = ''; $codeBuffer = $null
  $inMath  = $false; $mathBuffer = $null
  $inUl    = $false; $inOl = $false

  foreach ($raw in $lines) {
    $line = $raw.TrimEnd()

    # ---- code fence ----
    if ($line -match '^```([a-zA-Z0-9_-]+)?\s*$') {
      if (-not $inCode -and -not $inMath) {
        if ($inUl) { $html.Add('</ul>'); $inUl = $false }
        if ($inOl) { $html.Add('</ol>'); $inOl = $false }
        $codeLang = if ($matches[1]) { $matches[1].ToLowerInvariant() } else { '' }
        $codeBuffer = [System.Collections.Generic.List[string]]::new()
        $inCode = $true
      } else {
        if ($codeLang -eq 'mermaid') {
          $diagram = Escape-Html ($codeBuffer -join "`n")
          $html.Add("<div class='diagram-wrap'><pre class='mermaid'>$diagram</pre></div>")
        } else {
          $langBadge = if ($codeLang) { "<span class='lang-badge'>$codeLang</span>" } else { '' }
          $escaped = ($codeBuffer | ForEach-Object { Escape-Html $_ }) -join "`n"
          $html.Add("<div class='code-wrap'>$langBadge<pre><code>$escaped</code></pre></div>")
        }
        $inCode = $false; $codeLang = ''
      }
      continue
    }
    if ($inCode) { $codeBuffer.Add($raw); continue }

    # ---- display math ($$ on its own line) ----
    if ($line -match '^\$\$\s*$') {
      if (-not $inMath) {
        if ($inUl) { $html.Add('</ul>'); $inUl = $false }
        if ($inOl) { $html.Add('</ol>'); $inOl = $false }
        $mathBuffer = [System.Collections.Generic.List[string]]::new()
        $inMath = $true
      } else {
        $mc = $mathBuffer -join "`n"
        $html.Add('<div class="math-block">' + '$$' + "`n" + $mc + "`n" + '$$' + '</div>')
        $inMath = $false
      }
      continue
    }
    if ($inMath) { $mathBuffer.Add($raw); continue }

    # ---- blank line ----
    if ([string]::IsNullOrWhiteSpace($line)) {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      continue
    }

    # ---- headings ----
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

    # ---- blockquote ----
    if ($line -match '^>\s?(.*)$') {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      $html.Add("<blockquote><p>$(Convert-Inline $matches[1])</p></blockquote>")
      continue
    }

    # ---- horizontal rule ----
    if ($line -match '^-{3,}\s*$' -or $line -match '^\*{3,}\s*$') {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      $html.Add('<hr>')
      continue
    }

    # ---- ordered list ----
    if ($line -match '^\d+\.\s+(.+)$') {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if (-not $inOl) { $html.Add('<ol>'); $inOl = $true }
      $html.Add("<li>$(Convert-Inline $matches[1])</li>")
      continue
    }

    # ---- unordered list ----
    if ($line -match '^[-*]\s+(.+)$') {
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      if (-not $inUl) { $html.Add('<ul>'); $inUl = $true }
      $html.Add("<li>$(Convert-Inline $matches[1])</li>")
      continue
    }

    # ---- exercise callout ----
    if ($line -match '^Exercise:\s*(.+)$') {
      if ($inUl) { $html.Add('</ul>'); $inUl = $false }
      if ($inOl) { $html.Add('</ol>'); $inOl = $false }
      $html.Add("<div class='callout exercise'><div class='callout-title'>&#9998; Exercise</div><p>$(Convert-Inline $matches[1])</p></div>")
      continue
    }

    # ---- paragraph ----
    if ($inUl) { $html.Add('</ul>'); $inUl = $false }
    if ($inOl) { $html.Add('</ol>'); $inOl = $false }
    $html.Add("<p>$(Convert-Inline $line)</p>")
  }

  # close any open blocks
  if ($inUl) { $html.Add('</ul>') }
  if ($inOl) { $html.Add('</ol>') }
  if ($inMath) {
    $mc = $mathBuffer -join "`n"
    $html.Add('<div class="math-block">' + '$$' + "`n" + $mc + "`n" + '$$' + '</div>')
  }
  if ($inCode) {
    if ($codeLang -eq 'mermaid') {
      $diagram = Escape-Html ($codeBuffer -join "`n")
      $html.Add("<div class='diagram-wrap'><pre class='mermaid'>$diagram</pre></div>")
    } else {
      $escaped = ($codeBuffer | ForEach-Object { Escape-Html $_ }) -join "`n"
      $html.Add("<pre><code>$escaped</code></pre>")
    }
  }

  return ($html -join "`n")
}

# ---------------------------------------------------------------------------
# Process chapters
# ---------------------------------------------------------------------------

$chapterFiles = Get-ChildItem -Path $chaptersDir -Filter '*.md' | Sort-Object Name
if ($chapterFiles.Count -eq 0) { throw "No chapter files in $chaptersDir" }

$sections = [System.Collections.Generic.List[string]]::new()
$tocItems = [System.Collections.Generic.List[string]]::new()

foreach ($file in $chapterFiles) {
  $md = Get-Content -Path $file.FullName -Raw -Encoding UTF8
  $id = $file.BaseName

  # Extract chapter number & title from "# Chapter NN - Title"
  $chapterNum = ''
  $chapterTitle = $file.BaseName -replace '^\d+-','' -replace '-',' '

  $headingRx = [regex]::new('(?m)^#\s+Chapter\s+(\d+)\s*[\u2014\u2013\-]\s*(.+)$')
  $hm = $headingRx.Match($md)
  if ($hm.Success) {
    $chapterNum   = $hm.Groups[1].Value
    $chapterTitle = $hm.Groups[2].Value.Trim()
    $md = $headingRx.Replace($md, '', 1)             # strip heading from body
  }

  $body = Convert-Markdown $md
  $numDiv = if ($chapterNum) { "<div class='chapter-num'>$chapterNum</div>" } else { '' }

  $sections.Add(
    "<article class='chapter' id='$id'>" +
    "$numDiv<h1 class='chapter-title'>$(Escape-Html $chapterTitle)</h1>" +
    "<div class='chapter-body'>$body</div></article>"
  )

  $tocNumSpan = if ($chapterNum) { "<span class='toc-num'>$chapterNum</span>" } else { '' }
  $tocItems.Add("<li><a href='#$id'>$tocNumSpan$(Escape-Html $chapterTitle)</a></li>")
}

# ---------------------------------------------------------------------------
# HTML template  (literal here-string — no PowerShell expansion, $$ stays $$)
# ---------------------------------------------------------------------------

$template = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>NanoClaw &mdash; Learning Book</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
  <style>
/* ===== Variables ===== */
:root {
  --bg:          #f5f3ef;
  --surface:     #ffffff;
  --text:        #2d3748;
  --text-muted:  #718096;
  --accent:      #5b4cd8;
  --accent-soft: #eeeaff;
  --border:      #e2e0dc;
  --green:       #2f9e44;
  --exercise-bg: #f0fdf4;
  --code-bg:     #282c34;
  --code-text:   #abb2bf;
  --chapter-num: #eeeaff;
  --diagram-bg:  #f8f7ff;
  --shadow:      0 1px 3px rgba(0,0,0,.06);
}
@media (prefers-color-scheme: dark) { :root {
  --bg:          #0f1219;
  --surface:     #1a2030;
  --text:        #e2e8f0;
  --text-muted:  #94a3b8;
  --accent:      #a78bfa;
  --accent-soft: #1e1b3a;
  --border:      #2d3548;
  --green:       #4ade80;
  --exercise-bg: #0a2618;
  --code-bg:     #0d1117;
  --code-text:   #c9d1d9;
  --chapter-num: #1e1b3a;
  --diagram-bg:  #1a1832;
  --shadow:      0 1px 4px rgba(0,0,0,.3);
}}

/* ===== Reset & Base ===== */
*, *::before, *::after { box-sizing: border-box; }
html { height: 100%; scroll-behavior: smooth; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  font-size: 16.5px;
  line-height: 1.75;
  -webkit-font-smoothing: antialiased;
}

/* ===== Progress bar ===== */
#progress {
  position: fixed; top: 0; left: 0; height: 3px;
  background: linear-gradient(90deg, var(--accent), #e879f9);
  z-index: 200; width: 0; transition: width 120ms ease-out;
  border-radius: 0 2px 2px 0;
}

/* ===== Layout ===== */
.layout {
  max-width: 1380px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: 290px 1fr;
  gap: 28px;
  padding: 20px;
  min-height: 100vh;
}

/* ===== Sidebar ===== */
.sidebar {
  position: sticky; top: 20px; align-self: start;
  max-height: calc(100vh - 40px);
  overflow-y: auto; overflow-x: hidden;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 22px 18px;
  box-shadow: var(--shadow);
}
.sidebar::-webkit-scrollbar { width: 5px; }
.sidebar::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
.sidebar-brand {
  display: flex; align-items: center; gap: 10px;
  margin-bottom: 6px;
}
.sidebar-brand svg { flex-shrink: 0; }
.sidebar-brand h1 {
  margin: 0; font-size: 1.1rem; font-weight: 700;
  font-family: Georgia, Cambria, 'Times New Roman', serif;
  letter-spacing: -0.01em;
}
.sidebar > p {
  margin: 0 0 18px; color: var(--text-muted);
  font-size: 0.82rem; line-height: 1.5;
}
.sidebar h2 {
  margin: 0 0 8px; color: var(--text-muted);
  font-size: 0.72rem; text-transform: uppercase;
  letter-spacing: 0.1em; font-weight: 600;
}
.sidebar ul { list-style: none; margin: 0; padding: 0; }
.sidebar li + li { margin-top: 2px; }
.sidebar a {
  display: flex; align-items: baseline; gap: 8px;
  color: var(--text); text-decoration: none;
  padding: 7px 10px; border-radius: 8px;
  font-size: 0.86rem; line-height: 1.35;
  transition: background .15s, color .15s;
}
.sidebar a:hover { background: var(--accent-soft); color: var(--accent); }
.sidebar a.active {
  background: var(--accent-soft); color: var(--accent);
  font-weight: 600;
}
.toc-num {
  display: inline-flex; align-items: center; justify-content: center;
  min-width: 24px; height: 20px;
  font-size: 0.72rem; font-weight: 700;
  color: var(--accent); background: var(--accent-soft);
  border-radius: 5px; flex-shrink: 0;
}

/* ===== Content ===== */
.content {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 0;
  min-width: 0;
  box-shadow: var(--shadow);
  overflow: hidden;
}

/* ===== Book Cover ===== */
.book-cover {
  background: linear-gradient(135deg, var(--accent) 0%, #7c3aed 50%, #e879f9 100%);
  color: #fff;
  padding: 52px 42px 44px;
  text-align: center;
}
.cover-badge {
  display: inline-block;
  font-size: 0.72rem; font-weight: 700; text-transform: uppercase;
  letter-spacing: 0.14em;
  background: rgba(255,255,255,.18); backdrop-filter: blur(4px);
  padding: 5px 14px; border-radius: 20px;
  margin-bottom: 18px;
}
.book-cover h1 {
  margin: 0 0 10px;
  font-family: Georgia, Cambria, 'Times New Roman', serif;
  font-size: 2.6rem; line-height: 1.15;
  font-weight: 700; letter-spacing: -0.02em;
}
.book-cover p {
  margin: 0; font-size: 1.05rem; opacity: .88; max-width: 520px;
  margin: 0 auto; line-height: 1.55;
}
.cover-meta {
  margin-top: 22px; font-size: 0.82rem; opacity: .7;
  display: flex; align-items: center; justify-content: center; gap: 8px;
}
.meta-dot { font-size: 0.5rem; }

/* ===== Chapter ===== */
.chapters-wrap { padding: 10px 40px 50px; }

.chapter {
  padding: 44px 0 40px;
  border-bottom: 1px solid var(--border);
  scroll-margin-top: 20px;
  position: relative;
}
.chapter:last-child { border-bottom: none; padding-bottom: 0; }

.chapter-num {
  font-size: 5.5rem; font-weight: 800; line-height: 1;
  color: var(--chapter-num); letter-spacing: -0.04em;
  margin-bottom: -18px; user-select: none;
  font-family: Georgia, Cambria, 'Times New Roman', serif;
}

.chapter-title {
  font-family: Georgia, Cambria, 'Times New Roman', serif;
  font-size: 1.75rem; line-height: 1.25;
  margin: 0 0 24px; font-weight: 700;
  letter-spacing: -0.01em;
  color: var(--text);
}

.chapter-body { }

/* ===== Typography ===== */
h1, h2, h3 { line-height: 1.3; }
.chapter-body h1 {
  font-family: Georgia, Cambria, 'Times New Roman', serif;
  font-size: 1.5rem; margin: 36px 0 14px;
}
.chapter-body h2 {
  font-size: 1.2rem; margin: 32px 0 12px;
  color: var(--accent); font-weight: 700;
  padding-bottom: 6px;
  border-bottom: 2px solid var(--accent-soft);
}
.chapter-body h3 {
  font-size: 1.05rem; margin: 24px 0 10px; font-weight: 600;
}
.chapter-body p {
  margin: 0 0 14px;
}
.chapter-body ul, .chapter-body ol {
  margin: 0 0 14px; padding-left: 24px;
}
.chapter-body li { margin-bottom: 5px; }
.chapter-body li::marker { color: var(--accent); }

blockquote {
  margin: 16px 0; padding: 12px 20px;
  border-left: 4px solid var(--accent);
  background: var(--accent-soft);
  border-radius: 0 8px 8px 0;
}
blockquote p { margin: 0; }

a { color: var(--accent); text-decoration-thickness: 1px; text-underline-offset: 2px; }
a:hover { text-decoration-thickness: 2px; }

hr {
  border: none; height: 1px;
  background: var(--border); margin: 28px 0;
}

/* ===== Inline code ===== */
code {
  font-family: 'Cascadia Code', 'Fira Code', Consolas, 'Liberation Mono', monospace;
  font-size: 0.88em;
  background: var(--accent-soft);
  color: var(--accent);
  padding: 0.15em 0.4em;
  border-radius: 5px;
  font-weight: 500;
}
pre code {
  background: transparent; color: inherit;
  padding: 0; font-weight: 400;
}

/* ===== Code blocks ===== */
.code-wrap {
  position: relative; margin: 18px 0;
  border-radius: 10px; overflow: hidden;
  border: 1px solid var(--border);
}
.code-wrap pre {
  margin: 0;
  background: var(--code-bg); color: var(--code-text);
  padding: 16px 18px; overflow-x: auto;
  font-size: 0.88rem; line-height: 1.6;
  border-radius: 0; border: none;
}
.lang-badge {
  position: absolute; top: 0; right: 0;
  font-size: 0.68rem; font-weight: 600; text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 3px 10px;
  background: rgba(255,255,255,.08); color: var(--code-text);
  border-radius: 0 10px 0 8px;
  opacity: .6;
}

/* ===== Math blocks ===== */
.math-block {
  text-align: center;
  margin: 22px 0;
  padding: 18px 20px;
  background: var(--accent-soft);
  border-radius: 10px;
  border: 1px solid var(--border);
  overflow-x: auto;
  font-size: 1.1em;
}

/* ===== Mermaid diagrams ===== */
.diagram-wrap {
  margin: 22px 0;
  padding: 20px;
  background: var(--diagram-bg);
  border: 1px solid var(--border);
  border-radius: 10px;
  text-align: center;
  overflow-x: auto;
}
.diagram-wrap pre.mermaid {
  background: transparent; border: none;
  padding: 0; margin: 0;
  font-size: 0.9rem;
}

/* ===== Exercise callout ===== */
.callout {
  margin: 22px 0; padding: 16px 20px;
  border-radius: 0 10px 10px 0;
}
.callout.exercise {
  border-left: 4px solid var(--green);
  background: var(--exercise-bg);
}
.callout-title {
  font-weight: 700; font-size: 0.78rem;
  text-transform: uppercase; letter-spacing: 0.08em;
  color: var(--green); margin-bottom: 6px;
}
.callout p { margin: 0; }

/* ===== Tables ===== */
table {
  width: 100%; border-collapse: collapse;
  margin: 16px 0; font-size: 0.92rem;
}
th, td {
  text-align: left; padding: 8px 12px;
  border-bottom: 1px solid var(--border);
}
th { font-weight: 600; font-size: 0.82rem; text-transform: uppercase; letter-spacing: 0.04em; color: var(--text-muted); }

/* ===== Responsive ===== */
@media (max-width: 960px) {
  .layout { grid-template-columns: 1fr; padding: 12px; gap: 16px; }
  .sidebar { position: static; max-height: none; }
  .chapters-wrap { padding: 10px 20px 40px; }
  .book-cover { padding: 36px 24px 32px; }
  .book-cover h1 { font-size: 1.8rem; }
  .chapter-num { font-size: 3.5rem; }
}
@media (max-width: 480px) {
  body { font-size: 15px; }
  .chapters-wrap { padding: 8px 14px 30px; }
  .chapter-title { font-size: 1.35rem; }
}

/* ===== Print ===== */
@media print {
  .sidebar, #progress { display: none; }
  .layout { display: block; }
  .content { border: none; box-shadow: none; }
  .book-cover { background: none; color: var(--text); padding: 20px 0; }
  .chapter { page-break-inside: avoid; }
}
  </style>
</head>
<body>
  <div id="progress"></div>
  <div class="layout">

    <aside class="sidebar">
      <div class="sidebar-brand">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/>
          <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>
        </svg>
        <h1>NanoClaw</h1>
      </div>
      <p>A beginner&rsquo;s guide to Claude agents, TypeScript orchestration, and container isolation.</p>
      <h2>Contents</h2>
      <ul>
__TOC__
      </ul>
    </aside>

    <main class="content">
      <header class="book-cover">
        <div class="cover-badge">Learning Guide</div>
        <h1>NanoClaw</h1>
        <p>A hands-on path from zero to production &mdash; Claude agents, TypeScript orchestration, and container isolation.</p>
        <div class="cover-meta">
          <span>16 Chapters</span>
          <span class="meta-dot">&middot;</span>
          <span>From Zero to Production</span>
        </div>
      </header>

      <div class="chapters-wrap">
__SECTIONS__
      </div>
    </main>
  </div>

  <!-- Mermaid (ESM module, renders async) -->
  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
    const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    mermaid.initialize({ startOnLoad: false, theme: isDark ? 'dark' : 'default' });
    try { await mermaid.run({ querySelector: '.mermaid' }); } catch (e) { console.warn('Mermaid render:', e); }
  </script>

  <!-- KaTeX (synchronous at end of body so renderMathInElement exists) -->
  <script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
  <script>
    renderMathInElement(document.body, {
      delimiters: [
        { left: '$$', right: '$$', display: true },
        { left: '$',  right: '$',  display: false },
        { left: '\\(', right: '\\)', display: false },
        { left: '\\[', right: '\\]', display: true }
      ],
      throwOnError: false,
      ignoredTags: ['script','noscript','style','textarea','pre','code']
    });
  </script>

  <!-- Navigation & UI -->
  <script>
  (function() {
    // --- Progress bar ---
    var bar = document.getElementById('progress');
    window.addEventListener('scroll', function() {
      var h = document.documentElement.scrollHeight - window.innerHeight;
      bar.style.width = (h > 0 ? (window.scrollY / h * 100) : 0) + '%';
    });

    // --- ToC active tracking ---
    var tocLinks = Array.from(document.querySelectorAll('.sidebar a[href^="#"]'));
    var chapters = Array.from(document.querySelectorAll('.chapter'));

    function updateActive() {
      var scrollY = window.scrollY + 120;
      var active = chapters[0];
      for (var i = 0; i < chapters.length; i++) {
        if (chapters[i].offsetTop <= scrollY) active = chapters[i];
      }
      tocLinks.forEach(function(a) {
        a.classList.toggle('active', a.getAttribute('href') === '#' + active.id);
      });
    }
    window.addEventListener('scroll', updateActive, { passive: true });
    updateActive();

    // --- Smooth scroll ---
    tocLinks.forEach(function(link) {
      link.addEventListener('click', function(e) {
        e.preventDefault();
        var id = link.getAttribute('href');
        if (!id || id.length < 2) return;
        var el = document.getElementById(id.slice(1));
        if (el) {
          el.scrollIntoView({ behavior: 'smooth', block: 'start' });
          history.replaceState(null, '', id);
        }
      });
    });
  })();
  </script>
</body>
</html>
'@

# ---------------------------------------------------------------------------
# Assemble & write
# ---------------------------------------------------------------------------

$book = $template.Replace('__TOC__', ($tocItems -join "`n")).Replace('__SECTIONS__', ($sections -join "`n"))
[System.IO.File]::WriteAllText($outFile, $book, [System.Text.UTF8Encoding]::new($false))
Write-Host "Built learning book: $outFile ($($chapterFiles.Count) chapters)"
