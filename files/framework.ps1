$root = (Get-Location).Path

Get-ChildItem -Recurse -Include *.csproj,*.vbproj |
ForEach-Object {

    $content = Get-Content $_.FullName -Raw

    $framework = $null

    if ($content -match '<TargetFrameworkVersion>(.*?)</TargetFrameworkVersion>') {
        $framework = $Matches[1]
    }
    elseif ($content -match '<TargetFramework>(.*?)</TargetFramework>') {
        $framework = $Matches[1]
    }
    elseif ($content -match '<TargetFrameworks>(.*?)</TargetFrameworks>') {
        $framework = $Matches[1]
    }
	elseif ($content -match '<DefaultTargetFramework>(.*?)</DefaultTargetFramework>') {
        $framework = $Matches[1]
    }

    if ($framework) {

        $relativePath = $_.FullName.Substring($root.Length + 1)
        $firstFolder = ($relativePath -split '[\\/]')[0]

        [PSCustomObject]@{
            Framework = $framework
            Project   = "$firstFolder : $($_.Name)"
        }
    }
} |
Group-Object Framework |
Sort-Object Name |
ForEach-Object {
    "=== $($_.Name) ==="
    $_.Group.Project | Sort-Object
    ""
} | Out-File ProjectFrameworks.out

Write-Host "Framework.out aangemaakt"