function Update-K8sProduction {
    param ( )
    Import-Module powershell-yaml;
    $pPathList = Get-ChildItem -Directory -Exclude web-ui, notification;
    $upServices = New-Object 'Collections.Generic.List[UpgradeInfo]'
    $hasOverlays = $false;
    foreach ($pPath in $pPathList) {
        # 找到 overlays 目录下的 staging 和 production 的yaml
        foreach ($overlay in Get-ChildItem $pPath -Depth 2 -Directory overlays) {
            $hasOverlays = $true;
            if (!(Test-Path $overlay/staging/kustomization.yaml)) {
                continue;
            }
            $productionSource = Get-Content $overlay/production/kustomization.yaml;
            $production = ConvertFrom-Yaml $(Get-Content -Raw $overlay/production/kustomization.yaml);
            $staging = ConvertFrom-Yaml $(Get-Content -Raw $overlay/staging/kustomization.yaml);
            if ([string]::IsNullOrWhiteSpace($staging.images.newTag)) {
                # 依赖的基础服务没有newTag
                continue;
            }
            if ([String]::IsNullOrWhiteSpace($production.commonLabels.app)) {
                Write-Host "$overlay\production\kustomization.yaml 没有 commonLabels.app" -ForegroundColor DarkMagenta
                continue;
            }
            if ($production.images.newTag.GetType().FullName -eq "System.Object[]") {
                # 针对多个镜像的情况
                if (!([System.Linq.Enumerable]::SequenceEqual([object[]]$production.images.newTag, [object[]]$staging.images.newTag))) {
                    $info = [UpgradeInfo]::new();
                    $info.App = $production.commonLabels.app;
                    $info.Message = "有多个image, 需要手动处理, PS: 自动处理的代码需要你的帮助 :-)";
                    $upServices.Add($info);
                }
                continue;
            }
            if ($production.images.newTag -eq $staging.images.newTag) {
                continue;
            }
            $info = [UpgradeInfo]::new();
            $info.App = $production.commonLabels.app;
            $info.NewTag = $staging.images.newTag;
            $info.OldTag = $production.images.newTag;
            $upServices.Add($info);
            $tagStr = $productionSource[$productionSource.Length - 1];
            # 转换后的Yaml对象保存后, 其格式很怪异, 所以这里直接用文本转换
            $productionSource[$productionSource.Length - 1] = "$($tagStr.Split(":")[0]): $($staging.images.newTag)"
            $productionSource > $overlay/production/kustomization.yaml
        }
    }
    if (!($hasOverlays)) {
        Write-Host "当前目录的子目录里没有 overlays" -ForegroundColor Red
        return;
    }
    if ($upServices.Count -eq 0) {
        #有一行日期信息在里面
        Write-Host "没有需要升级的服务" -ForegroundColor Red
        return;
    }
    Write-Host "下列服务将升级, 请仔细核对:" -ForegroundColor DarkYellow
    # 着色方法 https://stackoverflow.com/a/49038815/4052810
    $upServices | Format-Table App, OldTag, @{
        Label      = "NewTag"
        Expression = {
            $color = "32"
            $e = [char]27
            "$e[${color}m$($_.NewTag)${e}[0m"
        }
    },@{
        Label = "Message"
        Expression = {
            $color = "31"
            $e = [char]27
            "$e[${color}m$($_.Message)${e}[0m"
        }
    }
    $strList = New-Object "System.Collections.Generic.List[String]";
    $oldGroup = $upServices[0].App.Split('-')[0];
    foreach ($info in $upServices) {
        $newGroup = $info.App.Split('-')[0];
        # 增加分组行
        if ($oldGroup -ne $newGroup) {
            $oldGroup = $newGroup;
            $strList.Add("---");
        }
        $strList.Add("- [ ] $($info.App) $($info.NewTag)");
    }
    $strList | clip
    Write-Host "发布内容已经复制到粘贴板" -ForegroundColor DarkCyan
}

class UpgradeInfo {
    [string]$App;
    [string]$OldTag;
    [string]$NewTag;
    [string]$Message;
}

# cd 'C:\GitLab\Exceed\Kubernetes\Deployment'
# Update-K8sProduction