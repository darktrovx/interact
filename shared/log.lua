local settings = require 'shared.settings'

return {
    debug = function(self, message, ...)
        if not settings.Debug then return end

        print(('[%s] %s'):format('DEBUG', message:format(...)))
    end,
    error = function(self, message, ...)
        print(('[%s] %s'):format('ERROR', message:format(...)))
    end
}