local post = {}

--- Logs the number of entities in the chosen `scope`.
--- 
--- Useful for debugging.
---@param args {scope: string}
---@return PostLogEntityCount
function post.log_entity_count(args)
    return {
        atype = "post-log-entity-count",
        scope = args.scope
    }
end

--- Redirects projectiles from the chosen `scope` towards the attack position.
---@param args {scope: string}
---@return PostRedirect
function post.redirect(args)
    return {
        atype = "post-redirect",
        scope = args.scope
    }
end

--- Removes all entities from the chosen `scope`.
--- 
--- The entities are not actually deleted from the game, just from the scope.
---@param args {scope: string}
---@return PostClearScope
function post.clear(args)
    return {
        atype = "post-clear-scope",
        scope = args.scope
    }
end

return post