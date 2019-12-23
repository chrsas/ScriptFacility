function Get-ProjectName {
    $readme = Get-Content .\README.md;
    $projectName = $readme[0].Substring(2).Replace("/", "\");
    return $projectName;
}