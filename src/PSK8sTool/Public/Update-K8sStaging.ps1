function Update-K8sStaging {
    param (
        [ValidatePattern("^\d+\.\d+.\d+")]
        [string] $tag,
        [Parameter(Mandatory = $false, HelpMessage = "不推送本地commit到git")]
        [switch]$doNotPush,
        [Parameter(Mandatory = $false, HelpMessage = "标记当前项目不需要查找sln，一般用于项目不需要Script Migration")]
        [switch]$hasntSln,
        [Parameter(Mandatory = $false, HelpMessage = "返回涉及的issue编号")]
        [Alias('i')]
        [switch]$includeIssues
    )
    # 遇到错误就停止
    $ErrorActionPreference = "Stop"
    $projectName = Get-ProjectName;
    Write-Host "当前项目:$projectName" -ForegroundColor Green;
    if ($null -ne $(git diff HEAD --name-only)) {
        git diff HEAD --name-only
        Write-Error "上述文件尚未提交" -ErrorAction Stop;
    }
    # 校验当前分支
    $currentBranch = git rev-parse --abbrev-ref HEAD;
    if ($null -ne $(git branch -r --contains $currentBranch)) {
        git pull --rebase
    }
    if ([string]::IsNullOrWhiteSpace($tag)) {
        Write-Host "分支:$currentBranch Tag:" -ForegroundColor Green -NoNewline
        git describe --tags
        Write-Host "请输入Tag:" -ForegroundColor Yellow -NoNewline
        $tag = Read-Host
        if ($tag -notmatch "^\d+\.\d+.\d+") {
            Write-Error "Tag不符合要求" -ErrorAction Stop;
        }
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
    if ($hasntSln -eq $false) {
        $sln = Get-Item *.sln;
        if (!$sln) {
            Write-Error "当前目录不是解决方案目录" -ErrorAction Stop;
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
    }
    if($includeIssues){
        $issues = Get-IssueCodes
    }
    git tag $tag
    if ($doNotPush -eq $false) {
        git push origin $currentBranch
        git push origin $tag
        Start-Pipeline
    }
    Write-Host "Commit $tag 已经生成" -ForegroundColor Green
    $project = Update-StagingFile $tag $projectName
    $tagInfo ="- $project $tag $issues";
    Write-Host $tagInfo -ForegroundColor Blue
    $tagInfo | clip
    if($includeIssues){
        return $issues
    }
}

# cd 'C:\GitLab\Exceed\Auth\am-service-dotnet'
# Update-K8sStaging 1.0.0