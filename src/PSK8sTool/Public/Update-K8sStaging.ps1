function Update-K8sStaging {
    param (
        [string] $tag
    )
    if ([string]::IsNullOrWhiteSpace($tag)) {
        Write-Error "tag 不能为空" -ErrorAction Stop
    }

    $projectName = Get-ProjectName;
    Write-Host "当前项目 $projectName" -ForegroundColor Green;
    if ($null -ne $(git diff HEAD --name-only)) {
        git diff HEAD --name-only
        Write-Error "上述文件尚未提交" -ErrorAction Stop;
    }
    git pull
    $sln = Get-Item *.sln;
    if (!$sln) {
        Write-Error "当前目录不是解决方案目录" -ErrorAction Stop;
    }
    Find-Tag $tag;
    # 发布vNext
    if (Test-Path .\sql\vNext) {
        Rename-Item .\sql\vNext .\sql\$tag
    }
    Convert-MigrationToSql $tag;
    if ($null -eq $(git diff HEAD --name-only)) {
        Write-Error "当前项目没有脚本" -ErrorAction Stop;
    }
    git add .
    git commit -m "准备脚本 $tag"
    git tag $tag
    Write-Host "Commit 已经生成" -ForegroundColor Green;
    Copy-ScriptToK8sStaging $tag $projectName
}
