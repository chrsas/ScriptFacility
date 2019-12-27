function Convert-MigrationToSql {
    param (
        [string] $tag
    )

    Get-ChildItem -Directory .\src\ -Name | ForEach-Object {
        # 目前有两种方案, 一种以Data结尾, 一种以Core结尾
        if ($_ -match '(Data|Core)$') {
            $projectPath = $_;
        }
        elseif ($_ -match '(Host|Web)$') {
            $hostPath = $_;
        }
    }

    if([string]::IsNullOrWhiteSpace($projectPath)){
        Write-Host 没有Migration需要生成 -ForegroundColor Yellow
        return;
    }

    $migrations = Get-ChildItem ".\src\$projectPath\Migrations\" -File *.cs | `
        # Migration个命名都是14个数字加_开头
        Where-Object { $_.name -match "^\d{14}_" }

    if ($null -eq $migrations) {
        Write-Host 没有Migration需要生成 -ForegroundColor Yellow
        return;
    }
    $sqlFileName = $($migrations | Select-Object -Last 1).Name.Split('_')[0];
    $fullSqlFileName = ".\sql\$tag\$sqlFileName.sql";

    dotnet ef migrations script -s ".\src\$hostPath\$hostPath.csproj" -p ".\src\$projectPath\$projectPath.csproj" -o $fullSqlFileName
    # 挪动文件到迁移历史
    $migrations | Move-Item -Destination '.\migration history\'
    Write-Host "Migration 已经处理" -ForegroundColor Green
    return $fullSqlFileName;
}