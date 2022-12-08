# Jenkins and Teamcity Test

hello world
this is a test file

Test scripts for learning jenkins and teamcity API.

1. *Connect to server test:* Connect to jenkins and Teamcity server
2. *Create new builds test:* Create new builds
3. *Last directory updated processing test:* If any of the directory or file inside direcory is updated or new directory is created inside target directory, create a new build with the same name as the directory name and trigger it.

**Git hooks implemented:**

1. post-commit
2. post-merge
3. pre-push

## Git Notifications

1. Copy post-commit to `.git/hooks/post-commit`
2. Make it executable  `chmod a+x .git/hooks/post-commit`

Now for every commit this script will be executed.

**NOTE:** Just adding folder wont help in above script. There has to be at least one
empty file inside the folder created, like `test_2` folder has `test.txt`. Then
only it will be available for `git add` and `git commit` commands.




