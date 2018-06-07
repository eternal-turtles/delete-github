# delete github

Would you like to delete all your GitHub repositories without deleting your account?

Once you've migrated your repositories someplace else, navigate to https://github.com/settings/tokens and generate an access token with the `delete_repo` scope. If you'd like to delete your private repositories, select the `repo` scope as well.

Then run the ruby script with environment variables `GITHUB_USER` and `GITHUB_TOKEN`.
