# QuickServicePub
Allows a developer to quickly publish services to the developer's application/web server.

QuickServicePub WILL:

* Update a service that has already been published and configured (either manually or by Chef)
* Clean up old server files, including deleting log files
* Copy binaries and other service files from the developer's machine to the server
* Stop and restart window services, as necessary

QuickServicePub WILL NOT:

* Install a new service on the server
* Pull projects from source
* Build projects
* Overwrite configuration files in the \configs directory

### Usage
After installing QuickServicePub:

1. Copy "QuickServicePub.config.template.json" to "QuickServicePub.config.json"
2. Update "QuickServicePub.config.json" with your environment values
3. (Optionally) Add additional repo or project definitions to "QuickServicePub.config.json"

To publish:

1. Pull service repo from GIT, if necessary
2. Build solution
3. Use QuickServicePub to either
   - Publish all projects in a repository: Publish-ServiceRepo _repository.name_
   - Publish a single project: Publish-ServiceProject _project.name_

