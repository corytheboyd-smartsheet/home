# ~ Sweet ~

Tracking changes to scripts in my `~`, such as `~/.zshrc`.

The `.gitigore` excludes all files recursively, so anything you want to track needs to be added with a negation. For example, `!.zshrc`.

It's also common to have a global `~/.gitignore`, which obviously conflicts with this one. To get around that, just rename it to `~/.gitignore.global` and then tell git about it:

```
git config --global core.excludesfile ~/.gitignore.global
```

