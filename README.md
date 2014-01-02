Vizardry
============

Remember back in the dark ages of 2013? When you had to search for vim plugins like a wild animal, using your browser?

In 2014, you can just type ":Invoke &lt;keyword&gt;" and vizardry will automatically search github for the plugin you want and install it for you.

##Basic Usage
- Type :<b>Invoke</b> with no keywords to reload the vimrc.
- Type :<b>Invoke</b> &lt;keyword&gt; and hit yes to install a plugin and reload the vimrc.
- Type :<b>Banish</b> &lt;samekeyword&gt; to remove that plugin from pathogen. You will have to restart vim to see the effect.

##Additional Usage
- Type :<b>Scry</b> with no keywards to list all invoked and banished plugins.
- Type :<b>Scry</b> &lt;keyword&gt; to search github for a script and output the top 10 results.
- Type :<b>Invoke</b> &lt;number&gt; to download the plugin with that number from the last scry.

##Examples
Suppose you're in the middle of vimming and you have a sudden need to surround random words in scarequotes. You can't remember who made the surround plugin, or whether it's called surround.vim or vim-surround or vim-surround-plugin. More importantly, you're lazy.

Just type:

    :Invoke surround

Vizardry will pop up a prompt saying:

    Found tpope/vim-surround
    (surround.vim: quoting/parenthesizing made simple)

    Clone as "surround"? (Yes/No/Rename)

Press Y and you can immediately start surrounding things. It's that easy.
<br><br><br>
To make things worse, sometimes people are jerks and name plugins based on what they find amusing, instead of what the plugins do. Say you're running multiple instances of vim and need a package to sync registers.

Type:

    :Invoke sync registers

Vizardry will prompt you with:

    Found ardagnir/united-front
    (Automatically syncs registers between vim instances)

    Clone as "syncregisters"? (Yes/No/Rename)

Just as easy.

##Requirements
- Vizardry requires [pathogen](https://github.com/tpope/vim-pathogen). But you already have pathogen installed, don't you?

- It also needs curl, as well as commandline programs that come with most \*nix systems.

- You will probably have issues if you use Windows.


##Installation
Use pathogen.

    cd ~/.vim/bundle
    git clone https://github.com/ardagnir/vizardry

##Notes
- Vizardry banishes plugins by adding a tilde to the end of their directory name. This stops pathogen from reading them. If you want to remove packages completly, you must do it yourself.
- Invoking a banished plugin unbanishes it instead of redownloading it from github.
- Vizardry finds the matching plugin with the highest star rating on github. This is usually, but not always, the one you want, so pay attention.
- Vizardry currently has no way of updating packages. That should change soon, but until then, you'll have to update them from the shell.

##License
Vizardry is licensed under the AGPL v3
