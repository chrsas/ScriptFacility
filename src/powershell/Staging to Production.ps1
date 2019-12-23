function Update-K8sProduction {
    param ( )
    Import-Module powershell-yaml;
    $pPathList = Get-ChildItem -Directory -Exclude web-ui, notification;
    "下列服务将升级, 请仔细核对:"
    $upServices = New-Object 'Collections.Generic.List[string]'
    $upServices.Add("# $(Get-Date -Format yyyy-MM-dd)")
    $newGroup = [String]::Empty;
    $hasOverlays = $false;
    foreach ($pPath in $pPathList) {
        # 找到 overlays 目录下的 staging 和 production 的yaml
        Get-ChildItem $pPath -Depth 2 -Directory overlays | ForEach-Object {
            $hasOverlays = $true;
            $productionSource = Get-Content $_/production/kustomization.yaml;
            $production = ConvertFrom-Yaml $(Get-Content -Raw $_/production/kustomization.yaml);
            $staging = ConvertFrom-Yaml $(Get-Content -Raw $_/staging/kustomization.yaml);
            if ($production.images.newTag -ne $staging.images.newTag) {
                $group = $production.commonLabels.app.Split('-')[0];
                # 服务组变换, 增加横线
                if (($newGroup -ne $group) -and ($newGroup.Length -ne 0) ) {
                    $upServices.Add("---");
                }
                $newGroup = $group;
                $upServices.Add("- [ ] $($production.commonLabels.app) $($staging.images.newTag)")
                Write-Host $production.commonLabels.app $production.images.newTag =>
                Write-host $staging.images.newTag -ForegroundColor DarkCyan
                $tagStr = $productionSource[$productionSource.Length - 1];
                # 转换后的Yaml对象保存后, 其格式很怪异, 所以这里直接用文本转换
                $productionSource[$productionSource.Length - 1] = "$($tagStr.Split(":")[0]): $($staging.images.newTag)"
                $productionSource > $_/production/kustomization.yaml
            }
        }
    }
    if (!($hasOverlays)) {
        Write-Host "当前目录的子目录里没有 overlays" -ForegroundColor Red
        return;
    }
    if ($upServices.Count -eq 1) {
        #有一行日期信息在里面
        Write-Host "没有需要升级的服务" -ForegroundColor Red
        return;
    }
    Write-Host "发布内容已经复制到粘贴板" -ForegroundColor DarkCyan
    $upServices | clip
}

Export-ModuleMember -Function Update-K8sProduction