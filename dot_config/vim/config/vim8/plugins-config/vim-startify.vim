let g:ascii = [
\ [
\ '                   __                 .__                   ',
\ '          |  | __ ____   ____ |__| ______                   ',
\ '          |  |/ // __ \ /    \|  |/  ___/                   ',
\ '          |    <\  ___/|   |  \  |\___ \                    ',
\ '          |__|_ \\___  >___|  /__/____  >                   ',
\ '               \/    \/     \/        \/                    ',
\ '                         blog:http://kenis1108.github.io/   ',
\ ],
\ [
\ '                                                            ',
\ '          /$$   /$$                     /$$                 ',
\ '         | $$  /$$/                    |__/                 ',
\ '         | $$ /$$/   /$$$$$$  /$$$$$$$  /$$  /$$$$$$$       ',
\ '         | $$$$$/   /$$__  $$| $$__  $$| $$ /$$_____/       ',
\ '         | $$  $$  | $$$$$$$$| $$  \ $$| $$|  $$$$$$        ',
\ '         | $$\  $$ | $$_____/| $$  | $$| $$ \____  $$       ',
\ '         | $$ \  $$|  $$$$$$$| $$  | $$| $$ /$$$$$$$/       ',
\ '         |__/  \__/ \_______/|__/  |__/|__/|_______/        ',
\ '                                                            ',
\ '                         blog:http://kenis1108.github.io/   ',
\ ],
\ [
\ '',
\ "        .-. .-')     ('-.       .-') _          .-')         ",
\ "        \\  ( OO )  _(  OO)     ( OO ) )        ( OO ).      ",
\ "        ,--. ,--. (,------.,--./ ,--,' ,-.-') (_)---\\_)     ",
\ "        |  .'   /  |  .---'|   \\ |  |\\ |  |OO)/    _ |     ",
\ "        |      /,  |  |    |    \\|  | )|  |  \\\\  :` `.    ",
\ "        |     ' _)(|  '--. |  .     |/ |  |(_/ '..`''.)      ",
\ "        |  .   \\   |  .--' |  |\\    | ,|  |_.'.-._)   \\   ",
\ "        |  |\\   \\  |  `---.|  | \\   |(_|  |   \\       /  ",
\ "        `--' '--'  `------'`--'  `--'  `--'    `-----'       ",
\ "                                                             ",
\ "                       blog:http://kenis1108.github.io/      ",
\ ]
\ ][2]

" 动态计算最长行宽度
let s:longest_line = max(map(copy(g:ascii), 'strwidth(v:val)'))
let g:startify_padding_left = float2nr((winwidth(0) / 2) - (s:longest_line / 2) - 1)

let g:startify_files_number = 5

let g:startify_session_persistence = 1
let g:startify_session_dir = g:custom_packpath . '/session'

let g:startify_custom_header = startify#center(g:ascii)
" let g:startify_custom_header = startify#center(startify#fortune#cowsay('', '═','║','╔','╗','╝','╚'))
let g:startify_custom_footer = startify#center([printf('⏱️ Vim loaded in %.2f ms', reltimefloat(reltime(g:vim_start_time)) * 1000)])

let g:startify_commands = [
  \ {'f': ['Find File', 'Files']},
  \ {'r': ['Recent File', 'History']},
  \ ]

let g:startify_lists = [
  \ { 'type': 'commands',  'header': startify#pad(['Fzf'])          },
  \ { 'type': 'sessions',  'header': startify#pad(['Sessions'])     },
  \ { 'type': 'files',     'header': startify#pad(['Recent Files']) },
  \ ]

