
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
            turtle:
                files:
                    'turtle': [ 'turtle.coffee', 'coffee/**/*.coffee' ]
            release:
                options: 
                    outdir: '.'
                    type:   '.sh'
                    pepper:  null
                    paprika: null
                    join:    true
                files:
                    '.release': ['release.sh']

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
            
        clean: ['password-turtle.app', 'password-turtle.zip', 'style/*.css', 'js', 'pepper', '.release.*']
            
            
        githubAsset:
            options:
                credentials: grunt.file.readJSON('.apitoken.json') 
                repo: 'git@github.com:monsterkodi/password-turtle.git',
                file: 'password-turtle.zip'
                
        shell:
            options:
                execOptions: 
                    maxBuffer: Infinity
            kill:
                command: "killall Electron || echo 1"
            build: 
                command: "bash build.sh"
            test: 
                command: "electron ."
            start: 
                command: "open password-turtle.app"
            release:
                command: 'bash .release.sh'
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
    grunt.loadNpmTasks 'grunt-github-release-asset'
    grunt.loadNpmTasks 'grunt-bumpup'
    grunt.loadNpmTasks 'grunt-pepper'
    grunt.loadNpmTasks 'grunt-shell'

    grunt.registerTask 'build',     [ 'clean', 'stylus', 'salt', 'pepper', 'bower_concat', 'coffee', 'shell:kill', 'shell:build', 'shell:start' ]
    grunt.registerTask 'release',   [ 'clean', 'stylus', 'salt', 'pepper', 'bower_concat', 'coffee', 'shell:build', 'shell:release', 'githubAsset' ]
    grunt.registerTask 'test',      [ 'clean', 'stylus', 'salt', 'pepper', 'bower_concat', 'coffee', 'shell:kill', 'shell:test' ]
    grunt.registerTask 'default',   [ 'test' ]
