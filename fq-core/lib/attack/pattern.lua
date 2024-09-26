local pattern = {}

pattern.parametric_curve = function(args)
    local domain = args.domain or error("Missing argument: interval")
    local nsteps = args.nsteps or error("Missing argument: nsteps")
    local f = args.f or error("Missing argument: f")

    local t0, t1 = table.unpack(domain)
    local result = {}
    local dt = (t1 - t0) / nsteps
    for i=1,nsteps do
        result[#result+1] = f(t0 + i*dt)
    end
    return result
end

pattern.circle = function(args)
    local radius = args.radius or error("Missing argument: radius")
    local count = args.count or error("Missing argument: count")
    return pattern.parametric_curve{
        domain = {0, 2*math.pi},
        nsteps = count,
        f = function(t) return {radius*math.cos(t), radius*math.sin(t)} end
    }
end

return pattern