function Update-K8sStaging {
    param (
        [ValidatePattern("^\d+\.\d+.\d+")]
        [string] $tag,
        [Alias("p")]
        [switch]$pushTag
    )
    # 遇到错误就停止
    $ErrorActionPreference = "Stop"
    $projectName = Get-ProjectName;
    Write-Host "当前项目 $projectName" -ForegroundColor Green;
    if ($null -ne $(git diff HEAD --name-only)) {
        git diff HEAD --name-only
        Write-Error "上述文件尚未提交" -ErrorAction Stop;
    }
    git pull
    git describe --tags
    if ([string]::IsNullOrWhiteSpace($tag)) {
        Write-Host "请输入Tag:" -ForegroundColor Yellow -NoNewline
        $tag = Read-Host
        if ($tag -notmatch "^\d+\.\d+.\d+") {
            Write-Error "Tag不符合要求" -ErrorAction Stop;
        }
    }
    $sln = Get-Item *.sln;
    if (!$sln) {
        Write-Error "当前目录不是解决方案目录" -ErrorAction Stop;
    }
    Find-Tag $tag;
    # 发布vNext
    if (Test-Path .\sql\vNext) {
        if (Test-Path .\sql\$tag) {
            Get-ChildItem -File .\sql\vNext | ForEach-Object { Move-Item $_ .\sql\$tag\ }
        }
        else {
            Rename-Item .\sql\vNext $tag
        }
    }
    Convert-MigrationToSql $tag;
    if ($null -eq $(git diff HEAD --name-only)) {
        Write-Information "当前项目没有脚本";
    }
    else {
        git add .
        git commit -m "准备脚本 $tag"
        Copy-ScriptToK8sStaging $tag $projectName
    }
    git tag $tag
    if ($pushTag) {
        git push
        git push origin $tag
    }
    Write-Host "Commit $tag 已经生成" -ForegroundColor Green;
    Update-StagingFile $tag $projectName
}

# cd 'C:\GitLab\Exceed\Auth\am-service-dotnet'
# Update-K8sStaging 1.0.0