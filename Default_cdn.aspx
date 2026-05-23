<%@ Page Language="C#" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>

<script runat="server">
    // ==========================================================
    // BACKEND LOGIC
    // ==========================================================
    private static readonly object _counterLock = new object();
    string rootPath = "";
    string currentRelativePath = "";
    string parentDirectory = "";
    int visitorCount = 1000; // Default start value
    string serverBaseUrl = "";
    string currentPlaylistUrl = ""; 

    protected void Page_Load(object sender, EventArgs e)
    {
        serverBaseUrl = Request.Url.Scheme + "://" + Request.Url.Authority;
        rootPath = Server.MapPath("~/");
        string reqPath = Request.QueryString["path"];

        // 1. Path Calculation
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
            
            // FIX: Replaced spaces with %20 so the copied Playlist URL works correctly
            currentPlaylistUrl = serverBaseUrl + Request.Url.AbsolutePath + "?path=" + currentRelativePath.Replace(" ", "%20") + "&action=playlist";
        }

        // 2. PLAYLIST GENERATION LOGIC
        if (Request.QueryString["action"] == "playlist" && !string.IsNullOrEmpty(currentRelativePath))
        {
            try 
            {
                string fullFolderPath = Path.Combine(rootPath, currentRelativePath);
                DirectoryInfo playlistDi = new DirectoryInfo(fullFolderPath);
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("#EXTM3U");

                foreach (FileInfo f in playlistDi.GetFiles())
                {
                    if (IsVideoFile(f.Extension))
                    {
                        string fileUrl = serverBaseUrl + Request.ApplicationPath.TrimEnd('/') + "/" + currentRelativePath + "/" + f.Name;
                        fileUrl = fileUrl.Replace(" ", "%20"); 
                        sb.AppendLine("#EXTINF:-1," + f.Name.Replace(f.Extension, ""));
                        sb.AppendLine(fileUrl);
                    }
                }

                Response.Clear();
                Response.ContentType = "audio/x-mpegurl";
                Response.AddHeader("Content-Disposition", "attachment; filename=\"" + playlistDi.Name + ".m3u\"");
                Response.Write(sb.ToString());
                Response.End();
            }
            catch { /* Ignore errors during generation */ }
        }

        // 3. VISITOR COUNTER LOGIC
        string counterFile = Server.MapPath("~/counter.txt");
        
        // Read existing
        try 
        {
            if (File.Exists(counterFile)) 
            {
                string fileContent = File.ReadAllText(counterFile);
                if(!string.IsNullOrEmpty(fileContent)) int.TryParse(fileContent, out visitorCount);
            }
        } 
        catch { }

        // Increment (Session based)
        if (Session["HasVisited"] == null)
        {
            visitorCount++;
            Session["HasVisited"] = "true";
            lock (_counterLock)
            {
                try { File.WriteAllText(counterFile, visitorCount.ToString()); } catch { }
            }
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

    bool IsVideoFile(string ext) { ext = ext.ToLower(); return (ext == ".mp4" || ext == ".mkv" || ext == ".avi" || ext == ".mov" || ext == ".webm" || ext == ".ts" || ext == ".m4v" || ext == ".flv"); }
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
    
    <title>SN FTP | Premium File Server</title>
    <meta name="description" content="SN FTP File Server - High speed FTP and media streaming service in Sirajganj.">
    <meta name="keywords" content="SN FTP, FTP, File Server, Sirajganj ISP, Movies, Software, Games">
    <meta name="author" content="Md Sohag Rana">
    <link rel="icon" type="image/png" href="/images/logo.png">

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <style>
        :root {
            --font-main: 'Inter', sans-serif;
            --glass-bg: rgba(255, 255, 255, 0.7);
            --glass-border: 1px solid rgba(255, 255, 255, 0.4);
            --row-hover: rgba(248, 250, 252, 0.8);
            --header-bg: rgba(255, 255, 255, 0.85);
            --text-main: #0f172a;
            --icon-bg: #f1f5f9;
            --scrollbar-thumb: #cbd5e1;
            --scrollbar-track: #f1f5f9;
            --shadow-soft: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.01);
        }

        [data-bs-theme="dark"] {
            --glass-bg: rgba(15, 23, 42, 0.7);
            --glass-border: 1px solid rgba(255, 255, 255, 0.05);
            --row-hover: rgba(30, 41, 59, 0.6);
            --header-bg: rgba(15, 23, 42, 0.85);
            --text-main: #f8fafc;
            --icon-bg: #1e293b;
            --scrollbar-thumb: #475569;
            --scrollbar-track: #1e293b;
        }

        html, body { height: 100%; margin: 0; padding: 0; }
        
        /* Premium Gradient Backgrounds */
        body { 
            font-family: var(--font-main); 
            background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%); 
            display: flex; flex-direction: column; color: var(--text-main); 
        }
        [data-bs-theme="dark"] body { 
            background: linear-gradient(135deg, #020617 0%, #0f172a 100%); 
        }

        /* Custom Scrollbar */
        ::-webkit-scrollbar { width: 10px; height: 10px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: var(--scrollbar-thumb); border-radius: 5px; border: 2px solid transparent; background-clip: padding-box; }
        ::-webkit-scrollbar-thumb:hover { background-color: #94a3b8; }

        /* Ticker */
        .news-ticker { flex: 0 0 40px; background: #1e293b; color: #fff; display: flex; align-items: center; overflow: hidden; border-bottom: 2px solid #3b82f6; z-index: 1060; }
        .ticker-content { display: inline-block; white-space: nowrap; animation: ticker 90s linear infinite; } 
        @keyframes ticker { 0% { transform: translateX(100vw); } 100% { transform: translateX(-100%); } }

        /* UPGRADED MAIN CARD (Glassmorphism) - Taller for a bigger table view */
        .main-card {
            border-radius: 24px;
            box-shadow: var(--shadow-soft);
            background: var(--glass-bg); 
            backdrop-filter: blur(16px); 
            -webkit-backdrop-filter: blur(16px);
            border: var(--glass-border);
            overflow: hidden; 
            display: flex;
            flex-direction: column;
            height: calc(100vh - 110px); 
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        /* App Toolbar */
        .app-toolbar { 
            flex: 0 0 auto; padding: 1.25rem 25px; 
            border-bottom: 1px solid rgba(0,0,0,0.05); 
            background: transparent; 
        }
        [data-bs-theme="dark"] .app-toolbar { border-bottom: 1px solid rgba(255,255,255,0.05); }

        /* DYNAMIC TABLE CONTAINER (Scroll Shadows) */
        .table-container { 
            flex: 1 1 auto; 
            overflow-y: auto; 
            overflow-x: auto; 
            position: relative; 
            scroll-behavior: smooth;
            background:
                linear-gradient(var(--glass-bg) 30%, rgba(255,255,255,0)),
                linear-gradient(rgba(255,255,255,0), var(--glass-bg) 70%) 0 100%,
                radial-gradient(farthest-side at 50% 0, rgba(0,0,0,0.08), rgba(0,0,0,0)),
                radial-gradient(farthest-side at 50% 100%, rgba(0,0,0,0.08), rgba(0,0,0,0)) 0 100%;
            background-repeat: no-repeat;
            background-color: transparent;
            background-size: 100% 40px, 100% 40px, 100% 14px, 100% 14px;
            background-attachment: local, local, scroll, scroll;
        }

        [data-bs-theme="dark"] .table-container {
            background:
                linear-gradient(var(--glass-bg) 30%, rgba(15,23,42,0)),
                linear-gradient(rgba(15,23,42,0), var(--glass-bg) 70%) 0 100%,
                radial-gradient(farthest-side at 50% 0, rgba(0,0,0,0.3), rgba(0,0,0,0)),
                radial-gradient(farthest-side at 50% 100%, rgba(0,0,0,0.3), rgba(0,0,0,0)) 0 100%;
            background-repeat: no-repeat;
            background-attachment: local, local, scroll, scroll;
        }

        /* TABLE STYLING & BLURRED STICKY HEADER - Bigger padding for larger rows */
        .table-custom { margin-bottom: 0; width: 100%; border-collapse: separate; border-spacing: 0; }
        .table-custom thead th {
            position: sticky; top: 0; z-index: 100; 
            background: var(--header-bg);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            box-shadow: 0 1px 0 rgba(0,0,0,0.05); 
            font-weight: 600; text-transform: uppercase;
            font-size: 0.85rem; 
            letter-spacing: 0.5px; 
            padding: 22px 25px; 
            cursor: pointer; user-select: none;
            color: var(--bs-secondary-color); border-bottom: none;
        }
        [data-bs-theme="dark"] .table-custom thead th { box-shadow: 0 1px 0 rgba(255,255,255,0.05); }
        
        .table-custom td {
            vertical-align: middle; 
            padding: 18px 25px; 
            white-space: nowrap; border-bottom: 1px solid rgba(0,0,0,0.05); font-size: 1rem;
            transition: background-color 0.2s ease;
        }
        [data-bs-theme="dark"] .table-custom td { border-bottom: 1px solid rgba(255,255,255,0.05); }
        
        .table-custom tbody tr:hover td { background-color: var(--row-hover); }
        .table-custom tbody tr:last-child td { border-bottom: none; }

        /* Modern Icon Box */
        .icon-box {
            width: 42px; height: 42px;
            border-radius: 12px;
            display: inline-flex; align-items: center; justify-content: center;
            background: var(--icon-bg);
            font-size: 1.25rem;
            transition: transform 0.2s;
        }
        .table-custom tbody tr:hover .icon-box { transform: scale(1.05); }
        
        /* Clean Text Truncation */
        .file-name-container { max-width: 450px; display: inline-block; vertical-align: middle; }
        
        /* Fixed text color for dark mode (removed text-dark) */
        .file-name { font-size: 1rem; font-weight: 500; color: inherit; text-decoration: none; }
        .file-name:hover { color: var(--bs-primary); text-decoration: none; }
        .text-purple { color: #8b5cf6 !important; }

        /* Buttons */
        .btn-action { 
            width: 36px; height: 36px; border-radius: 10px; 
            display: inline-flex; align-items: center; justify-content: center; 
            border: none; transition: all 0.2s; text-decoration: none; flex-shrink: 0;
            font-size: 0.9rem;
        }
        .btn-action:hover { transform: translateY(-2px); box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); }
        .btn-stream { background: rgba(16, 185, 129, 0.1); color: #10b981; } .btn-stream:hover { background: #10b981; color: white; }
        .btn-download { background: rgba(59, 130, 246, 0.1); color: #3b82f6; } .btn-download:hover { background: #3b82f6; color: white; }
        .btn-copy { background: rgba(100, 116, 139, 0.1); color: #64748b; } .btn-copy:hover { background: #64748b; color: white; }
        .dropdown-toggle::after { display: none !important; }

        .search-box { position: relative; width: 280px; }
        .search-box input { padding-left: 42px; padding-right: 15px; height: 38px; border-radius: 20px; background: var(--bs-body-bg); border: 1px solid rgba(0,0,0,0.1); font-size: 0.9rem;}
        [data-bs-theme="dark"] .search-box input { border: 1px solid rgba(255,255,255,0.1); }
        .search-box input:focus { box-shadow: none; border-color: #3b82f6; }
        .search-box i { position: absolute; left: 16px; top: 50%; transform: translateY(-50%); opacity: 0.4; font-size: 0.9rem;}
        
        .breadcrumb-item a { text-decoration: none; font-weight: 500; }
        .breadcrumb { font-size: 0.95rem; }

        #toast { position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%) translateY(100px); background: #1e293b; color: #fff; padding: 12px 24px; border-radius: 50px; box-shadow: 0 10px 25px rgba(0,0,0,0.2); z-index: 2000; opacity: 0; transition: all 0.4s; }
        #toast.show { transform: translateX(-50%) translateY(0); opacity: 1; }
        .theme-toggle { cursor: pointer; padding: 8px; border: none; background: transparent; color: var(--text-main); font-size: 1.2rem; transition: transform 0.2s; }
        .theme-toggle:hover { transform: scale(1.1); }

        /* MOBILE RESPONSIVE OVERHAUL */
        @media (max-width: 768px) {
            /* Hide non-essential elements on mobile completely */
            .mobile-hide { display: none !important; }
            td .badge { display: none !important; } /* Hide HD tags to save space */

            /* Force file name to truncate to prevent breaking the layout */
            .file-name-container { 
                max-width: 45vw; /* Perfectly scales with screen width */
            }

            /* Edge-to-edge layout on mobile */
            .main-card { 
                height: calc(100vh - 125px); 
                border-radius: 16px; 
                margin-left: -12px; 
                margin-right: -12px;
                border-left: none;
                border-right: none;
            }
            
            .app-toolbar { 
                flex-direction: column; 
                gap: 15px; 
                align-items: flex-start; 
                padding: 1rem 15px; 
            }
            
            .search-box { width: 100%; }
            
            /* Compress table padding */
            .table-custom td { padding: 12px 8px !important; }
            .table-custom thead th { padding: 12px 8px !important; }

            /* Shrink file icons */
            .icon-box {
                width: 32px; height: 32px; font-size: 1rem;
            }

            /* Shrink action buttons slightly */
            .btn-action {
                width: 32px; height: 32px; font-size: 0.85rem;
            }
            
            /* Tighten action buttons gap */
            .table-custom td .d-flex.gap-2 {
                gap: 0.35rem !important;
            }
        }
    </style>
</head>
<body>

    <div class="news-ticker mobile-hide">
        <div class="ticker-content">
            <span class="mx-4"><i class="fa-solid fa-bolt text-warning"></i> Welcome to SN FTP Premium File Server</span>
            <span class="mx-4"><i class="fa-solid fa-server text-info"></i> High Speed FTP & Media Streaming</span>
            <span class="mx-4"><i class="fa-solid fa-film text-danger"></i> Latest Movies & TV Shows Available</span>
            <span class="mx-4"><i class="fa-solid fa-laptop-code text-primary"></i> Download Premium Software Securely</span>
            <span class="mx-4"><i class="fa-solid fa-tv text-success"></i> Live TV App for Mobile & Smart TV</span>
        </div>
    </div>

    <div class="container py-4">
        <div class="row align-items-center mb-4 g-3">
            <div class="col-md-6">
                <div class="d-flex align-items-center gap-3">
                    <img src="/images/logo.png" style="height: 55px; width: auto;" alt="Logo" onerror="this.style.display='none'">
                    <div>
                        <h1 class="fw-bold mb-0 h3">SN FTP <span class="text-secondary fw-normal">Files</span></h1>
                        <div class="text-muted small mt-1 d-flex align-items-center">
                            <span id="clock" class="fw-medium me-3">Loading...</span>
                            <span class="badge bg-secondary-subtle text-secondary-emphasis border"><i class="fa-solid fa-eye me-1"></i> <%= visitorCount %></span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-6 text-md-end">
                <div class="d-flex gap-2 justify-content-md-end flex-wrap align-items-center">
                     <button class="theme-toggle me-2" onclick="toggleTheme()" data-bs-toggle="tooltip" title="Toggle Theme"><i id="themeIcon" class="fa-solid fa-moon"></i></button>
                    <a href="https://t.me/+3EcHBXjkDZQyZWQ1" target="_blank" class="btn btn-success btn-sm rounded-pill px-3 shadow-sm mobile-hide">
                        <i class="fa-brands fa-telegram me-2"></i>Request
                    </a>
                    <a href="http://100.100.100.2/" target="_blank" class="btn btn-outline-primary btn-sm rounded-pill px-3 shadow-sm mobile-hide">
                        <i class="fa-solid fa-tv me-2"></i>SN TV
                    </a>
                    <a href="http://100.100.100.6:8096" target="_blank" class="btn btn-outline-danger btn-sm rounded-pill px-3 shadow-sm mobile-hide">
                        <i class="fa-solid fa-play me-2"></i>SN Emby
                    </a>
                </div>
            </div>
        </div>

        <div class="card main-card">
            <div class="app-toolbar">
                <div class="row align-items-center gy-3">
                    <div class="col-md-7">
                        <nav aria-label="breadcrumb">
                            <ol class="breadcrumb mb-0">
                                <li class="breadcrumb-item"><a href="Default.aspx" class="text-primary"><i class="fa-solid fa-house"></i> Home</a></li>
                                <% if (!string.IsNullOrEmpty(currentRelativePath)) { 
                                       string[] parts = currentRelativePath.Split('/');
                                       string buildPath = "";
                                       for(int i=0; i < parts.Length; i++) {
                                           buildPath += (i > 0 ? "/" : "") + parts[i];
                                           if (i == parts.Length - 1) { %>
                                               <li class="breadcrumb-item active fw-bold" aria-current="page"><%= parts[i] %></li>
                                           <% } else { %>
                                               <li class="breadcrumb-item"><a href="?path=<%= buildPath %>"><%= parts[i] %></a></li>
                                           <% } 
                                       }
                                   } %>
                            </ol>
                        </nav>
                    </div>
                    <div class="col-md-5 d-flex flex-wrap justify-content-md-end align-items-center gap-2">
                        <% if (!string.IsNullOrEmpty(currentRelativePath)) { %>
                        <div class="d-flex gap-2">
                            <a href="?path=<%= currentRelativePath %>&action=playlist" class="btn btn-danger btn-sm rounded-pill px-3 shadow-sm text-decoration-none d-flex align-items-center">
                                <i class="fa-solid fa-file-audio me-2"></i>M3U Playlist
                            </a>
                            <button onclick="copyLink('<%= currentPlaylistUrl %>', 'Playlist URL Copied!')" class="btn btn-outline-secondary btn-sm rounded-pill px-3 shadow-sm d-flex align-items-center" title="Copy Playlist URL">
                                <i class="fa-solid fa-link"></i>
                            </button>
                        </div>
                        <% } %>
                        <div class="search-box ms-md-2">
                            <i class="fa-solid fa-magnifying-glass"></i>
                            <input type="text" id="tableSearch" class="form-control" placeholder="Search files..." onkeyup="searchTable()">
                        </div>
                    </div>
                </div>
            </div>

            <div class="table-container">
                <table class="table table-custom table-hover align-middle" id="fileTable">
                    <thead>
                        <tr>
                            <th style="width: 50px;" class="text-center">Type</th>
                            <th onclick="sortTable(1)">File Name <i class="fa-solid fa-sort ms-1 opacity-50"></i></th>
                            <th class="mobile-hide" onclick="sortTable(2)" style="width: 15%">Size <i class="fa-solid fa-sort ms-1 opacity-50"></i></th>
                            <th class="mobile-hide" onclick="sortTable(3)" style="width: 18%">Modified <i class="fa-solid fa-sort ms-1 opacity-50"></i></th>
                            <th class="text-end" style="width: 120px; padding-right: 25px;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% 
                        try {
                            string fullPath = Path.Combine(rootPath, currentRelativePath);
                            DirectoryInfo di = new DirectoryInfo(fullPath);

                            // Go Back Row
                            if (!string.IsNullOrEmpty(currentRelativePath)) { %>
                                <tr class="bg-primary bg-opacity-10" style="cursor: pointer;" onclick="window.location.href='?path=<%= parentDirectory %>'">
                                    <td class="text-center">
                                        <div class="icon-box bg-primary text-white bg-opacity-75" style="width: 36px; height: 36px; font-size: 1rem;">
                                            <i class="fa-solid fa-arrow-turn-up"></i>
                                        </div>
                                    </td>
                                    <td colspan="4" class="fw-semibold text-primary">
                                        Go Back
                                    </td>
                                </tr>
                            <% }

                            // Folders Loop
                            foreach (DirectoryInfo d in di.GetDirectories().OrderBy(x => x.Name)) {
                                if (d.Name.StartsWith(".") || (d.Attributes & FileAttributes.Hidden) != 0) continue;
                                string link = string.IsNullOrEmpty(currentRelativePath) ? d.Name : currentRelativePath + "/" + d.Name;
                        %>
                            <tr data-type="folder">
                                <td class="text-center">
                                    <div class="icon-box"><i class="fa-solid fa-folder text-warning"></i></div>
                                </td>
                                <td>
                                    <div class="file-name-container text-truncate">
                                        <a href="?path=<%= link %>" class="file-name" title="<%= d.Name %>"><%= d.Name %></a>
                                    </div>
                                </td>
                                <td class="text-muted mobile-hide">-</td>
                                <td class="text-muted mobile-hide small"><%= d.LastWriteTime.ToString("MMM dd, yyyy HH:mm") %></td>
                                <td class="text-end pe-3 pe-md-4">
                                    <a href="?path=<%= link %>" class="btn btn-sm btn-light border rounded-pill px-3 text-secondary shadow-sm" data-bs-toggle="tooltip" title="Open Folder">Open</a>
                                </td>
                            </tr>
                        <% } 

                            // Files Loop
                            foreach (FileInfo f in di.GetFiles().OrderBy(x => x.Name)) {
                                if (f.Name.Equals("Default.aspx", StringComparison.OrdinalIgnoreCase) || f.Name.Equals("web.config", StringComparison.OrdinalIgnoreCase) || f.Name.Equals("counter.txt", StringComparison.OrdinalIgnoreCase)) continue;

                                string link = string.IsNullOrEmpty(currentRelativePath) ? f.Name : currentRelativePath + "/" + f.Name;
                                string fullUrl = serverBaseUrl + Request.ApplicationPath.TrimEnd('/') + "/" + link.Replace(" ", "%20");
                                bool isVid = IsPreviewableVideo(f.Extension);
                                bool isImg = IsPreviewableImage(f.Extension);
                        %>
                            <tr data-type="file">
                                <td class="text-center">
                                    <div class="icon-box"><i class="<%= GetIconClass(f.Extension) %>"></i></div>
                                </td>
                                <td>
                                    <div class="d-flex align-items-center">
                                        <div class="file-name-container text-truncate">
                                            <a href="<%= link %>" class="file-name" title="<%= f.Name %>"><%= f.Name %></a>
                                        </div>
                                        <% if(isVid) { %> <span class="badge bg-success-subtle text-success border border-success-subtle ms-2 align-middle px-2 mobile-hide" style="font-size: 0.65rem; letter-spacing: 0.5px;">HD VIDEO</span> <% } %>
                                    </div>
                                </td>
                                <td class="text-muted mobile-hide small font-monospace" style="font-size: 0.9rem;"><%= FormatSize(f.Length) %></td>
                                <td class="text-muted mobile-hide small"><%= f.LastWriteTime.ToString("MMM dd, yyyy HH:mm") %></td>
                                <td class="text-end pe-3 pe-md-4">
                                    <div class="d-flex justify-content-end gap-2">
                                        <% if(isVid) { %>
                                            <div class="dropdown d-inline-block">
                                                <button class="btn-action btn-stream dropdown-toggle" type="button" data-bs-toggle="dropdown" title="Stream Options"><i class="fa-solid fa-play"></i></button>
                                                <ul class="dropdown-menu dropdown-menu-end shadow-lg border-0 rounded-4 p-2">
                                                    <li><h6 class="dropdown-header text-uppercase small fw-bold text-muted">Select Player</h6></li>
                                                    <li><a class="dropdown-item rounded py-2" href="#" onclick="previewMedia('<%= f.Name %>', '<%= link %>', 'video'); return false;"><i class="fa-solid fa-globe fa-fw me-2 text-primary"></i>Web Browser Player</a></li>
                                                    <li><hr class="dropdown-divider"></li>
                                                    <li><a class="dropdown-item rounded py-2 d-none d-md-block" href="vlc://<%= fullUrl %>"><i class="fa-solid fa-tv fa-fw me-2 text-warning"></i>VLC Media Player (PC)</a></li>
                                                    <li><a class="dropdown-item rounded py-2 d-none d-md-block" href="potplayer://<%= fullUrl %>"><i class="fa-solid fa-tv fa-fw me-2 text-info"></i>PotPlayer (PC)</a></li>
                                                    <li><a class="dropdown-item rounded py-2" href="intent:<%= fullUrl %>#Intent;package=com.mxtech.videoplayer.ad;type=video/*;end"><i class="fa-solid fa-play fa-fw me-2 text-primary"></i>MX Player (Mobile)</a></li>
                                                    <li><a class="dropdown-item rounded py-2" href="intent:<%= fullUrl %>#Intent;package=com.mxtech.videoplayer.pro;type=video/*;end"><i class="fa-solid fa-star fa-fw me-2 text-warning"></i>MX Player Pro (Mobile)</a></li>
                                                </ul>
                                            </div>
                                        <% } else if(isImg) { %>
                                            <button onclick="previewMedia('<%= f.Name %>', '<%= link %>', 'image')" class="btn-action btn-stream" data-bs-toggle="tooltip" title="View Image"><i class="fa-solid fa-eye"></i></button>
                                        <% } %>
                                        <a href="<%= link %>" download class="btn-action btn-download" data-bs-toggle="tooltip" title="Download"><i class="fa-solid fa-download"></i></a>
                                        
                                        <button onclick="copyLink('<%= fullUrl %>', 'Link Copied to Clipboard!')" class="btn-action btn-copy mobile-hide" data-bs-toggle="tooltip" title="Copy Direct Link"><i class="fa-solid fa-link"></i></button>
                                    </div>
                                </td>
                            </tr>
                        <% } 
                        } catch { %>
                            <tr><td colspan="5" class="text-center text-danger py-5"><i class="fa-solid fa-triangle-exclamation fa-2x mb-3"></i><br>Directory Access Error or Invalid Path</td></tr>
                        <% } %>
                    </tbody>
                </table>
                <div id="emptyState" class="d-none text-center py-5 mt-4">
                    <div class="icon-box mx-auto mb-3 text-secondary opacity-50" style="width: 80px; height: 80px; font-size: 2.5rem;"><i class="fa-solid fa-magnifying-glass"></i></div>
                    <h5 class="text-muted fw-bold">No files found</h5>
                    <p class="text-muted small">Try adjusting your search criteria</p>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="previewModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-xl modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg bg-transparent">
                <div class="modal-header border-bottom-0 bg-dark text-white rounded-top-3">
                    <h5 class="modal-title fs-6 fw-semibold text-truncate" id="previewTitle">File Preview</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" onclick="stopMedia()"></button>
                </div>
                <div class="modal-body p-0 text-center bg-black position-relative shadow" style="min-height: 400px; display: flex; align-items: center; justify-content: center;">
                    <video id="videoPlayer" controls class="w-100 d-none" style="max-height: 85vh;" autoplay><source id="videoSource" src="" type="video/mp4"></video>
                    <img id="imageViewer" src="" class="img-fluid d-none" style="max-height: 85vh;" alt="Preview">
                </div>
                <div class="modal-footer border-top-0 bg-dark rounded-bottom-3 justify-content-between">
                    <a id="modalDownload" href="#" download class="btn btn-primary rounded-pill px-4 shadow"><i class="fa-solid fa-download me-2"></i>Download File</a>
                    <button class="btn btn-outline-light rounded-pill px-4" data-bs-dismiss="modal" onclick="stopMedia()">Close Preview</button>
                </div>
            </div>
        </div>
    </div>
    
    <div id="toast" class="d-flex align-items-center gap-2"><i class="fa-solid fa-circle-check text-success fs-5"></i><span id="toastMsg" class="fw-medium">Action Successful</span></div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Theme Toggle Logic
        function toggleTheme() { const h = document.documentElement; const c = h.getAttribute('data-bs-theme'); const i = document.getElementById('themeIcon'); if (c === 'light') { h.setAttribute('data-bs-theme', 'dark'); i.className = 'fa-solid fa-sun'; localStorage.setItem('theme', 'dark'); } else { h.setAttribute('data-bs-theme', 'light'); i.className = 'fa-solid fa-moon'; localStorage.setItem('theme', 'light'); } }
        (function() { const s = localStorage.getItem('theme') || 'light'; document.documentElement.setAttribute('data-bs-theme', s); document.getElementById('themeIcon').className = s === 'dark' ? 'fa-solid fa-sun' : 'fa-solid fa-moon'; })();
        
        // Clock
        setInterval(() => { document.getElementById('clock').innerText = new Date().toLocaleString('en-US', { weekday: 'short', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }); }, 1000);
        
        // Tooltips Init
        const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
        const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));

        // Media Player Logic
        const pm = new bootstrap.Modal(document.getElementById('previewModal'));
        function previewMedia(n, l, t) { document.getElementById('previewTitle').innerText = n; document.getElementById('modalDownload').href = l; const v = document.getElementById('videoPlayer'); const i = document.getElementById('imageViewer'); v.classList.add('d-none'); i.classList.add('d-none'); if (t === 'video') { v.src = l; v.classList.remove('d-none'); v.play(); } else { i.src = l; i.classList.remove('d-none'); } pm.show(); }
        function stopMedia() { const v = document.getElementById('videoPlayer'); v.pause(); v.src = ""; }
        document.getElementById('previewModal').addEventListener('hidden.bs.modal', stopMedia);
        
        // Search Filter
        function searchTable() { 
            const f = document.getElementById("tableSearch").value.toUpperCase(); 
            const tr = document.getElementById("fileTable").getElementsByTagName("tr"); 
            let v = 0; 
            for (let i = 1; i < tr.length; i++) { 
                if(tr[i].innerHTML.includes('Go Back')) continue; 
                const td = tr[i].getElementsByTagName("td")[1]; 
                if (td) { 
                    if ((td.textContent || td.innerText).toUpperCase().indexOf(f) > -1) { 
                        tr[i].style.display = ""; v++; 
                    } else { 
                        tr[i].style.display = "none"; 
                    } 
                } 
            } 
            document.getElementById('emptyState').classList.toggle('d-none', v > 0); 
        }
        
        // Sorting Logic
        function sortTable(n) { 
            var t = document.getElementById("fileTable"), r, s = true, i, x, y, ss, d = "asc", c = 0; 
            while (s) { 
                s = false; r = t.rows; let sr = 1; 
                if(r[1] && r[1].innerHTML.includes('Go Back')) sr = 2; 
                for (i = sr; i < (r.length - 1); i++) { 
                    ss = false; x = r[i].getElementsByTagName("TD")[n]; y = r[i + 1].getElementsByTagName("TD")[n]; 
                    if (d == "asc") { 
                        if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) { ss = true; break; } 
                    } else if (d == "desc") { 
                        if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) { ss = true; break; } 
                    } 
                } 
                if (ss) { 
                    r[i].parentNode.insertBefore(r[i + 1], r[i]); s = true; c++; 
                } else { 
                    if (c == 0 && d == "asc") { d = "desc"; s = true; } 
                } 
            } 
        }
        
        // Copy to Clipboard
        function copyLink(text, msg) {
            if (navigator.clipboard && window.isSecureContext) {
                navigator.clipboard.writeText(text).then(() => showToast(msg)).catch(() => fallbackCopy(text, msg));
            } else {
                fallbackCopy(text, msg);
            }
        }

        function fallbackCopy(text, msg) {
            const textArea = document.createElement("textarea");
            textArea.value = text;
            textArea.style.top = "0"; textArea.style.left = "0"; textArea.style.position = "fixed";
            document.body.appendChild(textArea);
            textArea.focus(); textArea.select();
            try {
                const successful = document.execCommand('copy');
                if(successful) showToast(msg);
                else alert("Copy failed. Please copy manually: " + text);
            } catch (err) {
                console.error('Fallback copy failed', err);
                alert("Copy failed. Please copy manually: " + text);
            }
            document.body.removeChild(textArea);
        }

        function showToast(msg) {
            const o = document.getElementById("toast");
            if(msg) document.getElementById("toastMsg").innerText = msg;
            o.classList.add("show");
            setTimeout(() => o.classList.remove("show"), 2500);
        }
    </script>
</body>
</html>