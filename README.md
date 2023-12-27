# sycamore-end-tags.nvim

Small plugin to add virtual text as pseudo "closing tags" for Sycamore's HTML functions to help keep track of which curly brace goes to what HTML function.

![sycamore end tags](https://i.imgur.com/bI2Via1.png)

## Setup
Lazy
```
{
	"noxxxxxious/sycamore-end-tags.nvim",
	opts = {}
}
```

### Disclaimer
This is my first foray into Lua and Neovim plugins, as well as my first attempt at Treesitter queries. Feel free to let me know of anything that could be done better!

The Treesitter query can probably be changed to also capture other things inside the `view` macro. Any adjustments to this are very welcome!
