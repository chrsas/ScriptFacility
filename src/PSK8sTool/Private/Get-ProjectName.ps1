function Get-ProjectName {
    $readme = Get-Content .\README.md;
    # 单行的README, 读出来的是 string
    if ($readme.GetType().FullName -eq "System.String") {
        $firstLine = $readme;
    }
    else {
        $firstLine = $readme[0];
    }
    return $firstLine.Replace("# ", "").Replace("/", "\");
}