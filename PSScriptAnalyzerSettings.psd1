@{
  # Default rule set with these explicit suppressions:
  ExcludeRules = @(
    # install.ps1 + migration script use Write-Host with -ForegroundColor for the
    # adopter-facing colored install transcript. Intentional, not a portability bug.
    'PSAvoidUsingWriteHost',
    # Scripts are UTF-8 without BOM — cross-shell-friendly (Linux/macOS bash, pwsh on
    # all platforms). The em-dashes etc. work fine; BOM would just break here-docs.
    'PSUseBOMForUnicodeEncodedFile'
  )
}
