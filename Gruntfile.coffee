
module.exports = (grunt) ->

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'

        pepper:
            options:
                template: '::'
                pepper:  ['log']
                paprika: ['dbg']
                join:    false
                quiet:   true
            task:
                files:
                    'turtle': [ 'turtle.coffee', 'coffee/**/*.coffee' ]

        salt:
            options:
                dryrun:  false
                verbose: true
                refresh: false
            coffeelarge:
                options:
                    textMarker  : '#!!'
                files:
                    'asciiText': [ 'turtle.coffee', 'coffee/**/*.coffee' ]
            coffeesmall:
                options:
                    textMarker  : '#!'
                    textPrefix  : null
                    textFill    : '# '
                    textPostfix : null
                files:
                    'asciiText': [ 'turtle.coffee', 'coffee/**/*.coffee' ]
            style: 
                options:
                    verbose     : false
                    textMarker  : '//!'
                    textPrefix  : '/*'
                    textFill    : '*  '
                    textPostfix : '*/'
                files:
                    'asciiText' : ['./style/*.styl']

        stylus:
            options:
                compress: false
            compile:
                files:
                    'style/turtle-fixed.css':  ['style/turtle-fixed.styl']
                    'style/turtle-bright.css': ['style/turtle-bright.styl']
                    'style/turtle-dark.css':   ['style/turtle-dark.styl']
                    'style/bright.css':        ['style/bright-style.styl']
                    'style/dark.css':          ['style/dark-style.styl']

        bower_concat:
            all:
                dest: 'js/lib/bower.js'
                bowerOptions:
                    relative: false
                exclude: ['octicons', 'font-awesome']

        watch:
          sources:
            files: ['./*.coffee', './coffee/**/*.coffee', '**/*.styl', '*.html']
            tasks: ['build']

        coffee:
            options:
                bare: true
            turtle:
                expand:  true,
                flatten: true,
                cwd:     '.',
                src:     ['.pepper/turtle.coffee'],
                dest:    'js',
                ext:     '.js'
            coffee:
                expand:  true,
                flatten: true,
                cwd:     '.',
                src:     ['.pepper/coffee/*.coffee'],
                dest:    'js',
                ext:     '.js'
            knix:
                expand:  true,
                flatten: true,
                cwd:     '.',
                src:     ['.pepper/coffee/knix/*.coffee'],
                dest:    'js/knix',
                ext:     '.js'
            tools:
                expand:  true,
                flatten: true,
                cwd:     '.',
                src:     ['.pepper/coffee/tools/*.coffee'],
                dest:    'js/tools',
                ext:     '.js'

        bumpup:
            file: 'package.json'
            
        clean: ['password-turtle.app', 'style/*.css', 'js', 'pepper']
            
        shell:
            kill:
                command: "killall Electron || echo 1"
            build: 
                command: "node_modules/electron-packager/cli.js . password-turtle --platform=darwin --arch=x64 --prune --version=0.28.2 --app-version=0.9.2 --app-bundle-id=net.monsterkodi.password-turtle --ignore=node_modules/electron --icon=img/turtle.icns"
            test: 
                command: "electron ."
            start: 
                command: "open password-turtle.app"
            publish:
                command: 'npm publish'
            npmpage:
                command: 'open https://www.npmjs.com/package/password-turtle'
    ###
    npm install --save-dev grunt-contrib-watch
    npm install --save-dev grunt-contrib-coffee
    npm install --save-dev grunt-contrib-stylus
    npm install --save-dev grunt-contrib-clean
    npm install --save-dev grunt-bower-concat
    npm install --save-dev grunt-bumpup
    npm install --save-dev grunt-pepper
    npm install --save-dev grunt-shell
    ###

    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-stylus'
    grunt.loadNpmTasks 'grunt-contrib-clean'
    grunt.loadNpmTasks 'grunt-bower-concat'
    grunt.loadNpmTasks 'grunt-bumpup'
    grunt.loadNpmTasks 'grunt-pepper'
    grunt.loadNpmTasks 'grunt-shell'

    grunt.registerTask 'build',     [ 'clean', 'bumpup', 'stylus', 'salt', 'pepper', 'bower_concat', 'coffee',  'shell:kill', 'shell:build', 'shell:start' ]
    grunt.registerTask 'test',      [ 'clean', 'bumpup', 'stylus', 'salt', 'pepper', 'bower_concat', 'coffee', 'shell:kill', 'shell:test' ]
    grunt.registerTask 'default',   [ 'test' ]
    #grunt.registerTask 'publish',   [ 'bumpup', 'shell:publish', 'shell:npmpage' ]
