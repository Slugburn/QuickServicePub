# module-level variables
$environment = $null
$repos = $null

function deploy-win-service (
    [String]
    [ValidateNotNullOrEmpty()]
    $repoName,

    [String]
    [ValidateNotNullOrEmpty()]
    $projectName,

    [String]
    [ValidateNotNullOrEmpty()]
    $destination,

    [String]
    [ValidateNotNullOrEmpty()]
    $binPath,

    [String]
    [ValidateNotNullOrEmpty()]
    $serviceName,

    [String]
    [ValidateNotNullOrEmpty()]
    $sourceRoot,

    [String]
    [ValidateNotNullOrEmpty()]
    $winServiceRoot,

    [String]
    [ValidateNotNullOrEmpty()]
    $winServiceHostName ) 
{
    $projectDir = join-path (join-path $sourceRoot $repoName) $projectName
    $binDir = join-path $projectDir $binPath
    $destinationDir = join-path $winServiceRoot $destination

    $service = get-service -ComputerName $winServiceHostName -Name $serviceName
    echo "`tStopping $serviceName service..."
    stop-service -InputObject $service
    $service.WaitForStatus('Stopped','00:00:30')
    [System.Threading.Thread]::Sleep(2000)

    echo "`tCleaning files from $destinationDir"
    remove-item (join-path $destinationDir '*.exe')
    remove-item (join-path $destinationDir '*.dll')
    echo "`tCleaning log files from $destinationDir"
    remove-item (join-path $destinationDir '*log*.txt')
    
    echo "`tCopying files from $binDir to $destinationDir"
    copy-item (join-path $binDir '*.exe') $destinationDir
    copy-item (join-path $binDir '*.exe.config') $destinationDir
    copy-item (join-path $binDir '*.dll') $destinationDir
    
    echo "`tStarting $serviceName service..."
    Start-Service -InputObject $service
    $service.WaitForStatus('Running','00:00:30')
    echo "`t$serviceName started."
}

function deploy-web-service (
    [String]
    [ValidateNotNullOrEmpty()]
    $repoName,

    [String]
    [ValidateNotNullOrEmpty()]
    $projectName,

    [String]
    [ValidateNotNullOrEmpty()]
    $destination,

    [String]
    [ValidateNotNullOrEmpty()]
    $sourceRoot,

    [String]
    [ValidateNotNullOrEmpty()]
    $webServiceRoot ) 
{
    $sourceDir = join-path (join-path $sourceRoot $repoName) $projectName
    $destinationDir = join-path $webServiceRoot $destination
    echo "`tCopying web files from $sourceDir to $destinationDir"
    copy-item (join-path $sourceDir '*.svc') $destinationDir -Force
    copy-item (join-path $sourceDir '*.asax') $destinationDir -Force
    copy-item (join-path $sourceDir 'web.config') $destinationDir -Force
    echo "`tCleaning files from $(join-path $destinationDir 'bin')"
    remove-item (join-path $destinationDir 'bin\*.*')
    echo "`tCleaning log files from $destinationDir"
    remove-item (join-path $destinationDir '*log*.txt')
    echo "`tCopying files from $(join-path $sourceDir '\bin') to $(join-path $destinationDir '\bin')"
    copy-item (join-path $sourceDir 'bin\*.dll') (join-path $destinationDir '\bin')
    copy-item (join-path $sourceDir 'bin\*.xml') (join-path $destinationDir '\xml')
}

function deploy-project (
    [String]
    [ValidateNotNullOrEmpty()]
    $repoName,

    [String]
    [ValidateNotNullOrEmpty()]
    $projectName,

    [String]
    [ValidateSet("web","win")] 
    $projectType,

    $project
    )
{
    echo "Deploying project: $projectName"
    switch ($projectType) {
        "web" { deploy-web-service $repoName $projectName $project.destination $environment.sourceRoot $environment.webServiceRoot }
        "win" { deploy-win-service $repoName $projectName $project.destination $project.binPath $project.serviceName $environment.sourceRoot `
                $environment.winServiceRoot $environment.winServiceHostName }
    }
}

function deploy-repo (
    [String]
    [ValidateNotNullOrEmpty()]
    $repoName,

    [ValidateCount(1,[Int32]::MaxValue)]
    $projects)
{
    echo "Deploying repo: $repoName"
    foreach ($project in $repo.projects) {
        deploy-project $repoName $project.projectName $project.type $project $environment 
    }
}

<#
 .Synopsis
 Publishes a single service project.

 .Description
 Publishes a single service project.

 .Parameter projectName
 The name of the project to publish. The project must be defined in the settings JSON file specified when the PublishService module was loaded.

 .Example
 Publish-ServiceProject PPA.Verona.Service
#>
function Publish-ServiceProject ([string]$projectName)
{
    if (!$projectName) { throw "missing parameter: projectName" }
    $project = $projects | Where -Property projectName -EQ $projectName | Select -First 1
    if (!$project) { throw "project named $projectName not found" }
    $repoName = $project.repoName
    echo "Project named $projectName found in repo named $repoName"
    deploy-project $repoName $projectName $project.type $project
}

<#
 .Synopsis
 Publishes all service projects in a repository.

 .Description
 Publishes all service projects in a repository.

 .Parameter repoName
 The name of the repository to publish. The repository must be defined in the settings JSON file specified when the PublishService module was loaded.

 .Example
 Publish-ServiceRepo Verona.Services
#>
function Publish-ServiceRepo ([string]$repoName)
{
    if (!$repoName) {throw "missing parameter: repoName"}
    $repoProjects = $projects | Where -Property repoName -EQ $repoName
    if (!$repoProjects) { throw "repo named $repoName not found" }
    $repoProjects | ForEach {deploy-project $repoName $_.projectName $_.type $_ }
}

Export-ModuleMember -Function Publish-ServiceRepo
Export-ModuleMember -Function Publish-ServiceProject

function on-import(){
    $configFile = Join-Path $PSScriptRoot "QuickServicePub.config.json"

    if (!(Test-Path $configFile)) {throw "configuration file '$configFile' does not exist"}

    $config = Get-Content -Raw -Path $configFile | ConvertFrom-Json -Verbose
    if (!$config) { throw "unable to parse configuration file '$configFile'" }

    if (!$config.environment) { throw "environment property not specified" }
    if (!$config.repos) {throw "repos property not specified" }

    $script:environment = $config.environment

    # flatten repos hierarchy to make it easier to work with
    $script:projects = $config.repos | Select -Property repoName -ExpandProperty projects
    
    return $true
}

on-import