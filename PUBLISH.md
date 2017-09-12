# Publishing an updated Podspec

First: **Update code, test it works**

  * Update the `Intilery.podspec` file
  * Commit and Push all changes
  * Tag the repository `git tag -a v1.0.0 -m "Release 1.0.0"`
  * Push the tag `git push --follow-tags`
  * Create a release from the tag on GitHub
  * Check for any errors with `pod spec lint` (possibly with `--allow-warnings`)
  * Push the changes `pod trunk push`

