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
        template_path = vim.fn.expand(template_path)
        if vim.fn.filereadable(template_path) ~= 1 then
            vim.notify('Template file does not exist: ' .. template_path, vim.log.levels.WARN)
            return
        end

        vim.cmd('0r ' .. vim.fn.fnameescape(template_path))
    end

    local function load_template_with_fzf(template_dir)
        if not template_dir or template_dir == '' then
            vim.notify('Template directory is not configured', vim.log.levels.WARN)
            return
        end

        template_dir = vim.fn.expand(template_dir)
        if vim.fn.isdirectory(template_dir) ~= 1 then
            vim.notify('Template directory does not exist: ' .. template_dir, vim.log.levels.WARN)
            return
        end

        local fzf_command = 'ls -1 ' .. vim.fn.shellescape(template_dir)

        vim.call('fzf#run', vim.fn['fzf#wrap']({
            source = fzf_command,
            sink = function(selected_template)
                local selection = selected_template
                if type(selected_template) == 'table' then
                    selection = selected_template[2] or selected_template[1]
                end

                if not selection or selection == '' then
                    vim.notify('Template selection cancelled', vim.log.levels.INFO)
                    return
                end

                local template_file = template_dir .. '/' .. selection
                read_template_into_buffer(template_file)
            end,
            options = {'--prompt', 'Select a template: '}
        }))
    end

    local function create_or_open_template(template_type)
        if not template_type or template_type == '' then
            vim.notify('Please provide a template type, e.g. :LoadTemplate ccls', vim.log.levels.WARN)
            return
        end

        local file_path = M.config.file_paths[template_type]
        if not file_path then
            vim.notify('No file path configured for template type: ' .. template_type, vim.log.levels.WARN)
            return
        end

        local filepath = vim.fn.expand(vim.fn.getcwd() .. '/' .. file_path)

        if vim.fn.filereadable(filepath) == 1 then
            print('File already exists: ' .. filepath)
            vim.cmd('tabe ' .. vim.fn.fnameescape(filepath))
        else
            vim.cmd('tabe ' .. vim.fn.fnameescape(filepath))
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
