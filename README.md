
# USAGE

1, prepare the repo script

```
$ mkdir -p ~/.bin
$ curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo -o ~/.bin/repo
$ chmod a+rx ~/.bin/repo
$ export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo' 
$ export PATH="${HOME}/.bin:${PATH}"
```

2, initialize repo manifest in the directory where you want to checkout the git repos (in this case in the created yocto dir) with the repo init command:

```
$ mkdir yocto
$ cd yocto
$ repo init -u https://github.com/systemd-learning/experiments-manifest.git
```

3, Finally, to checkout all the git repos (here poky + the various meta layers), the repo sync command shall be used:

```
$ repo sync
```

Optional:

Use the external toolchain

```

- Download the prebuilt toolchain:
wget https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz

- Add the following strings to local.conf:

TCMODE = "external-arm"
EXTERNAL_TOOLCHAIN="/PATH/TO/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu"

- Add the following strings to bblayers.conf:

BBLAYERS += " \
  /PATH/TO/meta-arm/meta-arm-toolchain \
  "

```

