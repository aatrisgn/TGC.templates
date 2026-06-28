param(
    [Parameter(Mandatory = $true)]
    [string]$registryNamespace,

    [Parameter(Mandatory = $true)]
    [string]$imageName,

    [Parameter(Mandatory = $true)]
    [string]$inputTag
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

$namespaceName = $registryNamespace

Write-Host "Namespace: $namespaceName"
Write-Host "Image    : $imageName"
Write-Host "Input tag: $inputTag"

$namespaces = scw registry namespace list name=$namespaceName -o json | ConvertFrom-Json
$namespace = $namespaces | Where-Object { $_.name -eq $namespaceName } | Select-Object -First 1
if ($null -eq $namespace) {
    Write-Error "Namespace '$namespaceName' not found."
    exit 1
}

$images = scw registry image list "namespace-id=$($namespace.id)" "name=$imageName" -o json | ConvertFrom-Json
$image = $images | Where-Object { $_.name -eq $imageName } | Select-Object -First 1
if ($null -eq $image) {
    Write-Error "Image '$imageName' not found in namespace '$namespaceName'."
    exit 1
}

$tags = scw registry tag list "image-id=$($image.id)" order-by=created_at_desc -o json | ConvertFrom-Json

if ($inputTag -eq 'latest') {
    Write-Host "Tag is 'latest' - resolving newest tag..."
    $resolvedTag = $tags | Where-Object { $_.name -ne 'latest' } | Select-Object -First 1 -ExpandProperty name
    if ([string]::IsNullOrEmpty($resolvedTag)) {
        Write-Error "No non-'latest' tags found for image '$imageName'."
        exit 1
    }
    Write-Host "Resolved tag: $resolvedTag"
}
else {
    Write-Host "Verifying tag '$inputTag' exists..."
    $match = $tags | Where-Object { $_.name -eq $inputTag } | Select-Object -First 1
    if ($null -eq $match) {
        $available = ($tags | Select-Object -ExpandProperty name) -join ', '
        Write-Error "Tag '$inputTag' not found for image '$imageName'. Available: $available"
        exit 1
    }
    $resolvedTag = $inputTag
    Write-Host "Tag verified: $resolvedTag"
}

"IMAGE_TAG=$resolvedTag" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
Write-Host "GitHub Actions output IMAGE_TAG set to: $resolvedTag"
