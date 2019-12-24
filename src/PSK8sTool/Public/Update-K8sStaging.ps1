function Update-K8sStaging {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $tag,
        [Alias("p")]
        [switch]$pushTag
    )

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
        Write-Information "当前项目没有脚本";
    } else {
        git add .
        git commit -m "准备脚本 $tag"
        Copy-ScriptToK8sStaging $tag $projectName
    }
    git tag $tag
    if ($pushTag) {
        git push --follow-tags
    }
    Write-Host "Commit $tag 已经生成" -ForegroundColor Green;
    Update-StagingFile $tag $projectName
}
