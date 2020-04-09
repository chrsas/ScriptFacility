function Update-StagingFile {
    param (
        [string] $tag,
        [string] $projectName
    )
    if ([string]::IsNullOrWhiteSpace($tag)) {
        Write-Error "tag 不能为空" -ErrorAction Stop
    }
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        Write-Error "projectName 不能为空" -ErrorAction Stop
    }
    $deployDir = "..\..\kubernetes\deployment\$projectName";
    $targetStaging = "$deployDir\overlays\staging\kustomization.yaml";
    if (!(Test-Path $targetStaging)) {
        Write-Error "部署文件 $targetStaging 不存在" -ErrorAction Stop
    }
    # 转换后的Yaml对象保存后, 其格式很怪异, 所以这里直接用文本转换
    $staging = Get-Content $targetStaging;
    $newTag = $staging[$staging.Length -1];
    if (!($newTag.Contains($tag))) {
        $staging[$staging.Length - 1] = "$($newTag.Split(":")[0]): $tag"
        $staging > $targetStaging
    }
    Write-Host "staging\kustomization.yaml 中tag替换完成" -ForegroundColor Green;
    return $(ConvertFrom-Yaml $(Get-Content -Raw $targetStaging)).commonLabels.app;
}