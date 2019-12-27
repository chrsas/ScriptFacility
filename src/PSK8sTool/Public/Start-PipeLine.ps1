function Start-Pipeline {
    $gitUrl = git remote get-url origin
    if ([string]::IsNullOrWhiteSpace($gitUrl)) {
        Write-Error "没有找到 git orgin" -ErrorAction Stop;
    }
    if (!($gitUrl.StartsWith("http"))) {
        $gitUrl = "https://$($gitUrl.Replace(':','/'))"
    }
    Start-Process -Path "$($gitUrl.Replace('.git', ''))/pipelines"
}