function Compare-GitTag {
    param (
        [alias("p")]
        [switch]$pushTag
    )
    $root = $PWD
    $tagList = New-Object 'Collections.Generic.List[TagInfo]';
    foreach ($dir in Get-ChildItem -Directory -Depth 1 -Exclude design, '.vs', '.vscode', design, home, kubernetes, reports, authentication, ocr) {
        set-location $dir
        if ($null -eq $(Get-ChildItem -Directory -Hidden | Where-Object { $_.Name.Contains(".git") })) {
            continue;
        }
        git pull
        $describe = git describe --tags
        if ($null -eq $describe) {
            continue;
        }
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
            if ($tag.Split(".").Count -ne 3) {
                Write-Warning "新的Tag不符合规范"
                continue;
            }
            git tag $tag;
            git push origin $tag;
        }
    }
    if (!($pushTag)) {
        $tagList
    }
    Set-Location $root;
}

class TagInfo {
    [string]$Project
    [string]$Tag
    [Int32]$Lag
}

# Set-Location 'C:\GitLab\Chery'
# Compare-GitTag -p