Invoke-Expression (& { (zoxide init powershell | Out-String) })

Invoke-Expression (&starship init powershell)

fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

function y {
	$tmp = (New-TemporaryFile).FullName
	yazi.exe $args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if ($cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
		Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
	}
	Remove-Item -Path $tmp
}