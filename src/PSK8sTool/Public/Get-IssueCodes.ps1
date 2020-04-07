function Get-IssueCodes {
    param (
        [ValidatePattern("^\d+\.\d+.\d+")]
        [string] $tag
    )
    if ([String]::IsNullOrWhiteSpace($tag)) {
        $tag = git describe --abbrev=0
    }
    $set = New-Object System.Collections.Generic.HashSet[string];
    git log 1.2.10..HEAD --oneline |
    ForEach-Object {
        if ($_ -match '#\d+') {
            foreach ($ma in $Matches) {
                $null = $set.Add($ma.Values);
            }
        }
    }
    $issues = $($set | Sort-Object) -join ' ';
    return $issues
}