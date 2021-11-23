# Deprecated

Checkout native feature: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository

#### Setup

1. Deploy to heroku
1. Setup the developer applications at github https://github.com/settings/applications/new
1. Config the heroku ENV of the following:
    - GITHUB_CLIENT_ID
    - GITHUB_SECRET
    - GITHUB_REDIRECT_URI
    - GITHUB_WEBHOOK_PATH
    - GITHUB_WEBHOOK_SECRET
    - APP_SECRET
1. Add webhook to your repos https://github.com/{user}/{repos}/settings/hooks/new

======================================================

#### Usage

- webhook-url: {HOST}/{GITHUB_WEBHOOK_PATH}
- webhook-secret: GITHUB_WEBHOOK_SECRET


1. Register repos with OAuth at browser by visiting the following link
  - {HOST}/api/listenpr?repo={full-repo-name}
  - example: {HOST}/api/listenpr?repo=Steven-Chan/github-hook
2. Set the body to be append at Pull-Request
  - cat {path-to-file} | curl --data-binary @- -X PATCH {HOST}/api/listenpr?repo={full-repo-name}
3. No 3, it's Done.


#### Admin
__Check your registration__

{HOST}/admin/checklist?secret={APP_SECRET}

__Remove registration__

{HOST}/test/delete?repo={name}
