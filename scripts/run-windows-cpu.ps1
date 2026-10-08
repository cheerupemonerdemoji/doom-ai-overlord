param(
    [string]$Scenario = 'basic.cfg',
    [int]$Episodes = 1,
    [int]$MaxSteps = 60,
    [string]$ModelPath = $env:LAYA_DOOM_MODEL,
    [switch]$Headless,
    [switch]$HoldOpen
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Agent = Join-Path $RepoRoot '.venv\Scripts\doom-agent.exe'

if (-not $ModelPath) {
    $ModelPath = Join-Path $env:USERPROFILE `
        'Projects\laya-local\cache\huggingface\hub\models--convaiinnovations--laya\snapshots\7b928d828b7b0e022f929d9bd2e44165aa270148'
}

if (-not (Test-Path -LiteralPath $Agent)) {
    throw "The Doom environment is missing. Expected: $Agent"
}
if (-not (Test-Path -LiteralPath $ModelPath)) {
    throw "The local Laya checkpoint is missing. Set LAYA_DOOM_MODEL or pass -ModelPath."
}

$env:HF_HUB_OFFLINE = '1'
$env:TRANSFORMERS_OFFLINE = '1'
$env:LAYA_DEVICE = 'cpu'
$env:CUDA_VISIBLE_DEVICES = ''
$env:TOKENIZERS_PARALLELISM = 'false'

$RunArgs = @(
    '--scenario', $Scenario,
    '--episodes', $Episodes,
    '--max-steps', $MaxSteps,
    '--model', $ModelPath,
    '--device', 'cpu'
)
if ($Headless) {
    $RunArgs += '--headless'
}
if ($HoldOpen) {
    $RunArgs += '--hold-open'
}

Write-Host "Starting Doom with Laya on CPU ($Scenario). Press Ctrl+C to stop."
& $Agent @RunArgs
