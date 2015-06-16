###
 0000000  000000000  000   000  000      00000000   0000000  000   000  000  000000000   0000000  000   000
000          000      000 000   000      000       000       000 0 000  000     000     000       000   000
0000000      000       00000    000      0000000   0000000   000000000  000     000     000       000000000
     000     000        000     000      000            000  000   000  000     000     000       000   000
0000000      000        000     0000000  00000000  0000000   00     00  000     000      0000000  000   000
###

class StyleSwitch

    @schemes = ['dark.css', 'bright.css']
    @colors  = {}

    @init: =>
        @toggle()
        @toggle()

    @toggle: =>

        link = document.getElementById 'style-link'
        currentScheme = link.href.split('/').last()
        nextSchemeIndex = ( @schemes.indexOf(currentScheme) + 1) % @schemes.length
        newlink = document.createElement "link"
        newlink.setAttribute 'rel',  'stylesheet'
        newlink.setAttribute 'type', 'text/css'
        newlink.setAttribute 'href', 'style/'+@schemes[nextSchemeIndex]
        newlink.setAttribute 'id',   'style-link'

        link.parentNode.replaceChild(newlink, link)
        
        @initColors()
        
    @initColors: =>
        
        colors = document.createElement "div"
        for cn in ['analyser', 'analyser_trace', 'analyser_trigger', 'synth_canvas', 'synth_trace']
            colors.setAttribute 'class', cn
            @colors[cn] = window.getComputedStyle(colors).color

    @togglePathFilter: =>

        if not @filter?
            for p in $$('.path')
                s = window.getComputedStyle p
                @filter = p.instance.style('filter')
                p.instance.style 'filter: none'
        else
            for p in $$('.path')
                p.instance.style({ filter: @filter })
            delete @filter

module.exports = StyleSwitch