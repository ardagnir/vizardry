Vizardry
============

Remember back in the dark ages of 2013? When you had to search for vim plugins like a wild animal, using your browser?

In 2014, you can just type ":Invoke &lt;keyword&gt;" and vizardry will automatically search github for the plugin you want and install it for you.

In 2015 you can even upgrade plugins from any git repo or vim.org using [:Upgrade](https://github.com/dbeniamine/vizardry#upgrade).


## <a name="Fork">Why this fork ?</a>

This fork add several nice features to the [original vizardry plugin from ardagnir](https://github.com/ardagnir/vizardry):

+ `Destruct` command to actually remove a plugin.
+ `Upgrade` command to upgrade one or every plugins see [upgrade](https://github.com/dbeniamine/vizardry#upgrade).
+ Good submodule handeling for people having their vim config in a git repo
see [submodules](https://github.com/dbeniamine/vizardry#submodules)).
+ Retrieve the README.md file while using `:Invoke`
+ Set the lenght of `Scry` results list.
+ `:Helptags` is automatically called every time a sumodule is Invoked.

### <a name="submodules">How to use vizardry with submodules ?</a>

Set the following variables in your vimrc:

    let g:VizardryGitMethod="submodule add"
    let g:VizardryGitBaseDir="/path/to/your/git/repo"

The second variable ** must be** the root of the repo containing your vim
files.

Optionnaly you can set the vim commit messages (the name of the modified
plugin will always be happened in the end of the message, the proposed values
are the defaults):

    let g:VizardryCommitMsgs={'Invoke': "[Vizardry] Invoked vim submodule:",
          \'Banish': "[Vizardry] Banished vim submodule:",
          \'Destruct': "[Vizardry] Destructed vim submodule:",
          \'Upgrade': "[Vizardry] Upgraded vim submodule:",
          \}

Each time you `Invoke` are `Bannish` a module, the submodule will be correctly
updated and a minimal commit will be created.

#### Note:

+ Commits created by Vizardry are not automatically pushed.
+ The `.gitmodule` is included in each commit, do not use `Invoke` or `Bannish` if it contains some bad modifications.

##Basic Usage
- Type :<b>Invoke</b> with no keywords to reload your plugins.
- Type :<b>Invoke</b> &lt;keyword&gt; and hit yes to install a plugin and reload.
- Type :<b>Banish</b> &lt;samekeyword&gt; to remove that plugin from pathogen. You will have to restart vim to see the effect.
- Type :<b>Destruct</b> &lt;samekeyword&gt; to remove definitively that plugin files.
- Type :<b>Upgrade</b>  \[samekeyword\] to upgrade one or every plugns see [upgrade](https://github.com/dbeniamine/vizardry#upgrade).

##Additional Usage
- Type :<b>Unbanish</b> &lt;keyword&gt; to reverse a banish.
- Type :<b>Scry</b> with no keywards to list all invoked and banished plugins.
- Type :<b>Scry</b> &lt;keyword&gt; to search github for a script and output 
top N results. The number of displayed results can be set by adding `let g:VizardryNbScryResults=25` to your vimrc. Default is 10.
- Type :<b>Invoke</b> &lt;number&gt; to install the plugin with that number from the last scry.
- Type :<b>Magic</b> to manage global and plugin-specific settings. See [Magic](https://github.com/dbeniamine/vizardry#magic) below.


##Examples
Suppose you're in the middle of vimming and you have a sudden need to surround random words in "scare quotes". You can't remember who made the surround plugin, or whether it's called surround.vim, vim-surround or vim-surround-plugin. Most importantly, you're lazy.

Just type:

    :Invoke surround

Vizardry will pop up a prompt saying:

    Found tpope/vim-surround
    (surround.vim: quoting/parenthesizing made simple)

    Clone as "surround"? (Yes/No/Rename/DisplayMore)

Press Y and you can immediately start surrounding things.  You can also take a
look at the README.md directly in vim by hitting 'd'.  It's that easy.


Even plugins with vague or silly names can be found with vizardry. Imagine you're running multiple instances of vim and need a package to sync registers.

Type:

    :Invoke sync registers

Vizardry will prompt you with:

    Found ardagnir/united-front
    (Automatically syncs registers between vim instances)

    Clone as "syncregisters"? (Yes/No/Rename)

Just as easy.

## Upgrade

The ugrade function is able to upgrade any plugin instaled from a git
repository or vim.org.

To upgrade plugins from vim.org, you need to add a metainfos file.
A metainfos file contains two lines
1. The url of the vimscript
2. The version number (0 to initialize the synchronization)

**Note:** `atool` is required for upgrading sripts from vim.org

##Magic
  Too many globals and settings for each plugin? Vizardry stores a set of magic files that can keep track of these for you.

- Type :<b>Magic</b> * &lt;magic words&gt; and add thse words to a file that acts similarly to your vimrc.
- Type :<b>Magic</b> &lt;plugin&gt; &lt;magic words&gt; to add plugin-specific globals and settings. These are only used when that plugin isn't banished.
- Type :<b>Magic{edit/split/vsplit}</b> &lt;plugin&gt; to edit/split/vsplit the magic file for that plugin.


##Requirements
- Vizardry requires [pathogen](https://github.com/tpope/vim-pathogen). But you already have pathogen installed, don't you?

- It also needs curl, as well as commandline programs that come with most \*nix systems.

+ [pandoc](http://pandoc.org/) is recommended to display README.md files.

+ [atool](http://freecode.com/projects/atool) is required for upgrading sripts from vim.org.

- You will probably have issues if you use a Windows OS.

##Installation
Use pathogen.

    cd ~/.vim/bundle
    git clone https://github.com/dbeniamine/vizardry

##Notes
- Vizardry banishes plugins by adding a tilde to the end of their directory
  name. This stops pathogen from reading them. If you want to remove packages
  completly, you must use the `Destruct` command.
- Vizardry finds the matching plugin with the highest star rating on github. This is usually, but not always, the one you want, so pay attention. Remember that you can use scry to find more results.
- If you want to use submodules instead of cloning, see See [submodules](https://github.com/dbeniamine/vizardry#submodules) above

##License
Vizardry is licensed under the AGPL v3
