function Update-K8sStaging {
    param (
        [string] $tag
    )
    if ([string]::IsNullOrWhiteSpace($tag)) {
        Write-Error "tag 不能为空" -ErrorAction Stop
    }

    $projectName = Get-ProjectName;
    Write-Host "当前项目 $projectName" -ForegroundColor Green;
    if ($null -ne $(git diff HEAD --name-only)) {
        git diff HEAD --name-only
        Write-Error "上述文件尚未提交" -ErrorAction Stop;
    }
    git pull
    $sln = Get-Item *.sln;
    if (!$sln) {
        Write-Error "当前目录不是解决方案目录" -ErrorAction Stop;
    }
    Find-Tag $tag;
    # 发布vNext
    if (Test-Path .\sql\vNext) {
        Rename-Item .\sql\vNext .\sql\$tag
    }
    Convert-MigrationToSql $tag;
    if ($null -eq $(git diff HEAD --name-only)) {
        Write-Error "当前项目没有脚本" -ErrorAction Stop;
    }
    git add .
    git commit -m "准备脚本 $tag"
    # git tag $tag
    Write-Host "Commit 已经生成" -ForegroundColor Green;
    Copy-ScriptToK8sStaging $tag $projectName
}

function Copy-ScriptToK8sStaging {
    param (
        [string] $tag,
        [string] $projectName
    )
    if ([string]::IsNullOrWhiteSpace($tag)) {
        Write-Error "tag 不能为空" -ErrorAction Stop
    }
    if(!(Test-Path .\sql\$tag)){
        Write-Error "源地址 .\sql\$tag 不存在" -ErrorAction Stop
    }
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        Write-Error "projectName 不能为空" -ErrorAction Stop
    }
    $deployDir = "..\..\Deployment\deployment\$projectName";
    $targetPath = "$deployDir\sql\$(Get-Date -Format 'yyyyMMdd')-Update";
    $targetDdl = "$targetPath\1.update_ddl.sql";
    $targetData = "$targetPath\2.update_data.sql";
    # 复制ddl
    $sourceDdl = Get-ChildItem .\sql\$tag | Where-Object { $_.Name -Match "^\d{14}" } | Select-Object -First 1;
    if ($null -ne $sourceDdl) {
        if (!(Test-Path $targetDdl)) {
            New-Item -ItemType File -Path $targetDdl
        }
        # Migraion存在性判断
        if ($null -ne (Get-Content $targetDdl | Where-Object { $_ -Match $sourceDdl.BaseName })) {
            Write-Error "Migration $($sourceDdl.BaseName) 已在目标文件中 $($(Get-Item $targetDdl).FullName)" -ErrorAction Stop;
        }
        Get-Content $sourceDdl | Add-Content $targetDdl -Encoding utf8
        Write-Host "追加文件 $($targetDdl.Name)" -ForegroundColor Green
    }
    # 复制手写Sql
    $sourceData = Get-ChildItem .\sql\$tag | Where-Object { $_.Name -Match "^(?!\d{14}).*" };
    if ($null -ne $sourceData) {
        if (!(Test-Path $targetData)) {
            New-Item -ItemType File -Path $targetData
        }
        $targetDataContent = Get-Content $targetData;
        # 手写Sql重复性判断
        foreach ($file in $sourceData) {
            if ($targetDataContent | Where-Object { $_ -Match "-- $($file.Name)" }) {
                Write-Error "文件 $($file.Name) 已在目标文件中 $($(Get-Item $targetData).FullName)" -ErrorAction Stop;
            }
        }
        foreach ($file in $sourceData) {
            # 增加文件标记, 便于重复性检测
            Add-Content -Value "-- $($file.Name)" $targetData -Encoding utf8;
            Get-Content $file | Add-Content $targetData -Encoding utf8;
        }
        Write-Host "追加文件 $($targetData.Name)" -ForegroundColor Green
    }
}

function Get-ProjectName {
    $readme = Get-Content .\README.md;
    $projectName = $readme[0].Substring(2).Replace("/", "\");
    return $projectName;
}

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

Export-ModuleMember -Function Update-K8sStaging