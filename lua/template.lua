local M = {}

local default_config = {
    template_dirs = {
        fake = 'templates/fake',
    },
    file_paths = {
        fake = 'fake.ex',
    },
}
M.config = default_config



local function setup_template_loader()

    local function read_template_into_buffer(template_path)
        vim.cmd('0r ' .. template_path)
    end

    local function load_template_with_fzf(template_dir)
        template_dir = vim.fn.expand(template_dir)
        local fzf_command = 'ls -1 ' .. template_dir

        vim.call('fzf#run', vim.fn['fzf#wrap']({
            source = fzf_command,
            sink = function(selected_template)
                if selected_template then
                    local template_file = template_dir .. '/' .. selected_template
                    read_template_into_buffer(template_file)
                end
            end,
            options = {'--prompt', 'Select a template: ', '--expect', 'enter'}
        }))
    end

    local function create_or_open_template(template_type)
        local filepath = vim.fn.expand(vim.fn.getcwd() .. '/' .. M.config.file_paths[template_type])

        if vim.fn.filereadable(filepath) == 1 then
            print('File already exists: ' .. filepath)
            vim.cmd('tabe ' .. filepath)
        else
            vim.cmd('tabe ' .. filepath)
            load_template_with_fzf(M.config.template_dirs[template_type])
        end
    end


    local function load_template(template_type)
        create_or_open_template(template_type)
    end

    return load_template
end

M.load_template = setup_template_loader()

function M.setup(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})

    vim.api.nvim_create_user_command(
        'LoadTemplate',
        function(opts)
            M.load_template(opts.args)
        end,
        {nargs = "*"}
    )
end

return M
