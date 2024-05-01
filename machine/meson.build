project('v6502-msbasic', 'cpp',
  version : '0.1',
  default_options : ['warning_level=3',
                     'cpp_std=c++23'])

v6502_dep = subproject('v6502').get_variable('v6502_dep')

exe = executable(
  'v6502-msbasic', 'machine.cpp',
  dependencies: v6502_dep,
  install: true
)
