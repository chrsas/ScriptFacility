function Get-IssueCodes {
    param (
        [ValidatePattern("^\d+\.\d+.\d+")]
        [string] $tag
    )
    if ([String]::IsNullOrWhiteSpace($tag)) {
        $tag = git describe --tags --abbrev=0
    }
    $set = New-Object System.Collections.Generic.HashSet[string];
    Invoke-Expression "git log $tag..HEAD --oneline" |
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