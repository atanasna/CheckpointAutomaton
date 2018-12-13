module ParserHelpers
    def open_tag lines, tag, debug=false
        oneliner = false
        lines = Marshal.load(Marshal.dump(lines))
        tags_contents = Array.new

        #debug if debug then pp lines end

        match_start = lines.find{ |l| l.match(/^\t+:#{tag} \(/)}

        #debug
        if debug then pp match_start end 

        indent = match_start.match(/^\t+/).to_s.scan(/\t/).size
        match_start = lines.find{ |l| l[/^\t{#{indent}}:#{tag} \(/]}
        if match_start.match(/\(.*?\)/)
            oneliner = true
        end

        #debug
        if debug then pp oneliner end

        while true
            match_start = lines.find{ |l| l.match(/^\t+:#{tag} \(/)}
            tag_content = Array.new
            if oneliner
                tag_index = lines.index(match_start)

                if tag_index.nil?
                    break
                else
                    tag_content = lines[tag_index].match(/\((.*?)\)/i).captures.first.to_s
                    tags_contents.push tag_content
                    lines.delete_at(tag_index)
                end
            else
                tag_start_index = lines.index(match_start)
                if tag_start_index.nil?
                    break
                else
                    tag_tabs_count = lines[tag_start_index].match(/^\t+/).to_s.scan(/\t/).size
                    lines = lines.slice tag_start_index+1, (lines.count-1)

                    match_end = lines.find{ |l| l[/^\t{#{tag_tabs_count}}\)/]}
                    tag_end_index = lines.index(match_end)
                    tag_content = lines.slice 0,tag_end_index
                    lines = lines.slice tag_end_index, (lines.count-1)
                    tags_contents.push tag_content
                end
            end
        end
        
        return tags_contents
    end
end