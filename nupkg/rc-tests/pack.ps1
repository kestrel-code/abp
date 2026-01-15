. "..\common.ps1"

$rootFolder = (Get-Item -Path "../../" -Verbose).FullName
$localPackagesFolder = "C:\Github\localpackages"

# Delete existing nupkg files from local packages folder
if (Test-Path $localPackagesFolder) {
    Remove-Item (Join-Path $localPackagesFolder "*.nupkg") -Force -ErrorAction SilentlyContinue
}

# Rebuild all solutions
foreach ($solutionPath in $solutions) {    
    $solutionAbsPath = (Join-Path $rootFolder $solutionPath)
    Set-Location $solutionAbsPath
    dotnet build --configuration Release -- /maxcpucount
    if (-Not $?) {
        Write-Host ("Build failed for the solution: " + $solutionPath)
        Set-Location $rootFolder
        exit $LASTEXITCODE
    }
}

Set-Location $rootFolder

# Create all packages
$i = 0
$projectsCount = $projects.length
Write-Info "Running dotnet pack on $projectsCount projects..."

# Ensure the local packages folder exists
if (-Not (Test-Path $localPackagesFolder)) {
    New-Item -ItemType Directory -Path $localPackagesFolder -Force
}

foreach($project in $projects) {
    $i += 1
    $projectFolder = Join-Path $rootFolder $project
	$projectName = ($project -split '/')[-1]
		
	# Create nuget pack
    Write-Info "[$i / $projectsCount] - Packing project: $projectName"
	Set-Location $projectFolder

    #dotnet clean
    dotnet pack -c Release --no-build -o $localPackagesFolder -- /maxcpucount

    if (-Not $?) {
        Write-Error "Packaging failed for the project: $projectName" 
        exit $LASTEXITCODE
    }
	
	Seperator
}

# Go back to the custom pack folder
Set-Location $localPackagesFolder
