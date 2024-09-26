local post = {}

function post.log_entity_count(args)
    return {
        atype = "post-log-entity-count",
        scope = args.scope or "."
    }
end

return post