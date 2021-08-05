
local Set = require("module.utils").Set
local sizeOfTable = require("module.utils").sizeOfTable

---Class to solve dependencies
---@class DependencySolver
---@private
local DependencySolver = {
    new = function(self, modules)
        local o = {
            modules = modules or {},
        }
        setmetatable(o, self)
        self.__index = self
        return o
    end,

    solve = function(self)
        --[[ Python pseudocode:
            '''
            Dependency resolver

        "arg" is a dependency dictionary in which
        the values are the dependencies of their respective keys.
        '''
        d=dict((k, set(arg[k])) for k in arg)
        r=[]
        while d:
            # values not in keys (items without dep)
            t=set(i for v in d.values() for i in v)-set(d.keys())
            # and keys without value (items without dep)
            t.update(k for k, v in d.items() if not v)
            # can be done right away
            r.append(t)
            # and cleaned up
            d=dict(((k, v-t) for k, v in d.items() if v))
        return r
        --]]

        local d = self.modules
        local r = {}
        while sizeOfTable(d) > 0 do
            local t1 = Set:new()
            local t2 = Set:new()
            local t3 = Set:new()
            for mod, deps in pairs(d) do
                t2:add(mod)

                if sizeOfTable(deps) == 0 then
                    t3:add(mod)
                end

                for l, dep in pairs(deps) do
                    t1:add(dep)
                end
            end
            local t = (t1:subtract(t2)):update(t3)

            table.insert(r, t.data)

            local d2 = {}
            for mod, deps in pairs(d) do
                if sizeOfTable(deps) > 0 then
                    d2[mod] = Set:new(deps):subtract(t).data
                end
            end

            d = d2
        end

        return r
    end,
}

return {
    DependencySolver = DependencySolver
}