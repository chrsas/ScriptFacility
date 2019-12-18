$tag = Read-Host '请输入Tag'
git tag | % { if ($_ -eq $tag) { Write-Host -ForegroundColor Red Tag $tag 已经存在; return } }

Get-ChildItem .\src\ -Name | % { if ($_ -match 'Data$') { $projectPath = $_; return } }
dotnet ef migrations script -p .\src\$projectPath\$projectPath.csproj -o .\sql\$tag\20191217092334.sql

Get-ChildItem .\src\Sunlight.Stats.Data\Migrations\ | Where-Object { $_.name -match "^\d" } | Move-Item -Destination '.\migration history\'
git add .
git commit -m ""