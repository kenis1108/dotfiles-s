vim9script

def SetupSuggest()
  var options: dict<dict<any>> = {
    cmd: {
      enable: true,
      pum: true,
      exclude: [],
      onspace: ['b\%[uffer]', 'colo\%[rscheme]'],
      alwayson: true,
      popupattrs: {},
      wildignore: true,
      addons: true,
      trigger: 't',
      reverse: false,
      prefixlen: 1,
    },
    search: {
      enable: true,
      pum: true,
      fuzzy: false,
      alwayson: true,
      popupattrs: { maxheight: 12 },
      range: 100,
      timeout: 200,
      async: true,
      async_timeout: 3000,
      async_minlines: 1000,
      highlight: true,
      trigger: 't',
      prefixlen: 1,
    }
  }

  g:VimSuggestSetOptions(options)
enddef
defcompile

packadd vimsuggest
SetupSuggest()
