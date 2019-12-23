function Convert-MigrationToSql {
    param (
        [string] $tag
    )

    Get-ChildItem -Directory .\src\ -Name | ForEach-Object {
        if ($_ -match 'Data$') {
            $projectPath = $_;
        }
        elseif ($_ -match 'Host$') {
            $hostPath = $_;
        }
    }

    $migrations = Get-ChildItem ".\src\$projectPath\Migrations\" -File *.cs | `
        # Migration个命名都是14个数字加_开头
        Where-Object { $_.name -match "^\d{14}_" }

    if ($null -eq $migrations) {
        # 没有Migration需要生成
        return
    }
    $sqlFileName = $($migrations | Select-Object -Last 1).Name.Split('_')[0];
    $fullSqlFileName = ".\sql\$tag\$sqlFileName.sql";

    dotnet ef migrations script -s ".\src\$hostPath\$hostPath.csproj" -p ".\src\$projectPath\$projectPath.csproj" -o $fullSqlFileName
    # 挪动文件到迁移历史
    $migrations | Move-Item -Destination '.\migration history\'
    Write-Host "Migration 已经处理" -ForegroundColor Green
    return $fullSqlFileName;
}