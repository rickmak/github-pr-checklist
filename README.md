Setup Step

1. Deploy to heroku
1. Setup the developer applications at github https://github.com/settings/applications/new
1. Add webhook to your repos https://github.com/{user}/{repos}/settings/hooks/new

======================================================

Usage

- webhook-url: {host}/github-web-hook
- webhook-secret: oursky


1. register (with browser)
	- /api/listenpr?repo={full-repo-name}
	- example: {host}/api/listenpr?repo=Steven-Chan/github-hook
2. set appending body
	- cat {path-to-file} | curl --data-binary @- -X PATCH {host}/api/listenpr?repo={full-repo-name}
3. no 3


# to check your registration
{host}/test/see_all_client

# to reset all registration
{host}/test/reset