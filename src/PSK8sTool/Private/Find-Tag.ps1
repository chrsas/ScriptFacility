
<# 检测Tag是否存在 #>
function Find-Tag {
    param (
        [string] $tag
    )
    git tag | ForEach-Object {
        if ($_ -eq $tag) {
            Write-Error "Tag $tag 已经存在" -ErrorAction Stop;
        }
    }
}