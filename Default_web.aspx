<%@ Page Language="C#" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>

<script runat="server">
    // ==========================================================
    // BACKEND LOGIC
    // ==========================================================
    private static readonly object _counterLock = new object();
    string rootPath = "";
    string currentRelativePath = "";
    string parentDirectory = "";
    int visitorCount = 0;
    string serverBaseUrl = "";

    protected void Page_Load(object sender, EventArgs e)
    {
        serverBaseUrl = Request.Url.Scheme + "://" + Request.Url.Authority;
        rootPath = Server.MapPath("~/");
        string reqPath = Request.QueryString["path"];

        if (string.IsNullOrEmpty(reqPath))
        {
            currentRelativePath = "";
        }
        else
        {
            reqPath = reqPath.Replace("..", "").Replace("//", "/").TrimStart('/');
            currentRelativePath = reqPath;
            try
            {
                string checkPath = Path.GetFullPath(Path.Combine(rootPath, reqPath));
                if (!checkPath.StartsWith(rootPath)) currentRelativePath = "";
            }
            catch { currentRelativePath = ""; }
        }

        if (!string.IsNullOrEmpty(currentRelativePath))
        {
            int lastSlash = currentRelativePath.LastIndexOf('/');
            parentDirectory = (lastSlash > -1) ? currentRelativePath.Substring(0, lastSlash) : "";
        }

        string counterFile = Server.MapPath("~/counter.txt");
        if (Session["HasVisited"] == null)
        {
            lock (_counterLock)
            {
                try
                {
                    if (File.Exists(counterFile))
                    {
                        int.TryParse(File.ReadAllText(counterFile), out visitorCount);
                    }
                    visitorCount++;
                    File.WriteAllText(counterFile, visitorCount.ToString());
                    Session["HasVisited"] = "true";
                }
                catch { visitorCount = 0; }
            }
        }
        else
        {
            try { if (File.Exists(counterFile)) int.TryParse(File.ReadAllText(counterFile), out visitorCount); } catch { }
        }
    }

    // --- Helpers ---
    string GetIconClass(string ext)
    {
        ext = ext.ToLower();
        if (ext == ".png" || ext == ".jpg" || ext == ".jpeg" || ext == ".gif" || ext == ".webp") return "fa-solid fa-image text-purple";
        if (ext == ".pdf") return "fa-solid fa-file-pdf text-danger";
        if (ext == ".zip" || ext == ".rar" || ext == ".7z" || ext == ".tar" || ext == ".gz") return "fa-solid fa-file-zipper text-warning";
        if (ext == ".mp4" || ext == ".mkv" || ext == ".avi" || ext == ".mov" || ext == ".webm" || ext == ".ts") return "fa-solid fa-film text-success";
        if (ext == ".mp3" || ext == ".wav" || ext == ".flac") return "fa-solid fa-music text-info";
        if (ext == ".txt" || ext == ".log" || ext == ".xml" || ext == ".srt") return "fa-solid fa-file-lines text-secondary";
        if (ext == ".html" || ext == ".css" || ext == ".js" || ext == ".json" || ext == ".php") return "fa-solid fa-code text-dark";
        if (ext == ".apk") return "fa-brands fa-android text-success";
        if (ext == ".exe" || ext == ".msi" || ext == ".iso") return "fa-brands fa-windows text-primary";
        return "fa-solid fa-file text-muted";
    }

    bool IsPreviewableVideo(string ext) { ext = ext.ToLower(); return (ext == ".mp4" || ext == ".webm" || ext == ".ogg" || ext == ".mkv"); }
    bool IsPreviewableImage(string ext) { ext = ext.ToLower(); return (ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif" || ext == ".webp"); }

    string FormatSize(long bytes)
    {
        if (bytes >= 1073741824) return (bytes / 1073741824.0).ToString("0.00") + " GB";
        if (bytes >= 1048576) return (bytes / 1048576.0).ToString("0.00") + " MB";
        if (bytes >= 1024) return (bytes / 1024.0).ToString("0.00") + " KB";
        return bytes + " B";
    }
</script>

<!DOCTYPE html>
<html lang="en" data-bs-theme="light">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sarker Net | Premium File Server</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <style>
        :root {
            --font-main: 'Inter', sans-serif;
            --glass-bg: #ffffff;
            --glass-border: 1px solid #e2e8f0;
            --row-hover: #f8fafc;
            --header-bg: #ffffff;
            --text-main: #0f172a;
            --scrollbar-thumb: #cbd5e1;
            --scrollbar-track: #f1f5f9;
        }

        [data-bs-theme="dark"] {
            --glass-bg: #0f172a;
            --glass-border: 1px solid #1e293b;
            --row-hover: #1e293b;
            --header-bg: #0f172a;
            --text-main: #f8fafc;
            --scrollbar-thumb: #475569;
            --scrollbar-track: #1e293b;
        }

        html, body { height: 100%; overflow: hidden; margin: 0; padding: 0; }
        body { font-family: var(--font-main); background: var(--glass-bg); display: flex; flex-direction: column; color: var(--text-main); }

        /* --- Custom Scrollbar (Desktop Premium Look) --- */
        ::-webkit-scrollbar { width: 10px; height: 10px; }
        ::-webkit-scrollbar-track { background: var(--scrollbar-track); }
        ::-webkit-scrollbar-thumb { background: var(--scrollbar-thumb); border-radius: 5px; border: 2px solid var(--scrollbar-track); }
        ::-webkit-scrollbar-thumb:hover { background: #94a3b8; }

        /* Ticker */
        .news-ticker { flex: 0 0 40px; background: #1e293b; color: #fff; display: flex; align-items: center; overflow: hidden; border-bottom: 2px solid #3b82f6; z-index: 1060; }
        .ticker-content { display: inline-block; white-space: nowrap; animation: ticker 35s linear infinite; }
        @keyframes ticker { 0% { transform: translateX(100vw); } 100% { transform: translateX(-100%); } }

        /* App Layout */
        .app-header { flex: 0 0 auto; padding: 1rem 40px; border-bottom: var(--glass-border); background: var(--header-bg); z-index: 1050; }
        .app-toolbar { flex: 0 0 auto; padding: 0.75rem 40px; border-bottom: var(--glass-border); background: rgba(var(--bs-body-bg-rgb), 0.95); backdrop-filter: blur(10px); }
        .table-container { flex: 1 1 auto; overflow-y: auto; overflow-x: auto; position: relative; scroll-behavior: smooth; }

        /* Table Styling */
        .table-custom { margin-bottom: 0; width: 100%; border-collapse: separate; border-spacing: 0; }
        .table-custom thead th {
            position: sticky; top: 0; z-index: 100; background: var(--header-bg);
            box-shadow: 0 1px 0 var(--glass-border); font-weight: 600; text-transform: uppercase;
            font-size: 0.8rem; letter-spacing: 0.5px; padding: 16px 40px; cursor: pointer; user-select: none;
        }
        
        .table-custom td {
            vertical-align: middle; padding: 16px 40px;
            white-space: nowrap; border-bottom: var(--glass-border); font-size: 1rem;
        }
        
        /* Row Hover Effect */
        .table-custom tbody tr { transition: background-color 0.2s, transform 0.1s; }
        .table-custom tbody tr:hover { 
            background-color: var(--row-hover); 
            /* Subtle lift for desktop feel */
            box-shadow: inset 2px 0 0 var(--bs-primary);
        }

        /* Name Column */
        .file-icon { font-size: 1.5rem; width: 45px; text-align: center; display: inline-block; vertical-align: middle; }
        .file-name { font-size: 1.1rem; font-weight: 600; color: inherit; text-decoration: none; vertical-align: middle; }
        .file-name:hover { color: var(--bs-primary); text-decoration: underline; }
        .text-purple { color: #8b5cf6 !important; }

        /* Buttons with Animation */
        .btn-action { 
            width: 36px; height: 36px; border-radius: 10px; 
            display: inline-flex; align-items: center; justify-content: center; 
            border: none; transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275); text-decoration: none; flex-shrink: 0;
        }
        .btn-action:hover { transform: scale(1.15); box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        .btn-stream { background: rgba(16, 185, 129, 0.1); color: #10b981; } .btn-stream:hover { background: #10b981; color: white; }
        .btn-download { background: rgba(59, 130, 246, 0.1); color: #3b82f6; } .btn-download:hover { background: #3b82f6; color: white; }
        .btn-copy { background: rgba(100, 116, 139, 0.1); color: #64748b; } .btn-copy:hover { background: #64748b; color: white; }
        .dropdown-toggle::after { display: none !important; }

        .search-box { position: relative; width: 300px; }
        .search-box input { padding-left: 45px; border-radius: 10px; background: var(--bs-body-bg); border: var(--glass-border); transition: 0.2s; }
        .search-box input:focus { box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.15); border-color: #3b82f6; }
        .search-box i { position: absolute; left: 15px; top: 50%; transform: translateY(-50%); opacity: 0.5; }
        .breadcrumb-item a { text-decoration: none; font-weight: 500; transition: 0.2s; }
        .breadcrumb-item a:hover { text-decoration: underline; }

        /* Glass Modals */
        .modal-content { 
            background: rgba(var(--bs-body-bg-rgb), 0.8); 
            backdrop-filter: blur(15px); -webkit-backdrop-filter: blur(15px);
            border: 1px solid rgba(255,255,255,0.2); 
        }

        #toast { position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%) translateY(100px); background: #1e293b; color: #fff; padding: 12px 24px; border-radius: 50px; box-shadow: 0 10px 25px rgba(0,0,0,0.2); z-index: 2000; opacity: 0; transition: all 0.4s; display: flex; align-items: center; gap: 10px; }
        #toast.show { transform: translateX(-50%) translateY(0); opacity: 1; }
        .theme-toggle { cursor: pointer; padding: 8px 12px; border-radius: 10px; border: var(--glass-border); background: transparent; transition: 0.2s; }
        .theme-toggle:hover { background: rgba(var(--bs-primary-rgb), 0.1); border-color: var(--bs-primary); }

        @media (max-width: 768px) {
            .mobile-hide { display: none; }
            .table-custom td { white-space: normal; word-break: break-word; padding-left: 15px; padding-right: 15px; }
            .table-custom thead th { padding-left: 15px; padding-right: 15px; }
            .table-custom td.text-end { white-space: nowrap; width: 1%; }
            .file-name { font-size: 1rem; max-width: none; white-space: normal; display: inline; }
            .search-box { width: 100%; margin-top: 10px; }
            .btn-action { width: 32px; height: 32px; border-radius: 8px; }
            .app-header, .app-toolbar, .table-custom th, .table-custom td { padding-left: 15px; padding-right: 15px; }
        }
    </style>
</head>
<body>

    <div class="news-ticker">
        <div class="ticker-content">
            <span class="mx-4"><i class="fa-solid fa-bolt text-warning"></i> Welcome to Sarker Net Premium File Server</span>
            <span class="mx-4"><i class="fa-solid fa-server text-info"></i> High Speed FTP & Media Streaming</span>
            <span class="mx-4"><i class="fa-solid fa-phone text-success"></i> Support: 01329609346</span>
        </div>
    </div>

    <div class="app-header d-flex flex-wrap justify-content-between align-items-center gap-3">
        <div>
            <h4 class="fw-bold mb-0 text-primary d-flex align-items-center">
                <i class="fa-solid fa-network-wired me-2"></i> Sarker Net <span class="text-body-emphasis ms-2 fw-normal">Files</span>
            </h4>
            <div class="text-muted small mt-1 d-flex align-items-center">
                <span id="clock" class="fw-medium me-3"></span>
                <span class="badge bg-secondary-subtle text-secondary-emphasis border"><i class="fa-solid fa-eye me-1"></i> <%= visitorCount %></span>
            </div>
        </div>
        <div class="d-flex gap-2">
            <button class="theme-toggle" onclick="toggleTheme()" data-bs-toggle="tooltip" title="Toggle Theme"><i id="themeIcon" class="fa-solid fa-moon"></i></button>
            <button class="btn btn-outline-primary btn-sm fw-medium rounded-3" data-bs-toggle="modal" data-bs-target="#nodesModal"><i class="fa-solid fa-database me-2"></i>Nodes</button>
            <button class="btn btn-primary btn-sm fw-medium rounded-3" data-bs-toggle="modal" data-bs-target="#servicesModal"><i class="fa-solid fa-layer-group me-2"></i>Services</button>
            <a href="https://t.me/+59KXZDQ-K_s2YzRl" target="_blank" class="btn btn-success btn-sm fw-medium rounded-3"><i class="fa-brands fa-telegram me-2"></i>Request</a>
        </div>
    </div>

    <div class="app-toolbar">
        <div class="row align-items-center">
            <div class="col-md-7">
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="Default.aspx"><i class="fa-solid fa-house"></i> Home</a></li>
                        <% if (!string.IsNullOrEmpty(currentRelativePath)) { 
                               string[] parts = currentRelativePath.Split('/');
                               string buildPath = "";
                               for(int i=0; i < parts.Length; i++) {
                                   buildPath += (i > 0 ? "/" : "") + parts[i];
                                   if (i == parts.Length - 1) { %>
                                       <li class="breadcrumb-item active" aria-current="page"><%= parts[i] %></li>
                                   <% } else { %>
                                       <li class="breadcrumb-item"><a href="?path=<%= buildPath %>"><%= parts[i] %></a></li>
                                   <% } 
                               }
                           } %>
                    </ol>
                </nav>
            </div>
            <div class="col-md-5 d-flex justify-content-md-end">
                <div class="search-box">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <input type="text" id="tableSearch" class="form-control form-control-sm" placeholder="Filter files..." onkeyup="searchTable()">
                </div>
            </div>
        </div>
    </div>

    <div class="table-container">
        <table class="table table-custom" id="fileTable">
            <thead>
                <tr>
                    <th style="width: 60px;">Type</th>
                    <th onclick="sortTable(1)">Name <i class="fa-solid fa-sort ms-1 opacity-50"></i></th>
                    <th class="mobile-hide" onclick="sortTable(2)" style="width: 15%">Size <i class="fa-solid fa-sort ms-1 opacity-50"></i></th>
                    <th class="mobile-hide" onclick="sortTable(3)" style="width: 18%">Date <i class="fa-solid fa-sort ms-1 opacity-50"></i></th>
                    <th class="text-end" style="width: 150px;">Actions</th>
                </tr>
            </thead>
            <tbody>
                <% 
                try {
                    string fullPath = Path.Combine(rootPath, currentRelativePath);
                    DirectoryInfo di = new DirectoryInfo(fullPath);

                    if (!string.IsNullOrEmpty(currentRelativePath)) { %>
                        <tr class="bg-warning-subtle">
                            <td><span class="file-icon"><i class="fa-solid fa-level-up-alt text-warning"></i></span></td>
                            <td colspan="4"><a href="?path=<%= parentDirectory %>" class="text-decoration-none fw-bold text-dark"><i class="fa-solid fa-arrow-left me-2"></i>Go Back</a></td>
                        </tr>
                    <% }

                    foreach (DirectoryInfo d in di.GetDirectories().OrderBy(x => x.Name)) {
                        if (d.Name.StartsWith(".") || (d.Attributes & FileAttributes.Hidden) != 0) continue;
                        string link = string.IsNullOrEmpty(currentRelativePath) ? d.Name : currentRelativePath + "/" + d.Name;
                %>
                    <tr data-type="folder">
                        <td><span class="file-icon"><i class="fa-solid fa-folder text-warning"></i></span></td>
                        <td><a href="?path=<%= link %>" class="file-name"><%= d.Name %></a></td>
                        <td class="text-muted mobile-hide">-</td>
                        <td class="text-muted mobile-hide small"><%= d.LastWriteTime.ToString("yyyy-MM-dd HH:mm") %></td>
                        <td class="text-end"><a href="?path=<%= link %>" class="btn btn-sm btn-light border" data-bs-toggle="tooltip" title="Open Folder"><i class="fa-solid fa-arrow-right text-secondary"></i></a></td>
                    </tr>
                <% } 

                    foreach (FileInfo f in di.GetFiles().OrderBy(x => x.Name)) {
                        if (f.Name.Equals("Default.aspx", StringComparison.OrdinalIgnoreCase) || f.Name.Equals("web.config", StringComparison.OrdinalIgnoreCase) || f.Name.Equals("counter.txt", StringComparison.OrdinalIgnoreCase)) continue;

                        string link = string.IsNullOrEmpty(currentRelativePath) ? f.Name : currentRelativePath + "/" + f.Name;
                        string fullUrl = serverBaseUrl + Request.ApplicationPath.TrimEnd('/') + "/" + link;
                        bool isVid = IsPreviewableVideo(f.Extension);
                        bool isImg = IsPreviewableImage(f.Extension);
                %>
                    <tr data-type="file">
                        <td><span class="file-icon"><i class="<%= GetIconClass(f.Extension) %>"></i></span></td>
                        <td>
                            <a href="<%= link %>" class="file-name"><%= f.Name %></a>
                            <% if(isVid) { %> <span class="badge bg-success-subtle text-success border border-success-subtle ms-2 align-middle" style="font-size: 0.7rem;">HD</span> <% } %>
                        </td>
                        <td class="text-muted mobile-hide small font-monospace" style="font-size: 0.95rem;"><%= FormatSize(f.Length) %></td>
                        <td class="text-muted mobile-hide small"><%= f.LastWriteTime.ToString("yyyy-MM-dd HH:mm") %></td>
                        <td class="text-end">
                            <div class="d-flex justify-content-end gap-1">
                                <% if(isVid) { %>
                                    <div class="dropdown d-inline-block">
                                        <button class="btn-action btn-stream dropdown-toggle" type="button" data-bs-toggle="dropdown" title="Stream Options"><i class="fa-solid fa-play"></i></button>
                                        <ul class="dropdown-menu dropdown-menu-end shadow border-0 rounded-4 p-2">
                                            <li><h6 class="dropdown-header text-uppercase small fw-bold">Select Player</h6></li>
                                            <li><a class="dropdown-item rounded" href="#" onclick="previewMedia('<%= f.Name %>', '<%= link %>', 'video'); return false;"><i class="fa-solid fa-globe me-2 text-primary"></i>Browser</a></li>
                                            <li><hr class="dropdown-divider"></li>
                                            <li><a class="dropdown-item rounded d-none d-md-block" href="vlc://<%= fullUrl %>"><i class="fa-solid fa-traffic-cone me-2 text-warning"></i>VLC (PC)</a></li>
                                            <li><a class="dropdown-item rounded d-none d-md-block" href="potplayer://<%= fullUrl %>"><i class="fa-solid fa-tv me-2 text-info"></i>PotPlayer (PC)</a></li>
                                            <li><a class="dropdown-item rounded" href="intent:<%= fullUrl %>#Intent;package=com.mxtech.videoplayer.ad;type=video/*;end"><i class="fa-solid fa-play me-2 text-primary"></i>MX Mobile</a></li>
                                            <li><a class="dropdown-item rounded" href="intent:<%= fullUrl %>#Intent;package=com.mxtech.videoplayer.pro;type=video/*;end"><i class="fa-solid fa-star me-2 text-warning"></i>MX Player Pro</a></li>
                                        </ul>
                                    </div>
                                <% } else if(isImg) { %>
                                    <button onclick="previewMedia('<%= f.Name %>', '<%= link %>', 'image')" class="btn-action btn-stream" data-bs-toggle="tooltip" title="View Image"><i class="fa-solid fa-eye"></i></button>
                                <% } %>
                                <a href="<%= link %>" download class="btn-action btn-download" data-bs-toggle="tooltip" title="Download"><i class="fa-solid fa-download"></i></a>
                                <button onclick="copyToClipboard('<%= fullUrl %>')" class="btn-action btn-copy" data-bs-toggle="tooltip" title="Copy Link"><i class="fa-solid fa-link"></i></button>
                            </div>
                        </td>
                    </tr>
                <% } 
                } catch { %>
                    <tr><td colspan="5" class="text-center text-danger p-4">Directory Access Error or Invalid Path</td></tr>
                <% } %>
            </tbody>
        </table>
        <div id="emptyState" class="d-none text-center py-5">
            <i class="fa-solid fa-magnifying-glass fa-3x text-secondary opacity-25 mb-3"></i>
            <h5 class="text-muted">No files found</h5>
        </div>
    </div>

    <div class="modal fade" id="previewModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg">
                <div class="modal-header border-bottom-0"><h5 class="modal-title fs-6 fw-bold text-truncate" id="previewTitle">File Preview</h5><button type="button" class="btn-close" data-bs-dismiss="modal" onclick="stopMedia()"></button></div>
                <div class="modal-body p-0 text-center bg-black position-relative" style="min-height: 300px; display: flex; align-items: center; justify-content: center;">
                    <video id="videoPlayer" controls class="w-100 d-none" style="max-height: 80vh;" autoplay><source id="videoSource" src="" type="video/mp4"></video>
                    <img id="imageViewer" src="" class="img-fluid d-none" style="max-height: 80vh;" alt="Preview">
                </div>
                <div class="modal-footer border-top-0 justify-content-between"><a id="modalDownload" href="#" download class="btn btn-primary btn-sm rounded-3"><i class="fa-solid fa-download me-2"></i>Download</a><button class="btn btn-secondary btn-sm rounded-3" data-bs-dismiss="modal" onclick="stopMedia()">Close</button></div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="nodesModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered"><div class="modal-content border-0 shadow-lg"><div class="modal-header"><h5 class="modal-title fw-bold">Storage Nodes</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body"><div class="row g-2"><% for(int i=8080; i<=8095; i++) { %><div class="col-6"><a href="http://100.100.100.6:<%= i %>" target="_blank" class="d-flex justify-content-between align-items-center p-3 rounded-3 bg-light border text-decoration-none text-dark hover-shadow transition-all"><span>Port <%= i %></span></a></div><% } %></div></div></div></div>
    </div>

    <div class="modal fade" id="servicesModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered"><div class="modal-content border-0 shadow-lg"><div class="modal-header"><h5 class="modal-title fw-bold">Services</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body p-2"><div class="list-group list-group-flush"><a href="http://100.100.100.2/" class="list-group-item list-group-item-action p-3">Live TV</a><a href="http://100.100.100.6:8096" class="list-group-item list-group-item-action p-3">Emby</a><a href="http://100.100.100.6" class="list-group-item list-group-item-action p-3">FTP</a></div></div></div></div>
    </div>
    
    <div id="toast"><i class="fa-solid fa-circle-check text-success"></i><span id="toastMsg">Action Successful</span></div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function toggleTheme() { const h = document.documentElement; const c = h.getAttribute('data-bs-theme'); const i = document.getElementById('themeIcon'); if (c === 'light') { h.setAttribute('data-bs-theme', 'dark'); i.className = 'fa-solid fa-sun'; localStorage.setItem('theme', 'dark'); } else { h.setAttribute('data-bs-theme', 'light'); i.className = 'fa-solid fa-moon'; localStorage.setItem('theme', 'light'); } }
        (function() { const s = localStorage.getItem('theme') || 'light'; document.documentElement.setAttribute('data-bs-theme', s); document.getElementById('themeIcon').className = s === 'dark' ? 'fa-solid fa-sun' : 'fa-solid fa-moon'; })();
        setInterval(() => { document.getElementById('clock').innerText = new Date().toLocaleString('en-US', { weekday: 'short', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }); }, 1000);
        
        // Tooltips Init
        const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
        const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));

        const pm = new bootstrap.Modal(document.getElementById('previewModal'));
        function previewMedia(n, l, t) { document.getElementById('previewTitle').innerText = n; document.getElementById('modalDownload').href = l; const v = document.getElementById('videoPlayer'); const i = document.getElementById('imageViewer'); v.classList.add('d-none'); i.classList.add('d-none'); if (t === 'video') { v.src = l; v.classList.remove('d-none'); v.play(); } else { i.src = l; i.classList.remove('d-none'); } pm.show(); }
        function stopMedia() { const v = document.getElementById('videoPlayer'); v.pause(); vid.src = ""; }
        document.getElementById('previewModal').addEventListener('hidden.bs.modal', stopMedia);
        function searchTable() { const f = document.getElementById("tableSearch").value.toUpperCase(); const tr = document.getElementById("fileTable").getElementsByTagName("tr"); let v = 0; for (let i = 1; i < tr.length; i++) { if(tr[i].querySelector('.fa-level-up-alt')) continue; const td = tr[i].getElementsByTagName("td")[1]; if (td) { if ((td.textContent || td.innerText).toUpperCase().indexOf(f) > -1) { tr[i].style.display = ""; v++; } else { tr[i].style.display = "none"; } } } document.getElementById('emptyState').classList.toggle('d-none', v > 0); }
        function sortTable(n) { var t = document.getElementById("fileTable"), r, s = true, i, x, y, ss, d = "asc", c = 0; while (s) { s = false; r = t.rows; let sr = 1; if(r[1] && r[1].innerHTML.includes('Go Back')) sr = 2; for (i = sr; i < (r.length - 1); i++) { ss = false; x = r[i].getElementsByTagName("TD")[n]; y = r[i + 1].getElementsByTagName("TD")[n]; if (d == "asc") { if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) { ss = true; break; } } else if (d == "desc") { if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) { ss = true; break; } } } if (ss) { r[i].parentNode.insertBefore(r[i + 1], r[i]); s = true; c++; } else { if (c == 0 && d == "asc") { d = "desc"; s = true; } } } }
        function copyToClipboard(t) { navigator.clipboard.writeText(t).then(() => { const o = document.getElementById("toast"); o.classList.add("show"); setTimeout(() => o.classList.remove("show"), 2500); }); }
    </script>
</body>
</html>