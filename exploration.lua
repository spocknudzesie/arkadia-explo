scripts.explo = scripts.explo or {
    pluginName = 'arkadia-explo',
    categories = {
        ['o chaosie i jego tworach'] = 'Chaos i jego twory',
        ['o goblinoidach'] = 'goblinoidy',
        ['o golemach'] = 'golemy',
        ['o istotach demonicznych'] = 'istoty demoniczne',
        ['o jaszczuroludziach'] = 'jaszczuroludzie',
        ['o magii i jej tworach'] = 'magia i jej twory',
        ['o nieumarlych'] = 'nieumarli',
        ['o pajakach i pajakowatych'] = 'pajaki i pajakowate',
        ['o ryboludziach'] = 'ryboludzie',
        ['o smokach i smokowatych'] = 'smoki i smokowate',
        ['o starszych rasach'] = 'starsze rasy',
        ['o stworach pokoniunkcyjnych'] = 'stwory pokoniunkcyjne',
        ['o szczuroludziach'] = 'szczuroludzie',
        ['o wampirach'] = 'wampiry'
    }
}


table.contains = table.contains or function(table, element)
    for i, value in pairs(table) do
      if value == element then
        return i
      end
    end
    return false
end


function scripts.explo:msg(col, msg, ...)
    local message = string.format(msg, unpack(arg))
    hecho(string.format("[%sWIEDZA#r] %s\n", col, message))
end


function scripts.explo:ok(str, ...)
    return self:msg('#00ff00', str, unpack(arg))
end


function scripts.explo:err(str, ...)
    return self:msg('#ff0000', str, unpack(arg))
end


function scripts.explo:getFileName(category)
    return string.format("%s/plugins/%s/wiedza-%s.txt", getMudletHomeDir(), self.pluginName, category)
end


function scripts.explo:readList(category)
    local filename = self:getFileName(category)
    local data
    if not io.exists(filename) then
        self:err("Lista dla kategorii %S nie istnieje.", category)
        return
    end
    local f = io.open(filename, 'r')
    io.input(f)
    data = string.split(io.read('*a'), '\n')
    io.close(f)
    return data
end


function scripts.explo:printCategory(cat)
    local count = characterLore[cat]
    local proc = count.done / count.max
    local barLength = proc * 10
    hechoLink(string.format("[%3d/%3d]%-10s|", count.done, count.max,  string.rep('=', barLength)),
        function()
            scripts.explo:cmdExplo(cat, true)
        end,
    "pokaz szczegoly wiedzy o " .. cat, true)
    hecho(" wiedza " .. cat .. "\n")

    return {
        done = count.done,
        max = count.max
    }
end


function scripts.explo:cmdExplo(topic, hideKnown)
    local eventFireups = 1
    local i = 0
    topic = topic:trim()

    if topic:find('reset') then
        local lore = topic:match('reset (.+)')
        if lore then
            if self.categories[lore] then
                self:err("Eksploracja w kategorii %s zresetowana.", self.categories[lore])
                characterLore[lore] = nil
            else
                self:err("Brak kategorii wiedzy '%s'", lore)
            end
        else
            self:err("Eksploracja dla biezacej postaci zresetowana.")
            characterLore = nil
        end
        return
    end

    if topic == 'pomoc' then
        self:ok('Komendy do obslugi wiedzy z eksploracji:')
        self:ok('- /eksplo reset [temat] - resetuje dane o eksploracji [na dany temat] dla biezacej postaci')
        self:ok('- /eksplo [temat] - za pierwszym razem pobiera dane o wiedzy na dany [temat] dla biezacej postaci, pozniej wyswietla')
        self:ok('Klikniecie w pasek postepu eksploracji wyswietla szczegoly.')
        return
    end

    if not topic or topic == '' then
        if not characterLore or #table.keys(characterLore) == 0 then
            for cat, shortCat in pairs(self.categories) do
                tempTimer(0.5 * i, function()
                    scripts.explo:cmdExplo(cat)
                end)
                i = i + 1
            end
        else
            local done = 0
            local max = 0
            local progress = (max-done)/3
            self:ok("Twoja zebrana wiedza z eksploracji")
            self:ok('Klikniecie w pasek postepu eksploracji wyswietla szczegoly.')
            for cat, count in pairs(characterLore) do
                local res = self:printCategory(cat)
                done = done + res.done
                max = max + res.max
            end
            progress = (max-done)/3
            local niebotki = progress/16
            self:ok("Z eksploracji mozesz zrobic jeszcze %d postepow (czyli %d niebotow) wiec chyba warto!", progress, niebotki)
            return
        end
    else
        send('wiedza ' .. topic)
    end

    if self.messageEvent then killAnonymousEventHandler(self.messageEvent) end
    self.messageEvent = registerAnonymousEventHandler('incomingMessage', function(event, t, msg)
        -- print(dump_table({event=event, msg=msg, t=t}, true))
        if t ~= 'other' then return false end
        return self:processKnownLore(ansi2string(msg), hideKnown)
    end, 1)
end


function scripts.explo:processKnownLore(msg, hideKnown)
    local lines = string.split(msg, '\n')
    local category = lines[1]:match('Wiedza (o .+):')
    local shortCategory
    local _explored
    local explored = {}
    local availableLore
    local maxLore
    local myLore

    if not characterLore then
        characterLore = {}
    end

    shortCategory = self.categories[category]
    for i, line in ipairs(lines) do
        if line == "Szczegoly eksploracji:" then
            _explored = table.sub(lines, i+1)
        end
    end

    for _, line in ipairs(_explored) do
        local l = line
        l = l:sub(4, -2):gsub('las,', 'les,'):gsub('las ', 'les ')
        if string.len(l) > 1 then
            table.insert(explored, l)
        end
    end

    availableLore = self:readList(category)
    maxLore = #availableLore
    myLore = #explored
    -- print(dump_table(explored, true))

    for i, lore in ipairs(availableLore) do
        if table.contains(explored, lore) then
            if not hideKnown then
                hecho(string.format("#eeeeee(+) %s\n", lore))
            end
        elseif string.len(lore) > 1 then
            hecho(string.format("#666666        - %s.\n", lore))
        end
    end
    self:ok("Wiedza z eksploracji: %d/%d.", myLore, maxLore)
    characterLore[category] = {
        desc = string.format("%3d/%3d", myLore, maxLore),
        done = myLore,
        max = maxLore
    }

    -- print(dump_table(explored, true))
    return true
end

scripts.explo:ok("Plugin zaladowany! Uzyj komendy /eksplo pomoc.")
scripts.plugins_update_check:github_check_version('arkadia-explo', 'spocknudzesie')
