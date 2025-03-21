# Release workflow
This document is necessary because UCP3 ships modules and plugins in its zip file.

These modules and zip files can also be gotten from the Store.

To be user-friendly we ship them by default.

Different builds of the modules and plugins lead to different hashes, especially for modules.

## Steps
Let's imagine we update from 3.0.0 to 3.0.1

### Step 1: prepare the UCP3 repo
In the UCP3 repo, run these two commands to update the submodules from remote locations
```
git submodule update --remote .\content\ucp\modules\*
git submodule update --remote .\content\ucp\plugins\*
```

Then run this command to change submodule folder names
```ps
.\scripts\upgrade-extension-folders.ps1
```

Then, update version.yml to reflect the new version, and go to the dll folder to update the nuspec file with the new version.

Push the updated repo to the web

### Step 2
Tag the new repo version using the `v3.0.1` semver logic.

### Step 3
Enter the ucp3-extensions-store repo locally and make a branch from the branch that is named after the current UCP3 version (3.0.0).

Name the branch with the name of the new UCP3 version (3.0.1).

Modify the recipe.yml file to set the new framework version, branch, sha, git, etc.

Commit the changes and push it to 3.0.1 of the ucp3-extensions store. A CI build should trigger and build all modules and plugins that weren't in existence yet.

### Step 4
Trigger a CI build in the UCP3 repo to generate the new release. It will overwrite the tag that is already there for 3.0.1 but since no new changes were pushed that is no issue.

The CI build takes care of downloading the right modules and plugins from the store and add it into the published zip package.

### Step 5
Enjoy!