# Notes

## Use as a Git submodule

Add this repository as a submodule:

```sh
git submodule add -b main git@github.com:victorliu-sq/notes.git notes
```

Remove the submodule:

```sh
git submodule deinit -f notes
git rm -f notes # remove notes from .gitmodules and from directory
rm -rf .git/modules/notes # this will prevent re-add
```

Sync the submodule with the latest `main`:

```sh
git submodule update --remote --merge notes
```
