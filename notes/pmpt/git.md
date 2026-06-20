add RTTC repo as a submodule in apps/, tracking its main branch
```bash
git submodule add -b main git@github.com:victorliu-sq/RTTC.git apps/RTTC
```

How to let Clion watch the submodule:
```
1.
Open Settings/Preferences
2.
Go to Version Control
Go to Directory Mapping
3.
Add a new Git root:
```

How to check status of the submodule
```bash
git -C apps/RTTC status
```

`-C <path>` tells Git: “Before running the Git command, change directory to this path.”

How to update submodule to its latest version
```bash
git -C "${ROOT_DIR}" submodule update --init --recursive --remote --merge -- "${SUBMODULE_PATH}"
```

prompt to update submodule script to accept one argument
```bash
update @thisFile s.t. user can provide one path by themselves and if no path is provided then it will just use empty which is for all by default. we can use a flag -s + submodule path and when we hit -s, it can autocomplete to select path
```

how to remove a submodule
```bash
git submodule deinit -f dep_setup
git rm -f dep_setup
rm -rf .git/modules/dep_setup
git commit -m "Remove dep_setup submodule"
```

submodule update error: unrelated histories
```text
fatal: refusing to merge unrelated histories
fatal: Unable to merge '<commit>' in submodule path 'apps/LibRTS'
```

Reason: the submodule local branch and `origin/main` have different histories, and update uses `--remote --merge`.

Simple fix: reset the submodule to remote main, then commit the parent pointer.
```bash
git -C apps/LibRTS fetch origin
git -C apps/LibRTS reset --hard origin/main
git add apps/LibRTS
git commit -m "Update LibRTS submodule"
```

Command to redirect an existing submodule to another repo
```bash
git config -f .gitmodules submodule.submodules/owl.url git@github.com:victorliu-sq/tetmesh-owl.git
git config -f .gitmodules submodule.submodules/owl.branch main
git submodule sync submodules/owl

git -C submodules/owl remote set-url origin git@github.com:victorliu-sq/tetmesh-owl.git
git -C submodules/owl fetch origin main

cd submodules/owl
git switch -C main origin/main
git add owl/ll/Device.cpp owl/ll/UserGeomGroup.cpp owl/include/owl/common/owl-common.h
git commit -m "Make OWL build with OptiX 8 and CUDA 13"
git push -u origin main
```

# Submodules

## Add one submodule to `notes`.

```bash
git submodule add -b main git@github.com:victorliu-sq/notes.git notes 
# Create .gitmodules and clone notes 
git add .gitmodules notes # Optionally
```

## Remove the `notes` submodule completely.

```bash
git submodule deinit -f notes
git rm -f notes # remove notes from .gitmodules and from directory
rm -rf .git/modules/notes # this will prevent re-add
```

## Update changes
```sh
git pull --recurse-submodules # powerful ennough

git submodule update --init --recursive --remote # even more powerful
```

```sh
git pull --recurse-submodules # powerful ennough
```
It performs a standard git pull on your main repository and then automatically runs git submodule update.
It updates submodules to the specific commit hashes recorded in the main repository’s history.

```sh
git submodule update --init --recursive --remote # even more powerful
```
This command fetches the latest independent changes from the submodules, even if the main project hasn't "pinned" them yet.

`--remote`: This is the key flag. It tells Git to check the remote tracking branch of each submodule (often master or main) for new commits.
