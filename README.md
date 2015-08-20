Vizardry
============

Remember back in the dark ages of 2013? When you had to search for vim plugins like a wild animal, using your browser?

In 2014, you can just type ":Invoke &lt;keyword&gt;" and Vizardry will automatically search github for the plugin you want and install it for you.

In 2015 you can even upgrade plugins from any git repo or vim.org using [:Evolve](#evolve).


## <a name="Fork">Why this fork ?</a>

This fork add several nice features to the [original Vizardry plugin from ardagnir](https://github.com/ardagnir/Vizardry):

+ `Vanish` command to actually remove a plugin.
+ `Evolve` command to upgrade one or every plugins see [Evolve](#evolve).
+ Good submodule handling for people having their vim config in a git repo
see [submodules](#submodules)).
+ Retrieve the README.md file while using `:Invoke`.
+ Navigate through search results with `:Invoke`
+ Set the length of `Scry` results list.
+ Search script written by specific user with `:Scry` and `:Invoke`
+ Automatically call `:Helptags` every time a plugin is Invoked.

**Note:** Since v1.1, `VizardrySortScryResults` is replaced by VizardrySearchOptions
### <a name="submodules">How to use Vizardry with submodules ?</a>

Set the following variables in your vimrc:

    let g:VizardryGitMethod="submodule add"
    let g:VizardryGitBaseDir="/path/to/your/git/repo"

The second variable **must be** the root of the repo containing your vim
files.

Optionally you can set the vim commit messages (the name of the modified
plugin will always be happened in the end of the message, the proposed values
are the defaults):

    let g:VizardryCommitMsgs={'Invoke': "[Vizardry] Invoked vim submodule:",
          \'Banish': "[Vizardry] Banished vim submodule:",
          \'Vanish': "[Vizardry] Vanished vim submodule:",
          \'Evolve': "[Vizardry] Evolved vim submodule:",
          \}

Each time you `:Invoke`, `:Bannish` or `:Vanish` a module, the submodule will be correctly
updated and a minimal commit will be created.

#### Note:

+ Commits created by Vizardry are not automatically pushed.
+ The `.gitmodule` is included in each commit, do not use `:Invoke`, `:Bannish`
or `:Vanish` if it contains some bad modifications.


## Commands

+   :Scry [&lt;query&gt;]

    + If no <query> is given, list all invoked and banished plugins.
    + If a <query> is specified (see below), search github for a
    script matching <query> in title or readme and list N first results.

    The number of results displayed can be configured by adding the following
    to your vimrc:

        let g:VizardryNbScryResults = 25

    Default is 10.

    A `<query>` can be:

    + One or several `<keywords>`
    + A query matching the github 
    [search api](https://developer.github.com/v3/search/#search-repositories)
    + `-u <user>` (search every repositories of `<user>` matching 'vim'
    + One or several `<keywords>` and `-u <user>` (in any order)

    It is possible to set some github search option in your vimrc, default
    options are show forked repositories and sort by stars. These option can
    be overwritten. For instance adding the following to your vimrc will make
    vizardry show results sorted by number of stars hidding forked
    repositries.

        let g:VizardrySortOptions="fork:false+sort:stars"

    Any combination of github option can be used, a `+` must appear between
    each options. For the sort option, available parameters are `stars`,
    `forks`, `updated`, by default, it show the best match.

+   :Invoke [&lt;query&gt;|N]

    + If no arguments is specified, reload your plugins.
    + If the argument is a number, ask to install the plugin with that
        number from the last `:Scry` or Invoke.
    + If the argument is a `<query>`, search github for a plugin matching
    `<query>` (see above)  and ask for install, the sort criteria for
    search results can be configured (see above).

Suppose you're in the middle of vimming and you have a sudden need to surround
random words in "scare quotes". You can't remember who made the surround
plugin, or whether it's called surround.vim, vim-surround or
vim-surround-plugin. Most importantly, you're lazy.


    Just type:

        :Invoke surround

    Vizardry will pop up a prompt saying:

        Result 1/20: tpope/vim-surround
        (surround.vim: quoting/parenthesizing made simple)

        Clone as "surround"? (Yes/Rename/DisplayMore/Next/Previous/Abort)

    Press Y and you can immediately start surrounding things.  You can also take a
    look at the README.md directly in vim by hitting 'd', Go to the next or
    previous script with 'n' and 'p' or abort 'a'. It's that easy.

    To view the readme, an other instance of vim is called, the command line can
    be configured:

        let g:VizardryReadmeReader='view -c "set ft=markdown" -'


    Even plugins with vague or silly names can be found with Vizardry. Imagine
    you're running multiple instances of vim and need a package to sync registers.

    Type:

        :Invoke sync registers

    Vizardry will prompt you with:

        Result 1/3: ardagnir/united-front
        (Automatically syncs registers between vim instances)

        Clone as "syncregisters"? (Yes/Rename/DisplayMore/Next/Previous/Abort)

    Just as easy.



+   :Banish &lt;keyword&gt;

    Banish a plugin, this only forbid pathogen to load it and does not remove
    the files. You need to restart vim to see the effects.

+   :Unbanish &lt;keyword&gt;

    Reverse a banish.

+   :Vanish &lt;keyword&gt;

    Remove definitively a plugin's files.

+   <a name="evolve">:Evolve  [&lt;keyword&gt;]</a>

    Upgrade the plugin matching &lt;keyword&gt;. If no &lt;keyword&gt; is given, upgrade
    all possible plugins.

    The plugins downloaded from github are upgraded by doing:

        git pull origin master

    `:Evolve` is also able to upgrade plugin downloaded from vim.org, to do so,
    you need to create a `.metainfos` file at the root of the plugin directory
    (not yout bundle directory). Such a file is composed of two lines:

    1. the vimscript url (at vim.org)
    2. The current version number (0 for initialization)

    **Note:**

    +   `atool` is required for upgrading scripts from vim.org, see
        [Requirements](#requirements).
    +   Although this functionality works fine, it is recommended to always
        install plugins by cloning a repository. To install plugin found at
        vim.org by from github use:

            :Invoke -u vim-scripts <plugin-name>

        Were &lt;plugin-name&gt; is the actual name of the plugin at vim.org

        You can also search a plugin by vim.org id:

            :Invoke -u vim-scripts in:readme script_id=<id>

## Requirements
- Vizardry requires [pathogen](https://github.com/tpope/vim-pathogen). But you already have pathogen installed, don't you?

- It also needs curl, as well as commandline programs that come with most \*nix systems.

+ [atool](http://freecode.com/projects/atool) is required for upgrading scripts from vim.org.

- You will probably have issues if you use a Windows OS.

## Installation

Use pathogen.

    cd ~/.vim/bundle
    git clone https://github.com/dbeniamine/vizardry

##License

Vizardry is licensed under the AGPL v3
