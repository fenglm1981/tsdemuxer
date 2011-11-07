ui_vars=clone_table(http_vars)
ui_vars.return_url='/ui'

function ui_handler(args,data,ip)

    if args.action=='style' then
        http_send_headers(200,'css')
        http.sendfile(cfg.ui_path..'bootstrap-1.2.0.min.css')
        return
    end

    if args.action=='download' then
        http_send_headers(200,'m3u')
    else
        http_send_headers(200,'html')
    end

    if not args.action then
        http.sendtfile(cfg.ui_path..'ui_main.html',ui_vars)
    else
        if args.action=='upload' then

            ui_vars.return_url='/ui?action=playlist'

            local tt=util.multipart_split(data)
            data=nil

            if tt and tt[1] then
                local n,m=string.find(tt[1],'\r?\n\r?\n')

                if n then
                    local fname=string.match(string.sub(tt[1],1,n-1),'filename=\"(.+)\"')

                    if fname and string.find(fname,'.+%.m3u$') then
                        local tfname=cfg.tmp_path..fname

                        local fd=io.open(tfname,'w+')
                        if fd then
                            fd:write(string.sub(tt[1],m+1))
                            fd:close()
                        end

                        local pls=m3u.parse(tfname)

                        if pls then
                            if os.execute(string.format('mv %s %s',tfname,cfg.playlists_path..fname))~=0 then
                                os.remove(tfname)
                                http.sendtfile(cfg.ui_path..'ui_error.html',ui_vars)
                            else
                                core.sendevent('reload')
                                http.sendtfile(cfg.ui_path..'ui_ok.html',ui_vars)
                            end
                        else
                            os.remove(tfname)
                            http.sendtfile(cfg.ui_path..'ui_error.html',ui_vars)
                        end
                    else
                        http.sendtfile(cfg.ui_path..'ui_error.html',ui_vars)
                    end
                end
            end
        elseif args.action=='reload' then
            core.sendevent('reload')
            http.sendtfile(cfg.ui_path..'ui_ok.html',ui_vars)
        elseif args.action=='feeds' then
            update_feeds_async()
            http.sendtfile(cfg.ui_path..'ui_ok.html',ui_vars)
        elseif args.action=='save_config' then

            local f=io.open(cfg.config_path..'common.lua','w')
            if f then
                f:write('cfg.youtube_fmt=\'',args.youtube_q or '18','\'\ncfg.ivi_fmt=\'',args.ivi_q or 'MP4-lo','\'\ncfg.youtube_region=\'',args.youtube_r or '*','\'\n')
                f:close()
                core.sendevent('config')
            end

            http.sendtfile(cfg.ui_path..'ui_ok.html',ui_vars)
        elseif args.action=='playlist' then

            function show_playlists()
                http.send('<table>\n')
                local d=util.dir(cfg.playlists_path)
                if d then
                    table.sort(d)
                    for i,j in ipairs(d) do
                        if string.find(j,'.+%.m3u$') then
                            local fname=util.urlencode(j)
                            http.send(string.format('<tr><td><a href=\'/ui?action=show&fname=%s\'>%s</a> [<a href=\'/ui?action=remove&fname=%s\'>x</a>]</td></tr>\n',fname,j,fname))
                        end
                    end
                end
                http.send('</table>\n')
            end
   
            ui_vars.playlists=show_playlists
            http.sendtfile(cfg.ui_path..'ui_playlist.html',ui_vars)   
        elseif args.action=='playlist2' then

            function show_playlists()
                http.send('<table>\n')
                for i,j in ipairs(playlist_data.elements) do
                    http.send(string.format('<tr><td><a href=\'/ui?action=download&id=%s\'>%s</a></td></tr>\n',i,j.name))
                end
                http.send('</table>\n')
            end
   
            ui_vars.playlists=show_playlists
            http.sendtfile(cfg.ui_path..'ui_playlist.html',ui_vars)   
        elseif args.action=='show' then
            ui_vars.return_url='/ui?action=playlist'

            if not args.fname or not string.find(args.fname,'^[%w_]+%.m3u$') then
                http.sendtfile(cfg.ui_path..'ui_error.html',ui_vars)
                return
            end

            local pls=m3u.parse(cfg.playlists_path..args.fname)

            if pls then
                function show_playlist()
                    http.send('<table>\n')
                    for i,j in ipairs(pls.elements) do
                        http.send('<tr><td>'..j.name..'</td></tr>\n')
                    end
                    http.send('</table>\n')
                end

                local t=clone_table(ui_vars)
                ui_vars.playlist=show_playlist
                ui_vars.playlist_name=pls.name
                http.sendtfile(cfg.ui_path..'ui_show.html',ui_vars)
            else
                http.sendtfile(cfg.ui_path..'ui_error.html',ui_vars)
            end
        elseif args.action=='download' then
            local pls=playlist_data.elements[tonumber(args.id)]

            if pls then
                http.send('#EXTM3U\n')
                for i,j in ipairs(pls.elements) do
                    local url=j.url or ''
                    if j.path then
                        url=www_location..'/stream?s='..util.urlencode(j.objid)
                    else
                        if cfg.proxy>0 then
                            if cfg.proxy>1 or pls.mime[1]==2 then
                                url=www_location..'/proxy?s='..util.urlencode(j.objid)
                            end
                        end
                    end
                    http.send('#EXTINF:0,'..j.name..'\n'..url..'\n')
                end
            end
        elseif args.action=='remove' then
            ui_vars.return_url='/ui?action=playlist'

            if not args.fname or not string.find(args.fname,'^[%w_]+%.m3u$') then
                http.sendtfile(cfg.ui_path..'ui_error.html',ui_vars)
                return
            end

            if os.remove(cfg.playlists_path..args.fname) then
                core.sendevent('reload')
                http.sendtfile(cfg.ui_path..'ui_ok.html',ui_vars)
            else
                http.sendtfile(cfg.ui_path..'ui_error.html',ui_vars)
            end
        elseif args.action=='status' then
            function ui_show_streams()
                http.send('<table>\n')
                for i,j in pairs(childs) do
                    if j.status then
                        http.send(string.format('<tr><td>%s [<a href=\'/ui?action=kill&pid=%s\'>x</a>]</td></tr>\n',j.status,i))
                    end
                end
                http.send('</table>\n')
            end

            ui_vars.streams=ui_show_streams

            http.sendtfile(cfg.ui_path..'ui_status.html',ui_vars)

        elseif args.action=='kill' then
            ui_vars.return_url='/ui?action=status'

            if not args.pid or not childs[tonumber(args.pid)] then
                http.sendtfile(cfg.ui_path..'ui_error.html',ui_vars)
            else
                util.kill(args.pid)
                http.sendtfile(cfg.ui_path..'ui_ok.html',ui_vars)
            end
        else
            http.sendtfile(cfg.ui_path..'ui_'..args.action..'.html',ui_vars)
        end
    end
end
