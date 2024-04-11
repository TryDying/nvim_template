command! -nargs=* LoadTemplate lua require("template.init").load_template(<q-args>)
