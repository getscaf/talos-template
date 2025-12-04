# issue log
1. after `./scaf <appname> <template>` it says to cd into `my_talos`, when the directory is `my-talos`
1. after tilt up, backend never finishes updating
1. while running terraform commands, if multiple json tokens in ~/.aws/sso/cache it can grab the wrong one causing auth to fail
1. initial terraform `task deploy-sandbox` fails with github error. There is no mention of running `gh` commands as prereqs.
```shell
Do you want to apply this plan? Type 'yes' to confirm: yes
aws_iam_role.github_oidc_role: Creating...
aws_iam_role.github_oidc_role: Creation complete after 1s [id=my_talos-github-oidc-role]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
task: [set-github-variables] gh variable set AWS_REGION --body "us-east-1"
To get started with GitHub CLI, please run:  gh auth login
Alternatively, populate the GH_TOKEN environment variable with a GitHub API authentication token.
task: Failed to run task "deploy-sandbox": task: Failed to run task "deploy-environment": task: Failed to run task "set-github-variables": exit status
```
1. there needs to be mention that the github repo needs to exist before running terraform commands
1. public/private key variables apart of talos option when it looks like they should be k3s option
1. need to mention that whatever domain is used, that the registrar needs to have AWS Route 53 as the primary dns servers so AWS certificate validation works
1. after AWS resources are deployed it immediately tries to bootstrap the cluster, but talosctl fails because `bootstrap-cluster/sandbox/.env` is not loaded (and looks to be the wrong syntax?). This command `talosctl gen config {{.ENV.CLUSTER_NAME}} {{.ENV.CONTROL_PLANE_ENDPOINT}}` is the one that fails
1. `bootstrap-cluster/sandbox/.env` has suspect content. ":" instead of "=" 
1. Multiple runs of `task deploy-sandbox` cause issues with AWS secret creation
1. Command `task teardown-sandbox` errors out
```shell
Checking repository: my-talos-sandbox-backend
No images to delete in my-talos-sandbox-backend.
Tearing down the sandbox environment...
task: Failed to run task "teardown-sandbox": task: Failed to run task "teardown-environment": task: Task "bootstrap-cluster:k3s:delete-all-secrets" does not exist
```
1. subsequent runs of  `task deploy-sandbox` can fail on `commit-changes` if there are no files that have changed
1. must run `export ENV=sandbox` prior to `task deploy-sandbox` so `bootstrap-cluster/sandbox/.env` values are correctly sourced, otherwise talos config tails because `.env` values are not present so argument mismatch (expects 2, 0 provided) errors appear



# commands
```shell
aws ec2 describe-instances --region us-east-1 \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table

aws ec2 get-console-output --output text --latest --instance-id <id>

nc -vz 54.162.171.160 50000
nc -vuz 54.162.171.160 50000
```