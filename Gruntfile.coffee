
module.exports = (grunt) ->

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'

        pepper:
            options:
                template: '::'
                pepper:  ['log']
                paprika: ['dbg']
                join:    false
            task:
                files:
                    'sheep': [ 'sheep.coffee', 'coffee/**/*.coffee' ]

        salt:
            options:
                dryrun:  false
                verbose: true
                refresh: false
            coffee:
                files:
                    'asciiText': [ 'sheep.coffee', 'coffee/**/*.coffee' ]
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
                    'style/sheep.css':  ['style/sheep.styl']
                    'style/bright.css': ['style/bright-style.styl']
                    'style/dark.css':   ['style/dark-style.styl']

        bower_concat:
            all:
                dest: 'js/lib/bower.js'
                bowerOptions:
                    relative: false
                exclude: ['octicons', 'font-awesome']

        watch:
          sources:
            files: ['./*.coffee', './coffee/**/*.coffee', '*.styl', '*.html']
            tasks: ['build']

        coffee:
            options:
                bare: true
            sheep:
                expand:  true,
                flatten: true,
                cwd:     '.',
                src:     ['.pepper/sheep.coffee'],
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
            
        clean: ['sheepword.app']
            
        shell:
            kill:
                command: "killall Electron || echo 1"
            build: 
                command: "node_modules/electron-packager/cli.js . sheepword --platform=darwin --arch=x64 --prune --version=0.28.2 --app-version=0.1.0 --app-bundle-id=net.monsterkodi.sheepword --ignore=node_modules/electron --icon=img/sheepword.icns"
            test: 
                command: "electron ."
            start: 
                command: "open sheepword.app"
            publish:
                command: 'npm publish'
            npmpage:
                command: 'open https://www.npmjs.com/package/sheepword'
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
