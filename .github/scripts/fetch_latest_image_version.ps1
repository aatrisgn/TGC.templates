param(
    [Parameter(Mandatory = $true)]
    [string]$acrUrl,

    [Parameter(Mandatory = $true)]
    [string]$imageName,

    [Parameter(Mandatory = $true)]
    [string]$inputTag
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

$registryName = $acrUrl -replace '^https?://', '' -replace '\.azurecr\.io.*$', ''

Write-Host "Registry : $registryName"
Write-Host "Image    : $imageName"
Write-Host "Input tag: $inputTag"

try {
    $tagList = Get-AzContainerRegistryTag -RegistryName $registryName -RepositoryName $imageName
}
catch {
    Write-Error "Failed to retrieve tags from ACR for image '$imageName': $_"
    exit 1
}

$sortedTags = $tagList.Tags `
    | Sort-Object -Property {
        [System.DateTimeOffset]::Parse(
            $_.LastUpdateTime.Trim(),
            [System.Globalization.CultureInfo]::InvariantCulture)
    } -Descending `
    | Select-Object -ExpandProperty Name

if ($inputTag -eq 'latest') {
    Write-Host "Tag is 'latest' - resolving newest tag from ACR..."

    $resolvedTag = $sortedTags | Where-Object { $_ -ne 'latest' } | Select-Object -First 1

    if ([string]::IsNullOrEmpty($resolvedTag)) {
        Write-Error "No non-'latest' tags found in ACR for image '$imageName'."
        exit 1
    }

    Write-Host "Resolved tag: $resolvedTag"
}
else {
    Write-Host "Verifying tag '$inputTag' exists in ACR..."

    if ($sortedTags -notcontains $inputTag) {
        Write-Error "Tag '$inputTag' does not exist in ACR for image '$imageName'. Available tags: $($sortedTags -join ', ')"
        exit 1
    }

    $resolvedTag = $inputTag
    Write-Host "Tag verified: $resolvedTag"
}

# Set GitHub Actions output
"IMAGE_TAG=$resolvedTag" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
Write-Host "GitHub Actions output IMAGE_TAG set to: $resolvedTag"