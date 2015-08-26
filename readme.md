# QuickServicePub
Allows a developer to quickly publish services to their application/web server.

QuickServicePub **WILL**:

* Update a service that has already been published and configured (either manually or by Chef)
* Clean up old server files, including deleting log files
* Copy binaries and other service files from the developer's machine to the server
* Stop and restart window services, as necessary

QuickServicePub **WILL NOT**:

* Install a new service on the server
* Pull projects from source
* Build projects
* Overwrite configuration files in the \configs directory

### Usage
After installing QuickServicePub:

1. Copy **QuickServicePub.config.template.json** to **QuickServicePub.config.json**
2. Update **QuickServicePub.config.json** with your environment values
   - See below for format documentation and example usage
3. (Optionally) Add additional repo or project definitions to **QuickServicePub.config.json**

To publish:

1. Pull service repo from GIT, if necessary
2. Build solution
3. Use QuickServicePub to either
   - Publish all projects in a repository: **Publish-ServiceRepo** _repository.name_
   - Publish a single project: **Publish-ServiceProject** _project.name_

### QuickServicePub.config.json Format

* environment
  * sourceRoot: The directory on your local machine where GIT repositories live
  * webServiceRoot: The web service root directory on your web server
  * winServiceRoot: The windows service root directory on your app server (i.e. Program Files (x86)/Parametric Portfolio Associates)
  * winServiceHostName: The name of your app server
* repos: Array of repository definitions
  * repoName: The name of the GIT repository directory
  * projects: Array of service projects in the repository
    * projectName: The name of the service project directory
    * type: The service project type, either **web** or **win**
    * destination: The directory under the root service directory where the service is installed
    * binPath: For Windows services, the relative path from the project directory for the service binary directory
    * serviceName: For Window services, the service name

### QuickServicePub.config.json Example

    {
        "environment" : {
            "sourceRoot":"c:/git",
            "webServiceRoot":"//sea-2500-24/c$/services",
            "winServiceRoot":"//sea-2500-24/c$/Program Files (x86)/Parametric Portfolio Associates",
            "winServiceHostName":"sea-2500-24"
            },
        "repos":[
            { "repoName":"Axiom.Services","projects":[ 
                {"projectName":"PPA.Axiom.Services","type":"web","destination":"AxiomService"} ]},
            { "repoName":"Edison.Services","projects":[
                {"projectName":"PPA.Edison.WcfService.BenchmarkData","type":"web","destination":"BenchmarkService"},
                {"projectName":"PPA.Edison.WcfService.MarketData","type":"web","destination":"EdisonMarketDataService"},
                {"projectName":"PPA.Edison.WcfService.RiskData","type":"web","destination":"EdisonRiskDataService"} ]},
            { "repoName":"Edison.WebApi","projects":[ 
                {"projectName":"Edison.WebApi","type":"web","destination":"EdisonWeb"} ]},
            { "repoName":"Phoenix", "projects":[ 
                {"projectName":"PPA.Phoenix.TopShelf.ScenarioPosting","type":"win","destination":"PhoenixScenarioPosting","binPath":"bin/debug","serviceName":"PPA.Phoenix.ScenarioPosting"},
                {"projectName":"PPA.Phoenix.WebApi","type":"web","destination":"PhoenixWebApi"} ]},
            { "repoName":"TradeDesk.Services","projects":[ 
                {"projectName":"PPA.TradeDesk.Services","type":"web","destination":"TradeDeskService"} ]},
            { "repoName":"Verona.Services","projects":[
                {"projectName":"PPA.Verona.Web","type":"web","destination":"VeronaWebService"},
                {"projectName":"PPA.Verona.WcfService.Reports","type":"web","destination":"VeronaReportsService"},
                {"projectName":"PPA.Verona.Service","type":"win","destination":"VeronaService","binPath":"bin/x86/debug","serviceName":"PPA.Verona.Service"} ]} 
            ]
    }
