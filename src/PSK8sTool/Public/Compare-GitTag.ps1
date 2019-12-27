function Compare-GitTag {
    param (
        [alias("p")]
        [switch]$pushTag
    )
    $root = $PWD
    $tagList = New-Object 'Collections.Generic.List[TagInfo]';
    foreach ($dir in Get-ChildItem -Directory -Depth 1 -Exclude design, '.vs', '.vscode', design, home, kubernetes, deployment, reports, authentication, ocr) {
        set-location $dir
        if ($null -eq $(Get-ChildItem -Directory -Hidden | Where-Object { $_.Name.Contains(".git") })) {
            continue;
        }
        Write-Host "当前目录 $dir" -ForegroundColor DarkGray;
        # 校验当前分支
        $currentBranch = git rev-parse --abbrev-ref HEAD;
        if ($null -ne $(git branch -r --contains $currentBranch)) {
            git pull
        }
        $describe = git describe --tags
        if ($null -eq $describe) {
            continue;
        }
        # tag最新的时候, 没有差异信息
        $info = $describe.Split("-");
        if ($info.Length -eq 1) {
            continue;
        }
        $tagInfo = [TagInfo]::new()
        $tagInfo.Project = $dir;
        $tagInfo.Tag = $info[0]
        $tagInfo.Lag = $info[1]
        $tagList.Add($tagInfo);
        if ($pushTag) {
            Write-Host "$($tagInfo.Project) $($tagInfo.Tag) $($tagInfo.Lag)" -ForegroundColor DarkCyan
        }
        while ($pushTag) {
            $tag = Read-Host "新的Tag";
            if ([string]::IsNullOrWhiteSpace($tag)) {
                break;
            }
            if ($tag -notmatch "^\d+\.\d+.\d+") {
                Write-Warning "新的Tag不符合规范"
                continue;
            }
            Update-K8sStaging -pushTag -tag $tag;
            break;
        }
    }
    $tagList | Format-Table;
    Set-Location $root;
}

class TagInfo {
    [string]$Project
    [string]$Tag
    [Int32]$Lag
}

# Set-Location 'C:\GitLab\Chery'
# Compare-GitTag -p
