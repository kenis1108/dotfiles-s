vim9script

def SetupLsp()
  packadd lsp

  var lspServers = [
    {
      name: 'vimls',
      filetype: ['vim'],
      path: 'vim-language-server',
      args: ['--stdio']
    },
    # {
    #   name: 'tsserver',
    #   filetype: ['javascript', 'typescript'],
    #   path: 'typescript-language-server',
    #   args: ['--stdio']
    # },
    # {
    #   name: 'pyright',
    #   filetype: 'python',
    #   path: 'pyright-langserver',
    #   args: ['--stdio'],
    #   workspaceConfig: {
    #     python: {
    #       pythonPath: '/usr/bin/python3.10'
    #     }
    #   }
    # },
    {
      name: 'gopls',
      filetype: 'go',
      path: 'gopls',
      args: ['serve'],
      workspaceConfig: {
        gopls: {
          hints: {
            assignVariableTypes: true,
            compositeLiteralFields: true,
            compositeLiteralTypes: true,
            constantValues: true,
            functionTypeParameters: true,
            parameterNames: true,
            rangeVariableTypes: true
          }
        }
      }
    },
    # {
    #   name: 'nil',
    #   filetype: 'nix',
    #   path: 'nil'
    # },
    {
      name: 'nixd',
      filetype: 'nix',
      path: 'nixd'
    },
    # {
    #   name: 'rustanalyzer',
    #   filetype: ['rust'],
    #   path: 'rust-analyzer',
    #   args: [],
    #   syncInit: true,
    #   initializationOptions: {
    #     inlayHints: {
    #       typeHints: {
    #         enable: true
    #       },
    #       parameterHints: {
    #         enable: true
    #       }
    #     }
    #   }
    # }
  ]

  g:LspAddServer(lspServers)
enddef
defcompile

SetupLsp()
