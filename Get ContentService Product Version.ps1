$path = 'C:\Program Files\Imagine Communications\Content Service\ContentService.exe'
$item = get-item -LiteralPath $path

$item.VersionInfo.ProductVersion
