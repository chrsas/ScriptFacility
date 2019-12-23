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
